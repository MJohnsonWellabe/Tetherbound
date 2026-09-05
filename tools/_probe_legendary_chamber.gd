extends SceneTree
## N05-WORLD-DRESSING-0905. Headless inventory of everything drawn inside the
## Legendary Chamber, so the "cyan light-bars" and the "overlapping wall slabs
## with a black gap" three blind judges named (W06-FINALE-0904 rounds 1-3) can
## be attributed to the node that draws them instead of guessed at from a frame.
##
##   godot --headless --path . --script tools/_probe_legendary_chamber.gd
##
## Prints every VisualInstance3D whose global AABB centre lies within the
## chamber's footprint (plus a 2 m apron), with its scene path, size, position
## and -- for a StandardMaterial3D -- albedo and emission, then every Light3D
## within 40 m of the chamber centre.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 60


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var hold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	if hold == null:
		push_error("no Stronghold node")
		quit(1)
		return
	var centre: Vector3 = hold.call("marker", "legendary_chamber")
	var size: Vector3 = hold.call("chamber_size", "legendary_chamber")
	var half := Vector2(size.x, size.y) * 0.5 + Vector2(2.0, 2.0)
	print("[probe] legendary_chamber centre %s size %s" % [str(centre), str(size)])
	print("[probe] markers: %s" % str(hold.call("marker_names")))
	var visuals: Array[String] = []
	for node in root.find_children("*", "VisualInstance3D", true, false):
		var v := node as VisualInstance3D
		if not v.is_inside_tree():
			continue
		var box := v.global_transform * v.get_aabb()
		var c := box.get_center()
		if absf(c.x - centre.x) > half.x or absf(c.z - centre.z) > half.y:
			continue
		var line := "%s | pos %s | aabb size %s | y[%.2f..%.2f]" % [
			str(v.get_path()).replace("/root/", ""), _v(v.global_position), _v(box.size),
			box.position.y, box.end.y]
		var mi := v as MeshInstance3D
		if mi != null:
			var mat: Material = mi.material_override
			if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
				mat = mi.get_surface_override_material(0)
				if mat == null:
					mat = mi.mesh.surface_get_material(0)
			line += " | " + _mat(mat)
			line += " | rot %s" % _v(v.rotation_degrees)
		visuals.append(line)
	visuals.sort()
	print("[probe] %d visuals inside the chamber footprint:" % visuals.size())
	for line in visuals:
		print("  " + line)
	print("[probe] lights within 40 m:")
	for node in root.find_children("*", "Light3D", true, false):
		var l := node as Light3D
		if not l.is_inside_tree() or l.global_position.distance_to(centre) > 40.0:
			continue
		var extra := ""
		if l is OmniLight3D:
			extra = "omni range %.1f att %.2f" % [(l as OmniLight3D).omni_range, (l as OmniLight3D).omni_attenuation]
		elif l is SpotLight3D:
			extra = "spot range %.1f angle %.1f" % [(l as SpotLight3D).spot_range, (l as SpotLight3D).spot_angle]
		print("  %s | pos %s | colour %s | energy %.2f | shadow %s | %s" % [
			str(l.get_path()).replace("/root/", ""), _v(l.global_position), l.light_color.to_html(false),
			l.light_energy, str(l.shadow_enabled), extra])
	quit(0)


func _v(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]


func _mat(mat: Material) -> String:
	if mat == null:
		return "mat none"
	var sm := mat as StandardMaterial3D
	if sm == null:
		return "mat %s" % mat.get_class()
	var s := "albedo %s" % sm.albedo_color.to_html(false)
	if sm.emission_enabled:
		s += " EMISSION %s x%.2f" % [sm.emission.to_html(false), sm.emission_energy_multiplier]
	if sm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		s += " UNSHADED"
	return s
