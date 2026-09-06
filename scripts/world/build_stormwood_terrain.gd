extends SceneTree

## Offline Terrain3D height bake for Stormwood.
##
## The heightfield is deliberately the only producer of geometry here.  The
## field implementation remains replaceable while the region lifecycle,
## alignment rules, and freshness contract stay stable.

const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")

const CONFIG_PATH := "res://data/config/terrain_stormwood.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const DATA_DIR := "res://data/terrain/stormwood"
const SCRIPT_PATH := "res://scripts/world/build_stormwood_terrain.gd"
const MAP_HEIGHT := 0


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


func _run() -> void:
	var config := _load_json(CONFIG_PATH)
	var config_error := validate_config(config)
	if not config_error.is_empty():
		push_error(config_error)
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
	var completed := 0
	for location in locations:
		await _bake_region(data, field, ALIGNMENT.region_world_rect(location, 256, 2.0))
		completed += 1
		print("stormwood terrain: region %d/%d %s" % [completed, locations.size(), str(location)])
	data.call("save_directory", data_dir)
	# A partial bake intentionally gets no manifest.  Existing full-world data
	# therefore cannot be mistaken for fresh after an incremental debug run.
	if full_bake:
		_write_manifest(data_dir, config, locations.size())
	else:
		_invalidate_manifest(data_dir)
	quit(0)


func _bake_region(data: Object, field: RefCounted, rect: Dictionary) -> void:
	var size := 256
	var height_image := Image.create_empty(size, size, false, Image.FORMAT_RF)
	for pixel_z in size:
		var world_z := float(rect["min_z"]) + pixel_z * 2.0
		for pixel_x in size:
			var world_x := float(rect["min_x"]) + pixel_x * 2.0
			height_image.set_pixel(pixel_x, pixel_z, Color(field.height_at(world_x, world_z), 0.0, 0.0, 1.0))
	var images: Array[Image] = [null, null, null]
	images[MAP_HEIGHT] = height_image
	data.call("import_images", images, Vector3(rect["min_x"], 0.0, rect["min_z"]), 0.0, 1.0)
	await process_frame


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _write_manifest(data_dir: String, config: Dictionary, region_count: int) -> void:
	var sources := {}
	for path in [CONFIG_PATH, WORLD_PATH, SCRIPT_PATH, "res://scripts/world/stormwood_heightfield.gd"]:
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
