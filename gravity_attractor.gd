extends Node3D
class_name GravityAttractor

@export
var gravity_mass = 1

func _physics_process(_delta):
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "gravity_attraction", "_on_gravity_attraction", self)
