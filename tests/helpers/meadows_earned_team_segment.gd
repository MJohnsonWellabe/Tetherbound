extends RefCounted

## Continue the live opening/village: catch the missing permanent team members,
## then earn the tournament's level requirement in ordinary nearby wild fights.
## The S03 practice-meadow route supplies the route, not a save or a seeded party.
## Every catch, strike, party change and carried remedy goes through player input.
const CATCH := preload("res://tests/helpers/fresh_opening_segment.gd")
const CLOUDREACH := preload("res://tests/helpers/cloudreach_live_segment.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const MAX_TRAINING_FIGHTS := 40
const APPROACH_FRAMES := 3600
const SATCHEL_COLUMNS := 6
const BOUNDARY_CONFIG := "res://data/config/village_boundary.json"

var _tree: SceneTree
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _director: Node
var _combat: Node
var _arbiter: Node
var _menu: Node
var _nav: RefCounted
var _failures: Array[String] = []
var _receipts: Array[Dictionary] = []
var _initial_ids: Array[int] = []
var _caught_ids: Array[int] = []
var _completed := false


## Reusable camp care seam: one carried remedy or food, one retained party
## member, real Satchel focus/confirmation and a measured one-item spend.
## Use a new helper per call. No opening/catch/training prerequisite is run.
func care_existing(tree: SceneTree, world: Node3D, game: Node,
		item: String, party_index: int) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Live Satchel care needs the existing tree, world and Game")
		return result()
	if tree.current_scene != world or INPUT_OWNER.current(tree) != null:
		_fail("Live Satchel care needs world input in the current scene")
		return result()
	_menu = game.call("menu")
	if _menu == null or party_index < 0 or party_index >= int(_party().call("size")):
		_fail("Live Satchel care lacks its menu or retained party target")
		return result()
	_completed = await _use_remedy(item, party_index)
	return result()


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Earned team preparation needs the existing tree, world and Game")
		return result()
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows":
		_fail("Earned team preparation must stay in the current Meadows scene")
		return result()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	_menu = game.call("menu")
	if _player == null or _rig == null or _director == null or _combat == null \
			or _arbiter == null or _menu == null:
		_fail("Earned team preparation lacks a production input/combat dependency")
		return result()
	_initial_ids = _party_ids()
	if _initial_ids.size() != 2 or _fighting() or INPUT_OWNER.current(tree) != null:
		_fail("Preparation starts after live opening/village with two earned creatures and world input")
		return result()
	_nav = NAV.new(tree, _player, _rig, _stick)
	while not TOURNAMENT.team_ready(_party()):
		if not await _prepare_pilot(false):
			return result()
		var wild := _choose_wild()
		if wild == null:
			_fail("No living low-level practice-meadow wild is available for the next catch")
			return result()
		if not await _engage(wild):
			return result()
		# _engage verifies the actual admitted body, including after the input
		# frame. A different nearby wild cannot silently replace this selection.
		var before := _party_ids()
		var catch_driver := CATCH.new()
		var caught: Dictionary = await catch_driver.catch_existing(tree, world, game, _player, _rig, wild)
		if not bool(caught.get("passed", false)):
			_fail("Live catch failed: " + str(caught.get("failures", [])))
			return result()
		var after := _party_ids()
		if not one_new_member(before, after):
			_fail("Catch did not preserve the existing party and earn exactly one new member")
			return result()
		for id: int in after:
			if not before.has(id):
				_caught_ids.append(id)
		_receipt("caught", {"party": _party_snapshot()})
	var wins := 0
	while not TOURNAMENT.training_ready(_party()) and wins < MAX_TRAINING_FIGHTS:
		if not await _prepare_pilot(true):
			return result()
		var wild := _choose_wild()
		if wild == null:
			_fail("No living low-level practice-meadow wild is available for earned training")
			return result()
		var before := _party_snapshot()
		if not await _engage(wild) or not await _win_live_fight():
			return result()
		wins += 1
		var after := _party_snapshot()
		if not earned_training_progress(before, after):
			_fail("Wild victory awarded no observable XP or levels to the retained team")
			return result()
		_receipt("wild_training_win", {"number": wins, "before": before, "after": after})
	if not TOURNAMENT.training_ready(_party()):
		_fail("Earned training budget ended before the configured tournament level requirement")
		return result()
	# Tournament watches the actual party and owns these durable receipts.
	# Reading them alone is insufficient because they intentionally stay set.
	for _frame in 120:
		if _has("tournament_team_ready") and _has("tournament_training_ready"):
			break
		await tree.physics_frame
	if not TOURNAMENT.team_ready(_party()) or not TOURNAMENT.training_ready(_party()) \
			or not _has("tournament_team_ready") or not _has("tournament_training_ready"):
		_fail("Tournament did not observe the actually earned team and levels")
		return result()
	var expected := _initial_ids + _caught_ids
	if _party_ids() != expected:
		_fail("Preparation changed a permanent team member outside an observed catch")
		return result()
	_completed = true
	_receipt("team_ready", {"required_size": TOURNAMENT.required_party_size(),
		"required_level": TOURNAMENT.required_level(), "party": _party_snapshot()})
	return result()


func _choose_wild() -> Node3D:
	var candidates: Array[Node3D] = []
	var distances: Array[float] = []
	var owned := _party_ids()
	for body: Node3D in _director.call("wild_creatures"):
		if not is_instance_valid(body) or not body.is_visible_in_tree() \
				or not bool(body.call("is_alive")) or bool(body.get("engaged")):
			continue
		var creature: RefCounted = body.get("instance")
		if creature == null or owned.has(creature.get_instance_id()):
			continue
		var level := int(creature.get("level"))
		var species := str(creature.get("species_id"))
		# S03 starts in the authored Bramblebun practice meadow. Nearby Mudsnout
		# encounters extend that same opening route when its rabbits are spent.
		if species not in ["bramblebun", "mudsnout"] or level > TOURNAMENT.required_level():
			continue
		if Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(30, -40)) > 160.0:
			continue
		candidates.append(body)
		distances.append(_player.global_position.distance_to(body.global_position))
	# Production offers the nearest living wild. A level-weighted selection
	# could instead insist on a distant level-2 body while a nearby, equally
	# eligible level-4 body owned Engage. Select before approaching/pressing;
	# the catch reference and post-admission identity remain this exact body.
	var offered := _director.call("_engageable") as Node3D
	var selected := preferred_candidate_index(distances, candidates.find(offered))
	return candidates[selected] if selected >= 0 else null


