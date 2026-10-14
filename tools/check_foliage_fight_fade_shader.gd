extends SceneTree
## Root-granted GPU slot only: no world or assets required. Reject any shader
## compiler error in process output even if this script exits zero.
const FADE := preload("res://scripts/world/foliage_fight_fade.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("F10 fade draw check requires a rendering display")
		quit(1)
		return
	root.size = Vector2i(160, 160)
	RenderingServer.set_default_clear_color(Color.BLACK)
	var base := StandardMaterial3D.new()
	base.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base.albedo_color = Color.WHITE
	base.cull_mode = BaseMaterial3D.CULL_DISABLED
	base.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var code := FADE.STANDARD.code(base)
	var injected := FADE.inject(code)
	if injected.is_empty():
		push_error("F10 generated shader injection refused")
		quit(1)
		return
	var shader := Shader.new()
	shader.code = injected
	var found := false
	for parameter in shader.get_shader_uniform_list():
		if parameter.name == "tb_fight_strength":
			found = true
	if not found:
		push_error("F10 compiler did not expose injected uniform")
		quit(1)
		return
	var mesh := BoxMesh.new()
	mesh.material = base
	var fade := FADE.new()
	var decorated := fade.apply(mesh, "tree", "stormwood", {
		"enabled": true, "realms": ["stormwood"], "models": ["tree"]})
	var geometry := MeshInstance3D.new()
	geometry.mesh = mesh
	root.add_child(geometry)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 4)
	root.add_child(camera)
	camera.make_current()
	if not fade.has_materials():
		push_error("F10 test mesh did not receive a fade material")
		quit(1)
		return
	var converted := decorated.surface_get_material(0) as ShaderMaterial
	for parameter: Dictionary in converted.shader.get_shader_uniform_list():
		if str(parameter.name).begins_with("tb_fight_"): continue
		if converted.get_shader_parameter(parameter.name) != RenderingServer.material_get_param(base.get_rid(), parameter.name):
			push_error("F10 conversion changed material parameter: " + str(parameter.name))
			quit(1)
			return
	var stock := await _lit_pixels()
	geometry.mesh = decorated
	var baseline := await _lit_pixels()
	# A global fade would also pass the active/release test. Move the target
	# sideways first: the box must remain opaque outside the sight corridor.
	fade.target(1, Vector3(20, 0, -4))
	fade.update(camera.global_position, 0.2)
	var outside := await _lit_pixels()
	# Box at origin lies halfway between camera and target, inside the corridor.
	fade.target(1, Vector3(0, 0, -4))
	fade.update(camera.global_position, 0.2)
	var active := await _lit_pixels()
	fade.target(1, Vector3.INF)
	var released := await _lit_pixels()
	print("F10_SHADER_DRAW_COUNTS: ", JSON.stringify({"stock": stock, "baseline": baseline, "outside": outside, "active": active, "released": released,
		"renderer": RenderingServer.get_current_rendering_method(), "viewport": root.size}))
	if stock < 16 or baseline != stock or outside != baseline or active <= 0 or active >= baseline / 2 or released != baseline:
		push_error("F10 corridor must preserve off-corridor pixels, dither inside, and fully restore on release")
		quit(1)
		return
	print("F10_SHADER_DRAW_COMPLETE: outside/active/released raster verified; inspect compiler diagnostics; no visual acceptance")
	quit(0)

func _lit_pixels() -> int:
	for frame in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	var captured := root.get_texture().get_image()
	if captured == null or captured.is_empty(): return -1
	var count := 0
	for y in captured.get_height():
		for x in captured.get_width():
			var pixel := captured.get_pixel(x, y)
			if pixel.r > 0.5 and pixel.g > 0.5 and pixel.b > 0.5: count += 1
	return count
