extends Object
class_name TrailPath3D

var points = PackedVector3Array()
var index = 0

var current_length = 0.0

var current_size = 1000
var max_size = 1000

func set_max_size(new_max_size: int):
	max_size = max(new_max_size, 1)

func size() -> int:
	return current_size

func append(point: Vector3):
	if points.size() >= max_size:
		points.resize(max_size)
		current_size = max_size

	var last_point = get_last_point_or_fallback(point)

func get_last_point_or_fallback(fallback: Vector3):
	if current_size == 0:
		return fallback
	elif index == 0:
		return points[current_size - 1]
	else:
		return points[index]
