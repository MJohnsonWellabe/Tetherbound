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
	return [
		{"id": "stoneguard_brew", "label": "Authored Stoneguard Brew", "stands": [Vector3(-345, NAN, 2580)], "target": Vector3(-345, NAN, 2585), "target_ground": 0.32, "times": ["day", "night"]},
		{"id": "attack_tonic", "label": "Authored Attack Tonic", "stands": [Vector3(200, NAN, 3683)], "target": Vector3(200, NAN, 3688), "target_ground": 0.32, "times": ["day", "night"]},
		{"id": "swift_tonic", "label": "Authored Swift Tonic", "stands": [Vector3(155, NAN, 5600)], "target": Vector3(155, NAN, 5605), "target_ground": 0.32, "times": ["day", "night"]},
		{"id": "elixir_might", "label": "Authored Might cache", "stands": [Vector3(-165, NAN, 7060)], "target": Vector3(-165, NAN, 7065), "target_ground": 0.32, "times": ["day", "night"]}
	]
