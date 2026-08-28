extends SceneTree

## CONTENT-0828B blind-pass capture: constructed interiors, both consumers.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_constructed_interiors.gd
##
## NEVER `--headless` with a real rendering driver -- it hangs forever with no
## error and no output (`ralph/conventions.md`, the most expensive trap in this
## repo).
##
## The owner localised "some locations still look lame" to a class of space:
## "burrow warrens and the castle are the lame looking locations. basically
## everywhere we had to build an under ground or build a building". So the
## frames have to cover BOTH consumers of the fix, not one -- a method that
## only works in the room it was tuned in is not a method. Six of these eight
## stands are rooms nobody has photographed before, which is deliberate: the
## previous pass's own report records that its blind rounds "never caught it
## because the interior frames it took were the mouth, the hall and the
## dressing -- not the two deep rooms".
##
## `--before` writes to a separate directory so the same stands can be run
## against a stashed tree. `--warrens-only` / `--castle-only` skip half the
## run; each site costs several minutes to stand up under software GL.
##
## Structure, the torch, the frozen weather/hour and the parked player are
## lifted from `capture_content_0828.gd` and `capture_warrens_63.gd` rather
## than reinvented, including the reasons their comments record: a player
## dropped below the world falls into the kill volume and tints every frame
## red through the hurt vignette, and `WorldLook`/`WorldWeather` re-layer the
## hour every frame unless both are frozen AND the weather is cleared before
## the time is applied.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

## Cave-local metres. `burrow_warrens.json`: hall is centred (0,22) at 14x12
## h4.2, den (0,40) at 16x14 h4.8, vault (15,40) at 8x8 h3.4.
const WARRENS_VIEWS := [
	{
		# The den across its long axis, from the hall doorway -- the widest
		# view of the biggest room, which is where a bay rhythm either reads
		# as structure or does not read at all.
		# Round 2 stood this at (-6.5, 34), which is 1.5 m off one wall and 1 m
		# off another -- inside the corner pier, so the left third of the frame
		# was one blurred slab of stone half a metre from the lens. A stand has
		# to be somewhere a player can stand.
		"name": "W1-den-wide",
		"eye": Vector2(-4.0, 35.5), "eye_h": 1.75,
		"target": Vector2(4.0, 43.0), "target_h": 1.6,
	},
	{
		# A corner of the den, close. The corner post and the wall/ceiling
		# junction at the range a player actually stands at during the fight.
		# Round 3's version of this aimed at a bare corner and a blind critic
		# said so: 65% undifferentiated wall, no focal point, no reason for the
		# camera to be here. A frame offered for judgement has to be a frame
		# somebody would take. Same job -- the wall/ceiling junction and a
		# corner pier at fighting range -- with the guardian's half of the room
		# in it, so there is something for the structure to be behind.
		"name": "W2-den-corner", "aim_guardian": true,
		"eye": Vector2(-5.5, 45.0), "eye_h": 1.6,
		"target": Vector2(4.0, 43.0), "target_h": 1.2,
	},
	{
		# The vault, from just inside. The prior pass's own worst frame -- its
		# report calls `04-vault-prize` "a perfect rectangular box" and that
		# frame is the whole reason this lane exists.
		"name": "W3-vault",
		"eye": Vector2(11.8, 40.0), "eye_h": 1.7,
		"target": Vector2(16.0, 41.5), "target_h": 1.4,
	},
	{
		# The hall: an ORDINARY room, with no boss, no prize and no authored
		# lighting pass. If the method only works where the content is, it is
		# dressing and not a method. This is the control.
		"name": "W4-hall",
		"eye": Vector2(-2.0, 17.5), "eye_h": 1.7,
		"target": Vector2(3.0, 27.0), "target_h": 2.4,
	},
]

## Complex-local metres. `stronghold.json`: courtyard (0,32) 22x28 h9 open,
## tether_approach (0,64) 16x18 h6.5, warden_arena (0,90.2) 24x26 h11,
## legendary_chamber (-32,90.2) 28x28 h22.
const CASTLE_VIEWS := [
	{
		# The legendary chamber: 28x28 and 22m tall, two shadowless omnis and
		# one object in the middle. The largest interior in the chapter and
		# the worst case for "a room with no scale reference in it".
		"name": "C1-legendary-chamber",
		"eye": Vector2(-20.0, 82.0), "eye_h": 1.75,
		"target": Vector2(-36.0, 93.0), "target_h": 6.0,
	},
	{
		# The Warden arena, across the fight's own ground.
		"name": "C2-warden-arena",
		"eye": Vector2(9.0, 80.0), "eye_h": 1.75,
		"target": Vector2(-6.0, 96.0), "target_h": 3.0,
	},
	{
		# The tether approach: the corridor space between two set pieces, and
		# the one a player walks slowly. Also the frame that carries the gated
		# passage's reveal.
		"name": "C3-tether-approach",
		"eye": Vector2(-5.0, 57.0), "eye_h": 1.7,
		"target": Vector2(2.0, 72.0), "target_h": 2.2,
	},
	{
		# The courtyard: an OPEN chamber, under the real sky. It gets bays,
		# course and corners but no ribs, and it is where the method has to
		# survive daylight rather than a 0.35-energy omni.
		"name": "C4-courtyard",
		"eye": Vector2(-7.0, 21.0), "eye_h": 1.75,
		"target": Vector2(6.0, 42.0), "target_h": 4.0,
	},
]


