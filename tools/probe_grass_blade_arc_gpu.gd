extends SceneTree

## Native Compatibility GPU proof for the exact production blade-arc function.
## It compiles the balanced-brace-extracted hash and arc functions, then checks
## exact zero behavior plus curved root/height/opposite deterministic signs.
const SOURCE_PATH := "res://shaders/grass_field.gdshader"
const SIZE := Vector2i(64, 16)
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("grass blade arc GPU probe requires a rendering display")
		quit(1)
		return
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	var hash_fn := _extract_function(source, "float hash12(")
	var arc_fn := _extract_function(source, "vec2 grass_blade_arc(")
	_check(not hash_fn.is_empty(), "could not extract production hash12")
	_check(not arc_fn.is_empty(), "could not extract production grass_blade_arc")
	if not _failures.is_empty():
		_finish([])
		return
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float blade_arc_angle = 0.0;
%s
%s
void fragment() {
 int item=clamp(int(floor(UV.x*4.0)),0,3);
 float L=0.8; vec2 a;
 if(item==0) { a=grass_blade_arc(L,0.0,vec2(1.0,2.0)); }
 else if(item==1) { a=grass_blade_arc(L,0.5,vec2(1.0,2.0)); }
 else if(item==2) { a=grass_blade_arc(L,1.0,vec2(1.0,2.0)); }
 else { a=grass_blade_arc(L,1.0,vec2(3.0,4.0)); }
 bool zero = blade_arc_angle <= 0.000001;
 bool pass = zero ? abs(a.x-(item==0?0.0:(item==1?0.4:0.8)))<0.00001 && abs(a.y)<0.00001
  : (item==0 ? length(a)<0.00001 : (item==1 ? a.x>0.0 && a.x<0.4 && abs(a.y)>0.0 : (item==2 ? a.x>0.0 && a.x<0.8 && a.y<0.0 : a.x>0.0 && a.x<0.8 && a.y>0.0)));
 COLOR=pass?vec4(0.0,1.0,0.0,1.0):vec4(1.0,0.0,0.0,1.0);
}""" % [hash_fn, arc_fn]
	var material := ShaderMaterial.new()
	material.shader = shader
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rect := ColorRect.new()
	rect.size = Vector2(SIZE)
	rect.material = material
	viewport.add_child(rect)
	var records: Array[Dictionary] = []
	for pass_spec: Dictionary in [{"name":"zero_exact", "angle":0.0}, {"name":"curved_60deg", "angle":deg_to_rad(60.0)}]:
		material.set_shader_parameter("blade_arc_angle", pass_spec.angle)
		for _frame in 3:
			await process_frame
		var image := viewport.get_texture().get_image()
		var pixels := []
		for i in 4:
			var pixel := image.get_pixel(i * 16 + 8, 8)
			var passed := pixel.g > 0.9 and pixel.r < 0.1
			_check(passed, "%s tile %d failed" % [pass_spec.name, i])
			pixels.append([pixel.r, pixel.g, pixel.b])
		records.append({"pass":pass_spec.name,"angle_radians":pass_spec.angle,"pixels":pixels})
	viewport.queue_free()
	await process_frame
	await process_frame
	_finish(records)

func _extract_function(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var brace := source.find("{", start)
	if brace < 0:
		return ""
	var depth := 0
	for i in range(brace, source.length()):
		var character := source.substr(i, 1)
		if character == "{":
			depth += 1
		elif character == "}":
			depth -= 1
			if depth == 0:
				return source.substr(start, i - start + 1)
	return ""

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _finish(records: Array) -> void:
	var receipt={"source":SOURCE_PATH,"source_sha256":FileAccess.get_file_as_string(SOURCE_PATH).sha256_text(),
		"cases":records,"failures":_failures}
	print("GRASS_BLADE_ARC_GPU_RECEIPT ",JSON.stringify(receipt))
	for failure in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)
