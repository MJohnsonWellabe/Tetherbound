extends SceneTree

## PERF-2. What Terrain3DMeshAsset's LOD/impostor/fade properties actually
## are on this vendored build -- full property dicts (type, hint, hint_string,
## default via a live instance), not just names. `_probe_terrain_streaming.gd`
## only printed names; this fills in the semantics `vegetation.gd::
## _make_mesh_asset()` needs to set them correctly instead of guessing.
##
##   godot --headless --path . --script tools/_probe_mesh_asset_lod.gd

func _init() -> void:
	if not ClassDB.class_exists("Terrain3DMeshAsset"):
		print("Terrain3DMeshAsset ABSENT")
		quit(1)
		return
	var inst: Object = ClassDB.instantiate("Terrain3DMeshAsset")
	var props: Array = ClassDB.class_get_property_list("Terrain3DMeshAsset", true)
	for p: Dictionary in props:
		var name := String(p["name"])
		var default: Variant = inst.get(name)
		print("%-24s type=%-10s hint=%-10s hint_string=%-30s default=%s" % [
			name, p.get("type"), p.get("hint"), p.get("hint_string"), str(default)
		])
	quit(0)
