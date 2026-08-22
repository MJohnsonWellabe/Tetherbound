extends SceneTree

## RG1 / Phase -1.7 production-faithful regression for the intermittent
## post-modal freeze reported on the ROG Ally.
##
##   godot --headless --path . --script tests/smoke_post_modal_control.gd
##
## All player-facing transitions use raw InputMap-backed joypad events. Three
## mixed cycles run in one loaded Meadows world:
## Bram/service -> bed/Rest -> world Build -> pause-menu Build -> pause checks.
## The one direct pending_build assignment creates the bed fixture before the
## regression; its interaction, Rest selection, and exit are real input.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SETTLE_FRAMES := 240
const STRESS_CYCLES := 3
const MOVE_ACTIONS: Array[String] = ["move_forward", "move_back", "move_left", "move_right"]

var _failures: Array[String] = []
var _game: Node
var _menu: CanvasLayer
var _world: Node
var _player: CharacterBody3D
var _arbiter: Node
var _bed: Node3D
var _probe_serial := 0


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	_menu = _game.call("menu") if _game != null else null
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_arbiter = get_first_node_in_group("interaction_arbiter")
	if _game == null or _menu == null or _player == null or _arbiter == null:
		_fail("world did not stand up Game/menu/Player/InteractionArbiter")
		_report()
		return

	await _prepare_fixture()
	_bed = await _place_bed_fixture()
	if _bed == null:
		_report()
		return

	for cycle in STRESS_CYCLES:
		print("\nmodal stress cycle %d/%d" % [cycle + 1, STRESS_CYCLES])
		await _exercise_bram(cycle)
		await _pause_round_trip("cycle %d after Bram" % (cycle + 1))
		await _exercise_bed(cycle)
		await _pause_round_trip("cycle %d after bed" % (cycle + 1))
		await _exercise_world_build(cycle)
		await _exercise_pause_build(cycle)
		await _pause_round_trip("cycle %d after Build" % (cycle + 1))
	_report()


## The smoke is about post-opening UI. Move the director to its documented
## terminal beat and seed one real party member; no owner-facing path below is
## invoked through a private call.
func _prepare_fixture() -> void:
	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")
	var party: RefCounted = _game.get("party")
	while party != null and int(party.call("size")) < 1:
		var creature: RefCounted = _game.call("make_creature", "terrapup")
		if creature == null or not bool(party.call("add", creature)):
			break
	if party == null or int(party.call("size")) < 1:
		_fail("fixture: could not seed a party creature")
	_game.set("free_build", true)
	for i in 12:
		await physics_frame


## Genuine BuildPlacer-produced bed. Direct arming is fixture setup only; both
## Build regressions below select their pieces through the actual menu.
func _place_bed_fixture() -> Node3D:
	await _teleport_to(Vector3(70.0, 0.0, 70.0))
	_game.set("pending_build", "creature_bed")
	for i in 20:
		await physics_frame
	var before := _placed_count("creature_bed")
	await _tap("build_place")
	for i in 20:
		await physics_frame
	_game.set("pending_build", "")
	if _placed_count("creature_bed") != before + 1:
		_fail("fixture: BuildPlacer did not place a creature bed")
		return null
	for node: Node in get_nodes_in_group("placed_building"):
		if str(node.get_meta("building_id", "")) == "creature_bed":
			return node as Node3D
	_fail("fixture: placed creature bed is absent from placed_building")
	return null


