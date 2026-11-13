extends SceneTree
## F38#30 island strip: the Meshy mound keeps its main body and loses the
## detached floating shards; the config ships the block (flag-gated).

const WARRENS := preload("res://scripts/world/burrow_warrens.gd")
const MOUND := "res://assets/props/meshy-1020/burrow_hill_mound/burrow_hill_mound.glb"

var failures := 0
var tests := 0


func _initialize() -> void:
	_test_strip_real_mound()
	_test_config_block()
	print("test_hill_shell_island_strip: %d tests, %d failed" % [tests, failures])
	quit(1 if failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		push_error("FAIL: " + msg)


func _tris(mesh: Mesh) -> int:
	var n := 0
	for s: int in mesh.get_surface_count():
		var idx: PackedInt32Array = mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX]
		n += idx.size() / 3
	return n


func _test_strip_real_mound() -> void:
	tests += 1
	var scene := (load(MOUND) as PackedScene).instantiate()
	var found := scene.find_children("*", "MeshInstance3D", true, false)
	_check(not found.is_empty(), "mound has a mesh")
	if found.is_empty():
		return
	var mesh := (found[0] as MeshInstance3D).mesh
	var before := _tris(mesh)
	var t0 := Time.get_ticks_msec()
	var stripped := WARRENS.strip_mesh_islands(mesh, 1000)
	var ms := Time.get_ticks_msec() - t0
	var after := _tris(stripped)
	print("island strip: %d -> %d triangles in %d ms" % [before, after, ms])
	_check(after < before, "strip removed triangles")
	_check(after >= 55000, "main body kept (got %d)" % after)
	_check(before - after >= 3000, "islands removed (removed %d)" % (before - after))
	_check(stripped.surface_get_material(0) == mesh.surface_get_material(0), "material kept")
	scene.free()


func _test_config_block() -> void:
	tests += 1
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/burrow_warrens.json"))
	var strip: Dictionary = cfg["bank"]["hill_shell"].get("island_strip", {})
	_check(not strip.is_empty(), "island_strip block present")
	_check(str(strip.get("scope", "")) == "client_presentation", "scope declared")
	_check(int(strip.get("min_tris", 0)) == 1000, "min_tris 1000")
