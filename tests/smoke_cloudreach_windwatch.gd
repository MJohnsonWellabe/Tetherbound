extends SceneTree

const WATCH := preload("res://scripts/world/cloudreach_windwatch.gd")
var failures: Array[String] = []
var checks := 0

func _init() -> void:
	var cfg: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/cloudreach_visual.json")) as Dictionary).settlement.windwatch
	var source_bounds := WATCH.LOOKOUT.get_aabb()
	var source_faces := WATCH.LOOKOUT.get_faces()
	var timber := StandardMaterial3D.new()
	var roof := StandardMaterial3D.new()
	var parent := Node3D.new()
	root.add_child(parent)
	for height_key: String in ["upper_stone_height_m", "lower_stone_height_m"]:
		var height := float(cfg[height_key])
		var model: MeshInstance3D = WATCH.build(parent, Vector3.ZERO, height, cfg, timber, roof)
		var bounds := model.mesh.get_aabb()
		_check(model.mesh != WATCH.LOOKOUT, "source mesh is not edited")
		_check(model.mesh.get_surface_count() == 2, "both source material surfaces retained")
		_check(model.get_active_material(0) == timber and model.get_active_material(1) == roof,
			"imported timber and Celing surfaces receive distinct materials")
		_check(absf(bounds.position.y - float(cfg.source_gallery_floor_y)) < 0.001,
			"all scaffold below the deck is removed")
		_check(absf(bounds.end.y - source_bounds.end.y) < 0.001, "roof and upper silhouette retained")
		_check(absf(bounds.position.y * model.scale.y + model.position.y - height - float(cfg.deck_clearance_m)) < 0.001,
			"derived deck seats at configured crown clearance")
		_check(bounds.position.y * model.scale.y + model.position.y <= height + 0.30,
			"gallery floor overlaps the crown instead of floating")
		_check(absf(bounds.size.x * model.scale.x - float(cfg.gallery_width_m)) < 0.001,
			"configured horizontal footprint preserved")
		var valid_normals := true
		var degenerate := false
		for surface in model.mesh.get_surface_count():
			var arrays := model.mesh.surface_get_arrays(surface)
			for normal: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
				valid_normals = valid_normals and normal.is_finite() and absf(normal.length() - 1.0) < 0.01
		var faces := model.mesh.get_faces()
		for index in range(0, faces.size(), 3):
			degenerate = degenerate or (faces[index + 1] - faces[index]).cross(faces[index + 2] - faces[index]).length_squared() < 0.000000000001
		_check(valid_normals, "clipped face normals remain finite and normalized")
		_check(not degenerate, "clip creates no degenerate triangles")
	_check(WATCH.LOOKOUT.get_aabb() == source_bounds and WATCH.LOOKOUT.get_faces() == source_faces,
		"building both settlements leaves source geometry unchanged")
	parent.free()
	print("WINDWATCH_SMOKE checks=", checks, " failures=", failures.size())
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
