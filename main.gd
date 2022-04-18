extends Node

@export
var pickup_scene: PackedScene

var enable_debug_draw = true
var ship_curve_debug_mesh: ImmediateMesh

var attached_pickup_followers: Array[PathFollow3D] = []

func _ready():
	$CameraController.set_focus($Ship)

	spawn_new_pickup()

	if enable_debug_draw:
		ship_curve_debug_mesh = ImmediateMesh.new()
		var ship_curve_debug_mesh_instance = MeshInstance3D.new()
		ship_curve_debug_mesh_instance.mesh = ship_curve_debug_mesh
		add_child(ship_curve_debug_mesh_instance)

func _physics_process(_delta):
	var ship_curve = $ShipPath.curve
	ship_curve.add_point($Ship.get_attachment_position())
	var ship_curve_length = ship_curve.get_baked_length()

	for i in range(attached_pickup_followers.size()):
		var follow = attached_pickup_followers[i]
		follow.offset = ship_curve_length - ((i + 1) * 0.5)

	if ship_curve_debug_mesh:
		ship_curve_debug_mesh.clear_surfaces()
		ship_curve_debug_mesh.surface_begin(Mesh.PRIMITIVE_POINTS)
		for i in range(ship_curve.get_point_count()):
			ship_curve_debug_mesh.surface_add_vertex(ship_curve.get_point_position(i))
		ship_curve_debug_mesh.surface_end()

func _on_pickup_collided(_pickup, body):
	if body == $Ship:
		print("Collided with ship")


func _on_pickup_picked_up(pickup, body):
	if body == $Ship:
		var follower = PathFollow3D.new()
		$ShipPath.add_child(follower)
		attached_pickup_followers.append(follower)
		pickup.attach(follower)
		spawn_new_pickup()

func spawn_new_pickup():
	var location = get_new_pickup_location()
	var pickup = pickup_scene.instantiate()
	pickup.position = location
	pickup.picked_up.connect(_on_pickup_picked_up)
	pickup.collided.connect(_on_pickup_collided)
	$Pickups.add_child(pickup)

func get_new_pickup_location() -> Vector3:
	var planets = get_tree().get_nodes_in_group("planets")
	var planet_index = randi_range(0, planets.size() - 1)
	var planet := planets[planet_index] as Planet
	if not planet:
		push_warning("Node in group 'planets' was not type Planet")
		return Vector3.ZERO
	var planet_center = planet.global_transform.origin
	var rotation = randf_range(0, 2 * PI)
	var distance_from_surface = randf_range(0.5, 0.75)
	var distance = distance_from_surface + planet.radius
	var location = planet_center + Vector3(distance * sin(rotation), distance * cos(rotation), 0)
	return location