static func preferred_candidate_index(distances: Array[float], offered_index: int) -> int:
	if offered_index >= 0 and offered_index < distances.size():
		return offered_index
	var best := -1
	var nearest := INF
	for index in distances.size():
		if is_finite(distances[index]) and distances[index] >= 0.0 and distances[index] <= nearest:
			nearest = distances[index]
			best = index
	return best


func _engage(target: Node3D) -> bool:
	_nav.reset()
	var closest := INF
	var boundary := _boundary_approach(target)
	if bool(boundary.required) and (boundary.points as Array).is_empty():
		return _fail("The selected wild needs a physical village crossing but no current open gate route is available")
	var waypoint := 0
	var points: Array = boundary.points
	if not points.is_empty():
		_receipt("wild_boundary_route", {"target": str(target.name), "gate": boundary.gate, "points": points})
	_receipt("wild_approach", _approach_snapshot(target))
	for _frame in APPROACH_FRAMES:
		if _fighting():
			_stick(0, 0)
			if waypoint < points.size():
				return _fail("Combat interrupted the required physical village gate crossing")
			return _verify_engagement(target)
		if not is_instance_valid(target) or not bool(target.call("is_alive")):
			return _fail("The selected living wild disappeared before engagement")
		closest = minf(closest, _player.global_position.distance_to(target.global_position))
		var offer: Dictionary = _arbiter.call("winner")
		if waypoint >= points.size() and _arbiter.call("winning_provider") == _director \
				and bool(offer.get("actionable", false)) \
				and _director.call("_engageable") == target:
			_stick(0, 0)
			_receipt("wild_interact", _approach_snapshot(target))
			await _tap("interact")
			for _settle in 120:
				if _fighting():
					return _verify_engagement(target)
				await _tree.physics_frame
			return _fail("The offered wild did not enter combat after Interact")
		if waypoint < points.size():
			if not _open_boundary_gate(str(boundary.gate)):
				_stick(0, 0)
				return _fail("The actual village gate closed during the selected wild's approach")
			var at: Vector2 = points[waypoint]
			if Vector2(_player.global_position.x, _player.global_position.z).distance_to(at) <= 1.0:
				waypoint += 1
				_nav.reset()
				if waypoint == points.size():
					_receipt("wild_boundary_crossed", {"gate": boundary.gate, "player": str(_player.global_position),
						"target": str(target.name), "approach_frames": _frame})
			else:
				_nav.step(Vector3(at.x, float(_world.call("ground_height_at", at.x, at.y)), at.y))
		else:
			_nav.step(target.global_position)
		await _tree.physics_frame
	_stick(0, 0)
	var stalled := _approach_snapshot(target)
	stalled["closest_distance"] = closest
	stalled["approach_frames"] = APPROACH_FRAMES
	stalled["boundary_gate"] = boundary.gate
	stalled["boundary_waypoint"] = waypoint
	_receipt("wild_approach_failed", stalled)
	return _fail("Ordinary movement did not reach the practice-meadow wild: " + JSON.stringify(stalled))


