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

const SHOTS_DIR := "res://shots"
const OUT_PATH := "res://shots/_sheet.png"
const COLUMNS := 3
const TILE_WIDTH := 620
const PADDING := 14
const LABEL_HEIGHT := 26
const BACKGROUND := Color(0.07, 0.08, 0.09, 1.0)


func _init() -> void:
	var paths := _frame_paths()
	if paths.is_empty():
		push_error("no frames in %s; run tools/survey.sh first" % SHOTS_DIR)
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

	var error := sheet.save_png(OUT_PATH)
	if error != OK:
		push_error("could not write %s (%d)" % [OUT_PATH, error])
		quit(1)
		return

	print("%d tiles -> %s  (%dx%d)" % [tiles.size(), OUT_PATH, sheet_width, sheet_height])
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
	var dir := DirAccess.open(SHOTS_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		# Skip the sheet itself, or each run composites the previous one in.
		if entry.ends_with(".png") and not entry.begins_with("_"):
			out.append("%s/%s" % [SHOTS_DIR, entry])
		entry = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out
