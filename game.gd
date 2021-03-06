extends Node
class_name Game

signal game_over(cause: GameOver.GameOverCause, score: int)

@export
var pickup_scene: PackedScene

var next_pickup_hemisphere = 0

var attached_pickup_followers: Array[Node3D] = []

var score = 0

var fuzzy_distance = 3
var max_distance = 8

var game_over_triggered = false

@onready
var ship_smoke_emission_initial_velocity_min = $ShipSmoke.initial_velocity_min

@onready
var ship_smoke_emission_initial_velocity_max = $ShipSmoke.initial_velocity_min

@onready
var ship_trail = TrailPath3D.new()

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
	var smoke_emission_velocity_factor = 0.5 + ($Ship.current_thrust_strength * 0.5)

	$ShipSmoke.emission_points = PackedVector3Array([smoke_emission_point])
	$ShipSmoke.emission_normals = PackedVector3Array([rotated_smoke_emission_normal])
	$ShipSmoke.emitting = $Ship.is_thrusting()
	$ShipSmoke.initial_velocity_min = ship_smoke_emission_initial_velocity_min * smoke_emission_velocity_factor
	$ShipSmoke.initial_velocity_max = ship_smoke_emission_initial_velocity_max * smoke_emission_velocity_factor

	var current_volume = db2linear($ShipThrustSound.volume_db)
	var target_volume = $Ship.current_thrust_strength * 0.3
	if not $ShipThrustSound.playing:
		current_volume = 0.0
	var new_volume = lerp(current_volume, target_volume, 0.1)

	$ShipThrustSound.volume_db = linear2db(new_volume)
	if new_volume > 0 and not $ShipThrustSound.playing:
		$ShipThrustSound.play()
	elif new_volume <= 0 and $ShipThrustSound.playing:
		$ShipThrustSound.stop()

func _physics_process(_delta):
	update_ship_curve()

	if get_fuzziness() >= 1.0:
		trigger_game_over(GameOver.GameOverCause.LOST_SIGNAL)

func update_ship_curve():
	ship_trail.append($Ship.get_attachment_transform())

	var for_each_step = func(transform: Transform3D, index: int):
		var follow = attached_pickup_followers[index]
		follow.global_transform.basis = follow.global_transform.basis.slerp(transform.basis, 0.1)
		follow.global_transform.origin = follow.global_transform.origin.slerp(transform.origin, 0.1)
	var step_result = ship_trail.for_each_step(0.5, 1.0, attached_pickup_followers.size(), TrailPath3D.Direction.END_TO_START, for_each_step)

	if step_result.exit_result == TrailPath3D.ExitResult.COMPLETE:
		# Remove excess points from the trail to keep memory usage down. We keep
		# 200 extra points past what we currently need so that, if another
		# pickup is added, it should have enough extra space
		ship_trail.clean(TrailPath3D.Direction.END_TO_START, step_result.points_stepped + 200, 100)

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

		var follower = Node3D.new()
		follower.global_transform.origin = pickup.global_transform.origin
		$ShipPickups.add_child(follower)
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

		var intro_tween = create_tween().set_parallel(true)
		intro_tween.tween_property($CameraController, "fov", 50.0, 3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		intro_tween.tween_property($Earth, "rotation:x", 0.0, 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		intro_tween.tween_property($Earth, "rotation:z", 0.0, 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		intro_tween.tween_property($Earth, "radius", 1.108, 2.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		intro_tween.tween_property($Earth, "rotation_speed", 0.15, 5)
		$CameraController.enabled = true
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
