extends SceneTree

## F33#1 evidence: does equipped creature gear show on the creature as a trim
## or glow accent at the normal camera? Real Meadows world and the ordinary rig.
## Five real creature bodies (creature_body.gd, the deployed-body class) stand
## in a row as a disclosed VISUAL-ONLY placement: no gear, then Rootiron,
## Tidesteel, Skyglass and Stormglass (Harness and Charm at +3). Each is bound
## through the production accent (creature_gear_accent.bind_projection) with the
## flag-off visual switch enabled for this capture only.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --audio-driver Dummy --resolution 1920x1080 \
##     --script tests/capture_f33_gear_accent.gd -- --capture-dir=/abs/out
const SCENE := "res://scenes/world/meadows_playground.tscn"
const BODY := preload("res://scripts/creatures/creature_body.gd")
const ACCENT := preload("res://scripts/creatures/creature_gear_accent.gd")
const GEAR := preload("res://scripts/creatures/creature_gear.gd")
const TIERS := ["", "rootiron", "tidesteel", "skyglass", "stormglass"]
const SPECIES := "terrapup"
const ORIGIN := Vector3(2.0, 0.0, -12.0)
const SPACING := 3.2

var _accents: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			out = argument.substr("--capture-dir=".length())
	if DisplayServer.get_name() == "headless" or out.is_empty():
		print("F33 accent capture FAIL: native renderer and --capture-dir required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	await process_frame
	var game := root.get_node("Game")
	for flag: String in ["opening:beat:free_play", "opening:starter_granted"]:
		game.get("progression").call("set_flag", flag)
	root.get_viewport().disable_3d = true
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 300:
		await physics_frame
	var cfg := GEAR.config()
	cfg.feature_flags.visual_enabled = true # Capture only; production stays flag-off until judged.
	for i in TIERS.size():
		var body: Node3D = BODY.new()
		body.name = "Gear_" + (TIERS[i] if not TIERS[i].is_empty() else "none")
		var x := ORIGIN.x + i * SPACING
		world.add_child(body)
		body.global_position = Vector3(x, float(world.call("ground_height_at", x, ORIGIN.z)) + 0.05, ORIGIN.z)
		body.call("setup", SPECIES)
		body.rotation.y = PI
		for _frame in 4:
			await process_frame
		var uid := "gear-capture-%d" % i
		var gear := {"harness": "", "charm": ""} if TIERS[i].is_empty() else \
			{"harness": TIERS[i] + "_harness_plus_3", "charm": TIERS[i] + "_charm_plus_3"}
		var record := {"character_id": "capture", "party": [{"uid": uid}],
			"redesign_character": {"creatures": {uid: {"gear": gear}}}}
		var accent: RefCounted = ACCENT.new()
		var bound: bool = accent.call("bind_projection", body, func() -> Dictionary: return record, "capture", uid, cfg)
		print("F33 accent %s bound=%s" % [body.name, str(bound)])
		_accents.append(accent)
	var player := world.get_node("Player") as CharacterBody3D
	var rig := world.get_node("CameraRig") as Node3D
	var look := world.get_node("WorldLook")
	look.call("set_clock_frozen", true)
	var mid := ORIGIN + Vector3(SPACING * (TIERS.size() - 1) * 0.5, 0, 0)
	var stands := {"row": [mid + Vector3(0.0, 1.2, 7.5), mid], "close": [ORIGIN + Vector3(SPACING * 3.5, 1.2, 4.0), ORIGIN + Vector3(SPACING * 3.5, 0, 0)]}
	for stand: String in stands:
		var at: Vector3 = stands[stand][0]
		var aim: Vector3 = stands[stand][1]
		player.global_position = Vector3(at.x, float(world.call("ground_height_at", at.x, at.z)) + 0.9, at.z)
		player.velocity = Vector3.ZERO
		rig.set("yaw", atan2(-(aim.x - at.x), -(aim.z - at.z)))
		for _frame in 40:
			await physics_frame
		root.get_viewport().disable_3d = false
		for time_name: String in ["day", "night"]:
			look.call("apply_time", time_name)
			for _frame in 10:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s.png" % [stand, time_name]))
			print("F33 accent frame %s_%s" % [stand, time_name])
		root.get_viewport().disable_3d = true
	quit(0)
