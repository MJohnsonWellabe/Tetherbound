extends SceneTree

## Fixed same-camera proof of the self-lit installed source beside the production
## craftsperson's retained garment albedo with the exporter-artifact emission off.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const EXPECTED := "res://assets/characters/craftsperson/craftsperson_cloth_clean.png"
const SOURCE_SHA256 := "a260159b4ffab4ded76497e4bd7e85ff5838dc43e1bfa044489e816712578e70"
const SOURCE_PATH := "res://assets/characters/craftsperson/craftsperson_lod0_texture_0.png"

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
	var production: Dictionary = CHARACTER_MODEL.config_for("craftsperson").duplicate(true)
	var baseline := production.duplicate(true)
	baseline.erase("body_albedo_override")
	baseline.erase("body_emission_enabled")
	var source := _build_character(baseline, Vector3(-1.35, 0.0, 0.0), "self-lit source")
	var cleaned := _build_character(production, Vector3(1.35, 0.0, 0.0), "production PBR")
	_check(source != null and cleaned != null, "both body materials resolve")
	if source != null and cleaned != null:
		_check(source != cleaned, "override has a separate cached body material")
		_check(cleaned.albedo_texture != null and cleaned.albedo_texture.resource_path == EXPECTED,
			"production albedo samples the cleanup texture")
		_check(source.albedo_texture != cleaned.albedo_texture, "source and cleanup albedo are isolated")
		_check(source.emission_enabled, "installed source carries full-body emission")
		_check(not cleaned.emission_enabled, "production body disables full-body emission")
		_check(is_equal_approx(source.roughness, cleaned.roughness), "roughness is preserved")
		_check(is_equal_approx(source.metallic, cleaned.metallic), "metallic is preserved")
	_check(FileAccess.get_sha256(ProjectSettings.globalize_path(SOURCE_PATH)) == SOURCE_SHA256,
		"installed source hash matches")
	for frame in 16:
		await process_frame
	var output := "res://shots/character-craftsperson-cleanup/paired-1280x800.png"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var captured := root.get_viewport().get_texture().get_image()
	var error := captured.save_png(ProjectSettings.globalize_path(output))
	print("[craftsperson-cleanup] wrote %s size=%s error=%s checks=%d" % [output, captured.get_size(), error, _checks])
	for failure in _failures:
		push_error("CRAFTSPERSON CLEANUP FAIL: %s" % failure)
	quit(0 if error == OK and _failures.is_empty() else 1)


func _build_character(config: Dictionary, position: Vector3, label_text: String) -> BaseMaterial3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	_world.add_child(model)
	model.position = position
	if not model.call("build_from_config", config):
		_failures.append("could not build %s" % label_text)
		return null
	model.call("play", "idle")
	var material := model.call("body_material") as BaseMaterial3D
	print("[craftsperson-cleanup] %s albedo=%s emission_texture=%s emission=%s energy=%.3f roughness=%.3f metallic=%.3f" % [
		label_text,
		material.albedo_texture.resource_path if material != null and material.albedo_texture != null else "<none>",
		material.emission_texture.resource_path if material != null and material.emission_texture != null else "<none>",
		material.emission_enabled if material != null else false,
		material.emission_energy_multiplier if material != null else -1.0,
		material.roughness if material != null else -1.0,
		material.metallic if material != null else -1.0,
	])
	var label := Label3D.new()
	label.text = label_text
	label.position = Vector3(0.0, 2.25, 0.0)
	label.font_size = 38
	label.outline_size = 8
	label.modulate = Color("f4ead8")
	model.add_child(label)
	return material


func _check(condition: bool, description: String) -> void:
	_checks += 1
	print("[craftsperson-cleanup] %s %s" % ["PASS" if condition else "FAIL", description])
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
	camera.position = Vector3(0.0, 2.4, 6.6)
	camera.fov = 46.0
	_world.add_child(camera)
	camera.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)
	camera.make_current()
