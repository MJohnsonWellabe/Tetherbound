extends "res://tools/capture_water_chain_lures.gd"
## Same production CameraRig stands as the F13#3 receipt, preserved at1080p.
## DRY RUN: upstream flags and teleport fixtures, not earned or walked proof.

var _manifest: FileAccess
var _failures: Array[String] = []

func _run() -> void:
	await process_frame
	root.size = Vector2i(1920,1080)
	await process_frame
	var out := ProjectSettings.globalize_path(_arg("out"))
	DirAccess.make_dir_recursive_absolute(out)
	_manifest = FileAccess.open(out.path_join("manifest.jsonl"),FileAccess.WRITE)
	await super._run()
	if not _failures.is_empty():
		quit(1)

func _grab(file: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != Vector2i(1920,1080):
		_failures.append("Native frame unavailable: " + file)
		push_error("Native lure capture requires1920x1080")
		quit(1)
		return
	var name := file.trim_suffix(".jpg") + ".png"
	var path := ProjectSettings.globalize_path(_arg("out")).path_join(name)
	if image.save_png(path) != OK:
		_failures.append("Native frame write failed: " + path)
		quit(1)
		return
	var active := root.get_camera_3d()
	var record := {"file":name,"label":label,"proof":"DRY RUN — does not count", "feet":_v(player.global_position),
		"camera":_v(active.global_position),"fov":active.fov,"camera_rotation":_v(active.global_rotation_degrees),"size":[1920,1080]}
	_manifest.store_line(JSON.stringify(record))
	_manifest.flush()
	labels.append(name)
	print("LURE_NATIVE ",JSON.stringify(record))

func _check(ok: bool, label: String) -> void:
	if not ok:
		_failures.append(label)
	var record := {"check":label,"pass":ok}
	print("LURE_CHECK ", JSON.stringify(record))
	_manifest.store_line(JSON.stringify(record))
	_manifest.flush()

func _verify_lifecycle() -> void:
	var dressing := world.get_node(^"WaterLocalLureDressing")
	var count := dressing.get_child_count()
	var flags_before: Dictionary = game.world.flags.save_data().duplicate(true)
	dressing.call("build", world)
	_check(count == 2 and dressing.get_child_count() == count, "two sites; repeated build is idempotent")
	_check(game.world.flags.save_data() == flags_before, "presentation build does not change flags")
	_check(dressing.find_children("*", "CollisionObject3D", true, false).is_empty()
		and dressing.find_children("*", "CollisionShape3D", true, false).is_empty()
		and dressing.find_children("*", "NavigationRegion3D", true, false).is_empty(), "dressing adds no collision, area or navigation")
	var chains := world.get_node(^"WaterLocalChains")
	var satchel: Node3D = chains.call("site_root", "gull_research_satchel")
	var at := satchel.global_transform
	game.world.flags.set_flag("water_claim:local:gull_research:lead", false)
	chains.call("_refresh")
	_check(not satchel.visible and dressing.get_node(^"GullSurveySite").is_visible_in_tree(), "unoffered satchel hidden; survey site persists")
	game.world.flags.set_flag("water_claim:local:gull_research:lead")
	chains.call("_refresh")
	_check(satchel.visible, "heard lead reveals original satchel")
	game.world.flags.set_flag("water_claim:local:gull_research:satchel")
	chains.call("_refresh")
	_check(not satchel.visible and dressing.get_node(^"GullSurveySite").is_visible_in_tree(), "recovered satchel hidden; survey site persists")
	_check(satchel.global_transform == at, "satchel transform preserved through state changes")
	game.world.flags.load_data(flags_before)
	chains.call("_refresh")
	var docks := world.get_node(^"WaterDocks")
	var old_chart := docks.get_node(^"deep_watch_chart") as Node3D
	var chart_at := old_chart.global_transform
	var old_count := docks.get_child_count()
	docks.call("restore_progression_from_game", game)
	await process_frame
	_check(docks.get_node(^"deep_watch_chart").global_transform == chart_at, "restored chart interaction stays at original transform")
	_check(docks.get_child_count() == old_count and dressing.get_child_count() == count,
		"progression restoration neither loses nor duplicates dressing/equipment")
	_check(dressing.get_node(^"DeepWatchChartShelter").is_visible_in_tree(), "chart shelter remains after progression restoration")
	_check(game.world.flags.save_data() == flags_before, "fixture restores original flags")

func _v(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func _approach(key: String, island: String, lure: Vector3, what: String, mid: float) -> void:
	await super._approach(key, island, lure, what, mid)
	if key not in ["gull", "garden", "deep"]:
		return
	var landing := _landing(island)
	var toward := Vector2(landing.x - lure.x, landing.z - lure.z).normalized()
	var near := lure + Vector3(toward.x, 0, toward.y) * (3.0 if key == "deep" else 10.0)
	near.y = 0.0
	_pose(near, lure)
	await _settle(180)
	await _grab(key + "_3_near.jpg", what + " diagnostic near stand (teleport fixture)")
	var look := world.get_node(^"WorldLook")
	look.call("apply_time", "night")
	await _settle(90)
	await _grab(key + "_4_night.jpg", what + " diagnostic near night stand (teleport fixture)")
	look.call("apply_time", "day")
	var samples: Array = []
	for step in range(1, 21):
		var point := landing.lerp(lure, float(step) / 20.0)
		samples.append([point.x, float(world.call("ground_height_at", point.x, point.z)), point.z])
	_manifest.store_line(JSON.stringify({"site":key,"terrain_profile":samples}))
	_manifest.flush()
	if key == "deep":
		await _verify_lifecycle()
