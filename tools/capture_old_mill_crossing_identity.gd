extends SceneTree

## Dedicated production-scene proof for Old Mill Crossing. The four
## route-authored views retain the accepted arrival, gate and crossing axes.
## Frame 03 selects a stable point on the mill's reachable south/southwest
## apron, broadside to the wheel,
## proving the compact source/headrace/wheel/tailrace path and the battered
## masonry load path at ordinary player height. Production wildlife
## remains present at authored homes but is reset and movement-frozen after the
## local stream settles, so elapsed capture time cannot manufacture an enormous
## foreground blocker.
## It deliberately does not share or modify tools/_capture_locations.gd.
##
## Run with a real Compatibility renderer:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_old_mill_crossing_identity.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-old-mill-12

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_SERIAL := "final-old-mill-12"
const READY_TIMEOUT_MS := 420_000
const MILL := Vector2(-162.1, 4210.6)
const WHEEL := Vector2(-169.0, 4208.3)
const CROSSING_WATER_SURFACE_Y := -8.0
const WHEEL_NODE := "MillCrossing/Mill/OldMillWaterWheel"
const MILL_ROOT := "MillCrossing/Mill"
const FOUNDATION_NODE := MILL_ROOT + "/OldMillGroundedFoundation"
const RACE_ROOT := MILL_ROOT + "/OldMillHeadrace"
const R12_PROOF_NODES := {
	"foundation": FOUNDATION_NODE,
	"foundation_toe": FOUNDATION_NODE + "/GroundedToeUpstream",
	"headpond": RACE_ROOT + "/HeadpondWater",
	"headrace_stringer": RACE_ROOT + "/TroughBed",
	"installed_support": RACE_ROOT + "/HeadracePierShaft",
	"support_brace": RACE_ROOT + "/HeadracePierBrace",
	"support_foot": RACE_ROOT + "/HeadracePierFoot",
	"source": RACE_ROOT + "/SourceIntakeWater",
	"headrace_upper": RACE_ROOT + "/RunningWater",
	"headrace_mid": RACE_ROOT + "/HeadraceWaterMid",
	"headrace_lower": RACE_ROOT + "/HeadraceWaterLower",
	"feed_drop": RACE_ROOT + "/FeedDrop",
	"wheel_contact": RACE_ROOT + "/PaddleContact",
	"wheel": WHEEL_NODE,
	"discharge": RACE_ROOT + "/WheelDischarge",
	"tailrace": RACE_ROOT + "/TailraceWater",
	"tailrace_bed": RACE_ROOT + "/TailraceBed",
	"tailrace_mid": RACE_ROOT + "/TailraceMid",
	"tailrace_mouth": RACE_ROOT + "/TailraceMouth",
	"tailrace_mouth_bed": RACE_ROOT + "/TailraceBed02",
	"outfall": RACE_ROOT + "/TailraceOutfall",
	"river_toe": RACE_ROOT + "/TailraceRiverToe",
}
const R12_EXPECTED_FRAMES := [
	"01-south-arrival-day", "01-south-arrival-night",
	"02-gate-and-wheel-day", "02-gate-and-wheel-night",
	"03-hydraulic-sequence-south-bank-day", "03-hydraulic-sequence-south-bank-night",
	"04-crossing-axis-day", "04-crossing-axis-night",
]
const MAX_NEAR_WILDLIFE_DISTANCE_M := 18.0
const MAX_NEAR_WILDLIFE_FRAME_SHARE := 0.28
const STAND_SETTLE_PHYSICS_FRAMES := 60

## R10 proved the art and lens, but (-184, 4194) overlaps live severed-spoke
## recovery geometry. These points stay within a 6.4m south/southwest apron
## patch and retain the same wheel-axle side. Selection accepts the first point
## that remains grounded without drift or an unstick recovery and also passes
## the unchanged full R12 projection/hydraulic contract.
const HYDRAULIC_STAND_CANDIDATES := [
	{"id": "southwest_apron_south_01", "stand": Vector2(-183.0, 4190.0)},
	{"id": "southwest_apron_south_02", "stand": Vector2(-181.0, 4188.0)},
	{"id": "southwest_apron_outer_03", "stand": Vector2(-185.0, 4189.0)},
	{"id": "south_apron_outer_04", "stand": Vector2(-179.0, 4187.0)},
]

