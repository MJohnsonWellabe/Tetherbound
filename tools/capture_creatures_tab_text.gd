extends SceneTree

## Captures the pause-menu Creatures tab at a 1280x720 window and audits the
## raster size of every visible piece of text in it, for the X03 text-size
## order (UX §8: essential body text >= 18 px at 720p; ACCEPTANCE U2).
##
##   flock /tmp/claude-0/godot-render.lock xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_creatures_tab_text.gd -- --label=after
##
## NEVER `--headless` with a rendering driver (see tools/_capture_ui_survey.gd).
##
## Staging, stated so nobody mistakes it for gameplay: no world scene is loaded
## (the `Game` autoload mounts the pause menu itself); the party is cleared and
## refilled with five creatures carrying 14-letter nicknames (the name entry's
## MAX_LENGTH), so rows and the detail panel show their longest text.
##
## Output (under OUT_DIR/<label>/):
##   tab_slot<N>.jpg   the whole window with roster slot N selected
##   audit.txt         one line per visible text node: raster px, authored px,
##                     node path, first characters of its text
## The raster size is the authored font size times the window/canvas ratio,
## which is exactly how `canvas_items` stretch draws it.

const OUT_DIR := "res://ralph/reports/SHARED-UI/creatures-text"
const JPG_QUALITY := 0.85
const MIN_RASTER_PX := 18.0
const TEAM := [
	["terrapup", "Bartholomewsky"],
	["ripplet", "Wellingtonbeck"],
	["galewisp", "Featherstonemy"],
	["bramblebun", "Montgomeryhaze"],
	["mosshell", "Cornelius Vane"],
]

var _game: Node = null
var _menu: CanvasLayer = null
var _label := "after"
var _failures: Array[String] = []
var _written: Array[String] = []
var _audit: Array[String] = []


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
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
	var party: RefCounted = _game.get("party")
	party.call("clear")
	for entry: Array in TEAM:
		var creature: RefCounted = _game.call("make_creature", entry[0], entry[1])
		if creature == null or not bool(party.call("add", creature)):
			_failures.append("%s: could not add to party" % entry[0])
	var dir := OUT_DIR.path_join(_label)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for slot in [0, 4]:
		_menu.call("close")
		party.call("set_active", slot)
		if not bool(_menu.call("open", "creatures")):
			_failures.append("menu refused to open")
			break
		await _settle(12)
		var image := await _grab()
		_save(image, dir.path_join("tab_slot%d.jpg" % slot))
		if slot == 0:
			_audit_text(_menu, float(image.get_height()) / root.get_visible_rect().size.y)
			_audit_frame()
			var scroll := _detail_scroll(_menu)
			if scroll != null:
				_audit.append("detail scroll: at %d of %d" % [scroll.scroll_vertical,
					int(scroll.get_v_scroll_bar().max_value - scroll.size.y)])
				scroll.scroll_vertical = 0
				_save(await _grab(), dir.path_join("tab_slot0_top.jpg"))
	var file := FileAccess.open(ProjectSettings.globalize_path(dir.path_join("audit.txt")), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_audit) + "\n")
		_written.append(dir.path_join("audit.txt"))
	_finish()


func _audit_text(node: Node, ratio: float) -> void:
	var item := node as CanvasItem
	if item != null and not item.is_visible_in_tree():
		return
	var text := ""
	var size := 0
	if node is Label:
		text = (node as Label).text
		size = (node as Label).get_theme_font_size(&"font_size")
	elif node is Button:
		text = (node as Button).text
		size = (node as Button).get_theme_font_size(&"font_size")
	elif node is RichTextLabel:
		text = (node as RichTextLabel).get_parsed_text()
		size = (node as RichTextLabel).get_theme_font_size(&"normal_font_size")
	if not text.strip_edges().is_empty():
		var px := size * ratio
		var mark := "LOW " if px < MIN_RASTER_PX else "ok  "
		_audit.append("%s%5.1f px  (%2d)  %s  \"%s\"" % [
			mark, px, size, _menu.get_path_to(node),
			text.strip_edges().replace("\n", " / ").left(48)])
	for child in node.get_children():
		_audit_text(child, ratio)


## The menu frame must stay inside the canvas: a label that cannot wrap
## widens its column and pushes the whole frame past the right edge.
func _audit_frame() -> void:
	var frame := _menu.get_node_or_null(^"Root/Frame/Panel") as Control
	if frame == null:
		return
	var rect := frame.get_global_rect()
	var canvas := root.get_visible_rect()
	var inside := canvas.encloses(rect)
	_audit.append("%s frame %s inside canvas %s" % ["ok  " if inside else "LOW ", rect, canvas.size])
	if not inside:
		_failures.append("menu frame %s leaves the canvas %s" % [rect, canvas.size])


func _detail_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer and (node as Control).is_visible_in_tree():
		return node as ScrollContainer
	for child in node.get_children():
		var found := _detail_scroll(child)
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
