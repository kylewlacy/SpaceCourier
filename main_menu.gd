extends Control
class_name MainMenu

signal start
signal quit

signal start_music_preview
signal stop_music_preview
signal play_sound_preview
signal changed_music_volume(volume: float)
signal changed_sound_volume(volume: float)

func _ready():
	$StartButton.grab_focus()

func set_music_volume(new_value: float):
	$MusicSlider.value = new_value

func set_sound_volume(new_value: float):
	$SoundSlider.value = new_value

func _on_start_button_pressed():
	start.emit()

func _on_quit_button_pressed():
	quit.emit()

func _on_sound_slider_value_changed(value: float):
	play_sound_preview.emit()
	changed_sound_volume.emit(value)

func _on_music_slider_value_changed(value):
	changed_music_volume.emit(value)

func _on_music_slider_focus_entered():
	start_music_preview.emit()
	
func _on_music_slider_focus_exited():
	stop_music_preview.emit()
	

