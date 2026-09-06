extends SceneTree

## Offline sparse Terrain3D bake. Runtime loads committed regions. No terrain
## generation during play, and no dependence on whichever peer owns a camera.
const CONFIG := "res://data/config/water_world.json"
const VISUAL_CONFIG := "res://data/config/water_visual.json"
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const OUTPUT := "res://data/terrain/water"


func _init() -> void:
	_run()


func _run() -> void:
	var source := FileAccess.get_file_as_string(CONFIG)
	var config: Variant = JSON.parse_string(source)
	if not config is Dictionary or not ClassDB.class_exists("Terrain3D"):
		push_error("Water bake needs its config and Terrain3D extension")
		quit(1)
		return
	var field := FIELD.new(config)
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VISUAL_CONFIG))
	var spec: Dictionary = config.terrain
	var size := int(spec.region_size)
	var spacing := float(spec.vertex_spacing)
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	# Dynamically built assets have no path for Terrain3D to reload on entry.
	terrain.set("free_editor_textures", false)
	terrain.set("region_size", size)
	terrain.set("vertex_spacing", spacing)
	var bake_camera := Camera3D.new()
	root.add_child(bake_camera)
	bake_camera.current = true
	terrain.call("set_camera", bake_camera)
	root.add_child(terrain)
	await process_frame
	# Terrain3D ignores region_size before its data exists in this build.
	terrain.set("region_size", size)
	if int(terrain.get("region_size")) != size:
		push_error("Terrain3D did not accept the requested region size")
		quit(1)
		return
	var data: Object = terrain.get("data")
	if data == null:
		push_error("Terrain3D did not initialize bake data")
		quit(1)
		return
	var regions: Array = spec.region_locations
	var lowest := INF
	var highest := -INF
	for location: Array in regions:
		var origin := Vector3(float(location[0]) * size * spacing, 0, float(location[1]) * size * spacing)
		var heights := Image.create_empty(size, size, false, Image.FORMAT_RF)
		var colors := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
		for z in size:
			for x in size:
				var wx := origin.x + x * spacing
				var wz := origin.z + z * spacing
				var height: float = field.height_at(wx, wz)
				if not is_finite(height):
					push_error("Nonfinite Water terrain sample at %s" % Vector2(wx, wz))
					quit(1)
					return
				lowest = minf(lowest, height)
				highest = maxf(highest, height)
				heights.set_pixel(x, z, Color(height, 0, 0, 1))
				# Neutral modulation; detail comes from installed PBR textures.
				colors.set_pixel(x, z, Color.WHITE)
		var images: Array[Image] = [heights, null, colors]
		data.call("import_images", images, origin, 0.0, 1.0)
		await process_frame
		var imported: float = data.call("get_height", origin)
		if not is_finite(imported) or absf(imported - heights.get_pixel(0, 0).r) > 0.01:
			push_error("Water terrain import failed at %s; stopping before control writes" % origin)
			quit(1)
			return
		for z in size:
			for x in size:
				var position := origin + Vector3(x * spacing, 0, z * spacing)
				var height := heights.get_pixel(x, z).r
				var gradient := Vector2(
					field.height_at(position.x + spacing, position.z) - height,
					field.height_at(position.x, position.z + spacing) - height) / spacing
				var texture_id := 0
				if gradient.length() > float(visual.terrain.rock_gradient):
					texture_id = 2
				elif height < float(visual.terrain.shore_band_height_m):
					texture_id = 1
				data.call("set_control_base_id", position, texture_id)
				data.call("set_control_overlay_id", position, texture_id)
				data.call("set_control_blend", position, 0.0)
				data.call("set_control_auto", position, false)
		print("Water region %s baked" % str(location))
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	data.call("save_directory", OUTPUT)
	var manifest := FileAccess.open(OUTPUT + "/manifest.json", FileAccess.WRITE)
	if manifest == null:
		push_error("Cannot write Water terrain manifest")
		quit(1)
		return
	manifest.store_string(JSON.stringify({"schema_version": 1,
		"config_sha256": source.replace("\r\n", "\n").sha256_text(),
		"visual_sha256": FileAccess.get_file_as_string(VISUAL_CONFIG).replace("\r\n", "\n").sha256_text(),
		"heightfield_sha256": FileAccess.get_file_as_string("res://scripts/world/water_heightfield.gd").replace("\r\n", "\n").sha256_text(),
		"builder_sha256": FileAccess.get_file_as_string("res://scripts/world/build_water_terrain.gd").replace("\r\n", "\n").sha256_text(),
		"region_count": regions.size(), "min_height": lowest, "max_height": highest,
		"_comment": "Bake provenance only; no visual, collision or playability acceptance."}, "\t"))
	manifest.close()
	print("Water bake complete: %d regions, %.2f..%.2fm" % [regions.size(), lowest, highest])
	quit(0)
