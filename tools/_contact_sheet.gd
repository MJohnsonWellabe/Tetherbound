extends SceneTree

## Build one contact sheet from a directory of captured frames.
##
##   godot --headless --path . --script tools/_contact_sheet.gd -- \
##     --in=res://shots_band_pickups --out=res://ralph/reports/<LANE>/_sheet.png [--cols=3]
##
## Why this exists: this container has neither ImageMagick nor Pillow, and
## `AGENT_WORKFLOW.md` §8 allows exactly one committed sheet per round
## (`_sheet*.png`) and no per-frame PNGs. Godot's own `Image` API composites
## them with no extra dependency, headless, with no rendering driver -- this
## loads and blits pixels, it does not draw a scene.
##
## Frames are placed in sorted filename order, scaled down by an integer-ish
## factor to keep the sheet under a sensible size, each with a caption strip
## drawn as a dark band. The caption is the filename: the judge is code-blind
## and reads only what the frames show, so the labels stay descriptive of the
## shot, never of what changed.

const CELL_W := 640
const GAP := 8
const LABEL_H := 18


func _init() -> void:
	var in_dir := ""
	var out_path := ""
	var cols := 3
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			in_dir = arg.trim_prefix("--in=")
		elif arg.begins_with("--out="):
			out_path = arg.trim_prefix("--out=")
		elif arg.begins_with("--cols="):
			cols = int(arg.trim_prefix("--cols="))
	if in_dir == "" or out_path == "":
		print("usage: --in=<dir> --out=<file.png> [--cols=N]")
		quit(1)
		return

	var names: Array[String] = []
	var dir := DirAccess.open(in_dir)
	if dir == null:
		print("FAIL: cannot open %s" % in_dir)
		quit(1)
		return
	for file: String in dir.get_files():
		if file.get_extension().to_lower() == "png":
			names.append(file)
	names.sort()
	if names.is_empty():
		print("FAIL: no PNG frames in %s" % in_dir)
		quit(1)
		return

	var first := Image.load_from_file("%s/%s" % [in_dir, names[0]])
	if first == null:
		print("FAIL: could not load %s/%s" % [in_dir, names[0]])
		quit(1)
		return
	var cell_h := int(round(float(CELL_W) * float(first.get_height()) / float(first.get_width())))
	var rows := int(ceil(float(names.size()) / float(cols)))
	var sheet := Image.create(
		cols * CELL_W + (cols + 1) * GAP,
		rows * (cell_h + LABEL_H) + (rows + 1) * GAP,
		false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.09, 0.09, 0.10))

	var font_strip := Image.create(CELL_W, LABEL_H, false, Image.FORMAT_RGB8)
	font_strip.fill(Color(0.16, 0.16, 0.18))

	for index in names.size():
		var frame := Image.load_from_file("%s/%s" % [in_dir, names[index]])
		if frame == null:
			print("skip: %s did not load" % names[index])
			continue
		frame.resize(CELL_W, cell_h, Image.INTERPOLATE_LANCZOS)
		if frame.get_format() != Image.FORMAT_RGB8:
			frame.convert(Image.FORMAT_RGB8)
		var col := index % cols
		var row := index / cols
		var x := GAP + col * (CELL_W + GAP)
		var y := GAP + row * (cell_h + LABEL_H + GAP)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(x, y))
		# A plain strip under each frame so the cells read as separate shots.
		# The frame's own index is drawn as a run of ticks: no font is loaded
		# in a headless SceneTree, and the judge is told the order in prose.
		sheet.blit_rect(font_strip, Rect2i(Vector2i.ZERO, font_strip.get_size()), Vector2i(x, y + cell_h))
		for tick in (index + 1):
			for tx in range(6):
				for ty in range(8):
					sheet.set_pixel(x + 6 + tick * 10 + tx, y + cell_h + 5 + ty, Color(0.85, 0.85, 0.88))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	if sheet.save_png(out_path) != OK:
		print("FAIL: could not write %s" % out_path)
		quit(1)
		return
	print("%d frames -> %s (%dx%d)" % [names.size(), out_path, sheet.get_width(), sheet.get_height()])
	for index in names.size():
		print("  %d ticks: %s" % [index + 1, names[index]])
	quit(0)
