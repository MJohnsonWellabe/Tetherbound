extends SceneTree

## Native Compatibility-renderer proof for the exact height lookup functions in
## the production grass shader. Eight tiles exercise interiors, positive and
## negative seams, a four-region corner, an exact texel, and missing fallback.

const SOURCE_PATH := "res://shaders/grass_field.gdshader"
const SIZE := Vector2i(128, 16)
const REGION_TEXELS := 4
const MAP_SIZE := 8
const EPSILON := 0.0002
const CASES := [
	{"name":"interior", "uv":Vector2(1.25, 1.75)},
	{"name":"x_seam", "uv":Vector2(3.75, 1.4)},
	{"name":"z_seam", "uv":Vector2(1.3, 3.65)},
	{"name":"four_region_corner", "uv":Vector2(3.7, 3.8)},
	{"name":"negative_x_seam", "uv":Vector2(-0.25, 1.6)},
	{"name":"negative_interior", "uv":Vector2(-2.4, 2.2)},
	{"name":"exact_texel", "uv":Vector2(2.0, 2.0)},
	{"name":"missing_neighbor_fallback", "uv":Vector2(7.8, 1.2)},
]
const REGIONS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1),
	Vector2i(1, 1), Vector2i(-1, 0)]

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("grass height sampler GPU probe requires a rendering display")
		quit(1)
		return
	var production := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	var index_fn := _extract_function(production, "ivec3 get_index_coord(")
	var height_fn := _extract_function(production, "float grass_surface_height(")
	var declaration := "uniform highp sampler2DArray _height_maps : filter_linear, repeat_disable;"
	_check(production.count(declaration) == 1, "production height sampler declaration is not exact")
	_check(not index_fn.is_empty(), "could not extract production get_index_coord")
	_check(not height_fn.is_empty(), "could not extract production grass_surface_height")
	if not _failures.is_empty():
		_finish([])
		return

	var expected := PackedFloat32Array()
	var positions := PackedVector2Array()
	for case: Dictionary in CASES:
		var uv: Vector2 = case.uv
		positions.append(uv)
		if str(case.name) == "missing_neighbor_fallback":
			expected.append(_height(7.0, 1.0))
		else:
			expected.append(_bilinear_expected(uv))

	var shader := Shader.new()
	shader.code = _canvas_shader(index_fn, height_fn)
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("_height_maps", _height_array())
	material.set_shader_parameter("_region_size", float(REGION_TEXELS))
	material.set_shader_parameter("_region_texel_size", 1.0 / float(REGION_TEXELS))
	material.set_shader_parameter("_region_map_size", MAP_SIZE)
	material.set_shader_parameter("_region_map", _region_map())
	material.set_shader_parameter("test_positions", positions)
	material.set_shader_parameter("expected_values", expected)
	material.set_shader_parameter("epsilon", EPSILON)

	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var rect := ColorRect.new()
	rect.size = Vector2(SIZE)
	rect.material = material
	viewport.add_child(rect)
	for _frame in 3:
		await process_frame
	var image := viewport.get_texture().get_image()
	var records: Array[Dictionary] = []
	for i in CASES.size():
		var pixel := image.get_pixel(i * 16 + 8, 8)
		var passed := pixel.g > 0.9 and pixel.r < 0.1
		_check(passed, "%s GPU height lookup was outside %.5f" % [CASES[i].name, EPSILON])
		records.append({"case": CASES[i].name, "terrain_uv": CASES[i].uv,
			"expected": expected[i], "pixel": [pixel.r, pixel.g, pixel.b], "passed": passed})
	viewport.queue_free()
	await process_frame
	await process_frame
	_finish(records)


func _height(x: float, z: float) -> float:
	return 2.0 + 0.1 * x + 0.2 * z + 0.01 * x * z + 0.005 * x * x


func _bilinear_expected(uv: Vector2) -> float:
	var base := uv.floor()
	var blend := uv - base
	var low := lerpf(_height(base.x, base.y), _height(base.x + 1.0, base.y), blend.x)
	var high := lerpf(_height(base.x, base.y + 1.0),
			_height(base.x + 1.0, base.y + 1.0), blend.x)
	return lerpf(low, high, blend.y)


func _height_array() -> Texture2DArray:
	var images: Array[Image] = []
	for region: Vector2i in REGIONS:
		var image := Image.create(REGION_TEXELS, REGION_TEXELS, false, Image.FORMAT_RF)
		for z in REGION_TEXELS:
			for x in REGION_TEXELS:
				var gx := float(region.x * REGION_TEXELS + x)
				var gz := float(region.y * REGION_TEXELS + z)
				image.set_pixel(x, z, Color(_height(gx, gz), 0.0, 0.0, 1.0))
		images.append(image)
	var texture := Texture2DArray.new()
	var error := texture.create_from_images(images)
	_check(error == OK, "Texture2DArray RF creation failed: %s" % error_string(error))
	return texture


func _region_map() -> PackedInt32Array:
	var map := PackedInt32Array()
	map.resize(1024)
	map.fill(0)
	for layer in REGIONS.size():
		var region: Vector2i = REGIONS[layer]
		var pos := region + Vector2i(MAP_SIZE / 2, MAP_SIZE / 2)
		map[pos.y * MAP_SIZE + pos.x] = layer + 1
	return map


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


func _canvas_shader(index_fn: String, height_fn: String) -> String:
	return """shader_type canvas_item;
%s
uniform int _region_map[1024];
uniform float _region_size = 4.0;
uniform float _region_texel_size = 0.25;
uniform int _region_map_size = 8;
uniform vec2 test_positions[8];
uniform float expected_values[8];
uniform float epsilon = 0.0002;
%s
%s
void fragment() {
	int item = clamp(int(floor(UV.x * 8.0)), 0, 7);
	vec2 p = test_positions[item];
	ivec3 nearest_coord = get_index_coord(p, 1);
	float actual = grass_surface_height(p, nearest_coord);
	bool passed = abs(actual - expected_values[item]) < epsilon;
	COLOR = passed ? vec4(0.0, 1.0, 0.0, 1.0) : vec4(1.0, 0.0, 0.0, 1.0);
}""" % ["uniform highp sampler2DArray _height_maps : filter_linear, repeat_disable;",
		index_fn, height_fn]


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish(records: Array[Dictionary]) -> void:
	print("GRASS HEIGHT SAMPLER GPU: " + JSON.stringify({"cases": records,
		"production_shader": SOURCE_PATH, "failures": _failures}))
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)
