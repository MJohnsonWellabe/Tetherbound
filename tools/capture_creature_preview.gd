extends SceneTree

## Captures the TEAM tab's live creature preview (`scripts/ui/creature_viewport.gd`)
## inside the REAL pause-menu Creatures tab, at a 1280x720 window, for X03-WO2
## (creature preview framing and exposure).
##
##   flock /tmp/claude-0/godot-render.lock xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_creature_preview.gd -- --label=after
##
## NEVER `--headless` with a rendering driver (see tools/_capture_ui_survey.gd's
## header: the combination hangs forever).
##
## Flags (after `--`):
##   --label=before|after   sub-directory the stills go into (default "after").
##   --no-spin              skip the turntable frame sequences.
##
## Staging, stated so nobody mistakes it for gameplay: no world scene is loaded
## (the pause menu is mounted by the `Game` autoload itself), the party is
## cleared and refilled with ONE creature of the species under test so the
## Creatures tab selects it, and the widget's own `_process` is switched off so
## the turntable angle is deterministic -- under software GL one frame is ~2 s
## of `delta`, which would otherwise spin the model to a random angle per shot.
## Stills keep the widget's authored build angle; the spin sequence advances the
## widget's own `_turntable` by IDLE_SPIN_SPEED x 1 s per frame (i.e. the
## sequence is the idle turntable sampled at 1 fps).
##
## Output (all under OUT_DIR):
##   <label>/<species>.jpg         the preview widget, cropped at 1:1 window pixels
##   <label>/tab_<species>.jpg     the whole 1280x720 window, for context
##   spin/<species>_NN.jpg         turntable at 1 fps, window downscaled to 640x360
##                                 (written for --label=after only, to keep size down)
##   spin_sheet_<label>_<species>.jpg  contact sheet of that sequence
##   before_after_sheet.jpg        written once both before/ and after/ exist

const OUT_DIR := "res://ralph/reports/SHARED-UI/creature-preview"
const PREVIEW_SCRIPT := "res://scripts/ui/creature_viewport.gd"
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

## Three starters plus the two most-fielded Band 1 companions
## (`data/config/chapter_curve.json` baseline `party`), Mosshell (the reported
## shell-crop case) and the Abyssal Guardian (the legendary offer).
const NAMED_SPECIES := [
	"terrapup", "ripplet", "galewisp", "bramblebun", "mudsnout",
	"mosshell", "abyssal_guardian",
]
## How many extra species to add, picked by largest measured render bounds.
const LARGEST_EXTRA := 3
const SPIN_SPECIES := ["abyssal_guardian", "mosshell"]
const SPIN_FRAMES := 32
const SPIN_STEP_SECONDS := 1.0
const IDLE_SPIN_SPEED := 0.5
const SPIN_FRAME_SIZE := Vector2i(640, 360)
const JPG_QUALITY := 0.82

var _game: Node = null
var _menu: CanvasLayer = null
var _label := "after"
var _spin := true
var _failures: Array[String] = []
var _written: Array[String] = []


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg == "--no-spin":
			_spin = false
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run with opengl3")
		quit(1)
		return
	for i in 4:
		await process_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("FAIL: no Game autoload")
		quit(1)
		return
	_game.set("_last_input_was_gamepad", true)
	_menu = _game.call("menu")
	if _menu == null:
		print("FAIL: Game.menu() unavailable")
		quit(1)
		return

	var species_list: Array = NAMED_SPECIES.duplicate()
	for id: String in _largest_species(LARGEST_EXTRA, species_list):
		species_list.append(id)
	print("capturing: %s" % ", ".join(species_list))

	var dir := OUT_DIR.path_join(_label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for id: String in species_list:
		await _shoot_species(id, dir)

	if _spin:
		var spin_dir := OUT_DIR.path_join("spin")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(spin_dir))
		for id: String in SPIN_SPECIES:
			await _spin_species(id, spin_dir)

	_compose_before_after(species_list)
	_finish()


