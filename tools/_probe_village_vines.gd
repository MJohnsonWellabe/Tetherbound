extends SceneTree

## Lists the mesh surfaces near a point with their material and the lights
## that reach them. Written for the Meadows visual pass: round 2 found a vine
## rendering white at night and pale untextured slabs at the quarry. Runs
## headless; no frame is drawn. With no arguments it lists the village vines.
##
##   godot --headless --path . --script tools/_probe_village_vines.gd
##   godot --headless --path . --script tools/_probe_village_vines.gd -- --at=400,1803 --reach=8 --all

const SCENE := "res://scenes/world/meadows_playground.tscn"
var CENTRE := Vector3(3.0, 0.0, 1.0)
var REACH := 60.0
var _all := false


func _init() -> void:
	_run()


func _run() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var xz := a.substr(5).split(",")
			CENTRE = Vector3(float(xz[0]), 0.0, float(xz[1]))
		elif a.begins_with("--reach="):
			REACH = float(a.substr(8))
		elif a == "--all":
			_all = true
	var world: Node3D = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame
	var lights: Array[Light3D] = []
	_collect_lights(world, lights)
	_walk(world, lights)
	quit(0)


func _collect_lights(node: Node, into: Array[Light3D]) -> void:
	if node is OmniLight3D or node is SpotLight3D:
		into.append(node as Light3D)
	for child in node.get_children():
		_collect_lights(child, into)


func _walk(node: Node, lights: Array[Light3D]) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var at := mi.global_position
		if mi.mesh != null and Vector2(at.x - CENTRE.x, at.z - CENTRE.z).length() < REACH:
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				if mat == null or not (_all or "Vine" in mat.resource_name or "Vine" in str(mi.name)):
					continue
				var line := "%s surface %d mesh=%s mat=%s at=%s" % [mi.get_path(), s, mi.mesh.resource_path, mat.resource_name, at]
				if mat is StandardMaterial3D:
					var m := mat as StandardMaterial3D
					line += " albedo=%s tex=%s shading=%d emission=%s/%s energy=%.2f transp=%d cull=%d rough=%.2f metal=%.2f spec=%.2f backlight=%s" % [
						m.albedo_color.to_html(), m.albedo_texture.resource_path if m.albedo_texture else "-",
						m.shading_mode, m.emission_enabled, m.emission.to_html(), m.emission_energy_multiplier,
						m.transparency, m.cull_mode, m.roughness, m.metallic, m.metallic_specular,
						m.backlight_enabled]
				else:
					line += " class=%s" % mat.get_class()
				print(line)
				for light in lights:
					var d := light.global_position.distance_to(at)
					var reach: float = float(light.get("omni_range")) if light is OmniLight3D else float(light.get("spot_range"))
					if d < reach:
						print("    lit by %s d=%.2f range=%.2f energy=%.2f colour=%s visible=%s" % [
							light.get_path(), d, reach, light.light_energy, light.light_color.to_html(), light.is_visible_in_tree()])
	for child in node.get_children():
		_walk(child, lights)
