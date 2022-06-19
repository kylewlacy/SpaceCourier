extends Object
class_name TrailPath3D

var transforms = PackedVector3Array()

enum Direction {START_TO_END, END_TO_START}

func append(transform: Transform3D):
	transforms.append(transform.origin)
	transforms.append(transform.basis.x)
	transforms.append(transform.basis.y)
	transforms.append(transform.basis.z)

@warning_ignore(integer_division)
func size() -> int:
	return transforms.size() / 4

func get_transform(i: int) -> Transform3D:
	var origin = transforms[i * 4]
	var basis_x = transforms[i * 4 + 1]
	var basis_y = transforms[i * 4 + 2]
	var basis_z = transforms[i * 4 + 3]
	return Transform3D(basis_x, basis_y, basis_z, origin)

func for_each_step(space_between_points: float, start_distance: float, max_count: int, direction: Direction, f: Callable):
	var _dbg_initial_steps = 0
	var _dbg_trail_steps = 0

	var count = 0

	var i: int
	var step: int
	var last_i: int
	match direction:
		Direction.START_TO_END:
			i = 0
			step = 1
			last_i = min(max_count, size())
		Direction.END_TO_START:
			i = size() - 1
			step = -1
			last_i = 0

	var distance = 0.0
	var last_transform = get_transform(i)

	while distance < start_distance:
		var transform = get_transform(i)
		distance += last_transform.origin.distance_to(transform.origin)

		i += step
		_dbg_initial_steps += 1
		if i == last_i:
			print("early initial exit: %s + %s steps" % [_dbg_initial_steps, _dbg_trail_steps])
			return

		last_transform = transform

	f.call(last_transform)
	count += 1

	while count < max_count:
		distance = -1.0
		while distance < space_between_points:
			if distance < 0.0:
				distance = 0.0

			var transform = get_transform(i)
			distance += last_transform.origin.distance_to(transform.origin)

			i += step
			_dbg_trail_steps += 1
			if i == last_i:
				print("early exit: %s + %s steps" % [_dbg_initial_steps, _dbg_trail_steps])
				return

			last_transform = transform

		f.call(last_transform)
		count += 1

	print("finished: %s + %s steps" % [_dbg_initial_steps, _dbg_trail_steps])