## Bram is the innkeeper and owns a real shop service. Reach his Interactable
## through the arbiter, advance dialogue, buy once, and leave with B.
func _exercise_bram(cycle: int) -> void:
	var bram := _world.find_child("Bram", true, false) as Node3D
	var prompt := bram.get_node_or_null(^"Interactable") as Node3D if bram != null else null
	if bram == null or prompt == null:
		_fail("Bram cycle %d: innkeeper or Interactable missing" % (cycle + 1))
		return
	# Seed before opening so the panel builds an enabled stock row. Adding coin
	# after open would correctly leave the already-built Button disabled.
	if cycle == 0:
		(_game.get("inventory") as RefCounted).call("add", "coin", 100)
	# Bram stands behind the inn counter. Approach along his authored +Z/front
	# direction so the harness lands on the customer side instead of inside the
	# counter collision (which correctly permits no movement in any direction).
	await _teleport_near(prompt, bram.global_transform.basis.z * 2.0)
	if not await _wait_provider(prompt):
		_fail("Bram cycle %d: prompt never won (%s)" % [cycle + 1, _diagnostics()])
		return
	await _tap("interact")
	var dialogue := get_first_node_in_group("dialogue_panel")
	if dialogue == null or not bool(dialogue.call("is_open")):
		_fail("Bram cycle %d: interact did not open dialogue" % (cycle + 1))
		return
	var guard := 0
	while bool(dialogue.call("is_open")) and guard < 20:
		await _tap("interact")
		guard += 1
	if bool(dialogue.call("is_open")):
		_fail("Bram cycle %d: dialogue stayed open" % (cycle + 1))
		return
	var shop := await _wait_open_panel("vendor_id")
	if shop == null or str(shop.call("vendor_id")) != "bram":
		_fail("Bram cycle %d: no service handoff" % (cycle + 1))
		return
	if cycle == 0:
		var inventory: RefCounted = _game.get("inventory")
		var coins_before := int(inventory.call("count", "coin"))
		await _tap("ui_accept")
		if int(inventory.call("count", "coin")) >= coins_before:
			_fail("Bram service: A on focused stock did not buy")
		else:
			print("Bram service: purchase completed through focused joypad UI")
	await _tap("menu_cancel")
	if bool(shop.call("is_open")):
		_fail("Bram cycle %d: B did not close service" % (cycle + 1))
		return
	await _control_returned("Bram cycle %d" % (cycle + 1))


func _exercise_bed(cycle: int) -> void:
	var prompt := _bed.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("bed cycle %d: no Interactable" % (cycle + 1))
		return
	await _teleport_near(prompt)
	if not await _wait_provider(prompt):
		_fail("bed cycle %d: prompt never won (%s)" % [cycle + 1, _diagnostics()])
		return
	await _tap("interact")
	var panel := await _wait_open_script("creature_bed_panel.gd")
	if panel == null:
		_fail("bed cycle %d: interact did not open Rest UI" % (cycle + 1))
		return
	var before := int(_bed.call("occupant_index"))
	await _tap("ui_accept")
	var after := int(_bed.call("occupant_index"))
	if after == before:
		_fail("bed cycle %d: focused A did not Rest/wake" % (cycle + 1))
	else:
		print("creature bed: Rest state changed %d -> %d through joypad UI" % [before, after])
	await _tap("menu_cancel")
	if bool(panel.call("is_open")):
		_fail("bed cycle %d: B did not close Rest UI" % (cycle + 1))
		return
	await _control_returned("bed cycle %d" % (cycle + 1))


func _exercise_world_build(cycle: int) -> void:
	await _teleport_to(Vector3(100.0 + cycle * 24.0, 0.0, 80.0))
	var before := _placed_total()
	# CONTROLLER-MAP, ralph/OWNER_DIRECTIVES_2026-08-22.md section 1: "Build
	# hammer is the same pattern: select it, press interact, you are in build
	# mode. `build_open` loses its button." It is keyboard-only now, so tapping
	# it on a pad opened nothing and this reported Build as broken. Equip the
	# hammer and press interact, which is `playground_hud.gd::
	# _hammer_opens_the_catalogue()` -- the real player route.
	_game.set("equipped_tool", "hammer")
	for _i in 4:
		await process_frame
	await _tap("interact")
	var build_menu := await _wait_open_group("build_menu")
	# Put the hammer away whatever happened next. Left in hand, every later
	# `interact` in this stress loop opens the catalogue instead of talking to
	# Bram or using the bed -- `playground_hud.gd::_hammer_opens_the_catalogue()`
	# reads the equipped tool, not a mode flag.
	_game.set("equipped_tool", "")
	if build_menu == null:
		_fail("world Build cycle %d: the hammer + interact opened nothing%s" % [
			cycle + 1, _why_the_hammer_was_refused(),
		])
		return
	await _tap("ui_accept")
	await _finish_placement("world Build cycle %d" % (cycle + 1), before)


func _exercise_pause_build(cycle: int) -> void:
	await _teleport_to(Vector3(100.0 + cycle * 24.0, 0.0, 110.0))
	var before := _placed_total()
	await _tap("game_menu")
	if not await _settles(func() -> bool: return bool(_menu.call("is_open")) and paused):
		_fail("pause Build cycle %d: Menu did not open main menu" % (cycle + 1))
		return
	var guard := 0
	while str(_menu.call("current_tab_id")) != "build" and guard < 8:
		await _tap("menu_tab_right")
		guard += 1
	if str(_menu.call("current_tab_id")) != "build":
		_fail("pause Build cycle %d: RB never reached Build" % (cycle + 1))
		return
	await _tap("ui_accept")
	var build_menu := await _wait_open_group("build_menu")
	if build_menu == null:
		_fail("pause Build cycle %d: A did not hand off" % (cycle + 1))
		return
	if paused or bool(_menu.call("is_open")):
		_fail("pause Build cycle %d: stale shell/pause (%s)" % [cycle + 1, _diagnostics()])
		return
	await _tap("ui_accept")
	await _finish_placement("pause Build cycle %d" % (cycle + 1), before)


