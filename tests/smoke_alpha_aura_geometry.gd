extends SceneTree

## Read actual ImmediateMesh geometry/colors against the exact main formula.
## A real renderer is required; dummy-renderer empty arrays cannot pass.
## No world/config/authority change and no FPS/screenshot judgement claim.
const AURA := preload("res://scripts/creatures/alpha_aura.gd")
const EXPECTED_CASES := 126
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
		print("Alpha aura geometry parity requires a real renderer for mesh readback.")
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
	world.queue_free()
	await process_frame
	# A GDScript runtime error can abort a nested comparison while its caller
	# continues. Require completed comparisons and actual vertex work before
	# reporting PASS, rather than trusting only the failure counter.
	_check(_cases == EXPECTED_CASES, "all requested cases ran")
	_check(_completed_cases == EXPECTED_CASES, "every comparison completed")
	_check(_vertices == EXPECTED_VERTICES, "exact expected generated vertex count")
	_check(_compared_vertices == EXPECTED_VERTICES, "every expected vertex and RGBA compared")
	print("Alpha aura geometry parity %s: %d/%d completed cases, %d/%d vertices, %d/%d checks passed" % [
		"FAIL" if _failures else "PASS", _completed_cases, EXPECTED_CASES,
		_compared_vertices, EXPECTED_VERTICES, _checks - _failures, _checks])
	quit(1 if _failures else 0)


func _compare_meshes(current: ImmediateMesh, original: ImmediateMesh, label: String) -> void:
	if not _check(current.get_surface_count() == 1 and original.get_surface_count() == 1,
			label + " preserves one actual triangle surface"):
		return
	# Mesh exposes array readback, but primitive_type is bound on ArrayMesh
	# only. RenderingServer exposes the actual ImmediateMesh RID surface.
	# Godot4.7 servers/rendering/rendering_server.cpp::_mesh_get_surface.
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
	for index in vertices.size():
		_check(vertices[index].is_equal_approx(wanted_vertices[index]),
			label + " vertex %d" % index)
		_check(colours[index] == wanted_colours[index], label + " RGBA %d" % index)
		_compared_vertices += 1
	_vertices += vertices.size()
	_completed_cases += 1
