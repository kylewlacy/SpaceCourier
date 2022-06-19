extends Control
class_name PauseMenu

signal on_resume
signal on_restart
signal on_toggle_fullscreen
signal on_quit

signal start_music_preview
signal stop_music_preview
signal play_sound_preview
signal changed_music_volume(volume: float)
signal changed_sound_volume(volume: float)

func _process(delta):
	if visible and Input.is_action_just_pressed("restart"):
		on_restart.emit()

func set_music_volume(new_value: float):
	$MusicSlider.value = new_value

func set_sound_volume(new_value: float):
	$SoundSlider.value = new_value

func _on_resume_button_pressed():
	on_resume.emit()

func _on_restart_button_pressed():
	on_restart.emit()

func _on_quit_button_pressed():
	on_quit.emit()

func _on_sound_slider_value_changed(value):
	play_sound_preview.emit()
	changed_sound_volume.emit(value)

func _on_music_slider_value_changed(value):
	changed_music_volume.emit(value)

func _on_music_slider_focus_entered():
	start_music_preview.emit()

func _on_music_slider_focus_exited():
	stop_music_preview.emit()


func _on_pause_menu_focus_entered():
	$ResumeButton.grab_focus()


func _on_pause_menu_visibility_changed():
	if visible:
		$ResumeButton.grab_focus()


func _on_toggle_fullscreen_button_pressed():
	on_toggle_fullscreen.emit()
