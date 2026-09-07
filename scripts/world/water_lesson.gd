extends RefCounted

## Host-side observation of ordinary owner-authorized movement. A dialogue,
## arrival teleport or claimed completion cannot finish the lesson.
var _spec: Dictionary
var _start: Vector3
var _end: Vector3
var _actors: Dictionary = {}


func _init(spec: Dictionary) -> void:
	_spec = spec
	var points: Array = spec.surface_polyline
	_start = Vector3(float(points[0][0]), 0, float(points[0][2]))
	_end = Vector3(float(points[-1][0]), 0, float(points[-1][2]))


func observe(peer: int, position: Vector3, aquatic_mode: int) -> bool:
	if peer <= 0 or not position.is_finite():
		return false
	position.y = 0.0
	var radius := float(_spec.get("validation", {}).get("marker_radius_m", 8.0))
	if not _actors.has(peer):
		if position.distance_to(_start) <= radius:
			_actors[peer] = {"position": position, "distance": 0.0}
		return false
	var actor: Dictionary = _actors[peer]
	var step := position.distance_to(actor.position)
	var direction := _end - _start
	var fraction := clampf((position - _start).dot(direction) / direction.length_squared(), 0, 1)
	var from_course := position.distance_to(_start + direction * fraction)
	if step > float(_spec.get("validation", {}).get("maximum_observed_step_m", 3.0)) \
			or from_course > float(_spec.get("validation", {}).get("course_radius_m", 12.0)):
		_actors.erase(peer)
		return false
	# Forward progress only; loops and passive time cannot satisfy the distance.
	if aquatic_mode == 1:
		actor.distance = maxf(0.0, float(actor.distance) + (position - (actor.position as Vector3)).dot(direction.normalized()))
	actor.position = position
	if aquatic_mode == 0 and position.distance_to(_end) <= radius \
			and float(actor.distance) >= float(_spec.get("validation", {}).get("minimum_swim_m", 50.0)):
		_actors.erase(peer)
		return true
	return false
