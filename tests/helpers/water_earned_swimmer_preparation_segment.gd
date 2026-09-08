extends RefCounted

## Live post-Iona preparation. No chapter bootstrap or campaign state writes.
const SWIMMER := preload("res://tests/helpers/water_earned_swimmer_segment.gd")
const HARVEST := preload("res://tests/helpers/water_reedhaven_segment.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var failures: Array[String] = []
var _tree: SceneTree
var world: Node3D
var game: Node
var player: CharacterBody3D
var camera: Node3D
var director: Node
var manager: Node
var riding: Node
var _arbiter: Node
var _harvest: RefCounted
var _capture: RefCounted
var _care: RefCounted
var _activated: Object
var swimmer: RefCounted
var before_ids: Array[int] = []
var paid_saddle_receipt: Dictionary = {}
var _completed := false

## Explicit farewell policy: only a duplicate species, lowest level first;
## stable slot order breaks ties. A unique species is never silently released.
static func outgoing_duplicate(members: Array) -> int:
	var counts := {}
	for creature in members:
		if creature == null:
			return -1
		var species := str(creature.species_id)
		counts[species] = int(counts.get(species, 0)) + 1
	var selected := -1
	for index in members.size():
		if int(counts[str(members[index].species_id)]) > 1 \
				and (selected < 0 or int(members[index].level) < int(members[selected].level)):
			selected = index
	return selected

static func harvest_needed(row: Dictionary, costs: Dictionary, counts: Dictionary) -> bool:
	var item := str(row.get("item_id", ""))
	return str(row.get("island_id", "")) == "tidal_cradle" and int(row.get("yield", 0)) > 0 \
		and costs.has(item) and int(counts.get(item, 0)) < int(costs[item])

func run(tree: SceneTree, actual_world: Node3D, actual_game: Node) -> Dictionary:
	_tree = tree
	world = actual_world
	game = actual_game
	if tree == null or world == null or game == null or tree.current_scene != world \
			or str(game.current_realm) != "water" or not str(game.pending_realm_entry).is_empty() \
			or not world.shell_build_complete() or game.pending_catch != null \
			or not game.local.flags.has("water_swim_stone_earned") \
			or not game.local.flags.has("water_swim_saddle_recipe_learned"):
		return _fail("Preparation requires the actual post-Iona ready Water world and settled belt")
	player = world.get_node_or_null("Player")
	camera = world.get_node_or_null("CameraRig")
	director = world.get_node_or_null("EncounterDirector")
	manager = world.get_node_or_null("CombatManager")
	riding = world.get_node_or_null("RidingController")
	_arbiter = world.get_node_or_null("InteractionArbiter")
	before_ids = _ids()
	if player == null or camera == null or director == null or manager == null or riding == null \
			or _arbiter == null or before_ids.size() != 5 or _unique_count(before_ids) != 5 \
			or INPUT_OWNER.current(tree) != null or manager.is_fighting() or riding.is_mounted():
		return _fail("Preparation requires five distinct live creatures and free ordinary controls")
	var outgoing := outgoing_duplicate(game.party.members())
	if outgoing < 0:
		return _fail("No duplicate species can make room: an explicit unique-creature farewell decision is required")
	print("WATER SWIMMER farewell policy: slot=%d species=%s level=%d identity=%d" % [outgoing,
		game.party.at(outgoing).species_id, game.party.at(outgoing).level, before_ids[outgoing]])
	_harvest = HARVEST.new()
	_harvest.setup(tree, world, player, camera)
	_care = SWIMMER.WATER_WALK.new()
	_care.setup(tree, world, player, camera)
	_capture = SWIMMER.new()
	# Bind observation/input handles only. replace_swimmer installs its own catch
	# observers once; do not call its fixture/root entry point or collect twice.
	_capture._tree = tree
	_capture._world = world
	_capture._game = game
	_capture._player = player
	_capture._rig = camera
	_capture._encounter = director
	_capture._combat = manager
	_capture._arbiter = _arbiter
	_arbiter.activated.connect(_on_activated)
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	await tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await tree.process_frame
	await _run_live(outgoing)
	_harvest._stop_stick()
	if _arbiter.activated.is_connected(_on_activated):
		_arbiter.activated.disconnect(_on_activated)
	if _arbiter.activated.is_connected(_harvest._on_activated):
		_arbiter.activated.disconnect(_harvest._on_activated)
	if _arbiter.activated.is_connected(_care._on_activated):
		_arbiter.activated.disconnect(_care._on_activated)
	await tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	return result()

func _run_live(outgoing: int) -> void:
	if not await _gather_costs():
		return
	if not await _care._ensure_ally_deployed("before earned swimmer catch"):
		_fail("No available catch ally: %s" % str(_care.failures))
		return
	var ally: RefCounted = director.ally_instance()
	if bool(ally.resting) or bool(ally.fainted):
		_fail("Deployed catch ally is unavailable; no state repair permitted")
		return
	if float(ally.hp) < float(ally.max_hp) - 0.01:
		if not await _care._recover_at_camp("before earned swimmer catch", "water_camp_tidal_cradle"):
			_fail("Ordinary Tidal recovery failed: %s" % str(_care.failures))
			return
	var target := _nearest_dry_swimmer()
	if target == null:
		_fail("No currently resident living dry ordinary compatible swimmer; no spawn or reroll permitted")
		return
	swimmer = target.get("instance")
	print("WATER SWIMMER chosen real body=%s species=%s level=%d position=%s" % [
		target.name, swimmer.species_id, swimmer.level, target.global_position])
	# The existing fresh catch approach's original first-target ceiling.
	if not await _capture._walk_to_and_engage_wild(target, 2600):
		_fail("Exact live swimmer Engage failed: %s" % str(_capture._failures))
		return
	var caught: Dictionary = await _capture.replace_swimmer(_tree, world, game, player, camera, target, outgoing)
	if not bool(caught.get("passed", false)):
		_fail("Actual swimmer catch/farewell failed: %s" % str(caught.get("failures", [])))
		return
	var costs_before := {}
	for cost: Dictionary in game.recipe_cost_for(SWIMMER.SADDLE_RECIPE):
		costs_before[str(cost.id)] = game.inventory.count(str(cost.id))
	var saddle_before := int(game.inventory.count("swim_saddle"))
	var crafted: Dictionary = await _capture.craft_earned_saddle()
	if not bool(crafted.get("passed", false)):
		_fail("Actual paid saddle failed: %s" % str(crafted.get("failures", [])))
		return
	var costs_after := {}
	for item: String in costs_before:
		costs_after[item] = game.inventory.count(item)
	paid_saddle_receipt = {"recipe": SWIMMER.SADDLE_RECIPE, "before": costs_before,
		"after": costs_after, "saddles_before": saddle_before,
		"saddles_after": game.inventory.count("swim_saddle"), "verified": true}
	if not await _mount_caught():
		return
	if not SWIMMER.replacement_receipt(before_ids, _ids(), outgoing, swimmer.get_instance_id()) \
			or _tree.current_scene != world or game.pending_catch != null:
		_fail("Mounted endpoint lost the exact ordinary farewell receipt or retained world")
		return
	_completed = true
	print("WATER SWIMMER READY: actual captured identity=%d species=%s level=%d mounted; late crossings unproved" % [
		swimmer.get_instance_id(), swimmer.species_id, swimmer.level])

func _gather_costs() -> bool:
	var costs := {}
	for cost: Dictionary in game.recipe_cost_for(SWIMMER.SADDLE_RECIPE):
		costs[str(cost.id)] = int(cost.n)
	if costs.is_empty():
		_fail("Production saddle recipe has no registered costs")
		return false
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HARVEST.PICKUP_DATA))
	var remaining: Array = data.get("harvest", []).duplicate()
	# At most one pass over finite authored nodes. Each successful harvest has
	# its existing exact-yield/receipt checks; a failed approach stops immediately.
	for _selection in remaining.size():
		var counts := {}
		var ready := true
		for item: String in costs:
			counts[item] = game.inventory.count(item)
			ready = ready and int(counts[item]) >= int(costs[item])
		if ready:
			return true
		var best := -1
		var distance := INF
		for index in remaining.size():
			var row: Dictionary = remaining[index]
			if not harvest_needed(row, costs, counts) \
					or game.progression.has("harvest_node:order:" + str(row.id)):
				continue
			var at := _point(row.position)
			var separation := Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length_squared()
			if separation < distance:
				best = index
				distance = separation
		if best < 0:
			break
		var selected: Dictionary = remaining.pop_at(best)
		if selected.has("approach_from") and not await _harvest._walk_to(_point(selected.approach_from), str(selected.id) + " authored approach"):
			_fail("Saddle supply approach failed: %s" % str(_harvest.failures))
			return false
		var item := str(selected.item_id)
		var tool := "knife" if item == "reed_fiber" else str(selected.gather_action)
		if not await _harvest._gather(str(selected.id), item, tool):
			_fail("Saddle supply failed: %s" % str(_harvest.failures))
			return false
	var paid_ready := true
	for item: String in costs:
		paid_ready = paid_ready and int(game.inventory.count(item)) >= int(costs[item])
	if paid_ready:
		return true
	_fail("Finite unclaimed Tidal supplies did not cover the exact production saddle cost")
	return false