func _boundary_approach(target: Node3D) -> Dictionary:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BOUNDARY_CONFIG))
	var open_ids: Array[String] = []
	for entry: Dictionary in (config.get("gates", {}) as Dictionary).get("entries", []):
		var id := str(entry.get("id", ""))
		if _open_boundary_gate(id):
			open_ids.append(id)
	return boundary_approach(config, Vector2(_player.global_position.x, _player.global_position.z),
		Vector2(target.global_position.x, target.global_position.z), open_ids)


func _open_boundary_gate(id: String) -> bool:
	var gate := _world.get_node_or_null("VillageBoundary/" + id)
	if gate == null or str(gate.get("flag_id")) != "road_gate_open" or not bool(gate.get("_open")):
		return false
	var script := gate.get_script() as Script
	if script == null or script.resource_path != "res://scripts/world/road_gate.gd":
		return false
	var leaf := gate.get("_shape") as CollisionShape3D
	return leaf != null and leaf.disabled


## The village is a closed polygon even after its three leaves open. Crossing
## its solid corner to pursue an outside wild is not a navigation shortcut.
## Derive the crossing from current authored leaves; the caller supplies only
## IDs whose actual live leaf collider is open. Other obstacles remain the
## ordinary stick navigator's job, inside the same approach frame budget.
static func boundary_approach(config: Dictionary, from: Vector2, target: Vector2,
		open_ids: Array[String]) -> Dictionary:
	var polygon := PackedVector2Array()
	for raw: Array in (config.get("outline", {}) as Dictionary).get("points", []):
		polygon.append(Vector2(float(raw[0]), float(raw[1])))
	var refused := {"required": true, "gate": "", "points": []}
	if polygon.size() < 3:
		return refused
	var from_inside := Geometry2D.is_point_in_polygon(from, polygon)
	var target_inside := Geometry2D.is_point_in_polygon(target, polygon)
	if from_inside == target_inside:
		# A same-side chord that crosses the fence twice needs an explicit
		# multi-gate route, not a blind line through the settlement.
		return refused if crosses_boundary(from, target, polygon) else {"required": false, "gate": "", "points": []}
	var clearance := float((config.get("wall", {}) as Dictionary).get("gate_clear_m", 0.0))
	if clearance <= 1.0:
		return refused
	var best := refused
	var best_distance := INF
	for entry: Dictionary in (config.get("gates", {}) as Dictionary).get("entries", []):
		var id := str(entry.get("id", ""))
		if not open_ids.has(id):
			continue
		var raw: Array = entry.get("at", [])
		if raw.size() != 2:
			continue
		var centre := Vector2(float(raw[0]), float(raw[1]))
		var yaw := deg_to_rad(float(entry.get("yaw_deg", 0.0)))
		var across := Vector2(sin(yaw), cos(yaw)) * clearance
		var inside := centre + across
		var outside := centre - across
		if not Geometry2D.is_point_in_polygon(inside, polygon):
			var swap := inside
			inside = outside
			outside = swap
		if not Geometry2D.is_point_in_polygon(inside, polygon) or Geometry2D.is_point_in_polygon(outside, polygon):
			continue
		var first := inside if from_inside else outside
		var last := outside if from_inside else inside
		var approach: Array[Vector2] = [first]
		var departure: Array[Vector2] = [target]
		if crosses_boundary(from, first, polygon):
			if from_inside:
				continue
			approach = exterior_path(from, first, polygon)
		if crosses_boundary(last, target, polygon):
			if target_inside:
				continue
			departure = exterior_path(last, target, polygon)
		if approach.is_empty() or departure.is_empty():
			continue
		var points: Array[Vector2] = approach.duplicate()
		points.append(centre)
		points.append(last)
		# Callers append the final target themselves.
		points.append_array(departure.slice(0, departure.size() - 1))
		var distance := 0.0
		var previous := from
		for point: Vector2 in points:
			distance += previous.distance_to(point)
			previous = point
		distance += previous.distance_to(target)
		if distance < best_distance:
			best_distance = distance
			best = {"required": true, "gate": id, "points": points}
	return best


