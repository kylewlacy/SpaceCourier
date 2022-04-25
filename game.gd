extends Node
class_name Game

signal game_over(cause: GameOver.GameOverCause, score: int)

@export
var pickup_scene: PackedScene

var next_pickup_hemisphere = 0

var attached_pickup_followers: Array[PathFollow3D] = []

var score = 0

func _ready():
	$ShipSmoke.emitting = false
	$ShipSmoke.global_transform.origin = Vector3.ZERO
	$ShipSmoke.rotation = Vector3.ZERO

	$CameraController.set_focus($Ship)

	$Earth.rotation_speed = 0

func _process(_delta):
	var smoke_emission_point = $Ship.get_smoke_position()
	var smoke_emission_normal = (smoke_emission_point - $Ship.global_transform.origin).normalized()
	var rotated_smoke_emission_normal = Quaternion(Vector3.FORWARD, PI / 2) * smoke_emission_normal
	$ShipSmoke.emission_points = PackedVector3Array([smoke_emission_point])
	$ShipSmoke.emission_normals = PackedVector3Array([rotated_smoke_emission_normal])
	$ShipSmoke.emitting = $Ship.is_thrusting()

func _physics_process(_delta):
	update_ship_curve()

# TODO: This function slows down significantly after collecting lots of pickups
func update_ship_curve():
	var ship_curve = $ShipPath.curve
	ship_curve.add_point($Ship.get_attachment_position())
	var ship_curve_length = ship_curve.get_baked_length()

	for i in range(attached_pickup_followers.size()):
		var follow = attached_pickup_followers[i]
		follow.offset = ship_curve_length - (1.0 + (i * 0.5))

func _on_pickup_collided(_pickup, body):
	if body == $Ship:
		game_over.emit(GameOver.GameOverCause.CRASHED_BOX, score)


func _on_pickup_picked_up(pickup, body):
	if body == $Ship:
		score += 1

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
	var pickup_hemisphere_offset = next_pickup_hemisphere * PI
	next_pickup_hemisphere = (next_pickup_hemisphere + 1) % 2

	var planets = get_tree().get_nodes_in_group("planets")
	var planet_index = randi_range(0, planets.size() - 1)
	var planet := planets[planet_index] as Planet
	if not planet:
		push_warning("Node in group 'planets' was not type Planet")
		return Vector3.ZERO
	var planet_center = planet.global_transform.origin
	var rotation = pickup_hemisphere_offset + randf_range(-3 * PI / 8, 3 * PI / 8)
	var distance_from_surface = randf_range(0.5, 0.75)
	var distance = distance_from_surface + planet.radius
	var location = planet_center + Vector3(distance * sin(rotation), distance * cos(rotation), 0)
	return location


func _on_initial_pickup_picked_up(pickup, body):
	if body == $Ship:
		$Ship.complete_intro()
		$Earth.rotation_speed = 0.15
		$CameraController.enabled = true
		$EarthAnimation.play("IntroToStandard")
		pickup.scale = Vector3.ONE

	_on_pickup_picked_up(pickup, body)
