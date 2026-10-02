extends "res://tools/net/peer_runner.gd"

## F18 integration witness. Fixtures are explicitly separate from evidence:
## one creature, protected keys and free-play flags BEFORE hosting/admission;
## one grounded staging teleport BEFORE the first touch/input action. Nothing
## after that seam grants items, edits progress, permissions or actor transforms.
const F18_TRAVEL := preload("res://tests/helpers/f49_portal_travel.gd")
const F18_STONE := preload("res://scripts/world/waystone.gd")
const F18_TEACHING := preload("res://scripts/creatures/teaching.gd")
const F18_NAV := preload("res://tests/helpers/stick_navigator.gd")
const F18_INPUT := preload("res://scripts/ui/input_owner.gd")
var _f18_fixture_done := false
var _f18_started := false
var _f18_staged := false
var _f18_results: Array[Dictionary] = []
var _f18_presentation: Node

func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if not action.begins_with("f18_"): return await super._execute_step(msg)
	var game := root.get_node_or_null(^"Game")
	if game == null: return {"verdict": "ERROR", "detail": "F18 has no Game"}
	if action in ["f18_home_key", "f18_arch"] and DisplayServer.get_name() != "headless" and not is_instance_valid(_f18_presentation):
		_f18_presentation = preload("res://tests/helpers/f18_presentation_capture.gd").attach(self, game,
			"res://ralph/reports/HUB/f18/native/peer_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	if not game.is_connected("portal_action_result", _f18_note):
		game.connect("portal_action_result", _f18_note)
	var before := _physics_count
	var args: Dictionary = msg.get("args", {})
	var result: Dictionary
	match action:
		"f18_boot_world":
			if _f18_started or _f18_fixture_done or _session().call("is_active") == true:
				result = _f18_verdict(false, "direct world fixture boot must precede setup/admission")
			else:
				await _boot_scene("world", 30)
				result = _f18_verdict(current_scene != null and current_scene.scene_file_path == WORLD_SCENE,
					"disclosed sequential world fixture boot after lightweight title hello")
		"f18_fixture": result = await _f18_fixture(game, args)
		"f18_stage": result = await _f18_stage(game, args)
		"f18_inspect": result = _f18_verdict(true, "read-only production/disk witness", _f18_state(game, args))
		"f18_touch":
			_f18_started = true
			result = await _f18_touch(game, args)
		"f18_home_key":
			_f18_started = true
			result = await _f18_home_key(game)
		"f18_arch":
			_f18_started = true
			result = await _f18_arch(game, args)
		_: result = _f18_verdict(false, "unknown F18 action " + action)
	result.frames_used = _physics_count - before
	if is_instance_valid(_f18_presentation): _f18_presentation.call("_flush")
	return result

func _f18_verdict(ok: bool, detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "PASS" if ok else "FAIL", "detail": detail, "data": data}

func _f18_note(result: Dictionary) -> void:
	_f18_results.append(result.duplicate(true))

func _f18_fixture(game: Node, args: Dictionary) -> Dictionary:
	if _f18_fixture_done or _f18_started or _session().call("is_active") == true:
		return _f18_verdict(false, "fixtures require a fresh disconnected peer")
	if _session().call("portal_runtime_ready") != true:
		return _f18_verdict(false, "production F18 runtime is disabled; smoke must not override it")
	var local: RefCounted = game.get("local")
	var party: RefCounted = game.get("party")
	if party.call("size") == 0:
		var creature: RefCounted = game.call("make_creature", "terrapup", "F18 fixture")
		if creature == null or party.call("add", creature) != true:
			return _f18_verdict(false, "disclosed one-creature fixture could not be installed")
	# These are fixture facts, never proof of Grandpa's gift or earned boss keys.
	local.get("flags").call("set_flag", "opening:beat:free_play", true)
	local.get("flags").call("set_flag", "opening:starter_granted", true)
	var inventory: RefCounted = game.get("inventory")
	var fixture_items: Array[String] = ["home_key"]
	if bool(args.get("guest", false)): fixture_items.append("tidewake_portal_key")
	for item: String in fixture_items:
		if inventory.call("count", item) != 0 or inventory.call("add", item, 1) != 0:
			return _f18_verdict(false, "cannot install exactly one disclosed fixture " + item)
	local.get("flags").call("set_flag", "home_key_given", true)
	var snapshot: Dictionary = game.get("save_system").call("snapshot", game)
	local.set("redesign_character", F18_TEACHING.character_loadout_mirror(snapshot.party,
		local.get("redesign_character")))
	for node: Node in get_nodes_in_group("progression_restore"):
		if node.has_method("restore_progression_from_game"): node.call("restore_progression_from_game", game)
	for frame in 30: await physics_frame
	# The joiner relinquished world-save ownership before its initial scene;
	# disconnected solo autosave consequently refuses. This PUBLIC portable
	# save is fixture setup only, before admission or gameplay evidence.
	if bool(args.get("guest", false)):
		if game.get("save_system").call("save_character", game, str(local.get("character_id"))) != true:
			return _f18_verdict(false, "disclosed pre-admission portable fixture save refused")
	else:
		var saved: Dictionary = _step_save_character_here({})
		if saved.get("verdict") != "PASS": return saved
	_f18_fixture_done = true
	return _f18_verdict(true, "DISCLOSED setup only: starter/free-play flags and own HomeKey per peer; guest Tidewake key, not earned opening",
		_f18_state(game, {}))

func _f18_stage(game: Node, args: Dictionary) -> Dictionary:
	if not _f18_fixture_done or _f18_staged or _f18_started:
		return _f18_verdict(false, "one disclosed position fixture is closed after first gameplay evidence")
	var stone := _f18_find_stone(str(args.get("stone", "")))
	var player := game.call("find_player") as CharacterBody3D
	if stone == null or player == null or current_scene == null:
		return _f18_verdict(false, "staging requires the actual mounted stone/player")
	var at := stone.global_position + Vector3(0, 0, 5.3)
	at.y = float(current_scene.call("ground_height_at", at.x, at.z)) + player.safe_margin
	if not at.is_finite(): return _f18_verdict(false, "staging fixture lacks ordinary ground")
	REMOTE_CREATURE_TP.teleport_body(player, at)
	player.velocity = Vector3.ZERO
	for frame in 60: await physics_frame
	_f18_staged = true
	return _f18_verdict(player.is_on_floor() and player.global_position.distance_to(stone.global_position) > 2.4,
		"DISCLOSED grounded staging outside touch radius; gameplay starts after this seam", _f18_state(game, {}))

func _f18_find_stone(id: String) -> Node3D:
	for node: Node in get_nodes_in_group("waystones"):
		if current_scene != null and current_scene.is_ancestor_of(node) and node.get("waystone_id") == id:
			return node as Node3D
	return null

func _f18_find_arch(id: String) -> Node3D:
	for node: Node in get_nodes_in_group("portal_arches"):
		if current_scene != null and current_scene.is_ancestor_of(node) and node.get("arch_id") == id:
			return node as Node3D
	return null

func _f18_touch(game: Node, args: Dictionary) -> Dictionary:
	var id := str(args.get("stone", ""))
	var stone := _f18_find_stone(id)
	var player := game.call("find_player") as CharacterBody3D
	var rig := current_scene.get_node_or_null(^"CameraRig") as Node3D
	if stone == null or player == null or rig == null or F18_INPUT.current(self) != null:
		return _f18_verdict(false, "touch needs actual stone and ordinary world input")
	var local: RefCounted = game.get("local")
	var before: Array = local.get("redesign_character").transaction_receipts.duplicate()
	var result_start := _f18_results.size()
	var travel := F18_TRAVEL.new(self, game)
	var nav := F18_NAV.new(self, player, rig, travel._stick)
	var recoveries := int(player.get("_unstick_count"))
	var walked: bool = await nav.walk_to(stone.global_position, 1200, 2.1)
	travel._stick(0, 0)
	if not walked or not player.is_on_floor() or int(player.get("_unstick_count")) != recoveries:
		return _f18_verdict(false, "ordinary capsule walk did not actually touch the stone")
	var deadline := Time.get_ticks_msec() + 16000
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		for index in range(result_start, _f18_results.size()):
			var reply := _f18_results[index]
			if reply.get("kind") != "waystone_touch" or reply.get("waystone_id") != id: continue
			var state := _f18_state(game, {})
			var receipt := ""
			for candidate: String in state.character.get("transaction_receipts", []):
				if candidate.begins_with("craft:waystone_") and not before.has(candidate): receipt = candidate
			var disk: Dictionary = state.character_disk.get("redesign_character", {})
			var ok: bool = reply.get("ok") == true and reply.get("durable") == true \
				and reply.get("character_id") == state.character_id and not receipt.is_empty() \
				and state.character.last_waystones.get("meadows") == id \
				and disk.get("last_waystones", {}).get("meadows") == id \
				and disk.get("transaction_receipts", []).has(receipt) \
				and disk.get("waystones_activated", {}).get("meadows", []).has(id)
			state.observed_reply = reply
			state.touch_receipt = receipt
			return _f18_verdict(ok, "actual walk/touch requires bound durable reply + new receipt on portable disk", state)
	return _f18_verdict(false, "actual stone emitted no successful durable acknowledgement", _f18_state(game, {}))

func _f18_home_key(game: Node) -> Dictionary:
	var start := _f18_results.size()
	var before := _f18_state(game, {})
	var travel := F18_TRAVEL.new(self, game)
	if not await travel.home_key():
		return _f18_verdict(false, "actual Satchel HomeKey input: " + str(travel.failures), _f18_state(game, {}))
	var reply := _f18_latest(start, "home_key_finish")
	var after := _f18_state(game, {})
	var target := Vector3(INF, INF, INF)
	for hall: Node in get_nodes_in_group("crossing_halls"):
		if current_scene.is_ancestor_of(hall): target = hall.call("home_arrival")
	var ok: bool = reply.get("ok") == true and reply.get("durable") == true and reply.get("saved") == true \
		and reply.get("character_id") == after.character_id and after.realm == "meadows" \
		and after.home_key_count == 1 and before.home_key_count == 1 and target.is_finite() \
		and _f18_vector(after.position).distance_to(target) < 1.0 \
		and _f18_disk_pose_at(after, "meadows", _f18_vector(after.position))
	after.observed_reply = reply
	after.before_position = before.position
	return _f18_verdict(ok, "production Satchel Use requires saved authoritative HomeKey return at actual Hall", after)

func _f18_arch(game: Node, args: Dictionary) -> Dictionary:
	var id := str(args.get("arch", ""))
	var mode := str(args.get("mode", ""))
	var arch := _f18_find_arch(id)
	if arch == null or mode not in ["unlock", "enter"]: return _f18_verdict(false, "missing actual arch/mode")
	var before := _f18_state(game, {})
	var view: Dictionary = game.call("portal_view", id)
	if mode == "unlock" and (view.get("has_key") != true or view.get("character_open") == true):
		return _f18_verdict(false, "unlock requires matching fixture key and locked personal arch", before)
	if mode == "enter" and (view.get("open") != true or view.get("has_key") == true):
		return _f18_verdict(false, "Enter requires an already open arch without a consumable key", before)
	var start := _f18_results.size()
	var travel := F18_TRAVEL.new(self, game)
	if not await travel.activate(arch.get_node_or_null(^"Interactable") as Node3D):
		return _f18_verdict(false, "actual controller arch prompt: " + str(travel.failures))
	var kind := "portal_unlock" if mode == "unlock" else "portal_enter"
	var deadline := Time.get_ticks_msec() + 180000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var reply := _f18_latest(start, kind)
		if reply.is_empty(): continue
		var state := _f18_state(game, {})
		var disk: Dictionary = state.character_disk.get("redesign_character", {})
		var ok: bool = reply.get("ok") == true and reply.get("durable") == true and reply.get("character_id") == state.character_id
		if mode == "unlock":
			var receipt := str(reply.get("receipt", ""))
			ok = ok and not receipt.is_empty() and before.tidewake_key_count == 1 and state.tidewake_key_count == 0 \
				and state.character.portal_unlocks.has(id) and disk.get("portal_unlocks", []).has(id) \
				and disk.get("transaction_receipts", []).has(receipt) \
				and not before.character.get("transaction_receipts", []).has(receipt) \
				and _f18_stack_count(state.character_disk.get("inventory", []), "tidewake_portal_key") == 0
		else:
			var realm := str(args.get("realm", ""))
			ok = ok and reply.get("saved") == true and state.realm == realm and state.grounded == true \
				and _f18_disk_pose_at(state, realm, _f18_vector(state.position)) and F18_INPUT.current(self) == null
			if args.has("stone"):
				var stone := _f18_find_stone(str(args.stone))
				var target := F18_STONE.resolve_position(current_scene, stone.get("_row"), true) if stone != null else Vector3(INF, INF, INF)
				ok = ok and target.is_finite() and _f18_vector(state.position).distance_to(target) < 1.0
		state.observed_reply = reply
		return _f18_verdict(ok, "actual prompt " + mode + " requires bound durable reply and exact portable outcome", state)
	return _f18_verdict(false, "actual arch produced no authoritative outcome within bounded deadline", _f18_state(game, {}))

func _f18_latest(start: int, kind: String) -> Dictionary:
	for index in range(start, _f18_results.size()):
		if _f18_results[index].get("kind") == kind: return _f18_results[index]
	return {}

func _f18_stack_count(stacks: Array, item: String) -> int:
	var count := 0
	for stack: Variant in stacks:
		if stack is Dictionary and stack.get("id") == item: count += int(stack.get("n", 0))
	return count

func _f18_vector(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2])) if values.size() == 3 else Vector3(INF, INF, INF)