## Outside detours clear the square 1.1 m corner guards, the 0.4 m player
## capsule and the caller's 1 m waypoint tolerance. Keep a small margin over
## sqrt(2) * 1.1 + 0.4 + 1.0. This changes route planning, never player state.
const EXTERIOR_CLEARANCE := 3.0


static func exterior_path(from: Vector2, target: Vector2,
		polygon: PackedVector2Array) -> Array[Vector2]:
	var nodes: Array[Vector2] = [from, target]
	for contour: PackedVector2Array in Geometry2D.offset_polygon(polygon, 3.2, Geometry2D.JOIN_MITER):
		for point: Vector2 in contour:
			if not Geometry2D.is_point_in_polygon(point, polygon):
				nodes.append(point)
	var distance: Array[float] = []
	var parent: Array[int] = []
	var visited: Array[bool] = []
	for _index in nodes.size():
		distance.append(INF)
		parent.append(-1)
		visited.append(false)
	distance[0] = 0.0
	for _step in nodes.size():
		var current := -1
		for index in nodes.size():
			if not visited[index] and (current < 0 or distance[index] < distance[current]):
				current = index
		if current < 0 or is_inf(distance[current]):
			break
		if current == 1:
			var result: Array[Vector2] = []
			while current != 0:
				result.push_front(nodes[current])
				current = parent[current]
			return result
		visited[current] = true
		for next in nodes.size():
			if visited[next] or not exterior_edge_clear(nodes[current], nodes[next], polygon):
				continue
			var candidate := distance[current] + nodes[current].distance_to(nodes[next])
			if candidate < distance[next]:
				distance[next] = candidate
				parent[next] = current
	return []


static func exterior_edge_clear(from: Vector2, target: Vector2,
		polygon: PackedVector2Array) -> bool:
	if Geometry2D.is_point_in_polygon(from, polygon) or Geometry2D.is_point_in_polygon(target, polygon) \
			or crosses_boundary(from, target, polygon):
		return false
	for index in polygon.size():
		var a := polygon[index]
		var b := polygon[(index + 1) % polygon.size()]
		for point: Vector2 in [from, target]:
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)) < EXTERIOR_CLEARANCE:
				return false
		for point: Vector2 in [a, b]:
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point, from, target)) < EXTERIOR_CLEARANCE:
				return false
	return true


static func crosses_boundary(from: Vector2, to: Vector2, polygon: PackedVector2Array) -> bool:
	for index in polygon.size():
		if Geometry2D.segment_intersects_segment(from, to, polygon[index], polygon[(index + 1) % polygon.size()]) != null:
			return true
	return false


