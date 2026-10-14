extends SceneTree

## Real-renderer stored-value transfer proof, not visual equivalence or world evidence.
const FADE := preload("res://scripts/world/foliage_fight_fade.gd")
const SOURCE := "287801583d8794d48f975c3e2482610a3f39aa75"
var failures: Array[String] = []
var checks := 0
var cases := 0

func _init() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)

func _run() -> void:
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "forward_plus":
		push_error("Retint transfer requires a native Forward+ renderer")
		quit(2)
		return
	if not OS.get_cmdline_user_args().has("--source-commit=" + SOURCE):
		push_error("Retint transfer requires its exact source argument")
		quit(2)
		return
	root.msaa_3d = Viewport.MSAA_4X
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 0, 5)
	camera.make_current()
	var light := DirectionalLight3D.new()
	scene.add_child(light)
	light.rotation_degrees = Vector3(-35, 20, 0)
	for with_detail in [false, true]:
		var source := StandardMaterial3D.new()
		source.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		source.roughness = 0.94
		source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		source.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE
		source.alpha_antialiasing_edge = 0.27
		var stored_edge := source.alpha_antialiasing_edge
		source.backlight_enabled = true
		source.backlight = Color(0.28, 0.28, 0.28, 1.0)
		source.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
		source.normal_enabled = true
		source.detail_enabled = with_detail
		if with_detail:
			source.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
			source.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
			source.uv2_triplanar = true
			source.uv2_world_triplanar = true
		var mesh := BoxMesh.new()
		mesh.material = source
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		scene.add_child(visual)
		await process_frame
		await RenderingServer.frame_post_draw
		var native_source: Variant = RenderingServer.material_get_param(source.get_rid(), "alpha_antialiasing_edge")
		check(native_source != null, "native source edge exists")
		check(native_source == stored_edge, "native source edge equals exact stored property")
		var fade := FADE.new()
		var converted_mesh := fade.apply(mesh, "tree", "stormwood", {"enabled": true, "realms": ["stormwood"], "models": ["tree"]})
		var converted := converted_mesh.surface_get_material(0) as ShaderMaterial
		check(converted != null, "retint converts for detail=" + str(with_detail))
		if converted == null:
			visual.queue_free()
			continue
		var uniforms: Array[String] = []
		for parameter: Dictionary in converted.shader.get_shader_uniform_list():
			uniforms.append(str(parameter.name))
		check(uniforms.has("alpha_antialiasing_edge"), "native shader exposes edge uniform")
		check(source.alpha_antialiasing_edge == stored_edge, "conversion retains exact source property")
		var transferred: Variant = converted.get_shader_parameter("alpha_antialiasing_edge")
		check(transferred != null, "converted edge is non-null")
		check(transferred == stored_edge, "conversion transfers exact stored source edge")
		check(converted.get_meta("fight_fade_source") == source, "source retained by converted material")
		visual.mesh = converted_mesh
		await process_frame
		await RenderingServer.frame_post_draw
		check(RenderingServer.material_get_param(converted.get_rid(), "alpha_antialiasing_edge") == stored_edge, "rendered converted edge remains exact")
		check(source.alpha_antialiasing_edge == stored_edge, "rendering leaves exact source edge unchanged")
		check(source.detail_enabled == with_detail, "detail case remains selected")
		check(root.msaa_3d == Viewport.MSAA_4X, "coverage path retains 4x MSAA")
		cases += 1
		visual.queue_free()
		await process_frame
		fade.clear()
	for failure in failures:
		push_error("Retint transfer: " + failure)
	var passed := failures.is_empty() and cases == 2 and checks == 24
	print("STORMWOOD_RETINT_TRANSFER ", "PASS" if passed else "FAIL", " cases=", cases, " checks=", checks, " failures=", failures.size(), " source=", SOURCE)
	scene.queue_free()
	await process_frame
	quit(0 if passed else 1)
