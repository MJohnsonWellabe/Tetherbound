extends "res://tests/smoke_village_hall_redesign.gd"

## Literal F17#3 access witness. The original farmhouse-to-Hall leg remains
## unchanged. Then both production day/night states use parsed movement/look,
## real door prompts, collider floors and service providers. No pose writes
## occur after the inherited initial farmhouse fixture. Pixel quality is #6.
const PEOPLE_CONFIG := "res://data/config/village_npcs.json"
const HOUSE_SERVICES := {"Mira": "mira_shop", "Tam": "tam_workshop", "Bram": "bram_inn",
	"Oskar": "oskar_house", "Maren": "research_house"}
const REQUIRED_HOUSES := ["mira_shop", "tam_workshop", "bram_inn", "halda_house",
	"research_house", "oskar_house", "alder_house", "orchard_house"]


func _after_hall_arrival(_hall: Node3D) -> bool:
	var houses: Dictionary = {}
	for raw: Node in get_nodes_in_group("village_road_houses"):
		var role := str(raw.get_meta("village_role", ""))
		if not raw is Node3D or not REQUIRED_HOUSES.has(role) or houses.has(role):
			return _services_fail("unknown, repeated or nonphysical road house: " + role)
		if str(raw.get_meta("house_name", "")).is_empty():
			return _services_fail("road house has no actual household identity: " + role)
		houses[role] = raw
	if houses.size() != REQUIRED_HOUSES.size():
		return _services_fail("every one of the eight required house identities must exist exactly once")
	var people: Dictionary = {}
	var required_people: Array = HOUSE_SERVICES.keys()
	required_people.append("Halda")
	for person: String in required_people:
		var matches := _world.find_children(person, "Node3D", true, false)
		if matches.size() != 1 or not matches[0].has_method("add_prompt"):
			return _services_fail("required actual named service resident missing or duplicated: " + person)
		people[person] = matches[0]
	for role: String in REQUIRED_HOUSES:
		var building: Node3D = houses[role]
		var interior := building.get_node_or_null("Interior")
		# Source review identifies real bed/table/stock/bar/work-tool furnishing
		# in these installed interior templates. Actual instantiated geometry and
		# warm room light must be present; an empty room script is insufficient.
		if interior == null or interior.find_children("*", "MeshInstance3D", true, false).size() < 3 \
				or interior.find_children("*", "Light3D", true, false).is_empty():
			return _services_fail("house lacks actual lived-in room furnishing/light: " + role)
	var tournament := _world.get_node_or_null("Tournament")
	var board := _world.get_node_or_null("Tournament/Board") as Node3D
	if tournament == null or board == null or not bool(tournament.call("built")):
		return _services_fail("one actual tournament board provider is required")
	var plan: Dictionary = _json(VILLAGE_CONFIG).get("road_plan", {})
	var start := _v(plan.get("road_start", []))
	var end := _v(plan.get("road_end", []))
	var look := _world.get_node_or_null("WorldLook")
	var weather := _world.get_node_or_null("WorldWeather")
	if look == null or weather == null:
		return _services_fail("production day/night providers are missing")
	look.call("set_clock_frozen", true)
	weather.call("set_weather", "clear")
	for time_name: String in ["day", "night"]:
		_time = time_name
		look.call("apply_time", time_name)
		for frame in 8:
			await physics_frame
		for role: String in REQUIRED_HOUSES:
			var building: Node3D = houses[role]
			var door := building.get_node_or_null("Door") as Node3D
			var target: Vector3
			if door != null:
				target = door.global_position + building.global_basis.z.normalized() * 1.5
			else:
				# The workshop's installed open arch is the actual front module,
				# not an invented doorway tuple or a scripted opening.
				var arches := building.find_children("Wall_Arch*", "Node3D", true, false)
				if arches.size() != 1:
					return _services_fail("workshop must have one actual open arch")
				target = arches[0].global_position + building.global_basis.z.normalized() * 1.5
			if not await _service_leg([_xz(), _road_join(start, end), Vector2(target.x, start.y), Vector2(target.x, target.z)], time_name + " house " + role):
				return false
		for person: String in HOUSE_SERVICES:
			var npc: Node3D = people[person]
			var building: Node3D = houses[HOUSE_SERVICES[person]]
			var direction := building.global_basis.z.normalized()
			var stop := npc.global_position + direction * 1.9
			var leg: Array[Vector2] = [_xz(), _road_join(start, end)]
			var door := building.get_node_or_null("Door") as Node3D
			if door != null and person in ["Mira", "Bram"]:
				var outer := door.global_position + direction * 1.4
				var inner := door.global_position - direction * 1.0
				leg.append(Vector2(outer.x, start.y))
				leg.append(Vector2(outer.x, outer.z))
				leg.append(Vector2(inner.x, inner.z))
			else:
				leg.append(Vector2(stop.x, start.y))
			leg.append(Vector2(stop.x, stop.z))
			if not await _service_leg(leg, time_name + " service " + person):
				return false
			var prompt := await _prompt_winner(npc)
			if prompt.is_empty() or _xz().distance_to(Vector2(npc.global_position.x, npc.global_position.z)) > 3.0:
				return _services_fail("actual named service prompt never became reachable: " + person)
			print("F17 service actual %s %s: prompt=%s body=%s on_floor=true" % [time_name, person, prompt, _player.global_position])
			# Leave indoor services through their same physical doorway.
			if door != null and person in ["Mira", "Bram"]:
				var exit := door.global_position + direction * 1.4
				if not await _service_leg([_xz(), Vector2(door.global_position.x, door.global_position.z), Vector2(exit.x, exit.z), Vector2(exit.x, start.y)], "leave " + person):
					return false
		var halda: Node3D = people.Halda
		var board_at := Vector2(board.global_position.x, board.global_position.z)
		var arena: Array = _json("res://data/config/tournament_ground_presentation.json").get("arena", {}).get("centre", [])
		if arena.size() < 2:
			return _services_fail("actual tournament arena pose is missing")
		var arena_at := _v(arena)
		var halda_at := Vector2(halda.global_position.x, halda.global_position.z)
		var halda_stop := halda_at + (arena_at - halda_at).normalized() * 1.9
		if not await _service_leg([_xz(), _road_join(start, end), Vector2(arena_at.x, start.y), arena_at, halda_stop], time_name + " tournament keeper"):
			return false
		if (await _prompt_winner(halda)).is_empty():
			return _services_fail("actual tournament keeper prompt is unreachable")
		var board_stop := board_at + (arena_at - board_at).normalized() * 1.7
		if not await _service_leg([_xz(), arena_at, board_stop], time_name + " tournament board"):
			return false
		if (await _prompt_winner(board)).is_empty():
			return _services_fail("actual tournament board prompt is unreachable")
	print("F17#3 physical day/night circuit PASS: eight unique lived-in houses; actual Mira/Tam/Bram/Oskar/Maren/Halda and board prompts; collision/floor and parsed input. Opening/time fixtures disclosed; no camera quality, device, earned M1 or co-op claim.")
	return true


