extends "res://tests/smoke_village_hall_redesign.gd"

## F17#2 physical access witness. Inherits the real farmhouse-to-Hall walk,
## then uses the same parsed joypad/look steering to approach all real slots.
## Signed meshes/state checks are structural; code-blind native judging is
## separate. No position writes are permitted after inherited initial spawn.
const ORDER := preload("res://scripts/data/biome_order.gd")


func _after_hall_arrival(hall: Node3D) -> bool:
	var expected := ORDER.ids()
	var arches := get_nodes_in_group("crossing_hall_arches")
	var pedestals := get_nodes_in_group("crossing_hall_pedestals")
	if arches.size() != expected.size() or pedestals.size() != expected.size():
		return _circuit_fail("actual Hall requires eight distinct arches and eight distinct pedestals")
	var arch_by_biome: Dictionary = {}
	var stand_by_biome: Dictionary = {}
	for pair: Array in [[arches, arch_by_biome], [pedestals, stand_by_biome]]:
		for raw: Node in pair[0]:
			var biome := str(raw.get_meta("biome", ""))
			if not raw is Node3D or raw.get_parent() != hall or not expected.has(biome) or pair[1].has(biome):
				return _circuit_fail("unknown, duplicate or foreign Hall slot: " + biome)
			var marker := raw.get_node_or_null("Approach") as Marker3D
			if marker == null or not marker.is_visible_in_tree() or not _has_visible_model(raw):
				return _circuit_fail("real installed model/approach is missing: " + biome)
			var signed := false
			for child: Node in raw.get_children():
				if child is Label3D and child.is_visible_in_tree() and child.text == ORDER.display_name(biome):
					signed = true
			if not signed:
				return _circuit_fail("actual biome sign missing: " + biome)
			pair[1][biome] = raw
	var live := 0
	var sealed := 0
	for biome: String in expected:
		var arch: Node3D = arch_by_biome[biome]
		var state := str(arch.get_meta("arch_state", ""))
		var name_sign := arch.get_node_or_null("BiomeSign") as Label3D
		var sign := arch.get_node_or_null("StateSign") as Label3D
		if name_sign == null or not name_sign.is_visible_in_tree() or name_sign.text != ORDER.display_name(biome):
			return _circuit_fail("actual biome sign missing: " + biome)
		if sign == null:
			return _circuit_fail("actual state sign node missing: " + biome)
		# One visible Sealed label conveys both identical name/state; distinct
		# Home/Locked/Open states still need their own visible canonical text.
		if sign.is_visible_in_tree() != (sign.text != name_sign.text):
			return _circuit_fail("actual state sign visibility differs from name/state deduplication: " + biome)
		if biome == "meadows":
			if state != "open" or sign.text != "Home arch":
				return _circuit_fail("home arch is not signed as home")
		elif ORDER.ids(false).has(biome):
			if state not in ["locked", "open"] or sign.text != state.capitalize():
				return _circuit_fail("live-capable arch has an incorrect state/sign: " + biome)
			live += 1
		else:
			if state != "sealed" or sign.text != "Sealed":
				return _circuit_fail("reserved arch is not visibly signed sealed: " + biome)
			sealed += 1
	if live != 3 or sealed != 4:
		return _circuit_fail("Hall does not have three live-capable and four sealed biome arches")
	var gallery_route := _gallery_route(hall, stand_by_biome)
	if gallery_route.is_empty():
		return false
	print("F17 Hall circuit structure: one home, three live-capable, four sealed signed arches; eight signed installed pedestals. Node visibility is structural, not a screenshot judgment.")
	for biome: String in expected:
		var approach := (arch_by_biome[biome] as Node3D).get_node("Approach") as Marker3D
		if not await _walk_to_marker(hall, approach, Vector3.ZERO, "arch " + biome):
			return false
	for biome: String in expected:
		var approach := (stand_by_biome[biome] as Node3D).get_node("Approach") as Marker3D
		# Derive the doorway/aisle from actual floor colliders and real Approach
		# markers; no nonexistent test-only doorway or fixed x=7/x=12 tuple.
		if not await _walk_to_target(hall, hall.to_global(gallery_route.door), Vector3.ZERO, "shrine doorway before " + biome):
			return false
		if not await _walk_to_marker(hall, approach, gallery_route.aisle, "pedestal " + biome):
			return false
	print("F17 Hall circuit physical access PASS: all eight arches and eight pedestals reached on actual collision/floor, parsed joypad/look only after inherited initial placement. No mid-route teleport, collision removal, speedup, visual/device/progression/co-op claim.")
	return true


