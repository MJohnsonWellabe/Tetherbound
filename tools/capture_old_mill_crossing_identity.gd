extends SceneTree

## Dedicated production-scene proof for Old Mill Crossing. The four
## route-authored views retain the accepted arrival, gate and crossing axes.
## Frame 03 uses the mill's reachable southwest apron, broadside to the wheel,
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
##     --output=res://ralph/reports/MEADOWS-0912/final-old-mill-10

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_SERIAL := "final-old-mill-10"
const READY_TIMEOUT_MS := 420_000
const MILL := Vector2(-162.1, 4210.6)
const WHEEL := Vector2(-169.0, 4208.3)
const WHEEL_NODE := "MillCrossing/Mill/OldMillWaterWheel"
const MILL_ROOT := "MillCrossing/Mill"
const FOUNDATION_NODE := MILL_ROOT + "/OldMillGroundedFoundation"
const RACE_ROOT := MILL_ROOT + "/OldMillHeadrace"
const R10_PROOF_NODES := {
	"foundation": FOUNDATION_NODE,
	"foundation_toe": FOUNDATION_NODE + "/GroundedToeUpstream",
	"headpond": RACE_ROOT + "/HeadpondWater",
	"headrace_stringer": RACE_ROOT + "/TroughBed",
	"installed_support": RACE_ROOT + "/HeadracePierShaft",
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
	"tailrace_mid": RACE_ROOT + "/TailraceMid",
	"tailrace_mouth": RACE_ROOT + "/TailraceMouth",
	"outfall": RACE_ROOT + "/TailraceOutfall",
}
const R10_EXPECTED_FRAMES := [
	"01-south-arrival-day", "01-south-arrival-night",
	"02-gate-and-wheel-day", "02-gate-and-wheel-night",
	"03-hydraulic-sequence-south-bank-day", "03-hydraulic-sequence-south-bank-night",
	"04-crossing-axis-day", "04-crossing-axis-night",
]
const MAX_NEAR_WILDLIFE_DISTANCE_M := 18.0
const MAX_NEAR_WILDLIFE_FRAME_SHARE := 0.28

