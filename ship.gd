extends RigidDynamicBody3D

@export
var thrust_force = 2

@export
var gravity_pow = 2.0

@export
var rotation_force = 25 * PI / 360

func _physics_process(_delta):
	if Input.is_action_pressed("thrust"):
		apply_central_force(Vector3(0, thrust_force, 0) * quaternion.inverse())

	if Input.is_action_pressed("rotate_left"):
		apply_torque(Vector3(0, 0, rotation_force))
	if Input.is_action_pressed("rotate_right"):
		apply_torque(Vector3(0, 0, -rotation_force))

func _on_gravity_attraction(attractor: GravityAttractor):
	var vector = attractor.global_transform.origin - global_transform.origin
	var distance = vector.length()
	var gravity_force = vector.normalized() * (attractor.gravity_mass / pow(distance, gravity_pow))
	apply_central_force(gravity_force)

func pick_up(pickup: Pickup):
	print("Picked up")
	pickup.attach($Pickups)

func get_attachment_position() -> Vector3:
	return $AttachmentPoint.global_transform.origin
