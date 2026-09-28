extends "res://tools/capture_cloudreach_settlement_identity.gd"

## Same-boot isolation of visible foliage layers; diagnostic only.
func _build_rows(spec: Dictionary) -> Array:
	var selected: Array = []
	for row: Dictionary in super._build_rows(spec):
		if str(row.id) in ["place_cliffhold_court", "place_galefoot_hearth"]:
			row["times"] = ["day"]
			selected.append(row)
	for label: String in ["ProceduralGroundCover", "LookGroundCoverFinish", "LookAlpineRimMix", "CloudBanks"]:
		var node := _world.find_child(label, true, false) as Node3D
		_log_line({"kind":"layer", "name":label, "path":str(node.get_path()) if node != null else "MISSING"})
		if node == null:
			continue
		for batch: Node in node.find_children("*", "MultiMeshInstance3D", true, false):
			var mm := batch as MultiMeshInstance3D
			var box := mm.multimesh.mesh.get_aabb()
			var max_scale := Vector3.ZERO
			for i in mm.multimesh.instance_count:
				var instance := mm.global_transform * mm.multimesh.get_instance_transform(i)
				max_scale = max_scale.max(instance.basis.get_scale().abs())
			_log_line({"kind":"batch", "path":str(mm.get_path()), "count":mm.multimesh.instance_count,
				"mesh_size":_v(box.size), "maximum_scale":_v(max_scale)})
	return selected

func _capture_region_row(spec: Dictionary, row: Dictionary, time_name: String) -> void:
	var cases := {
		"all":[], "no_procedural":["ProceduralGroundCover"],
		"no_finish":["LookGroundCoverFinish"], "no_alpine":["LookAlpineRimMix"],
		"no_cover":["ProceduralGroundCover","LookGroundCoverFinish","LookAlpineRimMix"],
		"no_cloudbanks":["CloudBanks"]}
	for label: String in cases:
		var restored: Dictionary = {}
		for node_name: String in cases[label]:
			var node := _world.find_child(node_name, true, false) as Node3D
			if node != null:
				restored[node] = node.visible
				node.visible = false
		var diagnostic := row.duplicate(true)
		diagnostic["id"] = str(row.id) + "_" + label
		diagnostic["why"] = "Layer visibility isolation: " + label + "; not a proposed art result"
		await super._capture_region_row(spec, diagnostic, time_name)
		for node: Node3D in restored:
			node.visible = bool(restored[node])
