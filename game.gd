extends Node
class_name Game

signal game_over(cause: GameOver.GameOverCause, score: int)

@export
var pickup_scene: PackedScene

var next_pickup_hemisphere = 0

var attached_pickup_followers: Array[PathFollow3D] = []

var score = 0

var fuzzy_distance = 3
var max_distance = 8

var game_over_triggered = false

var ship_smoke_points: CurveXYZTexture
var ship_smoke_normals: CurveXYZTexture

func _ready():
	$ShipPath.curve.clear_points()

	ship_smoke_points = CurveXYZTexture.new()
	ship_smoke_points.width = 32
	ship_smoke_points.curve_x = Curve.new()
	ship_smoke_points.curve_y = Curve.new()
	ship_smoke_points.curve_z = Curve.new()
	ship_smoke_points.curve_x.add_point(Vector2.ZERO)
	ship_smoke_points.curve_y.add_point(Vector2.ZERO)
	ship_smoke_points.curve_z.add_point(Vector2.ZERO)

	ship_smoke_normals = CurveXYZTexture.new()
	ship_smoke_normals.width = 32
	ship_smoke_normals.curve_x = Curve.new()
	ship_smoke_normals.curve_y = Curve.new()
	ship_smoke_normals.curve_z = Curve.new()
	ship_smoke_normals.curve_x.add_point(Vector2.ZERO)
	ship_smoke_normals.curve_y.add_point(Vector2.ZERO)
	ship_smoke_normals.curve_z.add_point(Vector2.ZERO)

	$ShipSmoke.emitting = false
	$ShipSmoke.global_transform.origin = Vector3.ZERO
	$ShipSmoke.rotation = Vector3.ZERO
	$ShipSmoke.process_material.emission_shape = ParticlesMaterial.EMISSION_SHAPE_DIRECTED_POINTS
	$ShipSmoke.process_material.emission_point_texture = ship_smoke_points
	$ShipSmoke.process_material.emission_normal_texture = ship_smoke_normals

	$CameraController.set_focus($Ship)

	$Earth.rotation_speed = 0

func _process(delta):
	var smoke_emission_point = $Ship.get_smoke_position()
	var smoke_emission_normal = (smoke_emission_point - $Ship.global_transform.origin).normalized()
	var rotated_smoke_emission_normal = Quaternion(Vector3.FORWARD, PI / 2) * smoke_emission_normal

	set_ship_smoke_point(smoke_emission_point, rotated_smoke_emission_normal)
	$ShipSmoke.emitting = $Ship.is_thrusting()

	if $Ship.is_thrusting():
		if not $ShipThrustSound.playing:
			$ShipThrustSound.play()
		$ShipThrustSound.volume_db = clamp($ShipThrustSound.volume_db + (200 * delta), -30, -10)
	else:
		$ShipThrustSound.volume_db = clamp($ShipThrustSound.volume_db - (300 * delta), -80, -10)
		if $ShipThrustSound.volume_db <= -80 && $ShipThrustSound.playing:
			$ShipThrustSound.stop()

func set_ship_smoke_point(position: Vector3, normal: Vector3):
	ship_smoke_points.curve_x.set_point_value(0, position.x)
	ship_smoke_points.curve_y.set_point_value(0, position.y)
	ship_smoke_points.curve_z.set_point_value(0, position.z)

	ship_smoke_normals.curve_x.set_point_value(0, normal.x)
	ship_smoke_normals.curve_y.set_point_value(0, normal.y)
	ship_smoke_normals.curve_z.set_point_value(0, normal.z)

func _physics_process(_delta):
	update_ship_curve()

	if get_fuzziness() >= 1.0:
		trigger_game_over(GameOver.GameOverCause.LOST_SIGNAL)

func update_ship_curve():
	var ship_curve = $ShipPath.curve
	ship_curve.add_point($Ship.get_attachment_position())
	var ship_curve_length = ship_curve.get_baked_length()

	for i in range(attached_pickup_followers.size()):
		var follow = attached_pickup_followers[i]
		follow.offset = ship_curve_length - (1.0 + (i * 0.5))

	var max_curve_length = 3.0 + (attached_pickup_followers.size() * 0.5)
	var removed_points = 0
	while true:
		if ship_curve.get_baked_length() <= max_curve_length:
			break
		if removed_points >= 10:
			break

		ship_curve.remove_point(0)
		removed_points += 1

func trigger_game_over(cause: GameOver.GameOverCause):
	if game_over_triggered:
		return

	game_over.emit(cause, score)
	$Ship.crash()
	$MusicPlayer.stop()
	$CameraController.enabled = false
	$ShipCrashSoundController.play_crash_sound(cause, $Ship.linear_velocity.length())
	game_over_triggered = true

func _on_pickup_collided(_pickup, body):
	if body == $Ship and not $Ship.is_crashed():
		trigger_game_over(GameOver.GameOverCause.CRASHED_BOX)


func _on_pickup_picked_up(pickup, body):
	if body == $Ship and not $Ship.is_crashed():
		score += 1
		$BoxCollectSound.play()

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
		$IntroAnimation.play("IntroToStandard")
		pickup.scale = Vector3.ONE

	_on_pickup_picked_up(pickup, body)

func _on_ship_crashed_into_planet(_planet):
	trigger_game_over(GameOver.GameOverCause.CRASHED_PLANET)

func get_fuzziness() -> float:
	var min_pos = Vector3.ZERO
	var max_pos = Vector3.ZERO

	var planet_nodes = get_tree().get_nodes_in_group("planets")
	for node in planet_nodes:
		var planet := node as Planet
		if not planet:
			push_warning("Node in 'planets' group is not type Planet")
			continue

		if min_pos == Vector3.ZERO:
			min_pos = planet.position
		if max_pos == Vector3.ZERO:
			max_pos = planet.position

		var node_pos = planet.position
		min_pos = Vector3(min(min_pos.x, node_pos.x - planet.radius), min(min_pos.y, node_pos.y - planet.radius), min(min_pos.z, node_pos.z - planet.radius))
		max_pos = Vector3(max(max_pos.x, node_pos.x + planet.radius), max(max_pos.y, node_pos.y + planet.radius), max(max_pos.z, node_pos.z + planet.radius))

	var box = AABB(min_pos, max_pos - min_pos)
	var distance = distance_to_box(box, $Ship.global_transform.origin)

	if distance >= max_distance:
		return 1.0
	elif distance <= fuzzy_distance:
		return 0.0
	else:
		return (distance - fuzzy_distance) / (max_distance - distance)

func distance_to_box(box: AABB, position: Vector3) -> float:
	var box_center = box.position + (box.size / 2)
	var p = position - box_center
	var r = box.size / 2
	var dx = max(abs(p.x) - r.x, 0)
	var dy = max(abs(p.y) - r.y, 0)
	var dz = max(abs(p.z) - r.z, 0)
	return Vector3(dx, dy, dz).length()
