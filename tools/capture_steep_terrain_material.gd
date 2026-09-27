extends "res://tools/capture_visual_audit.gd"
## DRY RUN — does not count toward earned-play or full visual acceptance.
## Production terrain, lighting and CameraRig; inherited stand/clock fixtures.

func _run() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await process_frame
	if root.size != Vector2i(1920, 1080):
		push_error("Native 1920x1080 viewport required")
		quit(1)
		return
	await super._run()

func _build_rows(_spec: Dictionary) -> Array:
	return [
		{"id": "gully_north", "label": "South Bridge north wall", "stands": [Vector3(25, NAN, 1330)], "target": Vector3(25, NAN, 1342), "target_ground": 0.0, "times": ["day", "dusk"]},
		{"id": "gully_south", "label": "South Bridge south wall", "stands": [Vector3(25, NAN, 1330)], "target": Vector3(25, NAN, 1318), "target_ground": 0.0, "times": ["day"]},
		{"id": "bridge_approach", "label": "South Bridge approach and path", "stands": [Vector3(0, NAN, 1295)], "target": Vector3(0, NAN, 1350), "target_ground": 0.0, "times": ["day"]},
		{"id": "long_water", "label": "Long Water bank treatment", "stands": [Vector3(-280, NAN, 4174)], "target": Vector3(-360, NAN, 4187), "target_ground": 0.6, "times": ["day", "night"]}
	]

func _capture_region_row(spec: Dictionary, row: Dictionary, t: String) -> void:
	var paired := OS.get_cmdline_user_args().has("--paired")
	if not paired:
		await super._capture_region_row(spec, row, t)
		return
	var terrain := _world.get_node_or_null("Terrain")
	if terrain == null:
		push_error("Paired capture requires production Terrain3D")
		quit(1)
		return
	var material: Object = terrain.get("material")
	for variant: String in ["off", "on"]:
		material.call("set_shader_param", "steep_rock_strength", 0.0 if variant == "off" else 1.0)
		var view := row.duplicate()
		view["id"] = str(row["id"]) + "_" + variant
		await super._capture_region_row(spec, view, t)

func _shoot(name: String, info: Dictionary) -> void:
	if root.size != Vector2i(1920, 1080):
		_skip(name, "viewport is not native 1920x1080")
		return
	var pivot := _player.global_position + Vector3.UP * float(_rig.get("_height"))
	var camera_arm := _rcam.global_position.distance_to(pivot)
	if camera_arm < 2.0:
		_skip(name, "camera spring collapsed below 2m; invalid material view")
		return
	info["viewport"] = [root.size.x, root.size.y]
	info["camera_arm_m"] = camera_arm
	info["proof"] = "DRY RUN — does not count"
	await super._shoot(name, info)
