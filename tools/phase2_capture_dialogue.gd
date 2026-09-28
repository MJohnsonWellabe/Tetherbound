extends "res://tools/phase2_capture_characters.gd"

## Visual dialogue pass at each authored character post. Uses the installed
## production DialoguePanel and authored conversation text. The conversation
## is started directly after the post fixture; this records presentation, not
## proof that a normal interaction or progress gate is reachable.
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")

func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["dialogue_fixture"] = "Production DialoguePanel started with an authored conversation at each character post. Visual state only; no normal interaction or progression proof."

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
	for frame in 7:
		await process_frame
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
