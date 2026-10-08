extends SceneTree

## Gate A's production-faithful opening preflight, as one uninterrupted run.
##
## This intentionally does not use the shortcuts in smoke_catching.gd: no
## direct starter adoption, inventory seeding, teleport, HP assignment, or
## camera-yaw assignment. Every player action starts as a physical joypad event
## and travels through the live InputMap. State is read only to know when the
## next visible action is ready and to print useful checkpoint timings.

const OPENING_DRIVE := preload("res://tests/helpers/gate_a_opening_drive.gd")
const NPC_GATHER_SEGMENT := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const MATERIAL_ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const CAMPSITE_SEGMENT := preload("res://tests/helpers/gate_a_campsite_segment.gd")
const CONTINUOUS_CORE_FLAG := "--gate-a-continuous-core"
const LESSON_RELOAD_FLAG := "--lesson-reload-witness"
const LESSON_RULES := preload("res://scripts/onboarding/lesson_rules.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _lesson_reload := false
var _lesson_reload_observer: Callable


func _init() -> void:
	_run()


## The opening itself now lives in `tests/helpers/gate_a_opening_drive.gd`.
##
## It moved on 2026-08-23 so Gate B could PLAY the opening rather than grant it
## -- see that file's header for the measurements that forced it. This file is
## unchanged in what it asserts: the same drive, the same checkpoints, the same
## pass condition. What it no longer is, is the ONLY place that knows how to
## walk the opening.
func _run() -> void:
	if not _lesson_reload_options_valid():
		_finish()
		return
	if _lesson_reload and OS.get_cmdline_user_args().has("--functional-offload") \
		and not preload("res://tests/helpers/f19_functional_offload.gd").configure("full_fresh_campaign"):
		_failures.append("lesson reload: existing Compatibility functional offload refused")
		_finish()
		return
	var opening: Dictionary = await OPENING_DRIVE.new().run(self)
	for line: Variant in (opening.get("transcript", []) as Array):
		print("GATE A OPENING — %s" % str(line))
	for line: Variant in (opening.get("failures", []) as Array):
		_failures.append(str(line))
	_world = opening.get("world") as Node
	_game = opening.get("game") as Node
	_player = opening.get("player") as CharacterBody3D
	_rig = opening.get("rig") as Node3D

	if _failures.is_empty() and OS.get_cmdline_user_args().has(CONTINUOUS_CORE_FLAG):
		await _run_continuous_core()
	if _failures.is_empty() and _lesson_reload:
		await _run_lesson_reload_witness()
	_finish()


## Opt-in durability observation on the same naturally earned endpoint. This
## mode deliberately excludes the independent continuous-core continuation.
func _lesson_reload_options_valid() -> bool:
	var args := OS.get_cmdline_user_args()
	for arg: String in args:
		if arg.begins_with(LESSON_RELOAD_FLAG): _lesson_reload = true
	if not _lesson_reload: return true
	for option: String in [LESSON_RELOAD_FLAG, "--lesson-controller-witness", "--lesson-replay-witness"]:
		var matches: Array[String] = []
		for arg: String in args:
			if arg.begins_with(option): matches.append(arg)
		if not _reload_check(matches.size() == 1 and matches[0] == option,
			"reload witness requires exactly one valueless " + option): return false
	for arg: String in args:
		if not _reload_check(not arg.begins_with(CONTINUOUS_CORE_FLAG),
			"lesson reload witness cannot combine with the continuous core"): return false
	return true


func _run_lesson_reload_witness() -> void:
	var service := _game.get_node_or_null("OnboardingLessons")
	var combat := _world.get_node_or_null("CombatManager")
	if not _reload_check(current_scene == _world and not paused and INPUT_OWNER.current(self) == null \
		and _player.is_on_floor() and bool(_player.call("locomotion_enabled")) and _game.pending_catch == null \
		and combat != null and not bool(combat.call("is_fighting")) and str(combat.call("outcome")) == "caught" \
		and _game.party.size() == 2 and service != null and (service.get("_pending") as Dictionary).is_empty(),
		"lesson reload must start at the completed natural catch with free, settled world input"): return
	var before := _lesson_reload_state()
	if not _reload_check(not str(before.character_id).is_empty() and bool(before.home_key_ack) \
		and bool(before.home_key_given) and int(before.home_key_count) == 1,
		"lesson reload needs this character's acknowledged natural Home Key and sole key"): return
	var seen_uids: Array[String] = []
	for uid: String in before.party_uids:
		if not _reload_check(not uid.is_empty() and not seen_uids.has(uid), "lesson reload needs distinct original creature UIDs"): return
		seen_uids.append(uid)
	var slot := int(_game.call("autosave_slot"))
	if not _reload_check(bool(_game.call("save_game", slot)), "production autosave refused the acknowledged natural-catch state"): return
	if not _reload_check(_lesson_reload_state() == before, "autosave changed stable identity, rewards or move loadout"): return
	# Resolve the existing reader after the opening; its care adapter imports
	# the opening drive. Only tap() is used, with its actual joypad binding mode.
	var travel_script := load("res://tests/helpers/f20_portal_travel.gd") as GDScript
	if not _reload_check(travel_script != null, "lesson reload could not load its existing physical-input adapter"): return
	var travel: RefCounted = travel_script.new(self, _game)
	travel.set("_lesson_controller_input", true)
	if not _reload_check(change_scene_to_file(OPENING_DRIVE.TITLE_SCENE) == OK,
		"lesson reload could not open the production title"): return
	for frame in 10: await process_frame
	var title := current_scene
	if not _reload_check(title != null and title.scene_file_path == OPENING_DRIVE.TITLE_SCENE,
		"lesson reload did not reach the actual title"): return
	# Clear live memory only after the outgoing world is destroyed. The saved
	# bytes and the production SaveGame instance remain the ones just written.
	_game.call("reset_for_new_game")
	if not _reload_check(_game.party.size() == 0 and _game.inventory.call("count", "home_key") == 0 \
		and _game.local.flags.call("has", LESSON_RULES.PREFIX + "home_key") == false,
		"lesson reload did not clear the old in-memory party/key/acknowledgement"): return
	var reopened: Array[bool] = [false]
	_lesson_reload_observer = func() -> void:
		var lessons := _game.get_node_or_null("OnboardingLessons")
		var panel: Node = lessons.get("_panel") if lessons != null else null
		if is_instance_valid(panel) and panel.call("is_open") == true \
			and str((panel.get("_row") as Dictionary).get("id", "")) == "home_key": reopened[0] = true
	process_frame.connect(_lesson_reload_observer)
	var load_button := title.get("_load_button") as Button
	if not _reload_check(load_button != null and not load_button.disabled, "production title has no enabled Load Game"): return
	for step in 8:
		if root.gui_get_focus_owner() == load_button: break
		await travel.tap("ui_down")
	if not _reload_check(root.gui_get_focus_owner() == load_button, "physical title navigation did not focus Load Game"): return
	await travel.tap("ui_accept")
	var autosave := root.gui_get_focus_owner() as Button
	if not _reload_check(autosave != null and not autosave.disabled and autosave.text.begins_with("Autosave —"),
		"physical Load Game did not offer the saved autosave"): return
	await travel.tap("ui_accept")
	if not _reload_check((travel.get("failures") as Array).is_empty(), "physical title input adapter reported a failure"): return
	var ready := false
	var ready_frames := 0
	for frame in 7200:
		await process_frame
		if not _reload_check(not reopened[0], "Home Key card reopened during actual title Load"): return
		if current_scene != null and current_scene.scene_file_path == OPENING_DRIVE.WORLD_SCENE \
			and bool(travel.call("_ready_world", "meadows")):
			ready = true
			ready_frames = frame + 1
			break
	if not _reload_check(ready, "actual title Load did not restore a ready Meadows world within 7200 frames"): return
	_world = current_scene
	_player = _world.get_node_or_null("Player") as CharacterBody3D
	_rig = _world.get_node_or_null("CameraRig") as Node3D
	for frame in 300:
		await process_frame
		if not _reload_check(not reopened[0] and str(LESSON_RULES.due(_game.local).get("id", "")) != "home_key",
			"acknowledged Home Key became naturally due or reopened after disk Load"): return
	service = _game.get_node_or_null("OnboardingLessons")
	var after := _lesson_reload_state()
	if before != after:
		print("F46 LESSON RELOAD STATE MISMATCH " + JSON.stringify({"before": before, "after": after}))
	if not _reload_check(before == after, "disk Load changed stable character/party identity, rewards, flags or move loadout"): return
	if not _reload_check(_player != null and _player.is_on_floor() and bool(_player.call("locomotion_enabled")) \
		and not paused and INPUT_OWNER.current(self) == null and _game.pending_catch == null \
		and not Input.is_action_pressed("ui_down") and not Input.is_action_pressed("ui_accept") \
		and service != null and str(service.get("_identity")) == str(before.character_id) \
		and (service.get("_pending") as Dictionary).is_empty() and LESSON_RULES.available("home_key", _game.local),
		"loaded Home Key witness did not settle with its original character and free world input"): return
	print("F46 LESSON RELOAD WITNESS " + JSON.stringify({"passed": true, "save_slot": slot,
		"memory_cleared_before_load": true, "physical_title_load": true, "ready_frames": ready_frames,
		"settle_frames": 300, "before": before, "after": after, "home_key_card_reopened": reopened[0],
		"natural_due_lesson": str(LESSON_RULES.due(_game.local).get("id", "")),
		"scope": "Home Key acknowledgement survives actual autosave/title Load and is not naturally eligible again; no teacher return, other lessons or full F46 claim"}))


## Stable rewards/loadout only: HP, food, rest and world clocks keep advancing.
func _lesson_reload_state() -> Dictionary:
	var party: Array[Dictionary] = []
	var uids: Array[String] = []
	for member: RefCounted in _game.party.members():
		var card := {}
		for field: String in ["uid", "species_id", "nickname", "level", "xp", "known_moves", "move_quick",
			"move_charged", "move_utility", "move_ultimate", "move_mastery_uses", "move_mastery_receipts",
			"loadout_revision", "loadout_last_edit"]:
			card[field] = member.get(field)
		party.append(card)
		uids.append(str(member.uid))
	var inventory: Array = []
	for slot: int in int(_game.inventory.call("slot_count")):
		inventory.append(_game.inventory.call("stack_at", slot))
	var flags: Array = _game.local.flags.call("all_set").duplicate()
	flags.sort()
	return {"character_id": str(_game.local.character_id), "party_uids": uids, "party": party,
		"inventory": inventory, "personal_flags": flags, "home_key_count": _game.inventory.call("count", "home_key"),
		"home_key_given": _game.local.flags.call("has", "home_key_given"),
		"home_key_ack": _game.local.flags.call("has", LESSON_RULES.PREFIX + "home_key")}.duplicate(true)


func _reload_check(condition: bool, message: String) -> bool:
	if not condition: _failures.append("lesson reload: " + message)
	return condition


## Optional canonical-session continuation. It deliberately shares the
## already-running production world and does not seed state, load another scene,
## or use fixture positioning.
func _run_continuous_core() -> void:
	print("GATE A OPENING — continuous core: village, material, and paid-build segments")
	var npc_failures: Array[String] = await NPC_GATHER_SEGMENT.new().run(
		self, _world, _game, _player, _rig)
	if not npc_failures.is_empty():
		for failure: String in npc_failures:
			_failures.append("NPC/gather continuation: %s" % failure)
		return
	var material_route = MATERIAL_ROUTE.new()
	var route: Dictionary = await material_route.run(self, _world, _game, _player, _rig)
	for line: Variant in (route.get("transcript", []) as Array):
		print("GATE A MATERIAL — %s" % str(line))
	if not bool(route.get("passed", false)):
		for failure: Variant in (route.get("failures", []) as Array):
			_failures.append("material route: %s" % str(failure))
		return
	# The CURRENT paid build: tent, campfire, bedroll and three creature beds,
	# exactly what the material route funds. The legacy house segment
	# (`gate_a_build_segment.gd`, 39 wood / 34 stone) is no longer the paid
	# build; see `gate_a_campsite_segment.gd`'s header.
	var built: Dictionary = await CAMPSITE_SEGMENT.new().run_campsite(
		self, _world, _game, _player, _rig, material_route)
	for line: Variant in (built.get("transcript", []) as Array):
		print("GATE A PAID BUILD — %s" % str(line))
	if not bool(built.get("passed", false)):
		for failure: Variant in (built.get("failures", []) as Array):
			_failures.append("paid build: %s" % str(failure))


func _finish() -> void:
	if _lesson_reload_observer.is_valid() and process_frame.is_connected(_lesson_reload_observer):
		process_frame.disconnect(_lesson_reload_observer)
	print("")
	if _failures.is_empty():
		print("gate A opening segment: OK — title through natural catch%s passed continuously with parsed controller input" % (
			", village, material route and paid campsite" if OS.get_cmdline_user_args().has(CONTINUOUS_CORE_FLAG) else ""))
		quit(0)
		return
	for line: String in _failures:
		print("gate A opening segment FAIL: %s" % line)
	quit(1)
