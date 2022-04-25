extends Node3D

@export
var near_stars = 50

@export
var mid_stars = 200

@export
var far_stars = 500

@export
var star_seed = 1

@export
var mesh: Mesh

var rng = RandomNumberGenerator.new()

func _ready():
	rng.set_seed(star_seed)
	remove_example()
	generate_stars()

# For testing purposes, the starfield includes an example star. We remove it
# at runtime
func remove_example():
	for example in $Example.get_children():
		example.queue_free()
	$Example.queue_free()

func generate_stars():
	for i in range(near_stars):
		generate_star("Close star %s" % i, area_aabb($Area/Near))
	for i in range(mid_stars):
		generate_star("Mid star %s" % i, area_aabb($Area/Mid))
	for i in range(far_stars):
		generate_star("Far star %s" % i, area_aabb($Area/Far))

func generate_star(label: String, bounding_box: AABB):
	var star = MeshInstance3D.new()
	star.name = label
	star.mesh = mesh
	star.position = new_star_position(bounding_box)

	add_child(star)


func new_star_position(bounding_box: AABB) -> Vector3:
	var x = rng.randf_range(bounding_box.position.x, bounding_box.end.x)
	var y = rng.randf_range(bounding_box.position.y, bounding_box.end.y)
	var z = rng.randf_range(bounding_box.position.z, bounding_box.end.z)

	return Vector3(x, y, z)

func area_aabb(area: CollisionShape3D) -> AABB:
	var box = area.shape as BoxShape3D
	if not box:
		push_warning("Area is not a BoxShape3D")
		return make_aabb(area.position, Vector3.ONE)

	return make_aabb(area.position, box.size)

# FIXME: This is a duplicate of `make_aabb` in `camera_controller.gd`
func make_aabb(center: Vector3, box_size: Vector3) -> AABB:
	return AABB(center - (box_size / 2), box_size)
