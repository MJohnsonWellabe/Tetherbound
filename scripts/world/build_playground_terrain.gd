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
## For the authored routes only. The trail is painted into the ground here and
## laid with stones by the scatter, and both read the same polyline from
## data/config/trails.json — see that file's `_comment_one_source`.
const RULES := preload("res://scripts/world/scatter_rules.gd")
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
			var ground := _ground_colour(slope, colour_cfg)
			ground = _wear_the_trail(ground, world_x, world_z, colour_cfg)
			ground = _lay_the_shingle(ground, field, world_x, world_z, colour_cfg)
			colour_image.set_pixel(pixel_x, pixel_z, ground)

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
	_probe_the_authored_sites(field)
	quit(0)


## Report the ground under everything somebody placed by hand.
##
## Authored coordinates are typed, and a typed coordinate is a claim about
## terrain that nothing checks. A house whose pad did not take, a trail waypoint
## on a 40-degree face, a brook that stopped falling — all three look like an
## asset problem in the game and all three are visible here as a number, at the
## moment the terrain they depend on is written.
##
## The heightfield is asked directly rather than raycast, per D09. A quarter of
## downward rays miss ground that is demonstrably there.
func _probe_the_authored_sites(field: RefCounted) -> void:
	print("")
	print("authored sites, on the terrain just baked:")
	var sites: Dictionary = RULES.settlement().get("sites", {})
	for name: String in sites.keys():
		if name.begins_with("_"):
			continue
		var at: Array = (sites[name] as Dictionary).get("origin", [0.0, 0.0])
		var x := float(at[0])
		var z := float(at[1])
		var slope: float = field.slope_degrees_at(x, z)
		var flag := "" if slope < 3.0 else "   <-- NOT LEVEL; this site needs a pad in `pads`"
		print("  %-20s (%7.1f,%7.1f)  ground %6.2fm  slope %4.1f deg%s" % [name, x, z, field.height_at(x, z), slope, flag])

	for route: String in RULES.trails().get("routes", {}).keys():
		if route.begins_with("_"):
			continue
		var points := RULES.trail_points(route)
		var steepest := 0.0
		var awkward: Array[String] = []
		for spot in points:
			var slope: float = field.slope_degrees_at(spot.x, spot.y)
			steepest = maxf(steepest, slope)
			# Named, not just counted. "The steepest waypoint is 62 degrees" is
			# a fact you cannot act on; "(74,146) is 62 degrees" is an edit.
			if slope >= float(RULES.config().get("layers", {}).get("path_stones", {}).get("max_slope_deg", 26.0)):
				awkward.append("(%.0f,%.0f) at %.0f deg" % [spot.x, spot.y, slope])
		print("  trail '%s': %d waypoints, steepest %.1f deg" % [route, points.size(), steepest])
		if not awkward.is_empty():
			print("    the path stones will REFUSE these: %s" % ", ".join(awkward))

	for i in int(field.call("channel_count")):
		var spine: Array = field.call("channel_centreline", i, 4.0)
		if spine.is_empty():
			continue
		var source: Vector3 = spine[0]
		var mouth: Vector3 = spine[spine.size() - 1]
		var climbed := 0.0
		for step in range(1, spine.size()):
			climbed = maxf(climbed, float((spine[step] as Vector3).y) - float((spine[step - 1] as Vector3).y))
		print("  brook %d: bed falls %.1fm over %d samples, worst rise between samples %.3fm%s" % [
			i, source.y - mouth.y, spine.size(), climbed,
			"" if climbed <= 0.001 else "   <-- the bed goes UPHILL somewhere; water will pool"
		])


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


## Wear a track into the ground along the authored trail.
##
## The alternative was painting texture index 2 (soil) into Terrain3D's CONTROL
## map, which would give real dirt with its own albedo and normal instead of
## tinted grass. NOT ATTEMPTED, and the reason is worth writing down rather than
## rediscovering: the control layer is a uint32 bitfield reinterpreted through an
## RF image, `import_images` is the only way in from GDScript, and nothing in this
## project has ever written one. Getting the encoding subtly wrong produces a
## terrain that renders as a checkerboard or as one flat texture, which is a whole
## bake to find out. It is the right next move for the ground and it is on the
## record as such; it is not the move to make in the same pass that reshapes the
## terrain everything else stands on.
##
## So this is a multiply over the grass rather than a different material —
## darker, warmer, and honest about being trodden grass rather than bare earth.
##
## It is still the largest part of what makes the trail read. The stones alone
## were a dotted white line THROUGH the meadow, because the meadow closed over
## them from both sides; a path is defined by the ground it has worn as much as
## by anything laid on it. The vegetation layers keep off the same polyline
## (`off_trail` in vegetation.json), so the strip is bare as well as brown.
func _wear_the_trail(ground: Color, x: float, z: float, cfg: Dictionary) -> Color:
	var tint := Color(str(cfg.get("trail_colour", "#a08a5e")))
	var spot := Vector2(x, z)
	for route: String in RULES.trails().get("routes", {}).keys():
		if route.begins_with("_"):
			continue
		var geometry: Dictionary = RULES.trails()["routes"][route]
		var core := float(geometry.get("paint_half_width", 1.7))
		var edge := float(geometry.get("paint_edge", 2.8))
		var distance := RULES.distance_to_trail(route, spot)
		if distance >= core + edge:
			continue
		# Feathered, not stamped. A track with a crisp edge on both sides reads
		# as a decal laid on the grass rather than as ground people have walked
		# on, and the feather is where the two materials argue, which is where
		# every real path is scruffy.
		var strength := 1.0 - smoothstep(0.0, 1.0, maxf(0.0, distance - core) / maxf(0.001, edge))
		ground = ground.lerp(ground * tint, strength)
	return ground


## Pale shingle along the brook's banks.
##
## Same mechanism and the same argument: a watercourse whose banks are the same
## green as the meadow either side of it reads as a puddle in a lawn. This is the
## strip between the water and the grass, and it is what tells you at fifty
## metres that the green hollow has water in the bottom of it.
func _lay_the_shingle(ground: Color, field: RefCounted, x: float, z: float, cfg: Dictionary) -> Color:
	var core := float(cfg.get("shingle_half_width", 3.4))
	var edge := float(cfg.get("shingle_edge", 4.2))
	var distance: float = field.call("distance_to_channel", x, z)
	if distance >= core + edge:
		return ground
	var tint := Color(str(cfg.get("shingle_colour", "#cfc3a4")))
	var strength := 1.0 - smoothstep(0.0, 1.0, maxf(0.0, distance - core) / maxf(0.001, edge))
	return ground.lerp(ground * tint, strength)
