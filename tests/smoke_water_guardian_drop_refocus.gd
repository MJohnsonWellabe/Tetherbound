extends SceneTree

## Regression (TIDEWAKE, X05 f14_guardian_offer_capacity_space_drop #29): a
## Guardian offer at a FULL belt is on the Creatures tab's release choice when
## the live character is reloaded out from under it (a dropped link, the
## returning route blanking and reloading the character, another screen taking
## focus meanwhile). When the durable claim is presented again, the release
## choice must come back with controller focus on the ceremony -- not on
## nothing -- so a pad-only player can still pick who goes free.
##
## Fixture (disclosed): already freed Guardian, five ordinary companions, the
## player placed at the chamber prompt; the reload is `local.load_data({})`
## followed by the same five coming back, and a throwaway Button stands in for
## the title screen that takes focus and is then freed.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var checks := 0
var failures := 0

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
	return ok

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "guardian-drop-refocus-smoke"
	game.world.world_id = "guardian-drop-refocus-world"
	game.save_system = SAVE.new("user://water_guardian_drop_refocus_%d/" % Time.get_ticks_usec())
	var five: Array = []
	for i in 5:
		var keeper := SPECIES.spawn("water_mosshell")
		five.append(keeper)
		game.local.party.add(keeper)
	game.world.flags.set_flag("water_guardian_freed")
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(world.shell_build_complete(), "Actual Water world builds with freed Guardian fixture"):
		_finish()
		return
	var cave: Node3D = world.get_node("WaterVeilfall")
	var player: Node3D = world.local_rig()
	var prompt: Node3D = cave.get("_guardian_prompt")
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	player.velocity = Vector3.ZERO
	await _frames(8)
	var menu: Node = game.menu()
	var tab: Node
	for i in menu.get("_tabs").size():
		if str(menu.get("_tabs")[i].id) == "creatures": tab = menu.get("_bodies")[i]
	prompt.interaction_activate()
	if not await _wait_choose(game, menu, tab):
		check(false, "The at-capacity offer opens the release choice")
		_finish()
		return
	var claim_id := str(game.pending_catch.get_meta("water_capture_claim", ""))
	check(root.gui_get_focus_owner() == tab.get("_pending_button"), "First presentation: focus on the newcomer's row")

	# The drop: the live character is blanked (its unanswered offer leaves
	# pending_catch with it), another screen takes focus and goes away, and the
	# same character comes back with the same five.
	game.local.load_data({})
	game.local.character_id = "guardian-drop-refocus-smoke"
	await _frames(4)
	var thief := Button.new()
	root.add_child(thief)
	thief.grab_focus()
	await _frames(2)
	thief.queue_free()
	await _frames(2)
	for keeper: RefCounted in five:
		game.local.party.add(keeper)
	var guardians := 0
	for member: RefCounted in game.local.party.members():
		if str(member.species_id) == "water_abyssal_guardian": guardians += 1
	check(game.local.party.size() == 5 and guardians == 0 and game.world.water_capture_claims.has(claim_id),
		"Reloaded: five kept, nothing granted, the host still holds the claim (party %d, Guardians %d)" % [game.local.party.size(), guardians])

	# The claim service re-presents the same claim on its own poll.
	if not await _wait_choose(game, menu, tab):
		check(false, "The same claim is presented again at the release choice")
		_finish()
		return
	check(str(game.pending_catch.get_meta("water_capture_claim", "")) == claim_id, "It is the same claim")
	var focus := root.gui_get_focus_owner()
	check(focus != null and tab.is_ancestor_of(focus), "Re-presented: focus is inside the ceremony, not on nothing (got %s)"
		% (str(focus.get_path()) if focus != null else "nothing"))
	check(focus == tab.get("_pending_button"), "Re-presented: focus starts on the newcomer's row again")
	# A pad alone can reach a companion's row and ask to let them go.
	var target: Control = tab.get("_rows")[2]
	for i in 7:
		if root.gui_get_focus_owner() == target: break
		await _press("ui_up")
	check(root.gui_get_focus_owner() == target, "Up presses reach the third companion's row")
	await _press("ui_accept")
	check(str(tab.get("_release_stage")) == "confirm", "A on that row asks to confirm the farewell")
	_finish()

func _wait_choose(game: Node, menu: Node, tab: Node) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while (not menu.is_open() or str(tab.get("_release_stage")) != "choose" or game.pending_catch == null) \
			and Time.get_ticks_msec() < deadline:
		await process_frame
	await _frames(10)
	return menu.is_open() and str(tab.get("_release_stage")) == "choose" and game.pending_catch != null

func _press(action: String) -> void:
	Input.action_press(action)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	Input.action_release(action)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await physics_frame

func _finish() -> void:
	print("Water Guardian drop refocus smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
