extends SceneTree

## CONTENT-0828 blind-pass capture: the Burrow Warrens payoff and the TM prop.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_content_0828.gd
##
## Two owner complaints from the 2026-08-28 playtest, and both are judgements
## about frames rather than about numbers:
##
##   * "there needs to be a point to going in the burrows warren. like a prize
##     at the bottom or an alpha animal or something." The cave HAD both. What
##     it did not have was a guardian that reads as an alpha (it was a
##     burrowback with a name and an art-only scale, wearing the same texture
##     as the three residents one room back) or a branch door that reads as a
##     way on (a grey slab the same value as the wall it sits in). Frames 01-04
##     are those two things.
##   * "tms look awful." Frame 05 is a TM world pickup, which was a flat box
##     with a white box glued to it.
##
## Structure, the torch, the frozen weather/time and the parked player are all
## lifted from `capture_warrens_63.gd` rather than reinvented, including the
## reasons its own comments record for each -- a player dropped below the world
## falls into the kill volume and tints every later frame red through the hurt
## vignette, and `WorldLook`/`WorldWeather` re-layer the hour every frame unless
## both are frozen AND the weather is cleared before the time is applied.
##
## Same caveat as that file: Compatibility renderer under software GL, so
## composition, silhouette and relative value are trustworthy and fine lighting
## judgement is not. `docs/AGENT_WORKFLOW.md` forbids grading your own frames;
## this file only produces them.
##
## `--before` writes into `shots/content_0828_before/` instead, so the same
## camera stands can be run against a stashed tree and compared honestly.

const SCENE := "res://scenes/world/meadows_playground.tscn"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

## Cave-local metres, the frame `burrow_warrens.json` authors everything else
## in, so these stands survive another relocation of the site.
##
## The den is centred (0, 40) at 16x14; the vault door sits in the den->vault
## passage on the den's +x wall, and the guardian stands at (3, 44).
const VIEWPOINTS := [
	{
		# The fight as the player meets it: in through the den doorway, with
		# the guardian and the lit branch door in the SAME frame. That framing
		# is the whole claim -- a fight for what is behind the door rather than
		# a fight at the end of a corridor -- so it has to be one photograph.
		"name": "01-den-alpha-and-door",
		"eye": Vector2(-4.0, 33.5), "eye_h": 1.7,
		"target": Vector2(5.0, 42.0), "target_h": 1.3,
	},
	{
		# The alpha itself, close, aimed at its own body rather than at a
		# hand-guessed point near it -- round 2 of the BAND2-63 pass caught the
		# guardian half cropped off the frame edge in exactly this shot.
		# This is where the colourway, the silhouette rim and the mote aura
		# either read or do not.
		"name": "02-alpha-close", "aim_guardian": true,
		"eye": Vector2(-1.5, 38.5), "eye_h": 1.6,
		"target": Vector2(3.0, 44.0), "target_h": 1.2,
	},
	{
		# The shut branch door head-on from the den floor. If the seam and the
		# spill do their job this reads as a sealed way on with something lit
		# behind it; if they do not, it is still a grey rectangle.
		"name": "03-vault-door-shut",
		"eye": Vector2(2.0, 40.0), "eye_h": 1.7,
		"target": Vector2(9.0, 40.0), "target_h": 1.4,
	},
	{
		# The prize the door is shut on: the heartstone on its plinth, and the
		# vault's Elder Terrapup. Shot from just INSIDE the vault, not from the
		# passage -- the first run of this file put the eye at local (10, 40),
		# which is the 0.6 m gap between the den's footprint rect and the
		# vault's, where `built_floor_height_at()` has no opinion. The camera
		# fell back to the site's own origin height, ended up inside geometry,
		# and the frame never came back. `_cave_point()` now refuses a stand
		# with no floor under it instead of guessing one.
		"name": "04-vault-prize",
		"eye": Vector2(11.8, 40.0), "eye_h": 1.7,
		"target": Vector2(15.0, 41.0), "target_h": 0.9,
	},
]

## The TM prop, framed in the world where the game actually places one.
## `playground_world.gd::TM_AT` puts `tm_burrow_strike` at (6, -30), in open
## meadow near the village -- the first TM most players meet, in daylight,
## which is the least forgiving light this prop gets.
const TM_AT := Vector2(6.0, -30.0)


func _init() -> void:
	_run()


