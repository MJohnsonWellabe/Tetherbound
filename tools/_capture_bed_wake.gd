extends SceneTree

## OPENING-BED-0903. What the interior camera actually shows during the WAKE
## beat, reproduced the way `sequence_director.gd::_spawn_the_cast()` really
## stages it — not `capture_loft_exit.gd`'s panorama (which teleports the
## player to the GET-UP spot and keeps the lying pose only as an artefact of
## never clearing it) and not `capture_interior.gd` (which never poses lying
## at all, since it builds no SequenceDirector).
##
## This script poses the trainer exactly as the real beat does — lying, at
## the bed marker offset by BED_LIE_REACH, `Model.set_lying(true)` — then
## hands the camera rig `INTERIOR_PROFILE` through the same `set_target` seam
## `grandpa_house.gd`'s own Area3D calls on entry, and lets `_follow()`/
## `_apply_look()` settle the rig on their own (default yaw/pitch, matching a
## fresh game where the player has not touched the camera yet) rather than
## forcing a vantage — the point is what a first-time player's camera
## actually frames, not a chosen angle.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_bed_wake.gd -- <out_dir>

const GRANDPA_HOUSE := preload("res://scripts/world/grandpa_house.gd")
const CAMERA_RIG_SCRIPT := preload("res://scripts/player/camera_rig.gd")
const WORLD_LOOK_SCRIPT := preload("res://scripts/world/world_look.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

const SETTLE_FRAMES := 40
const CAMERA_SETTLE_FRAMES := 90
const BED_LIE_REACH := 1.5


func _init() -> void:
	_run()


func _house_const(house: Node3D, key: String) -> Variant:
	return house.get_script().get_script_constant_map().get(key)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "res://shots/bed_wake"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))

	var world := Node3D.new()
	root.add_child(world)
	await process_frame

	_build_lighting(world)
	var rig := _build_camera_rig(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	player.name = "Player"
	world.add_child(player)

	var house := GRANDPA_HOUSE.new()
	house.name = "GrandpaHouse"
	house.position = Vector3.ZERO
	world.add_child(house)
	house.call("build", rig, player)

	for i in SETTLE_FRAMES:
		await process_frame

	# Exactly sequence_director.gd::_spawn_the_cast()'s own WAKE staging: the
	# bed marker, offset toward the foot of the bed by BED_LIE_REACH, then the
	# body posed lying.
	var bed: Vector3 = house.call("marker", "bed")
	player.global_position = Vector3(bed.x, bed.y + 0.05, bed.z + BED_LIE_REACH)
	player.velocity = Vector3.ZERO
	var model := player.get_node_or_null(^"Model")
	if model != null and model.has_method("set_lying"):
		model.call("set_lying", true)
	else:
		push_error("no trainer Model / set_lying — cannot reproduce the wake pose")

	# The same call grandpa_house.gd's own Area3D fires on entry. Default
	# yaw/pitch (0.0, 0.0), matching a fresh game where the player has not
	# touched the camera yet.
	rig.call("set_target", player, _house_const(house, "INTERIOR_PROFILE"))

	for i in CAMERA_SETTLE_FRAMES:
		await process_frame

	var image := root.get_texture().get_image()
	image.save_png("%s/wake-default-camera.png" % out)
	print("shot -> %s/wake-default-camera.png" % out)

	# A second, top-down-ish vantage that does not depend on the rig's own
	# follow/collision behaviour at all, so the bed and whatever is lying on
	# it can be judged independent of any camera-framing bug found above.
	var overhead := Camera3D.new()
	overhead.fov = 55.0
	overhead.far = 100.0
	world.add_child(overhead)
	overhead.global_position = bed + Vector3(0.0, 2.4, 1.6)
	overhead.look_at(bed, Vector3.FORWARD)
	overhead.make_current()
	for i in 20:
		await process_frame
	image = root.get_texture().get_image()
	image.save_png("%s/wake-overhead.png" % out)
	print("shot -> %s/wake-overhead.png" % out)

	print("done: %s" % out)
	quit(0)


func _build_lighting(world: Node3D) -> DirectionalLight3D:
	var env_holder := WorldEnvironment.new()
	env_holder.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	env.fog_enabled = true
	env_holder.environment = env
	world.add_child(env_holder)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	world.add_child(sun)

	var look := Node.new()
	look.name = "WorldLook"
	look.set_script(WORLD_LOOK_SCRIPT)
	look.set("sun_path", NodePath("../Sun"))
	look.set("environment_path", NodePath("../WorldEnvironment"))
	world.add_child(look)
	return sun


func _build_camera_rig(world: Node3D) -> SpringArm3D:
	var rig := SpringArm3D.new()
	rig.name = "CameraRig"
	rig.spring_length = 5.2
	rig.margin = 0.6
	rig.set_script(CAMERA_RIG_SCRIPT)
	world.add_child(rig)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 70.0
	camera.far = 2000.0
	rig.add_child(camera)
	return rig
