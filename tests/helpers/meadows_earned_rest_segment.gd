extends RefCounted

## Live care at the caller's paid campsite. The party, structures and food are
## carried in from the uninterrupted campaign. Bed assignment, sleep, gathering
## and feeding only use the production input paths.
const TAIL := preload("res://tests/helpers/gate_b_tail_segment.gd")
const MATERIAL := preload("res://tests/helpers/gate_a_material_route.gd")
const CARE := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const MAX_NIGHTS := 3
const MAX_BITES := 12
const FOOD := "berries"


class BedInput extends TAIL:
	func _sleep_the_team_into_condition() -> bool:
		_fail("The earned rest segment owns its observed sleep and Satchel flow")
		return false
	func _feed_the_team() -> void:
		_fail("Direct fixture feeding is forbidden in the earned rest segment")


class BerryInput extends MATERIAL:
	# Berries have no tool requirement. Stow the actual held tool through its
	# assigned quick slot before using the ordinary harvest/pickup input seam.
	func _equip(item: String) -> bool:
		if item != "berries":
			_fail("The rest gatherer only picks berries")
			return false
		var held := str(_game.get("equipped_tool"))
		if held.is_empty():
			return true
		var slot := int(_game.call("hotbar_slot_of", held))
		if slot < 0 or slot > 3:
			_fail("The held tool has no controller quick slot for bare-hand berry picking")
			return false
		await _tap_action(StringName("hotbar_%d" % (slot + 1)))
		if not str(_game.get("equipped_tool")).is_empty():
			_fail("Quick-slot input did not stow the held tool for berry picking")
			return false
		return true


var _tree: SceneTree
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _party: RefCounted
var _bedroll: Node3D
var _beds: Array[Node3D] = []
var _entrants: Array[RefCounted] = []
var _indices: Array[int] = []
var _initial_ids: Array[int] = []
var _driver: BedInput
var _gatherer: BerryInput
var _failures: Array[String] = []
var _receipts: Array[Dictionary] = []
var _completed := false
var _lesson_mode := false


func run(tree: SceneTree, world: Node3D, game: Node,
		creature_beds: Array, bedroll: Node3D, lesson_mode: bool = false) -> Dictionary:
	_lesson_mode = lesson_mode
	_tree = tree
	_world = world
	_game = game
	_bedroll = bedroll
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Earned rest needs the existing tree, world and Game")
		return result()
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" \
			or tree.paused or INPUT_OWNER.current(tree) != null:
		_fail("Earned rest needs world input in the current Meadows scene")
		return result()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_party = game.get("party")
	if _player == null or _rig == null or not TOURNAMENT.team_ready(_party) \
			or not TOURNAMENT.training_ready(_party):
		_fail("Earned rest requires the actual trained tournament team and production player")
		return result()
	_initial_ids = party_ids(_party)
	_indices = entrant_indices(_party)
	var wanted_beds := int(preload("res://scripts/build/home_progress.gd").required_pieces().get("creature_bed", 0)) if _lesson_mode else _indices.size()
	if (_lesson_mode and wanted_beds != 1) or _indices.size() != TOURNAMENT.required_party_size() or creature_beds.size() != wanted_beds:
		_fail("Actual retained tournament entrants or selected paid-bed mode are incomplete")
		return result()
	if not _paid_structure(bedroll, "bedroll"):
		return result()
	var used_records: Array[int] = []
	for raw: Variant in creature_beds:
		var bed := raw as Node3D
		if not _paid_structure(bed, "creature_bed"):
			return result()
		var index := int(bed.get_meta("placed_index", -1))
		if used_records.has(index) or not bed.has_method("build_index") \
				or int(bed.call("build_index")) != index:
			_fail("Creature beds must have distinct production placement/assignment indices")
			return result()
		used_records.append(index)
		_beds.append(bed)
	for index: int in _indices:
		_entrants.append(_party.call("at", index))
	_driver = BedInput.new()
	_driver._tree = tree
	_driver._world = world
	_driver._game = game
	_driver._player = _player
	_driver._rig = _rig
	_driver._party = _party
	_driver._progression = game.get("progression")
	_driver._bedroll = bedroll
	_driver._beds.resize(int(_party.call("size")))
	for ordinal in _indices.size():
		_driver._beds[_indices[ordinal]] = _beds[0] if _lesson_mode else _beds[ordinal]
	if not _driver._collect_nodes():
		_fail("Bed input dependencies are missing: " + str(_driver.failures))
		return result()
	_driver._resolve_move_bindings()
	if not _driver.failures.is_empty() or bool(_driver._manager.call("is_fighting")):
		_fail("The paid camp is not available for ordinary bed input")
		return result()
	_gatherer = BerryInput.new()
	_gatherer._tree = tree
	_gatherer._world = world
	_gatherer._game = game
	_gatherer._player = _player
	_gatherer._rig = _rig
	_gatherer._arbiter = _driver._arbiter
	if not _gatherer._resolve_move_bindings():
		_fail("Berry gathering lacks controller movement bindings")
		return result()
	_gatherer._nav = MATERIAL.NAVIGATOR.new(tree, _player, _rig, _gatherer._send_stick)
	_completed = await _single_bed_lesson() if _lesson_mode else await _sleep_the_team_into_condition()
	return result()


