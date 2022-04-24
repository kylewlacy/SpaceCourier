extends Camera3D

var focus: Node3D

@export
var speed = 1.0

func set_focus(new_focus: Node3D):
	focus = new_focus

func _process(delta):
	var target_position = calculate_target_position()
	global_transform.origin = global_transform.origin.lerp(target_position, delta * speed)

func calculate_target_position_orig() -> Vector3:
	var bounding_box = make_aabb(focus.global_transform.origin, Vector3.ONE)
	print(bounding_box)

	var new_position = aabb_center(bounding_box)
	var distance = (bounding_box.size.x / 2) / tan(fov / 2)
	print(distance)
	new_position.z -= distance

	return new_position

func calculate_target_position() -> Vector3:
	var min_pos = focus.global_transform.origin
	var max_pos = focus.global_transform.origin

	var camera_tracking_nodes = get_tree().get_nodes_in_group("camera_tracking")
	for node in camera_tracking_nodes:
		var node3d := node as Node3D
		if not node3d:
			push_warning("Camera tracking node is not Node3D")
			continue

		var node_pos = node3d.global_transform.origin
		min_pos = Vector3(min(min_pos.x, node_pos.x), min(min_pos.y, node_pos.y), min(min_pos.z, node_pos.z))
		max_pos = Vector3(max(max_pos.x, node_pos.x), max(max_pos.y, node_pos.y), max(max_pos.z, node_pos.z))

	var bounding_box = AABB(min_pos, max_pos - min_pos)

	var new_position = aabb_center(bounding_box)
	var hfov = get_hfov()
	var v_distance = (bounding_box.size.x / 2) / tan(deg2rad(fov) / 2)
	var h_distance = (bounding_box.size.y / 2) / tan(deg2rad(hfov) / 2)
	var distance = max(v_distance, h_distance)

	new_position.z += distance

	return new_position

func get_hfov() -> float:
	# https://calculator.academy/vertical-fov-calculator/
	return rad2deg(2 * atan(tan(deg2rad(fov / 2)) * get_inverse_aspect_ratio()))

func get_inverse_aspect_ratio() -> float:
	var viewport_rect = get_viewport().get_visible_rect()
	return viewport_rect.size.y / viewport_rect.size.x

func make_aabb(center: Vector3, size: Vector3) -> AABB:
	return AABB(center - (size / 2), center + (size / 2))

func aabb_center(aabb: AABB) -> Vector3:
	return aabb.position + (aabb.size / 2)