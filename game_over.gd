extends Control
class_name GameOver

signal on_play_again
signal on_quit

enum GameOverCause {CRASHED_BOX, CRASHED_PLANET, LOST_SIGNAL}

func _ready():
	clear_game_over()

func trigger_game_over(cause: GameOverCause, score: int):
	visible = true

	match cause:
		GameOverCause.CRASHED_BOX:
			$GameOverMessage.text = "You crashed into your cargo."
		GameOverCause.CRASHED_PLANET:
			$GameOverMessage.text = "You crashed into a celestial body."
		GameOverCause.LOST_SIGNAL:
			$GameOverMessage.text = "Signal lost. You strayed too far."

	$ScoreMessage.text = "Your score: %s" % score
	$AnimationPlayer.play("GameOver")

func clear_game_over():
	visible = false
	$AnimationPlayer.stop()


func _on_play_again_pressed():
	on_play_again.emit()


func _on_quit_pressed():
	on_quit.emit()
