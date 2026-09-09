extends SceneTree

## Character visual lane: same-light, same-camera proof of Arlo's source
## beside the production config's explicit body-only teal-accent texture.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const EXPECTED := "res://assets/characters/trainer/trainer_teal_accent.png"

var _world: Node3D
var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_stage()
	var production: Dictionary = CHARACTER_MODEL.config_for("trainer").duplicate(true)
	var baseline := production.duplicate(true)
	baseline.erase("body_albedo_override")
	var source_material := _build_character(
		baseline, Vector3(-1.2, 0.0, 0.0), "source")
	var accent_material := _build_character(
		production, Vector3(1.2, 0.0, 0.0), "teal accent")
	_check(source_material != null and accent_material != null, "both body materials resolve")
	if source_material != null and accent_material != null:
		_check(source_material != accent_material, "body override has a separate cached material")
		_check(accent_material.albedo_texture != null \
			and accent_material.albedo_texture.resource_path == EXPECTED,
			"production body samples the declared external texture")
		_check(source_material.albedo_texture != accent_material.albedo_texture,
			"source and override do not share an albedo texture")
		_check(is_equal_approx(source_material.metallic, accent_material.metallic),
			"metallic finish is preserved")
		_check(is_equal_approx(source_material.roughness, accent_material.roughness),
			"roughness finish is preserved")
		_check(source_material.emission_enabled == accent_material.emission_enabled,
			"emission state is preserved")
	if "--validate-only" in OS.get_cmdline_user_args():
		print("CHARACTER_ACCENT checks=%d failures=%s" % [_checks, _failures])
		_world.free()
		quit(0 if _failures.is_empty() else 1)
		return
	for frame in 16:
		await process_frame
	var output := "res://shots/character-teal-accent/paired.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(output))
	print("[character-accent] wrote %s size=%s error=%s" % [output, image.get_size(), error])
	if not _failures.is_empty():
		for failure in _failures:
			push_error("CHARACTER ACCENT FAIL: %s" % failure)
	quit(0 if error == OK and _failures.is_empty() else 1)


func _build_character(config: Dictionary, position: Vector3,
		label_text: String) -> BaseMaterial3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	_world.add_child(model)
	model.position = position
	if not model.call("build_from_config", config):
		_failures.append("could not build %s" % label_text)
		return null
	model.call("play", "idle")
	var material := model.call("body_material") as BaseMaterial3D
	print("[character-accent] %s albedo=%s emission=%s roughness=%.3f metallic=%.3f" % [
		label_text,
		material.albedo_texture.resource_path if material != null and material.albedo_texture != null else "<embedded>",
		material.emission_enabled if material != null else false,
		material.roughness if material != null else -1.0,
		material.metallic if material != null else -1.0,
	])
	var label := Label3D.new()
	label.text = label_text
	label.position = Vector3(0.0, 2.2, 0.0)
	label.font_size = 42
	label.outline_size = 8
	label.modulate = Color("f4ead8")
	model.add_child(label)
	return material


func _check(condition: bool, description: String) -> void:
	_checks += 1
	print("[character-accent] %s %s" % ["PASS" if condition else "FAIL", description])
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
	plane.size = Vector2(9.0, 7.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("8a6338")
	floor.material_override = floor_material
	_world.add_child(floor)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.4, 6.4)
	camera.fov = 46.0
	_world.add_child(camera)
	camera.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)
	camera.make_current()
