extends Control
class_name PauseMenu

signal on_resume
signal on_restart
signal on_quit


func _on_resume_button_pressed():
	on_resume.emit()

func _on_restart_button_pressed():
	on_restart.emit()

func _on_quit_button_pressed():
	on_quit.emit()
