extends RefCounted

## Identical field queries on every peer and for the visible foam. Overlapping
## routes select one authored current; they never accidentally add strength.
var _currents: Array = []
var _flags: RefCounted


func _init(config: Dictionary = {}, flags: RefCounted = null) -> void:
	# Return shortcuts author the payoff separately from the current geometry so
	# world planning can describe ramps and current reductions in one list. Bind
	# only the reduction rows here, at the one field shared by human swimming and
	# mounted swimming. The live flag store is retained below, so a just-earned
	# flag and a flag restored from a completed save take the same path.
	_currents = bind_return_shortcuts(config).get("currents", []).duplicate(true)
	_flags = flags


static func bind_return_shortcuts(config: Dictionary) -> Dictionary:
	var bound := config.duplicate(true)
	var currents: Array = bound.get("currents", [])
	for raw: Variant in bound.get("return_shortcuts", []):
		if not raw is Dictionary:
			continue
		var shortcut := raw as Dictionary
		if str(shortcut.get("kind", "")) != "current_reduction":
			continue
		var route_id := str(shortcut.get("route_id", ""))
		var flag := str(shortcut.get("unlock_flag", ""))
		if route_id.is_empty() or flag.is_empty() or not shortcut.has("strength_after_unlock_m_s"):
			continue
		for current: Dictionary in currents:
			# Exact route identity prevents one shortcut from changing a sibling
			# direct/sheltered route with a similar prefix.
			if str(current.get("route_id", "")) != route_id:
				continue
			current["reduction_unlock_flag"] = flag
			current["strength_after_unlock_m_s"] = float(shortcut.strength_after_unlock_m_s)
	return bound


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
		var required := str(current.get("required_unlock_flag", ""))
		var closed: bool = _flags != null and not required.is_empty() and not bool(_flags.has(required))
		var strength := float(current.get("closed_strength_m_s", current.get("strength_m_s", 0.0))) if closed else float(current.get("strength_m_s", 0.0))
		var reduction_flag := str(current.get("reduction_unlock_flag", ""))
		if _flags != null and not reduction_flag.is_empty() and bool(_flags.has(reduction_flag)):
			strength = float(current.get("strength_after_unlock_m_s", strength))
		velocity *= maxf(0.0, strength) * influence
		if liberated:
			velocity *= clampf(float(current.get("post_liberation_strength_multiplier", 1.0)), 0.0, 1.0)
		best_priority = priority
		best_distance = distance
		result = {"id": str(current.get("id", "")), "velocity": velocity, "influence": influence}
	return result
