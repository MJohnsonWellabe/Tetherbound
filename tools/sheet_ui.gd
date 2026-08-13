extends SceneTree

## Contact sheet over the whole UI diagnostic suite (shots/_diag/*.png), the
## same idiom as tools/contact_sheet.gd -- READ THAT FIRST: `Image` has no font
## rendering in Godot, so a caption baked into the pixels is not on the table
## headless. That tool's answer is a coloured rule under each tile plus the
## reading order printed to stdout; this one copies it rather than inventing a
## second way to solve the same non-problem. tools/sheet.py is the PIL-backed
## alternative that DOES draw real text captions, for when a sheet has to
## stand alone outside this tool's own stdout.
##
##   godot --headless --path . --script tools/sheet_ui.gd
##
## Pure Image compositing -- no viewport, no rendering driver, confirmed by
## running under --headless with no xvfb.

const SHOTS_DIR := "res://shots/_diag"
const OUT_PATH := "res://shots/_diag/_ui_sheet.png"
const COLUMNS := 4
const TILE_WIDTH := 460
const PADDING := 12
const LABEL_HEIGHT := 22
const BACKGROUND := Color(0.07, 0.08, 0.09, 1.0)

## The UI suite's own filename families (task brief): hud_*, minimap_*,
## combat_*, pals_tab(.png), ui_*. Filtered rather than "every *.png in the
## dir" so a stray probe/debug frame someone drops in shots/_diag/ later
## doesn't silently ride along.
const PREFIXES := ["hud_", "minimap_", "combat_", "ui_", "pals_tab"]


func _init() -> void:
	var paths := _frame_paths()
	if paths.is_empty():
		push_error("no matching frames in %s; run the UI capture tools first" % SHOTS_DIR)
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
		push_error("every matching frame failed to load")
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
		# Same stand-in as contact_sheet.gd: a rule under each tile, real
		# captions printed to stdout below in reading order (also see
		# tools/sheet.py for a PNG that carries real text captions itself).
		_rule(sheet, x, y + tile.get_height() + 6, TILE_WIDTH, Color(0.42, 0.55, 0.29, 1.0))

	var error := sheet.save_png(OUT_PATH)
	if error != OK:
		push_error("could not write %s (%d)" % [OUT_PATH, error])
		quit(1)
		return

	print("%d tiles -> %s  (%dx%d, %d cols)" % [tiles.size(), OUT_PATH, sheet_width, sheet_height, COLUMNS])
	print("reading order, left to right, top to bottom:")
	for index in names.size():
		print("  %d. %s" % [index + 1, names[index]])
	print("")
	print("Frames are whatever each capture tool produced -- mixed Compatibility-renderer")
	print("software frames from several sessions. See each capture tool's own header for caveats.")
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
		if entry.ends_with(".png") and not entry.begins_with("_") and _matches_prefix(entry):
			out.append("%s/%s" % [SHOTS_DIR, entry])
		entry = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


func _matches_prefix(filename: String) -> bool:
	for prefix in PREFIXES:
		if filename.begins_with(prefix):
			return true
	return false
