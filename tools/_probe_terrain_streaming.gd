extends SceneTree

## OW5A. What the vendored Terrain3D 1.0.2 actually exposes for streaming, as
## opposed to what `scripts/world/vegetation.gd`'s header claims it does.
##
##   godot --headless --path . --script tools/_probe_terrain_streaming.gd
##
## Two questions the corridor footprint depends on and nobody had checked:
##   * is `Terrain3DInstancer` a real, script-reachable class on THIS build,
##     with methods that can add instances from GDScript at runtime?
##   * what collision knobs exist besides `collision_mode` — specifically, is
##     there a dynamic-collision radius that can be set large enough that a
##     sprinting player (8.6 m/s) cannot outrun it?
##
## Asks ClassDB rather than trusting the addon's own docs: the GDExtension is a
## compiled binary and the .gd files in `src/` are the editor plugin, not the
## runtime API.

func _init() -> void:
	for cls: String in [
		"Terrain3D", "Terrain3DData", "Terrain3DInstancer",
		"Terrain3DAssets", "Terrain3DMeshAsset", "Terrain3DRegion",
	]:
		if not ClassDB.class_exists(cls):
			print("%-22s ABSENT" % cls)
			continue
		print("%-22s present" % cls)
		var props: Array = ClassDB.class_get_property_list(cls, true)
		var names := PackedStringArray()
		for p: Dictionary in props:
			names.append(String(p["name"]))
		if not names.is_empty():
			print("    props:   %s" % ", ".join(names))
		var methods: Array = ClassDB.class_get_method_list(cls, true)
		var mnames := PackedStringArray()
		for m: Dictionary in methods:
			mnames.append(String(m["name"]))
		if not mnames.is_empty():
			print("    methods: %s" % ", ".join(mnames))
		print("")
	quit(0)
