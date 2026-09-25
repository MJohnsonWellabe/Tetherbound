extends SceneTree

## Earned save chain: fresh save -> Cloudreach arrival (C1 handoff), by ordinary
## play, one segment per process.
##
## WHAT IT IS
##   The same earned helpers the continuous driver
##   (`tests/smoke_four_biome_continuous.gd`) composes, cut at save boundaries.
##   Every segment either starts a FRESH game through the production title
##   (segment `opening_team`) or loads the previous segment's save through the
##   production title's Load list (slot 1, the pause-menu "Slot 2" save), runs
##   one or more earned helpers read-only, and on success writes slot 1 through
##   `Game.save_game()` -- the same call the menu Save tab makes. No teleport,
##   flag/inventory/party write, HP pin or debug skip is made by this file.
##
## SEGMENTS (in order; `run_chain.sh` drives them)
##   opening_team     fresh title -> first catch -> road gate -> village -> team
##   camp_tournament  materials -> paid camp -> rest -> tournament (camp beds are
##                    live nodes the rest helper needs, so these share a process)
##   bridge           South Bridge grunt + crossing
##   warrens          Quarry / Burrow Warrens cleared and exited
##   relay            Tether relay disabled, Mill crossed
##   hall             three Sigils, Hall gauntlet, Warden arena boundary
##   warden           Warden, Veridian offer ACCEPTED (see warden_accept.gd),
##                    acknowledgement, physical Rift crossing -> Cloudreach
##
## USAGE
##   TB_WORLD_SEED=<seed> godot --headless --path . \
##     --script tools/earned_saves/earned_chain_runner.gd -- \
##     --segment=<id> --save-dir=<abs dir> --receipt=<abs json>
##   The save dir for a resumed segment must already hold the previous
##   segment's save (run_chain.sh copies it), so every segment's output is kept
##   as a separate "last good save".
##
## OUTPUT
##   The receipt JSON (flags gained, party, key items, location, wall/game time,
##   helper receipts) and the line `EARNED CHAIN RESULT {...}`. Exit 0 on pass.
const SAVE := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")
const VILLAGE := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const TEAM := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const MATERIALS := preload("res://tests/helpers/meadows_earned_material_segment.gd")
const CAMP := preload("res://tests/helpers/meadows_earned_camp_segment.gd")
const REST := preload("res://tests/helpers/meadows_earned_rest_segment.gd")
const TOURNAMENT := preload("res://tests/helpers/meadows_earned_tournament_segment.gd")
const BRIDGE := preload("res://tools/earned_saves/bridge_crossing.gd")
const WARRENS := preload("res://tools/earned_saves/warrens_route.gd")
const RELAY := preload("res://tests/helpers/meadows_earned_relay_segment.gd")
const HALL := preload("res://tests/helpers/meadows_earned_hall_segment.gd")
const WARDEN_ACCEPT_PATH := "res://tools/earned_saves/warden_accept.gd"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const CHAIN_SLOT := 1
const SEGMENTS := ["opening_team", "camp_tournament", "bridge", "warrens", "relay", "hall", "warden"]
const LOAD_SETTLE_FRAMES := 300

var segment := ""
var save_dir := ""
var receipt_path := ""
var failures: Array[String] = []
var helper_receipts: Array = []
var started_ms := 0
var game: Node
var flags_before: Array = []
var party_before: Array = []
var disclosures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--segment="):
			segment = arg.get_slice("=", 1)
		elif arg.begins_with("--save-dir="):
			save_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--receipt="):
			receipt_path = arg.get_slice("=", 1)
	if not SEGMENTS.has(segment) or save_dir.is_empty() or receipt_path.is_empty():
		failures.append("usage: --segment=<%s> --save-dir=<dir> --receipt=<json>" % "|".join(SEGMENTS))
		_finish()
		return
	if OS.get_environment("TB_WORLD_SEED").is_empty():
		failures.append("TB_WORLD_SEED must pin the world for a reproducible chain")
		_finish()
		return
	game = root.get_node("Game")
	# Installed before any title input, reset, world construction or autosave.
	game.set("save_system", SAVE.new(save_dir))
	print("EARNED CHAIN segment=%s save_dir=%s seed=%s" % [segment, save_dir, OS.get_environment("TB_WORLD_SEED")])
	match segment:
		"opening_team":
			await _opening_team()
		_:
			if await _load_previous():
				await _resumed_segment()
	if failures.is_empty():
		if not bool(game.call("save_game", CHAIN_SLOT)):
			failures.append("Game.save_game(%d) refused the segment save" % CHAIN_SLOT)
	_finish()


