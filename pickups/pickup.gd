extends Node3D
class_name Pickup

signal picked_up(pickup: Pickup, body: Node3D)
signal collided(pickup: Pickup, body: Node3D)

enum PickupState {READY_TO_PICKUP, ATTACHING, ATTACHED}

var state: PickupState = PickupState.READY_TO_PICKUP

func attach(new_parent: Node, new_local_position: Vector3 = Vector3.ZERO):
	if state != PickupState.READY_TO_PICKUP:
		return

	state = PickupState.ATTACHING

	call_deferred("attach_to_new_parent", new_parent, new_local_position)

	$PickupArea.set_deferred("monitoring", false)
	await get_tree().create_timer(0.5).timeout # Wait before enabling collision

	print("Completed attachment")
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
