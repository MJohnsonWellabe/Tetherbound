extends SceneTree

## OWNER-0901-TRAIN-CLARITY-V2 evidence. Owner playtest 2026-09-01 item 7,
## "still unclear how to train a team", and item 12, Halda's guidance made
## concrete. Real headless execution (see this branch's other commits)
## already proved the mechanism works; this captures what a player actually
## SEES, at handheld size, so the coordinator's own visual-judge pass has
## real frames instead of a passing test's word for it.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_train_clarity.gd
##
## NEVER `--headless` with a real rendering driver -- it hangs forever with no
## error (`ralph/conventions.md`).
##
## 1280x800 is `tests/smoke_hud_handheld_legibility.gd`'s own HANDHELD_SIZE
## (the ROG Ally's real panel resolution), not the 1920x1080 the HIST-036
## capture tool this is modelled on used -- the owner's own complaint was
## read on the Ally, not a desktop monitor.
##
## Two frames:
##
##   01-objective-hint-card   the HUD's objective hint card, showing the
##                             `tournament_train_team` rung's own authored
##                             `how` text, over real terrain, as a player
##                             actually meets it when this rung becomes
##                             current.
##   02-halda-train-dialogue  Halda's `tournament_halda_train` conversation
##                             box, the same line in her own voice, as a
##                             player actually meets it when they talk to her
##                             with a full but untrained team.
##
## Software rasterisation on llvmpipe. Composition, colour and silhouette are
## trustworthy from these frames; frame times are not, and none is reported.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const OBJECTIVES_PATH := "res://data/progression/objectives.json"
const OUT_DIR := "res://shots/train-clarity-v2"
const BOOT_FRAMES := 90

var _game: Node = null
var _hud: CanvasLayer = null
var _dialogue: Node = null
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
	current_scene = world
	for i in BOOT_FRAMES:
		await physics_frame
	print("[world] boot settled")

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var rig: Node = world.get_node_or_null(^"CameraRig")
	_hud = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	_dialogue = world.get_node_or_null(^"DialoguePanel")
	if player == null or rig == null or _hud == null or _dialogue == null:
		_fail("missing Player/CameraRig/PlaygroundHUD/DialoguePanel")
		_finish()
		return
	rig.set_process(false)
	rig.set_physics_process(false)
	_pin_daylight(world)

	# Real spawn, dry ground -- see HIST-036's own capture tool for why a
	# hand-picked position is a trap (the pond drowns the player and tints
	# every frame red).
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var focus := player.global_position
	camera.global_position = focus + Vector3(5.0, 3.4, 6.0)
	camera.look_at(focus + Vector3.UP, Vector3.UP)
	await _settle(12)

	var entry := _read_entry("tournament_train_team")
	var label := str(entry.get("label", ""))
	var hint := str(entry.get("how", ""))
	if label.is_empty() or hint.is_empty():
		_fail("tournament_train_team entry missing label/how in %s" % OBJECTIVES_PATH)

	# Frame 1: the objective hint card, over terrain, at the size and
	# position a player actually meets it at.
	#
	# The reveal only fires on a TEXT CHANGE (`_update_objective()`), and by
	# this point in boot the real Tournament autoload has already polled the
	# seeded five-creature party and naturally advanced the tracked line to
	# this exact rung on its own -- so setting the same text again is not a
	# change and the card never reveals. Force a real change first (a
	# different placeholder), settle, THEN set the real text so the reveal
	# fires the way it does for an actual player crossing into this rung.
	_hud.call("_hide_objective_hint_card")
	_game.set("objective_hint", "")
	_game.set("objective_text", "")
	await _settle(3)
	_game.set("objective_hint", hint)
	_game.set("objective_text", label)
	await _settle(6)
	if not _card_visible():
		_fail("the hint card did not reveal for the capture")
	# Hold the reveal open across the shutter -- the real dwell window is
	# 2.5s + 0.3s/word and would otherwise expire under llvmpipe's slow
	# per-frame cost before the shutter fires.
	_hud.set(&"_objective_hint_until", Time.get_ticks_msec() / 1000.0 + 3600.0)
	await _shoot("01-objective-hint-card")

	# Frame 2: Halda's own voice, the same guidance, as a player actually
	# reads it mid-conversation. `tournament_halda_train` is three lines --
	# "All five. Good..." / "Half that lot have never taken a real hit..." /
	# "Feed them. Rest them... Get them to level five, then we'll talk." --
	# and the THIRD is the one item 12 is actually about (the concrete
	# actions), so two advances, not one.
	var started: bool = bool(_dialogue.call("start", "tournament_halda_train"))
	if not started:
		_fail("tournament_halda_train did not start on the real DialoguePanel")
	else:
		for i in 2:
			_dialogue.call("advance")
			await _settle(3)
		if not bool(_dialogue.call("is_open")):
			_fail("DialoguePanel closed before the capture -- fewer lines than expected")
	await _shoot("02-halda-train-dialogue")

	_finish()


func _pin_daylight(world: Node) -> void:
	for node in world.get_tree().get_nodes_in_group("day_cycle"):
		if node.has_method("apply_time"):
			node.call("apply_time", "day")
		node.set_process(false)


func _card_visible() -> bool:
	var card: Control = _hud.get(&"_objective_hint_card") as Control
	return card != null and card.visible


func _read_entry(id: String) -> Dictionary:
	var file := FileAccess.open(OBJECTIVES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for raw: Variant in ((parsed as Dictionary).get("main", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		if str(entry.get("id", "")) == id:
			return entry
	return {}


## Enough real state that both frames show a full but untrained team, which
## is the exact state this rung is authored for -- a full five-creature
## roster, all at the level the game hands out a fresh catch at.
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
