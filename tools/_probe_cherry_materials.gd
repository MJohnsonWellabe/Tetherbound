extends SceneTree

## Headless probe: what are the imported surface material resource_names of
## CherryBlossom_3.gltf, and which retint/retexture key in vegetation.json's
## grove layer does each match?
##
##   godot --headless --path . --script tools/_probe_cherry_materials.gd

func _init() -> void:
	var paths := [
		"res://assets/environment/stylized_nature/CherryBlossom_3.gltf",
		"res://assets/environment/stylized_nature/TwistedTree_2.gltf",
	]
	var cfg_file := FileAccess.open("res://data/config/vegetation.json", FileAccess.READ)
	var cfg: Dictionary = JSON.parse_string(cfg_file.get_as_text())
	var grove: Dictionary = cfg.get("layers", {}).get("grove", {})
	var keys: Array = []
	for k in ["retint", "retexture", "variant_retint"]:
		keys.append("%s=%s" % [k, str(grove.get(k, {}))])
	print("\n".join(keys))
	for path: String in paths:
		var packed: PackedScene = load(path)
		var node: Node = packed.instantiate()
		print("== %s" % path)
		for mi: Node in node.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = (mi as MeshInstance3D).mesh
			print("  MeshInstance %s mesh=%s surfaces=%d" % [mi.name, str(mesh.resource_name), mesh.get_surface_count()])
			for s in mesh.get_surface_count():
				var m: Material = mesh.surface_get_material(s)
				var mi_override: Material = (mi as MeshInstance3D).get_surface_override_material(s)
				var std := m as StandardMaterial3D
				var tex := "" if std == null or std.albedo_texture == null else std.albedo_texture.resource_path
				print("    surface %d: mesh material name='%s' class=%s albedo_tex=%s override=%s" % [
					s, "" if m == null else m.resource_name, "" if m == null else m.get_class(), tex,
					"" if mi_override == null else mi_override.resource_name])
				var matched: Array = []
				for k in ["retint", "retexture"]:
					for key in grove.get(k, {}).keys():
						if m != null and m.resource_name == key:
							matched.append("%s[%s]" % [k, key])
				print("      matches: %s" % (str(matched) if not matched.is_empty() else "NONE"))
		node.free()
	quit(0)
