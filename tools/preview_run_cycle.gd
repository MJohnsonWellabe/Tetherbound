extends SceneTree

## Photograph the trainer RUNNING, over time, in the real game.
##
##   xvfb-run -a -s "-screen 0 1200x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1200x900 \
##     --script tools/preview_run_cycle.gd
##
## `preview_arms.gd` answers "is this the right pose", by seeking one clip to a
## phase and holding it there. It cannot answer "does the animation keep
## playing", because seeking is exactly what a stopped AnimationPlayer will still
## do for you. A clip that has run past its end and is holding its last frame
## renders identically to one that is playing, in any single still, from any
## angle.
##
## So this holds the stick down and takes the picture repeatedly. The player is
## driven through the real input actions in the real playground scene — the same
## path `tests/smoke_input.gd` uses — because the bug being looked for lives in
## the state machine that chooses the clip and in the way it is played, not in
## the clip. Driving the AnimationPlayer directly would step straight over it.
##
## Two things come out. A strip of frames sampled across several seconds of held
## sprint, and — printed, because a strip of pictures is not a measurement — the
## skeleton's pose recorded as numbers at each sample. If consecutive samples
## report the same pose fingerprint while `ground_speed` is still 7 m/s, the
## trainer is sliding along the ground in a frozen pose, and that is the bug in
## figures rather than in an impression.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/_run_cycle.png"

## Long enough for terrain to stream and collision to build. Same figure the
## smokes use.
const SETTLE_FRAMES := 240

## Physics frames between samples, and how many samples. 12 frames is 0.2s, so
## sixteen samples span 3.2 seconds — four times the length of `Running_A`, which
## is what it takes for "it stopped after one cycle" to be visible rather than
## arguable.
const SAMPLE_EVERY := 12
const SAMPLES := 16

const CROP := Vector2i(300, 440)

## Side-on, from the trainer's own left. A run cycle is legs and arms swinging
## fore and aft, and that plane is edge-on to the camera in any front view.
const EYE := Vector3(3.2, 1.15, 0.0)


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		print("FAIL: no player")
		quit(1)
		return
	var model: Node3D = player.get_node_or_null(^"Model") as Node3D
	var anim := _animation_player(model)
	var skeleton := _skeleton(model)
	if anim == null or skeleton == null:
		print("FAIL: the trainer has no AnimationPlayer or no Skeleton3D")
		quit(1)
		return

	var camera := Camera3D.new()
	camera.fov = 42.0
	world.add_child(camera)
	camera.make_current()

	Input.action_press("move_forward")
	Input.action_press("sprint")

	var frames: Array[Image] = []
	var last := ""
	print("t      speed  clip          playing  pos     pose")
	for s in SAMPLES:
		for i in SAMPLE_EVERY:
			await physics_frame
		var pose := _fingerprint(skeleton)
		print("%5.2f  %5.2f  %-12s  %-7s  %5.2f  %s%s" % [
			(s + 1) * SAMPLE_EVERY / 60.0,
			player.call("ground_speed"),
			anim.current_animation,
			str(anim.is_playing()),
			anim.current_animation_position,
			pose,
			"   <- SAME POSE AS THE SAMPLE BEFORE" if pose == last else "",
		])
		last = pose
		var shot := await _shoot(camera, player, model)
		if shot != null:
			frames.append(shot)

	Input.action_release("move_forward")
	Input.action_release("sprint")

	var strip := _tile(frames)
	if strip != null:
		strip.save_png(OUT)
		print("wrote %s  (%d frames, %.2fs apart, left to right)" % [
			OUT, frames.size(), SAMPLE_EVERY / 60.0
		])
	quit(0)


## One frame, framed side-on to whichever way the trainer is currently facing, so
## the figure sits in the same place in every sample and the only thing that
## changes between them is the pose.
func _shoot(camera: Camera3D, player: Node3D, model: Node3D) -> Image:
	var yaw: float = 0.0 if model == null else model.rotation.y
	var eye := Basis(Vector3.UP, yaw) * EYE
	var feet := player.global_position
	camera.global_position = feet + eye
	camera.look_at(feet + Vector3(0.0, 0.95, 0.0), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot == null:
		return null
	var at := Vector2i(
		int((shot.get_width() - CROP.x) * 0.5), int((shot.get_height() - CROP.y) * 0.5)
	)
	return shot.get_region(Rect2i(at, CROP))


## The skeleton's pose as a short string, so two samples can be compared exactly.
##
## Limb bones only, and in the SKELETON's space rather than the world's: the
## trainer is travelling, so a fingerprint taken from global transforms would
## change every frame no matter what the animation was doing, which is precisely
## the false negative this is here to avoid.
func _fingerprint(skeleton: Skeleton3D) -> String:
	var out := ""
	for bone: String in ["DEF-thigh.L", "DEF-shin.L", "DEF-upper_arm.L", "DEF-forearm.R"]:
		var index := skeleton.find_bone(bone)
		if index < 0:
			continue
		var q := skeleton.get_bone_pose_rotation(index)
		out += "%.2f,%.2f,%.2f " % [q.x, q.y, q.z]
	return out


func _tile(frames: Array[Image]) -> Image:
	if frames.is_empty():
		return null
	var w: int = frames[0].get_width()
	var h: int = frames[0].get_height()
	var across: int = mini(8, frames.size())
	var down: int = int(ceil(float(frames.size()) / across))
	var sheet := Image.create(w * across, h * down, false, frames[0].get_format())
	for i in frames.size():
		sheet.blit_rect(
			frames[i], Rect2i(0, 0, w, h), Vector2i(w * (i % across), h * (i / across))
		)
	return sheet


func _animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _animation_player(child)
		if found != null:
			return found
	return null


func _skeleton(node: Node) -> Skeleton3D:
	if node == null:
		return null
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _skeleton(child)
		if found != null:
			return found
	return null