func _approach_snapshot(target: Node3D) -> Dictionary:
	var offered := _director.call("_engageable") as Node3D
	var provider: Object = _arbiter.call("winning_provider")
	var blockers: Array[String] = []
	var contacts: Array[Dictionary] = []
	for index in _player.get_slide_collision_count():
		var contact := _player.get_slide_collision(index)
		var collider: Object = contact.get_collider()
		blockers.append(str(collider.name) if collider is Node else str(collider))
		contacts.append({"collider": str(collider.get_path()) if collider is Node else str(collider),
			"position": str(contact.get_position()), "normal": str(contact.get_normal())})
	return {"target": str(target.name) if is_instance_valid(target) else "<missing>",
		"target_position": str(target.global_position) if is_instance_valid(target) else "<missing>",
		"player_position": str(_player.global_position),
		"distance": _player.global_position.distance_to(target.global_position) if is_instance_valid(target) else -1.0,
		"offered_target": str(offered.name) if is_instance_valid(offered) else "<none>",
		"winning_provider": str(provider.name) if provider is Node else str(provider),
		"offer": _arbiter.call("winner"), "can_walk": _nav.can_walk(),
		"input_owner": str(INPUT_OWNER.current(_tree)), "slide_colliders": blockers, "contacts": contacts,
		"input_vector": str(Input.get_vector("move_left", "move_right", "move_forward", "move_back")),
		"velocity": str(_player.velocity), "on_floor": _player.is_on_floor(), "on_wall": _player.is_on_wall(),
		"nav_side": _nav.get("_side"), "nav_detour": str(_nav.get("_detour")),
		"nav_detour_left": _nav.get("_detour_left")}


func _verify_engagement(target: Node3D) -> bool:
	var admitted: Node3D = _combat.call("enemy_body") as Node3D
	if not _fighting() or not is_instance_valid(target) or admitted != target:
		return _fail("Wild engagement admitted %s instead of selected %s" % [
			str(admitted.name) if is_instance_valid(admitted) else "<none>",
			str(target.name) if is_instance_valid(target) else "<missing>"])
	return true


func _win_live_fight() -> bool:
	var pilot := CLOUDREACH.CampaignPilot.new(_tree, _combat, _director, _rig)
	pilot.use_switching = false
	pilot.switch_input = true
	var observed: Dictionary = await pilot.fight_to_the_end()
	pilot._move_toward(Vector3.ZERO)
	if bool(observed.get("timed_out", true)) or str(observed.get("outcome", "")) != "won":
		return _fail("Ordinary wild training did not win: " + str(observed))
	for _frame in 120:
		if not _fighting() and INPUT_OWNER.current(_tree) == null:
			return true
		await _tree.physics_frame
	return _fail("Wild victory did not return world input")


func _prepare_pilot(training: bool) -> bool:
	# Revive through the actual Satchel before choosing a pilot: fainted members
	# miss ordinary party XP and cannot silently count as a healthy training team.
	for index in int(_party().call("size")):
		var member: RefCounted = _party().call("at", index)
		if bool(member.get("fainted")) and not await _use_remedy("revive", index):
			return false
	var potion_stock := int((_game.get("inventory") as RefCounted).call("count", "potion_small"))
	# Prefer an under-level pilot while carried care can make that choice safe.
	# Once it cannot, health alone selects the strongest usable member; shared
	# victory XP still advances every non-fainted member toward level five.
	var selection := pilot_selection(_party(), potion_stock, training,
		TOURNAMENT.required_level())
	var best := int(selection.get("index", -1))
	var score := float(selection.get("score", -INF))
	if best < 0:
		return _fail("The earned party has no available creature to pilot")
	var active: RefCounted = _party().call("at", best)
	if potion_stock < 1:
		_receipt("depleted_stock_pilot_selected", {"creature_id": active.get_instance_id(),
			"hp": active.get("hp"), "max_hp": active.get("max_hp"),
			"hp_fraction": float(active.get("hp")) / float(active.get("max_hp")),
			"maximum_eligible_fraction": score / 10.0, "stock": potion_stock})
	while float(active.get("hp")) < float(active.get("max_hp")) * 0.5:
		if int((_game.get("inventory") as RefCounted).call("count", "potion_small")) < 1:
			_receipt("care_depleted_pilot", {"creature_id": active.get_instance_id(),
				"hp": active.get("hp"), "max_hp": active.get("max_hp"),
				"level": active.get("level")})
			break
		if not await _use_remedy("potion_small", best):
			return false
	for _press in int(_party().call("size")):
		if int(_party().call("active_index")) == best:
			return true
		var before := int(_party().call("active_index"))
		if not await _tap_party_cycle():
			return false
		_receipt("party_cycle", {"wanted": best, "before": before,
			"after": int(_party().call("active_index"))})
	if int(_party().call("active_index")) == best:
		return true
	return _fail("Party-cycle input did not select the available training creature")


