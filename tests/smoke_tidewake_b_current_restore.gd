extends SceneTree

## ACCEPTANCE §6.1 F14#2: "the water/current network visibly changes and
## persists" after the Guardian freeing.
##
## Fixture (stated, never the thing under test): `water_guardian_freed` plus the
## four earlier dock facts and `water_aquaryn_resolved` (every real run has
## opened those docks long before the Veilfall), so the sampled Tidal Cradle ->
## Salt Crown direct current is an ordinary open route, not a closed-gate race.
## `water_currents_restored` is NEVER written by this test: it must come from
## the production Guardian settlement (water_guardian_reward.gd refuse(),
## reached through the Veilfall chamber's own Decline interaction on
## water_veilfall.gd request_guardian_decline(), which the player confirms with
## a second press).
##
## Proves, in the production Water scene:
##  1. the flag is written by that real path and journaled to the world file;
##  2. visible change: WaterCurrentFlow shader `calm_scale` 1.0 ->
##     current_flow.restored_calm_scale, and physics water_world.current_at()
##     at a fixed sample point drops by the authored post-liberation multiplier;
##  3. persistence: production Game.save_game / reset / Game.load_game and a
##     rebuilt Water scene keep the flag, the calm view and the calmer physics.
## With `-- --capture=<dir>` and a rendering display, it writes before/after
## PNGs from the production CameraRig/Camera3D at a fixed pose (the rig's own
## follow logic is paused so both frames share one pose and one frozen clock).
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const RELOAD := preload("res://tests/helpers/water_chain_reload.gd")
const FLAG := "water_currents_restored"
const FIXTURE := [
	"water_guardian_freed",
	"water_swim_lesson_complete",
	"water_dock_reedhaven_repaired",
	"water_dock_brine_steps_trial_won",
	"water_dock_shellwatch_residents_freed_and_pump_disabled",
	"water_aquaryn_resolved",
]
## Midpoint of tidal_cradle_to_salt_crown_direct_current (1.3 m/s authored).
const SAMPLE := Vector3(425.0, 0.0, 1920.0)
const POSES := [
	{"name": "overview", "eye": Vector3(560.0, 70.0, 1700.0), "target": Vector3(440.0, 0.0, 1820.0)},
	{"name": "shore", "eye": Vector3(548.0, 3.2, 1740.0), "target": Vector3(474.539, 0.0, 1795.468)},
]

var checks := 0
var failures: Array[String] = []
var finished := false
var game: Node
var capture_dir := ""


func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_dir = argument.trim_prefix("--capture=")
	_run.call_deferred()


func check(ok: bool, message: String) -> bool:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		failures.append(message)
	return ok


