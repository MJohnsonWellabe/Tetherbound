extends SceneTree

## Sequential A/B renderer for the bounded creature mipmap experiment.
## A preserves each active production image's current mip chain. B uses the
## same decoded pixels and material but generates a mip chain when absent.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const OUTPUT := "res://.artifacts/creature-mipmap-camera-fit-0909/captures"
const SIZE := Vector2i(1280, 800)
const TARGET_BODY_HEIGHT_PX := 180.0
const SUBPIXEL_OFFSETS: Array[float] = [0.0, 0.25, 0.5, 0.75]
const BODY_GUARD := Rect2(0.04, 0.04, 0.92, 0.92)

# Face regions are preregistered fractions of each measured projected body
# rectangle. They are deliberately broad anatomy guards, not claimed masks.
const COHORT: Array[Dictionary] = [
	{"id":"skyrill", "face":[0.25,0.05,0.50,0.34]},
	{"id":"pebbik", "face":[0.22,0.10,0.56,0.38]},
	{"id":"galecrest", "face":[0.27,0.04,0.46,0.30]},
	{"id":"aeriex", "face":[0.24,0.05,0.52,0.34]},
	{"id":"cloudfang", "face":[0.20,0.08,0.60,0.38]},
	{"id":"sparkit", "face":[0.22,0.08,0.56,0.36]},
	{"id":"tanglevolt", "face":[0.23,0.08,0.54,0.37]},
	{"id":"voltwig", "face":[0.24,0.06,0.52,0.34]},
	{"id":"voltarach", "face":[0.24,0.24,0.52,0.34]},
	{"id":"mosshock", "face":[0.20,0.08,0.60,0.38]},
	{"id":"staticub", "face":[0.20,0.08,0.60,0.38]},
	{"id":"stormraven", "face":[0.26,0.05,0.48,0.32]},
	{"id":"water_mangrove_monitor", "face":[0.24,0.08,0.52,0.34]},
	{"id":"water_torrentoad", "face":[0.17,0.07,0.66,0.43]},
	{"id":"water_mirejaw", "face":[0.20,0.09,0.60,0.40]},
	{"id":"water_mosshell", "face":[0.18,0.30,0.64,0.35]},
	{"id":"water_riverdrake", "face":[0.23,0.07,0.54,0.35]},
	{"id":"water_cragclaw", "face":[0.20,0.12,0.60,0.40]},
	{"id":"water_sirenseal", "face":[0.20,0.06,0.60,0.38]},
	{"id":"water_riptusk", "face":[0.17,0.08,0.66,0.40]},
]
const FIXED_FIVE: Array[String] = ["pebbik", "skyrill", "voltarach", "water_torrentoad", "water_cragclaw"]

var _world: Node3D
var _camera: Camera3D
var _viewport: SubViewport
var _manifest: Dictionary = {"complete":false, "records":[], "failures":[]}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_build_stage()
	if _viewport.get_visible_rect().size != Vector2(SIZE):
		_manifest.failures.append("capture viewport must be exactly %s; got %s" % [SIZE, _viewport.get_visible_rect().size])
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _capture_fixed_five()
	for entry: Dictionary in COHORT:
		await _capture_species(str(entry.id), entry.face)
	var manifest_path := ProjectSettings.globalize_path(OUTPUT.path_join("manifest.json"))
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		_manifest.failures.append("cannot write manifest")
	else:
		_manifest.complete = (_manifest.failures as Array).is_empty()
		file.store_string(JSON.stringify(_manifest, "  ") + "\n")
	_viewport.queue_free()
	await process_frame
	await process_frame
	print("CREATURE_MIPMAP_EXPERIMENT=%s" % JSON.stringify({"complete":_manifest.complete, "records":(_manifest.records as Array).size(), "failures":_manifest.failures}))
	quit(0 if _manifest.complete else 1)


