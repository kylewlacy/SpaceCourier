extends Node

var ship_curve_debug_mesh: ImmediateMesh

func _ready():
	pass
	ship_curve_debug_mesh = ImmediateMesh.new()
	var ship_curve_debug_mesh_instance = MeshInstance3D.new()
	ship_curve_debug_mesh_instance.mesh = ship_curve_debug_mesh
	add_child(ship_curve_debug_mesh_instance)

func _physics_process(_delta):
	var origin = $Ship.position
	var ship_curve = $ShipPath.curve
	ship_curve.add_point(origin)

	$ShipPath/ShipPathFollow.offset = ship_curve.get_baked_length() - 0.5

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
		pickup.attach($ShipPath/ShipPathFollow)
