extends SceneTree

## CREATURES visual lane: bounded attribution fixture for five K-family bodies.
## Builds the production CreatureBody path (therefore the ordinary vivid swap),
## prints the active material facts, and photographs the five bodies together.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const IDS: Array[String] = ["pebbik", "skyrill", "voltarach", "torrentoad", "water_cragclaw"]
const OUT := "res://shots/creatures-surface-probe/current-five.png"

var _world: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_stage()
	for index in IDS.size():
		var body := CREATURE_SCENE.instantiate() as CharacterBody3D
		body.set_script(BODY)
		_world.add_child(body)
		body.call("setup", IDS[index], false)
		body.set_physics_process(false)
		body.position = Vector3((float(index) - 2.0) * 3.8, 0.0, 0.0)
		_print_materials(body, IDS[index])
	for frame in 12:
		await process_frame
	var output := OUT
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(output))
	print("[surface-probe] wrote %s size=%s error=%s" % [output, image.get_size(), error])
	quit(0 if error == OK else 1)


func _build_stage() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("30373b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.76, 0.80)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = env
	_world.add_child(env_node)
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
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 5.0, 17.5)
	camera.fov = 52.0
	_world.add_child(camera)
	camera.look_at(Vector3(0.0, 1.7, 0.0), Vector3.UP)
	camera.make_current()


func _print_materials(node: Node, id: String) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh := instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var material := instance.get_active_material(surface) as BaseMaterial3D
			if material == null:
				continue
			print("[surface-probe] id=%s node=%s surface=%d material=%s albedo=%s emission=%s energy=%.3f roughness=%.3f metallic=%.3f" % [
				id, instance.name, surface, material.resource_name,
				material.albedo_texture.resource_path if material.albedo_texture else "null",
				material.emission_enabled,
				material.emission_energy_multiplier,
				material.roughness,
				material.metallic,
			])
	for child in node.get_children():
		_print_materials(child, id)
