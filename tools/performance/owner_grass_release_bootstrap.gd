extends Node

# Measurement entry only. Mount the sole shader overlay before the packaged
# production route and verify the resource actually returned by its cache.
func _ready() -> void:
	_begin.call_deferred()

func _begin() -> void:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--composition-") and argument.contains("="):
			var split := argument.find("=")
			options[argument.substr(0, split)] = argument.substr(split + 1)
	var overlay := str(options.get("--composition-overlay", ""))
	if not overlay.is_empty() and not ProjectSettings.load_resource_pack(overlay, true):
		_fail("Grass measurement cannot mount its sole-shader overlay")
		return
	var expected := FileAccess.get_file_as_string(str(options.get("--composition-expected", ""))).replace("\r\n", "\n")
	var actual := FileAccess.get_file_as_string("res://shaders/grass_field.gdshader").replace("\r\n", "\n")
	if expected.is_empty() or actual != expected:
		_fail("Grass measurement mounted source differs from scoped shader")
		return
	var shader := ResourceLoader.load("res://shaders/grass_field.gdshader", "Shader", ResourceLoader.CACHE_MODE_REPLACE) as Shader
	if shader == null or shader.code.replace("\r\n", "\n") != expected:
		_fail("Grass measurement cached Shader code differs from scoped shader")
		return
	var reused := ResourceLoader.load("res://shaders/grass_field.gdshader", "Shader", ResourceLoader.CACHE_MODE_REUSE) as Shader
	if reused != shader or reused.code.replace("\r\n", "\n") != expected:
		_fail("Grass measurement production reuse returns a different shader")
		return
	var tree := get_tree()
	if tree.get_script() != null:
		_fail("Grass measurement refuses an existing custom MainLoop")
		return
	var route := load("res://tools/capture_lookdev_route.gd") as Script
	if route == null or not route.can_instantiate():
		_fail("Grass measurement cannot load unchanged packaged route")
		return
	var receipt := FileAccess.open(str(options.get("--composition-receipt", "")), FileAccess.WRITE)
	if receipt == null:
		_fail("Grass measurement composition receipt cannot be opened")
		return
	receipt.store_string(JSON.stringify({"shader_path": "res://shaders/grass_field.gdshader", "overlay": overlay, "mounted_bytes_match": true, "cached_shader_code_match": true, "production_reuse_identity_match": true, "is_debug_build": OS.is_debug_build(), "hardware_performance_pass": null}, "\t") + "\n")
	if receipt.get_error() != OK:
		_fail("Grass measurement composition receipt write failed")
		return
	print("D GRASS RELEASE COMPOSITION PASS: mounted bytes / cached Shader / production reuse identical")
	tree.paused = false
	if tree.current_scene == self:
		tree.current_scene = null
	get_parent().remove_child(self)
	queue_free()
	tree.set_script(route)
	if tree.get_script() != route:
		push_error("Grass measurement cannot attach packaged route MainLoop")
		tree.quit(1)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