## Rank every species by its body's measured render bounds (the larger of
## height and the XZ diagonal) and return the top `count` not already listed.
func _largest_species(count: int, exclude: Array) -> Array:
	var holder := Node3D.new()
	holder.visible = false
	root.add_child(holder)
	var ranked: Array = []
	# Skip species that reuse an already-listed model (the `water_*` rows
	# inherit presentation), so the extra slots show genuinely new silhouettes.
	var seen_models := {}
	for id: String in exclude:
		seen_models[str(SPECIES.placeholder(id).get("model", ""))] = true
	for id: String in SPECIES.table().keys():
		# `water_*` rows are registered roster entries that reuse an installed
		# presentation and the party refuses them from this staging path; the
		# unit test still frames every one of them.
		if id.begins_with("water_"):
			continue
		var model := str(SPECIES.placeholder(id).get("model", ""))
		var body: Node3D = CREATURE_SCENE.instantiate() as Node3D
		body.set_script(CREATURE_BODY)
		holder.add_child(body)
		body.call("setup", id, false)
		var box: AABB = RENDER_BOUNDS.measure(body.get_node(^"Model"))
		var size := maxf(box.size.y, Vector2(box.size.x, box.size.z).length())
		ranked.append([size, id, model])
		body.free()
	holder.free()
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var picked: Array = []
	for entry: Array in ranked:
		if picked.size() >= count:
			break
		var id: String = entry[1]
		if id in exclude or seen_models.has(entry[2]):
			continue
		seen_models[entry[2]] = true
		picked.append(id)
		print("  largest: %s (%.2f m)" % [id, entry[0]])
	return picked


func _stage(id: String) -> Node:
	_menu.call("close")
	var party: RefCounted = _game.get("party")
	party.call("clear")
	var creature: RefCounted = _game.call("make_creature", id, "")
	if creature == null or not bool(party.call("add", creature)):
		_failures.append("%s: could not add to party" % id)
		return null
	party.call("set_active", 0)
	if not bool(_menu.call("open", "creatures")):
		_failures.append("%s: menu refused to open" % id)
		return null
	# The tab rebuilds its content on open, so look the widget up only after
	# it has settled, then freeze it on the authored build angle.
	await _settle(8)
	var preview := _find_preview(_menu)
	if preview == null:
		_failures.append("%s: no creature_viewport under the menu" % id)
		return null
	preview.set_process(false)
	# The widget re-measures its body once the authored rest pose has landed
	# (REMEASURE_AT). With `_process` off, step that settle explicitly: the
	# same call play makes, as if the tab had been open for 3 s, no rotation.
	if preview.has_method("advance"):
		await _settle(30)
		preview.call("advance", 0.0, 3.0)
	var turntable := preview.get("_turntable") as Node3D
	if turntable != null:
		turntable.rotation = Vector3.ZERO
	await _settle(4)
	return preview


func _shoot_species(id: String, dir: String) -> void:
	var preview: Node = await _stage(id)
	if preview == null or not is_instance_valid(preview):
		return
	var image := await _grab()
	if image == null or not is_instance_valid(preview):
		_failures.append("%s: no frame, or the widget was rebuilt mid-shot" % id)
		return
	var crop := _widget_rect(preview as Control, image)
	_save(image.get_region(crop), dir.path_join("%s.jpg" % id))
	var tab := image.duplicate() as Image
	_save(tab, dir.path_join("tab_%s.jpg" % id))
	print("  %s  widget=%s  subviewport=%s" % [id, crop, (preview as SubViewportContainer).size])


func _spin_species(id: String, dir: String) -> void:
	var preview: Node = await _stage(id)
	if preview == null or not is_instance_valid(preview):
		return
	var turntable := preview.get("_turntable") as Node3D
	var frames: Array[Image] = []
	for i in SPIN_FRAMES:
		var image := await _grab()
		if image == null:
			_failures.append("%s spin frame %d: no image" % [id, i])
			return
		image.resize(SPIN_FRAME_SIZE.x, SPIN_FRAME_SIZE.y, Image.INTERPOLATE_BILINEAR)
		if _label == "after":
			_save(image, dir.path_join("%s_%02d.jpg" % [id, i]))
		frames.append(image)
		# The widget's own step when it has one, so the camera follows the
		# turn exactly as in play (per-angle fit); older widgets just rotate.
		if preview.has_method("advance"):
			preview.call("advance", IDLE_SPIN_SPEED * SPIN_STEP_SECONDS, SPIN_STEP_SECONDS)
		elif turntable != null:
			turntable.rotate_y(IDLE_SPIN_SPEED * SPIN_STEP_SECONDS)
		await _settle(2)
	# Sheet crops each frame to the widget's area so the rotation is legible.
	var crop := _widget_rect(preview as Control, frames[0], Vector2(SPIN_FRAME_SIZE))
	var tiles: Array[Image] = []
	for frame: Image in frames:
		tiles.append(frame.get_region(crop))
	_save(_sheet(tiles, 8), OUT_DIR.path_join("spin_sheet_%s_%s.jpg" % [_label, id]))


