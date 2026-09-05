extends SceneTree

## CL-H8's one live probe: does `build_catalogue` genuinely fail to release
## after a workbench interact, or was S06's stuck context a script defect?
##
## The closure plan makes this a fork with two very different bills. If the
## context sticks, it is a game defect in shared UI (`build_menu.gd` /
## `craft_panel.gd` / `game_menu.gd`) and both the harness lanes and the UI
## lane need to know before either spends a session; if it does not, S06-30's
## invented workbench beat is simply a beat Band 2 never asked for and the
## segment loses it.
##
## Driven through the game's REAL nodes and read through the REAL resolver:
## `scripts/debug/gate_f_probe.gd::input_context()`, the same function the Gate
## F harness asserts on. Nothing here re-implements the context rules, so a
## PASS here is the same PASS the harness would report.
##
##   godot --headless --path . --script tools/_probe_workbench_context.gd

const PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"

var _probe: RefCounted = null
var _failures: Array[String] = []
var _log: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for i in 20:
		await physics_frame
	# The same boot the harness's own `boot` step makes: the title scene is what
	# a bare `--script` run stands up, and every accessor below reads
	# `current_scene`.
	var packed := load(WORLD_SCENE) as PackedScene
	if packed == null:
		_fail("could not load %s" % WORLD_SCENE)
		_report()
		return
	if current_scene != null:
		var old := current_scene
		root.remove_child(old)
		old.queue_free()
		await process_frame
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 240:
		await physics_frame
	_probe = PROBE.new(self)
	for i in 10:
		await physics_frame

	var world := _probe.call("world") as Node
	if world == null or _probe.call("player") == null:
		_fail("no world/player stood up; the probe proves nothing")
		_report()
		return
	_note("baseline input_context = %s" % str(_probe.call("input_context")))
	_expect("world", "baseline: nothing owns input before anything is opened")

	# --- 1. the catalogue itself, opened and closed as a player closes it ----
	#
	# S06-31..S06-38 open the build menu through the pause shell. The context
	# question is about the catalogue, not about the route to it, so this opens
	# the real BuildMenu node directly and closes it through its own `close()`
	# -- the same call `_process`'s `menu_cancel`/`build_cancel` branch makes.
	var menu: CanvasLayer = BUILD_MENU.new()
	menu.name = "BuildMenuProbe"
	root.add_child(menu)
	for i in 8:
		await physics_frame
	menu.call("open")
	for i in 8:
		await physics_frame
	_note("with the catalogue open, input_context = %s" % str(_probe.call("input_context")))
	_expect("build_catalogue", "an open build menu should BE the build_catalogue context")
	menu.call("close", false)
	for i in 12:
		await physics_frame
	_note("after closing the catalogue, input_context = %s" % str(_probe.call("input_context")))
	_expect("world", "CLOSING the catalogue must return input to the world")

	# --- 2. the workbench interact, which is what S06 actually did ----------
	#
	# `build_placer.gd::_spawn_building` gives a placed workbench a "Craft"
	# Interactable wired to `_open_craft_panel`. That is the interact S06-40
	# makes. Reached here by placing a real workbench through the real placer
	# rather than by calling the panel directly, so the thing under test is the
	# station the player builds.
	var game := _probe.call("game") as Node
	var placer := world.get_node_or_null(^"BuildPlacer")
	if placer == null or game == null:
		_fail("no BuildPlacer/Game; cannot place a workbench the way the game does")
		_report()
		return
	var bench: Node3D = placer.call("_spawn_building", game, "workbench", 0.0, -1)
	if bench == null:
		_fail("the placer refused to spawn a workbench")
		_report()
		return
	var craft_prompt := bench.get_node_or_null(^"CraftInteractable")
	if craft_prompt == null:
		_fail("the placed workbench carries no CraftInteractable; there is no interact to make")
		_report()
		return
	for i in 8:
		await physics_frame
	_note("workbench placed; input_context = %s" % str(_probe.call("input_context")))
	craft_prompt.emit_signal("activated")
	for i in 12:
		await physics_frame
	var after_interact := str(_probe.call("input_context"))
	_note("after the workbench interact, input_context = %s" % after_interact)
	if after_interact == "build_catalogue":
		_fail("THE DEFECT REPRODUCES: a workbench interact left the context in build_catalogue")
	var owner_node := INPUT_OWNER.current(self)
	_note("input owner after the interact = %s" % (
		"<none>" if owner_node == null else "%s (%s)" % [
			owner_node.name,
			"" if owner_node.get_script() == null
				else str(owner_node.get_script().resource_path).get_file()]))

	# --- 3. cancel out of it, which is S06-48/S06-49 -----------------------
	if owner_node != null and owner_node.has_method("close"):
		owner_node.call("close")
	for i in 12:
		await physics_frame
	_note("after cancelling out, input_context = %s" % str(_probe.call("input_context")))
	_expect("world", "S06-49: cancelling out of the crafting station must return the world context")

	_report()


func _expect(want: String, why: String) -> void:
	var have := str(_probe.call("input_context"))
	if have != want:
		_fail("%s -- expected '%s', got '%s'" % [why, want, have])


func _note(line: String) -> void:
	_log.append(line)
	print("[workbench] %s" % line)


func _fail(line: String) -> void:
	_failures.append(line)
	print("[workbench] FAIL: %s" % line)


func _report() -> void:
	print("[workbench] ---- verdict ----")
	if _failures.is_empty():
		print("[workbench] PASS: the build_catalogue context releases at every step of S06's beat.")
	else:
		for line in _failures:
			print("[workbench] %s" % line)
	quit(0 if _failures.is_empty() else 1)
