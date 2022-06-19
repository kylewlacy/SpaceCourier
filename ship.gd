extends RigidDynamicBody3D

signal crashed_into_planet(planet: Planet)

@export
var thrust_force = 2

@export
var gravity_pow = 2.0

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

	var vector = attractor.global_transform.origin - global_transform.origin
	var distance = vector.length()
	var gravity_force = vector.normalized() * (attractor.gravity_mass / pow(distance, gravity_pow))
	apply_central_force(gravity_force)



func get_attachment_transform() -> Transform3D:
	return $AttachmentPoint.global_transform

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
