extends Node3D

## Meadows' herd detour. This node adds no herd and owns no copied coordinate:
## it resolves the objective's spawn order through the same merged spawn table
## the encounter director consumes, then places one ordinary Interactable there.
## The existing wild pair remains catchable/fightable but neither verb is needed.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const BOND := preload("res://scripts/creatures/bond_milestones.gd")
const INVENTORY := preload("res://autoload/inventory.gd")

const OBJECTIVES_PATH := "res://data/progression/objectives.json"
const SPAWNS_PATH := "res://data/config/spawns.json"
const OBJECTIVE_ID := "band1_meadowhart_herd"
const REVEAL_FLAG := "band1_meadowhart_herd_met"
const COMPLETE_FLAG := "band1_meadowhart_herd_found"

var _player: Node3D = null
var _encounter: Node = null
var _prompt: Node3D = null
var _definition: Dictionary = {}
var _claiming := false
var _visit_submitted := false
var _acknowledgement_pending := false
## Item id -> count held when the claim was submitted, per reward part.
var _reward_counts_before := {}
var _landmark_credited_for_claim := false


static func definition() -> Dictionary:
	var parsed := _read_json(OBJECTIVES_PATH)
	for raw: Variant in parsed.get("local", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == OBJECTIVE_ID:
			return (raw as Dictionary).duplicate(true)
	return {}


static func herd_spawn(activity: Dictionary = {}) -> Dictionary:
	var visit: Dictionary = activity.get("visit", {}) as Dictionary
	var wanted := int(visit.get("spawn_order", -1))
	if wanted < 0:
		return {}
	var merged := BAND_CONTENT.load_config(SPAWNS_PATH, "spawns")
	for raw: Variant in merged.get("spawns", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == wanted:
			return (raw as Dictionary).duplicate(true)
	return {}


static func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("herd visit config missing at %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("herd visit config is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary


func build(world: Node3D, player: Node3D, encounter: Node) -> bool:
	_player = player
	_encounter = encounter
	_definition = definition()
	var herd := herd_spawn(_definition)
	var centre: Array = herd.get("centre", []) as Array
	var visit: Dictionary = _definition.get("visit", {}) as Dictionary
	if _definition.is_empty() or herd.is_empty() or centre.size() != 3:
		push_error("Meadowhart herd visit cannot resolve its objective or spawn order")
		return false
	if str(herd.get("species", "")) != "meadowhart" or int(herd.get("count", 0)) < 1:
		push_error("Meadowhart herd visit's configured spawn is not a Meadowhart herd")
		return false

	var x := float(centre[0])
	var z := float(centre[2])
	var ground := float(world.call("ground_height_at", x, z))
	if is_nan(ground):
		push_error("no ground under Meadowhart herd order %d" % int(herd.get("order", -1)))
		return false
	position = Vector3(x, ground, z)

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP
	_prompt.call("configure", "Watch the Meadowhart herd", float(visit.get("radius_m", 12.0)), true)
	# Two wild encounter offers share this ground. Watching wins one press while
	# this objective is open; fighting and catching remain after it clears.
	_prompt.set("priority", 5)
	_prompt.connect("activated", _on_activated)
	add_child(_prompt)

	add_to_group("progression_restore")
	STORY_LEDGER.listen(self, _on_delta_applied)
	_listen_for_refusals()
	restore_progression_from_game(get_node_or_null(^"/root/Game"))
	return true


func restore_progression_from_game(game: Node) -> void:
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", visit_pending(game, _definition.get("visit", {}) as Dictionary))


static func visit_pending(game: Node, visit: Dictionary) -> bool:
	if game == null:
		return false
	var landmark_id := str(visit.get("landmark_id", ""))
	var map: Variant = game.get("map")
	var landmark_pending := not landmark_id.is_empty() and map != null \
		and not bool((map as RefCounted).call("is_landmark_discovered", landmark_id))
	return not _has_local_flag(game, COMPLETE_FLAG) or landmark_pending


## Personal map discovery owns the once-only gate. Bond credit follows the
## existing whole-party semantics used by ordinary landmark discovery.
static func discover_for_party(game: Node, landmark_id: String) -> bool:
	if game == null or landmark_id.is_empty():
		return false
	var map: Variant = game.get("map")
	var party: Variant = game.get("party")
	if map == null or party == null \
			or not bool((map as RefCounted).call("discover_landmark", landmark_id)):
		return false
	for member: Variant in ((party as RefCounted).call("members") as Array):
		BOND.credit_landmark_visit(member as RefCounted)
	return true


func _on_activated() -> void:
	if _claiming:
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null or not visit_pending(game, _definition.get("visit", {}) as Dictionary):
		restore_progression_from_game(game)
		return
	var visit: Dictionary = _definition.get("visit", {}) as Dictionary
	var radius := float(visit.get("radius_m", 12.0))
	var director := _encounter_director()
	var ally := director.call("ally_body") as Node3D if director != null else null
	if _player == null or _flat_distance(_player.global_position, global_position) > radius:
		game.call("push_world_message", "Move closer to the Meadowhart herd.")
		return
	if ally == null or not is_instance_valid(ally) or _flat_distance(ally.global_position, global_position) > radius:
		game.call("push_world_message", "Bring your active companion close enough to watch with you.")
		return

	# Reaching the site together is itself valid discovery, even if Rae was not
	# visited and even when a full satchel leaves the payout pending.
	if not _has_local_flag(game, REVEAL_FLAG):
		STORY_LEDGER.write_flag(self, REVEAL_FLAG)
	var discovered_now := discover_for_party(game, str(visit.get("landmark_id", "")))
	if _has_local_flag(game, COMPLETE_FLAG):
		if discovered_now:
			game.call("push_world_message",
				"Meadowhart Grazing Ground discovered — your whole team gains bond progress.")
		restore_progression_from_game(game)
		return

	var inventory: RefCounted = game.get("inventory")
	var parts := reward_parts(visit)
	var reward_text := str(visit.get("reward_text", "the herd-visit reward"))
	if inventory == null or not rewards_fit(inventory, parts):
		game.call("push_world_message",
			("Meadowhart Grazing Ground discovered — your whole team gains bond progress. "
			+ "Make room for %s." % reward_text) if discovered_now \
			else "Make room in your satchel for the herd-visit reward.")
		return

	_reward_counts_before.clear()
	for part: Dictionary in parts:
		_reward_counts_before[part.item] = int(inventory.call("count", part.item))
	_claiming = true
	_visit_submitted = true
	_landmark_credited_for_claim = discovered_now
	# One reward_grant per part, each with its own once-only source, the way
	# encounter_rewards.gd pays a multi-item trainer purse. The completion flag
	# rides the LAST part, so the visit completes only once everything is paid;
	# a save that already holds the flag never reaches this code.
	var source := str(visit.get("reward_source", "meadowhart_herd_visit"))
	for index in parts.size():
		var part: Dictionary = parts[index]
		var intent := {
			"kind": "reward_grant",
			"realm": "meadows",
			"source": source if parts.size() == 1 else "%s:%s" % [source, part.item],
			"item": part.item,
			"count": part.count,
		}
		if index == parts.size() - 1:
			intent["flag"] = COMPLETE_FLAG
		var verdict := LEDGER_CLAIM.submit(self, intent)
		# A part an earlier, interrupted attempt already paid answers
		# `already_taken`: keep going, or the flag-carrying last part is never
		# reached and the visit is stranded (encounter_director `_grant_to`
		# attempts every component the same way). Any other refusal stops here.
		if not LEDGER_CLAIM.in_flight(verdict) and str(verdict.get("code", "")) != "already_taken":
			_claiming = false
			return


func _on_delta_applied(_delta: Dictionary) -> void:
	# A client's generic reward refusal has no source/request id. It may clear
	# _claiming, but cannot erase knowledge that this visit was submitted; the
	# player's own completion flag remains the authoritative acknowledgement.
	if not _visit_submitted:
		return
	var game := get_node_or_null(^"/root/Game")
	if not _has_local_flag(game, COMPLETE_FLAG):
		return
	_claiming = false
	_visit_submitted = false
	restore_progression_from_game(game)
	var visit: Dictionary = _definition.get("visit", {}) as Dictionary
	var inventory: RefCounted = game.get("inventory")
	var reward_text := str(visit.get("reward_text", "the herd-visit reward"))
	var paid := inventory != null and not _reward_counts_before.is_empty()
	for part: Dictionary in reward_parts(visit):
		if not paid:
			break
		paid = int(inventory.call("count", part.item)) >= int(_reward_counts_before.get(part.item, 0)) + int(part.count)
	if paid:
		game.call("push_world_message",
			("Meadowhart Grazing Ground discovered — your whole team gains bond progress, "
			+ "and the visit awards %s." % reward_text) if _landmark_credited_for_claim \
			else "Herd visited together — %s." % reward_text)
	_landmark_credited_for_claim = false
	_acknowledgement_pending = true
	set_process(true)
	_try_acknowledgement()


func _on_intent_refused(kind: String, _code: String, reason: String, _detail: Dictionary) -> void:
	if kind == "reward_grant" and _claiming:
		_claiming = false
		if _landmark_credited_for_claim:
			var game := get_node_or_null(^"/root/Game")
			if game != null:
				game.call("push_world_message",
					"Meadowhart Grazing Ground discovered — your whole team gains bond progress. %s"
					% reason)
		_landmark_credited_for_claim = false


## The visit's payout as [{item, count}, ...]: the `rewards` list when the
## objective defines one (F03#2: two Small Potions and a Revive), otherwise the
## legacy single `reward_item` x `reward_count` pair.
static func reward_parts(visit: Dictionary) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	var listed: Variant = visit.get("rewards", [])
	if listed is Array and not (listed as Array).is_empty():
		for raw: Variant in listed:
			if raw is Dictionary and int((raw as Dictionary).get("count", 0)) > 0:
				parts.append({"item": str((raw as Dictionary).get("item", "")), "count": int((raw as Dictionary).get("count", 0))})
		return parts
	parts.append({"item": str(visit.get("reward_item", "orb_basic")), "count": int(visit.get("reward_count", 3))})
	return parts


## Whether every part fits the satchel TOGETHER (a per-item has_room_for could
## pass each part alone and still overflow), on a scratch copy of the slots.
static func rewards_fit(inventory: RefCounted, parts: Array[Dictionary]) -> bool:
	if inventory == null:
		return false
	var trial := INVENTORY.new(inventory.get("_db"))
	for index in int(inventory.call("slot_count")):
		# stack_at() answers {} for an empty slot, and set_slot() stores any
		# dictionary as-is, so copying it verbatim made every empty slot of the
		# scratch copy read as occupied: no room for anything that is not
		# already stacked.
		var stack: Dictionary = inventory.call("stack_at", index)
		trial.set_slot(index, null if stack.is_empty() else stack)
	for part: Dictionary in parts:
		if trial.add(str(part.item), int(part.count)) != 0:
			return false
	return true


func _listen_for_refusals() -> void:
	var transport := LEDGER_CLAIM.transport(self)
	if transport != null and not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)


func _encounter_director() -> Node:
	if _encounter != null and is_instance_valid(_encounter):
		return _encounter
	var parent := get_parent()
	if parent != null:
		_encounter = parent.get_node_or_null(^"EncounterDirector")
	return _encounter


func _process(_delta: float) -> void:
	_try_acknowledgement()


func _exit_tree() -> void:
	_visit_submitted = false


func _try_acknowledgement() -> void:
	if not _acknowledgement_pending:
		set_process(false)
		return
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null or bool(panel.call("is_open")):
		return
	var visit: Dictionary = _definition.get("visit", {}) as Dictionary
	if bool(panel.call("start", str(visit.get("acknowledgement", "meadowhart_herd_found")))):
		_acknowledgement_pending = false
		set_process(false)


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


static func _has_local_flag(game: Node, flag_id: String) -> bool:
	if game == null:
		return false
	var local: Variant = game.get("local")
	if local == null:
		return false
	var flags: Variant = (local as RefCounted).get("flags")
	return flags != null and bool((flags as RefCounted).call("has", flag_id))
