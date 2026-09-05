extends SceneTree

## W09-VFX (CL-A2). What the VFX layer costs the renderer, measured in
## ISOLATION -- one creature body in a bare scene, sampled with each effect
## alive and again with it gone. Modelled directly on
## `tools/_probe_aspect_vfx_perf.gd`, which measures the Aspect variants'
## idle VFX the same way and for the same reason.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_probe_vfx_perf.gd
##
## Structural counters only (draw calls, primitives, objects submitted per
## frame) -- the same numbers a ROG Ally's GPU would be handed.
## `tools/perf_render_stats.gd`'s header is explicit that llvmpipe's frame
## TIME on this box is meaningless, and it is not reported.
##
## WHY ISOLATION IS THE HONEST MEASUREMENT HERE. The first attempt sampled
## the layer inside a real fight at `band1_open` with the tree paused,
## expecting the world to hold still between two consecutive samples. It does
## not: `draw_calls` fell 7,315 -> 3,790 and `objects` fell 6,826 -> 3,301
## between two samples of a PAUSED tree -- exactly -3,525 on both, i.e. about
## half the visible scene's objects, which cannot come from hiding two effect
## nodes. Terrain and scatter LOD keeps converging on the render side while
## the tree is paused, and it swamps anything this lane draws. A bare scene
## has nothing to converge, so the difference there IS the effect.
## `_capture_vfx_moments.gd --only=perf` still reports the in-world number,
## with a longer settle and an A/B/A/B pattern that shows the residual noise
## rather than hiding it.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const VFX := preload("res://scripts/vfx/combat_vfx.gd")

const SETTLE_FRAMES := 30
## Physics ticks into an effect's life before it is sampled -- past the birth
## frame, before the fade.
const BITE_TICKS := 5


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless reports zero for every render counter; run this under xvfb-run")
		quit(1)
		return
	await process_frame

	var world := Node3D.new()
	root.add_child(world)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.5
	env_node.environment = env
	world.add_child(env_node)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = Vector3(0.0, 1.6, 5.5)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	camera.make_current()

	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(BODY)
	world.add_child(body)
	body.call("setup", "terrapup", false)
	body.set_physics_process(false)
	for i in SETTLE_FRAMES:
		await physics_frame
	var baseline := await _sample("creature alone (baseline)")

	await _measure(world, body, baseline, "hit spark (quick, mid-damage)", func() -> void:
		VFX.hit(world, body.call("centre"), null, false, body, 0.15))
	await _measure(world, body, baseline, "hit spark (charged, heavy)", func() -> void:
		VFX.hit(world, body.call("centre"), null, true, body, 0.4))
	await _measure(world, body, baseline, "ko puff", func() -> void:
		VFX.knockout(world, body.call("centre"), body))
	await _measure(world, body, baseline, "catch burst", func() -> void:
		VFX.catch_success(world, body.call("centre")))
	await _measure(world, body, baseline, "level-up flourish (+ rim glow)", func() -> void:
		VFX.level_up(body, 1))
	# The worst case a real fight can reach: a charged blow that knocks the
	# opponent out while the winner levels, everything on screen at once.
	await _measure(world, body, baseline, "WORST CASE: charged hit + ko puff + flourish", func() -> void:
		VFX.hit(world, body.call("centre"), null, true, body, 0.4)
		VFX.knockout(world, body.call("centre"), body)
		VFX.level_up(body, 1))

	print("")
	print("Structural counters only; llvmpipe frame time is meaningless and is not reported.")
	quit(0)


## Fire `spawn`, let the effect open, sample, then let every effect expire and
## check the scene came back to the baseline it started from -- a leak shows
## up as a residual delta rather than as a number nobody checks.
func _measure(world: Node3D, body: Node3D, baseline: Array, label: String, spawn: Callable) -> void:
	spawn.call()
	for i in BITE_TICKS:
		await physics_frame
	var peak := await _sample(label)
	print("[vfx-perf] %-46s draw_calls=%+5d primitives=%+9d objects=%+4d" % [
		label, int(peak[0]) - int(baseline[0]), int(peak[1]) - int(baseline[1]),
		int(peak[2]) - int(baseline[2])])
	# Everything here is at most 1.5 s; 150 ticks is well past all of it.
	for i in 150:
		await physics_frame
	var after := await _sample("%s (expired)" % label)
	if int(after[0]) != int(baseline[0]) or int(after[2]) != int(baseline[2]):
		print("[vfx-perf] LEAK after '%s': draw_calls %+d, objects %+d not returned" % [
			label, int(after[0]) - int(baseline[0]), int(after[2]) - int(baseline[2])])


func _sample(_label: String) -> Array:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	return [
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	]
