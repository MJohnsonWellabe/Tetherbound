extends "res://tools/catalogue_survey.gd"

## Production catalogue capture plus a binding witness. No alternate scene,
## camera or ground-cover factory is used by this probe.
func _capture_row(row: Dictionary) -> void:
	await super._capture_row(row)
	var cover := _world.get_node_or_null("StormwoodGroundCover")
	var evidence := {"present": cover != null, "world_scene": _world.scene_file_path}
	if cover != null:
		var bound_camera := cover.get("_camera") as Camera3D
		var bound_terrain := cover.get("_terrain") as Node
		evidence.merge({"visible": cover.is_visible_in_tree(), "bound": cover.get("_bound"),
			"tufts": cover.get("_ring_instances"), "centre": str(cover.get("_centre")),
			"camera": str(bound_camera.get_path()) if bound_camera != null else "",
			"camera_is_rendering": bound_camera == root.get_camera_3d(),
			"terrain": str(bound_terrain.get_path()) if bound_terrain != null else ""})
	if not _manifest.has("ground_cover_witnesses"):
		_manifest["ground_cover_witnesses"] = []
	(_manifest["ground_cover_witnesses"] as Array).append(evidence)
	print("STORMWOOD GROUND COVER ", JSON.stringify(evidence))
	_write_manifest()
