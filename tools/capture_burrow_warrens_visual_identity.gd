extends SceneTree

## Dedicated production proof for the post-roster-scale Burrow Warrens fix.
## Loads the shipped Meadows world and changes no world state or art. Exterior
## arrival/threshold are captured in authored day/night; the approved interior
## is only re-proven from the real hall-to-den arrival with live encounters.
##
## Windows production command (Compatibility renderer; deliberately no
## `--headless`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_burrow_warrens_visual_identity.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-warrens-05

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const READY_TIMEOUT_MS := 420_000
const APPROACH := Vector2(-328.7, 2581.7)
const OBLIQUE_ROUTE_OFFSET_M := 12.0
const CAMERA_CLEARANCE_RADIUS_M := 0.20
const MAX_STAND_DRIFT_M := 0.45
const NIGHT_EVIDENCE_KEY_ENERGY := 2.8
const NIGHT_EVIDENCE_RIM_ENERGY := 1.6
const PLANNED_FRAMES := [
	"01-arrival-day", "02-mid-oblique-day", "03-threshold-day",
	"03a-threshold-step-day", "03b-threshold-inside-day",
	"01-arrival-night", "02-mid-oblique-night", "03-threshold-night",
	"04-den-arrival-day",
]

var _out_dir := ""
var _night_evidence_lights: Array[OmniLight3D] = []


func _init() -> void:
	_parse_args()
	_run()