const HYDRAULIC_VIEW := {
	"name": "03-hydraulic-sequence-south-bank",
	"target": WHEEL, "target_node": WHEEL_NODE, "aim_up": 0.0,
	"back": 1.6, "up": 3.0, "fov": 64.0,
}

const VIEWS := [
	{"name": "01-south-arrival", "stand": Vector2(-152.0, 4168.0),
		"target": Vector2(-157.0, 4207.0), "aim_up": 5.2, "back": 2.0, "up": 3.0, "fov": 60.0},
	{"name": "02-gate-and-wheel", "stand": Vector2(-143.0, 4181.0),
		"target": WHEEL, "target_node": WHEEL_NODE, "aim_up": 0.0,
		"back": 1.8, "up": 2.9, "fov": 55.0},
	{"name": "04-crossing-axis", "stand": Vector2(-151.0, 4185.0),
		"target": Vector2(-154.0, 4220.0), "aim_up": 4.0, "back": 1.8, "up": 3.1, "fov": 60.0},
]

var _out_dir := ""


func _init() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	_run()


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(_out_dir, "Old Mill Crossing capture"):
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
	var director := world.get_node_or_null(^"EncounterDirector")
	if player == null or not player is CharacterBody3D or not player.has_method("unstick_count") \
			or look == null or director == null:
		push_error("capture requires the production CharacterBody Player, WorldLook and EncounterDirector")
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

	var camera := Camera3D.new()
	camera.name = "OldMillCrossingEvidenceCamera"
	camera.far = 1200.0
	world.add_child(camera)
	camera.make_current()

	var records: Array[Dictionary] = []
	var failures: Array[String] = []
	var wildlife_reset_count := 0
	_pin_clock(look, "day")
	var hydraulic_selection := await _select_hydraulic_stand(world, player, camera)
	var views: Array = VIEWS.duplicate(true)
	if hydraulic_selection.has("view"):
		views.insert(2, hydraulic_selection["view"])
	else:
		failures.append("no stable south/southwest hydraulic stand passed production physics and R12 visual gates")
	for raw: Variant in views:
		var view := raw as Dictionary
		for time_name: String in ["day", "night"]:
			_pin_clock(look, time_name)
			var stand: Vector2 = view.stand
			var target: Vector2 = view.target
			var ground := _surface(world, stand, player)
			player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			var toward := (target - stand).normalized()
			player.rotation.y = atan2(toward.x, toward.y)
			var eye_xz := stand - toward * float(view.back)
			var eye_ground := _surface(world, eye_xz, player)
			camera.fov = float(view.fov)
			camera.global_position = Vector3(eye_xz.x, eye_ground + float(view.up), eye_xz.y)
			var target_point := Vector3(target.x,
				float(world.call("ground_height_at", target.x, target.y)) + float(view.aim_up), target.y)
			var target_node_name := str(view.get("target_node", ""))
			if not target_node_name.is_empty():
				var target_node := world.get_node_or_null(NodePath(target_node_name)) as Node3D
				if target_node == null:
					failures.append("%s-%s: explicit target node missing" % [str(view.name), time_name])
					continue
				target_point = target_node.global_position
			camera.look_at(target_point, Vector3.UP)
			# All four stands are far from spawn. Warm the local Terrain3D collision
			# and encounter rings, then return every living production resident to
			# its authored home and freeze movement. Bodies remain visible; this only
			# removes the sequential-capture bias that let two roaming Galecrest walk
			# into frame 03 during final-02.
			var recovery_before := int(player.call("unstick_count"))
			for i in STAND_SETTLE_PHYSICS_FRAMES:
				await physics_frame
			wildlife_reset_count = maxi(wildlife_reset_count,
				_freeze_wildlife_at_authored_homes(director))
			director.set_process(false)
			director.set_physics_process(false)
			ground = _surface(world, stand, player)
			player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			for i in STAND_SETTLE_PHYSICS_FRAMES:
				await physics_frame
			var settled_xz := Vector2(player.global_position.x, player.global_position.z)
			if int(player.call("unstick_count")) != recovery_before:
				failures.append("%s-%s: player triggered production unstick recovery" % [str(view.name), time_name])
				continue
			if settled_xz.distance_to(stand) > 0.2:
				failures.append("%s-%s: player drifted from authored XZ" % [str(view.name), time_name])
				continue
			if not (player as CharacterBody3D).is_on_floor() \
					or player.global_position.y < _surface(world, stand, player) - 0.15:
				failures.append("%s-%s: player is not stably grounded on the live surface" % [str(view.name), time_name])
				continue
			var wildlife_blocker := _near_wildlife_blocker(director, camera, stand)
			if not wildlife_blocker.is_empty():
				failures.append("%s-%s: %s" % [str(view.name), time_name, wildlife_blocker])
				continue
			var r12_proof := _verify_r12_projection(world, camera, str(view.name))
			var proof_failures := r12_proof.get("failures", []) as Array
			if not proof_failures.is_empty():
				for failure: Variant in proof_failures:
					failures.append("%s-%s: %s" % [str(view.name), time_name, str(failure)])
				continue
			_hide_overlays(world)
			for i in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if image == null or image.is_empty():
				failures.append("%s-%s: viewport returned no image" % [str(view.name), time_name])
				continue
			var frame_name := "%s-%s" % [str(view.name), time_name]
			var path := "%s/%s.png" % [_out_dir, frame_name]
			if image.save_png(path) != OK:
				failures.append("%s: save_png failed" % frame_name)
				continue
			records.append({
				"frame": frame_name,
				"time": time_name,
				"player_xz": [stand.x, stand.y],
				"camera_to_player_m": camera.global_position.distance_to(player.global_position),
				"mill_distance_m": stand.distance_to(MILL),
				"image_size": [image.get_width(), image.get_height()],
				"r12_visual_proof": r12_proof.get("metrics", {}),
			})
			print("wrote %s" % path)

	var captured_frames: Array[String] = []
	for record: Dictionary in records:
		captured_frames.append(str(record.get("frame", "")))
	for expected: String in R12_EXPECTED_FRAMES:
		if not captured_frames.has(expected):
			failures.append("required R12 production frame missing: %s" % expected)
	for captured: String in captured_frames:
		if not R12_EXPECTED_FRAMES.has(captured):
			failures.append("unexpected R12 production frame: %s" % captured)

	var manifest := {
		"capture_serial": CAPTURE_SERIAL,
		"production_scene": SCENE,
		"named_location": "Old Mill Crossing",
		"r12_required_nodes": R12_PROOF_NODES,
		"r12_expected_frames": R12_EXPECTED_FRAMES,
		"hydraulic_stand_selection": hydraulic_selection.get("receipt", {}),
		"fixture_disclosure": "Production Meadows scene with ordinary player, live Terrain3D, authoritative scatter, props, harvestables, crossing mechanics and encounters. Authored day/night clock applied then frozen; clear weather; HUD and independent SubmersionOverlay hidden. Frame 03 chooses the first point in a fixed 6.4m south/southwest apron set that remains on the live collision surface with no drift or production unstick recovery and passes the unchanged broadside, projection, continuity and downhill checks; all candidates and rejections are receipted. After local encounter streaming, existing production wildlife is returned through wild_creature.revive_at_home() and movement-frozen at those authored homes; no body is hidden, deleted, spawned, relocated to a capture-authored point or removed from ecology. A fail-closed projection check rejects any remaining giant foreground wildlife blocker. No progress, crossing, mill, route, vegetation or encounter injection.",
		"wildlife_reset_count": wildlife_reset_count,
		"complete": failures.is_empty() and hydraulic_selection.has("view") \
			and records.size() == R12_EXPECTED_FRAMES.size(),
		"frames": records,
		"failures": failures,
	}
	var file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if file == null:
		failures.append("manifest could not be written")
	else:
		file.store_string(JSON.stringify(manifest, "\t") + "\n")
		file.close()
	quit(0 if failures.is_empty() else 1)


