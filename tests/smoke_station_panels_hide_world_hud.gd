extends SceneTree

## `HIST-153` regression guard — "the exploration HUD draws over every station
## panel."
##
##   godot --headless --path . --script tests/smoke_station_panels_hide_world_hud.gd
##
## The defect: opening a bench, chest, shop, bed or swap panel left the world
## HUD drawing straight over it — creature block, roster, vitals, hotbar and
## minimap all painting across the panel's own rows. It survived an entire
## visual sweep because those panels had only ever been photographed with NO
## WORLD behind them, so there was no HUD in the frame to collide with. The
## register records it as **found**, never as fixed.
##
## Verified before writing a line of fix: current `main` already satisfies it.
## All five panels call `input_owner.gd::set_world_hud_visible()` on open and
## restore inside the same `current(tree) == null` branch that releases pause —
## which is the correct shape, not merely a call in the right place: restoring
## on any close would put the HUD back over a panel still open underneath.
##
## What was missing is this file. `set_world_hud_visible` had **zero**
## references anywhere under `tests/`, and for a defect that already hid from a
## full visual sweep once, the untested contract is the thing worth closing.
##
## A smoke test rather than a `test_*.gd` unit: `tests/test_case.gd`'s own
## header limits that suite to pure logic — "not scenes, not rendering" — and
## this necessarily mounts Controls into a tree with a `current_scene`, because
## `set_world_hud_visible()` resolves its two layers off exactly that. It does
## NOT stand up the Meadows: the contract is per-panel wiring, and
## `input_owner.gd`'s own header names the failure mode as "a sixth surface
## that joins `GROUP` and forgets to call this", so the useful test is the one
## that covers ALL the surfaces cheaply rather than one of them behind a
## four-minute world boot.

const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

## Every modal station surface, with the argument its `open()` takes.
## `craft_panel.gd::open()` takes none; storage and creature-bed take the world
## node they were opened from; shop and swap take a vendor id.
const PANELS := [
	{"script": "res://scripts/ui/craft_panel.gd", "arg": null},
	{"script": "res://scripts/ui/storage_panel.gd", "arg": "<node>"},
	{"script": "res://scripts/ui/shop_panel.gd", "arg": "general"},
	{"script": "res://scripts/ui/swap_panel.gd", "arg": "general"},
	{"script": "res://scripts/ui/creature_bed_panel.gd", "arg": "<node>"},
]

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for i in 4:
		await process_frame

	await _check_the_helper_reaches_both_layers()
	for entry: Variant in PANELS:
		await _check_panel(entry as Dictionary)

	print("")
	if _failures.is_empty():
		print("PASS: every station panel hides both world HUD layers and gives them back")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## Both layers, not one, asserted directly on the helper. `combat_hud.gd` is
## mounted beside `PlaygroundHUD` in the world scene and draws the encounter
## director's own prompt line whether or not a fight is on, so a panel that
## hid only the exploration HUD would still have "Call out Biscuit" printing
## through it. If `set_world_hud_visible` ever stopped reaching the second
## layer, the per-panel checks below would keep passing on the first.
func _check_the_helper_reaches_both_layers() -> void:
	var stage := _stage()
	var playground: CanvasLayer = stage.get_node(^"PlaygroundHUD")
	var combat: CanvasLayer = stage.get_node(^"CombatHUD")

	INPUT_OWNER.set_world_hud_visible(stage.get_tree(), false)
	if playground.visible or combat.visible:
		_failures.append("set_world_hud_visible(false) did not reach both layers (PlaygroundHUD %s, CombatHUD %s)" % [
			playground.visible, combat.visible,
		])
	INPUT_OWNER.set_world_hud_visible(stage.get_tree(), true)
	if not playground.visible or not combat.visible:
		_failures.append("set_world_hud_visible(true) did not restore both layers (PlaygroundHUD %s, CombatHUD %s)" % [
			playground.visible, combat.visible,
		])
	else:
		print("  ok    set_world_hud_visible reaches PlaygroundHUD and CombatHUD")
	await _teardown(stage)


func _check_panel(spec: Dictionary) -> void:
	var script_path := str(spec["script"])
	var name := script_path.get_file()
	var stage := _stage()
	var playground: CanvasLayer = stage.get_node(^"PlaygroundHUD")
	var combat: CanvasLayer = stage.get_node(^"CombatHUD")

	var script: GDScript = load(script_path)
	if script == null:
		_failures.append("%s could not be loaded" % name)
		await _teardown(stage)
		return
	# `script.new()` rather than `Control.new()` + `set_script()`: these panels
	# extend `CanvasLayer`, not `Control`, and forcing a script onto the wrong
	# native base fails at assignment and leaves a node with no `open()` on it.
	var panel := script.new() as Node
	if panel == null:
		_failures.append("%s did not instantiate to a Node" % name)
		await _teardown(stage)
		return
	panel.name = name.get_basename()
	stage.add_child(panel)
	for i in 3:
		await process_frame

	# Non-vacuity: if the layers were already hidden, every check below would
	# pass without the panel doing anything at all.
	if not playground.visible or not combat.visible:
		_failures.append("%s: the HUD layers were already hidden before open(); this check would pass vacuously" % name)
		await _teardown(stage)
		return

	_open(panel, spec.get("arg"))
	for i in 3:
		await process_frame
	if playground.visible or combat.visible:
		_failures.append("%s left a world HUD layer drawing over itself (PlaygroundHUD %s, CombatHUD %s)" % [
			name, playground.visible, combat.visible,
		])
		await _teardown(stage)
		return

	panel.call("close")
	for i in 3:
		await process_frame
	if not playground.visible or not combat.visible:
		_failures.append("%s closed without giving the world HUD back (PlaygroundHUD %s, CombatHUD %s)" % [
			name, playground.visible, combat.visible,
		])
		await _teardown(stage)
		return

	print("  ok    %s hides both layers on open and restores them on close" % name)
	await _teardown(stage)


## A stand-in for the world scene. `set_world_hud_visible()` resolves both
## layers as children of `tree.current_scene`, so what it needs is a current
## scene with those two names under it — not the Meadows.
func _stage() -> Node:
	var stage := Node.new()
	stage.name = "StageWorld"
	var playground := CanvasLayer.new()
	playground.name = "PlaygroundHUD"
	stage.add_child(playground)
	var combat := CanvasLayer.new()
	combat.name = "CombatHUD"
	stage.add_child(combat)
	root.add_child(stage)
	current_scene = stage
	return stage


func _open(panel: Node, arg: Variant) -> void:
	if arg == null:
		panel.call("open")
		return
	if str(arg) == "<node>":
		# These two read state off the world node they were opened from; a bare
		# Node is enough to reach the visibility call this file is about, and
		# keeps the test off the Meadows.
		var fixture := Node.new()
		fixture.name = "Fixture"
		panel.add_child(fixture)
		panel.call("open", fixture)
		return
	panel.call("open", str(arg))


func _teardown(stage: Node) -> void:
	# The panels pause the tree on open and only unpause through their own
	# close path; a check that failed mid-way would otherwise leave the tree
	# paused and hang every check after it.
	stage.get_tree().paused = false
	current_scene = null
	root.remove_child(stage)
	stage.queue_free()
	await process_frame
