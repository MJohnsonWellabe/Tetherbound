extends "res://tests/smoke_village_hall_redesign.gd"

## Location witness only: inherited disclosed post-opening fixture and one
## initial farmhouse placement, then actual controller travel on production
## floor/collision. No relic grant, collider removal, mid-route pose mutation,
## visual acceptance, earned M1 or cross-host state claim.
const NAV := preload("res://tests/helpers/opening_geometry_navigator.gd")

func _after_hall_arrival(_hall: Node3D) -> bool:
	var shrine := _world.get_node_or_null("MeadowsRealmHeartShrine") as Node3D
	if shrine == null:
		return _refuse("legacy Meadows circle is absent")
	var members: Array[Node3D] = [shrine]
	for id: String in ["cloudreach", "stormwood", "water"]:
		var slot := shrine.get_node_or_null("RelicSlot_" + id) as Node3D
		if slot == null:
			return _refuse("legacy circle lost slot " + id)
		members.append(slot)
	var centre := Vector3.ZERO
	for member: Node3D in members:
		centre += member.global_position
	centre /= 4.0
	var configured := _v((_json("res://data/config/realm_transitions.json").get("meadows_heart_shrine", {}) as Dictionary).get("position", []))
	if Vector2(centre.x, centre.z).distance_to(configured) > .01:
		return _refuse("actual circle centre differs from authored position")
	var nav := NAV.new(self, _player, _rig, _circle_stick, true)
	# Return along the installed Main Street, then leave the farmhouse frontage
	# on its east edge before the garden. These are route goals, never poses.
	var plan: Dictionary = _json(VILLAGE_CONFIG).get("road_plan", {})
	var road_start := _v(plan.get("road_start", []))
	var road_end := _v(plan.get("road_end", []))
	# The inherited outward trip already proves the actual farmhouse doorway.
	# R2's return to that same doorway invoked its containing-house departure
	# route beside the wall/lantern. Turn into the garden2m outward along the
	# installed road instead, staying outside that doorway's approach fixtures.
	var garden_turn := road_start + (road_end - road_start).normalized() * 2.0
	# The82.7m road exceeds900ticks at the production5m/s walk. Use its
	# actual midpoint as a separate goal, retaining every900tick allowance.
	for point: Vector2 in [road_end, (road_start + road_end) * .5, garden_turn, Vector2(garden_turn.x, 0)]:
		if not await _circle_walk(nav, Vector3(point.x, 0, point.y), "garden approach"):
			return false
	# Start at south; adjoining outside-ring legs avoid crossing the plinths.
	for index in [2, 3, 0, 1]:
		var member: Node3D = members[index]
		var outward := member.global_position - centre
		outward.y = 0
		outward = outward.normalized()
		var target := centre + outward * 9.2
		var height := float(_world.call("ground_height_at", target.x, target.z))
		if is_nan(height):
			return _refuse("circle approach has no production terrain")
		target.y = height
		if not await _circle_walk(nav, target, str(member.name)):
			return false
		var collision := member.get_node_or_null("ShrineCollision/CollisionShape3D") as CollisionShape3D
		var model := member.get_node_or_null("PresentationModel")
		var prompt := member.get("_prompt") as Node
		if collision == null or not collision.shape is CylinderShape3D or collision.disabled \
				or absf((collision.shape as CylinderShape3D).radius - 1.41) > .001 \
				or absf((collision.shape as CylinderShape3D).height - .62) > .001 \
				or collision.position.distance_to(Vector3(0, .31, 0)) > .001 \
				or model == null or prompt == null or not _circle_visible_mesh(model):
			return _refuse("circle model, existing collider or prompt component missing")
		var member_ground := float(_world.call("ground_height_at", member.global_position.x, member.global_position.z))
		if is_nan(member_ground) or absf(member.global_position.y - member_ground) > .01:
			return _refuse("circle plinth is not grounded at its actual terrain height")
		var gap := Vector2(_player.global_position.x - member.global_position.x, _player.global_position.z - member.global_position.z).length()
		if gap > float(member.get("interaction_radius")) or gap < 1.41:
			return _refuse("actual player is outside prompt range or inside the unchanged plinth collider")
		print("F17 LEGACY CIRCLE reached " + JSON.stringify({"member": str(member.name), "player": _coordinates(_player.global_position), "plinth": _coordinates(member.global_position), "gap": gap, "on_floor": _player.is_on_floor(), "state": str(member.call("state_for", _game)), "prompt": str(prompt.get("label")), "scope": "unchanged fresh-state prompt component; no earned relic activation"}))
	print("F17 LEGACY CIRCLE physical location PASS: all four actual grounded models/existing colliders/prompt components approached via production joypad steering, after farmhouse-road-Hall traversal. Visual and earned state remain separate.")
	return true

func _circle_walk(nav: RefCounted, target: Vector3, label: String) -> bool:
	nav.call("reset")
	var reached: bool = await nav.call("walk_to", target, 900, .25)
	_circle_stick(0, 0)
	if not reached or not _player.is_on_floor():
		return _refuse("circle controller travel failed at " + label + ": " + str(nav.call("refusal_reason")))
	return true

func _circle_stick(x: float, y: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, y]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = pair[0]
		event.axis_value = float(pair[1])
		Input.parse_input_event(event)
	Input.flush_buffered_events()

func _circle_visible_mesh(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is MeshInstance3D and child.mesh != null and child.is_visible_in_tree():
			return true
		if _circle_visible_mesh(child):
			return true
	return false

func _coordinates(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]

func _refuse(reason: String) -> bool:
	_failed = reason
	return false
