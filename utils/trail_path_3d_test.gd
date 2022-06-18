extends Node

@onready
var trail: TrailPath3D = TrailPath3D.new()

var ship_curve_debug_mesh: ImmediateMesh

@export
var speed = 10

@export
var steps_per_phys_frame = 100

@export
var debug_trail_size = 1000

func _ready():
	ship_curve_debug_mesh = ImmediateMesh.new()
	var ship_curve_debug_mesh_instance = MeshInstance3D.new()
	ship_curve_debug_mesh_instance.mesh = ship_curve_debug_mesh
	add_child(ship_curve_debug_mesh_instance)

func _physics_process(delta):
	for _i in range(0, steps_per_phys_frame):
		step(delta / steps_per_phys_frame)

func _process(_delta):
	$Control/SizeLabel.text = "Trail size: %s" % trail.size()

	ship_curve_debug_mesh.clear_surfaces()
	ship_curve_debug_mesh.surface_begin(Mesh.PRIMITIVE_POINTS)

	var max_points_to_draw = debug_trail_size if debug_trail_size > 0 else trail.size()
	for i in range(0, min(trail.size(), max_points_to_draw)):
		ship_curve_debug_mesh.surface_add_vertex(trail.get_point(trail.size() - i - 1))
	ship_curve_debug_mesh.surface_end()

func step(delta):
	$Node3D/Path3D/PathFollow3D.offset += delta * speed;

	trail.append($Node3D/Path3D/PathFollow3D/MeshInstance3D.global_transform.origin)
