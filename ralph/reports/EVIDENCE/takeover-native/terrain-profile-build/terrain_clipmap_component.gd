extends SceneTree
## Isolated native component diagnostic. Actual committed Meadows terrain;
## fixture camera/light/grey material. No gameplay, art score or performance claim.
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var output := ""

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		print("TERRAIN_COMPONENT_FAIL " + message)

func _settle(count: int) -> void:
	for frame in count: await physics_frame
	await RenderingServer.frame_post_draw

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	if output.is_empty() or not output.is_absolute_path():
		print("TERRAIN_COMPONENT_FAIL absolute isolated --out is required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	_check(ClassDB.class_exists("Terrain3D"), "Terrain3D class must load")
	var version := Engine.get_version_info()
	_check(int(version.major) == 4 and int(version.minor) == 7, "locked Godot 4.7 required")
	if not failures.is_empty():
		quit(1)
		return
	set_physics_interpolation_enabled(true)
	_check(is_physics_interpolation_enabled(), "physics interpolation must be enabled for this component fixture")
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(.01, .03, .06)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = .7
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	world.add_child(sun)
	sun.rotation_degrees = Vector3(-60, -30, 0)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.far = 2400.0
	camera.make_current()
	var terrain: Node3D = ClassDB.instantiate("Terrain3D") as Node3D
	terrain.set("region_size", int(config.region_size))
	terrain.set("vertex_spacing", float(config.vertex_spacing))
	terrain.set("debug_level", 3)
	world.add_child(terrain)
	terrain.set("data_directory", "res://data/terrain/playground")
	terrain.call("set_camera", camera)
	await _settle(8)
	var data: Object = terrain.get("data")
	var material: Object = terrain.get("material")
	material.set("world_background", 0)
	material.set("show_grey", true)
	_check(int(data.call("get_region_count")) > 0, "actual committed regions must be resident")
	var initial_lods := int(terrain.get("mesh_lods"))
	_check(initial_lods >= 2, "multiple clipmap LODs required")
	var positions: Array[Vector2] = [Vector2(96.2, 14), Vector2(112.2, 14), Vector2(344.3, 926.6), Vector2(96.2, 14)]
	for index in positions.size():
		var xz := positions[index]
		var height: float = data.call("get_height", Vector3(xz.x, 0, xz.y))
		_check(is_finite(height), "camera %d must sample native baked height" % index)
		if not is_finite(height): continue
		print("TERRAIN_COMPONENT_CAMERA_BEGIN %d" % index)
		camera.global_position = Vector3(xz.x, height + 12, xz.y)
		camera.look_at(Vector3(xz.x, height, xz.y + 24))
		await _settle(12)
		var snapped: Vector3 = terrain.call("get_snapped_position")
		var spacing := float(terrain.get("vertex_spacing"))
		var expected := (camera.global_position / spacing).floor() * spacing
		_check(snapped.is_equal_approx(expected), "camera %d native snapped position mismatch" % index)
		_check(terrain.call("get_camera") == camera, "native tracking camera must remain the fixture camera")
		_check(int(terrain.get("mesh_lods")) == initial_lods, "camera movement must preserve LOD count")
		var visible := root.get_texture().get_image()
		_check(not visible.is_empty(), "camera %d visible framebuffer required" % index)
		terrain.visible = false
		await _settle(3)
		var hidden := root.get_texture().get_image()
		terrain.visible = true
		await _settle(3)
		if visible.is_empty() or hidden.is_empty(): continue
		var changed := 0
		var samples := 0
		var minimum := 1.0
		var maximum := 0.0
		for y in range(0, visible.get_height(), 8):
			for x in range(0, visible.get_width(), 8):
				var a := visible.get_pixel(x, y)
				var b := hidden.get_pixel(x, y)
				if Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() > .05: changed += 1
				var luminance := .2126 * a.r + .7152 * a.g + .0722 * a.b
				minimum = minf(minimum, luminance)
				maximum = maxf(maximum, luminance)
				samples += 1
		_check(float(changed) / samples > .10, "camera %d terrain visibility must alter >10 percent of sampled pixels" % index)
		_check(maximum > .08 and maximum - minimum > .05, "camera %d terrain framebuffer must be nonblank" % index)
		_check(visible.save_png(output.path_join("camera-%d-visible.png" % index)) == OK, "visible PNG save failed")
		_check(hidden.save_png(output.path_join("camera-%d-hidden.png" % index)) == OK, "hidden PNG save failed")
		var row := {"index": index, "camera": [camera.position.x, camera.position.y, camera.position.z], "snapped": [snapped.x, snapped.y, snapped.z], "mesh_lods": initial_lods, "mesh_size": terrain.get("mesh_size"), "regions": data.call("get_region_count"), "physics_interpolation": is_physics_interpolation_enabled(), "visible_changed_fraction": float(changed) / samples, "luminance_range": [minimum, maximum], "viewport": [visible.get_width(), visible.get_height()]}
		observations.append(row)
		print("TERRAIN_COMPONENT_OBSERVED " + JSON.stringify(row))
	# EXTREME was only for the bounded snap observations. Native logger notes
	# warn about debug printing during teardown; ERROR mode still emits warnings/errors.
	terrain.set("debug_level", 0)
	data = null
	material = null
	world.queue_free()
	await _settle(3)
	_check(observations.size() == 4, "all four camera observations required")
	var file := FileAccess.open(output.path_join("component.json"), FileAccess.WRITE)
	_check(file != null, "component report open failed")
	var report := {"failures": failures, "observations": observations, "acceptance": false, "scope": "native component visibility and camera/clipmap state; inspect LOD snap logs and PNGs independently"}
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.flush()
		_check(file.get_error() == OK, "component report write failed")
		report["failures"] = failures
	print("TERRAIN_COMPONENT_RESULT " + JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
