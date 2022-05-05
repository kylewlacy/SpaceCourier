@tool
extends Node3D
class_name Planet

@export
var rotation_speed: float = 0.15

@export
var radius: float = 1.0:
	get:
		return scale.x
	set(new_radius):
		scale.x = new_radius
		scale.y = new_radius
		scale.z = new_radius


@export
var material: Material:
	get:
		return $Mesh.get_active_material(0)
	set(new_material):
		$Mesh.set_surface_override_material(0, new_material)

@export
var mass: float = 1.0:
	get:
		return $GravityAttractor.gravity_mass
	set(new_mass):
		if not $GravityAttractor:
			return

		$GravityAttractor.gravity_mass = new_mass

func _process(_delta):
	if Engine.is_editor_hint():
		return

	rotate_y(_delta * rotation_speed)
