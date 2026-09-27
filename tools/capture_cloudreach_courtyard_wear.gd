extends "res://tools/capture_cloudreach_settlement_identity.gd"

## Controlled material-only comparison in one production world instance.
## Save both untouched native frames; production source remains the candidate.
const CONTROL_PATH := "res://ralph/reports/VISUAL/cloudreach-courtyard-wear/baseline.shader.txt"
var _wear_shader: Shader = preload("res://shaders/cloudreach_worn_ground.gdshader")
var _candidate_code := _wear_shader.code
var _control_code := FileAccess.get_file_as_string(CONTROL_PATH)

func _build_rows(spec: Dictionary) -> Array:
	var rows := super._build_rows(spec)
	for yard_id: String in ["trainer_ila_lower_ring", "tether_lieutenant_senn", "officer_voss_summit_approach"]:
		var yard := _world.find_child(yard_id + "_yard", true, false) as Node3D
		if yard != null:
			rows.append({"id":"place_" + yard_id + "_wear", "label":yard_id + " clearing edge",
				"stands":[yard.global_position + Vector3(-8,0,10)], "target":yard.global_position,
				"pitch_deg":-18.0, "times":["day","night"], "why":"Production clearing, grounded diagnostic stand; no fight witness"})
		else:
			_skip(yard_id, "authored yard missing")
	var ash: MeshInstance3D
	var nearest := INF
	for node: Node in _world.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var material := mesh.material_override as ShaderMaterial
		if material == null or material.shader != _wear_shader:
			continue
		if not is_equal_approx(float(material.get_shader_parameter("radius")), 2.4):
			continue
		var distance := mesh.global_position.distance_to(Vector3(123,1160.2,5448))
		if distance < nearest:
			nearest = distance
			ash = mesh
	if ash != null:
		var inward := (Vector3(100,ash.global_position.y,5450) - ash.global_position).normalized()
		rows.append({"id":"place_brazier_ash", "label":"Paved brazier footing",
			"stands":[ash.global_position + inward * 7.0], "target":ash.global_position,
			"pitch_deg":-18.0, "times":["day","night"], "why":"Production ash on paving, grounded diagnostic stand; no finale-play witness"})
		var tell_row: Dictionary = rows.back().duplicate(true)
		tell_row["id"] = "place_brazier_ash_tell"
		tell_row["hazard_fixture"] = true
		tell_row["why"] = "Presentation-only frozen production hazard phase 2 at elapsed 0; no combat or timing proof"
		rows.append(tell_row)
	else:
		_skip("brazier_ash", "authored ash missing")
	rows.append({"id":"place_aviary_floor_wear", "label":"Aviary floor",
		"stands":[Vector3(100,1160,5330)], "target":Vector3(100,1160,5350),
		"pitch_deg":-18.0, "times":["day","night"], "why":"Production aviary floor, grounded diagnostic stand; no finale-play witness"})
	return rows

func _capture_region_row(spec: Dictionary, row: Dictionary, time_name: String) -> void:
	var overlay := _world.find_child("LiveHazardTelegraphs", true, false) as MeshInstance3D
	var hazard: ShaderMaterial
	var old_phase: Variant
	var old_elapsed: Variant
	var old_process := false
	if bool(row.get("hazard_fixture", false)) and overlay != null:
		hazard = overlay.material_override as ShaderMaterial
		old_phase = hazard.get_shader_parameter("phase")
		old_elapsed = hazard.get_shader_parameter("elapsed")
		old_process = overlay.get_parent().is_processing()
		overlay.get_parent().set_process(false)
		hazard.set_shader_parameter("phase", 2)
		hazard.set_shader_parameter("elapsed", 0.0)
		_log_line({"kind":"hazard_fixture", "phase":2, "elapsed":0.0,
			"wear_priority":-1, "hazard_priority":hazard.render_priority})
	for variant: String in ["control", "candidate"]:
		_wear_shader.code = _control_code if variant == "control" else _candidate_code
		for frame in 4:
			await process_frame
		var paired_row := row.duplicate(true)
		paired_row["id"] = str(row.id) + "_" + variant
		_log_line({"kind":"shader_variant", "variant":variant, "subject":row.id,
			"time":time_name, "shader_sha256":_wear_shader.code.sha256_text(),
			"fixture":"Shared shader code swapped in one world; geometry, material uniforms and production source unchanged between pairs"})
		await super._capture_region_row(spec, paired_row, time_name)
	_wear_shader.code = _candidate_code
	if hazard != null:
		hazard.set_shader_parameter("phase", old_phase)
		hazard.set_shader_parameter("elapsed", old_elapsed)
		overlay.get_parent().set_process(old_process)