## Choose an honest production-player seat, not a free-camera coordinate. Each
## candidate repeats the shutter's two-phase collision warmup and must stay on
## floor, within 0.2m of its authored XZ, and add no production unstick recovery.
## It must then pass the same pixel/world-space mechanism contract as the frame.
func _select_hydraulic_stand(world: Node3D, player: Node3D,
		camera: Camera3D) -> Dictionary:
	var rejected: Array[Dictionary] = []
	for raw_candidate: Dictionary in HYDRAULIC_STAND_CANDIDATES:
		var view: Dictionary = HYDRAULIC_VIEW.duplicate(true)
		var stand: Vector2 = raw_candidate["stand"]
		view["stand"] = stand
		var target: Vector2 = view["target"]
		var ground := _surface(world, stand, player)
		player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
		(player as CharacterBody3D).velocity = Vector3.ZERO
		var toward := (target - stand).normalized()
		player.rotation.y = atan2(toward.x, toward.y)
		var eye_xz := stand - toward * float(view["back"])
		camera.fov = float(view["fov"])
		camera.global_position = Vector3(eye_xz.x,
			_surface(world, eye_xz, player) + float(view["up"]), eye_xz.y)
		var wheel := world.get_node_or_null(NodePath(WHEEL_NODE)) as Node3D
		var problems: Array[String] = []
		if wheel == null:
			problems.append("explicit wheel target is missing")
		else:
			camera.look_at(wheel.global_position, Vector3.UP)
		var recovery_before := int(player.call("unstick_count"))
		for i in STAND_SETTLE_PHYSICS_FRAMES:
			await physics_frame
		ground = _surface(world, stand, player)
		player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
		(player as CharacterBody3D).velocity = Vector3.ZERO
		player.reset_physics_interpolation()
		for i in STAND_SETTLE_PHYSICS_FRAMES:
			await physics_frame
		var settled_xz := Vector2(player.global_position.x, player.global_position.z)
		var recovery_after := int(player.call("unstick_count"))
		if recovery_after != recovery_before:
			problems.append("triggered production unstick recovery")
		if settled_xz.distance_to(stand) > 0.2:
			problems.append("drifted %.2fm from candidate XZ" % settled_xz.distance_to(stand))
		if not (player as CharacterBody3D).is_on_floor() \
				or player.global_position.y < _surface(world, stand, player) - 0.15:
			problems.append("did not remain grounded on live collision")
		var proof := _verify_r12_projection(world, camera,
			"03-hydraulic-sequence-south-bank")
		for raw_problem: Variant in proof.get("failures", []):
			problems.append(str(raw_problem))
		var receipt := {
			"candidate_id": str(raw_candidate["id"]),
			"stand_xz": [stand.x, stand.y],
			"settled_xz": [settled_xz.x, settled_xz.y],
			"recovery_count_before": recovery_before,
			"recovery_count_after": recovery_after,
			"player_on_floor": (player as CharacterBody3D).is_on_floor(),
			"problems": problems,
		}
		if problems.is_empty():
			return {"view": view, "receipt": {
				"selected": receipt,
				"rejected_before_selection": rejected,
			}}
		rejected.append(receipt)
	return {"receipt": {"selected": {}, "rejected_before_selection": rejected}}