## Pure selection seam for the live pilot policy. The caller owns revival and
## Satchel care; this function only chooses among currently usable instances.
## A depleted stock removes the under-level bonus, so the healthiest usable
## creature wins rather than selecting somebody who cannot be safely healed.
static func pilot_selection(party: RefCounted, potion_stock: int, training: bool,
		required_level: int) -> Dictionary:
	var best := -1
	var score := -INF
	if party == null or not party.has_method("size") or not party.has_method("at"):
		return {"index": best, "score": score}
	for index in int(party.call("size")):
		var member: RefCounted = party.call("at", index)
		if member == null or bool(member.get("fainted")) or bool(member.get("resting")):
			continue
		var max_hp := float(member.get("max_hp"))
		var hp := float(member.get("hp"))
		if max_hp <= 0.0 or hp <= 0.0:
			continue
		var candidate := hp / max_hp * 10.0
		if potion_stock > 0 and training and int(member.get("level")) < required_level:
			candidate += 2.0
		if candidate > score:
			score = candidate
			best = index
	return {"index": best, "score": score}


func _tap_party_cycle() -> bool:
	# Physics-signal injection can mark the same edge for two physics ticks,
	# or miss the first tick entirely. Send the actual bound controller button
	# from the input frame, preserving the original three/five tick hold/release.
	await _tree.process_frame
	var event: InputEventJoypadButton
	for binding in InputMap.action_get_events("party_cycle"):
		if binding is InputEventJoypadButton:
			event = binding.duplicate()
			break
	if event == null:
		return _fail("Party-cycle has no physical controller binding")
	event.pressed = true
	Input.parse_input_event(event)
	for _frame in 3:
		await _tree.physics_frame
	await _tree.process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	for _frame in 5:
		await _tree.physics_frame
	return true


func _use_remedy(item: String, index: int) -> bool:
	var inventory: RefCounted = _game.get("inventory")
	var stock := int(inventory.call("count", item))
	if stock < 1:
		return _fail("Earned care needs " + item + " but the carried supply is exhausted")
	var creature: RefCounted = _party().call("at", index)
	var old_hp := float(creature.get("hp"))
	var old_food := float(creature.get("nourishment"))
	var old_mood := float(creature.get("happiness"))
	await _tap("inventory")
	for _frame in 90:
		if bool(_menu.call("is_open")) and str(_menu.call("current_tab_id")) == "backpack":
			break
		await _tree.process_frame
	if not bool(_menu.call("is_open")) or str(_menu.call("current_tab_id")) != "backpack":
		return _fail("Inventory input did not open the Satchel for earned care")
	var bodies: Array = _menu.get("_bodies")
	var backpack: Node = bodies[0]
	var buttons: Array = backpack.get("_buttons")
	var slot := int(inventory.call("find_slot", item))
	if not await _focus_slot(buttons, slot):
		return _fail("Controller focus did not reach the carried " + item)
	await _tap("interact")
	var feeding := not str(backpack.get("_targeting_food")).is_empty()
	var rows: Array = backpack.get("_target_rows")
	if int(backpack.get("_targeting")) < 0 or index >= rows.size() or rows[index].disabled:
		return _fail("The real Satchel refused the requested creature care target")
	for _step in rows.size():
		if _focus() == rows[index]:
			break
		var current := rows.find(_focus())
		if current < 0:
			return _fail("The care picker lost controller focus")
		await _tap("ui_down" if current < index else "ui_up")
	if _focus() != rows[index]:
		return _fail("Controller focus did not reach the injured party member")
	await _tap("ui_accept")
	var improved := float(creature.get("hp")) > old_hp
	if feeding:
		improved = float(creature.get("nourishment")) > old_food \
			or float(creature.get("happiness")) > old_mood
	if int(inventory.call("count", item)) != stock - 1 \
			or not improved or bool(creature.get("fainted")):
		return _fail("Satchel care did not consume one remedy and restore the selected creature")
	await _tap("menu_cancel")
	for _frame in 90:
		if not bool(_menu.call("is_open")) and INPUT_OWNER.current(_tree) == null:
			_receipt("care", {"item": item, "creature_id": creature.get_instance_id(),
				"hp_before": old_hp, "hp_after": creature.get("hp"), "remaining": stock - 1,
				"food_before": old_food, "food_after": creature.get("nourishment"),
				"mood_before": old_mood, "mood_after": creature.get("happiness")})
			return true
		await _tree.process_frame
	return _fail("Satchel care did not release world input")


