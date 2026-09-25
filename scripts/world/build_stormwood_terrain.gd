extends SceneTree

## Offline Terrain3D bake for Stormwood: heights and the route surface.
##
## The heightfield is deliberately the only producer of geometry here.  The
## field implementation remains replaceable while the region lifecycle,
## alignment rules, and freshness contract stay stable.
##
## WO-F09-04: every route in stormwood_world.json is also painted into the
## control map as the `path` texture slot (config stormwood_road_surface.json).
## A painted texel is {base: path, overlay: path, blend: 0, auto: off}; every
## other texel is the default auto-shader texel the heights-only bake always
## wrote. Meadows (build_playground_terrain.gd) measured that a partial control
## blend does not draw on this build and a base-id assignment does, so the lane
## edge is a ragged threshold rather than a blend ramp. grass_field.gd reads
## the same control map, so its grass refuses the lane and its stones fill it.
## Painting never touches the height channel.

const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")

const CONFIG_PATH := "res://data/config/terrain_stormwood.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const DATA_DIR := "res://data/terrain/stormwood"
const SCRIPT_PATH := "res://scripts/world/build_stormwood_terrain.gd"
const SURFACE_PATH := "res://data/config/stormwood_road_surface.json"
const TEXTURES_PATH := "res://data/config/terrain_playground.json"
const MAP_HEIGHT := 0
const MAP_CONTROL := 1
const REGION_SIZE := 256
const SPACING := 2.0
## Terrain3D's default control texel: auto-shader on, base/overlay 0, blend 0.
const CONTROL_AUTO := 1


func _init() -> void:
	_run()


static func validate_config(config: Dictionary) -> String:
	for key in ["region_size", "vertex_spacing"]:
		if not config.has(key):
			return "missing required key: %s" % key
	if int(config["region_size"]) != 256:
		return "region_size must be 256"
	if not is_equal_approx(float(config["vertex_spacing"]), 2.0):
		return "vertex_spacing must be 2.0"
	if not config.has("world_bounds") or not config["world_bounds"] is Dictionary:
		return "missing world_bounds dictionary"
	var bounds: Dictionary = config["world_bounds"]
	var expected := {"min_x": -2560.0, "max_x": 2048.0, "min_z": 0.0, "max_z": 6144.0}
	for key in expected:
		if not bounds.has(key) or not is_equal_approx(float(bounds[key]), expected[key]):
			return "world_bounds.%s must be %s" % [key, str(expected[key])]
	return ALIGNMENT.check_alignment(bounds, 256, 2.0)


static func canonical_hash(source: String, path: String) -> int:
	return (source.replace("\r\n", "\n").hash() + path.hash()) & 0x1FFFFFFFFFFFFF


static func dependency_fingerprint(sources: Dictionary) -> int:
	var combined := ""
	var keys: Array = sources.keys()
	keys.sort()
	for path in keys:
		combined += "%s\n%s\n" % [str(path), str(sources[path]).replace("\r\n", "\n")]
	return combined.hash() & 0x1FFFFFFFFFFFFF


static func parse_regions(arguments: Array[String], bounds: Dictionary) -> Array[Vector2i]:
	for argument in arguments:
		if not argument.begins_with("--regions="):
			continue
		var result: Array[Vector2i] = []
		for pair in argument.substr("--regions=".length()).split(",", false):
			var pieces := pair.split(":")
			if pieces.size() != 2 or not pieces[0].is_valid_int() or not pieces[1].is_valid_int():
				return []
			result.append(Vector2i(int(pieces[0]), int(pieces[1])))
		return result
	return ALIGNMENT.region_locations(bounds, 256, 2.0)


static func is_full_region_set(locations: Array[Vector2i], bounds: Dictionary) -> bool:
	var expected := ALIGNMENT.region_locations(bounds, 256, 2.0)
	if locations.size() != expected.size():
		return false
	var actual_keys := {}
	for location in locations:
		var key := "%d:%d" % [location.x, location.y]
		if actual_keys.has(key):
			return false
		actual_keys[key] = true
	for location in expected:
		if not actual_keys.has("%d:%d" % [location.x, location.y]):
			return false
	return true