## A capture is not proof merely because the authored nodes exist. This verifier
## runs after the live player/camera settle and requires the repair to occupy a
## readable part of the actual production frame. The dedicated hydraulic view
## also requires the hydraulic beats to remain separated and descend on screen,
## and rejects a wheel substantially enveloped by the foundation projection.
func _verify_r12_projection(world: Node3D, camera: Camera3D, view_name: String) -> Dictionary:
	var failures: Array[String] = []
	var metrics := {}
	var nodes := {}
	for key: String in R12_PROOF_NODES:
		var node := world.get_node_or_null(NodePath(str(R12_PROOF_NODES[key]))) as Node3D
		if node == null:
			failures.append("R12 proof node missing: %s" % key)
		else:
			nodes[key] = node
	if not failures.is_empty():
		return {"failures": failures, "metrics": metrics}

	var required := {}
	match view_name:
		"01-south-arrival":
			required = {"foundation": Vector2(7.0, 7.0)}
		"02-gate-and-wheel":
			required = {
				"wheel": Vector2(52.0, 52.0),
				"feed_drop": Vector2(7.0, 10.0),
				"wheel_contact": Vector2(8.0, 10.0),
				"installed_support": Vector2(5.0, 12.0),
			}
		"03-hydraulic-sequence-south-bank":
			required = {
				"foundation": Vector2(18.0, 24.0),
				"foundation_toe": Vector2(4.0, 4.0),
				"headpond": Vector2(34.0, 7.0),
				"headrace_stringer": Vector2(24.0, 6.0),
				"installed_support": Vector2(9.0, 50.0),
				"support_brace": Vector2(9.0, 50.0),
				"support_foot": Vector2(12.0, 5.0),
				"source": Vector2(10.0, 7.0),
				"headrace_upper": Vector2(22.0, 7.0),
				"headrace_mid": Vector2(20.0, 7.0),
				"headrace_lower": Vector2(16.0, 7.0),
				"feed_drop": Vector2(8.0, 14.0),
				"wheel_contact": Vector2(10.0, 12.0),
				"wheel": Vector2(120.0, 120.0),
				"discharge": Vector2(8.0, 18.0),
				"tailrace": Vector2(28.0, 7.0),
				"tailrace_bed": Vector2(28.0, 7.0),
				"tailrace_mid": Vector2(28.0, 7.0),
				"tailrace_mouth": Vector2(28.0, 7.0),
				"tailrace_mouth_bed": Vector2(28.0, 7.0),
				"outfall": Vector2(10.0, 7.0),
				"river_toe": Vector2(12.0, 5.0),
			}
		"04-crossing-axis":
			required = {"foundation": Vector2(14.0, 14.0)}

	var bounds := {}
	for key: String in required:
		var rect := _projected_visible_bounds(camera, nodes[key] as Node3D)
		bounds[key] = rect
		var minimum := required[key] as Vector2
		metrics["%s_visible_px" % key] = [snappedf(rect.size.x, 0.1), snappedf(rect.size.y, 0.1)]
		if rect.size.x < minimum.x or rect.size.y < minimum.y:
			failures.append("R12 %s is not projected/readable (%.1fx%.1f px; need %.1fx%.1f)" % [
				key, rect.size.x, rect.size.y, minimum.x, minimum.y])

	if view_name == "03-hydraulic-sequence-south-bank":
		var sequence := ["headpond", "source", "headrace_upper", "headrace_mid",
			"headrace_lower", "feed_drop", "wheel_contact", "discharge", "tailrace",
			"tailrace_mid", "tailrace_mouth", "outfall"]
		var screen_points: Array[Vector2] = []
		for key: String in sequence:
			var centre := _visual_world_centre(nodes[key] as Node3D)
			if camera.is_position_behind(centre):
				failures.append("R12 hydraulic beat is behind camera: %s" % key)
			screen_points.append(camera.unproject_position(centre))
		var segment_lengths: Array[float] = []
		for i in screen_points.size() - 1:
			var length := screen_points[i].distance_to(screen_points[i + 1])
			segment_lengths.append(snappedf(length, 0.1))
			if length < 6.0:
				failures.append("R12 hydraulic beats %s -> %s collapse together on screen (%.1f px)" % [
					sequence[i], sequence[i + 1], length])
		for run: Array in [["headpond", "source", "headrace_upper", "headrace_mid",
				"headrace_lower", "feed_drop", "wheel_contact"],
				["discharge", "tailrace", "tailrace_mid", "tailrace_mouth", "outfall"]]:
			for i in run.size() - 1:
				var gap := _rect_distance(bounds[run[i]] as Rect2, bounds[run[i + 1]] as Rect2)
				if gap > 8.0:
					failures.append("R12 visible water ribbon breaks at %s -> %s (%.1f px)" % [
						run[i], run[i + 1], gap])
		var first_point: Vector2 = screen_points[0]
		var last_point: Vector2 = screen_points[screen_points.size() - 1]
		var total_span: float = first_point.distance_to(last_point)
		metrics["hydraulic_segment_lengths_px"] = segment_lengths
		metrics["hydraulic_total_span_px"] = snappedf(total_span, 0.1)
		if total_span < 220.0:
			failures.append("R12 source-to-outfall chain spans only %.1f px" % total_span)
		var vertical_drop := screen_points[screen_points.size() - 1].y - screen_points[0].y
		metrics["hydraulic_vertical_drop_px"] = snappedf(vertical_drop, 0.1)
		if vertical_drop < 110.0:
			failures.append("R12 headpond-to-outfall drop reads as only %.1f px" % vertical_drop)
		var outfall_centre := _visual_world_centre(nodes["outfall"] as Node3D)
		var river_toe_centre := _visual_world_centre(nodes["river_toe"] as Node3D)
		metrics["outfall_world_y"] = snappedf(outfall_centre.y, 0.001)
		metrics["river_toe_world_y"] = snappedf(river_toe_centre.y, 0.001)
		if absf(outfall_centre.y - CROSSING_WATER_SURFACE_Y) > 0.65 \
				or absf(river_toe_centre.y - CROSSING_WATER_SURFACE_Y) > 0.45:
			failures.append("R12 tailrace does not physically meet the -8m crossing water surface")
		var outfall_to_toe_gap := _rect_distance(bounds["outfall"] as Rect2,
			bounds["river_toe"] as Rect2)
		metrics["outfall_to_river_toe_gap_px"] = snappedf(outfall_to_toe_gap, 0.1)
		if outfall_to_toe_gap > 4.0:
			failures.append("R12 tailrace outfall is visibly detached from its river toe")

		var wheel_bounds := bounds["wheel"] as Rect2
		var wheel_roundness := minf(wheel_bounds.size.x, wheel_bounds.size.y) / maxf(
			wheel_bounds.size.x, wheel_bounds.size.y)
		metrics["wheel_broadside_roundness"] = snappedf(wheel_roundness, 0.001)
		var wheel_axis := ((nodes["wheel"] as Node3D).global_basis.z).normalized()
		var camera_axis := (camera.global_position - (nodes["wheel"] as Node3D).global_position).normalized()
		var broadside_alignment := absf(camera_axis.dot(wheel_axis))
		metrics["wheel_broadside_alignment"] = snappedf(broadside_alignment, 0.001)
		if wheel_roundness < 0.72 or broadside_alignment < 0.72:
			failures.append("R12 wheel is not broadside/readable (roundness %.2f, alignment %.2f)" % [
				wheel_roundness, broadside_alignment])
		var foundation_overlap := _rect_overlap_share(wheel_bounds, bounds["foundation"] as Rect2)
		metrics["wheel_foundation_overlap_share"] = snappedf(foundation_overlap, 0.001)
		if foundation_overlap >= 0.35:
			failures.append("R12 wheel is %.0f%% enveloped by foundation projection" % [
				foundation_overlap * 100.0])
		var source_point := screen_points[0]
		var contact_point := screen_points[6]
		var discharge_point := screen_points[7]
		if not (source_point.y < contact_point.y and contact_point.y < discharge_point.y):
			failures.append("R12 source/contact/discharge do not descend on screen")
		var world_heights: Array[float] = []
		for key: String in sequence:
			world_heights.append(_visual_world_centre(nodes[key] as Node3D).y)
		for i in world_heights.size() - 1:
			if world_heights[i + 1] >= world_heights[i] - 0.04:
				failures.append("R12 hydraulic grade is not downhill at %s -> %s" % [
					sequence[i], sequence[i + 1]])
		metrics["hydraulic_world_heights_m"] = world_heights
	return {"failures": failures, "metrics": metrics}