func _road_join(start: Vector2, end: Vector2) -> Vector2:
	return Geometry2D.get_closest_point_to_segment(_xz(), start, end)


func _service_leg(points: Array, label: String) -> bool:
	_path = PackedVector2Array()
	for point: Vector2 in points:
		if _path.is_empty() or _path[-1].distance_to(point) > .05:
			_path.append(point)
	if _path.size() < 2:
		return _player.is_on_floor()
	_arcs = PackedFloat32Array([0.0])
	for index in range(1, _path.size()):
		_arcs.append(_arcs[-1] + _path[index - 1].distance_to(_path[index]))
	# These are authored house-frontage/indoor/service legs, not claims to be
	# painted Main Street. Original main-road band assertions already ran.
	_road_from_arc = _arcs[-1] + 1.0
	_road_until_arc = -1.0
	_events = [{"arc": _arcs[-1] - .5, "label": label}]
	await _walk()
	_release_all()
	if not _failed.is_empty():
		return false
	if _xz().distance_to(_path[-1]) > .75 or not _player.is_on_floor():
		return _services_fail("actual collision/floor approach failed: " + label)
	return true


func _capture(label: String) -> void:
	print("F17#3 route event %s: actual body=%s" % [label, _player.global_position])


func _services_fail(reason: String) -> bool:
	_failed = reason
	return false
