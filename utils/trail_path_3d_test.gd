extends Node3D

func _physics_process(delta):
	$Path3D/PathFollow3D.offset += delta * 5;
