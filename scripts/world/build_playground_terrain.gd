extends SceneTree

## Bakes the M1 movement playground into Terrain3D region data.
##
##   godot --headless --path . --script scripts/world/build_playground_terrain.gd
##
## Run once; the output is committed as data. Nothing generates terrain at
## runtime. Re-run after editing data/config/terrain_playground.json.
##
## This exists because Terrain3D is normally sculpted by hand in the editor, and
## the development environment for this project is headless. Generating the
## heightfield from a seeded recipe is also reproducible, which hand-sculpting
## is not — the same config always bakes the same playground.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const DATA_DIR := "res://data/terrain/playground"

# Terrain3DData.MapType. The enum is not reachable through ClassDB on this
# build, so the values are named here rather than left as bare indices.
const MAP_HEIGHT := 0
const MAP_CONTROL := 1
const MAP_COLOR := 2


func _init() -> void:
	# Terrain3D builds its Terrain3DData on the node's first frame, not on
	# add_child, so the body has to be able to await. A SceneTree's _init cannot
	# be a coroutine; this can.
	_run()


func _run() -> void:
	var config := HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config; nothing baked")
		quit(1)
		return

	var field: RefCounted = HEIGHTFIELD.new(config)
	var world_size := int(config.get("world_size", 512))
	var region_size := int(config.get("region_size", 256))
	var spacing := float(config.get("vertex_spacing", 1.0))
	var size := int(world_size / spacing)

	if world_size % region_size != 0:
		push_error("world_size %d is not a multiple of region_size %d; the bake would straddle region boundaries and leave unfilled flat gaps" % [world_size, region_size])
		quit(1)
		return

	print("baking %dm playground, %dx%d samples at %.2fm spacing, %d regions of %d" %
		[world_size, size, size, spacing, (world_size / region_size) ** 2, region_size])

	var origin := -0.5 * size * spacing
	var height_image := Image.create_empty(size, size, false, Image.FORMAT_RF)
	var colour_image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)

	var colour_cfg: Dictionary = config.get("colour", {})
	var lowest := INF
	var highest := -INF
	var steep_samples := 0

	for pixel_z in size:
		var world_z := origin + pixel_z * spacing
		for pixel_x in size:
			var world_x := origin + pixel_x * spacing
			var height: float = field.height_at(world_x, world_z)
			height_image.set_pixel(pixel_x, pixel_z, Color(height, 0.0, 0.0, 1.0))

			var slope: float = field.slope_degrees_at(world_x, world_z, spacing)
			colour_image.set_pixel(pixel_x, pixel_z, _ground_colour(slope, colour_cfg))

			lowest = minf(lowest, height)
			highest = maxf(highest, height)
			if slope >= 30.0:
				steep_samples += 1

	print("  height range %.1fm .. %.1fm (relief %.1fm)" % [lowest, highest, highest - lowest])
	print("  %.1f%% of the surface is steeper than 30 degrees" % (100.0 * steep_samples / float(size * size)))

	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", region_size)
	terrain.set("vertex_spacing", spacing)
	terrain.set("data_directory", DATA_DIR)
	root.add_child(terrain)
	await process_frame

	var data: Object = terrain.get("data")
	if data == null:
		push_error("Terrain3D exposed no data object even after a frame")
		quit(1)
		return

	# import_images places the maps with their CENTRE at global_position, so the
	# region lands centred on the world origin and the player spawns in the
	# middle of the playground rather than at its corner.
	var images: Array[Image] = [null, null, null]
	images[MAP_HEIGHT] = height_image
	images[MAP_CONTROL] = null
	images[MAP_COLOR] = colour_image
	data.call("import_images", images, Vector3(origin, 0.0, origin), 0.0, 1.0)

	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(DATA_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATA_DIR))
	data.call("save_directory", DATA_DIR)

	print("baked -> %s" % DATA_DIR)
	quit(0)


## Slope-driven ground colour. Grass on walkable ground, soil on the shoulders,
## rock on genuinely steep faces.
##
## This is a MULTIPLIER over the PBR albedo, not a paint layer, and that changed
## what belongs in it. It was authored when the colour map WAS the ground — real
## grass green, real soil brown, no textures anywhere — and those values kept
## being multiplied into the textures after the textures arrived. Grass albedo at
## luminance 0.40 times a #496c34 colour map at 0.36 is a ground of 0.14 before
## a photon reaches it, which is why the near field measured 0.096 against
## 0.27-0.60 across the references and why nothing about the lighting fixed it:
## the surface was dark on paper.
##
## So these are near-white now. The textures carry the colour; this carries the
## slope-driven VARIATION, which is the job it is actually good at. Anything
## much below #c0 here is a brightness change pretending to be a colour.
func _ground_colour(slope_degrees: float, cfg: Dictionary) -> Color:
	var grass_low := Color(str(cfg.get("grass_low", "#496c34")))
	var grass_high := Color(str(cfg.get("grass_high", "#7f8c3d")))
	var soil := Color(str(cfg.get("soil", "#d1b37e")))
	var rock := Color(str(cfg.get("rock", "#b4b1a6")))
	var soil_at := float(cfg.get("soil_slope_deg", 24.0))
	var rock_at := float(cfg.get("rock_slope_deg", 38.0))
	var blend := maxf(0.001, float(cfg.get("blend_deg", 7.0)))

	# Flat ground varies between the two greens by slope alone, so a hillside
	# reads lighter than a hollow without needing a second noise field.
	var grass := grass_low.lerp(grass_high, clampf(slope_degrees / soil_at, 0.0, 1.0))
	var to_soil := smoothstep(soil_at, soil_at + blend, slope_degrees)
	var to_rock := smoothstep(rock_at, rock_at + blend, slope_degrees)
	return grass.lerp(soil, to_soil).lerp(rock, to_rock)