func _projected_visible_bounds(camera: Camera3D, node: Node3D) -> Rect2:
	var points: Array[Vector2] = []
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for raw: Node in node.find_children("*", "MeshInstance3D", true, false):
		meshes.append(raw as MeshInstance3D)
	for mesh: MeshInstance3D in meshes:
		if mesh == null or not mesh.is_visible_in_tree() or mesh.mesh == null:
			continue
		var aabb := mesh.get_aabb()
		for x in 2:
			for y in 2:
				for z in 2:
					var local_corner := aabb.position + aabb.size * Vector3(float(x), float(y), float(z))
					var world_corner := mesh.global_transform * local_corner
					if not camera.is_position_behind(world_corner):
						points.append(camera.unproject_position(world_corner))
	if points.is_empty():
		return Rect2()
	var minimum: Vector2 = points[0]
	var maximum: Vector2 = points[0]
	for point: Vector2 in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	var projected := Rect2(minimum, maximum - minimum)
	return projected.intersection(Rect2(Vector2.ZERO,
		camera.get_viewport().get_visible_rect().size))


func _visual_world_centre(node: Node3D) -> Vector3:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).global_transform * (node as MeshInstance3D).get_aabb().get_center()
	return node.global_position


func _rect_overlap_share(subject: Rect2, blocker: Rect2) -> float:
	var subject_area := subject.size.x * subject.size.y
	if subject_area <= 0.0 or not subject.intersects(blocker):
		return 0.0
	var overlap := subject.intersection(blocker)
	return (overlap.size.x * overlap.size.y) / subject_area