func _nearest_dry_swimmer() -> Node3D:
	var selected: Node3D
	var distance := INF
	for body: Node3D in director.wild_creatures():
		if not is_instance_valid(body) or not body.is_visible_in_tree() or not body.is_alive() \
				or not body.has_meta("water_site_id") or body.has_meta("water_named_encounter") \
				or str(body.get_meta("water_placement_mode", "")) != "ground" \
				or not SWIMMER.compatible_swimmer(str(body.species_id)) \
				or float(world.water_depth_at(body.global_position)) > 0.0:
			continue
		var separation := player.global_position.distance_squared_to(body.global_position)
		if separation < distance:
			selected = body
			distance = separation
	return selected

func _mount_caught() -> bool:
	for _slot in game.party.size():
		if game.party.active() == swimmer:
			break
		await _tap("party_cycle")
	if game.party.active() != swimmer:
		_fail("Ordinary party cycle did not select this caught swimmer")
		return false
	# Existing 180-frame settle window; never call deployment or mount APIs.
	for _frame in 180:
		if director.ally_instance() == swimmer and is_instance_valid(director.ally_body()):
			break
		await _tree.physics_frame
	if director.ally_body() == null:
		await _tap("creature_recall")
	for _frame in 180:
		if director.ally_instance() == swimmer and is_instance_valid(director.ally_body()):
			break
		await _tree.physics_frame
	var body: Node3D = director.ally_body()
	if body == null or director.ally_instance() != swimmer:
		_fail("Selected swimmer did not deploy through ordinary controls")
		return false
	# Catching deliberately weakens this newcomer. Recover that exact creature
	# through the existing bed/rest flow before asking it to carry the route.
	if float(swimmer.hp) < float(swimmer.max_hp) - 0.01:
		if not await _care._recover_at_camp("newly caught swimmer", "water_camp_tidal_cradle"):
			_fail("New swimmer ordinary recovery failed: %s" % str(_care.failures))
			return false
		body = director.ally_body()
		if body == null or director.ally_instance() != swimmer:
			_fail("Ordinary recovery did not retain the caught swimmer")
			return false
	# Leave camp service offers once after care. The nearby spine[1] is only
	# 3 m from the bed; use authored spine[0], not a widened Ride radius.
	var clearance := camp_clearance_point(world.config)
	if not clearance.is_finite():
		_fail("Tidal authored camp-clearance route is absent")
		return false
	clearance.y = world.ground_height_at(clearance.x, clearance.z) + 0.1
	if not await _harvest._walk_to(clearance, "Tidal camp service clearance"):
		_fail("Ordinary camp clearance failed: %s" % str(_harvest.failures))
		return false
	var radius := float(body.body_radius())
	if not await _harvest._walk_to(body.global_position, "caught swimmer Ride approach", radius + 2.5):
		_fail("Ride approach failed: %s" % str(_harvest.failures))
		return false
	if _arbiter.winning_provider() != riding or not bool(_arbiter.winner().get("actionable", false)):
		_fail("Exact caught swimmer Ride did not win: %s" % str(_arbiter.winner()))
		return false
	_activated = null
	await _tap("interact")
	if _activated != riding or not riding.is_mounted() or riding.mount_body() != body \
			or director.ally_instance() != swimmer:
		_fail("Physical Ride did not mount the exact caught swimmer")
		return false
	return true

