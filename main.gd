extends Node

@export
var game_scene: PackedScene

@onready
var main_menu: MainMenu = $MainMenu
var game: Game

enum GameState {MAIN_MENU, PLAYING, ENDED}

var game_state = GameState.MAIN_MENU

func _ready():
	$MainMenu.start.connect(start_game)
	$MainMenu.quit.connect(quit_game)

	$PauseMenu.on_resume.connect(unpause)
	$PauseMenu.on_restart.connect(start_game)
	$PauseMenu.on_quit.connect(quit_game)

	$GameOver.on_play_again.connect(start_game)
	$GameOver.on_quit.connect(quit_game)

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

func quit_game():
	get_tree().quit()

func _unhandled_input(event: InputEvent):
	if event.is_action_released("pause") && game_state == GameState.PLAYING:
		toggle_pause()