## Every source whose text decides the baked output, heights and surface.
static func dependency_paths() -> Array[String]:
	return [CONFIG_PATH, WORLD_PATH, SCRIPT_PATH, "res://scripts/world/stormwood_heightfield.gd",
		SURFACE_PATH, TEXTURES_PATH]


## The manifest fingerprint the current checkout's sources would produce.
static func current_fingerprint() -> int:
	var sources := {}
	for path in dependency_paths():
		var file := FileAccess.open(path, FileAccess.READ)
		sources[path] = "" if file == null else file.get_as_text()
	return dependency_fingerprint(sources)


# ------------------------------------------------------------- route surface

## Terrain3D control texel for `texture_id` as the whole surface: base and
## overlay both that id, blend 0, auto-shader bit clear.
static func painted_control(texture_id: int) -> int:
	return ((texture_id & 0x1F) << 27) | ((texture_id & 0x1F) << 22)


## Id of texture `name` in terrain_playground.json's list (the order
## stormwood_world.gd builds the Terrain3D texture slots in), or -1.
static func texture_id(name: String, textures: Array = []) -> int:
	if textures.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEXTURES_PATH))
		textures = (parsed as Dictionary).get("textures", []) if parsed is Dictionary else []
	for index in textures.size():
		if str((textures[index] as Dictionary).get("name", "")) == name:
			return index
	return -1


## "" when every route kind has a lane width and the edge keeps a painted
## texel within reach of every centreline point on the 2 m lattice.
static func validate_surface(surface: Dictionary, routes: Array) -> String:
	var widths: Dictionary = surface.get("lane_half_width_m", {})
	var edge: Dictionary = surface.get("edge", {})
	var slack := float(edge.get("wander_m", 0.0)) + float(edge.get("fringe_m", 0.0)) * 0.5
	for route: Dictionary in routes:
		var kind := str(route.get("kind", ""))
		if not widths.has(kind):
			return "stormwood_road_surface.json has no lane_half_width_m for route kind '%s' (%s)" % [kind, str(route.get("id", "?"))]
		if float(widths[kind]) - slack < 1.25:
			return "lane_half_width_m.%s minus the edge wander and half the fringe is under 1.25 m" % kind
	if texture_id(str(surface.get("texture", ""))) < 0:
		return "stormwood_road_surface.json texture '%s' is not a terrain_playground.json slot" % str(surface.get("texture", ""))
	return ""


## One entry per route segment: {route, kind, a, b, half, start_m, flare_m,
## flare_length_m}. `start_m` is the segment's distance from the route's first
## point; only spurs flare, and only near that first point (their junction).
static func lane_segments(routes: Array, surface: Dictionary) -> Array[Dictionary]:
	var widths: Dictionary = surface.get("lane_half_width_m", {})
	var junction: Dictionary = surface.get("junction", {})
	var out: Array[Dictionary] = []
	for route: Dictionary in routes:
		var kind := str(route.get("kind", ""))
		var points: Array = route.get("points", [])
		var run := 0.0
		for i in range(1, points.size()):
			var a := Vector2(float(points[i - 1][0]), float(points[i - 1][1]))
			var b := Vector2(float(points[i][0]), float(points[i][1]))
			out.append({"route": str(route.get("id", "")), "kind": kind, "a": a, "b": b,
				"half": float(widths.get(kind, 0.0)), "start_m": run,
				"flare_m": float(junction.get("flare_m", 0.0)) if kind == "spur" else 0.0,
				"flare_length_m": float(junction.get("flare_length_m", 1.0))})
			run += a.distance_to(b)
	return out


## Lane half-width of `segment` at the point `along_m` from its route's start.
static func lane_half_width(segment: Dictionary, along_m: float) -> float:
	var flare := float(segment.flare_m)
	if flare <= 0.0:
		return float(segment.half)
	return float(segment.half) + flare * (1.0 - smoothstep(0.0, maxf(0.01, float(segment.flare_length_m)), along_m))


static func edge_noise(surface: Dictionary) -> FastNoiseLite:
	var edge: Dictionary = surface.get("edge", {})
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = int(edge.get("seed", 20260925))
	noise.frequency = 1.0 / maxf(1.0, float(edge.get("wander_wavelength_m", 26.0)))
	return noise


