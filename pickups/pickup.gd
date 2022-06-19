extends Node3D
class_name Pickup

signal picked_up(pickup: Pickup, body: Node3D)
signal collided(pickup: Pickup, body: Node3D)

enum PickupState {READY_TO_PICKUP, ATTACHING, ATTACHED}

var state: PickupState = PickupState.READY_TO_PICKUP

@export var pickup_hitbox_radius: float:
	get:
		var hitbox_shape = $PickupArea/PickupHitbox.shape as SphereShape3D
		if not hitbox_shape:
			push_warning("Pickup hitbox was not a SphereShape3D")
			return 1.0

		return hitbox_shape.radius
	set(new_radius):
		var new_hitbox = SphereShape3D.new()
		new_hitbox.radius = new_radius
		$PickupArea/PickupHitbox.shape = new_hitbox


@onready var time = 0.0

func _process(delta):
	match state:
		PickupState.READY_TO_PICKUP:
			time += delta
			$MeshOffset.transform.origin.y = cos(time * 2.5) * 0.02
			$MeshOffset.rotate_y(delta * 1.25)
		_:
			var target = Transform3D.IDENTITY
			$MeshOffset.transform = $MeshOffset.transform.sphere_interpolate_with(Transform3D.IDENTITY, 0.25)


func attach(new_parent: Node, new_local_position: Vector3 = Vector3.ZERO):
	if state != PickupState.READY_TO_PICKUP:
		return

	state = PickupState.ATTACHING

	call_deferred("attach_to_new_parent", new_parent, new_local_position)

	$PickupArea.set_deferred("monitoring", false)
	await get_tree().create_timer(0.5).timeout # Wait before enabling collision

	state = PickupState.ATTACHED
	$CollisionArea.set_deferred("monitoring", true)

func attach_to_new_parent(new_parent: Node, new_local_position: Vector3 = Vector3.ZERO):
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	self.position = new_local_position
	new_parent.add_child(self)

func _on_pickup_area_body_entered(body: Node3D):
	if state == PickupState.READY_TO_PICKUP:
		emit_signal("picked_up", self, body)

func _on_collision_area_body_entered(body: Node3D):
	if state == PickupState.ATTACHED:
		emit_signal("collided", self, body)
