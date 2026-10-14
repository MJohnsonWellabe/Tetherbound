extends SceneTree
## Root-granted GPU slot only: no world or assets required. Reject any shader
## compiler error in process output even if this script exits zero.
const FADE := preload("res://scripts/world/foliage_fight_fade.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var base := StandardMaterial3D.new()
	base.cull_mode = BaseMaterial3D.CULL_DISABLED
	base.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var code := RenderingServer.shader_get_code(base.get_shader_rid())
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
	var decorated := FADE.new().apply(mesh, "tree", "stormwood", {
		"enabled": true, "realms": ["stormwood"], "models": ["tree"]})
	var geometry := MeshInstance3D.new()
	geometry.mesh = decorated
	root.add_child(geometry)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 4)
	root.add_child(camera)
	camera.make_current()
	for frame in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	print("F10_SHADER_DRAW_COMPLETE: inspect compiler diagnostics; no visual acceptance")
	quit(0)