func _build_stage() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "CreatureMipmapCaptureViewport"
	_viewport.size = SIZE
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("30373b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.80)
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment_node.environment = environment
	_world.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-38.0), deg_to_rad(-28.0), 0.0)
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	_world.add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30.0, 12.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("657069")
	floor.material_override = floor_material
	_world.add_child(floor)
	_camera = Camera3D.new()
	_camera.fov = 52.0
	_world.add_child(_camera)
	_camera.make_current()


func _capture_fixed_five() -> void:
	var bodies: Array[CharacterBody3D] = []
	var materials: Array[Dictionary] = []
	for index: int in FIXED_FIVE.size():
		var body := CREATURE_SCENE.instantiate() as CharacterBody3D
		if body == null:
			_manifest.failures.append("fixed-five %s did not instantiate" % FIXED_FIVE[index])
			continue
		body.set_script(BODY)
		_world.add_child(body)
		body.set_physics_process(false)
		body.call("setup", FIXED_FIVE[index], false)
		body.position = Vector3((float(index) - 2.0) * 3.8, 0.0, 0.0)
		_freeze_animation(body)
		bodies.append(body)
		materials.append_array(_active_material_records(body))
	_camera.position = Vector3(0.0, 5.0, 17.5)
	_camera.look_at(Vector3(0.0, 1.7, 0.0), Vector3.UP)
	await process_frame
	for branch: String in ["A", "B"]:
		var signatures := _apply_branch(materials, branch)
		if signatures.size() != materials.size():
			_manifest.failures.append("fixed-five branch %s treatment validation failed before capture" % branch)
			break
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var filename := "fixed-five__%s.png" % branch
		var error := _save_capture(filename)
		var body_rects: Dictionary = {}
		for index: int in bodies.size():
			body_rects[FIXED_FIVE[index]] = _rect_array(_projected_rect(bodies[index]))
		_manifest.records.append({"kind":"fixed_five", "ids":FIXED_FIVE,
			"branch":branch, "file":filename, "body_rects":body_rects,
			"active_materials":signatures, "save_error":error})
		if error != OK:
			_manifest.failures.append("%s save error %s" % [filename, error])
	for body: CharacterBody3D in bodies:
		body.queue_free()
	await process_frame
	await process_frame


func _capture_species(id: String, face_values: Array) -> void:
	var body := CREATURE_SCENE.instantiate() as CharacterBody3D
	if body == null:
		_manifest.failures.append("%s did not instantiate" % id)
		return
	body.set_script(BODY)
	_world.add_child(body)
	body.set_physics_process(false)
	body.call("setup", id, false)
	_freeze_animation(body)
	var bounds := _visual_bounds(body)
	if bounds.size.length_squared() <= 0.0001:
		_manifest.failures.append("%s has no finite visual bounds" % id)
		body.queue_free()
		await process_frame
		return
	var center := bounds.get_center()
	var half_height := maxf(bounds.size.y * 0.5, 0.01)
	var vfov := deg_to_rad(_camera.fov)
	var target_fraction := TARGET_BODY_HEIGHT_PX / float(SIZE.y)
	var distance := half_height / (tan(vfov * 0.5) * target_fraction)
	var minimum_distance := bounds.size.z * 0.5 + _camera.near + 0.05
	distance = maxf(distance, minimum_distance)
	var hfov := 2.0 * atan(tan(vfov * 0.5) * float(SIZE.x) / float(SIZE.y))
	distance = _fit_camera_distance(body, center, distance, minimum_distance)
	await process_frame
	var source_materials := _active_material_records(body)
	if source_materials.is_empty():
		_manifest.failures.append("%s has no active albedo material" % id)
	else:
		for branch: String in ["A", "B"]:
			var signatures := _apply_branch(source_materials, branch)
			if signatures.size() != source_materials.size():
				_manifest.failures.append("%s branch %s treatment validation failed before capture" % [id, branch])
				break
			for offset: float in SUBPIXEL_OFFSETS:
				var pixel_world := 2.0 * distance * tan(hfov * 0.5) / float(SIZE.x)
				_camera.position.x = center.x + offset * pixel_world
				_camera.look_at(center + Vector3(offset * pixel_world, 0.0, 0.0), Vector3.UP)
				await process_frame
				await process_frame
				await RenderingServer.frame_post_draw
				var body_rect := _projected_rect(body)
				var face_rect := _fractional_rect(body_rect, face_values)
				var filename := "%s__%s__subpixel_%02d.png" % [id, branch, int(round(offset * 100.0))]
				var error := _save_capture(filename)
				_manifest.records.append({"kind":"isolated", "id":id, "branch":branch, "subpixel":offset, "file":filename, "body_rect":_rect_array(body_rect), "face_rect":_rect_array(face_rect), "active_materials":signatures, "save_error":error})
				if absf(body_rect.size.y - TARGET_BODY_HEIGHT_PX) > 40.0:
					_manifest.failures.append("%s projected height %.2f outside target tolerance" % [filename, body_rect.size.y])
				var guard_px := Rect2(BODY_GUARD.position * Vector2(SIZE), BODY_GUARD.size * Vector2(SIZE))
				if not guard_px.encloses(body_rect):
					_manifest.failures.append("%s body bounds %s exceed preregistered guard" % [filename, body_rect])
				if error != OK:
					_manifest.failures.append("%s save error %s" % [filename, error])
	body.queue_free()
	await process_frame
	await process_frame


