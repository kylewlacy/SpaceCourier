extends Object
class_name TrailPath3D

var transforms = PackedVector3Array()

enum Direction {START_TO_END, END_TO_START}
enum ExitResult {
	## No points have been added to the trail
	EMPTY,

	## Reached last points in the trail before visiting any points (all points before `start_distance`)
	EARLY_INITIAL_EXIT,

	## Reached last points in the trail before reaching `max_count`
	EARLY_EXIT,

	## Visited `max_count` points
	COMPLETE,
}

class StepResult:
	## Total number of points which were visited with `f`
	@export var count: int = 0

	## Total number of points stepped before reaching `start_distance`
	@export var points_skipped: int = 0

	## Total number of points which stepped after reaching `start_distanced`
	@export var points_walked: int = 0

	## Total number of points stepped (before or after `start_distance)
	@export var points_stepped: int:
		get:
			return points_skipped + points_walked

	## Total distance skipped before reaching `start_distance`
	@export var distance_skipped: float = 0.0

	## Total distance covered for visited points
	@export var distance_walked: float = 0.0

	## Total distance covered while walking points (skipped and visited)
	@export var distance_stepped: float:
		get:
			return distance_skipped + distance_walked

	## Previous transform accessed
	@export var last_transform: Transform3D = Transform3D.IDENTITY

	## Current transform being accessed before exiting
	@export var transform: Transform3D = Transform3D.IDENTITY

	## The reason for exiting
	@export var exit_result: ExitResult = ExitResult.EMPTY

	func debug_info() -> String:
		var reason = ""
		match exit_result:
			ExitResult.EMPTY:
				reason = "empty"
			ExitResult.EARLY_INITIAL_EXIT:
				reason = "early initial exit"
			ExitResult.EARLY_EXIT:
				reason = "early exit"
			ExitResult.COMPLETE:
				reason = "complete"

		return "finished walking %s points (%s): stepped %s + %s points (%s + %s distance)" % [count, reason, points_skipped, points_walked, distance_skipped, distance_walked]

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
	var state = StepResult.new()

	if size() <= 0 || max_count <= 0:
		return state

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
			last_i = -1

	var distance = 0.0
	state.last_transform = get_transform(i)

	while distance < start_distance:
		state.transform = get_transform(i)
		var step_distance = state.last_transform.origin.distance_to(state.transform.origin)
		distance += step_distance
		state.distance_skipped += step_distance

		i += step
		if i == last_i:
			state.exit_result = ExitResult.EARLY_INITIAL_EXIT
			return state

		state.last_transform = state.transform
		state.points_skipped += 1

	f.call(state.last_transform, state.count)
	state.count += 1

	while state.count < max_count:
		distance = -1.0
		while distance < space_between_points:
			if distance < 0.0:
				distance = 0.0

			state.transform = get_transform(i)
			var step_distance = state.last_transform.origin.distance_to(state.transform.origin)
			distance += step_distance
			state.distance_walked += step_distance

			i += step
			if i == last_i:
				state.exit_result = ExitResult.EARLY_EXIT
				return state

			state.points_walked += 1
			state.last_transform = state.transform

		f.call(state.last_transform, state.count)
		state.count += 1

	state.exit_result = ExitResult.COMPLETE
	return state

func clean(direction: Direction, after: int, threshold: int) -> int:
	after = max(after, 0)
	var starting_size = size()

	var to_remove = size() - after
	if to_remove < max(threshold, 1):
		return 0

	match direction:
		Direction.START_TO_END:
			transforms.resize(after * 4)
		Direction.END_TO_START:
			transforms = transforms.slice(to_remove * 4)
			pass

	return starting_size - size()
