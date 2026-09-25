extends SceneTree

## Production-camera receipt for the six filled Tidewake reward pockets (F13).
## For each Skill Candy row bound to a pocket, the trainer stands on dry ground
## about 7 m from the pocket, the production CameraRig faces it, and one day
## frame is taken with the HUD. Only the trainer's pose is written; the pickups
## come from the ordinary Water pickup streamer.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_water_reward_pockets.gd -- --sheet=<png>

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const STAND_M := 7.0

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
	var field := FIELD.new()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	var frames: Array[Image] = []
	for row: Dictionary in data.pickups:
		if not row.has("reward_pocket_id"):
			continue
		var at := Vector2(float(row.position[0]), float(row.position[2]))
		var stand := _stand_point(field, at)
		player.global_position = Vector3(stand.x, field.height_at(stand.x, stand.y) + 0.2, stand.y)
		player.velocity = Vector3.ZERO
		var toward := at - stand
		camera.set("yaw", atan2(-toward.x, -toward.y))
		for _frame in 90:
			await physics_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.convert(Image.FORMAT_RGB8)
		frames.append(image)
		labels.append("%s@%s" % [str(row.reward_pocket_id), str(row.id)])
	if frames.is_empty():
		push_error("no pocket rows found")
		quit(1)
		return
	var width := frames[0].get_width() / 2
	var height := frames[0].get_height() / 2
	var sheet := Image.create(width * 3, height * 2, false, Image.FORMAT_RGB8)
	for index in frames.size():
		var small := frames[index].duplicate() as Image
		small.resize(width, height, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(small, Rect2i(0, 0, width, height), Vector2i((index % 3) * width, (index / 3) * height))
	var target := _arg("sheet")
	target = target if target.begins_with("/") else ProjectSettings.globalize_path(target)
	sheet.save_png(target)
	print("POCKET CAPTURE OK frames=%d order=%s" % [frames.size(), ",".join(labels)])
	quit(0)


## A dry standing point STAND_M from the pocket, preferring the gentlest
## direction so the trainer is not placed on a cliff face.
func _stand_point(field: RefCounted, at: Vector2) -> Vector2:
	var best := at + Vector2(STAND_M, 0.0)
	var best_slope := INF
	for step in 16:
		var candidate := at + Vector2(cos(TAU * step / 16.0), sin(TAU * step / 16.0)) * STAND_M
		var height: float = field.height_at(candidate.x, candidate.y)
		if height < 0.8:
			continue
		var slope: float = field.slope_degrees_at(candidate.x, candidate.y)
		if slope < best_slope:
			best_slope = slope
			best = candidate
	return best