func _single_bed_lesson() -> bool:
	# A finite set of required care actions, not the five-bed mode's retry
	# nights. Each retained unrested entrant uses the same actual paid bed once.
	# The existing MAX_NIGHTS=3 team-retry mode and sleep frame bound stay intact.
	for ordinal in _indices.size():
		if not _team_preserved():
			return false
		var member := _entrants[ordinal]
		if bool(member.get("rested")):
			continue
		if bool(member.get("resting")) or int(_beds[0].call("occupant_index")) >= 0:
			return _fail("Lesson bed must be available before the next explicit assignment")
		if not await _driver._assign_to_bed(_indices[ordinal]):
			return _fail("Single-bed lesson assignment failed: " + str(_driver.failures))
		if int(member.get("rest_bed_index")) != int(_beds[0].call("build_index")) \
				or int(_beds[0].call("occupant_index")) != _indices[ordinal]:
			return _fail("Lesson panel assigned a different entrant or bed")
		_receipt("lesson_bed_assigned", {"creature":member.get_instance_id(),
			"party_index":_indices[ordinal], "bed_index":member.get("rest_bed_index")})
		if not await _sleep_once():
			return false
		if not bool(member.get("rested")) or bool(member.get("resting")) \
				or bool(member.get("fainted")) or float(member.get("hp")) <= 0 \
				or int(_beds[0].call("occupant_index")) >= 0:
			return _fail("Lesson sleep did not restore its entrant and free the actual bed")
		_receipt("lesson_rest_completed", {"creature":member.get_instance_id(),
			"day":_game.get("day"), "condition":CONDITION.summary(member, CONDITION.config())})
	if not await _feed_with_satchel():
		return false
	if not _team_preserved() or not _sleep_flag() or not TOURNAMENT.condition_ready(_party):
		return _fail("One finite lesson pass did not satisfy actual team condition: " + str(TOURNAMENT.readiness_report(_party)))
	for _frame in 120:
		if bool((_game.get("progression") as RefCounted).call("has", "tournament_team_fed")):
			return true
		await _tree.physics_frame
	return _fail("Tournament did not observe the lesson's actually fed entrants")


