extends SceneTree

## Production-camera receipt for the filled Tidewake reward pockets (F13) and
## the Cradle care nest. For each pocket row the trainer stands ON THE REAL
## APPROACH: the baked-ground route `tests/smoke_water_pocket_walk_claim.gd`
## walks from the island's arrival landing, at the route point about STAND_M
## short of the find. The production CameraRig looks along that approach,
## pitched down over the ground cover and turned a few degrees so the trainer
## does not cover the find. One day frame per pocket with the HUD. Only the
## trainer's pose and the camera's yaw/pitch are written; the finds come from
## the ordinary Water pickup streamer.
##
## The frame reports, from the camera itself, whether the find's centre is
## inside the view and unoccluded by physics geometry. Ground cover has no
## collision, so "unoccluded" is not "visible": the sheet is the evidence.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_water_reward_pockets.gd -- --sheet=<jpg|png>

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const WALK := preload("res://tests/smoke_water_pocket_walk_claim.gd")
const STAND_M := 5.0
const PITCH_DEG := -24.0
const YAW_OFFSET_DEG := 14.0
const TILE := Vector2i(426, 240)

var labels: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _arg(name: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % name):
			return argument.trim_prefix("--%s=" % name)
	return ""


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("pocket capture requires a rendering display")
		quit(1)
		return
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	var world := WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var look := world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
	var player := world.get_node(^"Player") as CharacterBody3D
	var camera := world.get_node(^"CameraRig") as Node3D
	var config: Dictionary = world.get("config")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	var frames: Array[Image] = []
	var seen := {}
	for row: Dictionary in data.pickups:
		var pocket := str(row.get("reward_pocket_id", ""))
		if pocket.is_empty() or seen.has(pocket):
			continue
		seen[pocket] = true
		var at := Vector2(float(row.position[0]), float(row.position[2]))
		var landing := _landing(config, str(row.island_id))
		var plan: Dictionary = WALK.plan_route(world, Vector2(landing.x, landing.z), at)
		var stand := _stand_on_route(plan.points, Vector2(landing.x, landing.z), at)
		player.global_position = Vector3(stand.x, float(world.call("ground_height_at", stand.x, stand.y)) + 0.2, stand.y)
		player.velocity = Vector3.ZERO
		var toward := at - stand
		var yaw := atan2(-toward.x, -toward.y)
		player.rotation.y = yaw
		camera.set("yaw", yaw + deg_to_rad(YAW_OFFSET_DEG))
		camera.set("pitch", deg_to_rad(PITCH_DEG))
		for _frame in 90:
			await physics_frame
		await RenderingServer.frame_post_draw
		var view := _view_of(world, str(row.id))
		var image := root.get_texture().get_image()
		image.convert(Image.FORMAT_RGB8)
		frames.append(image)
		labels.append("%s stand=%.1fm in_view=%s unoccluded=%s" % [pocket, stand.distance_to(at), view.in_view, view.clear])
	if frames.is_empty():
		push_error("no pocket rows found")
		quit(1)
		return
	var columns := 3
	var rows := ceili(frames.size() / float(columns))
	var sheet := Image.create(TILE.x * columns, TILE.y * rows, false, Image.FORMAT_RGB8)
	for index in frames.size():
		var small := frames[index].duplicate() as Image
		small.resize(TILE.x, TILE.y, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(small, Rect2i(Vector2i.ZERO, TILE), Vector2i((index % columns) * TILE.x, (index / columns) * TILE.y))
	var target := _arg("sheet")
	target = target if target.begins_with("/") else ProjectSettings.globalize_path(target)
	if target.ends_with(".jpg"):
		sheet.save_jpg(target, 0.82)
	else:
		sheet.save_png(target)
	print("POCKET CAPTURE OK frames=%d" % frames.size())
	for line: String in labels:
		print("  ", line)
	quit(0)


## The route point about STAND_M before the find, walking the planned route
## from the landing; the landing-side fallback keeps the approach bearing.
func _stand_on_route(points: Array, landing: Vector2, at: Vector2) -> Vector2:
	var previous := landing
	for point: Vector2 in points:
		if point.distance_to(at) <= STAND_M and previous.distance_to(at) > STAND_M:
			return previous.move_toward(point, previous.distance_to(at) - STAND_M) \
				if previous.distance_to(point) > 0.01 else previous
		previous = point
	return at + (landing - at).normalized() * STAND_M


## Whether the find's centre projects inside the camera's frame and no physics
## body stands between the camera and it.
func _view_of(world: Node3D, id: String) -> Dictionary:
	var node: Node3D = world.get_node(^"WaterPickups").call("node_for", id)
	var eye := root.get_viewport().get_camera_3d()
	if node == null or eye == null:
		return {"in_view": false, "clear": false}
	var point := node.global_position + Vector3.UP * 0.3
	var screen := eye.unproject_position(point)
	var inside := not eye.is_position_behind(point) and Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(screen)
	var query := PhysicsRayQueryParameters3D.create(eye.global_position, point)
	var player := world.get_node(^"Player") as CollisionObject3D
	query.exclude = [player.get_rid()]
	var hit := eye.get_world_3d().direct_space_state.intersect_ray(query)
	return {"in_view": inside, "clear": hit.is_empty() or hit.collider == node or node.is_ancestor_of(hit.collider as Node)}


func _landing(config: Dictionary, island_id: String) -> Vector3:
	for anchor: Dictionary in config.anchors:
		if str(anchor.island_id) == island_id and str(anchor.kind) == "arrival":
			var at: Array = anchor.safe_position
			return Vector3(float(at[0]), float(at[1]), float(at[2]))
	return Vector3.INF