## Per-texel 0..1 hash of the global lattice index. Integer arithmetic only,
## so the fringe is identical on every machine.
static func texel_hash(ix: int, iz: int) -> float:
	var h := (ix * 374761393 + iz * 668265263) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 65535.0


## Every painted texel as {Vector2i(ix, iz): true}, where the texel sits at
## world (min_x + ix * 2, min_z + iz * 2). A pure function of the routes,
## `surface` and `bounds`.
static func painted_texels(routes: Array, surface: Dictionary, bounds: Dictionary) -> Dictionary:
	var edge: Dictionary = surface.get("edge", {})
	var wander := float(edge.get("wander_m", 0.0))
	var fringe := float(edge.get("fringe_m", 0.0))
	var noise := edge_noise(surface)
	var min_x := float(bounds.min_x)
	var min_z := float(bounds.min_z)
	var count_x := int(round((float(bounds.max_x) - min_x) / SPACING))
	var count_z := int(round((float(bounds.max_z) - min_z) / SPACING))
	var out := {}
	for segment: Dictionary in lane_segments(routes, surface):
		var a: Vector2 = segment.a
		var b: Vector2 = segment.b
		var reach := float(segment.half) + float(segment.flare_m) + wander + fringe * 0.5
		var ix0 := maxi(0, int(floor((minf(a.x, b.x) - reach - min_x) / SPACING)))
		var ix1 := mini(count_x - 1, int(ceil((maxf(a.x, b.x) + reach - min_x) / SPACING)))
		var iz0 := maxi(0, int(floor((minf(a.y, b.y) - reach - min_z) / SPACING)))
		var iz1 := mini(count_z - 1, int(ceil((maxf(a.y, b.y) + reach - min_z) / SPACING)))
		for iz in range(iz0, iz1 + 1):
			var z := min_z + iz * SPACING
			for ix in range(ix0, ix1 + 1):
				var key := Vector2i(ix, iz)
				if out.has(key):
					continue
				var p := Vector2(min_x + ix * SPACING, z)
				var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
				var distance := p.distance_to(closest)
				if distance > reach:
					continue
				var half := lane_half_width(segment, float(segment.start_m) + a.distance_to(closest))
				var limit := half + wander * noise.get_noise_2d(p.x, p.y) + (texel_hash(ix, iz) - 0.5) * fringe
				if distance <= limit:
					out[key] = true
	return out


## The control image for one region: every texel the default auto texel,
## except `painted` texels inside this region, which are `painted_value`.
static func region_control_image(rect: Dictionary, bounds: Dictionary, painted: Dictionary,
		painted_value: int, template: PackedByteArray) -> Image:
	var bytes := template.duplicate()
	var ox := int(round((float(rect.min_x) - float(bounds.min_x)) / SPACING))
	var oz := int(round((float(rect.min_z) - float(bounds.min_z)) / SPACING))
	for pz in REGION_SIZE:
		for px in REGION_SIZE:
			if painted.has(Vector2i(ox + px, oz + pz)):
				bytes.encode_u32((pz * REGION_SIZE + px) * 4, painted_value)
	return Image.create_from_data(REGION_SIZE, REGION_SIZE, false, Image.FORMAT_RF, bytes)


static func default_control_bytes() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(REGION_SIZE * REGION_SIZE * 4)
	for i in REGION_SIZE * REGION_SIZE:
		bytes.encode_u32(i * 4, CONTROL_AUTO)
	return bytes


