extends SceneTree

## OP-0830-3 evidence: does a world pickup actually read, in real grass, at the
## distance a player is standing when they need to notice it?
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##       --script tools/capture_pickup_glow.gd -- --tag=AFTER
##
## NOT `--headless`: that swaps in a no-op renderer and the run silently
## produces nothing (`capture_catch_sequence.gd`'s own header). Software
## rendering, so composition, silhouette and READABILITY are trustworthy here
## and lighting quality is not -- which is the right way round for this
## question.
##
## ## Why this shoots through the GAMEPLAY camera
##
## The lane order for this work names a known capture defect: frames that render
## with no grass geometry at all, so a glow that looks perfectly visible may be
## lying. `ralph/T1-GROUND-3` root-caused it and the cause is specific --
## `grass_field.gd` is BOUND to one camera (`bind(terrain, camera)`, called by
## `playground_world.gd` with the gameplay camera) and dresses the ground under
## THAT camera. A capture tool that builds its own free `Camera3D` therefore
## photographs ground the field is not dressing, and gets a bare frame.
##
## So this tool does not build a camera. It moves the PLAYER to the stand, lets
## the rig follow, and shoots through the game's own camera -- which is the one
## the grass field is following, and is also the only camera a player ever looks
## through. `_assert_real_grass()` then proves it frame by frame rather than
## trusting it: it finds the field's tuft MultiMesh, checks it has instances,
## and checks the ring has actually moved to where the shot is being taken from.
## Every frame's grass verdict is printed and written into the contact log, so a
## frame that WAS bare says so in the evidence rather than in a caption someone
## writes afterwards.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/T5-FEEL/shots"
const GLOW := preload("res://scripts/world/pickup_glow.gd")
## The ground lane's own shutter check (landed on main 2026-08-30). Used
## alongside this file's `_grass_verdict()` rather than instead of it: theirs is
## the authoritative, shared statement of "this frame would not show the build"
## and refuses loudly; mine prints the tuft count and the ring's distance from
## the lens into the contact log, so the evidence carries the number rather than
## a pass/fail somebody has to take on trust.
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")

## Settling is done on PHYSICS frames, which cost nothing here, and only the
## handful of frames that actually have to be DRAWN are drawn. Under software
## GL at 1280x720 with the grass ring's 315k tufts a rendered frame is seconds,
## so settling on `process_frame` (the obvious way to write this) turned a
## six-frame capture into a half-hour run and made every re-render a decision
## rather than a step.
const SETTLE_PHYSICS_FRAMES := 240
const SETTLE_DRAW_FRAMES := 6
## Physics frames to let the rig arrive at the new stand, then draw frames so
## the grass ring has actually followed and the shutter is not photographing the
## previous stand's cover.
##
## 120, not the 24 this started at, and the number is the SpringArm3D's. Moving
## the player between stands teleports them, which collapses the arm on
## intrusion; `camera_rig.gd` eases it back out at `_recover_speed` 4 m/s, so
## recovering the full 5.2m boom takes about 1.3 seconds -- 78 physics frames.
## At 24 the shutter opened while the camera was still inside the trainer's
## backpack, and three of six frames in the first pass were unusable for that
## reason alone. Physics frames cost nothing here; only the draw frames below
## are expensive.
const POSE_PHYSICS_FRAMES := 120
const POSE_DRAW_FRAMES := 10

## Each stand: a real authored pickup, the distance the shot is taken from, and
## what the frame is for. Distances are the two that matter -- the range at
## which a player decides whether to walk over, and the range at which they are
## looking for it at their feet.
const STANDS := [
	{
		"name": "01-gate-key-far",
		"at": Vector2(31.2, -8.4),
		"from": 14.0,
		"why": "OP-0830-2's key, at the range a player on the road decides to detour",
	},
	{
		"name": "02-gate-key-near",
		"at": Vector2(31.2, -8.4),
		"from": 4.0,
		"why": "the same key at arrival range -- the glow must step DOWN here, not wash the key out",
	},
	{
		"name": "03-tm-stone-rush",
		"at": Vector2(34.0, -20.0),
		"from": 16.0,
		"why": "a TM orb: the owner's own example, and a 20cm object on a plinth",
	},
	{
		"name": "04-harvest-fiber",
		"at": Vector2(12.0, -22.0),
		"from": 13.0,
		"why": "a gathering node in open meadow -- the case that must not read as loot spam",
	},
	{
		"name": "05-harvest-stone",
		"at": Vector2(22.0, -34.0),
		"from": 12.0,
		"why": "a low rock deposit, the prop most easily lost in a thickening carpet",
	},
	{
		"name": "06-deadwood",
		"at": Vector2(16.0, -28.0),
		"from": 15.0,
		"why": "a TALL prop: proves the halo sits in its body rather than over its head",
	},
]

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _tag: String = "AFTER"
## Stand names to shoot, empty meaning all of them. See `--only=` below.
var _only: PackedStringArray = PackedStringArray()
var _log: Array[String] = []
var _failures: Array[String] = []


