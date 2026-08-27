extends SceneTree

## HIST-036 evidence. The objective hint card, and the objective plate the same
## measurement pass found overflowing, photographed through the real render
## path over the real world.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_capture_objective_hint_card.gd
##
## NEVER `--headless` with a real rendering driver -- it hangs forever with no
## error (`ralph/conventions.md`, the single most expensive trap in this repo).
##
## Three frames, same camera, same world, same seeded state:
##
##   before-plate  the objective block laid out the way `main` lays it out
##                 (fixed 170px), with the longest authored tracked line in it
##   after-plate   the same line, with the plate sized to its own text
##   after-card    the hint card up, over terrain, as a player meets it
##
## The "before" frame is produced by suppressing the new layout call rather than
## by checking out `main` and rendering twice: the two frames then differ in
## exactly one thing, which is what a before/after pair is for.
##
## Software rasterisation on llvmpipe. Composition, colour and silhouette are
## trustworthy from these frames; frame times are not, and none is reported.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const OUT_DIR := "res://shots/hist-036"
const BOOT_FRAMES := 90

var _game: Node = null
var _hud: CanvasLayer = null
var _written: Array[String] = []
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for i in 8:
		await process_frame

	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload missing")
		_finish()
		return
	_seed()

	var packed: PackedScene = load(WORLD_SCENE)
	if packed == null:
		_fail("could not load %s" % WORLD_SCENE)
		_finish()
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	# `current_scene` is what the HUD reads to find the world; a scene parented
	# to `root` without this is a state no play session is ever in, and the
	# minimap silently never bakes.
	current_scene = world
	for i in BOOT_FRAMES:
		await physics_frame
	print("[world] boot settled")

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var rig: Node = world.get_node_or_null(^"CameraRig")
	_hud = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if player == null or rig == null or _hud == null:
		_fail("missing Player/CameraRig/PlaygroundHUD")
		_finish()
		return
	rig.set_process(false)
	rig.set_physics_process(false)
	_pin_daylight(world)

	# THE PLAYER STAYS WHERE THE WORLD SPAWNED THEM. A first pass of this tool
	# placed them at a hand-picked (-15, -1), which is under the pond: the
	# world's water level is y -17 and `water.gd::is_fully_submerged()` is a
	# plain global-plane test, so the player drowned through the whole capture.
	# Every frame came back with `water.gd`'s damage-phase submersion tint --
	# `Color(0.75, 0.12, 0.12)` at up to 0.55 alpha on a CanvasLayer ABOVE the
	# HUD -- and read as a heavy red cast over the world AND the interface,
	# which is not a lighting defect and is not the renderer. The spawn is
	# authored, dry, and the frames come back in daylight.
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var focus := player.global_position
	camera.global_position = focus + Vector3(5.0, 3.4, 6.0)
	camera.look_at(focus + Vector3.UP, Vector3.UP)
	await _settle(12)

	var longest := _longest_objective_line()
	var hint := _first_hint()

	# BEFORE. `OBJECTIVE_BLOCK_HEIGHT` is a fixed 170, which leaves 94px of
	# interior; the longest authored tracked line wraps to 159. Restoring the
	# block to that fixed height with the long line in it is exactly what
	# `main` draws.
	_hud.call("_hide_objective_hint_card")
	_set_objective(longest, "")
	await _settle(6)
	var block: Control = _hud.get(&"_objective_block") as Control
	var backing: PanelContainer = _hud.get(&"_objective_backing") as PanelContainer
	if block != null:
		block.size = Vector2(block.size.x, 170.0)
		if backing != null:
			backing.size = block.size
	await _shoot("01-before-plate-fixed-170")

	# AFTER, same line, plate sized to its own text.
	_hud.call("_layout_objective_block")
	await _settle(6)
	await _shoot("02-after-plate-fits-text")

	# AFTER, the card itself, over terrain, at the size and position a player
	# meets it at.
	_set_objective("Open the village gate and follow the road in.", hint)
	await _settle(6)
	if not _card_visible():
		_fail("the hint card did not reveal for the capture")
	# Hold the reveal open across the shutter. The dwell window is real wall
	# time (2.5s + 0.3s a word, ~8.5s for this hint) and a settle-plus-shutter
	# under llvmpipe is 12 frames at seconds each -- the first pass of this
	# tool photographed the card AFTER its own deadline had passed, i.e. an
	# empty frame, with the visibility check above still having passed. The
	# window is not being changed, only held still while it is photographed.
	_hud.set(&"_objective_hint_until", Time.get_ticks_msec() / 1000.0 + 3600.0)
	await _shoot("03-after-hint-card")

	_finish()


## Stop the clock, and stop it at day.
##
## `world_look.gd` runs a live day cycle off `_process(delta)`, and under
## software rasterisation on llvmpipe a capture takes many wall-clock minutes
## -- so the first pass of this tool photographed the whole world, HUD panels
## included, at a heavy sunset red, which reads as a lighting defect and is not
## one. Paid for once here; the frames in `shots/hist-036` are the re-shoot.
## Frames from this harness are for composition, colour and silhouette; if the
## clock is allowed to run, only two of those three survive.
func _pin_daylight(world: Node) -> void:
	for node in world.get_tree().get_nodes_in_group("day_cycle"):
		if node.has_method("apply_time"):
			node.call("apply_time", "day")
		node.set_process(false)


func _set_objective(text: String, hint: String) -> void:
	# Written straight onto `Game` rather than through `set_objective()`, which
	# deliberately clears the hint -- see that function's own comment. This is
	# the shape `_process()` produces on a real flag change.
	_game.set("objective_hint", hint)
	_game.set("objective_text", text)


func _card_visible() -> bool:
	var card: Control = _hud.get(&"_objective_hint_card") as Control
	return card != null and card.visible


func _longest_objective_line() -> String:
	var out := ""
	var log_reader: RefCounted = QUEST_LOG.new()
	var progression: RefCounted = PROGRESSION.new()
	for raw: Variant in (log_reader.call("main_entries", progression) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var text := str((raw as Dictionary).get("label", ""))
		if text.length() > out.length():
			out = text
	return out


func _first_hint() -> String:
	var log_reader: RefCounted = QUEST_LOG.new()
	var progression: RefCounted = PROGRESSION.new()
	for raw: Variant in (log_reader.call("main_entries", progression) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var hint := str((raw as Dictionary).get("how", ""))
		if not hint.is_empty():
			return hint
	return ""


## Enough real state that the HUD around the card is the HUD a player has, not
## an empty one: a full five-creature belt and a stocked bar.
func _seed() -> void:
	var party: RefCounted = _game.get("party")
	var inventory: RefCounted = _game.get("inventory")
	if party == null or inventory == null:
		_fail("Game.party/Game.inventory not reachable -- the HUD will draw empty")
		return
	for species in ["terrapup", "ripplet", "bramblebun", "mosshell", "tuskroot"]:
		var creature: RefCounted = _game.call("make_creature", species, "")
		if creature != null:
			party.call("add", creature)
	inventory.call("add", "orb_basic", 10)
	inventory.call("add", "berries", 10)
	inventory.call("add", "potion_small", 3)
	inventory.call("add", "axe", 1)
	inventory.call("add", "wood", 40)


func _shoot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_fail("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		_fail("%s: save_png failed (%d)" % [name, error])
		return
	_written.append(path)
	print("  %-28s -> %s" % [name, path])


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rasterisation. Composition/colour/silhouette only; no frame")
	print("time from this harness is a performance measurement.")
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