func _opening_team() -> void:
	if bool(game.call("has_save", CHAIN_SLOT)) or bool(game.call("has_save", 0)):
		failures.append("the fresh segment's save dir already holds a save")
		return
	var opening := OPENING.new()
	var live: Dictionary = await opening.run(self)
	if not _take(live, "passed", "opening"):
		return
	live = await opening.open_road_gate()
	if not _take(live, "passed", "road_gate"):
		return
	var village_failures: Array[String] = await VILLAGE.new().run(self,
		live["world"], live["game"], live["player"], live["rig"])
	if not village_failures.is_empty():
		failures.append_array(village_failures)
		return
	helper_receipts.append({"segment": "village", "passed": true})
	flags_before = []
	_take(await TEAM.new().run(self, current_scene, game), "passed", "team")


func _load_previous() -> bool:
	if not bool(game.call("has_save", CHAIN_SLOT)):
		failures.append("no previous-segment save in slot %d of %s" % [CHAIN_SLOT, save_dir])
		return false
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 10:
		await process_frame
	# The production Load list, then the chain slot's own button.
	var load_button := title.get("_load_button") as Button
	if load_button == null:
		failures.append("the production title has no Load button")
		return false
	load_button.pressed.emit()
	await process_frame
	var chosen: Button = null
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Save %d" % CHAIN_SLOT) \
				and not (node as Button).disabled:
			chosen = node
	if chosen == null:
		failures.append("the title's Load list does not offer Save %d" % CHAIN_SLOT)
		return false
	chosen.pressed.emit()
	var world: Node = null
	for _frame in 3600:
		await process_frame
		var scene := current_scene
		if scene != null and scene != title and is_instance_valid(scene) \
				and scene.get_node_or_null("Player") != null \
				and str(game.get("pending_realm_entry")).is_empty() \
				and bool(game.call("_realm_scene_ready", scene, str(game.get("current_realm")))):
			world = scene
			break
	if world == null:
		failures.append("the loaded save never reached a ready world scene")
		return false
	for _i in LOAD_SETTLE_FRAMES:
		await physics_frame
	for _i in 600:
		if INPUT_OWNER.current(self) == null:
			break
		await process_frame
	flags_before = (game.get("progression").call("all_set") as Array).duplicate()
	party_before = _party()
	print("EARNED CHAIN loaded realm=%s player=%s flags=%d party=%s" % [
		game.get("current_realm"), world.get_node("Player").global_position, flags_before.size(), JSON.stringify(party_before)])
	return true


func _resumed_segment() -> void:
	var world := current_scene as Node3D
	match segment:
		"camp_tournament":
			var player := world.get_node("Player") as CharacterBody3D
			var rig := world.get_node("CameraRig") as Node3D
			if not _take(await MATERIALS.new().run(self, world, game, player, rig, false), "passed", "materials"):
				return
			var camp := CAMP.new()
			if not _take(await camp.run(self, world, game, player, rig, false, false, false), "passed", "camp"):
				return
			if not _take(await REST.new().run(self, world, game, camp._beds, camp._bedroll, false), "passed", "rest"):
				return
			_take(await TOURNAMENT.new().run(self, world, game, player, rig), "passed", "tournament")
		"bridge":
			_take(await BRIDGE.new().run(self, world, game), "passed", "bridge")
		"warrens":
			_take(await WARRENS.new().run(self, world, game), "passed", "warrens")
		"relay":
			_take(await RELAY.new().run(self, world, game), "passed", "relay")
		"hall":
			_take(await HALL.new().run(self, world, game), "passed", "hall")
		"warden":
			_take(await (load(WARDEN_ACCEPT_PATH) as GDScript).new().run(self, world, game), "passed", "warden_accept")
			# The helper follows the production Rift callback into Cloudreach.
			for _i in 120:
				await physics_frame


