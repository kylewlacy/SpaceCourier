extends Node3D
class_name Pickup

signal picked_up(pickup: Pickup, body: Node3D)
signal collided(pickup: Pickup, body: Node3D)

enum PickupState {READY_TO_PICKUP, ATTACHED}

var state: PickupState = PickupState.READY_TO_PICKUP

func attach(new_parent: Node, new_local_position: Vector3 = Vector3.ZERO):
	if state != PickupState.READY_TO_PICKUP:
		return

	state = PickupState.ATTACHED

	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	self.position = new_local_position
	new_parent.add_child(self)

	$PickupArea.set_deferred("monitoring", false)
	$CollisionArea.set_deferred("monitoring", true)

func _on_pickup_area_body_entered(body: Node3D):
	if state == PickupState.READY_TO_PICKUP:
		emit_signal("picked_up", self, body)

func _on_collision_area_body_entered(body: Node3D):
	if state == PickupState.ATTACHED:
		emit_signal("collided", self, body)
