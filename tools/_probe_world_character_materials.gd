extends SceneTree

## GF-B-010, the in-world half. `tools/_probe_npc_materials.gd` reads the rigs
## as `character_model.gd` builds them from `art.json`; this boots the REAL
## world scene and reads what is actually standing in it, because the band-2
## frame shows a lit player and a jet-black NPC in the same shot, under the same
## sun, and a config-level dump cannot tell those two apart.
##
##   xvfb-run -a -s "-screen 0 320x200x24" godot --path . \
##     --rendering-driver opengl3 --resolution 320x200 \
##     --script tools/_probe_world_character_materials.gd
##
## Reports, for every character-shaped node in the live tree: which script built
## it, where it is, and the metallic/albedo/emission of every surface it draws —
## plus the Environment the whole scene is lit by, since a metal's only response
## is specular and specular in this renderer comes from the sky.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE := 180


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		print("FAIL: could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE:
		await process_frame

	_report_environment(world)
	print("\n--- characters in the live tree ---")
	var seen := 0
	seen = _walk(world, seen)
	print("\n%d character-shaped nodes reported" % seen)
	quit(0)


func _report_environment(world: Node) -> void:
	var env: Environment = null
	var node := _find_first(world, "WorldEnvironment")
	if node is WorldEnvironment:
		env = (node as WorldEnvironment).environment
	if env == null:
		print("environment: NONE FOUND")
		return
	print("environment: bg_mode=%d sky=%s ambient_source=%d sky_contribution=%.2f ambient_energy=%.2f ambient_colour=%s reflected_source=%d" % [
		env.background_mode, str(env.sky != null), env.ambient_light_source,
		env.ambient_light_sky_contribution, env.ambient_light_energy,
		env.ambient_light_color, env.reflected_light_source])
	var sun := _find_first(world, "Sun")
	if sun is DirectionalLight3D:
		var d := sun as DirectionalLight3D
		print("sun: rotation_deg=%s energy=%.2f colour=%s direction=%s" % [
			d.rotation_degrees, d.light_energy, d.light_color,
			-d.global_transform.basis.z])


func _find_first(node: Node, cls: String) -> Node:
	if node.get_class() == cls or node.name == cls:
		return node
	for child in node.get_children():
		var found := _find_first(child, cls)
		if found != null:
			return found
	return null


## A "character-shaped" node is one whose script is `character_model.gd` or a
## subclass of it -- the one door every humanoid in this project goes through.
func _walk(node: Node, seen: int) -> int:
	var script: Variant = node.get_script()
	if script != null and node.has_method("body_material") and node is Node3D:
		seen += 1
		var n3 := node as Node3D
		print("\n[%d] %s  script=%s" % [seen, node.name, str((script as Script).resource_path)])
		print("     global_position=%s  parent=%s" % [n3.global_position, node.get_parent().name])
		_surfaces(node, "")
	for child in node.get_children():
		seen = _walk(child, seen)
	return seen


func _surfaces(node: Node, path: String) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var m: Material = mi.get_active_material(s)
				if m is BaseMaterial3D:
					var b := m as BaseMaterial3D
					print("     %s/%s[%d] metallic=%.2f metallic_tex=%s roughness=%.2f albedo=%s emission=%s/%s visible=%s" % [
						path, mi.name, s, b.metallic,
						("none" if b.metallic_texture == null else "yes"),
						b.roughness, b.albedo_color, b.emission_enabled, b.emission,
						mi.is_visible_in_tree()])
				elif m == null:
					print("     %s/%s[%d] NO MATERIAL" % [path, mi.name, s])
	for child in node.get_children():
		_surfaces(child, "%s/%s" % [path, node.name])
