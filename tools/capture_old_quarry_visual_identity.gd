extends SceneTree

## Dedicated current-production proof for The Old Quarry after the creature-scale
## and consolidated Meadows scatter passes. Does not edit world state, actors,
## quarry art, or the generic location harness.
##
## Windows production command (Compatibility renderer; deliberately no headless):
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_old_quarry_visual_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/MEADOWS-0912/OLD-QUARRY-TERRACE-R11"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const READY_TIMEOUT_MS := 420_000
const SHOTS := [
	{
		# R7's 380,1820 stand sat west of the cleared road and put the camera
		# directly behind/inside the new west shelf. This point remains inside
		# the authored final-approach clearing and continues the production road,
		# looking back along the same cut-face bearing proven by shot 04.
		"label": "01-arrival", "stand": Vector2(394.0, 1817.0),
		"target": Vector2(383.0, 1804.0), "back": 1.0, "up": 3.0,
		"aim_up": 1.8, "fov": 68.0,
	},
	{
		"label": "02-worked-floor", "stand": Vector2(400.0, 1803.0),
		"target": Vector2(418.0, 1764.0), "back": 2.0, "up": 2.5,
		"aim_up": 2.0, "fov": 64.0,
	},
	{
		# Back off along the actual pylon sightline rather than the old 399,1809
		# close crop whose foreground deadfall/foundation edge hid the machine.
		"label": "03-conduit-head", "stand": Vector2(392.0, 1812.0),
		"target": Vector2(404.0, 1804.0), "back": 1.5, "up": 2.6,
		"aim_up": 1.7, "fov": 58.0,
	},
	{
		# R10 proved the connected strata but its 12.4m reverse lens filled 99%
		# of the frame with their merged bounds. This nearby worked-floor stand
		# keeps the distinct eastward angle while placing the eye 21.6m from the
		# face; the wider lens admits the whole extraction hierarchy as a scene.
		"label": "04-cut-face", "stand": Vector2(398.0, 1815.0),
		"target": Vector2(383.0, 1804.0), "back": 3.0, "up": 3.5,
		"aim_up": 1.8, "fov": 75.0,
	},
]


func _init() -> void:
	_run()


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(OUT_DIR, "Old Quarry terrace capture"):
		quit(1)
		return
	var packed := load(SCENE) as PackedScene
	if packed == null:
		push_error("could not load production Meadows scene")
		quit(1)
		return
	var world := packed.instantiate() as Node3D
	root.add_child(world)
	if not await _wait_for_world(world):
		push_error("production Meadows scene did not finish building")
		quit(1)
		return
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	if player == null or look == null:
		push_error("capture requires production Player and WorldLook")
		quit(1)
		return
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	var camera := Camera3D.new()
	camera.name = "OldQuarryVisualEvidenceCamera"
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var terrain := world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	_hide_overlays(world)

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	var grounding: Dictionary = {}
	for time_name: String in ["day", "night"]:
		grounding[time_name] = {}
		for shot: Dictionary in SHOTS:
			var result := await _capture(world, player, look, camera, shot, time_name,
				records, failures)
			(grounding[time_name] as Dictionary)[str(shot["label"])] = result
	for shot: Dictionary in SHOTS:
		var label := str(shot["label"])
		var day: Dictionary = (grounding.get("day", {}) as Dictionary).get(label, {})
		var night: Dictionary = (grounding.get("night", {}) as Dictionary).get(label, {})
		if absf(float(day.get("support_y", INF)) - float(night.get("support_y", -INF))) > 0.05:
			failures.append("%s day/night sampled different live ground surfaces" % label)
		if not bool(day.get("player_on_floor", false)) \
				or not bool(night.get("player_on_floor", false)) \
				or absf(float(day.get("player_ground_delta", INF))) > 0.75 \
				or absf(float(night.get("player_ground_delta", INF))) > 0.75:
			failures.append("%s player did not remain grounded in both frames" % label)

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Old Quarry",
		"fixture_disclosure": "Production Meadows scene with current Terrain3D, consolidated scatter, vegetation, quarry art, player, props, gatherables and live encounters. Clear authored day/night; HUD and independent SubmersionOverlay hidden. No actor relocation, progression state, or production art mutation.",
		"complete": failures.is_empty() and records.size() == SHOTS.size() * 2,
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % OUT_DIR, FileAccess.WRITE)
	if file == null:
		failures.append("manifest could not be written")
	else:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	quit(0 if failures.is_empty() else 1)


