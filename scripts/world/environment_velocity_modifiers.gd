extends RefCounted

## Ordered, transient body-local modifiers; no world, combat or save coupling.
## Callables may edit velocity only. They must not move/slide the body themselves.
var _entries: Dictionary = {}
var _sequence := 0
var _added := Vector3.ZERO
var _surviving := Vector3.ZERO
var _last_velocity := Vector3.INF


func register_modifier(id: StringName, owner: Node, modifier: Callable, order: int = 0) -> bool:
	if id.is_empty() or not is_instance_valid(owner) or not modifier.is_valid():
		return false
	clear_modifier(id)
	var cleanup := func() -> void: clear_modifier(id)
	owner.tree_exiting.connect(cleanup, CONNECT_ONE_SHOT)
	_entries[id] = {"owner": weakref(owner), "modifier": modifier, "order": order,
		"sequence": _sequence, "cleanup": cleanup}
	_sequence += 1
	return true


func clear_modifier(id: StringName) -> void:
	if not _entries.has(id):
		return
	var entry: Dictionary = _entries[id]
	var owner: Node = entry.owner.get_ref()
	if is_instance_valid(owner) and owner.tree_exiting.is_connected(entry.cleanup):
		owner.tree_exiting.disconnect(entry.cleanup)
	_entries.erase(id)


func clear_all() -> void:
	for id: StringName in _entries.keys():
		clear_modifier(id)


func begin_step(body: CharacterBody3D) -> void:
	# The movement controllers accelerate from last frame's collision velocity.
	# Remove only our surviving contribution, not the creature's own impulses.
	# An external velocity reset (teleport, combat/recovery) invalidates the debt.
	if not _surviving.is_zero_approx() and body.velocity.is_equal_approx(_last_velocity):
		body.velocity -= _surviving
	_surviving = Vector3.ZERO
	_added = Vector3.ZERO


func apply(body: CharacterBody3D, delta: float) -> void:
	var ordered: Array = _entries.keys()
	ordered.sort_custom(func(a: StringName, b: StringName) -> bool:
		var left: Dictionary = _entries[a]
		var right: Dictionary = _entries[b]
		return int(left.order) < int(right.order) if left.order != right.order else int(left.sequence) < int(right.sequence))
	var before := body.velocity
	var before_position := body.position
	for id: StringName in ordered:
		if not _entries.has(id):
			continue # An earlier callback may unregister a later one.
		var entry: Dictionary = _entries[id]
		if not is_instance_valid(entry.owner.get_ref()) or not (entry.modifier as Callable).is_valid():
			clear_modifier(id)
			continue
		(entry.modifier as Callable).call(body, delta)
	_added = body.velocity - before if body.position.is_equal_approx(before_position) else Vector3.ZERO


func after_slide(body: CharacterBody3D, discarded: bool = false) -> void:
	_surviving = Vector3.ZERO if discarded else _added
	# Only remove next frame what survived collision response. Subtracting the
	# original blocked wind would otherwise kick a resting body away from a wall.
	if not _surviving.is_zero_approx():
		for index in body.get_slide_collision_count():
			var normal := body.get_slide_collision(index).get_normal()
			if _surviving.dot(normal) < 0.0:
				_surviving = _surviving.slide(normal)
	_last_velocity = body.velocity
