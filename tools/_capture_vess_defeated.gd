extends SceneTree

## Vess-officer evidence render (STATE ruling 11). Captain Vess (`captain_ridge`)
## now stands on the female officer body `officer_b`, which gained a `defeated`
## clip. This photographs her at her own post through the real placement code:
## idle, then the defeated slump trainer_npc.gd plays when she is beaten.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_capture_vess_defeated.gd
##
## Never `--headless` with a real rendering driver. Scratch/evidence tool,
## not wired into any test. Built on tools/_capture_t1_cast_world.gd's setup.

const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/MEADOWS/vess-officer"
const TRAINER_ID := "captain_ridge"

const SETTLE_FRAMES := 60
const STREAM_SETTLE_FRAMES := 30
const POSE_FRAMES := 6
const FOV := 60.0
## Stand in front of her along her facing, at a conversation distance and at
## the fight-camera distance the reaction must read from.
const SHOTS := [
	{"name": "01-vess-idle-4m", "clip": "idle", "distance": 4.0, "seek": 1.0},
	{"name": "02-vess-defeated-4m", "clip": "defeated", "distance": 4.0, "seek": 1.5},
	{"name": "03-vess-defeated-8m", "clip": "defeated", "distance": 8.0, "seek": 1.5},
]


func _init() -> void:
	_run()


func _find_trainer(node: Node) -> Node3D:
	if node is Node3D and str(node.get_meta("trainer_id", "")) == TRAINER_ID:
		return node as Node3D
	for child in node.get_children():
		var found := _find_trainer(child)
		if found != null:
			return found
	return null


func _anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _anim_player(child)
		if found != null:
			return found
	return null


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_hide_canvas_layers(world)

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 3000.0
	# `root` on a SceneTree IS the Window; parent the camera into the world the
	# same way `_judge_capture_hall.gd` does, so `capture_check.gd` finds the
	# grass field's own tree from it.
	world.add_child(camera)
	camera.make_current()

	# Hand Terrain3D and the weather/look rig to THIS camera, exactly as
	# `_judge_capture_hall.gd` does. Round 1 of this tool skipped both and
	# `capture_check` refused the frames for it -- "Terrain3D is streaming
	# around 'Camera3D', not the capture camera" and "WorldWeather is still
	# processing -- the weather pin will drift across a multi-shot pass". That
	# is the check earning its keep: without it these would have been committed
	# as cast evidence while streaming around the wrong camera, which is the
	# precise failure that invalidated this project's earlier visual evidence.
	var terrain: Node = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	# `grass_field.gd` builds its tuft ring around the PLAYER, and Terrain3D's
	# streaming bubble follows it too, so a stand 7km up the map from spawn
	# renders on bare far-cover ground with no grass in it -- the exact "no
	# grass" defect that invalidated this project's earlier evidence. The
	# player goes where the camera goes; it is hidden and frozen either way.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var field: RefCounted = HEIGHTFIELD.new()
	# Her authored post; carry the player there so her band's placer, the
	# terrain bubble and the grass ring all stream in around her.
	var post := Vector2(-280.0, 6460.0)
	if player != null:
		player.global_position = Vector3(post.x, float(field.call("height_at", post.x, post.y)) + 1.7, post.y + 6.0)
	for i in STREAM_SETTLE_FRAMES * 3:
		await physics_frame
	var vess := _find_trainer(world)
	if vess == null:
		push_error("no body placed for %s" % TRAINER_ID)
		quit(1)
		return
	var model_path := ""
	for child in vess.find_children("*", "Node3D", true, false):
		if str(child.scene_file_path) != "":
			model_path = child.scene_file_path
			break
	print("[vess] body at %s facing %.1f deg, model %s" % [vess.global_position, rad_to_deg(vess.rotation.y), model_path])
	var failures: Array[String] = []
	var written := 0
	for shot: Dictionary in SHOTS:
		var clip := str(vess.call("clip_for", str(shot["clip"]), ""))
		print("[vess] %s resolves %s -> '%s'" % [shot["name"], shot["clip"], clip])
		vess.call("play", clip, false)
		var forward := Vector3(sin(vess.rotation.y), 0.0, cos(vess.rotation.y))
		var at := vess.global_position
		var eye := at + forward * float(shot["distance"])
		eye.y = float(field.call("height_at", eye.x, eye.z)) + 1.6
		var target := at + Vector3(0.0, 1.0, 0.0)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		if player != null:
			player.global_position = eye + Vector3(0.0, 0.0, 0.0)
		for pass_index in 2:
			for i in STREAM_SETTLE_FRAMES:
				await physics_frame
			for i in POSE_FRAMES:
				await process_frame
		var ap := _anim_player(vess)
		if ap != null and clip != "":
			ap.seek(float(shot["seek"]), true)
			ap.pause()
		await process_frame
		var problems: Array = CAPTURE_CHECK.warn_only(self, camera, "clear", null,
			[player] if player != null else [])
		if not problems.is_empty():
			failures.append("%s: %s" % [shot["name"], ", ".join(problems)])
		await process_frame
		var image := camera.get_viewport().get_texture().get_image()
		var path: String = "%s/%s.png" % [OUT_DIR, shot["name"]]
		image.save_png(ProjectSettings.globalize_path(path))
		print("  %-28s -> %s" % [shot["name"], path])
		written += 1
	print("\n%d frames -> %s" % [written, OUT_DIR])
	if failures.is_empty():
		print("[capture_check] every frame passed")
	else:
		print("[capture_check] PROBLEMS -- do not judge these as the shipping game:")
		for f: String in failures:
			print("  %s" % f)
	quit()
