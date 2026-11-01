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

## Beyond this the post is not at the speaker; the dialogue frame stands the
## player beside the body instead (a normal talking distance is 2-4 m).
const SPEAKER_STAND_WITHIN_M := 4.5

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
	# DLG-1 (GPU, 31 Oct): 14 of 34 frames opened the panel with no push-in
	# because the panel's own begin() reads the arbiter's live winning prompt,
	# and no enabled speaker prompt was offering at those posts (the speaker
	# stood elsewhere, or the prompt is off in this fresh state). Play opens
	# each of these conversations with the speaker's body beside the player,
	# so frame that body: find it, stand beside it if the post is not at it,
	# and hand it to the conversation camera, as the game's own victory path
	# does (encounter_director.gd `_present_trainer_victory`). Framing is the
	# production camera's; nothing about the shot is changed here.
	var speaker_note := await _frame_speaker(row)
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
		record["dialogue_speaker_body"] = speaker_note
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


## The speaker's body for a character post: matched by authored id, display
## name or slug against every character body (character_model.gd duck type)
## in the world, including the encounter directors' `trainer_nodes`. Nearest
## match wins. Null when this state has not placed them.
func _speaker_body(row: Dictionary) -> Node3D:
	var keys: Dictionary = {}
	for value: Variant in [row.get("authored_id", ""), row.get("destination_display_name", ""),
			row.get("subject", ""), row.get("slug", "")]:
		var key := str(value).to_lower().strip_edges()
		if not key.is_empty():
			keys[key] = true
	var candidates: Array[Node3D] = []
	for node: Node in root.find_children("*", "Node", true, false):
		var trainers: Variant = node.get("trainer_nodes") if "trainer_nodes" in node else null
		if trainers is Dictionary:
			var specs: Variant = node.get("trainer_specs") if "trainer_specs" in node else {}
			for id: Variant in (trainers as Dictionary):
				var body: Variant = (trainers as Dictionary)[id]
				var shown := ""
				if specs is Dictionary and (specs as Dictionary).get(id) is Dictionary:
					shown = str(((specs as Dictionary)[id] as Dictionary).get("name", "")).to_lower()
				if (keys.has(str(id).to_lower()) or (not shown.is_empty() and keys.has(shown))) \
						and is_instance_valid(body) and body is Node3D:
					candidates.append(body as Node3D)
		if not (node is Node3D and node.has_method("height") and node.has_method("has_model")):
			continue
		if node == _player or _player.is_ancestor_of(node):
			continue
		var names: Array[String] = [str(node.name).to_lower(), str(node.get_meta("water_npc_id", "")).to_lower()]
		var spec: Variant = node.get_meta("foundation_trainer_spec", {})
		if spec is Dictionary:
			names.append(str((spec as Dictionary).get("id", "")).to_lower())
		for name: String in names:
			if not name.is_empty() and keys.has(name):
				candidates.append(node as Node3D)
				break
	var best: Node3D = null
	var best_d := INF
	for body: Node3D in candidates:
		# A far body may be hidden by residency culling; standing beside it
		# brings it back, so hidden is not absent.
		if not body.is_inside_tree():
			continue
		var d := body.global_position.distance_to(_player.global_position)
		if d < best_d:
			best_d = d
			best = body
	return best


## Returns what was done, for the manifest: "near", "moved:<m>", "absent" or
## "refused".
func _frame_speaker(row: Dictionary) -> String:
	var body := _speaker_body(row)
	if body == null:
		var seen: Array[String] = []
		for node: Node in root.find_children("*", "Node3D", true, false):
			if node.has_method("height") and node.has_method("has_model") and seen.size() < 80:
				seen.append(str(node.name))
		print("DLG_SPEAKER %s absent; character bodies: %s" % [str(row.frame_id), ", ".join(seen)])
		return "absent"
	var note := "near"
	var reach := SPEAKER_STAND_WITHIN_M
	var d := body.global_position.distance_to(_player.global_position)
	if d > reach:
		# The catalogue post is not where this body stands: talk to it where it
		# is, from the side the player is coming from.
		var away := Vector2(_player.global_position.x - body.global_position.x,
			_player.global_position.z - body.global_position.z)
		if away.length() < 0.01:
			away = Vector2(0.0, 1.0)
		away = away.normalized()
		var game := root.get_node_or_null(^"Game")
		var placed := false
		for gap: float in [2.6, 3.2, 2.0, 3.8, 4.4]:
			for turn: float in [0.0, 0.6, -0.6, 1.2, -1.2, 1.8, -1.8, 2.4, -2.4, PI]:
				var dir := away.rotated(turn)
				var at := Vector2(body.global_position.x, body.global_position.z) + dir * gap
				if game == null or not bool(game.call("debug_teleport_to", at.x, at.y, _biome_id, "")):
					continue
				for _frame in ARRIVE_FRAMES:
					await physics_frame
				var terrain := float(_world.call("ground_height_at", at.x, at.y))
				if not is_finite(terrain):
					continue
				var ground := resolve_capture_ground(_player, at.x, at.y, terrain)
				if not is_finite(ground) or absf(ground - body.global_position.y) > 2.5:
					# P2-083/P2-081 (GPU DLG-2): Captain Marrow stands on the
					# Dynamo deck 260 m above the terrain, which the terrain and
					# built-floor answers never see, so every stand was refused
					# and the frame showed the player on the forest floor under
					# the deck. A walkable collider within reach of the body's
					# own height is the floor the player talks to him from.
					ground = _deck_floor(at, body.global_position.y)
				if not is_finite(ground) or absf(ground - body.global_position.y) > 2.5:
					continue
				_player.global_position = Vector3(at.x, ground, at.y)
				_player.velocity = Vector3.ZERO
				var face := Vector2(body.global_position.x - at.x, body.global_position.z - at.y)
				_player.rotation.y = atan2(face.x, face.y)
				_rig.global_position = _player.global_position
				_player.reset_physics_interpolation()
				_rig.reset_physics_interpolation()
				for _frame in POPULATE_FRAMES:
					await physics_frame
				placed = true
				break
			if placed:
				break
		if not placed:
			print("DLG_SPEAKER %s refused: no stand beside the body (%.1f m)" % [str(row.frame_id), d])
			return "refused"
		note = "moved:%.1f" % d
	var push_in := get_first_node_in_group("conversation_camera")
	if push_in == null or not bool(push_in.call("begin", body)):
		print("DLG_SPEAKER %s refused by the conversation camera" % str(row.frame_id))
		return "refused"
	print("DLG_SPEAKER %s %s %s" % [str(row.frame_id), note, str(body.get_path())])
	return note


## The top of whatever collider lies under `at` within 2.5 m of `near_y`, or
## NAN. Used only when the terrain and built-floor answers are far from the
## speaker's own height (a raised deck no building registers).
func _deck_floor(at: Vector2, near_y: float) -> float:
	var space := _player.get_world_3d().direct_space_state if _player != null else null
	if space == null:
		return NAN
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, near_y + 2.5, at.y), Vector3(at.x, near_y - 2.5, at.y))
	if _player is CollisionObject3D:
		query.exclude = [(_player as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return NAN
	return float((hit["position"] as Vector3).y)
