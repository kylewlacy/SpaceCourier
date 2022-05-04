extends Control
class_name PauseMenu

signal on_resume
signal on_restart
signal on_quit

signal start_music_preview
signal stop_music_preview
signal play_sound_preview
signal changed_music_volume(volume: float)
signal changed_sound_volume(volume: float)

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


func _on_music_slider_value_changed(value):
	changed_music_volume.emit(value)


func _on_sound_slider_value_changed(value):
	play_sound_preview.emit()
	changed_sound_volume.emit(value)


func _on_music_slider_drag_started():
	start_music_preview.emit()


func _on_music_slider_drag_ended(value_changed):
	stop_music_preview.emit()