func _parse_args() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(_out_dir, "Burrow Warrens capture"):
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Burrow Warrens capture requires a rendering display")
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
	var threshold_step_a := threshold.lerp(Vector2(entrance.x, entrance.z), 0.55)
	var threshold_step_b := Vector2(entrance.x, entrance.z).lerp(Vector2(hall.x, hall.z), 0.20)
	var threshold_inside_target := Vector2(entrance.x, entrance.z).lerp(
		Vector2(hall.x, hall.z), 0.45)
	var route_normal := Vector2(-outward.y, outward.x)
	var oblique := threshold.lerp(APPROACH, 0.48) + route_normal * OBLIQUE_ROUTE_OFFSET_M
	var camera := Camera3D.new()
	camera.name = "BurrowWarrensVisualEvidenceCamera"
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	_night_evidence_lights = _make_night_evidence_lights(world)
	# A downward world ray inside the throat hits the newly closed roof cap
	# before it reaches the walked floor. Use the public Warrens floor contract
	# for the true inside stand, and interpolate the short ramp step from the
	# unobstructed outer threshold to that authored floor.
	var threshold_floor := _surface(world, threshold, player)
	var threshold_step_a_floor := lerpf(threshold_floor, entrance.y, 0.55)
	var threshold_step_b_floor := float(warrens.call("built_floor_height_at",
		threshold_step_b.x, threshold_step_b.y))
	if is_nan(threshold_step_b_floor):
		push_error("inside threshold stand is outside the production Warrens floor")
		quit(1)
		return

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	var arrival_grounding: Dictionary = {}
	for time_name: String in ["day", "night"]:
		arrival_grounding[time_name] = await _capture_exterior(world, warrens, player, look,
			camera, "01-arrival", APPROACH,
			Vector2(entrance.x, entrance.z), 2.0, 3.0, 2.8, 60.0, time_name, records, failures)
		await _capture_exterior(world, warrens, player, look, camera, "02-mid-oblique", oblique,
			Vector2(entrance.x, entrance.z), 1.4, 3.2, 2.8, 58.0, time_name, records, failures, {
				"evidence_role": "facade_mid_oblique",
				"route_axis_offset_m": OBLIQUE_ROUTE_OFFSET_M,
			})
		var threshold_meta: Dictionary = {"motion_receipt_index": 0,
			"motion_receipt_count": 3} if time_name == "day" else {}
		await _capture_exterior(world, warrens, player, look, camera, "03-threshold", threshold,
			Vector2(entrance.x, entrance.z), 1.8, 2.8, 2.3, 62.0, time_name,
			records, failures, threshold_meta)
		# A short three-position receipt (03 plus these two day frames) crosses
		# the outer brow and seats just inside the throat. A cap seam that flickers
		# or opens only in motion cannot hide behind one favourable threshold still.
		if time_name == "day":
			await _capture_exterior(world, warrens, player, look, camera,
				"03a-threshold-step", threshold_step_a,
				Vector2(entrance.x, entrance.z), 0.65, 1.58, 1.30, 68.0, time_name,
				records, failures, {"motion_receipt_index": 1, "motion_receipt_count": 3}, {
					"floor_y": threshold_step_a_floor,
					"eye_floor_y": threshold_step_a_floor,
					"target_floor_y": entrance.y,
					"require_camera_clearance": true,
				})
			await _capture_exterior(world, warrens, player, look, camera,
				"03b-threshold-inside", threshold_step_b,
				threshold_inside_target, 0.65, 1.58, 1.35, 70.0, time_name,
				records, failures, {"motion_receipt_index": 2, "motion_receipt_count": 3}, {
					"floor_y": threshold_step_b_floor,
					"eye_floor_y": threshold_step_b_floor,
					"target_floor_y": threshold_step_b_floor,
					"require_camera_clearance": true,
				})
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
	_set_night_evidence_lights(camera, entrance, false)
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
	await _write_frame("04-den-arrival-day", camera, player, records, failures, {
		"guardian_height_m": guardian_height,
		"guardian_distance_m": hall.distance_to(guardian.global_position),
		"hall_floor_y": den_floor,
		"earned_residents_cleared": staged_defeats,
	})

	var complete := failures.is_empty() and records.size() == PLANNED_FRAMES.size()
	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Burrow Warrens",
		"output_directory": _out_dir,
		"expected_frame_count": PLANNED_FRAMES.size(),
		"captured_frame_count": records.size(),
		"planned_frames": PLANNED_FRAMES,
		"fixture_disclosure": "Production Meadows scene with ordinary live Terrain3D, scatter, props, vegetation, player and encounters. Exterior uses authored clear day/night and resets living residents to their authored homes before each comparison frame through wild_creature.revive_at_home(), preventing the day frame's elapsed AI time from biasing the night frame. Night exterior frames use bounded capture-only key/rim evidence lights around the facade so brow, roots, threshold walls and traveled floor remain judgeable; production materials, art and world lighting are unchanged. Frames 03/03a/03b are a sequential outside-to-inside day threshold receipt at three player-height positions. The two inside-throat stands use the Warrens' authored built floor instead of a downward ray that can hit the closed roof cap, and require a collision-clear camera eye; no world geometry or collision is altered by the harness. Interior environment/art/geometry is untouched. The hall-to-den frame stages the earned sequential route by applying the ordinary CreatureInstance.take_damage + wild_creature.notify_fainted/clear_faint lifecycle only to the mandatory mouth and hall residents a player must already have beaten to stand there; guardian and optional branch resident remain fully live. HUD and independent SubmersionOverlay hidden; no progression reward/clear flag injected.",
		"complete": complete,
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if file == null:
		failures.append("manifest could not be written")
		complete = false
	else:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	quit(0 if complete else 1)


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
		failures: Array[String], evidence_meta: Dictionary = {}, framing: Dictionary = {}) -> Dictionary:
	_pin_clock(look, time_name)
	var toward := (target - stand).normalized()
	player.rotation.y = atan2(toward.x, toward.y)
	var eye_xz := stand - toward * back
	var floor_override := float(framing.get("floor_y", NAN))
	var eye_floor_override := float(framing.get("eye_floor_y", NAN))
	var target_floor_override := float(framing.get("target_floor_y", NAN))
	var eye_floor := _surface(world, eye_xz, player) if is_nan(eye_floor_override) \
		else eye_floor_override
	camera.fov = fov
	camera.global_position = Vector3(eye_xz.x, eye_floor + up, eye_xz.y)
	var target_y := float(world.call("ground_height_at", target.x, target.y)) \
		if is_nan(target_floor_override) else target_floor_override
	var aim := Vector3(target.x, target_y + aim_up, target.y)
	camera.look_at(aim, Vector3.UP)
	_set_night_evidence_lights(camera, aim, time_name == "night")
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
	var ground := _surface(world, stand, player) if is_nan(floor_override) else floor_override
	player.global_position = Vector3(stand.x, ground + 0.30, stand.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	for i in 9:
		await physics_frame
	var seated_surface := _surface(world, stand, player) if is_nan(floor_override) else floor_override
	var ground_delta := player.global_position.y - seated_surface
	var seated_xz := Vector2(player.global_position.x, player.global_position.z)
	var stand_drift := seated_xz.distance_to(stand)
	if stand_drift > MAX_STAND_DRIFT_M:
		failures.append("%s-%s: player drifted %.2fm from the authored stand" % [
			label, time_name, stand_drift])
	if absf(ground_delta) > 0.75:
		failures.append("%s-%s: player is %.2fm from the authored floor" % [
			label, time_name, ground_delta])
	var camera_clear := _camera_eye_clear(world, camera.global_position, player)
	if bool(framing.get("require_camera_clearance", false)) and not camera_clear:
		failures.append("%s-%s: evidence camera intersects production collision" % [
			label, time_name])
	_hide_overlays(world)
	for i in 6:
		await process_frame
	var frame_meta := {
		"stand_xz": [stand.x, stand.y],
		"surface_y": seated_surface,
		"player_ground_delta": ground_delta,
		"player_stand_drift_m": stand_drift,
		"camera_eye_clear": camera_clear,
		"capture_evidence_light": time_name == "night",
	}
	frame_meta.merge(evidence_meta, true)
	await _write_frame("%s-%s" % [label, time_name], camera, player, records, failures,
		frame_meta)
	return {"surface_y": seated_surface, "player_ground_delta": ground_delta}


func _write_frame(label: String, camera: Camera3D, player: Node3D,
		records: Array[Dictionary], failures: Array[String], extra: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("%s: viewport returned no image" % label)
		return
	var path := "%s/%s.png" % [_out_dir, label]
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


func _make_night_evidence_lights(world: Node3D) -> Array[OmniLight3D]:
	var lights: Array[OmniLight3D] = []
	for spec: Dictionary in [
			{"name": "WarrensEvidenceKey", "colour": Color("ffd1a3"), "range": 14.0},
			{"name": "WarrensEvidenceRim", "colour": Color("9fc4ef"), "range": 11.0},
	]:
		var light := OmniLight3D.new()
		light.name = str(spec.name)
		var colour: Color = spec.get("colour", Color.WHITE)
		light.light_color = colour
		light.omni_range = float(spec.range)
		light.light_energy = 0.0
		light.shadow_enabled = false
		world.add_child(light)
		lights.append(light)
	return lights


func _set_night_evidence_lights(camera: Camera3D, subject: Vector3, enabled: bool) -> void:
	if _night_evidence_lights.size() != 2:
		return
	var from_subject := camera.global_position - subject
	var horizontal := Vector3(from_subject.x, 0.0, from_subject.z).normalized()
	if horizontal.is_zero_approx():
		horizontal = Vector3.FORWARD
	var side := Vector3.UP.cross(horizontal).normalized()
	_night_evidence_lights[0].global_position = subject + horizontal * 3.2 \
		+ side * 2.2 + Vector3.UP * 3.4
	_night_evidence_lights[1].global_position = subject - horizontal * 2.0 \
		- side * 3.0 + Vector3.UP * 2.3
	_night_evidence_lights[0].light_energy = NIGHT_EVIDENCE_KEY_ENERGY if enabled else 0.0
	_night_evidence_lights[1].light_energy = NIGHT_EVIDENCE_RIM_ENERGY if enabled else 0.0


func _camera_eye_clear(world: Node3D, eye: Vector3, player: Node3D) -> bool:
	var sphere := SphereShape3D.new()
	sphere.radius = CAMERA_CLEARANCE_RADIUS_M
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, eye)
	query.collide_with_areas = false
	if player is CollisionObject3D:
		query.exclude = [(player as CollisionObject3D).get_rid()]
	return world.get_world_3d().direct_space_state.intersect_shape(query, 8).is_empty()


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
