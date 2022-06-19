extends Node

@onready
var trail: TrailPath3D = TrailPath3D.new()

var ship_curve_debug_mesh: ImmediateMesh

@export var speed = 10
@export var steps_per_phys_frame = 100

@export var debug_trail_size = 1000
@export var debug_trail_initial_offset = 0.1
@export var debug_trail_offset = 0.01


var last_transform = null

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

	var max_points_to_draw = debug_trail_size if debug_trail_size > 0 else trail.size()#

	var state = {"points_drawn": 0}
	var for_each_transform = func(transform: Transform3D, index: int):
		ship_curve_debug_mesh.surface_add_vertex(transform.origin)
		state["points_drawn"] += 1
	var result = trail.for_each_step(debug_trail_offset, debug_trail_initial_offset, max_points_to_draw, TrailPath3D.Direction.END_TO_START, for_each_transform)

	print(result.debug_info())
	if state["points_drawn"] > max_points_to_draw:
		push_warning("Expected to draw at most %s but drew %s points" % [max_points_to_draw, state["points_drawn"]])

	if result.exit_result == TrailPath3D.ExitResult.COMPLETE:
		var cleaned = trail.clean(TrailPath3D.Direction.END_TO_START, result.points_stepped + 100, 1000)
		if cleaned > 0:
			print("Cleaned %s point(s)" % cleaned)


	ship_curve_debug_mesh.surface_end()

func step(delta):
	$Node3D/Path3D/PathFollow3D.offset += delta * speed;

	var new_transform = $Node3D/Path3D/PathFollow3D/MeshInstance3D.global_transform
	trail.append(new_transform)

	var check_new_transform = trail.get_transform(trail.size() - 1)
	if check_new_transform != new_transform:
		push_warning("Transform did not match!")

	if last_transform:
		var check_last_transform = trail.get_transform(trail.size() - 2)
		if check_last_transform != last_transform:
			push_warning("Last transform did not match!")

	last_transform = new_transform

