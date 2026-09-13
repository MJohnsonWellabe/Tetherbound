extends SceneTree

## Dedicated current-production proof for The Old Quarry after the creature-scale
## and consolidated Meadows scatter passes. Does not edit world state, actors,
## quarry art, or the generic location harness.
##
## Windows production command (Compatibility renderer; deliberately no headless):
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_old_quarry_visual_identity.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/MEADOWS-0912/OLD-QUARRY-TERRACE-R28"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const READY_TIMEOUT_MS := 420_000
const CAMERA_SETTLE_PHYSICS_FRAMES := 36
const R27_FACE_NAMES: Array[String] = ["WorkedFaceWest", "WorkedFaceMidWest",
	"WorkedFaceMidEast", "WorkedFaceEast"]
const R27_COURSE_NAMES: Array[String] = ["StrataCourseUpperWest",
	"StrataCourseUpperEast", "StrataCourseLowerWest", "StrataCourseLowerEast"]
const R27_BENCH_NAMES: Array[String] = ["WorkedBenchWest", "WorkedBenchEast",
	"WorkedBenchToe"]
const R27_WAGON_APRON_NAMES: Array[String] = ["HaulApronUpper", "HaulApronLower"]
const R27_CONDUIT_APRON_NAMES: Array[String] = ["ConduitApronInner", "ConduitApronHead"]
# Conservative measured south/front limits of the four retained collision masses,
# ordered west-to-east. R27 visual faces must project beyond these, never hide in them.
const R27_RETAINED_COLLISION_SOUTH_Z: Array[float] = [1800.0, 1799.0, 1798.0, 1796.5]
const REQUIRED_FRAME_LABELS: Array[String] = [
	"01-arrival-day", "02-worked-floor-day", "03-conduit-head-day", "04-cut-face-day",
	"01-arrival-night", "02-worked-floor-night", "03-conduit-head-night", "04-cut-face-night",
]
const ARRIVAL_CAMERA_CANDIDATES := [
	{
		# R15 proved the lower incoming-road positions genuinely cannot see the
		# descending benches: every live upper/outer ray met Terrain. These fixed
		# positions advance to the late approach/threshold on the same authored
		# 310,1660 -> 400,1800 spine. R27 keeps R26's honest grounded composition;
		# its repair moves the art onto the camera-facing collision side. Keep the
		# targets, but pull the lens back along that same road vector for an honest
		# establishing view; projected/crop and live-ray bars remain unchanged.
		"candidate_id": "late-spine-threshold",
		"label": "01-arrival", "stand": Vector2(391.0, 1786.0),
		"target": Vector2(388.0, 1804.0), "back": 22.0, "up": 4.0,
		"aim_up": 1.8, "fov": 100.0,
	},
	{
		"candidate_id": "late-west-threshold",
		"label": "01-arrival", "stand": Vector2(389.0, 1787.0),
		"target": Vector2(387.0, 1804.0), "back": 22.0, "up": 4.0,
		"aim_up": 1.8, "fov": 100.0,
	},
	{
		"candidate_id": "late-east-threshold",
		"label": "01-arrival", "stand": Vector2(395.0, 1792.0),
		"target": Vector2(389.0, 1804.0), "back": 22.0, "up": 4.0,
		"aim_up": 1.8, "fov": 100.0,
	},
]
const SHOTS := [
	{
		# The proven late-west threshold is a real grounded production seat. The
		# floor lens stays on its open south side and looks past the retained wagon
		# toward the west apron and first bench.
		"label": "02-worked-floor", "stand": Vector2(389.0, 1787.0),
		"target": Vector2(390.0, 1797.0), "back": 6.0, "up": 3.2,
		"aim_up": 0.85, "fov": 90.0,
	},
	{
		# The same reachable threshold seat turns toward the conduit head. The wide
		# lens keeps the diagonal cut at frame left without putting the camera
		# behind the east rock collider as R20/R21 did.
		"label": "03-conduit-head", "stand": Vector2(389.0, 1787.0),
		"target": Vector2(394.0, 1802.0), "back": 7.0, "up": 3.4,
		"aim_up": 1.65, "fov": 105.0,
	},
	{
		# A tighter west/centre read from the same player-safe seat proves the face
		# and courses from their exposed side. It remains a normal ground-level
		# view rather than the rejected north/east beauty camera.
		"label": "04-cut-face", "stand": Vector2(389.0, 1787.0),
		"target": Vector2(382.0, 1792.0), "back": 16.0, "up": 3.5,
		"aim_up": 2.0, "fov": 92.0,
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
	_pin_clock(look, "day")
	for i in 36:
		await physics_frame
	var arrival_selection := await _select_arrival_camera(world, player, camera)
	var shots: Array = SHOTS.duplicate(true)
	if arrival_selection.has("shot"):
		shots.push_front(arrival_selection["shot"])
	else:
		failures.append("no fixed production-road arrival camera passed live occlusion/readability checks")
	var grounding: Dictionary = {}
	for time_name: String in ["day", "night"]:
		grounding[time_name] = {}
		for shot: Dictionary in shots:
			var result := await _capture(world, player, look, camera, shot, time_name,
				records, failures)
			(grounding[time_name] as Dictionary)[str(shot["label"])] = result
	for shot: Dictionary in shots:
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
	_require_exact_frame_set(records, failures)
	var geometry_receipt := _worked_cut_receipt(world)
	if geometry_receipt.get("piece_count", 0) != 15:
		failures.append("R27 production worked cut did not instantiate all 15 defining pieces")
	failures.append_array(_r27_layout_problems(world))

	var manifest := {
		"production_scene": SCENE,
		"named_location": "The Old Quarry",
		"fixture_disclosure": "Production Meadows scene with current Terrain3D, consolidated scatter, vegetation, quarry art, player, props, gatherables and live encounters. Clear authored day/night; HUD and independent SubmersionOverlay hidden. Every fixed seat grounds the real production player before the normal settle, rejects a camera inside production collision, and requires projected bounds plus rays to the actual camera-facing mesh surfaces. No world art, collisions, scene visibility, lighting or progression state is changed for selection.",
		"selection_streaming_anchor": "production Player grounded at candidate stand before settle",
		"camera_settle_physics_frames": CAMERA_SETTLE_PHYSICS_FRAMES,
		"arrival_camera_selection": arrival_selection.get("receipt", {}),
		"required_frame_labels": REQUIRED_FRAME_LABELS,
		"worked_cut_geometry": geometry_receipt,
		"complete": failures.is_empty() and arrival_selection.has("shot") \
			and records.size() == shots.size() * 2,
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


func _select_arrival_camera(world: Node3D, player: Node3D,
		camera: Camera3D) -> Dictionary:
	# This is selection, not repair-by-mutation: candidates are serialized
	# production road lenses and the world is untouched while they are tested.
	# Candidate order is stable, so the same production seed chooses the same eye.
	var rejected: Array[Dictionary] = []
	for raw_candidate: Dictionary in ARRIVAL_CAMERA_CANDIDATES:
		var candidate := raw_candidate.duplicate(true)
		_pose_camera(world, player, camera, candidate)
		_place_player_for_shot(world, player, candidate)
		# Match the shutter's full settle interval. Terrain3D/scatter collisions
		# follow the production player, not this evidence camera. Moving and
		# grounding that real player before this wait makes the candidate's scatter
		# resident before any lens can be certified.
		for i in CAMERA_SETTLE_PHYSICS_FRAMES:
			await physics_frame
		await RenderingServer.frame_post_draw
		var problems := CAPTURE_CHECK.problems(self, camera, "clear", null, [player])
		problems.append_array(_readable_terrace_problems(world, camera))
		problems.append_array(_r27_worked_cut_problems(world, camera, "01-arrival"))
		var receipt := {
			"candidate_id": str(candidate["candidate_id"]),
			"stand_xz": [candidate["stand"].x, candidate["stand"].y],
			"target_xz": [candidate["target"].x, candidate["target"].y],
			"camera_xyz": [camera.global_position.x, camera.global_position.y,
				camera.global_position.z],
			"problems": problems,
		}
		if problems.is_empty():
			return {"shot": candidate, "receipt": {
				"selected": receipt, "rejected_before_selection": rejected,
			}}
		rejected.append(receipt)
	return {"receipt": {"selected": {}, "rejected_before_selection": rejected}}


func _capture(world: Node3D, player: Node3D, look: Node, camera: Camera3D,
		shot: Dictionary, time_name: String, records: Array[Dictionary],
		failures: Array[String]) -> Dictionary:
	_pin_clock(look, time_name)
	var stand: Vector2 = shot["stand"]
	_pose_camera(world, player, camera, shot)
	_place_player_for_shot(world, player, shot)
	for i in CAMERA_SETTLE_PHYSICS_FRAMES:
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
	var shot_label := str(shot["label"])
	if shot_label in ["01-arrival", "04-cut-face"]:
		capture_problems.append_array(_readable_terrace_problems(world, camera))
	if shot_label in ["01-arrival", "02-worked-floor", "03-conduit-head", "04-cut-face"]:
		capture_problems.append_array(_r27_worked_cut_problems(world, camera, shot_label))
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


func _pose_camera(world: Node3D, player: Node3D, camera: Camera3D,
		shot: Dictionary) -> void:
	var stand: Vector2 = shot["stand"]
	var target: Vector2 = shot["target"]
	var toward := (target - stand).normalized()
	var eye_xz := stand - toward * float(shot["back"])
	camera.fov = float(shot["fov"])
	camera.global_position = Vector3(eye_xz.x,
		_surface(world, eye_xz, player) + float(shot["up"]), eye_xz.y)
	var target_y := float(world.call("ground_height_at", target.x, target.y))
	camera.look_at(Vector3(target.x, target_y + float(shot["aim_up"]), target.y), Vector3.UP)


func _place_player_for_shot(world: Node3D, player: Node3D,
		shot: Dictionary) -> void:
	# The production scatter streamer follows the real player. Selection and
	# shutter setup must therefore place the same player at the same grounded
	# stand before their shared settle interval; moving only the camera proves
	# nothing about the collisions that will exist when the frame is captured.
	var stand: Vector2 = shot["stand"]
	var target: Vector2 = shot["target"]
	var toward := (target - stand).normalized()
	var ground := _surface(world, stand, player)
	player.global_position = Vector3(stand.x, ground + 0.30, stand.y)
	player.rotation.y = atan2(toward.x, toward.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.reset_physics_interpolation()


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
	# R13 frames R12's two densely overlapping strata. The merged boxes remain
	# the composition authority: both authored visual units must be in frame,
	# large enough to read, and not cropped. Do not use a merged box's centre for
	# occlusion, though: the descending benches' centre is below the irregular
	# rock surfaces, so a clear formation can be falsely reported behind Terrain.
	# R15 separately samples upper/outer points on every named live piece and
	# requires clear rays across multiple pieces. The production cluster is
	# excluded only from those rays; terrain, vegetation, and outside colliders
	# still block a genuinely hidden face.
	var rear_names: Array[String] = ["OldQuarryCutFaceWest",
		"OldQuarryCutFaceMidWest", "OldQuarryCutFaceCentre",
		"OldQuarryCutFaceMidEast", "OldQuarryCutFaceEast"]
	# R27's rebuilt projecting benches are the visible working levels now under
	# review. The retained rock bench collision remains untouched and excluded
	# only as the physical substrate; it cannot certify hidden replacement art.
	var bench_names: Array[String] = R27_BENCH_NAMES.duplicate()
	var rear: Variant = _merged_named_aabb(world, rear_names)
	var bench: Variant = _merged_named_aabb(world, bench_names)
	if rear == null or bench == null:
		return ["connected quarry cut is missing visible rear-wall or lower-bench geometry"]
	var problems := CAPTURE_CHECK.readable_problems_for_camera(camera, [
		{"name": "connected rear cut face", "aabb": rear as AABB,
			"body": null},
		{"name": "descending worked benches", "aabb": bench as AABB,
			"body": null},
	], {
		"min_height_frac": 0.055,
		"min_inside_frac": 0.70,
		# Keep a 5-point buffer below the former 55% close-up ceiling so small
		# projection changes cannot turn a technically green frame into a crop.
		"max_height_frac": 0.50,
		"max_overlap_frac": 0.0,
		# Occlusion is checked against per-piece surface samples below. Passing a
		# null space here preserves every projected-bounds check in the helper.
		"space": null,
	})
	problems.append_array(_stratum_visibility_problems(world, camera,
		rear_names, "connected rear cut face"))
	problems.append_array(_stratum_visibility_problems(world, camera,
		bench_names, "descending worked benches"))
	return problems


## R27 is not certified by node presence. Every interior and cut-face frame must
## contain the faceted extraction wound and both physical handoffs, while live
## surface rays prove that faces, thick strata, benches and aprons are not hidden.
func _r27_worked_cut_problems(world: Node3D, camera: Camera3D,
		shot_label: String) -> Array[String]:
	var face_and_courses: Array[String] = R27_FACE_NAMES.duplicate()
	face_and_courses.append_array(R27_COURSE_NAMES)
	var floor_and_apron: Array[String] = R27_BENCH_NAMES.duplicate()
	floor_and_apron.append_array(R27_WAGON_APRON_NAMES)
	floor_and_apron.append_array(R27_CONDUIT_APRON_NAMES)
	var face: Variant = _merged_named_aabb(world, face_and_courses)
	var floor_handoff: Variant = _merged_named_aabb(world, floor_and_apron)
	if face == null or floor_handoff == null:
		return ["R27 worked cut is missing faceted face/strata or bench/apron geometry"]
	var readability_subjects: Array[Dictionary] = [
		{"name": "R27 concave extraction face and thick strata", "aabb": face as AABB,
			"body": null},
	]
	# The cut-face close read proves wall and benches. The two broader floor and
	# conduit frames remain solely responsible for the complete wagon handoff.
	if shot_label != "04-cut-face":
		readability_subjects.append({"name": "R27 bench-to-wagon/conduit handoff",
			"aabb": floor_handoff as AABB, "body": null})
	var problems := CAPTURE_CHECK.readable_problems_for_camera(camera, readability_subjects, {
		"min_height_frac": 0.04,
		"min_inside_frac": 0.55,
		"max_height_frac": 0.62,
		"max_overlap_frac": 0.0,
		"space": null,
	})
	problems.append_array(_stratum_visibility_problems(world, camera,
		R27_FACE_NAMES, "R27 faceted extraction faces", true))
	problems.append_array(_stratum_visibility_problems(world, camera,
		R27_COURSE_NAMES, "R27 thick worked strata", true))
	problems.append_array(_stratum_visibility_problems(world, camera,
		R27_BENCH_NAMES, "R27 projecting working benches", true))
	if shot_label != "04-cut-face":
		problems.append_array(_stratum_visibility_problems(world, camera,
			R27_WAGON_APRON_NAMES, "R27 floor-to-wagon apron", true))
		problems.append_array(_stratum_visibility_problems(world, camera,
			R27_CONDUIT_APRON_NAMES, "R27 floor-to-conduit apron", true))
	return problems


func _stratum_visibility_problems(world: Node3D, camera: Camera3D,
		names: Array[String], label: String, exact_mesh_surface := false) -> Array[String]:
	var pieces: Array[Dictionary] = []
	var cluster: Node = null
	for node_name: String in names:
		var piece := world.find_child(node_name, true, false) as Node3D
		if piece == null:
			return ["%s is missing named production piece '%s'" % [label, node_name]]
		var raw_box: Variant = _node_world_aabb(piece)
		if raw_box == null:
			return ["%s piece '%s' has no visible live geometry" % [label, node_name]]
		pieces.append({"name": node_name, "aabb": raw_box as AABB, "node": piece})
		if cluster == null:
			cluster = piece.get_parent()

	var excluded: Array[RID] = []
	if cluster != null:
		_collect_collision_rids(cluster, excluded)
	var clear_samples := 0
	var visible_pieces := 0
	var total_samples := 0
	var blocker_counts: Dictionary = {}
	var space := world.get_world_3d().direct_space_state
	for piece: Dictionary in pieces:
		var box: AABB = piece["aabb"]
		var piece_visible := false
		var targets := _camera_facing_mesh_samples(piece["node"] as Node3D, camera) \
			if exact_mesh_surface else _upper_outer_samples(box)
		for target: Vector3 in targets:
			total_samples += 1
			var query := PhysicsRayQueryParameters3D.create(camera.global_position, target)
			query.exclude = excluded
			query.collide_with_areas = false
			var hit: Dictionary = space.intersect_ray(query)
			var clear := hit.is_empty()
			if not clear:
				var hit_at: Vector3 = hit.get("position", target)
				# Terrain may meet the base of an exposed irregular rock. A hit only
				# counts as reaching the sample when it is within a small surface
				# tolerance; terrain metres in front remains an occluder.
				clear = hit_at.distance_to(target) <= 0.30
			if clear:
				clear_samples += 1
				piece_visible = true
			else:
				var collider: Variant = hit.get("collider")
				var blocker: String = (collider as Node).name if collider is Node else "unnamed geometry"
				blocker_counts[blocker] = int(blocker_counts.get(blocker, 0)) + 1
		if piece_visible:
			visible_pieces += 1

	# Three points per piece are sampled. Requiring at least one quarter of all
	# rays and at least two distinct pieces prevents a single exposed rock tip
	# from certifying a formation that vegetation or terrain otherwise hides.
	var required_samples := maxi(3, ceili(float(total_samples) * 0.25))
	if clear_samples >= required_samples and visible_pieces >= 2:
		return []
	var blockers: Array[String] = []
	for blocker: Variant in blocker_counts:
		blockers.append("%s:%d" % [str(blocker), int(blocker_counts[blocker])])
	blockers.sort()
	return [("'%s' has only %d/%d clear camera-facing mesh-face rays across %d/%d " +
		"named pieces (needs %d rays across 2 pieces); blockers: %s") % [
		label, clear_samples, total_samples, visible_pieces, pieces.size(),
		required_samples, ", ".join(blockers)]]


func _camera_facing_mesh_samples(node: Node3D, camera: Camera3D) -> Array[Vector3]:
	# R26 originally called this exact mesh-surface proof but selected three
	# points on a mesh AABB face. Those points can be metres off an irregular
	# wedge and made the retained sibling collision look like an occluder. Read
	# the live render surface arrays instead. Every returned target is the exact
	# centroid of a real triangle; no collision proxy or AABB point can pass here.
	var mesh_instance := node as MeshInstance3D
	if mesh_instance == null or mesh_instance.mesh == null:
		return []
	var candidates: Array[Dictionary] = []
	for surface_index in mesh_instance.mesh.get_surface_count():
		var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
		if arrays.size() <= Mesh.ARRAY_INDEX:
			continue
		var raw_vertices: Variant = arrays[Mesh.ARRAY_VERTEX]
		if not raw_vertices is PackedVector3Array:
			continue
		var vertices := raw_vertices as PackedVector3Array
		var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
		var indices := raw_indices as PackedInt32Array \
			if raw_indices is PackedInt32Array else PackedInt32Array()
		var corner_count := indices.size() if not indices.is_empty() else vertices.size()
		for first_corner in range(0, corner_count - 2, 3):
			var ia := indices[first_corner] if not indices.is_empty() else first_corner
			var ib := indices[first_corner + 1] if not indices.is_empty() else first_corner + 1
			var ic := indices[first_corner + 2] if not indices.is_empty() else first_corner + 2
			if ia < 0 or ib < 0 or ic < 0 or ia >= vertices.size() \
					or ib >= vertices.size() or ic >= vertices.size():
				continue
			var a := mesh_instance.global_transform * vertices[ia]
			var b := mesh_instance.global_transform * vertices[ib]
			var c := mesh_instance.global_transform * vertices[ic]
			var crossed := (b - a).cross(c - a)
			if crossed.length_squared() <= 0.000001:
				continue
			var point := (a + b + c) / 3.0
			var to_camera := camera.global_position - point
			if to_camera.length_squared() <= 0.000001:
				continue
			# Imported/generated winding differs between PrimitiveMesh and
			# SurfaceTool surfaces. Absolute alignment identifies faces oriented
			# toward the ray; distance then chooses the near member of an opposed
			# pair. A far face stays honest: its ray hits the near collision first.
			var alignment := absf(crossed.normalized().dot(to_camera.normalized()))
			if alignment < 0.12:
				continue
			candidates.append({
				"point": point,
				"score": alignment * 4.0 - to_camera.length() * 0.002,
			})
	candidates.sort_custom(_mesh_sample_score_descending)
	var result: Array[Vector3] = []
	var separation := maxf(mesh_instance.global_transform.basis.get_scale().length() * 0.08, 0.08)
	for candidate: Dictionary in candidates:
		var point := candidate["point"] as Vector3
		var separated := true
		for accepted: Vector3 in result:
			if accepted.distance_to(point) < separation:
				separated = false
				break
		if separated:
			result.append(point)
		if result.size() == 3:
			break
	return result


func _mesh_sample_score_descending(a: Dictionary, b: Dictionary) -> bool:
	return float(a["score"]) > float(b["score"])


func _require_exact_frame_set(records: Array[Dictionary], failures: Array[String]) -> void:
	var counts := {}
	for record: Dictionary in records:
		var label := str(record.get("frame", ""))
		counts[label] = int(counts.get(label, 0)) + 1
	for label: String in REQUIRED_FRAME_LABELS:
		if int(counts.get(label, 0)) != 1:
			failures.append("required production frame '%s' has count %d, expected exactly 1" % [
				label, int(counts.get(label, 0))])
	for label: Variant in counts:
		if not str(label) in REQUIRED_FRAME_LABELS:
			failures.append("unexpected production frame '%s' is not part of the R27 proof" % str(label))


## Projection alone let R25 certify a large rectangular bunker. R27 also pins
## the authored shape and both physical story handoffs before evidence can be
## complete: bowed face in plan, broken crown, thick benches, wagon apron and
## conduit apron. These are measured from live production nodes after streaming.
func _r27_layout_problems(world: Node3D) -> Array[String]:
	var problems: Array[String] = []
	var face_centres: Array[Vector3] = []
	var crown_heights: Array[float] = []
	for face_index in R27_FACE_NAMES.size():
		var node_name: String = R27_FACE_NAMES[face_index]
		var node := world.find_child(node_name, true, false) as MeshInstance3D
		var box_value: Variant = _node_world_aabb(node) if node != null else null
		if node == null or box_value == null:
			problems.append("R27 concave face is missing %s" % node_name)
			continue
		if not node.mesh is ArrayMesh:
			problems.append("R27 face %s regressed to a rectangular box" % node_name)
		var box := box_value as AABB
		if box.position.z > R27_RETAINED_COLLISION_SOUTH_Z[face_index] - 1.25:
			problems.append("R27 face %s is not decisively camera-side of retained collision" % node_name)
		face_centres.append(box.get_center())
		crown_heights.append(box.end.y)
	if face_centres.size() == R27_FACE_NAMES.size():
		if face_centres[1].z <= face_centres[0].z + 0.45 \
				or face_centres[1].z <= face_centres[3].z + 0.75:
			problems.append("R27 face contour is not concave into the retained hillside")
	if crown_heights.size() == R27_FACE_NAMES.size():
		var crown_range: float = crown_heights.max() - crown_heights.min()
		if crown_range < 0.75:
			problems.append("R27 face crown is too level to read as broken excavation")

	for node_name: String in R27_COURSE_NAMES + R27_BENCH_NAMES:
		var node := world.find_child(node_name, true, false) as MeshInstance3D
		if node == null or not node.mesh is ArrayMesh:
			problems.append("R27 worked ledge %s is absent or box-like" % node_name)
			continue
		var box_value: Variant = _node_world_aabb(node)
		if box_value == null or (box_value as AABB).size.y < 0.36 \
				or minf((box_value as AABB).size.x, (box_value as AABB).size.z) < 1.85:
			problems.append("R27 worked ledge %s is too thin to carry quarry activity" % node_name)

	var wagon_chain: Array[String] = ["WorkedBenchToe", "HaulApronUpper", "HaulApronLower"]
	problems.append_array(_continuous_plan_chain_problems(world, wagon_chain,
		Vector2(399.0, 1787.5), 3.8, "wagon"))
	var conduit_chain: Array[String] = ["WorkedFaceEast", "ConduitApronInner", "ConduitApronHead"]
	problems.append_array(_continuous_plan_chain_problems(world, conduit_chain,
		Vector2(404.0, 1804.0), 7.8, "conduit head"))
	return problems


func _continuous_plan_chain_problems(world: Node3D, names: Array[String], endpoint: Vector2,
		max_gap: float, label: String) -> Array[String]:
	var points: Array[Vector2] = []
	for node_name: String in names:
		var node := world.find_child(node_name, true, false) as Node3D
		if node == null:
			return ["R27 %s handoff is missing %s" % [label, node_name]]
		points.append(Vector2(node.global_position.x, node.global_position.z))
	points.append(endpoint)
	for i in points.size() - 1:
		if points[i].distance_to(points[i + 1]) > max_gap:
			return ["R27 %s handoff breaks between %s and its next beat" % [label, names[i]]]
	return []


func _worked_cut_receipt(world: Node3D) -> Dictionary:
	var names: Array[String] = []
	names.append_array(R27_FACE_NAMES)
	names.append_array(R27_COURSE_NAMES)
	names.append_array(R27_BENCH_NAMES)
	names.append_array(R27_WAGON_APRON_NAMES)
	names.append_array(R27_CONDUIT_APRON_NAMES)
	var pieces: Array[Dictionary] = []
	for node_name: String in names:
		var node := world.find_child(node_name, true, false) as Node3D
		var box_value: Variant = _node_world_aabb(node) if node != null else null
		if node == null or box_value == null:
			continue
		var box := box_value as AABB
		pieces.append({"name": node_name,
			"centre_xyz": [box.get_center().x, box.get_center().y, box.get_center().z],
			"size_xyz": [box.size.x, box.size.y, box.size.z]})
	return {"piece_count": pieces.size(), "pieces": pieces}


func _upper_outer_samples(box: AABB) -> Array[Vector3]:
	# Pull slightly inward from the mathematical AABB edges so rays test the
	# visible crown/shoulders rather than empty space just beyond an irregular
	# mesh. Each live per-node AABB contributes a crown and two outer shoulders.
	var centre := box.get_center()
	var inset_x := box.size.x * 0.18
	var inset_z := box.size.z * 0.18
	var upper_y := box.end.y - maxf(0.08, box.size.y * 0.10)
	return [
		Vector3(centre.x, upper_y, centre.z),
		Vector3(box.position.x + inset_x, upper_y, box.position.z + inset_z),
		Vector3(box.end.x - inset_x, upper_y, box.end.z - inset_z),
	]


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