func _walk_to_marker(hall: Node3D, marker: Marker3D, via_local: Vector3, label: String) -> bool:
	return await _walk_to_target(hall, marker.global_position, via_local, label)


func _walk_to_target(hall: Node3D, target: Vector3, via_local: Vector3, label: String) -> bool:
	var via := hall.to_global(via_local)
	_path = PackedVector2Array([_xz(), Vector2(via.x, via.z), Vector2(target.x, target.z)])
	_arcs = PackedFloat32Array([0.0])
	for index in range(1, _path.size()):
		_arcs.append(_arcs[index - 1] + _path[index - 1].distance_to(_path[index]))
	_road_from_arc = _arcs[-1] + 1.0
	_road_until_arc = -1.0
	_events = [{"arc": _arcs[-1] - 0.5, "label": label}]
	# Face the leg first, as a player would, so the walker's stall clock
	# measures blocked movement rather than a reversal turn in place.
	await _turn_to(_yaw_toward(_path[0], _path[1] if _path[0].distance_to(_path[1]) > .3 else _path[-1]))
	# End the leg on position, not arc: 2 of 5 runs ended on arc progress with
	# the body 0.85-1.02 m to the side after open-floor sidesteps. The 0.75 m
	# gate below is unchanged; this only stops the walk short of it.
	_arrive_within_m = 0.6
	await _walk()
	_arrive_within_m = 0.0
	_release_all()
	if not _failed.is_empty():
		return false
	var distance := _xz().distance_to(Vector2(target.x, target.z))
	if distance > 0.75 or not _player.is_on_floor():
		return _circuit_fail("physical approach refused at %s: distance %.3f floor %s" % [label, distance, _player.is_on_floor()])
	print("F17 Hall circuit reached %s: player=%s distance=%.3f floor=true" % [label, _player.global_position, distance])
	return true


func _turn_to(target_yaw: float) -> void:
	_release_all()
	for _frame in 240:
		var err := rad_to_deg(angle_difference(float(_rig.get("yaw")), target_yaw))
		_pad_release("look_left")
		_pad_release("look_right")
		if absf(err) < 3.0:
			break
		_pad_press("look_left" if err > 0.0 else "look_right", clampf(absf(err) / 45.0, 0.25, 1.0))
		await physics_frame
	_pad_release("look_left")
	_pad_release("look_right")
	for _frame in 20:
		await physics_frame


func _gallery_route(hall: Node3D, stands: Dictionary) -> Dictionary:
	var aisle := Vector3.ZERO
	for stand: Node3D in stands.values():
		aisle += hall.to_local((stand.get_node("Approach") as Marker3D).global_position)
	aisle /= float(stands.size())
	var floors: Array[Rect2] = []
	var recipe: Dictionary = _json("res://data/config/building_prefabs.json").get("prefabs", {}).get("crossing_hall_shell", {})
	for box: Dictionary in recipe.get("colliders", []):
		var at: Array = box.get("at", [])
		var size: Array = box.get("size", [])
		if at.size() != 3 or size.size() != 3:
			continue
		if float(size[1]) > .3 or float(at[1]) > .3 or float(size[0]) < 3.0 or float(size[2]) < 3.0:
			continue
		var extent := Vector2(float(size[0]), float(size[2]))
		floors.append(Rect2(Vector2(float(at[0]), float(at[2])) - extent * .5, extent))
	var nave := Rect2()
	var gallery := Rect2()
	for floor_rect: Rect2 in floors:
		if floor_rect.has_point(Vector2.ZERO):
			nave = floor_rect
		if floor_rect.has_point(Vector2(aisle.x, aisle.z)):
			gallery = floor_rect
	var lower := maxf(nave.position.y, gallery.position.y)
	var upper := minf(nave.end.y, gallery.end.y)
	if nave.size == Vector2.ZERO or gallery.size == Vector2.ZERO or nave == gallery \
			or absf(nave.end.x - gallery.position.x) > .05 or upper <= lower:
		_circuit_fail("actual nave/gallery collision floors do not share a supported doorway")
		return {}
	return {"door": Vector3((nave.end.x + gallery.position.x) * .5, 0, (lower + upper) * .5), "aisle": aisle}


func _has_visible_model(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is MeshInstance3D and child.mesh != null and child.is_visible_in_tree():
			return true
		if _has_visible_model(child):
			return true
	return false


func _circuit_fail(reason: String) -> bool:
	_failed = reason
	return false
