extends Node

func _on_pickup_collided(_pickup, body):
	if body == $Ship:
		print("Collided with ship")


func _on_pickup_picked_up(pickup, body):
	if body == $Ship:
		$Ship.pick_up(pickup)
