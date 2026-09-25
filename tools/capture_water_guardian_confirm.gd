extends SceneTree

## Capture the Guardian Accept/Decline confirm (ACCEPTANCE F14) in the real
## production Water scene, HUD and pause menu at 1280x720.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" /root/godot-bin/godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_water_guardian_confirm.gd
##
## Writes:
##   ralph/reports/WATER-PROGRESS/_guardian_confirm.png               the offer
##   ralph/reports/WATER-PROGRESS/_guardian_confirm_decline_step.png  Decline's
##       second step ("Let the Deep Watcher go? This is final.")
##   ralph/reports/WATER-PROGRESS/_guardian_confirm_declining.png     after
##       Confirm, while the host has not yet journaled the refusal
##
## FIXTURE (disclosed): the Guardian is already freed (the same flag-only fixture
## smoke_water_guardian_ceremony.gd uses: no Nerissa fight is played), the belt
## is four ordinary level-55 companions so one holder is free, and the player is
## placed beside the freed Guardian. The offer itself is real: the chamber's
## Invite prompt mints the durable claim and the claim service presents it; Game
## opens the Creatures tab on its own. The live device is pinned to the gamepad
## (as capture_ui_suite.gd does) so the frames show controller glyphs. Buttons
## are driven with real ui_down / ui_accept presses. For the last frame the host's FIRST
## world-journal write is refused (the smoke's RefusingSaver) so the pending
## "Declining..." wording is on screen, as it is for any joiner until the host
## journals the refusal; the real saver is restored immediately after.

const SCENE := "res://scenes/world/water_archipelago.tscn"
const OUT_DIR := "res://ralph/reports/WATER-PROGRESS"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SAVE := preload("res://scripts/save/save_game.gd")

class RefusingSaver extends RefCounted:
	func save_world(_game: Object, _id: String) -> bool: return false

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "guardian-confirm-capture"
	game.world.world_id = "guardian-confirm-capture-world"
	game.save_system = SAVE.new("user://guardian_confirm_capture_%d/" % Time.get_ticks_usec())
	var keepers := ["water_mosshell", "water_mosshell", "water_mosshell", "water_mosshell"]
	for species: String in keepers:
		var keeper := SPECIES.spawn(species)
		keeper.set_level(55, PROGRESSION.config())
		game.local.party.add(keeper)
	game.world.flags.set_flag("water_guardian_freed")
	var world: Node3D = load(SCENE).instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 120000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not world.shell_build_complete():
		_finish("Water world did not build")
		return
	game.set("_last_input_was_gamepad", true)
	var cave: Node3D = world.get_node("WaterVeilfall")
	var player: Node3D = world.local_rig()
	var prompt: Node3D = cave.get("_guardian_prompt")
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	prompt.interaction_activate()
	var menu: Node = game.menu()
	var tab: Node = null
	for i in menu.get("_tabs").size():
		if str(menu.get("_tabs")[i].id) == "creatures":
			tab = menu.get("_bodies")[i]
	deadline = Time.get_ticks_msec() + 10000
	while (not menu.is_open() or str(tab.get("_release_stage")) != "guardian") and Time.get_ticks_msec() < deadline:
		await process_frame
	if str(tab.get("_release_stage")) != "guardian":
		_finish("the Guardian confirm did not open")
		return
	# Let the creature viewport frame the Guardian.
	for i in 45:
		await process_frame
	await _shoot("_guardian_confirm")

	await _press("ui_down")
	await _press("ui_accept")
	if str(tab.get("_release_stage")) != "guardian_decline":
		_finish("Decline did not open its confirm step")
		return
	for i in 10:
		await process_frame
	await _shoot("_guardian_confirm_decline_step")

	await _press("ui_down")
	# Hold the claim service's resend for this frame only (as the ceremony
	# smoke does) so the genuinely-pending wording is what is on screen.
	var claim_service: Node = game.ledger.get_node("WaterCaptureClaims")
	claim_service.set("_poll", 1000.0)
	var real_saver: RefCounted = game.save_system
	game.save_system = RefusingSaver.new()
	await _press("ui_accept")
	game.save_system = real_saver
	if str(menu.get("_status").text) != str(cave.DECLINE_PENDING):
		_failures.append("status line is %s, not the pending wording" % str(menu.get("_status").text))
	for i in 10:
		await process_frame
	await _shoot("_guardian_confirm_declining")
	claim_service.set("_poll", 0.0)
	var settle_by := Time.get_ticks_msec() + 6000
	while str(menu.get("_status").text) != str(cave.DECLINE_RESULT) and Time.get_ticks_msec() < settle_by:
		await process_frame
	if str(menu.get("_status").text) != str(cave.DECLINE_RESULT):
		_failures.append("status line never showed the settled result (%s)" % str(menu.get("_status").text))
	_finish("")


func _press(action: String) -> void:
	game_pin()
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await process_frame


## An InputEventAction is not a pad event: keep the pad glyphs pinned.
func game_pin() -> void:
	root.get_node("Game").set("_last_input_was_gamepad", true)


func _shoot(name: String) -> void:
	game_pin()
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % name)
		return
	print("  %s -> %s (%dx%d)" % [name, path, image.get_width(), image.get_height()])


func _finish(error: String) -> void:
	if not error.is_empty():
		_failures.append(error)
	for line in _failures:
		print("FAIL: %s" % line)
	print("Guardian confirm capture: %s" % ("FAILED" if not _failures.is_empty() else "ok"))
	quit(1 if not _failures.is_empty() else 0)
