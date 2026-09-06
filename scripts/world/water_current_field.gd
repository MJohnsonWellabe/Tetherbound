extends RefCounted

## Identical field queries on every peer and for the visible foam. Overlapping
## routes select one authored current; they never accidentally add strength.
var _currents: Array = []


func _init(config: Dictionary = {}) -> void:
	_currents = config.get("currents", []).duplicate(true)


func sample(position: Vector3, liberated: bool = false) -> Dictionary:
	var result := {"id": "", "velocity": Vector3.ZERO, "influence": 0.0}
	if not position.is_finite():
		return result
	var best_priority := -2147483648
	var best_distance := INF
	for current: Dictionary in _currents:
		var points: Array = current.get("polyline", [])
		var distance := INF
		for index in range(1, points.size()):
			var a := Vector2(float(points[index - 1][0]), float(points[index - 1][2]))
			var b := Vector2(float(points[index][0]), float(points[index][2]))
			var point := Vector2(position.x, position.z)
			var segment := b - a
			var t := 0.0 if segment.length_squared() == 0.0 else clampf((point - a).dot(segment) / segment.length_squared(), 0.0, 1.0)
			distance = minf(distance, point.distance_to(a + segment * t))
		var radius := maxf(0.0, float(current.get("width_m", 0.0)) * 0.5)
		if distance >= radius:
			continue
		var priority := int(current.get("priority", 0))
		if priority < best_priority or (priority == best_priority and distance >= best_distance):
			continue
		var blend := clampf(float(current.get("edge_blend_m", 0.0)), 0.0, radius)
		var influence := 1.0 if blend <= 0.0 else 1.0 - smoothstep(radius - blend, radius, distance)
		var direction: Array = current.get("flow_direction_xz", [0.0, 0.0])
		var velocity := Vector3(float(direction[0]), 0.0, float(direction[1])).normalized()
		velocity *= maxf(0.0, float(current.get("strength_m_s", 0.0))) * influence
		if liberated:
			velocity *= clampf(float(current.get("post_liberation_strength_multiplier", 1.0)), 0.0, 1.0)
		best_priority = priority
		best_distance = distance
		result = {"id": str(current.get("id", "")), "velocity": velocity, "influence": influence}
	return result
