extends Node

@export
var game_scene: PackedScene

@onready
var main_menu = $MainMenu
var game: Game

enum GameState {MAIN_MENU, PLAYING, ENDED}

var game_state = GameState.MAIN_MENU

var music_preview_playing = false
var sound_preview_playing = false

var fuzz_compressor: AudioEffectCompressor
var fuzz_low_pass: AudioEffectLowPassFilter

func _ready():
	fuzz_compressor = AudioEffectCompressor.new()
	fuzz_compressor.ratio = 35
	fuzz_compressor.gain = 1.2
	fuzz_compressor.attack_us = 20
	fuzz_compressor.release_ms = 34

	fuzz_low_pass = AudioEffectLowPassFilter.new()
	fuzz_low_pass.cutoff_hz = 10

	AudioServer.add_bus_effect(AudioServer.get_bus_index("Distortable"), fuzz_compressor)
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Distortable"), fuzz_low_pass)

	self.update_music_volume(0.8)
	self.update_sound_volume(0.8)

	$MainMenu.start.connect(start_game)
	$MainMenu.toggle_fullscreen.connect(toggle_fullscreen)
	$MainMenu.quit.connect(quit_game)

	$PauseMenu.on_resume.connect(unpause)
	$PauseMenu.on_restart.connect(start_game)
	$PauseMenu.on_toggle_fullscreen.connect(toggle_fullscreen)
	$PauseMenu.on_quit.connect(quit_game)

	$GameOver.on_play_again.connect(start_game)
	$GameOver.on_quit.connect(quit_game)

	$MainMenu.changed_music_volume.connect(update_music_volume)
	$MainMenu.changed_sound_volume.connect(update_sound_volume)
	$MainMenu.play_sound_preview.connect(play_sound_preview)
	$MainMenu.start_music_preview.connect(start_music_preview)
	$MainMenu.stop_music_preview.connect(stop_music_preview)

	$PauseMenu.changed_music_volume.connect(update_music_volume)
	$PauseMenu.changed_sound_volume.connect(update_sound_volume)
	$PauseMenu.play_sound_preview.connect(play_sound_preview)
	$PauseMenu.start_music_preview.connect(start_music_preview)
	$PauseMenu.stop_music_preview.connect(stop_music_preview)


func start_game():
	$GameOver.clear_game_over()

	if main_menu:
		main_menu.queue_free()
		main_menu = null

	if game:
		game.queue_free()
		game = null

	game = game_scene.instantiate() as Game
	game.game_over.connect(game_over)
	if not game:
		push_warning("Game scene was not Game")
		return

	add_child(game)
	game_state = GameState.PLAYING

	unpause()

func game_over(cause: GameOver.GameOverCause, score: int):
	if game_state == GameState.PLAYING:
		$GameOver.trigger_game_over(cause, score)
		game_state = GameState.ENDED

func pause():
	$PauseMenu.visible = true
	get_tree().paused = true

func unpause():
	$PauseMenu.visible = false
	get_tree().paused = false

func toggle_pause():
	if get_tree().paused:
		unpause()
	else:
		pause()

func toggle_fullscreen():
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_MINIMIZED, DisplayServer.WINDOW_MODE_MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func quit_game():
	get_tree().quit()

func _process(delta: float):
	process_fuzziness()
	process_sound(delta)

func process_fuzziness():
	match game_state:
		GameState.PLAYING:
			if game:
				set_fuzziness(game.get_fuzziness())
			else:
				set_fuzziness(0)
		GameState.MAIN_MENU:
			set_fuzziness(0)
		GameState.ENDED:
			# Keep fuzziness during game over screen
			pass

func set_fuzziness(fuzziness: float):
	$Fuzziness.visible = fuzziness > 0
	$Fuzziness/FuzzRect.material.set_shader_param("alpha", fuzziness)

	if fuzziness > 0:
		if not $FuzzSound.playing:
			$FuzzSound.play()
		AudioServer.set_bus_bypass_effects(AudioServer.get_bus_index("Distortable"), false)
	elif fuzziness <= 0:
		if $FuzzSound.playing:
			$FuzzSound.stop()
		AudioServer.set_bus_bypass_effects(AudioServer.get_bus_index("Distortable"), true)
	$FuzzSound.volume_db = linear2db(clamp(fuzziness, 0, 1))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Distortable"), linear2db(clamp(1 - fuzziness, 0.5, 1)))
	fuzz_compressor.threshold = clamp(fuzziness * 2, 0, 1) * -16
	fuzz_low_pass.cutoff_hz = 10 + ((1 - fuzziness) * 20490)

func process_sound(delta: float):
	if can_play_preview_sounds():
		if music_preview_playing:
			$MusicPreview.volume_db = linear2db(clamp(db2linear($MusicPreview.volume_db) + 2 * delta, 0, 1))
			if not $MusicPreview.playing:
				$MusicPreview.play()
		else:
			if $MusicPreview.playing:
				$MusicPreview.volume_db = linear2db(clamp(db2linear($MusicPreview.volume_db) - 4 * delta, 0, 1))
				if $MusicPreview.volume_db < -60:
					$MusicPreview.stop()

	else:
		if $MusicPreview.playing:
			$MusicPreview.stop()
		if $SoundPreview.playing:
			$SoundPreview.stop()

func can_play_preview_sounds() -> bool:
	if game_state == GameState.MAIN_MENU:
		return true
	elif $PauseMenu.visible:
		return true
	else:
		return false

func _input(event: InputEvent):
	if event.is_action_released("pause") && game_state == GameState.PLAYING:
		toggle_pause()
	if event.is_action_pressed("toggle_fullscreen"):
		get_viewport().set_input_as_handled() # Prevent "Enter" from triggering other events
		toggle_fullscreen()


func start_music_preview():
	music_preview_playing = true

func stop_music_preview():
	music_preview_playing = false

func play_sound_preview():
	if not $SoundPreview.playing:
		$SoundPreview.play()


func update_music_volume(volume: float):
	if main_menu:
		main_menu.set_music_volume(volume)
	$PauseMenu.set_music_volume(volume)

	var volume_db = linear2db(clamp(volume, 0, 1))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volume_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Fuzz"), volume_db)


func update_sound_volume(volume: float):
	if main_menu:
		main_menu.set_sound_volume(volume)
	$PauseMenu.set_sound_volume(volume)

	var volume_db = linear2db(clamp(volume, 0, 1))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), volume_db)
