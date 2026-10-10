extends SceneTree

## Compare actual emitted arrays against the original formula, without tolerances.
## Requires a real renderer; empty dummy-renderer arrays cannot pass.
## Source proof only: no FPS, screenshot, or whole visual acceptance claim.
const AURA := preload("res://scripts/creatures/alpha_aura.gd")
const EXPECTED_CASES := 126
const EXPECTED_ENDPOINTS := 9
# Per camera/size/color: 6+6+7+7+6+7+7 visible motes, 8 triangle wedges
# of 3 vertices each; multiplied by 3 cameras * 3 sizes * 2 colors.
const EXPECTED_VERTICES := 19872

class OriginalAura extends "res://scripts/creatures/alpha_aura.gd":
	func _disc(centre: Vector3, right: Vector3, up: Vector3, colour: Color) -> void:
		var rim := Color(colour.r, colour.g, colour.b, 0.0)
		for i in MOTE_SEGMENTS:
			var a0: float = TAU * float(i) / float(MOTE_SEGMENTS)
			var a1: float = TAU * float(i + 1) / float(MOTE_SEGMENTS)
			_mesh.surface_set_color(colour)
			_mesh.surface_add_vertex(centre)
			_mesh.surface_set_color(rim)
			_mesh.surface_add_vertex(centre + right * cos(a0) + up * sin(a0))
			_mesh.surface_set_color(rim)
			_mesh.surface_add_vertex(centre + right * cos(a1) + up * sin(a1))

var _failures := 0
var _checks := 0
var _cases := 0
var _completed_cases := 0
var _byte_compared_cases := 0
var _vertices := 0
var _compared_vertices := 0


func _init() -> void:
	_run.call_deferred()


func _check(value: bool, label: String) -> bool:
	_checks += 1
	if not value:
		_failures += 1
		print("FAIL: " + label)
	return value


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("Alpha aura cached geometry parity requires a real renderer for mesh readback.")
		quit(2)
		return
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	var current := AURA.new()
	var original := OriginalAura.new()
	world.add_child(current)
	world.add_child(original)
	current.set_physics_process(false)
	original.set_physics_process(false)
	if not _check(current.is_node_ready() and original.is_node_ready(),
			"both auras initialized before manual geometry updates"):
		world.free()
		quit(1)
		return
	if not _check_cache_contract(current):
		world.free()
		quit(1)
		return
	var instance: Variant = current.get("_instance")
	if not _check(instance is MeshInstance3D and instance.mesh is ImmediateMesh
			and instance.mesh == current.get("_mesh"), "initialized aura owns its emitted mesh"):
		world.free()
		quit(1)
		return
	var material: Variant = instance.material_override
	_check(material is StandardMaterial3D and material.vertex_color_use_as_albedo
		and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		and material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
		and material.blend_mode == BaseMaterial3D.BLEND_MODE_MIX and not material.no_depth_test,
		"initialized material preserves vertex RGBA, alpha mixing, and depth occlusion")
	var initial_cos: PackedFloat64Array = current.get("_mote_cos")
	var initial_sin: PackedFloat64Array = current.get("_mote_sin")
	# Bytes are independent snapshots, so later mutation cannot alter the oracle.
	var initial_cos_bytes := initial_cos.to_byte_array()
	var initial_sin_bytes := initial_sin.to_byte_array()
	var bases: Array[Basis] = [Basis.IDENTITY,
		Basis.from_euler(Vector3(0.37, -0.8, 0.12)),
		Basis.from_euler(Vector3(-0.65, 2.4, -0.22))]
	# Include the first mote's fade-cutoff sides and both periodic wrap points.
	var cutoff := asin(0.01) / PI * AURA.RISE_PERIOD
	var phases: Array[float] = [0.0, cutoff - 0.000001, cutoff + 0.000001,
		AURA.RISE_PERIOD * 0.5, AURA.RISE_PERIOD, AURA.ORBIT_PERIOD, 18.9]
	var sizes: Array[Vector2] = [Vector2(0.15, 0.3), Vector2(0.6, 1.0), Vector2(3.2, 4.7)]
	var colours: Array[Color] = [Color("#ffd479"), Color(0.13, 0.7, 0.95, 0.42)]
	for basis in bases:
		camera.global_basis = basis
		for size in sizes:
			for colour in colours:
				current.set("_radius", size.x)
				current.set("_height", size.y)
				current.set("_colour", colour)
				original.set("_radius", size.x)
				original.set("_height", size.y)
				original.set("_colour", colour)
				for phase in phases:
					current.set("_life", phase)
					original.set("_life", phase)
					current.call("_physics_process", 0.0)
					original.call("_physics_process", 0.0)
					await RenderingServer.frame_post_draw
					_cases += 1
					_compare_meshes(current.get("_mesh"), original.get("_mesh"),
						"case %d phase %.8f" % [_cases, phase])
	var final_cos: PackedFloat64Array = current.get("_mote_cos")
	var final_sin: PackedFloat64Array = current.get("_mote_sin")
	_check(final_cos.to_byte_array() == initial_cos_bytes,
		"cosine cache remains unchanged across all camera/size/color/phase updates")
	_check(final_sin.to_byte_array() == initial_sin_bytes,
		"sine cache remains unchanged across all camera/size/color/phase updates")
	world.queue_free()
	await process_frame
	# A nested runtime error can abort a comparison while its caller continues.
	# Require completed byte comparisons and actual vertex work before PASS.
	_check(_cases == EXPECTED_CASES, "all requested cases ran")
	_check(_completed_cases == EXPECTED_CASES, "every comparison completed")
	_check(_byte_compared_cases == EXPECTED_CASES, "every array-byte comparison completed")
	_check(_vertices == EXPECTED_VERTICES, "exact expected generated vertex count")
	_check(_compared_vertices == EXPECTED_VERTICES, "every expected exact vertex and RGBA compared")
	print("Alpha aura cached geometry parity %s: %d/%d completed cases, %d/%d byte comparisons, %d/%d vertices, %d/%d checks passed" % [
		"FAIL" if _failures else "PASS", _completed_cases, EXPECTED_CASES,
		_byte_compared_cases, EXPECTED_CASES, _compared_vertices, EXPECTED_VERTICES,
		_checks - _failures, _checks])
	quit(1 if _failures else 0)


