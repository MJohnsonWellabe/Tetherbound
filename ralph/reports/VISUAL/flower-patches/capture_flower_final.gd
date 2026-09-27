extends "D:/tetherbound/visual-acceptance-local/capture_flower_patches.gd"

func _build_rows(_spec: Dictionary) -> Array:
	return [
		{"id": "place_flower_final_ironwood", "label": "Ironwood", "stands": [Vector3(-345, NAN, 5060)], "target": Vector3(-250, NAN, 6490), "target_ground": 2.0, "times": ["day", "night"], "why": "final loaded-material and short motion witness"},
		{"id": "place_flower_final_ridgeline", "label": "The Ridgeline Watch", "stands": [Vector3(-250, NAN, 6490)], "target": Vector3(0, NAN, 7000), "target_ground": 2.0, "times": ["day", "night"], "why": "existing authored flower composition regression witness"}
	]

func _boot_region(spec: Dictionary) -> bool:
	if not await super._boot_region(spec):
		return false
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("D:/tetherbound/visual-acceptance-local/flower-original-grass-field.json"))
	assert(_flowers.size() == 2)
	for tier: Dictionary in _flowers:
		for key: String in tier.after:
			var actual: Variant = (tier.material as ShaderMaterial).get_shader_parameter(key)
			var expected: Variant = tier.after[key]
			assert(actual.is_equal_approx(expected) if expected is Vector2 else is_equal_approx(float(actual), float(expected)), "loaded material mismatch: " + tier.name + "/" + key)
		for old: Dictionary in original.cover_tiers:
			if "Cover_" + str(old.name) != str(tier.name):
				continue
			for key: String in tier.after:
				tier.before[key] = Vector2.ZERO if key == "drift_offset" else old.get(key, 0)
		print("FLOWER_FINAL_VERIFIED ", tier.name, " actual=", tier.after, " baseline=", tier.before)
	return true

func _shoot(label: String, info: Dictionary) -> void:
	await super._shoot(label, info)
	if not label.contains("ironwood_day"):
		return
	_apply_flower_variant(true)
	var initial := _player.global_position
	Input.action_press("move_forward")
	for index in 24:
		for frame in 10:
			await physics_frame
		_clear_interruptions()
		await RenderingServer.frame_post_draw
		var file := "motion_%02d.png" % index
		var picture := root.get_texture().get_image()
		assert(picture.save_png(_dir + "/" + file) == OK)
		_log_line({"kind": "motion_frame", "file": file, "index": index, "feet": _v(_player.global_position), "camera": _v(_rcam.global_position), "fixture": "staged start; production movement input, candidate loaded settings; HUD hidden; director frozen"})
	Input.action_release("move_forward")
	print("FLOWER_MOTION_DISPLACEMENT_M ", initial.distance_to(_player.global_position))
	_apply_flower_variant(false)
