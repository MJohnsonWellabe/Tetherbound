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
	var slug := str(row.get("authored_id", row.get("destination_display_name", ""))).to_lower().replace(" ", "_").replace("-", "_")
	if slug.is_empty():
		return ""
	var table := RUNNER.table()
	var prefixes: Array[String] = []
	match _biome_id:
		"meadows": prefixes = ["village_%s" % slug, "trainer_%s" % slug]
		"water": prefixes = ["water_%s" % slug]
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
	_write_manifest()
