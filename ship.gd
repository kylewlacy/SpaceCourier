extends RigidDynamicBody3D

@export
var thrust_force = 2

@export
var gravity_pow = 2.0

@export
var rotation_force = 25 * PI / 360

var ship_is_thrusting: bool = false

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

	if Input.is_action_pressed("thrust"):
		apply_central_force(Vector3(0, thrust_force, 0) * quaternion.inverse())
		ship_is_thrusting = true
	else:
		ship_is_thrusting = false

	if Input.is_action_pressed("rotate_left"):
		apply_torque(Vector3(0, 0, rotation_force))
	if Input.is_action_pressed("rotate_right"):
		apply_torque(Vector3(0, 0, -rotation_force))

func physics_process_intro(delta: float):
	if Input.is_action_pressed("thrust"):
		ship_is_thrusting = true
		if intro_lock_remaining > 0:
			intro_lock_remaining -= delta
		else:
			apply_central_force(Vector3(0, thrust_force, 0))
	else:
		ship_is_thrusting = false
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


func get_attachment_position() -> Vector3:
	return $AttachmentPoint.global_transform.origin

func get_smoke_position() -> Vector3:
	return $SmokePoint.global_transform.origin

func is_thrusting() -> bool:
	return ship_is_thrusting

func complete_intro():
	ship_state = ShipState.STANDARD

func crashed():
	ship_state = ShipState.CRASHED
	ship_is_thrusting = false