func _compose_before_after(species_list: Array) -> void:
	var before_dir := ProjectSettings.globalize_path(OUT_DIR.path_join("before"))
	var after_dir := ProjectSettings.globalize_path(OUT_DIR.path_join("after"))
	var tiles: Array[Image] = []
	for id: String in species_list:
		var b := Image.load_from_file(before_dir.path_join("%s.jpg" % id)) if FileAccess.file_exists(before_dir.path_join("%s.jpg" % id)) else null
		var a := Image.load_from_file(after_dir.path_join("%s.jpg" % id)) if FileAccess.file_exists(after_dir.path_join("%s.jpg" % id)) else null
		if b == null or a == null:
			continue
		b.convert(Image.FORMAT_RGB8)
		a.convert(Image.FORMAT_RGB8)
		if a.get_size() != b.get_size():
			a.resize(b.get_width(), b.get_height(), Image.INTERPOLATE_BILINEAR)
		var pair := Image.create(b.get_width() * 2 + 6, b.get_height(), false, Image.FORMAT_RGB8)
		pair.fill(Color(0.5, 0.5, 0.5))
		pair.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i.ZERO)
		pair.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i(b.get_width() + 6, 0))
		tiles.append(pair)
	if tiles.is_empty():
		print("  (no before/after pairs yet; sheet skipped)")
		return
	_save(_sheet(tiles, 2), OUT_DIR.path_join("before_after_sheet.jpg"))


func _sheet(tiles: Array[Image], columns: int) -> Image:
	var w := tiles[0].get_width()
	var h := tiles[0].get_height()
	var gap := 6
	var rows := int(ceil(float(tiles.size()) / columns))
	var sheet := Image.create(columns * w + (columns + 1) * gap, rows * h + (rows + 1) * gap, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.85, 0.85, 0.85))
	for i in tiles.size():
		var tile := tiles[i]
		tile.convert(Image.FORMAT_RGB8)
		var at := Vector2i(gap + (i % columns) * (w + gap), gap + (i / columns) * (h + gap))
		sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), at)
	return sheet


## The widget's on-screen rectangle in the captured image's pixels. Canvas
## stretch maps the 1920x1080 logical UI onto the window, so scale by the
## image/visible-rect ratio (and optionally onto a downscaled frame).
func _widget_rect(widget: Control, image: Image, target: Vector2 = Vector2.ZERO) -> Rect2i:
	var xf := widget.get_global_transform_with_canvas()
	var rect := xf * Rect2(Vector2.ZERO, widget.size)
	var visible := root.get_visible_rect().size
	var px := Vector2(image.get_size()) if target == Vector2.ZERO else target
	var scale := px / visible
	var out := Rect2i(Vector2i((rect.position * scale).round()), Vector2i((rect.size * scale).round()))
	return out.intersection(Rect2i(Vector2i.ZERO, Vector2i(px)))


func _find_preview(node: Node) -> Node:
	var script_res: Variant = node.get_script()
	if script_res != null and str(script_res.resource_path) == PREVIEW_SCRIPT and (node as CanvasItem).is_visible_in_tree():
		return node
	for child in node.get_children():
		var found := _find_preview(child)
		if found != null:
			return found
	return null


func _grab() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _save(image: Image, path: String) -> void:
	var rgb := image.duplicate() as Image
	rgb.convert(Image.FORMAT_RGB8)
	var err := rgb.save_jpg(ProjectSettings.globalize_path(path), JPG_QUALITY)
	if err != OK:
		_failures.append("save %s failed (%d)" % [path, err])
		return
	_written.append(path)


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _finish() -> void:
	print("%d files written under %s" % [_written.size(), OUT_DIR])
	for f in _failures:
		print("FAIL: %s" % f)
	quit(1 if not _failures.is_empty() else 0)
