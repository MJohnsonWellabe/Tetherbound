extends "res://tools/catalogue_survey.gd"

## Native ordinary-motion evidence for retained shared grass. The catalogue base
## performs one disclosed South Bridge setup; every later pose comes only from
## production move_forward input, physics, and the production camera rig.
const TOOL_PATH := "res://tools/probe_grass_motion_south_bridge.gd"
const WALK_FRAMES := 10
const PHYSICS_STEPS_PER_FRAME := 24
var _walk_receipt: Dictionary = {}

func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "meadows" or _planned.size() != 1 \
			or not str(_planned[0].frame_id).contains("south_bridge"):
		push_error("grass motion probe requires one Meadows South Bridge row")
		return false
	return true

func _capture_row(row: Dictionary) -> void:
	await super._capture_row(row)
	if not _failures.is_empty():
		return
	var grass := _world.get_node_or_null(^"GrassField") as Node3D
	if grass == null or not grass.visible:
		_failures.append("grass motion probe found no visible production GrassField")
		_write_manifest()
		return
	var initial := _player.global_position
	var initial_wind := _wind_readback(grass)
	var samples: Array[Dictionary] = []
	Input.action_press(&"move_forward", 1.0)
	for sample_index in WALK_FRAMES:
		for _step in PHYSICS_STEPS_PER_FRAME:
			await physics_frame
		var position := _player.global_position
		var travelled := Vector2(position.x - initial.x, position.z - initial.z).length()
		await _save_motion_frame(row, sample_index, travelled)
		samples.append({"index":sample_index, "player_position":_vec3(position),
			"camera_position":_vec3(_camera.global_position), "travelled_xz_m":travelled,
			"velocity":_vec3(_player.velocity)})
	Input.action_release(&"move_forward")
	var final_position := _player.global_position
	var travel := Vector2(final_position.x - initial.x, final_position.z - initial.z).length()
	if travel < 5.0:
		_failures.append("ordinary forward input travelled only %.3fm" % travel)
	_walk_receipt = {"initial_catalogue_frame":row.frame_id,
		"initial_player_position":_vec3(initial), "final_player_position":_vec3(final_position),
		"physical_travel_xz_m":travel, "walk_frames":WALK_FRAMES,
		"physics_steps_between_frames":PHYSICS_STEPS_PER_FRAME,
		"samples":samples, "grass_census":_grass_census(grass),
		"initial_wind_uniforms":initial_wind,
		"wind_uniforms":_wind_readback(grass),
		"weather_fixture":"Base catalogue freezes clear weather and daylight; this does not test weather transitions",
		"teleports_after_initial_catalogue_setup":0,
		"player_or_camera_transform_writes_after_setup":0,
		"grass_count_density_radius_tint_material_or_shader_mutation":false}
	_write_manifest()

func _save_motion_frame(row: Dictionary, index: int, travelled: float) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var frame_id := "%s__walk_%02d" % [str(row.frame_id), index]
	var path := "%s/%s.png" % [_output_dir, frame_id]
	if image == null or image.is_empty() or image.get_width() != root.size.x \
			or image.get_height() != root.size.y:
		_failures.append("%s: viewport image is empty or wrong-sized" % frame_id)
	elif image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % frame_id)
	else:
		var record := row.duplicate(true)
		record["frame_id"] = frame_id
		record["file"] = path
		record["player_position"] = _vec3(_player.global_position)
		record["camera_position"] = _vec3(_camera.global_position)
		record["camera_transform"] = _transform(_camera.global_transform)
		record["physical_travel_xz_m"] = travelled
		record["motion_source"] = "held production move_forward input"
		record["bytes"] = FileAccess.get_file_as_bytes(path).size()
		_records.append(record)
		print("GRASS MOTION CAPTURE %s -> %s" % [frame_id, path])
	_write_manifest()

func _grass_census(grass: Node3D) -> Dictionary:
	var instances := 0
	var geometries := 0
	var pending: Array[Node] = [grass]
	while not pending.is_empty():
		var node := pending.pop_back() as Node
		for child: Node in node.get_children():
			pending.append(child)
		if node is MultiMeshInstance3D:
			var geometry := node as MultiMeshInstance3D
			if geometry.multimesh != null:
				geometries += 1
				instances += geometry.multimesh.instance_count
	return {"geometry_count":geometries, "instance_count":instances}

func _wind_readback(grass: Node3D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	var pending: Array[Node] = [grass]
	while not pending.is_empty():
		var node := pending.pop_back() as Node
		for child: Node in node.get_children():
			pending.append(child)
		if not node is GeometryInstance3D:
			continue
		var material := (node as GeometryInstance3D).material_override as ShaderMaterial
		if material == null or seen.has(material.get_instance_id()):
			continue
		seen[material.get_instance_id()] = true
		out.append({"material_instance_id":material.get_instance_id(),
			"wind_strength":material.get_shader_parameter("wind_strength"),
			"gust":material.get_shader_parameter("gust"),
			"wind_time":material.get_shader_parameter("wind_time")})
	return out

func _finish(_complete: bool) -> void:
	Input.action_release(&"move_forward")
	_manifest["grass_motion"] = _walk_receipt.duplicate(true)
	_manifest["capture_tool"] = {"path":TOOL_PATH,
		"sha256":FileAccess.get_file_as_string(TOOL_PATH).sha256_text()}
	super._finish(_failures.is_empty() and _records.size() == _planned.size() + WALK_FRAMES)