func _focus_slot(buttons: Array, target: int) -> bool:
	var current := buttons.find(_focus())
	if current < 0 or target < 0 or target >= buttons.size():
		return false
	var from_row: int = current / SATCHEL_COLUMNS
	var to_row: int = target / SATCHEL_COLUMNS
	for _step in absi(to_row - from_row):
		await _tap("ui_down" if to_row > from_row else "ui_up")
	for _step in absi(target % SATCHEL_COLUMNS - current % SATCHEL_COLUMNS):
		await _tap("ui_right" if target % SATCHEL_COLUMNS > current % SATCHEL_COLUMNS else "ui_left")
	return _focus() == buttons[target]


func _focus() -> Control:
	return _tree.root.get_viewport().gui_get_focus_owner()


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	for _frame in 3:
		await _tree.physics_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	for _frame in 5:
		await _tree.physics_frame


func _stick(x: float, z: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, z]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = int(pair[0])
		event.axis_value = float(pair[1])
		Input.parse_input_event(event)


func _party() -> RefCounted:
	return _game.get("party")


func _party_ids() -> Array[int]:
	var ids: Array[int] = []
	for index in int(_party().call("size")):
		ids.append((_party().call("at", index) as RefCounted).get_instance_id())
	return ids


func _party_snapshot() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for index in int(_party().call("size")):
		var member: RefCounted = _party().call("at", index)
		rows.append({"id": member.get_instance_id(), "species": member.get("species_id"),
			"level": member.get("level"), "xp": member.get("xp"), "hp": member.get("hp")})
	return rows


static func one_new_member(before: Array[int], after: Array[int]) -> bool:
	if after.size() != before.size() + 1 or after.size() > 5:
		return false
	for index in before.size():
		if after[index] != before[index]:
			return false
	return not before.has(after.back())


static func earned_training_progress(before: Array[Dictionary], after: Array[Dictionary]) -> bool:
	if before.size() != after.size():
		return false
	var progress := false
	for index in before.size():
		if before[index].id != after[index].id:
			return false
		if int(after[index].level) < int(before[index].level) \
				or (int(after[index].level) == int(before[index].level) \
				and int(after[index].xp) < int(before[index].xp)):
			return false
		if int(after[index].level) > int(before[index].level) \
				or int(after[index].xp) > int(before[index].xp):
			progress = true
	return progress


func _fighting() -> bool:
	return bool(_combat.call("is_fighting"))


func _has(flag: String) -> bool:
	return bool((_game.get("progression") as RefCounted).call("has", flag))


func _receipt(beat: String, detail: Dictionary) -> void:
	var row := detail.duplicate(true)
	row["beat"] = beat
	_receipts.append(row)
	print("[meadows_earned_team] " + JSON.stringify(row))


func _fail(message: String) -> bool:
	_failures.append(message)
	print("[meadows_earned_team] FAIL: " + message)
	return false


func result() -> Dictionary:
	if _tree != null:
		_stick(0, 0)
	return {"passed": _completed and _failures.is_empty(), "completed": _completed,
		"failures": _failures.duplicate(), "receipts": _receipts.duplicate(true),
		"world": _world, "game": _game, "player": _player, "rig": _rig}