func _save_capture(filename: String) -> Error:
	var image := _viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_manifest.failures.append("%s capture returned no image" % filename)
		return ERR_CANT_ACQUIRE_RESOURCE
	if image.get_size() != SIZE:
		_manifest.failures.append("%s capture must be exactly %s; got %s" % [filename, SIZE, image.get_size()])
		return ERR_INVALID_DATA
	return image.save_png(ProjectSettings.globalize_path(OUTPUT.path_join(filename)))


func _fit_camera_distance(body: Node3D, center: Vector3, initial_distance: float, minimum_distance: float) -> float:
	var low := initial_distance
	var high := initial_distance
	_set_camera_distance(center, initial_distance)
	var initial_height := _projected_rect(body).size.y
	if initial_height > TARGET_BODY_HEIGHT_PX:
		for iteration: int in 24:
			high *= 2.0
			_set_camera_distance(center, high)
			if _projected_rect(body).size.y <= TARGET_BODY_HEIGHT_PX:
				break
	else:
		for iteration: int in 24:
			low = maxf(minimum_distance, low * 0.5)
			_set_camera_distance(center, low)
			if _projected_rect(body).size.y >= TARGET_BODY_HEIGHT_PX or is_equal_approx(low, minimum_distance):
				break
	for iteration: int in 24:
		var midpoint := (low + high) * 0.5
		_set_camera_distance(center, midpoint)
		if _projected_rect(body).size.y > TARGET_BODY_HEIGHT_PX:
			low = midpoint
		else:
			high = midpoint
	var fitted_distance := (low + high) * 0.5
	_set_camera_distance(center, fitted_distance)
	return fitted_distance


func _set_camera_distance(center: Vector3, distance: float) -> void:
	_camera.position = Vector3(center.x, center.y, center.z + distance)
	_camera.look_at(center, Vector3.UP)


func _active_material_records(body: Node) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	_collect_active_materials(body, records)
	return records


func _collect_active_materials(node: Node, records: Array[Dictionary]) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		for surface: int in (instance.mesh.get_surface_count() if instance.mesh != null else 0):
			var material := instance.get_active_material(surface) as BaseMaterial3D
			if material != null and material.albedo_texture != null:
				records.append({"instance":instance, "surface":surface, "source":material,
					"texture":material.albedo_texture,
					"uses_instance_override":instance.material_override != null})
	for child: Node in node.get_children():
		_collect_active_materials(child, records)