func _rect_distance(a: Rect2, b: Rect2) -> float:
	var dx := maxf(maxf(a.position.x - b.end.x, b.position.x - a.end.x), 0.0)
	var dy := maxf(maxf(a.position.y - b.end.y, b.position.y - a.end.y), 0.0)
	return Vector2(dx, dy).length()


func _freeze_wildlife_at_authored_homes(director: Node) -> int:
	var reset_count := 0
	for value: Variant in director.call("wild_creatures"):
		var body := value as Node3D
		if body == null or not is_instance_valid(body) or not body.is_inside_tree():
			continue
		if body.has_method("revive_at_home"):
			body.call("revive_at_home")
		body.set_process(false)
		body.set_physics_process(false)
		body.reset_physics_interpolation()
		reset_count += 1
	return reset_count


func _near_wildlife_blocker(director: Node, camera: Camera3D, stand: Vector2) -> String:
	var viewport_size := camera.get_viewport().get_visible_rect().size
	for value: Variant in director.call("wild_creatures"):
		var body := value as Node3D
		if body == null or not is_instance_valid(body) or not body.is_inside_tree() \
				or not body.is_visible_in_tree():
			continue
		if body.has_method("is_alive") and not bool(body.call("is_alive")):
			continue
		var distance := stand.distance_to(Vector2(body.global_position.x, body.global_position.z))
		if distance > MAX_NEAR_WILDLIFE_DISTANCE_M:
			continue
		var height := maxf(0.1,
			float(body.call("body_height")) if body.has_method("body_height") else 1.0)
		var radius := maxf(0.1,
			float(body.call("body_radius")) if body.has_method("body_radius") else height * 0.4)
		var foot := body.global_position
		var centre := foot + Vector3.UP * height * 0.5
		if camera.is_position_behind(centre) or not camera.is_position_in_frustum(centre):
			continue
		var head := foot + Vector3.UP * height
		var projected_height := absf(camera.unproject_position(head).y
			- camera.unproject_position(foot).y)
		var screen_right := camera.global_basis.x
		var projected_width := absf(camera.unproject_position(centre + screen_right * radius).x
			- camera.unproject_position(centre - screen_right * radius).x)
		var frame_share := maxf(projected_height / maxf(viewport_size.y, 1.0),
			projected_width / maxf(viewport_size.x, 1.0))
		if frame_share > MAX_NEAR_WILDLIFE_FRAME_SHARE:
			return "live wildlife %s at %.1fm occupies %.0f%% of a frame axis" % [
				str(body.get("species_id")), distance, frame_share * 100.0]
	return ""


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
		Vector3(at.x, analytic + 4.0, at.y),
		Vector3(at.x, analytic - 6.0, at.y))
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
