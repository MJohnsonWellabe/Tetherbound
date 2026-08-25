extends SceneTree

## WORLD-GRASS research. What Terrain3D 1.0.2 actually exposes, read off the
## live ClassDB rather than off its documentation.
##
##   godot --headless --path . --script tools/_probe_terrain3d_api.gd
##
## Written because the addon ships as a GDExtension BINARY here
## (`addons/terrain_3d/bin/*.so`, no C++ sources vendored), so the usual
## "check it against the real Terrain3D source" this repo does -- see
## `vegetation.gd::_make_mesh_asset`'s own note verifying lod0_range semantics
## against TokisanGames/Terrain3D -- is not available offline. ClassDB is the
## next most authoritative thing: it is what the running engine will actually
## accept, whatever any doc page says.
##
## The specific questions this exists to answer, before anybody proposes
## replacing the baked scatter with a procedural one:
##
##   1. Does `Terrain3DMeshAsset.density` exist, and does the INSTANCER expose
##      a call that populates from it -- i.e. is there a path that does not
##      require us to hand it a transform per blade?
##   2. Does `Terrain3DMaterial` accept a custom shader override, which is what
##      a camera-relative grass carpet or a terrain detail tier would need?
##   3. What else on the instancer is a per-cell/per-region knob rather than a
##      per-instance one?

const CLASSES := [
	"Terrain3D", "Terrain3DMeshAsset", "Terrain3DInstancer", "Terrain3DAssets",
	"Terrain3DMaterial", "Terrain3DTextureAsset", "Terrain3DData", "Terrain3DRegion",
]

## Substrings worth pulling out of the noise, per question above.
const INTERESTING := [
	"density", "instance", "shader", "override", "cell", "region", "lod",
	"fade", "shadow", "visibility", "custom", "uniform", "append", "add_",
	"clear", "swap", "update",
]


func _init() -> void:
	for class_name_str in CLASSES:
		if not ClassDB.class_exists(class_name_str):
			print("MISSING CLASS: %s" % class_name_str)
			continue
		print("")
		print("=== %s (inherits %s) ===" % [
			class_name_str, ClassDB.get_parent_class(class_name_str)])

		print("  -- properties --")
		for entry: Dictionary in ClassDB.class_get_property_list(class_name_str, true):
			var pname := str(entry.get("name", ""))
			if pname == "" or pname.begins_with("_"):
				continue
			print("     %-34s %s" % [pname, type_string(int(entry.get("type", 0)))])

		print("  -- methods --")
		for entry: Dictionary in ClassDB.class_get_method_list(class_name_str, true):
			var mname := str(entry.get("name", ""))
			if mname == "" or mname.begins_with("_"):
				continue
			var args: Array = entry.get("args", [])
			var sig: Array[String] = []
			for a: Dictionary in args:
				sig.append("%s: %s" % [str(a.get("name", "?")),
					type_string(int(a.get("type", 0)))])
			print("     %s(%s)" % [mname, ", ".join(sig)])

	# Question 2, answered directly rather than inferred from the list: can a
	# Terrain3DMaterial be handed a Shader we wrote?
	print("")
	print("=== shader override, checked by construction ===")
	if ClassDB.class_exists("Terrain3DMaterial"):
		var mat: Object = ClassDB.instantiate("Terrain3DMaterial")
		var props: Array[String] = []
		for entry: Dictionary in ClassDB.class_get_property_list("Terrain3DMaterial", true):
			props.append(str(entry.get("name", "")))
		for prop in ["shader_override", "shader_override_enabled", "world_background"]:
			print("  %-28s exists: %s" % [prop, str(prop in props)])
		if mat.has_method("get_shader_code"):
			var code := str(mat.call("get_shader_code"))
			print("  generated shader is %d chars; first uniforms:" % code.length())
			var shown := 0
			for line in code.split("\n"):
				if line.begins_with("uniform") and shown < 20:
					print("     %s" % line.strip_edges())
					shown += 1
	quit(0)