func _apply_branch(records: Array[Dictionary], branch: String) -> Array[Dictionary]:
	var signatures: Array[Dictionary] = []
	for record: Dictionary in records:
		var source := record.source as BaseMaterial3D
		var source_texture := record.texture as Texture2D
		var image := source_texture.get_image()
		if image == null or image.is_empty():
			_manifest.failures.append("%s unavailable image" % source_texture.resource_path)
			continue
		var branch_image := image.duplicate()
		if branch_image.is_compressed():
			var decompress_error: Error = branch_image.decompress()
			if decompress_error != OK:
				_manifest.failures.append("%s branch %s decompression failed: %s" % [source_texture.resource_path, branch, decompress_error])
				continue
		if branch == "B" and branch_image.get_mipmap_count() == 0:
			branch_image.generate_mipmaps()
		if branch == "B" and image.get_mipmap_count() == 0 and branch_image.get_mipmap_count() == 0:
			_manifest.failures.append("%s branch B did not generate a mip chain" % source_texture.resource_path)
			continue
		var branch_texture := ImageTexture.create_from_image(branch_image)
		var material := source.duplicate() as BaseMaterial3D
		material.albedo_texture = branch_texture
		var instance := record.instance as MeshInstance3D
		if bool(record.get("uses_instance_override", false)):
			instance.material_override = material
		else:
			instance.set_surface_override_material(int(record.surface), material)
		var effective := instance.get_active_material(int(record.surface)) as BaseMaterial3D
		var effective_texture := effective.albedo_texture if effective != null else null
		if effective_texture != branch_texture:
			_manifest.failures.append("%s branch %s did not become the effective active texture" % [source_texture.resource_path, branch])
			continue
		if effective.texture_filter != source.texture_filter:
			_manifest.failures.append("%s branch %s changed texture filter" % [source_texture.resource_path, branch])
			continue
		signatures.append({
			"source_path": source_texture.resource_path,
			"source_mips": image.get_mipmap_count(),
			"branch_mips": branch_image.get_mipmap_count(),
			"texture_filter": int(effective.texture_filter) if effective != null else -1,
			"normal_path": effective.normal_texture.resource_path if effective != null and effective.normal_texture != null else "",
			"emission_enabled": effective.emission_enabled if effective != null else false,
			"emission_energy": effective.emission_energy_multiplier if effective != null else 0.0,
			"roughness": effective.roughness if effective != null else 0.0,
			"metallic": effective.metallic if effective != null else 0.0,
		})
	return signatures


func _freeze_animation(node: Node) -> void:
	if node is AnimationPlayer:
		(node as AnimationPlayer).pause()
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	if node is AnimationTree:
		(node as AnimationTree).active = false
	for child: Node in node.get_children():
		_freeze_animation(child)


func _visual_bounds(body: Node3D) -> AABB:
	var found := false
	var result := AABB()
	for child: Node in body.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		if instance.mesh == null:
			continue
		var local := body.global_transform.affine_inverse() * instance.global_transform
		var transformed := local * instance.get_aabb()
		result = transformed if not found else result.merge(transformed)
		found = true
	return result if found else AABB()


func _projected_rect(body: Node3D) -> Rect2:
	var bounds := _visual_bounds(body)
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for x: int in 2:
		for y: int in 2:
			for z: int in 2:
				var local := bounds.position + Vector3(bounds.size.x * x, bounds.size.y * y, bounds.size.z * z)
				var screen := _camera.unproject_position(body.to_global(local))
				minimum = minimum.min(screen)
				maximum = maximum.max(screen)
	return Rect2(minimum, maximum - minimum)


func _fractional_rect(body_rect: Rect2, values: Array) -> Rect2:
	return Rect2(body_rect.position + body_rect.size * Vector2(float(values[0]), float(values[1])), body_rect.size * Vector2(float(values[2]), float(values[3])))


func _rect_array(rect: Rect2) -> Array[float]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
