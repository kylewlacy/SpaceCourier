extends Camera3D

var focus: Node3D

@export
var base_zoom = 10.0

@export
var speed = 1.0

func set_focus(new_focus: Node3D):
	focus = new_focus

func _process(delta):
	var target_position = calculate_target_position()
	global_transform.origin = global_transform.origin.lerp(target_position, delta * speed)

func calculate_target_position() -> Vector3:
	return focus.global_transform.origin + Vector3(0, 0, base_zoom)
