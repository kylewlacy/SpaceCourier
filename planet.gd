@tool
extends Node3D

@export
var radius: float = 1.0:
	get:
		return scale.x
	set(new_radius):
		scale.x = new_radius
		scale.y = new_radius
		scale.z = new_radius

@export
var mass: float = 1.0:
	get:
		return $GravityAttractor.gravity_mass
	set(new_mass):
		if not $GravityAttractor:
			return

		$GravityAttractor.gravity_mass = new_mass

