extends SceneTree

## Dedicated production proof for the post-roster-scale Burrow Warrens fix.
## Loads the shipped Meadows world and changes no world state or art. Exterior
## arrival/threshold are captured in authored day/night; the R51 world finish
## finish is proven from the real hall-to-den arrival with live encounters.
##
## Windows production command (Compatibility renderer; deliberately no
## `--headless`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_burrow_warrens_visual_identity.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-warrens-51

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const READY_TIMEOUT_MS := 900_000
const APPROACH := Vector2(-328.7, 2581.7)
const OBLIQUE_ROUTE_OFFSET_M := 6.0
const CAMERA_CLEARANCE_RADIUS_M := 0.20
const MAX_STAND_DRIFT_M := 0.45
const REMOTE_COLLISION_WARMUP_FRAMES := 120
const COMPANION_FORMATION_SETTLE_FRAMES := 36
const THRESHOLD_STEP_A_STAND_CALIBRATION := Vector2(0.50, -0.10)
const NIGHT_EVIDENCE_KEY_ENERGY := 4.8
const NIGHT_EVIDENCE_RIM_ENERGY := 2.8
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
	var threshold_step_a := threshold.lerp(Vector2(entrance.x, entrance.z), 0.55) \
		+ THRESHOLD_STEP_A_STAND_CALIBRATION
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
			Vector2(entrance.x, entrance.z), 1.4, 4.0, 2.8, 58.0, time_name, records, failures, {
				"evidence_role": "facade_mid_oblique",
				"route_axis_offset_m": OBLIQUE_ROUTE_OFFSET_M,
			})
		var threshold_meta: Dictionary = {"motion_receipt_index": 0,
			"motion_receipt_count": 3} if time_name == "day" else {}
		await _capture_exterior(world, warrens, player, look, camera, "03-threshold", threshold,
			Vector2(entrance.x, entrance.z), 0.40, 2.35, 1.75, 68.0, time_name,
			records, failures, threshold_meta)
		# A short three-position receipt (03 plus these two day frames) crosses
		# the outer brow and seats just inside the throat. A cap seam that flickers
		# or opens only in motion cannot hide behind one favourable threshold still.
		if time_name == "day":
			await _capture_exterior(world, warrens, player, look, camera,
				"03a-threshold-step", threshold_step_a,
				Vector2(entrance.x, entrance.z), -0.55, 1.75, 1.45, 72.0, time_name,
				records, failures, {"motion_receipt_index": 1, "motion_receipt_count": 3}, {
					"floor_y": threshold_step_a_floor,
					"eye_floor_y": threshold_step_a_floor,
					"target_floor_y": entrance.y,
					"require_camera_clearance": true,
				})
			await _capture_exterior(world, warrens, player, look, camera,
				"03b-threshold-inside", threshold_step_b,
				threshold_inside_target, -0.40, 1.52, 1.25, 74.0, time_name,
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
	# The guardian remains the live authored body, but return it to the same home
	# used by gameplay spawn and freeze only while this one frame serializes. This
	# prevents random wander timing from putting the camera behind a den wall.
	if guardian.has_method("revive_at_home"):
		guardian.call("revive_at_home")
		await physics_frame
	guardian.set_physics_process(false)
	var den_floor := hall.y
	player.global_position = hall + Vector3.UP * 0.25
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	var toward_guardian := Vector2(guardian.global_position.x - hall.x,
		guardian.global_position.z - hall.z).normalized()
	player.rotation.y = atan2(toward_guardian.x, toward_guardian.y)
	# R23 steps through the hall-to-den aperture and moves laterally inside the
	# chamber. Earlier corridor views made the guardian fill the doorway and hide
	# the authored den; this three-quarter room view proves both in one frame.
	var guardian_side := Vector3(-toward_guardian.y, 0.0, toward_guardian.x)
	camera.fov = 46.0
	camera.global_position = hall \
		+ Vector3(toward_guardian.x, 0.0, toward_guardian.y) * 16.0 \
		+ guardian_side * 5.5 + Vector3.UP * 2.65
	for i in 45:
		await physics_frame
	var guardian_height := float(guardian.call("body_height"))
	camera.look_at(guardian.global_position + guardian_side * 0.9 \
		+ Vector3.UP * guardian_height * 0.48, Vector3.UP)
	_hide_overlays(world)
	for i in 6:
		await process_frame
	await _write_frame("04-den-arrival-day", camera, player, records, failures, {
		"guardian_height_m": guardian_height,
		"guardian_distance_m": hall.distance_to(guardian.global_position),
		"guardian_camera_distance_m": camera.global_position.distance_to(
			guardian.global_position + Vector3.UP * guardian_height * 0.48),
		"hall_floor_y": den_floor,
		"earned_residents_cleared": staged_defeats,
	})
	guardian.set_physics_process(true)

	var bank_mesh := warrens.find_child("Bank", true, false) as MeshInstance3D
	var hidden_collision_carriers := warrens.find_children("*CollisionCarrier",
		"MeshInstance3D", true, false)
	var hidden_bank_carriers := warrens.find_children("BankSurfaceCollisionCarrier",
		"MeshInstance3D", true, false)
	var hidden_wall_boxes := warrens.find_children("OrganicWallCollisionCarrier_*",
		"MeshInstance3D", true, false)
	var hidden_passage_boxes := warrens.find_children("OrganicPassageCollisionCarrier_*",
		"MeshInstance3D", true, false)
	var hidden_chamber_ceilings := warrens.find_children("OrganicChamberCollisionCarrier_*",
		"MeshInstance3D", true, false)
	var hidden_floor_boxes := warrens.find_children("OrganicFloorHidden_*",
		"MeshInstance3D", true, false)
	var visible_rejected_carriers := 0
	for node_v: Variant in hidden_collision_carriers + hidden_wall_boxes + hidden_passage_boxes \
			+ hidden_chamber_ceilings + hidden_floor_boxes:
		var node := node_v as MeshInstance3D
		if node != null and node.visible:
			visible_rejected_carriers += 1
	var geometry_receipt := {
		"facade_root_holder_present": warrens.find_child("BuriedFacadeRoots", true, false) != null,
		"continuous_mantle_present": bank_mesh != null and
			str(bank_mesh.get_meta("warrens_facade_revision", "")) == "continuous_foreland_mantle_r17",
		"excavated_threshold_apron_count": warrens.find_children("ExcavatedThresholdApron", "MeshInstance3D", true, false).size(),
		"excavated_threshold_canopy_count": warrens.find_children("ExcavatedThresholdCanopy", "MeshInstance3D", true, false).size(),
		"excavated_threshold_overburden_count": warrens.find_children("ExcavatedThresholdOverburden_*", "MeshInstance3D", true, false).size(),
		"threshold_bank_blend_count": warrens.find_children("ExcavatedThresholdBankBlend_*", "MeshInstance3D", true, false).size(),
		"continuous_approach_apron_count": warrens.find_children("ContinuousApproachApron", "MeshInstance3D", true, false).size(),
		"hidden_approach_ramp_visual_count": warrens.find_children("ApproachRampCollisionCarrier_*", "MeshInstance3D", true, false).size(),
		"landmark_sign_count": warrens.find_children("BurrowWarrensTrailSign", "Node3D", true, false).size(),
		"den_rootstone_cairn_count": warrens.find_children("DenRootstoneCairn", "Node3D", true, false).size(),
		"applied_warren_hole_count": warrens.find_children("WarrenHoleDisc", "MeshInstance3D", true, false).size(),
		"excavated_cavern_terrain_count": warrens.find_children("ExcavatedCavernTerrain_*", "MeshInstance3D", true, false).size(),
		"excavated_passage_cut_count": warrens.find_children("ExcavatedPassageCut_*", "MeshInstance3D", true, false).size(),
		"rejected_capsule_mass_count": warrens.find_children("ExcavatedThresholdMass_*", "MeshInstance3D", true, false).size() + warrens.find_children("ExcavatedChamberMass_*", "MeshInstance3D", true, false).size() + warrens.find_children("ExcavatedPassageMass_*", "MeshInstance3D", true, false).size() + warrens.find_children("ExcavatedEndMass_*", "MeshInstance3D", true, false).size(),
		"rejected_arch_skin_count": warrens.find_children("OrganicCanopy_*", "MeshInstance3D", true, false).size() + warrens.find_children("OrganicPassage_*", "MeshInstance3D", true, false).size() + warrens.find_children("OrganicEndcap_*", "MeshInstance3D", true, false).size(),
		"rejected_portal_hood_count": warrens.find_children("OrganicPortal_*", "MeshInstance3D", true, false).size(),
		"rejected_threshold_fan_count": warrens.find_children("ThresholdFan", "MeshInstance3D", true, false).size(),
		"hidden_collision_visual_count": hidden_collision_carriers.size(),
		"hidden_bank_collision_visual_count": hidden_bank_carriers.size(),
		"hidden_organic_wall_visual_count": hidden_wall_boxes.size(),
		"hidden_organic_passage_visual_count": hidden_passage_boxes.size(),
		"hidden_organic_chamber_ceiling_count": hidden_chamber_ceilings.size(),
		"hidden_organic_floor_visual_count": hidden_floor_boxes.size(),
		"visible_rejected_carrier_count": visible_rejected_carriers,
	}
	if bool(geometry_receipt.facade_root_holder_present):
		failures.append("R17 exterior still instantiated a separate facade-root assembly")
	if not bool(geometry_receipt.continuous_mantle_present):
		failures.append("R17 exterior did not build the cleaned continuous bank mantle")
	if int(geometry_receipt.excavated_threshold_apron_count) != 1 \
			or int(geometry_receipt.excavated_threshold_canopy_count) != 0 \
			or int(geometry_receipt.excavated_threshold_overburden_count) != 0 \
			or int(geometry_receipt.excavated_cavern_terrain_count) != 4 \
			or int(geometry_receipt.excavated_passage_cut_count) != 4:
		failures.append("R51 open threshold or organic enclosure is incomplete")
	if int(geometry_receipt.threshold_bank_blend_count) != 2:
		failures.append("R35 did not join both open trench banks to the analytic façade")
	if int(geometry_receipt.continuous_approach_apron_count) != 1 \
			or int(geometry_receipt.hidden_approach_ramp_visual_count) != 10:
		failures.append("R35 did not replace the ten visible ramp bands with one continuous apron")
	if int(geometry_receipt.landmark_sign_count) != 1 \
			or int(geometry_receipt.den_rootstone_cairn_count) != 1:
		failures.append("R36 Warrens identity motif is incomplete")
	if int(geometry_receipt.applied_warren_hole_count) != 0:
		failures.append("R39 retained applied dark oval hole props on the mound")
	if int(geometry_receipt.rejected_capsule_mass_count) != 0:
		failures.append("R17 retained rejected capsule/egg mass geometry")
	if int(geometry_receipt.rejected_arch_skin_count) != 0:
		failures.append("R17 retained a rejected swept arch or half-dome skin")
	if int(geometry_receipt.rejected_portal_hood_count) != 0:
		failures.append("R17 retained rejected projecting portal hoods")
	if int(geometry_receipt.rejected_threshold_fan_count) != 0:
		failures.append("R17 retained the rejected separately triangulated threshold fan")
	if int(geometry_receipt.hidden_collision_visual_count) != 4 \
			or int(geometry_receipt.hidden_bank_collision_visual_count) != 1:
		failures.append("R17 hidden bank/throat/cap collision carriers are incomplete")
	if int(geometry_receipt.hidden_organic_wall_visual_count) != 38 \
			or int(geometry_receipt.hidden_organic_passage_visual_count) != 12 \
			or int(geometry_receipt.hidden_organic_chamber_ceiling_count) != 5 \
			or int(geometry_receipt.hidden_organic_floor_visual_count) != 9:
		failures.append("R51 did not isolate every acceptance-route box mesh from rendering")
	if int(geometry_receipt.visible_rejected_carrier_count) != 0:
		failures.append("R17 rendered a collision-only legacy mesh")
	var complete := failures.is_empty() and records.size() == PLANNED_FRAMES.size()
	var manifest := {
		"geometry_revision": "BURROW-WARRENS-IDENTITY-R51",
		"production_scene": SCENE,
		"named_location": "The Burrow Warrens",
		"output_directory": _out_dir,
		"expected_frame_count": PLANNED_FRAMES.size(),
		"captured_frame_count": records.size(),
		"planned_frames": PLANNED_FRAMES,
		"fixture_disclosure": "Production Meadows scene with ordinary live Terrain3D, scatter, props, vegetation, player and encounters. Exterior uses authored clear day/night and resets living residents to authored homes before each comparison frame. Night frames retain bounded capture-only evidence lights; R25 adds no production light. Frames 03/03a/03b are the sequential outside-to-inside receipt; their evidence camera sits just ahead of the real player. The deployed companion and non-guardian Warrens residents remain live and simulated but are hidden only immediately before those three location-composition frames serialize, after the final authored-home reset, preventing unrelated creature close-ups from replacing the threshold proof. ThresholdFan and crossed den shaft cards remain absent. The converging feathered wear field overlaps an open excavated apron with no roof shell. Ten proven ramp collision steps remain active but hidden beneath one continuous non-colliding dirt surface. Bank, Throat, BankCap, DoorwayCollar, chamber-wall, chamber-ceiling and passage collision shapes stay active and unchanged while their rejected carrier MeshInstances remain hidden. The mouth cavern uses the bank wet-earth textures and its front cut continues deeper and wider than the threshold so its chamber surface cannot close into another portal arch. The visible bank omits only the steep notch feather; low asymmetric gallery cuts overlap radial sloped cavern masses with longer sealed joins. A physical Warrens trail sign and repeated den rootstone cairn are production presentation; neither changes collision. Pointed arches, planar room fins, ceiling panels, square recesses, detached floors, capsules, portal hoods, pipes and half-domes are rejected. The guardian frame changes only the evidence camera and moves through the aperture to a three-quarter den view that shows chamber context around the whole creature. Immediately before that frame, the live guardian is returned to its authored home and physics-paused only through serialization so wander timing cannot replace the den composition. Earned staging uses the ordinary resident defeat lifecycle; guardian and optional branch resident remain live. HUD and SubmersionOverlay hidden; no progression state injected.",
		"geometry_receipt": geometry_receipt,
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
	var exclude_companion := label.begins_with("03")
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
	var ground := _surface(world, stand, player) if is_nan(floor_override) else floor_override
	# Remote collision residency follows the production player. Anchor that real
	# player at the requested stand before the warmup, then reseat after streaming
	# so the first day frame receives the same live support as the later night one.
	player.global_position = Vector3(stand.x, ground + 0.30, stand.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	for i in REMOTE_COLLISION_WARMUP_FRAMES:
		await physics_frame
	# Reset after that camera/collision settle, not before it. Otherwise the live
	# mouth resident spends the whole settle interval advancing toward whichever
	# player pose preceded this shot and replaces the tunnel composition. This is
	# the resident's existing lifecycle/home, not actor relocation or art editing.
	_reset_residents_to_authored_homes(warrens)
	player.global_position = Vector3(stand.x, ground + 0.30, stand.y)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	# The production follower's camera-safe station needs more than the old nine
	# physics frames after a remote teleport. Let it reach that normal formation,
	# then put the live Warrens residents back at their authored homes immediately
	# before the shutter so neither actor class replaces the location composition.
	for i in COMPANION_FORMATION_SETTLE_FRAMES:
		await physics_frame
	_reset_residents_to_authored_homes(warrens)
	_hide_overlays(world)
	for i in 6:
		await process_frame
	# Receipt values and the recorded player pose must describe the same final
	# frame. R7 measured these before six live process frames, then serialized a
	# later pose; sample only after every pre-write wait has completed.
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
	var frame_meta := {
		"stand_xz": [stand.x, stand.y],
		"surface_y": seated_surface,
		"player_ground_delta": ground_delta,
		"player_stand_drift_m": stand_drift,
		"camera_eye_clear": camera_clear,
		"capture_evidence_light": time_name == "night",
	}
	frame_meta.merge(evidence_meta, true)
	# Exclude close-up actors only after the final home reset and settle. Hiding
	# them earlier is ineffective because revive_at_home() restores visibility.
	var excluded_creatures: Array[Node3D] = []
	if exclude_companion:
		# R30's production trace identified the remaining close-up as the ambient
		# Band-2 Wild_burrowback_3_1, not the follower. The voice group is the
		# common production identity for ambient, deployed and dungeon creatures;
		# hide only those near this location, and retain the guardian for its frame.
		var guardian := warrens.call("guardian") as Node3D
		var entrance: Vector3 = warrens.call("marker", "entrance")
		for creature_v: Node in get_nodes_in_group(&"creature_voice"):
			var creature := creature_v as Node3D
			if creature != null and creature != guardian and creature.visible \
					and creature.global_position.distance_to(entrance) < 50.0:
				creature.visible = false
				excluded_creatures.append(creature)
		await process_frame
	await _write_frame("%s-%s" % [label, time_name], camera, player, records, failures,
		frame_meta)
	for creature: Node3D in excluded_creatures:
		if is_instance_valid(creature):
			creature.visible = true
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
