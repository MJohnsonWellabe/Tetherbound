extends "res://tools/capture_visual_audit.gd"
## DRY RUN — does not count. Production pickup loaders on the calibrated art
## stage, or actual authored Meadows placements through production CameraRig.
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const HARVEST := preload("res://scripts/world/harvest_node.gd")
const DRINKS := ["elixir_might", "elixir_guard", "elixir_vigour", "swift_tonic", "attack_tonic", "stoneguard_brew"]

func _run() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await process_frame
	if root.size != Vector2i(1920, 1080):
		push_error("Native 1920x1080 required")
		quit(1)
		return
	await super._run()

func _run_roster() -> void:
	await _build_stage()
	var game := root.get_node("Game")
	var db: RefCounted = game.get("items")
	_trainer.position = Vector3(-1.0, 0, 0)
	for id: String in DRINKS:
		var definition: Dictionary = db.call("definition", id)
		var body := Node3D.new()
		body.set_script(CACHE)
		_stage.add_child(body)
		body.call("setup", id, "Take it", str(definition["world_model"]), float(definition["world_model_scale"]), "draught_dry_run_" + id)
		for i in 10:
			await process_frame
		_frame(-1.3, 0.5, 1.8, 12)
		await _shoot(id + "_trainer_scale", {"item": id, "view": "trainer scale", "proof": "DRY RUN — does not count", "size_m": _v(_measured(body)), "viewport": [1920, 1080]})
		_trainer.visible = false
		for az: float in [8.0, 100.0, 188.0]:
			var a := deg_to_rad(az)
			_camera.position = Vector3(sin(a) * 1.55, 0.78, cos(a) * 1.55)
			_camera.look_at(Vector3(0, 0.32, 0))
			await _shoot(id + "_detail_" + str(int(az)), {"item": id, "view": "detail", "azimuth": az, "proof": "DRY RUN — does not count", "viewport": [1920, 1080]})
		_trainer.visible = true
		body.queue_free()
		await process_frame
	# Exercise the three explicit Meadows harvest loaders as well, including
	# their imported-material treatment; each uses the actual authored spec.
	for band: String in ["band2_stone_and_root", "band3_the_river_lock", "band4_upper_meadows_ironwood"]:
		var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/bands/%s/harvest.json" % band))
		for raw: Variant in cfg.values():
			if not raw is Array:
				continue
			for spec: Variant in raw:
				if not spec is Dictionary or not DRINKS.has(str(spec.get("item", ""))):
					continue
				var node := Node3D.new()
				node.set_script(HARVEST)
				_stage.add_child(node)
				node.call("setup", spec)
				_frame(-1.3, 0.5, 1.8, 12)
				await _shoot(str(spec.item) + "_harvest", {"item": spec.item, "view": "production harvest loader", "size_m": _v(_measured(node)), "proof": "DRY RUN — does not count", "viewport": [1920, 1080]})
				node.queue_free()
				await process_frame

func _build_rows(_spec: Dictionary) -> Array:
	if _region == "tidewake":
		return [
			{"id": "attack_tonic", "label": "First Shore authored Attack", "stands": [Vector3(94, NAN, 137)], "target": Vector3(94, NAN, 162), "target_ground": 1.8, "times": ["day", "night"]},
			{"id": "swift_tonic", "label": "First Shore authored Swift", "stands": [Vector3(172, NAN, -7)], "target": Vector3(172, NAN, 18), "target_ground": 1.8, "times": ["day", "night"]}
		]
	if _region == "stormwood":
		return [
			{"id": "swift_tonic", "label": "Stormwood pocket 178", "stands": [Vector3(-128, 98.79, 5235)], "target": Vector3(-128, 100.0, 5260), "times": ["break"]},
			{"id": "stoneguard_brew", "label": "Stormwood enlarged pocket 188", "stands": [Vector3(-453.03, 80.22, 5251.82)], "target": Vector3(-453.03, 82.0, 5277.82), "times": ["break"]}
		]
	return [
		{"id": "stoneguard_brew", "label": "Authored Stoneguard Brew", "stands": [Vector3(-347, NAN, 2584)], "target": Vector3(-347, NAN, 2610), "target_ground": 1.8, "times": ["day", "night"]},
		{"id": "attack_tonic", "label": "Authored Attack Tonic", "stands": [Vector3(198, NAN, 3687)], "target": Vector3(198, NAN, 3713), "target_ground": 1.8, "times": ["day", "night"]},
		{"id": "swift_tonic", "label": "Authored Swift Tonic", "stands": [Vector3(153, NAN, 5604)], "target": Vector3(153, NAN, 5630), "target_ground": 1.8, "times": ["day", "night"]},
		{"id": "elixir_might", "label": "Authored Might cache", "stands": [Vector3(-167, NAN, 7064)], "target": Vector3(-167, NAN, 7090), "target_ground": 1.8, "times": ["day", "night"]}
	]

func _shoot(name: String, info: Dictionary) -> void:
	info["viewport"] = [root.size.x, root.size.y]
	info["proof"] = "DRY RUN — does not count"
	if root.size != Vector2i(1920, 1080):
		_skip(name, "viewport changed from native 1920x1080")
		return
	if _section == "region":
		var contacts: Array = []
		for node: Node in get_nodes_in_group("progression_restore"):
			if not (node is CACHE or node is HARVEST):
				continue
			if str(node.get("_item_id")) != str(info.get("subject", "")):
				continue
			var body := node as Node3D
			if body.global_position.distance_to(_player.global_position) > 8.0:
				continue
			var visual := body.get("_visual") as Node3D
			if visual != null:
				var box := visual.global_transform * RENDER_BOUNDS.measure(visual)
				var ground := _ground_guess(body.global_position.x, body.global_position.z, body.global_position.y)
				contacts.append({"node": str(body.get_path()), "anchor": _v(body.global_position), "base_y": box.position.y, "ground_y": ground, "height_m": box.size.y, "ground_gap_m": box.position.y - ground})
		info["pickup_contacts"] = contacts
	await super._shoot(name, info)
