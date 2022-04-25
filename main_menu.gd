extends Control
class_name MainMenu

signal start
signal quit


func _on_start_button_pressed():
	start.emit()

func _on_quit_button_pressed():
	quit.emit()
