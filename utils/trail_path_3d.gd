extends Object
class_name TrailPath3D

var points = PackedVector3Array()

func append(point: Vector3):
	points.append(point)

func size() -> int:
	return points.size()

func get_point(i: int) -> Vector3:
	return points[i]