func _init() -> void:
	_run()


func _run() -> void:
	var argv: PackedStringArray = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	var before := "--before" in argv
	var want_warrens := not ("--castle-only" in argv)
	var want_castle := not ("--warrens-only" in argv)
	var out_dir := "res://shots/interiors_before" if before else "res://shots/interiors"
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

	# Parked far away ON THE GROUND, hidden, physics off -- never below the
	# world, or the kill volume tints every later frame red.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := Vector2(-357.0 + 700.0, 2610.0 + 700.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	# OF24's carried torch. Both buildings are authored dark on purpose and
	# capturing either without one photographs a room no player ever sees.
	var torch := OmniLight3D.new()
	torch.light_energy = 2.6
	torch.omni_range = 12.0
	torch.light_color = Color("#ffd8a0")
	torch.visible = false
	world.add_child(torch)

	var written: Array[String] = []
	var failures: Array[String] = []

	var jobs: Array = []
	if want_warrens:
		jobs.append([world.get_node_or_null(^"BurrowWarrens"), WARRENS_VIEWS, "BurrowWarrens", true])
	if want_castle:
		jobs.append([world.get_node_or_null(^"Stronghold"), CASTLE_VIEWS, "Stronghold", false])

	for job: Array in jobs:
		var host: Node3D = job[0] as Node3D
		if host == null:
			failures.append("no %s in the scene" % str(job[2]))
			continue
		for entry: Variant in (job[1] as Array):
			var view: Dictionary = entry
			var name_value := str(view["name"])
			var eye: Vector3 = _stand(host, view, "eye")
			var target: Vector3 = _stand(host, view, "target")
			# Aim at the guardian's actual body rather than at a hand-guessed
			# point near it -- it is a wild body with a `home` and it wanders,
			# so a typed coordinate crops it off the frame edge sooner or later.
			if bool(view.get("aim_guardian", false)) and host.has_method("guardian"):
				var creature: Node3D = host.call("guardian") as Node3D
				if creature != null and is_instance_valid(creature):
					target = creature.global_position + Vector3.UP * 0.7
			if eye.is_equal_approx(Vector3.INF) or target.is_equal_approx(Vector3.INF):
				failures.append("%s: stand is outside the building's footprint" % name_value)
				continue
			camera.global_position = eye
			camera.look_at(target, Vector3.UP)
			# The cave is lit by a carried torch; the fortress is not (it has
			# its own installed lighting and a courtyard open to the sky), so
			# lighting it by hand would flatter frames no player sees.
			torch.visible = bool(job[3])
			torch.global_position = eye + Vector3(0.0, 0.35, 0.0)
			var path := await _shoot(look, out_dir, name_value)
			if path == "":
				failures.append(name_value)
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


## A building-local `[x, z]` plus a height above ITS OWN built floor, in world
## metres. Both consumers expose `built_floor_height_at()` and both stand
## metres clear of the terrain, so a heightfield-relative camera sits inside
## the rock. A stand with no built floor under it is refused rather than
## guessed at -- `capture_content_0828.gd` lost a frame to a camera that fell
## back to the site origin and ended up inside geometry.
func _stand(host: Node3D, view: Dictionary, key: String) -> Vector3:
	var flat: Vector2 = view[key]
	var world_flat: Vector3 = host.to_global(Vector3(flat.x, 0.0, flat.y))
	var floor_y := float(host.call("built_floor_height_at", world_flat.x, world_flat.z))
	if is_nan(floor_y):
		push_error("%s.%s is building-local (%.1f, %.1f), which is not inside any chamber footprint"
			% [str(view.get("name", "?")), key, flat.x, flat.y])
		return Vector3.INF
	return Vector3(world_flat.x, floor_y + float(view.get("%s_h" % key, 1.7)), world_flat.z)


## Settle, re-apply the frozen hour, draw, save. The hour is re-applied AFTER
## the settle frames because the scene's own day-cycle group re-applies it
## while they run.
func _shoot(look: Node, out_dir: String, name_value: String) -> String:
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
	print("  %-24s -> %s" % [name_value, path])
	return path
