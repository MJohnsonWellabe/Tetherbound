extends "res://tools/phase2_capture_characters.gd"

## Visual dialogue pass at each authored character post. Uses the installed
## production DialoguePanel and authored conversation text. The conversation
## is started directly after the post fixture; this records presentation, not
## proof that a normal interaction or progress gate is reachable.
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")

func _load_plan() -> bool:
	if not super._load_plan():
		return false
	var start := 0
	var count := -1
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--start="):
			start = maxi(0, int(arg.trim_prefix("--start=")))
		elif arg.begins_with("--count="):
			count = maxi(1, int(arg.trim_prefix("--count=")))
	if start > 0 or count > 0:
		_planned = _planned.slice(start, mini(_planned.size(), start + count) if count > 0 else _planned.size())
	return not _planned.is_empty()

func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["dialogue_fixture"] = "Production DialoguePanel started with an authored conversation at each character post. Visual state only; no normal interaction or progression proof."

func _finish(_complete: bool) -> void:
	# This pass deliberately records a post plus a conversation per plan row.
	super._finish(_failures.is_empty() and _records.size() == _planned.size() * 2)

func _dialogue_for(row: Dictionary) -> String:
	var source := str(row.get("authored_source", ""))
	var authored := str(row.get("authored_id", ""))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://" + source)) if not source.is_empty() else null
	if parsed is Dictionary:
		var config := parsed as Dictionary
		var groups: Array[String] = ["villagers", "trainers", "npcs", "characters"]
		for group: String in groups:
			for raw: Variant in config.get(group, []):
				if not raw is Dictionary:
					continue
				var spec := raw as Dictionary
				if str(spec.get("id", spec.get("name", ""))) != authored:
					continue
				for field: String in ["greeting", "challenge", "intro_conversation"]:
					var direct := str(spec.get(field, ""))
					if RUNNER.table().has(direct):
						return direct
				var ids: Array = spec.get("dialogue_ids", [])
				if not ids.is_empty() and RUNNER.table().has(str(ids[0])):
					return str(ids[0])
				if _biome_id == "stormwood":
					var derived := "stormwood_trainer_%s_challenge" % authored if group == "trainers" else "stormwood_%s_arrival" % authored
					if RUNNER.table().has(derived):
						return derived
	var slug := str(row.get("authored_id", row.get("destination_display_name", ""))).to_lower().replace(" ", "_").replace("-", "_")
	if slug.is_empty():
		return ""
	var table := RUNNER.table()
	var prefixes: Array[String] = []
	match _biome_id:
		"meadows": prefixes = ["village_%s" % slug, "trainer_%s" % slug]
		"water": prefixes = [slug if slug.begins_with("water_") else "water_%s" % slug]
		"cloudreach": prefixes = ["cloudreach_%s" % slug]
		"stormwood": prefixes = ["stormwood_%s" % slug]
	var candidates: Array[String] = []
	for key: String in table:
		if key.contains("defeated") or key.contains("aftermath"):
			continue
		for prefix: String in prefixes:
			if key == prefix or key.begins_with(prefix + "_"):
				candidates.append(key)
				break
	candidates.sort_custom(func(a: String, b: String) -> bool:
		return a.length() < b.length() if a.length() != b.length() else a < b)
	return candidates[0] if not candidates.is_empty() else ""

func _capture_row(row: Dictionary) -> void:
	var before := _records.size()
	await super._capture_row(row)
	if _records.size() == before:
		return
	var conversation := _dialogue_for(row)
	if conversation.is_empty():
		_failures.append("%s: no authored dialogue id mapped to post" % str(row.frame_id))
		_write_manifest()
		return
	var panel := get_first_node_in_group("dialogue_panel") as CanvasLayer
	if panel == null or not panel.has_method("start"):
		_failures.append("%s: production DialoguePanel missing" % str(row.frame_id))
		_write_manifest()
		return
	panel.visible = true
	if not bool(panel.call("start", conversation)):
		_failures.append("%s: panel refused %s" % [str(row.frame_id), conversation])
		panel.visible = false
		_write_manifest()
		return
	if not await _settle_dialogue_capture():
		panel.call("close")
		panel.visible = false
		_write_manifest()
		return
	await RenderingServer.frame_post_draw
	var path := "%s/%s__dialogue.jpg" % [_output_dir, str(row.frame_id)]
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_jpg(path, 0.87) != OK:
		_failures.append("%s: dialogue viewport save failed" % str(row.frame_id))
	else:
		var record := _records[-1].duplicate(true)
		record["frame_id"] = str(row.frame_id) + "__dialogue"
		record["identity"] = record.frame_id
		record["file"] = path
		record["view"] = "dialogue"
		record["dialogue_id"] = conversation
		record["dialogue_visual_only"] = true
		# The panel may change the production camera after the post frame.
		# Record the transform that actually produced this dialogue image.
		record["camera_position"] = _vec3(_camera.global_position)
		record["camera_transform"] = _transform(_camera.global_transform)
		record["camera_rig_transform"] = _transform(_rig.global_transform)
		record["camera_rig_spring_length"] = _rig.spring_length
		record["camera_player_distance_m"] = _camera.global_position.distance_to(_player.global_position)
		record["camera_fov_degrees"] = _camera.fov
		record["conversation_camera_active"] = bool(_rig.call("is_in_conversation"))
		record["conversation_camera_blend"] = float(_rig.call("conversation_blend"))
		var shot: Dictionary = _rig.call("conversation_shot")
		for key: String in shot:
			if shot[key] is Vector3:
				shot[key] = _vec3(shot[key])
		record["conversation_camera_shot"] = shot
		record["conversation_camera_fallback"] = bool(_rig.call("conversation_used_fallback"))
		record["camera_purpose"] = "dialogue"
		record["player_position"] = _vec3(_player.global_position)
		record["bytes"] = FileAccess.get_file_as_bytes(path).size()
		record["size"] = [image.get_width(),image.get_height()]
		var nearby_creatures := _nearby_creatures(_player.global_position)
		record["nearby_creatures_160m"] = nearby_creatures.size()
		record["nearby_creature_records_160m"] = nearby_creatures
		var surge := _world.get_node_or_null(^"StormwoodSurge")
		if surge != null:
			record["phase"] = str(surge.get("phase"))
		record["dialogue_speaker"] = str(panel.call("current_speaker"))
		record["dialogue_portrait"] = str(panel.call("current_portrait"))
		_records.append(record)
		print("DIALOGUE CAPTURE %s -> %s" % [conversation, path])
	panel.call("close")
	panel.visible = false
	# The production conversation camera eases its spring back after close.
	# Give the next post its ordinary third-person stand, not the last NPC's
	# close conversation framing.
	for frame in 30:
		await physics_frame
	_write_manifest()


func _settle_dialogue_capture() -> bool:
	for frame in 7:
		await process_frame
	return true