func _sleep_the_team_into_condition() -> bool:
	var definition: Dictionary = (_game.get("items") as RefCounted).call("definition", FOOD)
	var food: Dictionary = definition.get("creature_food", {})
	if float(food.get("nourishment", 0)) <= 0 or float(food.get("happiness", 0)) <= 0:
		return _fail("Berries must carry their production nourishment and happiness effects")
	for night in MAX_NIGHTS:
		if not _team_preserved():
			return false
		var wanted := 0
		for member: RefCounted in _entrants:
			wanted += berries_needed(member, food, CONDITION.config())
		if not await _gather_food_to(wanted):
			return false
		for ordinal in _indices.size():
			var member := _entrants[ordinal]
			if bool(member.get("resting")):
				return _fail("An entrant was already assigned before this night's bed-panel input")
			if not await _driver._assign_to_bed(_indices[ordinal]):
				return _fail("Live bed assignment failed: " + str(_driver.failures))
			if int(member.get("rest_bed_index")) != int(_beds[ordinal].call("build_index")) \
					or int(_beds[ordinal].call("occupant_index")) != _indices[ordinal]:
				return _fail("Bed-panel assignment did not bind the selected entrant to its own paid bed")
			_receipt("bed_assigned", {"creature": member.get_instance_id(),
				"party_index": _indices[ordinal], "bed_index": member.get("rest_bed_index")})
		if not await _sleep_once():
			return false
		for member: RefCounted in _entrants:
			if not bool(member.get("rested")) or bool(member.get("resting")) \
					or bool(member.get("fainted")) or float(member.get("hp")) <= 0:
				return _fail("An assigned entrant did not complete a real restorative night: " + str(CONDITION.summary(member, CONDITION.config())))
		if not await _feed_with_satchel():
			return false
		_receipt("night_completed", {"night": night + 1, "day": _game.get("day"),
			"readiness": Array(TOURNAMENT.readiness_report(_party))})
		if TOURNAMENT.condition_ready(_party):
			if not _team_preserved() or not _sleep_flag():
				return _fail("Ready team lacks its retained roster or durable real-sleep receipt")
			for _frame in 120:
				if bool((_game.get("progression") as RefCounted).call("has", "tournament_team_fed")):
					break
				await _tree.physics_frame
			if not bool((_game.get("progression") as RefCounted).call("has", "tournament_team_fed")):
				return _fail("Tournament did not observe the actually fed entrants")
			return true
	return _fail("Three real nights did not satisfy the tournament's actual condition: " + str(TOURNAMENT.readiness_report(_party)))


func _sleep_once() -> bool:
	var prompt := _bedroll.get_node_or_null("Interactable") as Node3D
	if prompt == null or not await _driver._walk_to_prompt(prompt, "paid bedroll"):
		return _fail("Ordinary travel did not reach the paid bedroll: " + str(_driver.failures))
	var day_before := int(_game.get("day"))
	var children_before := _bedroll.get_children()
	await _driver._tap(&"interact")
	# Observe the real day callback and its newly created fade layer going away.
	# Process-frame count is not elapsed time in a headless campaign.
	for _frame in 360:
		var fade_active := false
		for child: Node in _bedroll.get_children():
			if child is CanvasLayer and not children_before.has(child):
				fade_active = true
		if int(_game.get("day")) == day_before + 1 and not fade_active:
			return true
		await _tree.physics_frame
	return _fail("Bedroll input did not complete exactly one visible night (%d -> %d)" % [day_before, int(_game.get("day"))])


func _feed_with_satchel() -> bool:
	for ordinal in _indices.size():
		var member := _entrants[ordinal]
		for _bite in MAX_BITES:
			# Food solves hunger. A fed but unhappy entrant can spend another
			# real night in its bed; do not keep feeding until the Satchel's
			# full-creature refusal turns that valid care route into a failure.
			if CONDITION.is_fed(member, CONDITION.config()):
				break
			if not await _gather_food_to(1):
				return false
			var care: Dictionary = await CARE.new().care_existing(_tree, _world, _game, FOOD, _indices[ordinal])
			if not bool(care.get("passed", false)):
				return _fail("Real Satchel feeding failed: " + str(care.get("failures", [])))
			for row: Dictionary in care.get("receipts", []):
				_receipts.append(row)
		if not CONDITION.is_fed(member, CONDITION.config()):
			return _fail("Twelve real bites did not feed the entrant: " + str(CONDITION.summary(member, CONDITION.config())))
	return true