func _run() -> void:
	var argv: PackedStringArray = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	var before := "--before" in argv
	# Each frame costs ~40 s under software GL and the cave costs ~8 minutes to
	# stand up, so a run that only needs the TM prop should not pay for both.
	var want_warrens := not ("--tm-only" in argv)
	var want_tm := not ("--warrens-only" in argv)
	var out_dir := "res://shots/content_0828_before" if before else "res://shots/content_0828"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		push_error("no BurrowWarrens in the scene")
		quit(1)
		return

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	# Parked far away ON THE GROUND, hidden, physics off. Not below the world:
	# see this file's header and capture_warrens_63.gd's own note.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := Vector2(-357.0, 2610.0) + Vector2(700.0, 700.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	# OF24's carried torch, as a stand-in. The warrens is authored dark on
	# purpose (`burrow_warrens.json::_comment_lights`) and capturing it without
	# a torch photographs a cave no player ever sees.
	var torch := OmniLight3D.new()
	torch.light_energy = 2.6
	torch.omni_range = 12.0
	torch.light_color = Color("#ffd8a0")
	torch.visible = false
	world.add_child(torch)

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in (VIEWPOINTS if want_warrens else []):
		var view: Dictionary = entry
		var name_value := str(view["name"])
		var eye: Vector3 = _cave_point(warrens, view, "eye")
		var target: Vector3 = _cave_point(warrens, view, "target")
		if bool(view.get("aim_guardian", false)):
			var guardian: Node3D = warrens.call("guardian") as Node3D
			if guardian != null and is_instance_valid(guardian):
				target = guardian.global_position + Vector3.UP * 0.8
		if eye.is_equal_approx(Vector3.INF) or target.is_equal_approx(Vector3.INF):
			failures.append("%s: stand is outside the cave footprint" % name_value)
			continue
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		torch.visible = true
		torch.global_position = eye + Vector3(0.0, 0.35, 0.0)
		var path := await _shoot(world, look, camera, out_dir, name_value)
		if path == "":
			failures.append(name_value)
		else:
			written.append(path)

	# The TM prop, in daylight, out in the meadow. The torch comes off: this is
	# an exterior stand and a hand-held light beside it would flatter the prop
	# in a way no player's walk-up does.
	torch.visible = false
	var tm_ground := float(world.call("ground_height_at", TM_AT.x, TM_AT.y)) if want_tm else NAN
	if not want_tm:
		pass
	elif is_nan(tm_ground):
		failures.append("05-tm-pickup: no ground under the TM site")
	else:
		var tm_target := Vector3(TM_AT.x, tm_ground + 0.55, TM_AT.y)
		# Two stands: the walk-up read at conversational range, and the
		# distance at which a player decides whether to walk over at all.
		for stand: Array in [["05-tm-pickup", 2.6, 1.55], ["06-tm-at-distance", 11.0, 1.7]]:
			var away := float(stand[1])
			var eye_h := float(stand[2])
			var eye := Vector3(TM_AT.x - away * 0.72, tm_ground + eye_h, TM_AT.y - away * 0.69)
			camera.global_position = eye
			camera.look_at(tm_target, Vector3.UP)
			var path := await _shoot(world, look, camera, out_dir, str(stand[0]))
			if path == "":
				failures.append(str(stand[0]))
			else:
				written.append(path)

	print("")
	print("%d frames -> %s" % [written.size(), out_dir])
	print("Software rendering. These are for an independent critic, not for this file's author.")
	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## A cave-local `[x, z]` plus a height above the CAVE FLOOR, in world metres.
##
## The floor is metres off the terrain here, so a heightfield-relative camera
## sits inside the rock -- `built_floor_height_at()` is the warrens' own answer
## and the reason it is public.
func _cave_point(warrens: Node3D, view: Dictionary, key: String) -> Vector3:
	var flat: Vector2 = view[key]
	var world_flat: Vector3 = warrens.to_global(Vector3(flat.x, 0.0, flat.y))
	var floor_y := float(warrens.call("built_floor_height_at", world_flat.x, world_flat.z))
	if is_nan(floor_y):
		# Not a stand this cave claims -- a passage gap, or a number typed
		# wrong. Say so rather than guessing a height and photographing rock.
		push_error("%s.%s is cave-local (%.1f, %.1f), which is not inside any chamber footprint"
			% [str(view.get("name", "?")), key, flat.x, flat.y])
		return Vector3.INF
	return Vector3(world_flat.x, floor_y + float(view.get("%s_h" % key, 1.7)), world_flat.z)


## Settle, re-apply the frozen hour, draw, save. The hour is re-applied AFTER
## the settle frames because the scene's own day-cycle group re-applies it
## while they run -- capture_warrens_63.gd lost half a round to that.
func _shoot(world: Node, look: Node, _camera: Camera3D, out_dir: String, name_value: String) -> String:
	for i in 20:
		await physics_frame
	if look != null:
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("%s: viewport returned no image" % name_value)
		return ""
	var path := "%s/%s.png" % [out_dir, name_value]
	if image.save_png(path) != OK:
		push_error("%s: save_png failed" % name_value)
		return ""
	print("  %-26s -> %s" % [name_value, path])
	return path