func _tap(action: StringName) -> void:
	# Match the proved live party-cycle controller edge alignment: GUI taps
	# belong to the existing farewell helper; world verbs use bound pad events.
	await _tree.process_frame
	var event: InputEventJoypadButton
	for binding in InputMap.action_get_events(action):
		if binding is InputEventJoypadButton:
			event = binding.duplicate()
			break
	if event == null:
		_fail("World verb has no physical pad button: " + str(action))
		return
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

func _on_activated(provider: Object) -> void:
	_activated = provider

func _ids() -> Array[int]:
	var ids: Array[int] = []
	for creature in game.party.members():
		ids.append(creature.get_instance_id())
	return ids

static func _unique_count(ids: Array[int]) -> int:
	var unique := {}
	for id in ids:
		if id == 0:
			return 0
		unique[id] = true
	return unique.size()

static func _point(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))

static func camp_clearance_point(config: Dictionary) -> Vector3:
	for route: Dictionary in config.get("land_routes", []):
		if str(route.get("id", "")) == "tidal_cradle_exploration_spine":
			var points: Array = route.get("polyline", [])
			if points.size() == 7:
				return _point(points[0])
	return Vector3.INF

func _fail(message: String) -> Dictionary:
	failures.append(message)
	print("WATER SWIMMER PREPARATION FAILED: " + message)
	return result()

func result() -> Dictionary:
	return {"passed": _completed and failures.is_empty(), "failures": failures.duplicate(),
		"completed_mounted": _completed, "world": world, "game": game, "player": player,
		"camera": camera, "director": director, "manager": manager, "riding": riding,
		"swimmer": swimmer, "initial_party_ids": before_ids.duplicate(),
		"paid_saddle_receipt": paid_saddle_receipt.duplicate(true),
		"endpoint": "mounted at Tidal arrival-side camp-clearance spine point; departure travel remains"}
