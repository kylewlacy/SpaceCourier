extends Node

@export
var game_scene: PackedScene

var game: Game

enum GameState {MAIN_MENU, PLAYING, ENDED}

var game_state = GameState.MAIN_MENU

func _ready():
	$MainMenu.start.connect(start_game)
	$MainMenu.quit.connect(quit_game)

func start_game():
	$MainMenu.queue_free()

	game = game_scene.instantiate() as Game
	if not game:
		push_warning("Game scene was not Game")
		return

	add_child(game)
	game_state = GameState.PLAYING

func toggle_pause():
	var is_currently_paused = get_tree().paused

	get_tree().paused = !is_currently_paused

func quit_game():
	get_tree().quit()

func _unhandled_input(event: InputEvent):
	if event.is_action_released("pause") && game_state == GameState.PLAYING:
		toggle_pause()
