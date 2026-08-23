extends SceneTree

## Assemble the survey frames into one labelled contact sheet.
##
##   godot --headless --path . --script tools/contact_sheet.gd
##
## Why a sheet and not just the frames: defects that are invisible in any single
## frame are obvious when frames sit side by side. Two views disagreeing about
## fog, a palette that drifts between locations, one biome reading as a
## different game from the next — none of those are visible one image at a time.
## That was the single most useful property of the previous project's harness.
##
## Runs headless: this is image compositing, not rendering.

## Both overridable, so a lane can sheet its own capture set without moving
## files into `res://shots` and disturbing the standing survey:
##
##   godot --headless --path . --script tools/contact_sheet.gd -- \
##     --dir=res://shots/band5_approach
##   godot --headless --path . --script tools/contact_sheet.gd -- \
##     --dir=shots/band3 --out=res://shots/band3/_sheet.png
##
## The D3 and D5 lanes each added this independently, within hours, for the same
## reason: both had a region's worth of frames to put in front of the blind
## critic and no way to sheet them without clobbering the five survey shots the
## visual-judge skill expects to find in `res://shots`. This is the union of the
## two. `--dir` accepts a path with or without the `res://` prefix and with or
## without a trailing slash (D3's normalisation, because a lane WILL pass one of
## each), and defaults the sheet to `<dir>/_sheet.png` so the common case needs
## one flag. `--out` overrides that explicitly (D5's), and wins regardless of
## argument order.
const DEFAULT_SHOTS_DIR := "res://shots"
const DEFAULT_OUT_PATH := "res://shots/_sheet.png"

var _shots_dir := DEFAULT_SHOTS_DIR
var _out_path := DEFAULT_OUT_PATH
const COLUMNS := 3
const TILE_WIDTH := 620
const PADDING := 14
const LABEL_HEIGHT := 26
const BACKGROUND := Color(0.07, 0.08, 0.09, 1.0)


func _init() -> void:
	var explicit_out := ""
	for argument in OS.get_cmdline_user_args():
		var parts := argument.split("=", true, 1)
		var key := parts[0].lstrip("-")
		if parts.size() < 2:
			continue
		if key == "dir":
			_shots_dir = "res://%s" % parts[1].trim_prefix("res://").trim_suffix("/")
			_out_path = "%s/_sheet.png" % _shots_dir
		elif key == "out":
			explicit_out = parts[1]
	# Applied after the loop so `--out` wins whichever side of `--dir` it was
	# passed on; `--dir` sets a default out as a side effect.
	if explicit_out != "":
		_out_path = explicit_out
	var paths := _frame_paths()
	if paths.is_empty():
		push_error("no frames in %s; run tools/survey.sh first" % _shots_dir)
		quit(1)
		return

	var tiles: Array[Image] = []
	var names: Array[String] = []
	var tile_height := 0

	for path in paths:
		var image := Image.load_from_file(path)
		if image == null:
			push_warning("could not read %s" % path)
			continue
		var scale := float(TILE_WIDTH) / float(image.get_width())
		var height := int(round(image.get_height() * scale))
		image.resize(TILE_WIDTH, height, Image.INTERPOLATE_LANCZOS)
		tiles.append(image)
		names.append(path.get_file().get_basename())
		tile_height = maxi(tile_height, height)

	if tiles.is_empty():
		push_error("every frame failed to load")
		quit(1)
		return

	var rows := int(ceil(float(tiles.size()) / float(COLUMNS)))
	var cell_height := tile_height + LABEL_HEIGHT
	var sheet_width := COLUMNS * TILE_WIDTH + (COLUMNS + 1) * PADDING
	var sheet_height := rows * cell_height + (rows + 1) * PADDING

	var sheet := Image.create_empty(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	sheet.fill(BACKGROUND)

	for index in tiles.size():
		var column := index % COLUMNS
		var row := index / COLUMNS
		var x := PADDING + column * (TILE_WIDTH + PADDING)
		var y := PADDING + row * (cell_height + PADDING)
		var tile: Image = tiles[index]
		if tile.get_format() != Image.FORMAT_RGBA8:
			tile.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(x, y))
		# A thin rule under each tile stands in for text: Image has no font
		# rendering, and pulling in a Label + viewport to draw five captions
		# would cost more than it returns. The frame ORDER is fixed and printed
		# below, which is enough to name any tile.
		_rule(sheet, x, y + tile.get_height() + 8, TILE_WIDTH, Color(0.42, 0.55, 0.29, 1.0))

	var error := sheet.save_png(_out_path)
	if error != OK:
		push_error("could not write %s (%d)" % [_out_path, error])
		quit(1)
		return

	print("%d tiles -> %s  (%dx%d)" % [tiles.size(), _out_path, sheet_width, sheet_height])
	print("reading order, left to right, top to bottom:")
	for index in names.size():
		print("  %d. %s" % [index + 1, names[index]])
	print("")
	print("Software rendering, Compatibility renderer. See tools/survey.sh for what")
	print("these frames can and cannot be used to judge.")
	quit(0)


func _rule(target: Image, x: int, y: int, width: int, colour: Color) -> void:
	var bar := Image.create_empty(width, 3, false, Image.FORMAT_RGBA8)
	bar.fill(colour)
	target.blit_rect(bar, Rect2i(0, 0, width, 3), Vector2i(x, y))


func _frame_paths() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(_shots_dir)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		# Skip the sheet itself, or each run composites the previous one in.
		if entry.ends_with(".png") and not entry.begins_with("_"):
			out.append("%s/%s" % [_shots_dir, entry])
		entry = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out
