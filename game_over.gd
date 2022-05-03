extends Control
class_name GameOver

signal on_play_again
signal on_quit

enum GameOverCause {CRASHED_BOX, CRASHED_PLANET, LOST_SIGNAL}

var fast_forward_input_threshold = 5
var game_over_inputs = 0

func _ready():
	clear_game_over()

func trigger_game_over(cause: GameOverCause, score: int):
	visible = true

	match cause:
		GameOverCause.CRASHED_BOX:
			$GameOverMessage.text = "You destroyed your cargo."
		GameOverCause.CRASHED_PLANET:
			$GameOverMessage.text = "You crashed into a celestial body."
		GameOverCause.LOST_SIGNAL:
			$GameOverMessage.text = "Signal lost. You strayed too far."

	$ScoreMessage.text = "Your score: %s" % score
	$AnimationPlayer.playback_speed = 1
	$AnimationPlayer.play("GameOver")

func clear_game_over():
	visible = false
	game_over_inputs = 0
	$AnimationPlayer.stop()
	$GameOverMusic.stop()


func _on_play_again_pressed():
	fast_forward_input_threshold = 1
	on_play_again.emit()

func _on_quit_pressed():
	on_quit.emit()

func _unhandled_input(event: InputEvent):
	handle_game_over_input(event)

func _gui_input(event: InputEvent):
	handle_game_over_input(event)

func handle_game_over_input(event: InputEvent):
	if event is InputEventScreenTouch and event.pressed:
		handle_game_over_press(event)
	elif event is InputEventMouseButton and event.pressed:
		handle_game_over_press(event)
	elif event is InputEventJoypadButton and event.pressed:
		handle_game_over_press(event)
	elif event is InputEventKey and event.pressed:
		handle_game_over_press(event)

func handle_game_over_press(event: InputEvent):
	if visible and $AnimationPlayer.is_playing():
		game_over_inputs += 1

		if game_over_inputs >= fast_forward_input_threshold:
			$AnimationPlayer.playback_speed = 20
