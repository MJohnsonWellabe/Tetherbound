extends SceneTree

## Dedicated production-scene proof for Old Mill Crossing. The four
## route-authored views retain the accepted arrival, gate and crossing axes.
## Frame 03 uses the mill's cleared stream-side apron, nearly normal to the
## wheel plane, proving the complete headrace/wheel/tailrace path at ordinary
## player height. Production wildlife
## remains present at authored homes but is reset and movement-frozen after the
## local stream settles, so elapsed capture time cannot manufacture an enormous
## foreground blocker.
## It deliberately does not share or modify tools/_capture_locations.gd.
##
## Run with a real Compatibility renderer:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_old_mill_crossing_identity.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-old-mill-05

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_SERIAL := "final-old-mill-05"
const READY_TIMEOUT_MS := 420_000
const MILL := Vector2(-162.1, 4210.6)
const WHEEL := Vector2(-166.1, 4209.3)
const WHEEL_NODE := "MillCrossing/Mill/OldMillWaterWheel"
const MILL_ROOT := "MillCrossing/Mill"
const FOUNDATION_NODE := MILL_ROOT + "/OldMillGroundedFoundation"
const RACE_ROOT := MILL_ROOT + "/OldMillHeadrace"
const R5_PROOF_NODES := {
	"foundation": FOUNDATION_NODE,
	"headrace_stringer": RACE_ROOT + "/TroughBed",
	"installed_support": RACE_ROOT + "/InstalledHeadraceBrace1Outer",
	"source": RACE_ROOT + "/SourceIntakeWater",
	"wheel_contact": RACE_ROOT + "/FeedDrop",
	"wheel": WHEEL_NODE,
	"discharge": RACE_ROOT + "/WheelDischarge",
	"tailrace": RACE_ROOT + "/TailraceWater",
	"outfall": RACE_ROOT + "/TailraceOutfall",
}
const MAX_NEAR_WILDLIFE_DISTANCE_M := 18.0
const MAX_NEAR_WILDLIFE_FRAME_SHARE := 0.28

const VIEWS := [
	{"name": "01-south-arrival", "stand": Vector2(-152.0, 4168.0),
		"target": Vector2(-157.0, 4207.0), "aim_up": 5.2, "back": 2.0, "up": 3.0, "fov": 60.0},
	{"name": "02-gate-and-wheel", "stand": Vector2(-143.0, 4181.0),
		"target": WHEEL, "target_node": WHEEL_NODE, "aim_up": 0.0,
		"back": 1.8, "up": 2.9, "fov": 55.0},
	# This remains an ordinary on-foot apron stand. Its revised angle looks nearly
	# normal to the wheel plane, so upstream flume, exposed contact, wheel and
	# downstream tailrace spread laterally instead of hiding one another in depth.
	{"name": "03-hydraulic-chain-three-quarter", "stand": Vector2(-168.0, 4224.5),
		"target": WHEEL, "target_node": WHEEL_NODE, "aim_up": 0.0,
		"back": 1.6, "up": 2.8, "fov": 62.0},
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
			var r5_proof := _verify_r5_projection(world, camera, str(view.name))
			var proof_failures := r5_proof.get("failures", []) as Array
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
				"r5_visual_proof": r5_proof.get("metrics", {}),
			})
			print("wrote %s" % path)

	var manifest := {
		"capture_serial": CAPTURE_SERIAL,
		"production_scene": SCENE,
		"named_location": "Old Mill Crossing",
		"r5_required_nodes": R5_PROOF_NODES,
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
## also requires the four water beats to remain separated on screen, and rejects
## a wheel almost wholly enveloped by the foundation or headrace projections.
func _verify_r5_projection(world: Node3D, camera: Camera3D, view_name: String) -> Dictionary:
	var failures: Array[String] = []
	var metrics := {}
	var nodes := {}
	for key: String in R5_PROOF_NODES:
		var node := world.get_node_or_null(NodePath(str(R5_PROOF_NODES[key]))) as Node3D
		if node == null:
			failures.append("R5 proof node missing: %s" % key)
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
				"wheel": Vector2(24.0, 24.0),
				"wheel_contact": Vector2(3.0, 7.0),
				"installed_support": Vector2(2.0, 5.0),
			}
		"03-hydraulic-chain-three-quarter":
			required = {
				"foundation": Vector2(24.0, 24.0),
				"headrace_stringer": Vector2(2.0, 22.0),
				"installed_support": Vector2(3.0, 8.0),
				"source": Vector2(4.0, 8.0),
				"wheel_contact": Vector2(4.0, 8.0),
				"wheel": Vector2(34.0, 34.0),
				"discharge": Vector2(4.0, 8.0),
				"tailrace": Vector2(4.0, 22.0),
				"outfall": Vector2(3.0, 6.0),
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
			failures.append("R5 %s is not projected/readable (%.1fx%.1f px; need %.1fx%.1f)" % [
				key, rect.size.x, rect.size.y, minimum.x, minimum.y])

	if view_name == "03-hydraulic-chain-three-quarter":
		var sequence := ["source", "wheel_contact", "discharge", "outfall"]
		var screen_points: Array[Vector2] = []
		for key: String in sequence:
			screen_points.append(camera.unproject_position(_visual_world_centre(nodes[key] as Node3D)))
		var segment_lengths: Array[float] = []
		for i in screen_points.size() - 1:
			var length := screen_points[i].distance_to(screen_points[i + 1])
			segment_lengths.append(snappedf(length, 0.1))
			if length < 10.0:
				failures.append("R5 hydraulic beats %s -> %s collapse together on screen (%.1f px)" % [
					sequence[i], sequence[i + 1], length])
		var total_span := screen_points.front().distance_to(screen_points.back())
		metrics["hydraulic_segment_lengths_px"] = segment_lengths
		metrics["hydraulic_total_span_px"] = snappedf(total_span, 0.1)
		if total_span < 90.0:
			failures.append("R5 source-to-outfall chain spans only %.1f px" % total_span)

		var wheel_bounds := bounds["wheel"] as Rect2
		for blocker_key in ["foundation", "headrace_stringer"]:
			var overlap := _rect_overlap_share(wheel_bounds, bounds[blocker_key] as Rect2)
			metrics["wheel_%s_overlap_share" % blocker_key] = snappedf(overlap, 0.001)
			if overlap >= 0.82:
				failures.append("R5 wheel is %.0f%% enveloped by %s projection" % [
					overlap * 100.0, blocker_key])
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
	var minimum := points.front()
	var maximum := points.front()
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