func _gather_food_to(wanted: int) -> bool:
	var inventory: RefCounted = _game.get("inventory")
	for _stop in 32:
		if int(inventory.call("count", FOOD)) >= wanted:
			return true
		var bush := _nearest_berry_bush()
		if bush == null:
			return _fail("No live authored berry bush remains for the camp's actual food shortfall")
		var at := bush.global_position
		var before := int(inventory.call("count", FOOD))
		if not await _gatherer._walk_to(at, 1.65, _gatherer._travel_budget(at)) \
				and _player.global_position.distance_to(at) > MATERIAL.WITHIN_REACH:
			return _fail("Ordinary travel could not reach the live berry bush")
		if not await _gatherer._harvest_node(bush, FOOD, true):
			return _fail("Real berry harvest failed: " + str(_gatherer.failures))
		var after := int(inventory.call("count", FOOD))
		if after <= before:
			return _fail("Berry-bush input yielded no inventory receipt")
		_receipt("berries_gathered", {"before": before, "after": after, "at": str(at)})
	return _fail("Physical berry harvests did not cover the actual care shortfall")


func _nearest_berry_bush() -> Node3D:
	var nearest: Node3D
	var distance := INF
	for node: Node in _tree.get_nodes_in_group("harvestable"):
		if not node is Node3D or node.is_queued_for_deletion() or not node.is_inside_tree():
			continue
		var script := node.get_script() as Script
		if script == null or script.resource_path != MATERIAL.HARVEST_NODE_PATH:
			continue
		if str(node.call("resource_item")) != FOOD or not _gatherer._is_unspent(node):
			continue
		if absf(node.global_position.y - _player.global_position.y) > MATERIAL.WALKABLE_RISE:
			continue
		var gap := _player.global_position.distance_squared_to(node.global_position)
		if gap < distance:
			distance = gap
			nearest = node
	return nearest


func _paid_structure(node: Node3D, id: String) -> bool:
	if not is_instance_valid(node) or not _world.is_ancestor_of(node) \
			or str(node.get_meta("building_id", "")) != id:
		return _fail("Earned rest requires a live paid " + id + " in the current world")
	var records: Array = _game.get("placed_buildings")
	var index := int(node.get_meta("placed_index", -1))
	if index < 0 or index >= records.size() or not paid_record_matches(records[index], id):
		return _fail("The live " + id + " lacks its paid durable record")
	return true


static func paid_record_matches(record: Dictionary, id: String) -> bool:
	return str(record.get("id", "")) == id and bool(record.get("paid", false)) \
		and not bool(record.get("removed", false)) and str(record.get("realm", "meadows")) == "meadows"


static func entrant_indices(party: RefCounted) -> Array[int]:
	var indices: Array[int] = []
	for entry: Dictionary in TOURNAMENT.entrants(party):
		for index in int(party.call("size")):
			if party.call("at", index) == entry.creature:
				indices.append(index)
				break
	return indices


static func berries_needed(member: RefCounted, food: Dictionary, cfg: Dictionary) -> int:
	var nourishment: Dictionary = cfg.get("nourishment", {})
	var missing_food := maxf(0.0, float(nourishment.get("max", 100)) * float(nourishment.get("fed_at", 0.55)) - float(member.get("nourishment")))
	return ceili(missing_food / maxf(float(food.get("nourishment", 0)), 0.001))


static func party_ids(party: RefCounted) -> Array[int]:
	var ids: Array[int] = []
	for index in int(party.call("size")):
		ids.append((party.call("at", index) as RefCounted).get_instance_id())
	return ids


func _team_preserved() -> bool:
	if party_ids(_party) != _initial_ids:
		return _fail("The permanent team changed during earned camp care")
	return true


func _sleep_flag() -> bool:
	return bool((_game.get("progression") as RefCounted).call("has", "player_slept_at_home"))


func _receipt(beat: String, detail: Dictionary) -> void:
	var row := detail.duplicate(true)
	row["beat"] = beat
	_receipts.append(row)
	print("[meadows_earned_rest] " + JSON.stringify(row))


func _fail(message: String) -> bool:
	_failures.append(message)
	print("[meadows_earned_rest] FAIL: " + message)
	return false


func result() -> Dictionary:
	if _driver != null:
		_driver._release_move()
	if _gatherer != null:
		_gatherer._release_move()
	return {"passed": _completed and _failures.is_empty(), "completed": _completed,
		"failures": _failures.duplicate(), "receipts": _receipts.duplicate(true),
		"world": _world, "game": _game, "player": _player, "rig": _rig}