func _run() -> void:
	var config := _load_json(CONFIG_PATH)
	var config_error := validate_config(config)
	if not config_error.is_empty():
		push_error(config_error)
		quit(1)
		return
	var routes: Array = _load_json(WORLD_PATH).get("routes", [])
	var surface := _load_json(SURFACE_PATH)
	var surface_error := validate_surface(surface, routes)
	if not surface_error.is_empty():
		push_error(surface_error)
		quit(1)
		return
	var bounds: Dictionary = config["world_bounds"]
	var locations := parse_regions(OS.get_cmdline_user_args(), bounds)
	if locations.is_empty():
		push_error("no Stormwood regions requested")
		quit(1)
		return
	var data_dir := DATA_DIR
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--data-dir="):
			data_dir = argument.substr("--data-dir=".length())
	var counts := ALIGNMENT.region_counts(bounds, 256, 2.0)
	var full_bake := is_full_region_set(locations, bounds)
	var field: RefCounted = HEIGHTFIELD.new(config)
	# Terrain3D scans its data directory while constructing Terrain3DData. Make
	# the directory first so a clean checkout does not emit a false load error.
	var output_absolute := ProjectSettings.globalize_path(data_dir)
	if not DirAccess.dir_exists_absolute(output_absolute):
		DirAccess.make_dir_recursive_absolute(output_absolute)
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", 256)
	terrain.set("vertex_spacing", 2.0)
	terrain.set("data_directory", data_dir)
	root.add_child(terrain)
	await process_frame
	var data: Object = terrain.get("data")
	if data == null:
		push_error("Terrain3D exposed no data object")
		quit(1)
		return
	var surface_start := Time.get_ticks_msec()
	var painted := painted_texels(routes, surface, bounds)
	var path_control := painted_control(texture_id(str(surface.texture)))
	var template := default_control_bytes()
	print("stormwood terrain: %d route texels painted as '%s' (%d ms)" % [
		painted.size(), str(surface.texture), Time.get_ticks_msec() - surface_start])
	var completed := 0
	for location in locations:
		var rect := ALIGNMENT.region_world_rect(location, 256, 2.0)
		await _bake_region(data, field, rect, region_control_image(rect, bounds, painted, path_control, template))
		completed += 1
		print("stormwood terrain: region %d/%d %s" % [completed, locations.size(), str(location)])
	_pin_subresource_ids(data, locations)
	data.call("save_directory", data_dir)
	# A partial bake intentionally gets no manifest.  Existing full-world data
	# therefore cannot be mistaken for fresh after an incremental debug run.
	if full_bake:
		_write_manifest(data_dir, config, locations.size())
	else:
		_invalidate_manifest(data_dir)
	quit(0)


func _bake_region(data: Object, field: RefCounted, rect: Dictionary, control_image: Image) -> void:
	var size := 256
	var height_image := Image.create_empty(size, size, false, Image.FORMAT_RF)
	for pixel_z in size:
		var world_z := float(rect["min_z"]) + pixel_z * 2.0
		for pixel_x in size:
			var world_x := float(rect["min_x"]) + pixel_x * 2.0
			height_image.set_pixel(pixel_x, pixel_z, Color(field.height_at(world_x, world_z), 0.0, 0.0, 1.0))
	var images: Array[Image] = [null, null, null]
	images[MAP_HEIGHT] = height_image
	images[MAP_CONTROL] = control_image
	data.call("import_images", images, Vector3(rect["min_x"], 0.0, rect["min_z"]), 0.0, 1.0)
	await process_frame


## Godot's resource saver names each unnamed sub-resource with a random id
## (`Image_xxxxx`), so two bakes of identical content wrote different bytes.
## Naming each region's three map images first makes the files reproducible.
func _pin_subresource_ids(data: Object, locations: Array[Vector2i]) -> void:
	for location in locations:
		var region: Object = data.call("get_region", location)
		if region == null:
			continue
		for map_name in ["height_map", "control_map", "color_map"]:
			var image: Variant = region.get(map_name)
			if image is Image:
				(image as Image).set_scene_unique_id(map_name.replace("_", ""))


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _write_manifest(data_dir: String, config: Dictionary, region_count: int) -> void:
	var sources := {}
	for path in dependency_paths():
		var file := FileAccess.open(path, FileAccess.READ)
		sources[path] = "" if file == null else file.get_as_text()
	var hashes := {}
	for path in sources:
		hashes[path] = canonical_hash(str(sources[path]), str(path))
	var absolute := ProjectSettings.globalize_path(data_dir)
	if not DirAccess.dir_exists_absolute(absolute):
		DirAccess.make_dir_recursive_absolute(absolute)
	var manifest := {
		"schema_version": 1,
		"world": "stormwood",
		"region_size": 256,
		"vertex_spacing": 2.0,
		"regions": region_count,
		"dependency_hashes": hashes,
		"dependency_fingerprint": dependency_fingerprint(sources)
	}
	var file := FileAccess.open("%s/manifest.json" % data_dir, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "  "))


func _invalidate_manifest(data_dir: String) -> void:
	var manifest_path := "%s/manifest.json" % data_dir
	if FileAccess.file_exists(manifest_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manifest_path))
