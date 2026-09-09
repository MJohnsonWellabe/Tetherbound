extends SceneTree

## Diagnostic-only character fixture. The left body uses the ordinary production
## craftsperson config. The right body replaces only its duplicated surface texture
## with a false-colour source-atlas mask so the measured green selector can be
## attributed to 3D garments before any production repaint is proposed.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const SOURCE_PATH := "res://assets/characters/craftsperson/craftsperson_lod0_texture_0.png"
const SOURCE_SHA256 := "a260159b4ffab4ded76497e4bd7e85ff5838dc43e1bfa044489e816712578e70"
const MASK_PATH := "res://.artifacts/craftsperson-attribution-0909/atlas-false-color.png"
const MASK_SHA256 := "cf5dfec3fedb567ecd3ab4b2f50cf82ecfa6cbfba0e0e6a4ec00a4fcdb61a7b4"

var _world: Node3D
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_stage()
	var config := CHARACTER_MODEL.config_for("craftsperson")
	var source_body := _build_character(config, Vector3(-1.45, 0.0, 0.0), "production source")
	var mask_body := _build_character(config, Vector3(1.45, 0.0, 0.0), "false-colour regions")
	var source_material := source_body.call("body_material") as BaseMaterial3D \
		if source_body != null else null
	var image := Image.load_from_file(ProjectSettings.globalize_path(MASK_PATH))
	var mask_texture := ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null
	var mask_material := _apply_mask_material(mask_body, mask_texture)
	_check(source_material != null, "production body material resolves")
	_check(mask_material != null and mask_texture != null, "false-colour diagnostic material resolves")
	if source_material != null:
		print("[craftsperson-mask] production albedo=%s emission=%s energy=%.3f roughness=%.3f metallic=%.3f" % [
			source_material.albedo_texture.resource_path if source_material.albedo_texture else "<embedded>",
			source_material.emission_enabled,
			source_material.emission_energy_multiplier,
			source_material.roughness,
			source_material.metallic,
		])
		_check(source_material.albedo_texture != null \
			and source_material.albedo_texture.resource_path == SOURCE_PATH,
			"runtime reports the audited companion path")
	if source_material != null and mask_material != null:
		_check(source_material != mask_material, "diagnostic material is isolated")
		_check(is_equal_approx(source_material.roughness, mask_material.roughness),
			"roughness is copied")
		_check(is_equal_approx(source_material.metallic, mask_material.metallic),
			"metallic is copied")
		_check(source_material.emission_enabled == mask_material.emission_enabled,
			"emission state is copied")
	_check(FileAccess.get_sha256(ProjectSettings.globalize_path(SOURCE_PATH)) == SOURCE_SHA256,
		"installed source hash matches")
	_check(FileAccess.get_sha256(ProjectSettings.globalize_path(MASK_PATH)) == MASK_SHA256,
		"false-colour mask hash matches")
	for frame in 16:
		await process_frame
	var output := "res://shots/character-craftsperson-attribution/mask-fixture-1280x800.png"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var captured := root.get_viewport().get_texture().get_image()
	var error := captured.save_png(ProjectSettings.globalize_path(output))
	print("[craftsperson-mask] wrote %s size=%s error=%s" % [output, captured.get_size(), error])
	for failure in _failures:
		push_error("CRAFTSPERSON MASK FAIL: %s" % failure)
	quit(0 if error == OK and _failures.is_empty() else 1)


func _build_character(config: Dictionary, position: Vector3, label_text: String) -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	_world.add_child(model)
	model.position = position
	if not model.call("build_from_config", config):
		_failures.append("could not build %s" % label_text)
		return null
	model.call("play", "idle")
	var label := Label3D.new()
	label.text = label_text
	label.position = Vector3(0.0, 2.25, 0.0)
	label.font_size = 36
	label.outline_size = 8
	label.modulate = Color("f4ead8")
	model.add_child(label)
	return model


func _apply_mask_material(node: Node, texture: Texture2D) -> BaseMaterial3D:
	var first: BaseMaterial3D = null
	if node is MeshInstance3D and texture != null:
		var instance := node as MeshInstance3D
		for surface in (instance.mesh.get_surface_count() if instance.mesh != null else 0):
			var source := instance.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as BaseMaterial3D
			material.albedo_texture = texture
			if material.emission_enabled and material.emission_texture != null:
				material.emission_texture = texture
			instance.set_surface_override_material(surface, material)
			if first == null:
				first = material
	for child in node.get_children():
		var child_material := _apply_mask_material(child, texture)
		if first == null and child_material != null:
			first = child_material
	return first


func _check(condition: bool, description: String) -> void:
	print("[craftsperson-mask] %s %s" % ["PASS" if condition else "FAIL", description])
	if not condition:
		_failures.append(description)


func _build_stage() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("263137")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.68, 0.73, 0.76)
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment_node.environment = environment
	_world.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-32.0), 0.0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	_world.add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10.0, 7.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("8a6338")
	floor.material_override = floor_material
	_world.add_child(floor)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.4, 6.8)
	camera.fov = 46.0
	_world.add_child(camera)
	camera.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)
	camera.make_current()