func _finish_placement(context: String, before: int) -> void:
	if str(_game.get("pending_build")).is_empty():
		_fail("%s: focused A armed no piece" % context)
		return
	for i in 15:
		await physics_frame
	await _tap("build_place")
	for i in 20:
		await physics_frame
	if _placed_total() != before + 1:
		_fail("%s: X placed nothing" % context)
		return
	# Placement is intentionally persistent; B cancels it without reopening UI.
	await _tap("build_cancel")
	if not str(_game.get("pending_build")).is_empty() or bool(_menu.call("is_open")):
		_fail("%s: B left placement/menu state (%s)" % [context, _diagnostics()])
		return
	await _control_returned(context)


func _control_returned(context: String) -> void:
	if paused or INPUT_OWNER.current(self) != null:
		_fail("%s: ownership not released (%s)" % [context, _diagnostics()])
		return
	var result: Dictionary = await _movement_attempt()
	# Bram's customer spot is intentionally tight and a following creature can
	# arrive on top of it between repeated visits. A zero-distance first probe
	# with otherwise healthy ownership is ambiguous collision, not evidence of
	# a modal freeze. Retry on a known open meadow coordinate; stale locomotion
	# still fails there, while counter/follower obstruction does not.
	if float(result.get("distance", 0.0)) < 0.3:
		_probe_serial += 1
		await _teleport_to(Vector3(180.0 + _probe_serial * 9.0, 0.0, 150.0))
		result = await _movement_attempt()
	var best := float(result.get("distance", 0.0))
	var best_action := str(result.get("action", ""))
	if best < 0.3:
		_fail("%s: locomotion stayed below %.2fm (%s)" % [context, best, _diagnostics()])
	else:
		print("%s: control returned via %s (%.2fm)" % [context, best_action, best])


func _movement_attempt() -> Dictionary:
	var best := 0.0
	var best_action := ""
	for action in MOVE_ACTIONS:
		var start := _player.global_position
		_player.velocity = Vector3.ZERO
		Input.action_press(action)
		for i in 30:
			await physics_frame
		Input.action_release(action)
		for i in 4:
			await physics_frame
		var drift := Vector2(_player.global_position.x - start.x, _player.global_position.z - start.z).length()
		if drift > best:
			best = drift
			best_action = action
		if drift >= 0.3:
			break
	return {"distance": best, "action": best_action}


func _pause_round_trip(context: String) -> void:
	if paused or INPUT_OWNER.current(self) != null:
		_fail("%s: cannot begin pause check (%s)" % [context, _diagnostics()])
		return
	# CONTROLLER-MAP: "Menu | game menu", "B | hotbar 1" and, in a menu, back.
	# B never OPENED the pause shell after the remap -- `game_menu` is button 6
	# (Menu/Start) and `menu_cancel` is B, so this asked the wrong button to
	# open and then reported the shell as broken. Open on Menu, back out on B,
	# which is the round trip a player actually makes.
	await _tap("game_menu")
	if not await _settles(func() -> bool: return bool(_menu.call("is_open")) and paused):
		_fail("%s: Menu could not reopen pause (%s)" % [context, _diagnostics()])
		return
	await _tap("menu_cancel")
	if not await _settles(func() -> bool: return not bool(_menu.call("is_open")) and not paused):
		_fail("%s: B could not close pause (%s)" % [context, _diagnostics()])
		return
	await _control_returned(context + " recovery")


## Raw physical button from the live InputMap. This exposes shared-button B
## edges that Input.action_press and direct close calls cannot reproduce.
func _tap(action: String) -> void:
	var index := _pad_button_for(action)
	if index < 0:
		_fail("InputMap action '%s' has no joypad button" % action)
		return
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 5:
		await process_frame


## Wait, bounded, for a tapped press to actually take effect.
##
## Asserting on the frame immediately after the release is a race, and it is
## the reason this file reported "B could not close pause" against a shell that
## demonstrably opens and closes cleanly: `tools/_probe_pause.gd` drove the
## same two physical buttons through the same live InputMap and got
## open=true/paused=true then open=false/paused=false, twice running. The shell
## is PROCESS_MODE_ALWAYS and closes on its own `_process` turn, which is not
## guaranteed to be inside the five frames `_tap` happened to wait.
##
## Still fails if the state never arrives -- this waits for a verdict, it does
## not assume one. A pause menu that genuinely would not close still fails here,
## just after 90 frames instead of 5.
func _settles(predicate: Callable) -> bool:
	for _i in 90:
		if bool(predicate.call()):
			return true
		await process_frame
	return false


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else _player.global_position.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 12:
		await physics_frame


