extends RigidDynamicBody3D

signal crashed_into_planet(planet: Planet)

@export
var thrust_force = 2

@export
var gravity_strength = 1.3

@export
var rotation_force = 25 * PI / 360

var current_thrust_strength: float = 0.0

enum ShipState {INTRO, STANDARD, CRASHED}

var ship_state = ShipState.INTRO

@export
var intro_lock_duration = 1

@export
var intro_ramp_thrust_duration = 0.5

var intro_thrust_force = 0

var intro_lock_remaining = intro_lock_duration

func _physics_process(delta):
	match ship_state:
		ShipState.INTRO:
			physics_process_intro(delta)
			return
		ShipState.CRASHED:
			return
		ShipState.STANDARD:
			pass

	var thrust_strength = update_current_thrust_strength()
	apply_central_force(Vector3(0, thrust_force * thrust_strength, 0) * quaternion.inverse())

	if Input.is_action_pressed("rotate_left"):
		apply_torque(Vector3(0, 0, rotation_force))
	if Input.is_action_pressed("rotate_right"):
		apply_torque(Vector3(0, 0, -rotation_force))

func physics_process_intro(delta: float):
	var thrust_strength = update_current_thrust_strength()
	if thrust_strength > 0:
		if intro_lock_remaining > 0:
			intro_lock_remaining -= delta * thrust_strength
		else:
			apply_central_force(Vector3(0, thrust_force * thrust_strength, 0))
	else:
		if intro_lock_remaining > 0:
			intro_lock_remaining = intro_lock_duration

	if intro_lock_remaining <= 0:
		if Input.is_action_pressed("rotate_left"):
			apply_torque(Vector3(0, 0, rotation_force))
		if Input.is_action_pressed("rotate_right"):
			apply_torque(Vector3(0, 0, -rotation_force))

		if intro_thrust_force < thrust_force:
			intro_thrust_force += thrust_force * delta * intro_ramp_thrust_duration
		intro_thrust_force = min(thrust_force, intro_thrust_force)

func update_current_thrust_strength() -> float:
	if ship_state == ShipState.CRASHED:
		return current_thrust_strength

	current_thrust_strength = Input.get_action_strength("thrust")
	if current_thrust_strength <= 0.01:
		current_thrust_strength = 0.0
	return current_thrust_strength

func _on_gravity_attraction(attractor: GravityAttractor):
	match ship_state:
		ShipState.INTRO:
			return
		ShipState.CRASHED:
			return
		ShipState.STANDARD:
			pass

	# Apply gravity linearly based on the distance to the surface of the attractor
	var vector = attractor.global_transform.origin - global_transform.origin
	var distance_to_center = vector.length()
	var min_strength = attractor.radius + 2 # Apply gravity starting 2 units away from the surface
	var max_strength = attractor.radius + 0.5 # Gravity is strongest 0.5 units away from the surface
	var gravity_percent = clamp(1 - ((distance_to_center - max_strength) / (min_strength - max_strength)), 0.0, 1.0)
	var gravity_force = vector.normalized() * gravity_strength * attractor.gravity_mass * gravity_percent
	apply_central_force(gravity_force)



func get_attachment_transform() -> Transform3D:
	match ship_state:
		ShipState.CRASHED:
			# When crashed, attach based on the attachment point's rotation.
			# This gives a better "tumbling uncontrollably" look
			return $AttachmentPoint.global_transform
		_:
			# Normally, attach based on the attachment point's position but
			# rotate to match the ship's velocity
			var attachment_point = $AttachmentPoint.global_transform.origin
			var target = linear_velocity if linear_velocity != Vector3.ZERO else Vector3.UP
			return Transform3D(Basis.IDENTITY.looking_at(target, Vector3.FORWARD) * Basis.from_euler(Vector3(PI / 2, PI, 0)), attachment_point)

func get_smoke_position() -> Vector3:
	return $SmokePoint.global_transform.origin

func is_thrusting() -> bool:
	return current_thrust_strength > 0.0

func is_crashed() -> bool:
	return ship_state == ShipState.CRASHED

func complete_intro():
	ship_state = ShipState.STANDARD

func crash():
	ship_state = ShipState.CRASHED
	current_thrust_strength = 0
	angular_damp = 0

# NOTE: This handles planetary collisions. Pickup collisions are handled in `Game`/`Pickup`
func _on_ship_body_entered(body):
	match ship_state:
		ShipState.INTRO:
			return
		ShipState.CRASHED:
			return
		ShipState.STANDARD:
			pass

	var planet = body as Planet
	if planet:
		crashed_into_planet.emit(planet)