func _init() -> void:
	var glow := true
	for raw: String in OS.get_cmdline_user_args():
		if raw.begins_with("--tag="):
			_tag = raw.substr(6)
		elif raw.begins_with("--only="):
			# Iteration. A full six-stand pass under software GL is most of an
			# hour, which is too slow to tune a look against -- and tuning a look
			# against anything other than the real world is what produced a glow
			# calibrated on a flat untextured test plane and blown out to white
			# in an actual meadow.
			_only = raw.substr(7).split(",", false)
		elif raw == "--glow=off":
			glow = false
	if not glow:
		# The BEFORE frame, taken from the SAME code on the SAME stands rather
		# than from a reverted checkout: `pickup_glow.json`'s `enabled` flag is
		# the treatment's own documented revert, so turning it off here
		# photographs exactly the world the owner reported. Poked at runtime
		# because `config()` caches the parsed dictionary by reference, and this
		# runs before the world builds and registers anything.
		GLOW.config()["enabled"] = false
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_PHYSICS_FRAMES:
		await physics_frame
	for i in SETTLE_DRAW_FRAMES:
		await process_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("[glow-capture] no Player/CameraRig; nothing to shoot")
		quit(1)
		return
	_pin_the_weather()

	for stand: Dictionary in STANDS:
		if not _only.is_empty() and not _only.has(str(stand["name"])):
			continue
		await _shoot(stand)

	var contact := "\n".join(_log) + "\n"
	print("")
	print(contact)
	for failure: String in _failures:
		print("[glow-capture] FAILURE: %s" % failure)
	quit(1 if not _failures.is_empty() else 0)


## Stand the player back from the pickup and look at it. The rig's own follow
## and yaw are used rather than a placed camera, for the reason in the header.
func _shoot(stand: Dictionary) -> void:
	var at: Vector2 = stand["at"]
	var distance := float(stand["from"])
	var ground := float(_world.call("ground_height_at", at.x, at.y))
	var target := Vector3(at.x, ground, at.y)

	# Approach from the south-east, which is where the road runs past these
	# sites; a stand chosen to flatter the shot would not be evidence.
	var bearing := Vector3(0.72, 0.0, 0.69).normalized()
	var stand_at := target + bearing * distance
	stand_at.y = float(_world.call("ground_height_at", stand_at.x, stand_at.z)) + 0.1
	_player.global_position = stand_at
	_player.velocity = Vector3.ZERO

	var to := target - stand_at
	_rig.set("yaw", atan2(-to.x, -to.z))
	_rig.set("pitch", -atan2(maxf(stand_at.y + 1.4 - target.y, 0.0), maxf(distance, 0.01)) * 0.5)
	for i in POSE_PHYSICS_FRAMES:
		await physics_frame
	for i in POSE_DRAW_FRAMES:
		await process_frame

	var camera := root.get_camera_3d()
	if camera == null:
		_failures.append("%s: no current camera" % stand["name"])
		return
	CAPTURE_CHECK.require(self, camera)
	var grass := _grass_verdict(camera)
	if grass.begins_with("NO GRASS"):
		_failures.append("%s: %s" % [stand["name"], grass])

	await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s-%s.png" % [OUT_DIR, stand["name"], _tag]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % stand["name"])
		return
	_log.append("%-20s %-6s dist=%4.1fm  %s\n%-20s %s\n%-20s %s" % [
		stand["name"], _tag, distance, grass,
		"", stand["why"],
		"", path,
	])
	# Written after EVERY shot, not once at the end. A software-GL pass over the
	# whole stand list runs long enough to hit a wall-clock timeout, and the
	# first version lost the entire contact log to that -- the frames survived
	# and the record of what they were and whether their grass checked out did
	# not, which is the half that makes them evidence.
	_write_contact()
	print("[glow-capture] %s -> %s | %s" % [stand["name"], path, grass])


func _write_contact() -> void:
	var file := FileAccess.open("%s/pickup-glow-%s.log" % [OUT_DIR, _tag], FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_log) + "\n")


## Pin AND freeze `WorldWeather`, the same idiom
## `tools/_capture_day_night_transition.gd` and `_capture_ground_and_sky.gd`
## already use, and the thing `capture_check.gd` refuses a frame without.
##
## Left running it rolls a new preset on its own real-time timer, independent of
## anything this tool drives -- so a six-stand pass can photograph the same
## pickup under different weather and the BEFORE/AFTER pair stops being a
## comparison of the glow and starts being a comparison of the sky.
func _pin_the_weather() -> void:
	var weather: Node = _world.get_node_or_null(^"WorldWeather")
	if weather == null:
		print("[glow-capture] no WorldWeather node to pin")
		return
	if weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
	weather.set_process(false)


## Is the ground in this frame actually dressed?
##
## The whole point of the check the lane order asked for. Two independent
## claims, because either one alone can be true while the frame is bare: the
## tuft MultiMesh has to HAVE instances, and the camera-relative ring has to
## have moved to where this shot is being taken from -- a field following some
## other camera reports a healthy instance count while dressing ground that is
## nowhere in the picture.
func _grass_verdict(camera: Camera3D) -> String:
	var field := _world.get_node_or_null(^"GrassField")
	if field == null:
		return "NO GRASS: no GrassField node in this world"
	# `GrassField` IS a MultiMeshInstance3D (the tuft ring itself) and carries the
	# stone and cover tiers as children, so the node has to be counted alongside
	# them -- a first version searched only the children and reported the stone
	# ring's 93k while the 315k tuft ring, the thing this check exists for, was
	# never looked at.
	var best_count := 0
	var layers: Array[Node] = [field]
	layers.append_array(field.find_children("*", "MultiMeshInstance3D", true, false))
	for layer: Node in layers:
		var mmi := layer as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null:
			continue
		best_count = maxi(best_count, mmi.multimesh.instance_count)
	if best_count <= 0:
		return "NO GRASS: the grass field carries zero instances"
	var drift := (field as Node3D).global_position.distance_to(camera.global_position)
	if drift > 40.0:
		return "NO GRASS: the ring is %.0fm from this camera (following another one)" % drift
	return "grass ok: %d tufts, ring %.1fm from the lens" % [best_count, drift]
