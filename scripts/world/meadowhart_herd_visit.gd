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
var _reward_count_before := 0
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
	var reward_item := str(visit.get("reward_item", "orb_basic"))
	var reward_count := int(visit.get("reward_count", 3))
	if inventory == null or not bool(inventory.call("has_room_for", reward_item, reward_count)):
		game.call("push_world_message",
			("Meadowhart Grazing Ground discovered — your whole team gains bond progress. "
			+ "Make room for the three Basic Orbs.") if discovered_now \
			else "Make room in your satchel for the herd-visit reward.")
		return

	_reward_count_before = int(inventory.call("count", reward_item))
	_claiming = true
	_visit_submitted = true
	_landmark_credited_for_claim = discovered_now
	var verdict := LEDGER_CLAIM.submit(self, {
		"kind": "reward_grant",
		"realm": "meadows",
		"source": str(visit.get("reward_source", "meadowhart_herd_visit")),
		"item": reward_item,
		"count": reward_count,
		"flag": COMPLETE_FLAG,
	})
	if not LEDGER_CLAIM.in_flight(verdict):
		_claiming = false


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
	if inventory != null and int(inventory.call("count", str(visit.get("reward_item", "orb_basic")))) \
			>= _reward_count_before + int(visit.get("reward_count", 3)):
		game.call("push_world_message",
			("Meadowhart Grazing Ground discovered — your whole team gains bond progress, "
			+ "and the visit awards 3 Basic Orbs.") if _landmark_credited_for_claim \
			else "Herd visited together — 3 Basic Orbs.")
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
