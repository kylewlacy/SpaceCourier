extends AudioStreamPlayer

@export var light_sounds: Array[AudioStream] = []

@export var mid_threshold: float = 0.1
@export var mid_sounds: Array[AudioStream] = []

@export var heavy_threshold: float = 1
@export var heavy_sounds: Array[AudioStream] = []

@export var small_crash_sounds: Array[AudioStream] = []

@export var big_crash_threshold: float = 0.3
@export var big_crash_sounds: Array[AudioStream] = []

var has_already_played: bool = false



func play_crash_sound(cause: GameOver.GameOverCause, ship_speed: float):
	if has_already_played:
		return

	has_already_played = true

	match cause:
		GameOver.GameOverCause.CRASHED_PLANET:
			if ship_speed > heavy_threshold && heavy_sounds.size() > 0:
				stream = heavy_sounds[randi_range(0, heavy_sounds.size() - 1)]
			elif ship_speed > mid_threshold && mid_sounds.size() > 0:
				stream = mid_sounds[randi_range(0, mid_sounds.size() - 1)]
			elif light_sounds.size() > 0:
				stream = light_sounds[randi_range(0, light_sounds.size() - 1)]
			else:
				push_warning("Could not pick planet crash sound")
		GameOver.GameOverCause.CRASHED_BOX:
			if ship_speed > big_crash_threshold && big_crash_sounds.size() > 0:
				stream = big_crash_sounds[randi_range(0, big_crash_sounds.size() - 1)]
			elif small_crash_sounds.size() > 0:
				stream = big_crash_sounds[randi_range(0, small_crash_sounds.size() - 1)]
			else:
				push_warning("Could not pick box crash sound")

	if not stream:
		return

	play()
