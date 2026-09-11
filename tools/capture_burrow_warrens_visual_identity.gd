extends SceneTree

## Dedicated production proof for the post-roster-scale Burrow Warrens fix.
## Loads the shipped Meadows world and changes no world state or art. Exterior
## arrival/threshold are captured in authored day/night; the approved interior
## is only re-proven from the real hall-to-den arrival with live encounters.
##
## Windows production command (Compatibility renderer; deliberately no
## `--headless`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_burrow_warrens_visual_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/BROAD-VISUAL-0910/BURROW-WARRENS-POST-SCALE"
const READY_TIMEOUT_MS := 420_000
const APPROACH := Vector2(-328.7, 2581.7)


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
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
	var warrens := world.get_node_or_null(^"BurrowWarrens") as Node3D
	var player := world.get_node_or_null(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var weather := world.get_node_or_null(^"WorldWeather")
	var rig := world.get_node_or_null(^"CameraRig")
	if warrens == null or player == null or look == null:
		push_error("capture requires production Warrens, Player and WorldLook")
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
	look.set_process(false)
	look.set_physics_process(false)
	_hide_overlays(world)

	var entrance: Vector3 = warrens.call("marker", "entrance")
	var hall: Vector3 = warrens.call("marker", "hall")
	var guardian: Node3D = warrens.call("guardian") as Node3D
	if guardian == null:
		push_error("live Warren Guardian is missing")
		quit(1)
		return
	var outward := Vector2(entrance.x - hall.x, entrance.z - hall.z).normalized()
	var threshold := Vector2(entrance.x, entrance.z) + outward * 6.0
	var camera := Camera3D.new()
	camera.name = "BurrowWarrensVisualEvidenceCamera"
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	var arrival_grounding: Dictionary = {}
	for time_name: String in ["day", "night"]:
		arrival_grounding[time_name] = await _capture_exterior(world, warrens, player, look,
			camera, "01-arrival", APPROACH,
			Vector2(entrance.x, entrance.z), 2.0, 3.0, 2.8, 60.0, time_name, records, failures)
		await _capture_exterior(world, warrens, player, look, camera, "02-threshold", threshold,
			Vector2(entrance.x, entrance.z), 1.8, 2.8, 2.3, 62.0, time_name, records, failures)
	var day_grounding: Dictionary = arrival_grounding.get("day", {})
	var night_grounding: Dictionary = arrival_grounding.get("night", {})
	if absf(float(day_grounding.get("surface_y", INF))
			- float(night_grounding.get("surface_y", -INF))) > 0.05:
		failures.append("arrival day/night sampled different live ground surfaces")
	if absf(float(day_grounding.get("player_ground_delta", INF))) > 0.75 \
			or absf(float(night_grounding.get("player_ground_delta", INF))) > 0.75:
		failures.append("arrival player did not remain grounded in both comparison frames")

	# The interior itself is binding-approved and untouched. This is the real
	# live hall-to-den arrival used by the location capture. Reaching it on the
	# authored main route necessarily means the mouth and hall residents were
	# already beaten; stage exactly that earned state through their ordinary
	# take-damage/faint/clear lifecycle before placing the player in the hall.
	var staged_defeats := _stage_mandatory_residents_defeated(warrens)
	_pin_clock(look, "day")
	var den_floor := hall.y
	player.global_position = hall + Vector3.UP * 0.25
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	var toward_guardian := Vector2(guardian.global_position.x - hall.x,
		guardian.global_position.z - hall.z).normalized()
	player.rotation.y = atan2(toward_guardian.x, toward_guardian.y)
	camera.fov = 66.0
	camera.global_position = hall - Vector3(toward_guardian.x, 0.0, toward_guardian.y) * 1.2 \
		+ Vector3.UP * 2.65
	for i in 45:
		await physics_frame
	var guardian_height := float(guardian.call("body_height"))
	camera.look_at(guardian.global_position + Vector3.UP * guardian_height * 0.48, Vector3.UP)
	_hide_overlays(world)
	for i in 6:
		await process_frame
	await _write_frame("03-den-arrival-day", camera, player, records, failures, {
		"guardian_height_m": guardian_height,
		"guardian_distance_m": hall.distance_to(guardian.global_position),
		"hall_floor_y": den_floor,
		"earned_residents_cleared": staged_defeats,
	})

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Burrow Warrens",
		"fixture_disclosure": "Production Meadows scene with ordinary live Terrain3D, scatter, props, vegetation, player and encounters. Exterior uses authored clear day/night and resets living residents to their authored homes before each comparison frame through wild_creature.revive_at_home(), preventing the day frame's elapsed AI time from biasing the night frame. Interior environment/art/geometry is untouched. The hall-to-den frame stages the earned sequential route by applying the ordinary CreatureInstance.take_damage + wild_creature.notify_fainted/clear_faint lifecycle only to the mandatory mouth and hall residents a player must already have beaten to stand there; guardian and optional branch resident remain fully live. HUD and independent SubmersionOverlay hidden; no progression reward/clear flag injected.",
		"complete": failures.is_empty() and records.size() == 5,
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


func _reset_residents_to_authored_homes(warrens: Node3D) -> void:
	for body: Node3D in (warrens.call("population") as Array[Node3D]):
		if body != null and is_instance_valid(body) and body.has_method("revive_at_home"):
			body.call("revive_at_home")


func _stage_mandatory_residents_defeated(warrens: Node3D) -> Array[String]:
	var staged: Array[String] = []
	var population: Array[Node3D] = warrens.call("population") as Array[Node3D]
	for chamber_id: String in ["mouth", "hall"]:
		var marker: Vector3 = warrens.call("marker", chamber_id)
		var nearest: Node3D = null
		var nearest_distance := INF
		for body: Node3D in population:
			if body == null or not is_instance_valid(body) or not bool(body.call("is_alive")):
				continue
			var distance := Vector2(body.global_position.x - marker.x,
				body.global_position.z - marker.z).length()
			if distance < nearest_distance:
				nearest = body
				nearest_distance = distance
		if nearest == null:
			continue
		var creature_instance: RefCounted = nearest.get("instance") as RefCounted
		if creature_instance == null:
			continue
		creature_instance.call("take_damage", float(creature_instance.get("hp")))
		nearest.call("notify_fainted")
		nearest.call("clear_faint")
		staged.append("%s:%s" % [chamber_id, nearest.name])
	return staged


func _capture_exterior(world: Node3D, warrens: Node3D, player: Node3D, look: Node,
		camera: Camera3D, label: String, stand: Vector2, target: Vector2, back: float, up: float,
		aim_up: float, fov: float, time_name: String, records: Array[Dictionary],
		failures: Array[String]) -> Dictionary:
	_pin_clock(look, time_name)
	var toward := (target - stand).normalized()
	player.rotation.y = atan2(toward.x, toward.y)
	var eye_xz := stand - toward * back
	camera.fov = fov
	camera.global_position = Vector3(eye_xz.x, _surface(world, eye_xz, player) + up, eye_xz.y)
	var target_y := float(world.call("ground_height_at", target.x, target.y))
	camera.look_at(Vector3(target.x, target_y + aim_up, target.y), Vector3.UP)
	# Let the production terrain/collision stream follow the evidence camera
	# before seating the player. The previous ordering parked the first day frame
	# before this remote site's collision was resident, so gravity dropped it
	# 17m while the otherwise-identical night frame stayed on the live surface.
	for i in 36:
		await physics_frame
	# Reset after that camera/collision settle, not before it. Otherwise the live
	# mouth resident spends the whole settle interval advancing toward whichever
	# player pose preceded this shot and replaces the tunnel composition. This is
	# the resident's existing lifecycle/home, not actor relocation or art editing.
	_reset_residents_to_authored_homes(warrens)
	var ground := _surface(world, stand, player)
	player.global_position = Vector3(stand.x, ground + 0.30, stand.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	for i in 9:
		await physics_frame
	var seated_surface := _surface(world, stand, player)
	var ground_delta := player.global_position.y - seated_surface
	_hide_overlays(world)
	for i in 6:
		await process_frame
	await _write_frame("%s-%s" % [label, time_name], camera, player, records, failures,
		{
			"stand_xz": [stand.x, stand.y],
			"surface_y": seated_surface,
			"player_ground_delta": ground_delta,
		})
	return {"surface_y": seated_surface, "player_ground_delta": ground_delta}


func _write_frame(label: String, camera: Camera3D, player: Node3D,
		records: Array[Dictionary], failures: Array[String], extra: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("%s: viewport returned no image" % label)
		return
	var path := "%s/%s.png" % [OUT_DIR, label]
	if image.save_png(path) != OK:
		failures.append("%s: save_png failed" % label)
		return
	var record := {
		"frame": label,
		"player_xyz": [player.global_position.x, player.global_position.y, player.global_position.z],
		"camera_xyz": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
		"image_size": [image.get_width(), image.get_height()],
	}
	record.merge(extra, true)
	records.append(record)
	print("wrote %s" % path)


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


func _surface(world: Node3D, at: Vector2, player: Node3D) -> float:
	var analytic := float(world.call("ground_height_at", at.x, at.y))
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 100.0, at.y), Vector3(at.x, analytic - 100.0, at.y))
	query.collide_with_areas = false
	if player is CollisionObject3D:
		query.exclude = [(player as CollisionObject3D).get_rid()]
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	return analytic if hit.is_empty() else float((hit.position as Vector3).y)


func _wait_for_world(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await physics_frame
	return false