func finish() -> void:
	finished = true
	print("Tidewake current restore smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _frames(count: int) -> void:
	for frame in count:
		await process_frame


func _build_world() -> Node3D:
	var world: Node3D = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 1500:
		await process_frame
		if world.shell_build_complete():
			break
	return world if world.shell_build_complete() else null


func _calm(world: Node3D) -> float:
	var flow := world.get_node_or_null("WaterVeilfall/WaterCurrentFlow") as MeshInstance3D
	if flow == null or not flow.material_override is ShaderMaterial:
		return -1.0
	return float((flow.material_override as ShaderMaterial).get_shader_parameter("calm_scale"))


func _speed(world: Node3D) -> float:
	return (world.current_at(SAMPLE) as Vector3).length()


func _capture(world: Node3D, tag: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	var rig := world.get_node_or_null("CameraRig")
	var camera := world.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var player := world.get_node_or_null("Player") as Node3D
	if rig == null or camera == null:
		check(false, "Production CameraRig/Camera3D present for capture")
		return
	rig.set_process(false)
	rig.set_physics_process(false)
	if player != null:
		player.set_process(false)
		player.set_physics_process(false)
		player.global_position = Vector3(556.0, float(world.ground_height_at(556.0, 1733.0)) + 0.1, 1733.0)
	var look := world.get_node_or_null("WorldLook")
	if look != null:
		look.call("apply_time", "day")
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		look.set_process(false)
	for node: Node in world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	camera.make_current()
	DirAccess.make_dir_recursive_absolute(capture_dir)
	for pose: Dictionary in POSES:
		var eye: Vector3 = pose.eye
		var ground := maxf(0.0, float(world.ground_height_at(eye.x, eye.z)))
		camera.global_position = Vector3(eye.x, ground + eye.y, eye.z)
		camera.look_at(pose.target, Vector3.UP)
		await _frames(16)
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "%s/%s_%s.png" % [capture_dir, str(pose.name), tag]
		check(image.save_png(path) == OK, "Captured " + path)


func _run() -> void:
	create_timer(420.0).timeout.connect(func() -> void:
		if not finished:
			check(false, "420 second watchdog expired")
			finish())
	await process_frame
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "tidewake-b-current-restore"
	RELOAD.isolate(game, "tidewake_b_current_restore")
	for flag: String in FIXTURE:
		game.world.flags.set_flag(flag)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	var restored_calm := float(config.get("current_flow", {}).get("restored_calm_scale", -1.0))
	check(restored_calm > 0.0 and restored_calm < 1.0, "Config declares a calmer restored_calm_scale (%.2f)" % restored_calm)
	var world := await _build_world()
	if not check(world != null, "Production Water world builds"):
		finish()
		return
	check(not game.world.flags.has(FLAG), "Fixture does not pre-set " + FLAG)
	var calm_before := _calm(world)
	var speed_before := _speed(world)
	print("BEFORE calm_scale=%.3f current_speed_m_s=%.4f at %s" % [calm_before, speed_before, SAMPLE])
	check(is_equal_approx(calm_before, 1.0), "Unrestored current foam runs at calm_scale 1.0")
	check(speed_before > 1.0, "Unrestored Tidal Cradle -> Salt Crown current pushes at authored strength")
	await _capture(world, "before")

	# Real settlement path: the Veilfall chamber's Decline, confirmed.
	var cave: Node3D = world.get_node("WaterVeilfall")
	var player: Node3D = world.local_rig()
	var prompt: Node3D = cave.get("_guardian_prompt")
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	player.velocity = Vector3.ZERO
	await _frames(8)
	var decline: Node3D = cave.get("_decline_prompt")
	if not check(decline != null and decline.enabled, "Freed Guardian chamber offers its Decline interaction"):
		finish()
		return
	cave.request_guardian_decline()
	check(cave.decline_armed() and not game.world.flags.has(FLAG), "First press only arms the decline")
	# The confirm guard is wall-clock (water_veilfall.gd DECLINE_MIN_CONFIRM_MSEC);
	# block for it without rendering, so a slow software-rendered frame cannot
	# overrun the confirm window.
	OS.delay_msec(600)
	cave.request_guardian_decline()
	check(game.world.flags.has(FLAG), "Confirmed Guardian decline settles the world: " + FLAG + " set by water_guardian_reward.refuse()")
	var disk: Dictionary = game.save_system.get("_worlds").read(game.world.world_id)
	check(disk.get("flags", {}).get("flags", []).has(FLAG), "World journal persists " + FLAG + " at settlement")
	# The view polls the flag store once a second.
	await create_timer(1.3).timeout
	var calm_after := _calm(world)
	var speed_after := _speed(world)
	print("AFTER calm_scale=%.3f current_speed_m_s=%.4f at %s" % [calm_after, speed_after, SAMPLE])
	check(is_equal_approx(calm_after, restored_calm), "Restored foam switches calm_scale to %.2f" % restored_calm)
	check(speed_after < speed_before * 0.5 and speed_after > 0.0, "Restored physics current is calmer at the same point")

	var reloaded: Dictionary = await RELOAD.save_and_reload(self, game, world, FLAG, "")
	for pair: Array in reloaded.checks:
		check(bool(pair[0]), str(pair[1]))
	var fresh: Node3D = reloaded.world
	if fresh == null:
		finish()
		return
	await _frames(4)
	var calm_reload := _calm(fresh)
	var speed_reload := _speed(fresh)
	print("RELOAD calm_scale=%.3f current_speed_m_s=%.4f at %s" % [calm_reload, speed_reload, SAMPLE])
	check(game.world.flags.has(FLAG), "Reloaded world keeps " + FLAG)
	check(is_equal_approx(calm_reload, restored_calm), "Rebuilt current foam starts calm after reload")
	check(is_equal_approx(speed_reload, speed_after), "Rebuilt physics current stays calm after reload")
	# The "after" frames come from the reloaded world: restored state read back
	# from the save, same camera pose and frozen clock as the "before" frames.
	await _capture(fresh, "after_reload")
	finish()
