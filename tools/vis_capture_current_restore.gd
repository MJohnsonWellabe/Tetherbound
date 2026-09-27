extends SceneTree

## VIS capture for audit row V-TW-1 (F14#2, "Tidewake water network visibly
## changes"). For each stand over a mandatory direct current it writes four
## frames from the production CameraRig/Camera3D at one fixed pose and one
## frozen time of day: live t0, live t0+1 s, restored t0, restored t0+1 s.
##
## Disclosed shortcuts (state is proven elsewhere by
## tests/smoke_tidewake_b_current_restore.gd, which walks the real path):
##  - `water_currents_restored` is set/cleared directly on the world flag store
##    between captures at the same pose; the view polls it once a second, so
##    the tool waits past the poll and checks the shader's calm_scale.
##  - The rig (a SpringArm3D, process-disabled so it cannot re-place its
##    camera), the trainer and the WorldLook clock are paused;
##    the Camera3D is posed directly (production fov/far/environment). The
##    trainer is hidden and parked under the stand; HUD layers are hidden.
##  - The smoke test's fixture flags plus the Salt Crown and Sluice Isle dock
##    facts are set, so every sampled direct current is an open route and not a
##    closed-gate tide race (any run that reaches the Guardian has them).
##  - Shader clock: software rendering takes seconds per frame, so the shader
##    TIME of two frames "1 s apart" is not controllable. The tool clones the
##    current-flow, sea-surface and tide-race shaders at runtime with TIME
##    replaced by a `vis_time` uniform (code otherwise identical) and pins it:
##    t0 = CLOCK_T0 in both states, t1 = CLOCK_T0 + 1 s. Game files unchanged.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/vis_capture_current_restore.gd -- --out=shots/vis_f14_2
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const FLAG := "water_currents_restored"
const FIXTURE := [
	"water_guardian_freed",
	"water_swim_lesson_complete",
	"water_dock_reedhaven_repaired",
	"water_dock_brine_steps_trial_won",
	"water_dock_shellwatch_residents_freed_and_pump_disabled",
	"water_aquaryn_resolved",
	"water_dock_salt_crown_landing_charted",
	"water_dock_sluice_isle_both_controls_disabled",
]
const PINNED_SHADERS := [
	"res://shaders/water_current_flow.gdshader",
	"res://shaders/water.gdshader",
	"res://shaders/water_tide_race.gdshader",
]
const CLOCK_T0 := 100.0
## Each stand looks at the midpoint of a direct current from the side, a
## little back along the route, so the streaks cross the frame.
const STANDS := [
	{"name": "S1", "current": "tidal_cradle_to_salt_crown_direct_current", "time": "day",
		"a": Vector2(550.0, 1742.0), "b": Vector2(300.0, 2098.0)},
	{"name": "S2", "current": "salt_crown_to_sluice_isle_direct_current", "time": "day",
		"a": Vector2(341.0, 2487.0), "b": Vector2(637.0, 2763.0)},
	{"name": "S3", "current": "sluice_isle_to_veilfall_direct_current", "time": "day",
		"a": Vector2(710.0, 3214.0), "b": Vector2(393.0, 3790.0)},
	{"name": "S4", "current": "tidal_cradle_to_salt_crown_direct_current", "time": "golden",
		"a": Vector2(550.0, 1742.0), "b": Vector2(300.0, 2098.0)},
]
const SIDE_M := 40.0
const BACK_M := 25.0
const EYE_HEIGHT_M := 16.0
const SETTLE_FRAMES := 30
const SETTLE_S := 2.0
const GAP_S := 1.0
const POLL_WAIT_S := 1.4

var out_dir := "shots/vis_f14_2"
var failures: Array[String] = []
var world: Node3D
var game: Node
var camera: Camera3D
var pinned: Array[ShaderMaterial] = []
var expected_eye := Vector3.ZERO


func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_dir = argument.trim_prefix("--out=")
	_run.call_deferred()


func _fail(message: String) -> void:
	failures.append(message)
	print("FAIL: " + message)


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame


func _calm() -> float:
	var flow := world.get_node_or_null("WaterVeilfall/WaterCurrentFlow") as MeshInstance3D
	if flow == null or not flow.material_override is ShaderMaterial:
		return -1.0
	return float((flow.material_override as ShaderMaterial).get_shader_parameter("calm_scale"))


func _shot(stand: String, state: String, tick: String, t_start: int) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var path := "%s/%s_%s_%s.png" % [out_dir, stand, state, tick]
	if camera.global_position.distance_to(expected_eye) > 0.5:
		_fail("camera at %s, not the stand eye %s" % [camera.global_position, expected_eye])
	if image.save_png(path) != OK:
		_fail("save " + path)
	print("SHOT cam=%s %s vis_time=%.2f ms_since_t0=%d calm_scale=%.3f flag=%s size=%dx%d" % [
		camera.global_position, path, float(pinned[0].get_shader_parameter("vis_time")) if not pinned.is_empty() else -1.0, Time.get_ticks_msec() - t_start, _calm(), game.world.flags.has(FLAG),
		image.get_width(), image.get_height()])


