extends SceneTree

## T1-CREATURE-ART. Structural render cost of the four Aspect variants' VFX
## (billboards + the recolored materials), measured the way this repo's own
## `tools/perf_render_stats.gd` header insists on for a software-rasterised
## (llvmpipe) box: draw calls and primitives from RenderingServer, never frame
## TIME. Compares one plain Burrowback against one Nightburrow (VFX + swapped
## materials) in an otherwise identical scene, so the delta isolates what
## THIS lane added rather than the scene's own baseline cost.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_aspect_vfx_perf.gd

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
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
	camera.global_position = Vector3(0.0, 1.5, 5.0)
	camera.look_at(Vector3(0.0, 1.2, 0.0), Vector3.UP)
	camera.make_current()

	var plain := await _sample(world, "burrowback", "")
	var dressed := await _sample(world, "burrowback", "nightburrow")

	print("")
	print("plain burrowback   : draw_calls=%d  primitives=%d" % [plain[0], plain[1]])
	print("nightburrow (+VFX) : draw_calls=%d  primitives=%d" % [dressed[0], dressed[1]])
	print("delta              : draw_calls=%+d  primitives=%+d" % [
		dressed[0] - plain[0], dressed[1] - plain[1]])
	quit(0)


func _sample(world: Node3D, source: String, variant: String) -> Array:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(BODY)
	world.add_child(body)
	body.call("setup", source, false)
	if variant != "":
		body.call("set_aspect_variant", variant, source)
	body.set_physics_process(false)

	for i in 40:
		await physics_frame
	for i in 2:
		await process_frame
	await RenderingServer.frame_post_draw

	var draw_calls := RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives := RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)

	body.queue_free()
	await process_frame
	return [draw_calls, primitives]