func _check_cache_contract(aura: Node3D) -> bool:
	# Check the fixed fan's public numerical contract, not its initialization loop.
	var cosines: Variant = aura.get("_mote_cos")
	var sines: Variant = aura.get("_mote_sin")
	if not _check(typeof(cosines) == TYPE_PACKED_FLOAT64_ARRAY
			and typeof(sines) == TYPE_PACKED_FLOAT64_ARRAY,
			"coefficients are retained as double arrays before vector multiplication"):
		return false
	var cached_cos: PackedFloat64Array = cosines
	var cached_sin: PackedFloat64Array = sines
	if not _check(AURA.MOTE_SEGMENTS == 8
			and cached_cos.size() == EXPECTED_ENDPOINTS and cached_sin.size() == EXPECTED_ENDPOINTS,
			"eight wedges have nine initialized endpoints"):
		return false
	var opening_ok := _check(cached_cos[0] == 1.0 and cached_sin[0] == 0.0,
		"opening endpoint is the original zero-angle endpoint")
	var closing_ok := _check(cached_cos[8] == cos(TAU) and cached_sin[8] == sin(TAU),
		"closing endpoint retains the original full revolution in double precision")
	var distinct_ok := _check(cached_sin[8] != cached_sin[0],
		"closing sine is not wrapped to or quantized into the opening endpoint")
	return opening_ok and closing_ok and distinct_ok


func _compare_meshes(current: ImmediateMesh, original: ImmediateMesh, label: String) -> void:
	if not _check(current.get_surface_count() == 1 and original.get_surface_count() == 1,
			label + " preserves one actual triangle surface"):
		return
	# RenderingServer exposes the actual ImmediateMesh RID surface topology.
	var surface := RenderingServer.mesh_get_surface(current.get_rid(), 0)
	var original_surface := RenderingServer.mesh_get_surface(original.get_rid(), 0)
	_check(surface.get("primitive", -1) == RenderingServer.PRIMITIVE_TRIANGLES
		and original_surface.get("primitive", -1) == RenderingServer.PRIMITIVE_TRIANGLES,
		label + " actual triangle topology")
	var seen := current.surface_get_arrays(0)
	var expected := original.surface_get_arrays(0)
	if not _check(seen.size() == Mesh.ARRAY_MAX and expected.size() == Mesh.ARRAY_MAX,
			label + " real renderer arrays"):
		return
	var vertices: PackedVector3Array = seen[Mesh.ARRAY_VERTEX]
	var wanted_vertices: PackedVector3Array = expected[Mesh.ARRAY_VERTEX]
	var colours: PackedColorArray = seen[Mesh.ARRAY_COLOR]
	var wanted_colours: PackedColorArray = expected[Mesh.ARRAY_COLOR]
	if not _check(vertices.size() > 0 and vertices.size() == wanted_vertices.size()
			and colours.size() == vertices.size() and colours.size() == wanted_colours.size(),
			label + " visible mote count and vertex/color order"):
		return
	# Both arrays came from the same real renderer/build and contain finite values.
	# Byte equality also detects signed-zero or precision differences hidden by ==.
	var vertex_bytes := vertices.to_byte_array()
	var wanted_vertex_bytes := wanted_vertices.to_byte_array()
	var colour_bytes := colours.to_byte_array()
	var wanted_colour_bytes := wanted_colours.to_byte_array()
	if not _check(not vertex_bytes.is_empty() and vertex_bytes.size() == wanted_vertex_bytes.size()
			and not colour_bytes.is_empty() and colour_bytes.size() == wanted_colour_bytes.size(),
			label + " nonempty comparable packed array bytes"):
		return
	_check(vertex_bytes == wanted_vertex_bytes, label + " exact emitted vertex array bytes")
	_check(colour_bytes == wanted_colour_bytes, label + " exact emitted RGBA array bytes")
	_byte_compared_cases += 1
	for index in vertices.size():
		var vertex := vertices[index]
		var wanted := wanted_vertices[index]
		_check(vertex.x == wanted.x and vertex.y == wanted.y and vertex.z == wanted.z,
			label + " exact vertex components %d" % index)
		_check(colours[index] == wanted_colours[index], label + " exact RGBA %d" % index)
		_compared_vertices += 1
	_vertices += vertices.size()
	_completed_cases += 1