const VIEWS := [
	{"name": "01-south-arrival", "stand": Vector2(-152.0, 4168.0),
		"target": Vector2(-157.0, 4207.0), "aim_up": 5.2, "back": 2.0, "up": 3.0, "fov": 60.0},
	{"name": "02-gate-and-wheel", "stand": Vector2(-143.0, 4181.0),
		"target": WHEEL, "target_node": WHEEL_NODE, "aim_up": 0.0,
		"back": 1.8, "up": 2.9, "fov": 55.0},
	# This ordinary on-foot southwest apron remains south of the river rim and
	# reachable before the gate opens. It looks almost along the wheel axle, so the
	# complete ribbon and wheel face separate instead of collapsing edge-on.
	{"name": "03-hydraulic-sequence-south-bank", "stand": Vector2(-184.0, 4194.0),
		"target": WHEEL, "target_node": WHEEL_NODE, "aim_up": 0.0,
		"back": 1.6, "up": 3.0, "fov": 64.0},
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
	if player == null or look == null or director == null:
		push_error("capture requires the production Player, WorldLook and EncounterDirector")
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
	for raw: Variant in VIEWS:
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
			for i in 60:
				await physics_frame
			wildlife_reset_count = maxi(wildlife_reset_count,
				_freeze_wildlife_at_authored_homes(director))
			director.set_process(false)
			director.set_physics_process(false)
			ground = _surface(world, stand, player)
			player.global_position = Vector3(stand.x, ground + 0.35, stand.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			for i in 60:
				await physics_frame
			var settled_xz := Vector2(player.global_position.x, player.global_position.z)
			if settled_xz.distance_to(stand) > 0.2:
				failures.append("%s-%s: player drifted from authored XZ" % [str(view.name), time_name])
				continue
			if player.global_position.y < _surface(world, stand, player) - 0.15:
				failures.append("%s-%s: player below live surface" % [str(view.name), time_name])
				continue
			var wildlife_blocker := _near_wildlife_blocker(director, camera, stand)
			if not wildlife_blocker.is_empty():
				failures.append("%s-%s: %s" % [str(view.name), time_name, wildlife_blocker])
				continue
			var r10_proof := _verify_r10_projection(world, camera, str(view.name))
			var proof_failures := r10_proof.get("failures", []) as Array
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
				"r10_visual_proof": r10_proof.get("metrics", {}),
			})
			print("wrote %s" % path)

	var captured_frames: Array[String] = []
	for record: Dictionary in records:
		captured_frames.append(str(record.get("frame", "")))
	for expected: String in R10_EXPECTED_FRAMES:
		if not captured_frames.has(expected):
			failures.append("required R10 production frame missing: %s" % expected)
	for captured: String in captured_frames:
		if not R10_EXPECTED_FRAMES.has(captured):
			failures.append("unexpected R10 production frame: %s" % captured)

	var manifest := {
		"capture_serial": CAPTURE_SERIAL,
		"production_scene": SCENE,
		"named_location": "Old Mill Crossing",
		"r10_required_nodes": R10_PROOF_NODES,
		"r10_expected_frames": R10_EXPECTED_FRAMES,
		"fixture_disclosure": "Production Meadows scene with ordinary player, live Terrain3D, authoritative scatter, props, harvestables, crossing mechanics and encounters. Authored day/night clock applied then frozen; clear weather; HUD and independent SubmersionOverlay hidden. Live collision-surface seating. After local encounter streaming, existing production wildlife is returned through wild_creature.revive_at_home() and movement-frozen at those authored homes; no body is hidden, deleted, spawned, relocated to a capture-authored point or removed from ecology. A fail-closed projection check rejects any remaining giant foreground wildlife blocker. No progress, crossing, mill, route, vegetation or encounter injection.",
		"wildlife_reset_count": wildlife_reset_count,
		"complete": failures.is_empty() and records.size() == VIEWS.size() * 2,
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


## A capture is not proof merely because the authored nodes exist. This verifier
## runs after the live player/camera settle and requires the repair to occupy a
## readable part of the actual production frame. The dedicated hydraulic view
## also requires the hydraulic beats to remain separated and descend on screen,
## and rejects a wheel substantially enveloped by the foundation projection.
func _verify_r10_projection(world: Node3D, camera: Camera3D, view_name: String) -> Dictionary:
	var failures: Array[String] = []
	var metrics := {}
	var nodes := {}
	for key: String in R10_PROOF_NODES:
		var node := world.get_node_or_null(NodePath(str(R10_PROOF_NODES[key]))) as Node3D
		if node == null:
			failures.append("R10 proof node missing: %s" % key)
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
				"tailrace_mid": Vector2(28.0, 7.0),
				"tailrace_mouth": Vector2(28.0, 7.0),
				"outfall": Vector2(10.0, 7.0),
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
			failures.append("R10 %s is not projected/readable (%.1fx%.1f px; need %.1fx%.1f)" % [
				key, rect.size.x, rect.size.y, minimum.x, minimum.y])

	if view_name == "03-hydraulic-sequence-south-bank":
		var sequence := ["headpond", "source", "headrace_upper", "headrace_mid",
			"headrace_lower", "feed_drop", "wheel_contact", "discharge", "tailrace",
			"tailrace_mid", "tailrace_mouth", "outfall"]
		var screen_points: Array[Vector2] = []
		for key: String in sequence:
			var centre := _visual_world_centre(nodes[key] as Node3D)
			if camera.is_position_behind(centre):
				failures.append("R10 hydraulic beat is behind camera: %s" % key)
			screen_points.append(camera.unproject_position(centre))
		var segment_lengths: Array[float] = []
		for i in screen_points.size() - 1:
			var length := screen_points[i].distance_to(screen_points[i + 1])
			segment_lengths.append(snappedf(length, 0.1))
			if length < 6.0:
				failures.append("R10 hydraulic beats %s -> %s collapse together on screen (%.1f px)" % [
					sequence[i], sequence[i + 1], length])
		for run: Array in [["headpond", "source", "headrace_upper", "headrace_mid",
				"headrace_lower", "feed_drop", "wheel_contact"],
				["discharge", "tailrace", "tailrace_mid", "tailrace_mouth", "outfall"]]:
			for i in run.size() - 1:
				var gap := _rect_distance(bounds[run[i]] as Rect2, bounds[run[i + 1]] as Rect2)
				if gap > 8.0:
					failures.append("R10 visible water ribbon breaks at %s -> %s (%.1f px)" % [
						run[i], run[i + 1], gap])
		var first_point: Vector2 = screen_points[0]
		var last_point: Vector2 = screen_points[screen_points.size() - 1]
		var total_span: float = first_point.distance_to(last_point)
		metrics["hydraulic_segment_lengths_px"] = segment_lengths
		metrics["hydraulic_total_span_px"] = snappedf(total_span, 0.1)
		if total_span < 220.0:
			failures.append("R10 source-to-outfall chain spans only %.1f px" % total_span)
		var vertical_drop := screen_points[screen_points.size() - 1].y - screen_points[0].y
		metrics["hydraulic_vertical_drop_px"] = snappedf(vertical_drop, 0.1)
		if vertical_drop < 110.0:
			failures.append("R10 headpond-to-outfall drop reads as only %.1f px" % vertical_drop)

		var wheel_bounds := bounds["wheel"] as Rect2
		var wheel_roundness := minf(wheel_bounds.size.x, wheel_bounds.size.y) / maxf(
			wheel_bounds.size.x, wheel_bounds.size.y)
		metrics["wheel_broadside_roundness"] = snappedf(wheel_roundness, 0.001)
		var wheel_axis := ((nodes["wheel"] as Node3D).global_basis.z).normalized()
		var camera_axis := (camera.global_position - (nodes["wheel"] as Node3D).global_position).normalized()
		var broadside_alignment := absf(camera_axis.dot(wheel_axis))
		metrics["wheel_broadside_alignment"] = snappedf(broadside_alignment, 0.001)
		if wheel_roundness < 0.72 or broadside_alignment < 0.72:
			failures.append("R10 wheel is not broadside/readable (roundness %.2f, alignment %.2f)" % [
				wheel_roundness, broadside_alignment])
		var foundation_overlap := _rect_overlap_share(wheel_bounds, bounds["foundation"] as Rect2)
		metrics["wheel_foundation_overlap_share"] = snappedf(foundation_overlap, 0.001)
		if foundation_overlap >= 0.35:
			failures.append("R10 wheel is %.0f%% enveloped by foundation projection" % [
				foundation_overlap * 100.0])
		var source_point := screen_points[0]
		var contact_point := screen_points[6]
		var discharge_point := screen_points[7]
		if not (source_point.y < contact_point.y and contact_point.y < discharge_point.y):
			failures.append("R10 source/contact/discharge do not descend on screen")
		var world_heights: Array[float] = []
		for key: String in sequence:
			world_heights.append(_visual_world_centre(nodes[key] as Node3D).y)
		for i in world_heights.size() - 1:
			if world_heights[i + 1] >= world_heights[i] - 0.04:
				failures.append("R10 hydraulic grade is not downhill at %s -> %s" % [
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
