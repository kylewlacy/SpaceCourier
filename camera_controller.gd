extends Camera3D

var focus: Node3D

@export
var enabled = true

@export
var speed = 1.0

@export
var margin = 1.0

func set_focus(new_focus: Node3D):
	focus = new_focus

func _process(delta):
	if !enabled:
		return
	var target_position = calculate_target_position()
	global_transform.origin = global_transform.origin.lerp(target_position, delta * speed)

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
		min_pos = Vector3(min(min_pos.x, node_pos.x - margin), min(min_pos.y, node_pos.y - margin), min(min_pos.z, node_pos.z - margin))
		max_pos = Vector3(max(max_pos.x, node_pos.x + margin), max(max_pos.y, node_pos.y + margin), max(max_pos.z, node_pos.z + margin))

	var bounding_box = AABB(min_pos, max_pos - min_pos)

	var new_position = aabb_center(bounding_box)
	var hfov = get_hfov()
	var v_distance = (bounding_box.size.x / 2) / tan(deg2rad(hfov) / 2)
	var h_distance = (bounding_box.size.y / 2) / tan(deg2rad(fov) / 2)
	var distance = max(v_distance, h_distance)

	new_position.z += distance

	return new_position

func get_hfov() -> float:
	# https://calculator.academy/vertical-fov-calculator/
	return rad2deg(2 * atan(tan(deg2rad(fov / 2)) * get_aspect_ratio()))

func get_aspect_ratio() -> float:
	var viewport_rect = get_viewport().get_visible_rect()
	return viewport_rect.size.x / viewport_rect.size.y

func make_aabb(center: Vector3, box_size: Vector3) -> AABB:
	return AABB(center - (box_size / 2), box_size)

func aabb_center(aabb: AABB) -> Vector3:
	return aabb.position + (aabb.size / 2)