func _f18_disk_pose_at(state: Dictionary, realm: String, at: Vector3) -> bool:
	var pose: Dictionary = state.character_disk.get("player_pose", {})
	return pose.get("realm") == realm and _f18_vector(pose.get("position", [])).distance_to(at) < 0.5

func _f18_read(path: String) -> Dictionary:
	var raw: Variant = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return raw if raw is Dictionary else {}

func _f18_state(game: Node, args: Dictionary) -> Dictionary:
	var local: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	var character: String = local.get("character_id")
	var target: String = str(args.get("character_id", character))
	var world_id: String = world.get("world_id")
	var character_path: String = saver.call("characters").call("path_for", character)
	var world_path: String = saver.call("worlds").call("path_for", world_id)
	var player := game.call("find_player") as CharacterBody3D
	var inventory: RefCounted = game.get("inventory")
	var admitted: Dictionary = {}
	for row: Dictionary in _session().call("peers"):
		if row.get("character_id") == target: admitted = _session().call("admitted_character_state", int(row.get("peer_id", 0)))
	var disk := _f18_read(world_path)
	# Compare native decoded Variants before the JSON verdict wire can round
	# doubles. A rounded report dictionary cannot prove immutable disk equality.
	var exact_rows := {}
	for id: String in world.get("reward_deliveries"):
		exact_rows[id] = preload("res://scripts/creatures/essence.gd")._equivalent(
			world.get("reward_deliveries")[id], disk.get("reward_deliveries", {}).get(id))
	var payload := {"character_id": character, "world_id": world_id,
		"world_instance": world.get("reward_delivery_namespace"), "realm": game.get("current_realm"),
		"position": [player.global_position.x, player.global_position.y, player.global_position.z] if player != null else [],
		"grounded": player != null and player.is_on_floor(), "character": local.get("redesign_character").duplicate(true),
		"world": world.get("redesign_world").duplicate(true), "world_disk": disk,
		"character_disk": _f18_read(character_path), "admitted": admitted,
		"deliveries": world.get("reward_deliveries").duplicate(true), "deliveries_disk_exact": exact_rows,
		"home_key_count": inventory.call("count", "home_key"), "tidewake_key_count": inventory.call("count", "tidewake_portal_key"),
		"tidewake_view": game.call("portal_view", "tidewake"), "runtime_enabled": _session().call("portal_runtime_ready")}
	# JSON normalizes int/float domains and makes verdict transport explicit.
	return JSON.parse_string(JSON.stringify(payload)) as Dictionary
