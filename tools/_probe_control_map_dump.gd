extends SceneTree

## DUMP THE BAKED CONTROL MAP AS AN IMAGE. Headless, seconds, no renderer.
##
## Sibling of `_probe_control_map.gd`, which samples the same data and prints a
## histogram over a 400m square. This one writes the whole region out as false
## colour instead, because the question it was written for is about the SHAPE
## of what landed rather than the proportions: a histogram cannot tell a
## material boundary apart from a lattice of single-texel dropouts, and a
## picture can.
##
##   godot --headless --path . --script tools/_probe_control_map_dump.gd -- \
##     --region=0:0 [--data-dir=res://data/terrain/playground]
##
## Written for the dashed seam lines (JUDGE-VISUAL-2026-08-29 subject 5, still
## unattributed after two ground lanes). `tools/_probe_ground_seams.gd` settles
## the two hypotheses that were already on record; this one exists because the
## band-1 evidence frame ruled out the surviving candidate on its own terms.
## The dashes cross the SAND PATH as well as the grass, and both grass-field
## sheets carry `"path"` in their `forbidden_ground`, so neither of them draws
## a single fragment there -- whatever makes the marks is in the terrain data
## itself, and the control map is the only part of it written per world
## position rather than imported as a whole Image.
##
## So this dumps what actually landed in the map: base id, overlay id and blend
## as three PNGs, at one image pixel per control texel, colour-coded by id.
## Isolated texels and single-texel rows are what a dashed line looks like
## from inside the data, and they are visible at a glance in a false-colour
## dump in a way they are not in a rendered frame with grass on top of it.
##
## Also prints a NEIGHBOUR-DISAGREEMENT census: texels whose base id differs
## from all four of their orthogonal neighbours. A boundary between two
## materials produces long runs of texels that disagree with two neighbours
## and agree with two; an isolated texel that agrees with none of them is not
## a boundary, it is a dropout, and a regular lattice of dropouts is a dashed
## line.

const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")

const OUT_DIR := "res://shots/control_map"

## False colour per base texture id. Chosen to be told apart at a glance rather
## than to resemble the ground: this is a data dump, not a preview.
const ID_COLOURS := [
	Color(0.30, 0.65, 0.20),  # 0 grass
	Color(0.70, 0.50, 0.25),  # 1 soil
	Color(0.55, 0.55, 0.60),  # 2 rock
	Color(0.95, 0.85, 0.45),  # 3 path
	Color(0.25, 0.55, 0.85),  # 4 damp
	Color(0.45, 0.30, 0.15),  # 5 forest_floor
]


func _init() -> void:
	var region := Vector2i(0, 0)
	var data_dir := "res://data/terrain/playground"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--region="):
			var parts := arg.substr("--region=".length()).split(":")
			if parts.size() == 2:
				region = Vector2i(int(parts[0]), int(parts[1]))
		elif arg.begins_with("--data-dir="):
			data_dir = arg.substr("--data-dir=".length())
	_run(region, data_dir)


func _run(region: Vector2i, data_dir: String) -> void:
	var config: Dictionary = _load_json("res://data/config/terrain_playground.json")
	var region_size := int(config.get("region_size", 256))
	var spacing := float(config.get("vertex_spacing", 2.0))

	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", region_size)
	terrain.set("vertex_spacing", spacing)
	terrain.set("data_directory", data_dir)
	root.add_child(terrain)
	await process_frame

	var data: Object = terrain.get("data")
	if data == null:
		push_error("Terrain3D exposed no data object")
		quit(1)
		return

	var rect := ALIGNMENT.region_world_rect(region, region_size, spacing)
	var origin := Vector3(rect["min_x"], 0.0, rect["min_z"])
	print("region %s, x[%.0f,%.0f] z[%.0f,%.0f], %d x %d texels at %.1fm" % [
		str(region), rect["min_x"], rect["max_x"], rect["min_z"], rect["max_z"],
		region_size, region_size, spacing])

	var base_img := Image.create_empty(region_size, region_size, false, Image.FORMAT_RGB8)
	var blend_img := Image.create_empty(region_size, region_size, false, Image.FORMAT_RGB8)
	var ids := PackedInt32Array()
	ids.resize(region_size * region_size)
	var histogram := {}
	for pz in region_size:
		for px in region_size:
			var at := Vector3(origin.x + px * spacing, 0.0, origin.z + pz * spacing)
			var base_id: int = data.call("get_control_base_id", at)
			var blend: float = data.call("get_control_blend", at)
			ids[pz * region_size + px] = base_id
			histogram[base_id] = int(histogram.get(base_id, 0)) + 1
			var colour: Color = ID_COLOURS[base_id] if base_id >= 0 and base_id < ID_COLOURS.size() \
				else Color(1.0, 0.0, 1.0)
			base_img.set_pixel(px, pz, colour)
			blend_img.set_pixel(px, pz, Color(blend, blend, blend))

	print("  base id histogram (texels): %s" % str(histogram))

	# The dropout census. A material BOUNDARY has each texel agreeing with the
	# neighbours on its own side; a texel agreeing with NONE of its four is an
	# isolated speck, and specks arranged on a lattice are the artefact.
	var isolated := 0
	var isolated_img := Image.create_empty(region_size, region_size, false, Image.FORMAT_RGB8)
	isolated_img.fill(Color.BLACK)
	for pz in range(1, region_size - 1):
		for px in range(1, region_size - 1):
			var here := ids[pz * region_size + px]
			var same := 0
			for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if ids[(pz + step.y) * region_size + px + step.x] == here:
					same += 1
			if same == 0:
				isolated += 1
				isolated_img.set_pixel(px, pz, Color.WHITE)
	var interior := float((region_size - 2) * (region_size - 2))
	print("  isolated texels (base id differs from ALL four neighbours): %d of %d (%.3f%%)" % [
		isolated, int(interior), 100.0 * float(isolated) / interior])

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var stem := "%s/region_%d_%d" % [OUT_DIR, region.x, region.y]
	base_img.save_png(ProjectSettings.globalize_path("%s_base.png" % stem))
	blend_img.save_png(ProjectSettings.globalize_path("%s_blend.png" % stem))
	isolated_img.save_png(ProjectSettings.globalize_path("%s_isolated.png" % stem))
	print("  wrote %s_{base,blend,isolated}.png" % stem)
	quit(0)


func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}
