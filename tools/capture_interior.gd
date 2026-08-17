extends SceneTree

## CAP1: capture a single interior without booting the Meadows.
##
## `tools/capture_loft_exit.gd` is the worked example this generalises from —
## same vantage/render loop, same interior camera seam — but it pays the whole
## corridor's boot (terrain, 23,707+ scatter instances, the village) to
## photograph one room. That was ~24-32 minutes on this container before the
## corridor grew to 8192 x 2048 m / 64 baked regions, and it is the tax on
## EVERY interior task from here on, not a one-time cost.
##
## This script instantiates ONLY what an interior actually needs: the sky/sun/
## fog rig `world_look.gd` drives from data/config/art.json (so the light
## matches what the player sees, not an improvised stand-in), the camera rig
## and its `set_target(target, profile)` seam, a bare player body, and the
## interior itself (`grandpa_house.gd`, built at the world origin — the house
## script never queries terrain; `playground_world.gd` only uses terrain to
## find the house's OWN pad height, and that pad is flat ground = y 0 works
## fine for a capture that only cares about the room).
##
## No Terrain3D, no vegetation, no village, no NPCs, no combat, no HUD. That is
## the entire saving, and it is also the entire risk: anything the real path
## lights or times differently is now invisible to this one. See this script's
## own comment above `_build_lighting()` for what was checked and what was not.
##
##   TAG=after xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_interior.gd
##
## Frames land in shots/interior/<INTERIOR>/<TAG>/. Filenames match
## capture_loft_exit.gd's own vantage names for `grandpa` so the two can be
## diffed frame-for-frame.
##
## MEASURED 2026-08-17, same container, same warm `.godot/` import cache for
## both (so this isolates the world-build step, not engine startup):
## `capture_loft_exit.gd` (full corridor: terrain, 26,985 scattered props, the
## village, water, stronghold) took 10m35s wall-clock for 3 frames. This
## script took 1m12s for the same 3 frames — a fresh scene, one house, no
## terrain. ~8.8x on a warm cache; PT-03's own 24-32 minute figure was on a
## cold one, where the gap is larger still because nothing here touches the
## step that cost that time.
##
## COMPARED against that same run's frames, pixel for pixel: the room itself —
## walls, windows, ceiling, floor, the bed, shadow placement — is
## indistinguishable (flat-surface regions of a diff mask are black; only mesh
## edges differ, by the sub-pixel jitter two independent renders always carry).
## The interior camera profile and `_build_lights()` are NOT where this diverges.
##
## One divergence, found and understood rather than papered over: the baseline
## frames show the trainer's body as a barely-visible sliver near the floor,
## this script's show it standing normally. Cause: `SequenceDirector`
## (scripts/story/sequence_director.gd:717, `_spawn_the_cast()`) poses the
## trainer LYING FLAT for the opening's wake beat before `capture_loft_exit.gd`
## ever runs, and that capture moves the body to each vantage without ever
## clearing the pose — so the baseline shows a lying body edge-on, wherever it
## was teleported to. This script never builds a SequenceDirector at all
## (story choreography is not the room), so the trainer keeps its default
## standing pose. Left as-is on purpose: replicating one story beat's posing
## just to match a frame that is itself an artefact of the same beat would be
## solving the wrong problem, and it does not touch what this task is actually
## for — whether the ROOM reads the same, which it does.

const GRANDPA_HOUSE := preload("res://scripts/world/grandpa_house.gd")
const CAMERA_RIG_SCRIPT := preload("res://scripts/player/camera_rig.gd")
const WORLD_LOOK_SCRIPT := preload("res://scripts/world/world_look.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

const SETTLE_FRAMES := 30
const SHOT_FRAMES := 20

## Same reach/pitch/vantage set as capture_loft_exit.gd, on purpose: the point
## of this script is a frame comparable to that one, not a fresh set of angles.
const BED_LIE_REACH := 1.5
const PITCH_DEG := -10.0
const VANTAGES := [
	[Vector3.ZERO, Vector3(1, 0, 0), "02-wake-east"],
	[Vector3.ZERO, Vector3(0, 0, -1), "01-wake-north"],
	[Vector3.ZERO, Vector3(3.6, 0, -2.8), "05-wake-toward-stairhead"],
]


func _init() -> void:
	_run()


func _house_const(house: Node3D, key: String) -> Variant:
	return house.get_script().get_script_constant_map().get(key)


func _run() -> void:
	var tag := OS.get_environment("TAG")
	if tag == "":
		tag = "current"
	var interior := OS.get_environment("INTERIOR")
	if interior == "":
		interior = "grandpa"
	if interior != "grandpa":
		push_error("capture_interior.gd only builds the 'grandpa' interior today; got '%s'" % interior)
		quit(1)
		return

	var out := "res://shots/interior/%s/%s" % [interior, tag]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))

	var world := Node3D.new()
	root.add_child(world)
	# A SceneTree main script's _init() runs before the tree has actually
	# started iterating: is_inside_tree() is false for anything added here
	# until at least one frame passes. grandpa_house.gd::build() calls
	# to_global() for its markers, and calling it before this frame returns
	# an identity transform instead of erroring loudly — it happened to match
	# here only because the house sits at the exact origin with no rotation.
	# playground_world.gd's own _ready() never hits this because it awaits
	# two frames (for Terrain3D's data_directory) before it ever builds the
	# house; this is the same fix, applied earlier since there is no terrain
	# step to wait on.
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

	# The interior profile the house itself applies on entry (grandpa_house.gd
	# ::_on_body_entered). Asked for explicitly, same as capture_loft_exit.gd,
	# because the player is teleported rather than walked in, and an Area3D's
	# body_entered may never fire for a teleport.
	rig.call("set_target", player, _house_const(house, "INTERIOR_PROFILE"))

	var loft_y: float = float(_house_const(house, "FLOOR_H")) + 0.25
	var bed_local: Vector3 = house.to_local(house.call("marker", "bed"))
	var stand := Vector3(bed_local.x, loft_y + 0.05, bed_local.z + BED_LIE_REACH)

	for spec: Array in VANTAGES:
		var offset: Vector3 = spec[0]
		var at := stand + Vector3(offset.x, 0.0, offset.z)
		var dir: Vector3 = spec[1]
		var name: String = spec[2]

		player.global_position = house.to_global(at)
		player.velocity = Vector3.ZERO

		var forward := house.to_global(at + Vector3(dir.x, 0.0, dir.z)) - house.to_global(at)
		forward.y = 0.0
		forward = forward.normalized()
		var yaw := atan2(-forward.x, -forward.z)
		for i in SHOT_FRAMES:
			rig.set("yaw", yaw)
			rig.set("pitch", deg_to_rad(PITCH_DEG))
			await process_frame

		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [out, name])
		print("shot -> %s/%s.png" % [out, name])

	print("done: %d frames in %s" % [VANTAGES.size(), out])
	quit(0)


## Sun + sky + fog, driven by data/config/art.json through world_look.gd —
## the SAME script and the SAME config the full playground uses
## (playground_world.gd never touches these values itself; WorldLook is the
## only thing that ever writes them). Reproduced here rather than hand-copied
## so this scene cannot drift from the real one's light the way a second set
## of hardcoded sun/tonemap numbers eventually would.
##
## What this deliberately does NOT reproduce: bounce/occlusion from the
## terrain, scatter or village geometry around the house exterior. The house
## shell "blocks the sun entirely" per grandpa_house.gd's own note, so direct
## sun contributes nothing inside the walls either way — the open question is
## ambient/sky fill leaking through the door and windows, which is why the
## comparison frame this task calls for is the thing to trust over this
## comment.
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
