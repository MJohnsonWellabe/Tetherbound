extends SceneTree

## WO-F09-04: do Light3D distance fade and GeometryInstance3D visibility-range
## self fade work in the renderer this runs under? A still, animation-free
## scene, so every pixel difference is the effect itself (the production world
## has wind, rain and sky motion that swamp a small light's contribution).
##
## - Light: a lit grey floor, black sky, no ambient, one OmniLight3D with the
##   pocket lamps' exact fade settings (stormwood_pockets.json draw_distance
##   and spur_marker.lamp energy/range). Mean floor brightness under the light
##   is reported at camera distances either side of lights_m.
## - Mesh: a white unshaded 6 m box with the palisade's visibility_range_end
##   (models_m) and margin (models_fade_m), FADE_SELF. Mean brightness of the
##   box's screen area is reported at distances either side of models_m.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/probe_compat_fade_synthetic.gd

const POCKETS := preload("res://scripts/world/stormwood_pockets.gd")
const LIGHT_DISTANCES := [20.0, 40.0, 44.0, 50.0, 55.0, 59.0, 62.0, 70.0]
const MESH_DISTANCES := [200.0, 230.0, 249.0, 255.0, 265.0, 279.0, 285.0, 300.0]

var _camera: Camera3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var cfg := POCKETS.config()
	var draw: Dictionary = cfg.draw_distance
	var style := POCKETS.spur_lamp_style(cfg)
	print("SYNTH renderer=%s driver=%s" % [str(ProjectSettings.get_setting("rendering/renderer/rendering_method")),
		RenderingServer.get_current_rendering_driver_name()])
	var scene := Node3D.new()
	root.add_child(scene)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	env.ambient_light_energy = 0.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	scene.add_child(world_env)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(2000, 2000)
	floor.mesh = plane
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.6, 0.6, 0.6)
	grey.roughness = 1.0
	floor.material_override = grey
	scene.add_child(floor)
	_camera = Camera3D.new()
	_camera.far = 2000.0
	scene.add_child(_camera)
	_camera.make_current()

	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.0, 0)
	light.light_energy = float(style.light_energy)
	light.omni_range = float(style.light_range_m)
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = float(draw.lights_m) - float(draw.lights_fade_m)
	light.distance_fade_length = float(draw.lights_fade_m)
	scene.add_child(light)
	print("SYNTH light fade begin=%.1f length=%.1f (gone by %.1f m)" % [light.distance_fade_begin, light.distance_fade_length, float(draw.lights_m)])
	for distance: float in LIGHT_DISTANCES:
		var on := await _shot(Vector3(0, 2.0, distance), Vector3.ZERO)
		light.visible = false
		var off := await _shot(Vector3(0, 2.0, distance), Vector3.ZERO)
		light.visible = true
		var focus := _camera.unproject_position(Vector3.ZERO)
		print("SYNTH LIGHT camera_to_light_m=%.1f lit_mean=%.3f unlit_mean=%.3f" % [
			Vector3(0, 2.0, distance).distance_to(light.position), _mean(on, focus, 60), _mean(off, focus, 60)])
	light.queue_free()

	var box := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(6, 6, 6)
	box.mesh = cube
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	box.material_override = white
	box.position = Vector3(0, 3, 0)
	box.visibility_range_end = float(draw.models_m)
	box.visibility_range_end_margin = float(draw.models_fade_m)
	box.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	scene.add_child(box)
	floor.visible = false
	print("SYNTH mesh visibility_range_end=%.1f margin=%.1f fade=self" % [box.visibility_range_end, box.visibility_range_end_margin])
	for distance: float in MESH_DISTANCES:
		var shot := await _shot(Vector3(0, 3.0, distance), Vector3(0, 3, 0))
		var focus := _camera.unproject_position(Vector3(0, 3, 0))
		print("SYNTH MESH camera_to_box_m=%.1f box_mean=%.3f" % [distance, _mean(shot, focus, 3)])
	quit(0)


func _shot(at: Vector3, look: Vector3) -> Image:
	_camera.position = at
	_camera.look_at(look, Vector3.UP)
	for _frame in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


## Mean 0..255 brightness in a square of half-size `half` px around `focus`.
func _mean(image: Image, focus: Vector2, half: int) -> float:
	# unproject_position works in the viewport's design size (1920x1080 with
	# canvas_items stretch); the grabbed image is the window size.
	focus *= Vector2(image.get_size()) / root.get_visible_rect().size
	var total := 0.0
	var count := 0
	for y in range(int(focus.y) - half, int(focus.y) + half + 1):
		for x in range(int(focus.x) - half, int(focus.x) + half + 1):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var c := image.get_pixel(x, y)
			total += (c.r + c.g + c.b) / 3.0
			count += 1
	return total / maxf(1.0, float(count)) * 255.0
