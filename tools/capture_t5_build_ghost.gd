extends SceneTree

## T5-CARE visual evidence: does the build ghost read against the grass field?
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_t5_build_ghost.gd
##
## Exit criterion H1 asks that a basic shelter be "fast and pleasant" to build.
## The lane brief asks the narrower question a frame can actually answer: *does
## the ghost read clearly against grass?* Nobody has looked.
##
## Deliberately shot through the REAL world and the REAL placer -- the ghost in
## these frames is the one `build_placer.gd::_show_ghost()` builds, armed by
## setting `Game.pending_build` exactly as the catalogue does, standing on the
## real Meadows terrain with the real grass field. It is NOT a staged mesh on a
## flat plane, because the whole question is contrast against grass and a
## staged plane would answer a different one.
##
## `tools/capture_check.gd` runs at every shutter, per the evidence rule in
## `ralph/MEADOWS_EXIT_CRITERION.md`: a frame that quietly lost the grass field
## would otherwise be evidence for the opposite conclusion.
##
## Software rendering (D06 Compatibility). Composition, contrast and silhouette
## are trustworthy here; fine lighting judgements and frame times are not.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const OUT_DIR := "res://shots/t5-care"
const SETTLE_FRAMES := 300
const POSE_FRAMES := 12

## The Practice Meadow clearing -- the opening's own build patch, which is
## grass, and the place the chapter actually asks the player to build.
const PATCH := Vector2(30.0, -40.0)

## One shot per piece the opening's camp needs, plus the creature bed the care
## lesson needs. `valid`/`invalid` is the ghost's own tint state.
const SHOTS: Array = [
	["ghost-camp", "camp"],
	["ghost-creature-bed", "creature_bed"],
	["ghost-floor", "floor"],
	["ghost-wall", "wall"],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("T5> BLOCKED: no Game autoload")
		quit(1)
		return
	# Ordinary paid stock, so the ghost is the one a player with materials sees
	# rather than a free-build ghost with different refusal behaviour.
	game.set("free_build", false)
	var inventory: RefCounted = game.get("inventory")
	for id in ["wood", "stone", "fiber"]:
		inventory.call("add", id, 300)

	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var camera := _find_camera(world)
	if player == null or camera == null:
		print("T5> BLOCKED: no player or no current camera in the real world")
		quit(1)
		return

	# Stand the player on the build patch and let the terrain settle under them.
	var ground := float(world.call("ground_height_at", PATCH.x, PATCH.y))
	player.global_position = Vector3(PATCH.x, ground + 1.0, PATCH.y)
	player.velocity = Vector3.ZERO
	player.global_rotation = Vector3.ZERO
	for i in 120:
		await physics_frame

	var placer := _find_placer(world)
	if placer == null:
		print("T5> BLOCKED: the world has no BuildPlacer")
		quit(1)
		return

	var written: Array[String] = []
	var failures: Array[String] = []
	for entry: Variant in SHOTS:
		var shot := str((entry as Array)[0])
		var piece := str((entry as Array)[1])
		# Arm it the way the catalogue does. The placer's own _physics_process
		# then builds and positions the ghost -- this tool never places one.
		game.set("pending_build", piece)
		for i in 30:
			await physics_frame

		var ghost: Node3D = placer.get("_ghost") as Node3D
		if ghost == null or not is_instance_valid(ghost):
			failures.append("%s: arming '%s' produced no ghost at all" % [shot, piece])
			continue

		# Frame the ghost from just behind and above the player's shoulder --
		# the angle the player is actually looking from when they place.
		var at := ghost.global_position
		var eye := at + Vector3(0.0, 3.4, 6.0)
		camera.global_position = eye
		camera.look_at(at + Vector3.UP * 0.6, Vector3.UP)
		for i in 20:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame

		# The evidence rule. Warn rather than abort so one bad pose does not
		# cost the whole set, but every problem is printed beside its frame.
		var problems: Array = CAPTURE_CHECK.warn_only(self, camera)
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % shot)
			continue
		var path := "%s/%s.png" % [OUT_DIR, shot]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [shot, error])
			continue
		written.append(path)
		print("T5> %-22s ghost at (%.1f, %.2f, %.1f)  capture_check problems: %d %s" % [
			shot, at.x, at.y, at.z, problems.size(),
			str(problems) if not problems.is_empty() else ""])

	game.set("pending_build", "")
	print("")
	print("T5> %d frames -> %s" % [written.size(), OUT_DIR])
	print("T5> Software rendering. Frame times from this harness are NOT a performance measurement.")
	for line in failures:
		print("T5> FAIL: %s" % line)
	quit(1 if not failures.is_empty() else 0)


func _find_camera(world: Node) -> Camera3D:
	for node in world.find_children("*", "Camera3D", true, false):
		var camera := node as Camera3D
		if camera != null and camera.current:
			return camera
	for node in world.find_children("*", "Camera3D", true, false):
		return node as Camera3D
	return null


func _find_placer(world: Node) -> Node:
	for node in world.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("build_placer.gd"):
			return node
	return null