func _pin_clocks() -> void:
	var clones := {}
	var regex := RegEx.create_from_string("\\bTIME\\b")
	for node: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var material := (node as GeometryInstance3D).material_override as ShaderMaterial
		if material == null or material.shader == null or not PINNED_SHADERS.has(material.shader.resource_path):
			continue
		var path := material.shader.resource_path
		if not clones.has(path):
			var lines := material.shader.code.split("\n")
			var out := PackedStringArray()
			var inserted := false
			for line: String in lines:
				out.append(regex.sub(line, "vis_time", true))
				if not inserted and line.begins_with("render_mode"):
					out.append("uniform float vis_time = 0.0;")
					inserted = true
			var clone := Shader.new()
			clone.code = "\n".join(out)
			clones[path] = clone
		material.shader = clones[path]
		if not pinned.has(material):
			pinned.append(material)
	print("PINNED clocks on %d materials from %s" % [pinned.size(), clones.keys()])
	if not clones.has(PINNED_SHADERS[0]):
		_fail("current-flow shader was not pinned")


func _clock(t: float) -> void:
	for material: ShaderMaterial in pinned:
		material.set_shader_parameter("vis_time", t)
	await _frames(3)


func _set_restored(restored: bool) -> void:
	game.world.flags.set_flag(FLAG, restored)
	await create_timer(POLL_WAIT_S).timeout
	var want := 1.0
	if restored:
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
		want = float(config.get("current_flow", {}).get("restored_calm_scale", 0.5))
	if not is_equal_approx(_calm(), want):
		_fail("calm_scale %.3f != %.3f after flag=%s" % [_calm(), want, restored])


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("capture requires a rendering display")
		quit(1)
		return
	create_timer(4200.0).timeout.connect(func() -> void:
		_fail("watchdog")
		quit(1))
	await process_frame
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	for flag: String in FIXTURE:
		game.world.flags.set_flag(flag)
	game.world.flags.set_flag(FLAG, false)
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 1500:
		await process_frame
		if world.shell_build_complete():
			break
	if not world.shell_build_complete():
		_fail("water world shell did not build")
		quit(1)
		return
	var rig := world.get_node_or_null("CameraRig")
	camera = world.get_node_or_null("CameraRig/Camera3D") as Camera3D
	if rig == null or camera == null:
		_fail("production CameraRig/Camera3D missing")
		quit(1)
		return
	# CameraRig is a SpringArm3D: its internal physics step rewrites the
	# Camera3D's transform every frame (set_physics_process(false) does not
	# stop that), so the whole rig subtree is disabled and the camera posed.
	rig.process_mode = Node.PROCESS_MODE_DISABLED
	var player := world.get_node_or_null("Player") as Node3D
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.visible = false
	var look := world.get_node_or_null("WorldLook")
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	for node: Node in world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	camera.make_current()
	_pin_clocks()
	DirAccess.make_dir_recursive_absolute(out_dir)
	print("fov=%.1f far=%.1f" % [camera.fov, camera.far])
	for stand: Dictionary in STANDS:
		await _stand(stand, look, player)
	print("VIS CURRENT RESTORE %s failures=%d" % ["OK" if failures.is_empty() else "FAILED", failures.size()])
	quit(0 if failures.is_empty() else 1)


func _stand(stand: Dictionary, look: Node, player: Node3D) -> void:
	var a: Vector2 = stand.a
	var b: Vector2 = stand.b
	var mid := (a + b) * 0.5
	var along := (b - a).normalized()
	var side := Vector2(along.y, -along.x)
	var eye_xz := mid + side * SIDE_M - along * BACK_M
	var ground := maxf(0.0, float(world.ground_height_at(eye_xz.x, eye_xz.y)))
	var eye := Vector3(eye_xz.x, ground + EYE_HEIGHT_M, eye_xz.y)
	var target := Vector3(mid.x, 0.0, mid.y)
	if look != null:
		look.call("apply_time", str(stand.time))
	if player != null:
		player.global_position = Vector3(eye_xz.x, ground, eye_xz.y)
	await _set_restored(false)
	expected_eye = eye
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	await _frames(SETTLE_FRAMES)
	await create_timer(SETTLE_S).timeout
	print("STAND %s current=%s time=%s eye=%s target=%s ground_at_eye=%.2f ground_at_target=%.2f current_speed_m_s=%.3f" % [
		stand.name, stand.current, stand.time, eye, target, ground,
		float(world.ground_height_at(mid.x, mid.y)), (world.current_at(target) as Vector3).length()])
	var t0 := Time.get_ticks_msec()
	await _clock(CLOCK_T0)
	await _shot(stand.name, "live", "t0", t0)
	await _clock(CLOCK_T0 + GAP_S)
	await _shot(stand.name, "live", "t1", t0)
	await _set_restored(true)
	print("STAND %s restored current_speed_m_s=%.3f" % [stand.name, (world.current_at(target) as Vector3).length()])
	t0 = Time.get_ticks_msec()
	await _clock(CLOCK_T0)
	await _shot(stand.name, "restored", "t0", t0)
	await _clock(CLOCK_T0 + GAP_S)
	await _shot(stand.name, "restored", "t1", t0)