func _teleport_near(prompt: Node3D, offset: Vector3 = Vector3(0.35, 0.0, 0.35)) -> void:
	var at := prompt.global_position + offset
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else _player.global_position.y
	_player.global_position = Vector3(at.x + 0.35, y + 0.2, at.z + 0.35)
	_player.velocity = Vector3.ZERO
	for i in 15:
		await physics_frame


func _wait_provider(provider: Node) -> bool:
	for i in 30:
		await physics_frame
		if _arbiter.call("winning_provider") == provider:
			return true
	return false


func _wait_open_panel(method: String) -> Node:
	for i in 30:
		await process_frame
		for node: Node in root.get_children():
			if node.has_method(method) and node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _wait_open_script(suffix: String) -> Node:
	for i in 30:
		await process_frame
		for node: Node in get_nodes_in_group(INPUT_OWNER.GROUP):
			var script: Script = node.get_script() as Script
			if script != null and str(script.resource_path).ends_with(suffix) and node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _wait_open_group(group: String) -> Node:
	for i in 30:
		await process_frame
		for node: Node in get_nodes_in_group(group):
			if node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _placed_total() -> int:
	return get_nodes_in_group("placed_building").size()


func _placed_count(id: String) -> int:
	var count := 0
	for node: Node in get_nodes_in_group("placed_building"):
		if str(node.get_meta("building_id", "")) == id:
			count += 1
	return count


func _diagnostics() -> String:
	var owner := INPUT_OWNER.current(self)
	var owners: Array[String] = []
	for node: Node in get_nodes_in_group(INPUT_OWNER.GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			owners.append(str(node.get_path()))
	var focus := root.get_viewport().gui_get_focus_owner()
	return "paused=%s mouse=%d owner=%s active=%s menu=%s pending='%s' arbiter=%s physics=%s focus=%s cancel[p=%s,jp=%s,jr=%s]" % [paused, Input.mouse_mode, str(owner.get_path()) if owner != null else "none", str(owners), bool(_menu.call("is_open")), str(_game.get("pending_build")), str(_arbiter.get("_enabled")), _player.is_physics_processing(), str(focus.get_path()) if focus != null else "none", Input.is_action_pressed("menu_cancel"), Input.is_action_just_pressed("menu_cancel"), Input.is_action_just_released("menu_cancel")]


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: %s" % message)


func _cleanup() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)
	if _game != null:
		_game.set("free_build", false)
		_game.set("pending_build", "")
	if paused:
		paused = false


func _report() -> void:
	_cleanup()
	print("")
	if _failures.is_empty():
		print("post-modal control smoke passed: %d mixed real-joypad cycles" % STRESS_CYCLES)
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## Which of `_hammer_opens_the_catalogue()`'s refusals is live.
##
## "Opened nothing" names a symptom shared by five different causes, and this
## harness exists to catch the one where a closed modal never gave the world its
## input back. Reporting the cause is the difference between a failure that says
## where to look and one that starts another investigation from scratch.
func _why_the_hammer_was_refused() -> String:
	var hud: Node = _world.find_child("PlaygroundHUD", true, false) if _world != null else null
	if hud == null:
		return " (no PlaygroundHUD in the scene)"
	var reasons: Array[String] = []
	if str(_game.get("equipped_tool")) != "hammer":
		reasons.append("equipped_tool is '%s', not the hammer" % str(_game.get("equipped_tool")))
	var arbiter: Object = hud.get("_arbiter")
	if arbiter != null and is_instance_valid(arbiter):
		if not bool(arbiter.call("enabled")):
			reasons.append("the interaction arbiter is DISABLED (a modal never released the world)")
		elif arbiter.call("winning_provider") != null:
			reasons.append("a prompt provider is winning the interact button")
	var owner_node: Variant = INPUT_OWNER.current(self)
	if owner_node != null:
		reasons.append("INPUT_OWNER is still held by %s" % str(owner_node))
	if bool(_game.get("pending_build") != ""):
		reasons.append("pending_build is already armed as '%s'" % str(_game.get("pending_build")))
	if reasons.is_empty():
		return " (and none of the known refusals is live -- the press itself did not land)"
	return " (" + "; ".join(reasons) + ")"