func _capture(world: Node3D, player: Node3D, look: Node, camera: Camera3D,
		shot: Dictionary, time_name: String, records: Array[Dictionary],
		failures: Array[String]) -> Dictionary:
	_pin_clock(look, time_name)
	var stand: Vector2 = shot["stand"]
	var target: Vector2 = shot["target"]
	var toward := (target - stand).normalized()
	var eye_xz := stand - toward * float(shot["back"])
	camera.fov = float(shot["fov"])
	camera.global_position = Vector3(eye_xz.x,
		_surface(world, eye_xz, player) + float(shot["up"]), eye_xz.y)
	var target_y := float(world.call("ground_height_at", target.x, target.y))
	camera.look_at(Vector3(target.x, target_y + float(shot["aim_up"]), target.y), Vector3.UP)
	for i in 36:
		await physics_frame
	var ground := _surface(world, stand, player)
	player.global_position = Vector3(stand.x, ground + 0.30, stand.y)
	player.rotation.y = atan2(toward.x, toward.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	for i in 9:
		await physics_frame
	var terrain_surface := _surface(world, stand, player)
	var support_surface := _support_surface(world, stand, player, terrain_surface)
	var ground_delta := player.global_position.y - support_surface
	var player_on_floor := player is CharacterBody3D \
		and (player as CharacterBody3D).is_on_floor()
	_hide_overlays(world)
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var capture_problems := CAPTURE_CHECK.problems(self, camera, "clear", null, [player])
	if str(shot["label"]) in ["01-arrival", "04-cut-face"]:
		capture_problems.append_array(_readable_terrace_problems(world, camera))
	var label := "%s-%s" % [str(shot["label"]), time_name]
	if not capture_problems.is_empty():
		failures.append("%s: refused invalid quarry frame: %s" % [
			label, " | ".join(capture_problems)])
		return {
			"terrain_y": terrain_surface, "support_y": support_surface,
			"player_ground_delta": ground_delta, "player_on_floor": player_on_floor,
		}
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("%s: viewport returned no image" % label)
	elif image.save_png("%s/%s.png" % [OUT_DIR, label]) != OK:
		failures.append("%s: save_png failed" % label)
	else:
		records.append({
			"frame": label,
			"stand_xz": [stand.x, stand.y],
			"player_xyz": [player.global_position.x, player.global_position.y, player.global_position.z],
			"camera_xyz": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
			"terrain_y": terrain_surface,
			"support_y": support_surface,
			"player_ground_delta": ground_delta,
			"player_on_floor": player_on_floor,
			"image_size": [image.get_width(), image.get_height()],
		})
		print("wrote %s/%s.png" % [OUT_DIR, label])
	return {
		"terrain_y": terrain_surface, "support_y": support_surface,
		"player_ground_delta": ground_delta, "player_on_floor": player_on_floor,
	}


func _pin_clock(look: Node, time_name: String) -> void:
	look.call("apply_time", time_name)
	if look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	look.set_process(false)
	look.set_physics_process(false)


func _hide_overlays(world: Node) -> void:
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var submersion := world.get_node_or_null(^"Water/SubmersionOverlay") as CanvasLayer
	if submersion != null:
		submersion.visible = false
	for child: Node in root.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _surface(world: Node3D, at: Vector2, _player: Node3D) -> float:
	# A ground sample must never reinterpret a tree crown or prop collider as a
	# ten-metre-high camera seat. The production world's Terrain3D-backed helper
	# is the same placement authority used by the world and CaptureCheck.
	return float(world.call("ground_height_at", at.x, at.y))


func _support_surface(world: Node3D, at: Vector2, player: Node3D,
		terrain_y: float) -> float:
	# The player may legally settle on low quarry rubble or a foundation lip.
	# Sample only the short interval directly below the settled body: unlike the
	# old 200m ray, this cannot mistake a tree crown for ground, and unlike the
	# Terrain3D-only R7 receipt it measures the collision actually supporting the
	# player. Exclude the complete player subtree so the ray cannot self-hit.
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, player.global_position.y + 0.6, at.y),
		Vector3(at.x, terrain_y - 1.0, at.y))
	query.collide_with_areas = false
	var excluded: Array[RID] = []
	_collect_collision_rids(player, excluded)
	query.exclude = excluded
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	return terrain_y if hit.is_empty() else float((hit.position as Vector3).y)


func _collect_collision_rids(node: Node, out: Array[RID]) -> void:
	if node is CollisionObject3D:
		out.append((node as CollisionObject3D).get_rid())
	for child: Node in node.get_children():
		_collect_collision_rids(child, out)


func _readable_terrace_problems(world: Node3D, camera: Camera3D) -> Array[String]:
	# R9 deliberately joins the rocks into two overlapping strata. Testing each
	# rock as a separate subject made the connected face occlude itself and
	# rewarded the old six-detached-boulders composition. Prove the two authored
	# visual units instead: one rear cut and one descending working bench. Their
	# shared production cluster is excluded only from their own occlusion rays;
	# terrain, vegetation and every outside collider can still fail the frame.
	var rear_names: Array[String] = ["OldQuarryCutFaceWest",
		"OldQuarryCutFaceCentre", "OldQuarryCutFaceEast"]
	var bench_names: Array[String] = ["OldQuarryCutBenchWest",
		"OldQuarryCutBenchCentre", "OldQuarryCutSpoilEast"]
	var rear: Variant = _merged_named_aabb(world, rear_names)
	var bench: Variant = _merged_named_aabb(world, bench_names)
	if rear == null or bench == null:
		return ["connected quarry cut is missing visible rear-wall or lower-bench geometry"]
	var first := world.find_child(rear_names[0], true, false) as Node3D
	var production_cluster: Node = first.get_parent() if first != null else null
	return CAPTURE_CHECK.readable_problems_for_camera(camera, [
		{"name": "connected rear cut face", "aabb": rear as AABB,
			"body": production_cluster},
		{"name": "descending worked benches", "aabb": bench as AABB,
			"body": production_cluster},
	], {
		"min_height_frac": 0.055,
		"min_inside_frac": 0.70,
		"max_height_frac": 0.55,
		"max_overlap_frac": 0.0,
	})


func _merged_named_aabb(world: Node3D, names: Array[String]) -> Variant:
	var merged: Variant = null
	for node_name: String in names:
		var subject := world.find_child(node_name, true, false) as Node3D
		if subject == null:
			return null
		var box_value: Variant = _node_world_aabb(subject)
		if box_value == null:
			return null
		merged = (merged as AABB).merge(box_value as AABB) \
			if merged != null else box_value
	return merged


func _node_world_aabb(node: Node3D) -> Variant:
	var result: Variant = null
	if node is VisualInstance3D and node.is_visible_in_tree():
		result = node.global_transform * (node as VisualInstance3D).get_aabb()
	for child: Node in node.get_children():
		if child is Node3D:
			var child_box: Variant = _node_world_aabb(child as Node3D)
			if child_box != null:
				result = (result as AABB).merge(child_box as AABB) \
					if result != null else child_box
	return result


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
