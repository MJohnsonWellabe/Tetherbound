extends "res://tests/smoke_f32_material_sites.gd"

## F27#1 actual-path witness for research task essence: the Journal is opened
## with `game_menu`, tabbed to Quests with `menu_tab_right`, its Research log
## opened with `ui_accept`, and a completed task's Claim button reached with
## `ui_down` and confirmed with `ui_accept` (tab_quest_log -> Session
## .request_research_claim -> research_actions.commit -> research_log claim).
## The payout is read from the isolated owner/world saves on disk.
##
##   godot --headless --path . --script tests/smoke_f27_research_claim_essence.gd
##
## 1. Claim terrapup "sight": disk gains exactly research_log.reward() of it,
##    with an accepted research_claim row and its research receipt.
## 2. The panel no longer offers that Claim, and replaying the same claim
##    request pays nothing.
##
## Disclosed fixtures (as smoke_f27_essence_node): isolated save dir, one
## owned Terrapup, opening free-play. The task's completion is SEEDED in the
## research log (terrapup seen, sight 1/1) before the world loads: its
## production trigger is engaging a wild (encounter_director _retain_research
## "sight"), which would leave this solo smoke inside a live fight before the
## claim. Not claimed: the event producer, two-peer, earned route, visuals.

const RESEARCH := preload("res://scripts/creatures/research_log.gd")
const SPECIES := "terrapup"
const TASK := "sight"


func _run() -> void:
	_realm = "meadows"
	_output = "user://f27_research_claim_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(_output)
	create_timer(600.0).timeout.connect(func() -> void:
		if not _finished:
			_check(false, "native watchdog expired")
			_finish())
	_game = root.get_node_or_null(^"Game")
	_saver = SAVE.new(_output.path_join("working"))
	_game.set("save_system", _saver)
	_game.call("reset_for_new_game")
	_game.set("current_realm", _realm)
	_game.get("local").set("character_id", "f27-research-owner")
	_game.get("world").set("world_id", "f27-research-world")
	_game.get("party").call("add", preload("res://scripts/creatures/creature_species.gd").spawn(SPECIES))
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	var task := RESEARCH.task_definition(SPECIES, TASK, RESEARCH.config())
	if not _check(not task.is_empty() and RESEARCH.config().get("runtime_enabled") == true, "research task %s/%s is configured and enabled" % [SPECIES, TASK]):
		_finish(); return
	var reward: Array = RESEARCH.reward(SPECIES, task)
	var personal: Dictionary = _game.get("local").get("redesign_character")
	var research_log: Dictionary = personal.get("research", RESEARCH.empty_log())
	if research_log.is_empty(): research_log = RESEARCH.empty_log()
	research_log.species[SPECIES] = {"seen": true, "caught": false, "tasks": {TASK: int(task.get("required", 1))}}
	personal.research = research_log
	_game.get("local").set("redesign_character", personal)
	if not _check(change_scene_to_file(SCENES[_realm]) == OK, "request actual Meadows scene"):
		_finish(); return
	for frame in 2400:
		await process_frame
		if current_scene != null and current_scene.has_method("shell_build_complete") \
			and current_scene.call("shell_build_complete") == true:
			_world = current_scene as Node3D
			break
	if not _check(_world != null, "Meadows procedural build completed"):
		_finish(); return
	_player = _game.call("find_player") as CharacterBody3D
	_driver = DRIVER.new()
	_driver.set("_tree", self)
	_driver.set("_world", _world)
	_driver.set("_game", _game)
	_driver.set("_player", _player)
	_driver.set("_rig", _world.get_node_or_null(^"CameraRig"))
	_driver.set("_arbiter", get_first_node_in_group(&"interaction_arbiter"))
	if not _check(_player != null and _driver.call("_resolve_move_bindings") == true, "production player and controller driver"):
		_finish(); return
	await _frames(60)
	_saver.call("finish_fallback")
	if not _check(_saver.call("save_world_prepared", _game, str(_game.get("world").world_id)) == true \
		and _saver.call("save_character_prepared", _game, str(_game.get("local").character_id)) == true,
		"pre-claim owner and world saved to isolated disk"):
		_finish(); return
	var before := _disk("before")
	if not await _open_research_log(): _finish(); return
	var claim_key := "claim:%s:%s" % [SPECIES, TASK]
	if not _check(await _focus_by_ui_down(claim_key), "ui_down reaches the %s Claim button" % claim_key):
		_finish(); return
	await _driver.call("_tap_action", &"ui_accept")
	await _frames(240)
	var after := _disk("after")
	var cid := str(_game.get("local").character_id)
	var receipt := "research:%s:%s:%s" % [SPECIES, TASK, cid]
	for stack: Dictionary in reward:
		var gained := _count(after.character, str(stack.id)) - _count(before.character, str(stack.id))
		_check(gained == int(stack.n), "1 disk gained exactly %d %s (delta %d)" % [int(stack.n), str(stack.id), gained])
	var row: Dictionary = {}
	for value: Variant in after.world.get("reward_deliveries", {}).values():
		if value is Dictionary and value.get("action") == "research_claim" and value.get("receipt") == receipt: row = value
	var personal_after: Dictionary = after.character.get("redesign_character", {})
	_check(row.get("status") == "accepted" and personal_after.get("research_receipts", []).has(receipt)
		and personal_after.get("transaction_receipts", []).has(receipt), "1 accepted research_claim row and receipt %s on disk" % receipt)
	await _frames(60)
	_check(_button(claim_key) == null, "2 the paid task no longer offers Claim")
	var replay: Dictionary = _game.get("session").call("request_research_claim", {"species_id": SPECIES, "task_id": TASK})
	await _frames(120)
	var again := _disk("again")
	for stack: Dictionary in reward:
		_check(_count(again.character, str(stack.id)) == _count(after.character, str(stack.id)),
			"2 replayed claim pays no more %s (%s)" % [str(stack.id), JSON.stringify(replay).left(160)])
	print("F27_RESEARCH_CLAIM: %s %s/%s paid %s" % ["PASS" if not _failed else "FAIL", SPECIES, TASK, str(reward)])
	_finish()