func _take(result: Dictionary, key: String, label: String) -> bool:
	var receipts: Variant = result.get("receipts", result.get("transcript", []))
	helper_receipts.append({"segment": label, "passed": bool(result.get(key, false)),
		"receipts": JSON.parse_string(JSON.stringify(receipts))})
	for line: Variant in result.get("failures", []):
		failures.append("%s: %s" % [label, str(line)])
	for row: Variant in (receipts if receipts is Array else []):
		var beat := str((row as Dictionary).get("beat", "")) if row is Dictionary else ""
		if beat == "gate_prompt_assertion_bypassed":
			disclosures.append("bridge: the Meadows helper's 'gate must own the interact prompt' assertion was bypassed because ordinary play had already opened the South Bridge (south_bridge_open set, key spent); the stale '%s' battle offer ('offered a battle that could not start') remains an open Meadows defect" % "south_bridge_grunt")
		elif beat == "unreachable_node_skipped":
			disclosures.append("warrens: harvest order 16 rootstone (393,1802) skipped as physically unreachable (BLOCKERS.md B2, open Meadows defect); nothing later consumes rootstone, so no replacement gathering was needed")
		elif beat == "undertrail_mound_detour":
			disclosures.append("warrens: added an ordinary controller-walk detour west of the Warrens mound on the undertrail approach (BLOCKERS.md B3)")
		elif beat == "quarry_east_detour":
			disclosures.append("warrens: added an ordinary controller-walk detour east of the quarry pylon before the fourth rootstone (helper's direct leg stalls; BLOCKERS.md B2)")
		elif beat == "veridian_accepted":
			disclosures.append("warden: Veridian offer ACCEPTED with a full belt through the production farewell ceremony; released lowest-level earned member %s" % JSON.stringify((row as Dictionary).get("released", {})))
	if not bool(result.get(key, false)) and failures.is_empty():
		failures.append("%s returned %s=false" % [label, key])
	return failures.is_empty()


func _party() -> Array:
	var out: Array = []
	var party: RefCounted = game.get("party")
	if party == null:
		return out
	for member: Variant in (party.call("members") as Array):
		var c := member as RefCounted
		if c == null:
			continue
		out.append({"uid": str(c.get("uid")), "species": str(c.get("species_id")),
			"nickname": str(c.get("nickname")), "level": int(c.get("level")),
			"hp": int(c.get("hp")) if c.get("hp") != null else -1})
	return out


func _inventory() -> Dictionary:
	var stacks := {}
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return stacks
	for index in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", index)
		if stack.is_empty():
			continue
		var id := str(stack.get("id", ""))
		stacks[id] = int(stacks.get(id, 0)) + int(stack.get("n", 0))
	return stacks


func _finish() -> void:
	var flags_after: Array = []
	var location := {}
	if game != null:
		flags_after = (game.get("progression").call("all_set") as Array).duplicate()
		var scene := current_scene
		var player := scene.get_node_or_null("Player") as Node3D if scene != null else null
		location = {"realm": str(game.get("current_realm")), "scene": str(scene.name) if scene != null else "",
			"player": [player.global_position.x, player.global_position.y, player.global_position.z] if player != null else []}
	var gained: Array = []
	for flag: Variant in flags_after:
		if not flags_before.has(flag):
			gained.append(flag)
	gained.sort()
	var inventory := _inventory() if game != null else {}
	var key_items := {}
	for id: String in inventory:
		if id.contains("key") or id.contains("sigil") or id.contains("recipe") or id.contains("gear"):
			key_items[id] = inventory[id]
	var receipt := {
		"segment": segment,
		"passed": failures.is_empty(),
		"failures": failures,
		"world_seed_env": OS.get_environment("TB_WORLD_SEED"),
		"saved_world_seed": int(game.get("world_seed")) if game != null else 0,
		"wall_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
		"game_day": int(game.get("day")) if game != null else 0,
		"game_clock_seconds": float(game.get("clock_elapsed_seconds")) if game != null else -1.0,
		"location": location,
		"flags_gained": gained,
		"flags_total": flags_after.size(),
		"party_before": party_before,
		"party_after": _party() if game != null else [],
		"inventory": inventory,
		"key_items": key_items,
		"free_build": bool(game.get("free_build")) if game != null else false,
		"disclosures": disclosures,
		"helper_receipts": helper_receipts,
	}
	var file := FileAccess.open(receipt_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(receipt, "  "))
		file.close()
	print("EARNED CHAIN RESULT %s" % JSON.stringify({"segment": segment, "passed": failures.is_empty(),
		"wall_seconds": receipt.wall_seconds, "location": location, "failures": failures,
		"party": receipt.party_after, "flags_gained": gained.size()}))
	quit(0 if failures.is_empty() else 1)
