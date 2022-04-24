extends Node3D

@export
var close_stars = 50

@export
var far_stars = 200

@export
var seed = 1

@export
var mesh: Mesh

var rng = RandomNumberGenerator.new()

func _ready():
	rng.set_seed(seed)
	remove_all_children()
	generate_stars()

# For testing purposes, the starfield includes an example star. We remove it
# at runtime
func remove_all_children():
	for child in get_children():
		remove_child(child)

func generate_stars():
	for i in range(close_stars):
		generate_star("Close star %s" % i, 8, 10)
	for i in range(far_stars):
		generate_star("Far star %s" % i, 20, 40)

func generate_star(label: String, min_distance: float, max_distance: float):
	var star = MeshInstance3D.new()
	star.name = label
	star.mesh = mesh
	star.position = new_star_position(min_distance, max_distance)

	add_child(star)


func new_star_position(min_distance: float, max_distance: float) -> Vector3:
	var distance = rng.randf_range(min_distance, max_distance)
	var polar_angle = rng.randf_range(PI / 2, PI)
	#var polar_angle = rng.randf_range(0, PI)
	var azimuthal_angle = rng.randf_range(0, 2 * PI)

	var x = distance * cos(azimuthal_angle) * sin(polar_angle)
	var y = distance * sin(azimuthal_angle) * sin(polar_angle)
	var z = distance * cos(polar_angle)

	return Vector3(x, y, z)
