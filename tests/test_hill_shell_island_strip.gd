extends SceneTree
## F38#30 island strip: the Meshy mound keeps its main body and loses the
## detached floating shards; the config ships the block (flag-gated).

const WARRENS := preload("res://scripts/world/burrow_warrens.gd")
const MOUND := "res://assets/props/meshy-1020/burrow_hill_mound/burrow_hill_mound.glb"

var failures := 0
var tests := 0


func _initialize() -> void:
	_test_strip_real_mound()
	_test_fill_holes()
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


func _open_edges(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var weld := {}
	var vid := PackedInt32Array()
	vid.resize(verts.size())
	for i: int in verts.size():
		var v := verts[i]
		var key := Vector3i(roundi(v.x * 100000.0), roundi(v.y * 100000.0), roundi(v.z * 100000.0))
		if not weld.has(key):
			weld[key] = weld.size()
		vid[i] = int(weld[key])
	var count := {}
	for t: int in idx.size() / 3:
		for e: int in 3:
			var a := vid[idx[t * 3 + e]]
			var b := vid[idx[t * 3 + (e + 1) % 3]]
			var k := Vector2i(mini(a, b), maxi(a, b))
			count[k] = int(count.get(k, 0)) + 1
	var open := 0
	for k: Variant in count:
		if int(count[k]) == 1:
			open += 1
	return open


func _test_fill_holes() -> void:
	tests += 1
	var scene := (load(MOUND) as PackedScene).instantiate()
	var mesh := (scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var stripped := WARRENS.strip_mesh_islands(mesh, 1000)
	var before := _open_edges(stripped)
	var t0 := Time.get_ticks_msec()
	var filled := WARRENS.fill_mesh_holes(stripped, 80)
	var ms := Time.get_ticks_msec() - t0
	var after := _open_edges(filled)
	print("hole fill: open edges %d -> %d in %d ms" % [before, after, ms])
	_check(before > 1000, "mound starts with open edges (%d)" % before)
	_check(after * 10 < before, "fill closes at least 90%% of open edges (%d left)" % after)
	var a0 := stripped.surface_get_arrays(0)
	var a1 := filled.surface_get_arrays(0)
	for k: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV]:
		if a0[k] != null:
			_check((a1[k] as Variant).size() == (a1[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), "attribute %d sized to vertices" % k)
	scene.free()


func _test_config_block() -> void:
	tests += 1
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/burrow_warrens.json"))
	var strip: Dictionary = cfg["bank"]["hill_shell"].get("island_strip", {})
	_check(not strip.is_empty(), "island_strip block present")
	_check(str(strip.get("scope", "")) == "client_presentation", "scope declared")
	_check(int(strip.get("min_tris", 0)) == 1000, "min_tris 1000")