func _open_research_log() -> bool:
	await _driver.call("_tap_action", &"game_menu")
	var menu: Node = _game.call("menu")
	if not _check(menu != null and menu.call("is_open") == true, "game_menu opens the Journal"): return false
	# Step tab by tab, judging each only after it settles; step back on an overshoot.
	for i in 16:
		await _frames(10)
		var tab := str(menu.call("current_tab_id"))
		print("RESEARCH DIAG tab step %d: %s" % [i, tab])
		if tab == "quest_log": break
		await _driver.call("_tap_action", &"menu_tab_left" if tab == "build" else &"menu_tab_right")
	await _frames(10)
	if not _check(menu.call("current_tab_id") == "quest_log", "menu_tab_right reaches the Quests tab"): return false
	await _frames(10)
	var focus := root.gui_get_focus_owner()
	print("RESEARCH DIAG tab=%s focus=%s" % [str(menu.call("current_tab_id")), str(focus.get_path()) if focus != null else "none"])
	for i in 24:
		if focus is Button and str((focus as Button).text).begins_with("Research log"): break
		await _driver.call("_tap_action", &"ui_up" if i < 12 else &"ui_down")
		await _frames(4)
		focus = root.gui_get_focus_owner()
		print("RESEARCH DIAG step %d tab=%s focus=%s" % [i, str(menu.call("current_tab_id")), str(focus.get_path()) if focus != null else "none"])
	if not _check(focus is Button and str((focus as Button).text).begins_with("Research log"),
		"ui_up/ui_down reach the Research log button (focus '%s')" % (str((focus as Button).text) if focus is Button else str(focus))):
		return false
	await _driver.call("_tap_action", &"ui_accept")
	for frame in 120:
		if _button("species:" + SPECIES) != null: return _check(true, "ui_accept opens the Research log panel")
		await physics_frame
	return _check(false, "ui_accept opens the Research log panel")


func _focus_by_ui_down(key: String) -> bool:
	for i in 40:
		var focus := root.gui_get_focus_owner()
		if focus != null and focus.get_meta("system_focus_key", "") == key: return true
		await _driver.call("_tap_action", &"ui_down")
		await _frames(4)
	return false


func _button(key: String) -> Button:
	for node: Node in root.find_children("*", "Button", true, false):
		if node.get_meta("system_focus_key", "") == key and (node as Button).is_visible_in_tree(): return node as Button
	return null
