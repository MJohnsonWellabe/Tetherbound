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
	_test_output_valid()
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


## Every surface the repair hands the renderer: non-empty, whole triangles,
## indices in range, no zero-area triangles, finite attributes, unit normals
## and tangents with w = +/-1 (GPU lane: intermittent integer-divide crash).
func _validate(mesh: Mesh, label: String) -> Dictionary:
	var report := {"surfaces": mesh.get_surface_count(), "degenerate": 0, "bad_index": 0, "nonfinite": 0, "bad_normal": 0, "bad_tangent": 0}
	_check(mesh.get_surface_count() > 0, "%s: has surfaces" % label)
	for s: int in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		_check(v.size() >= 3 and idx.size() >= 3, "%s: surface %d non-empty" % [label, s])
		_check(idx.size() % 3 == 0, "%s: surface %d index count %d is whole triangles" % [label, s, idx.size()])
		for i: int in idx.size():
			if idx[i] < 0 or idx[i] >= v.size():
				report.bad_index += 1
		for t: int in idx.size() / 3:
			var p0 := v[idx[t * 3]]
			var area := (v[idx[t * 3 + 1]] - p0).cross(v[idx[t * 3 + 2]] - p0).length()
			if area < 1e-12:
				report.degenerate += 1
		for p: Vector3 in v:
			if not p.is_finite():
				report.nonfinite += 1
		if a[Mesh.ARRAY_NORMAL] != null:
			for n: Vector3 in (a[Mesh.ARRAY_NORMAL] as PackedVector3Array):
				if not n.is_finite():
					report.nonfinite += 1
				elif absf(n.length() - 1.0) > 0.02:
					report.bad_normal += 1
		if a[Mesh.ARRAY_TEX_UV] != null:
			for uv: Vector2 in (a[Mesh.ARRAY_TEX_UV] as PackedVector2Array):
				if not uv.is_finite():
					report.nonfinite += 1
		if a[Mesh.ARRAY_TANGENT] != null:
			var tg: PackedFloat32Array = a[Mesh.ARRAY_TANGENT]
			_check(tg.size() == v.size() * 4, "%s: tangent array sized to vertices" % label)
			for i: int in tg.size() / 4:
				var tv := Vector3(tg[i * 4], tg[i * 4 + 1], tg[i * 4 + 2])
				if not tv.is_finite() or absf(tv.length() - 1.0) > 0.02 or absf(absf(tg[i * 4 + 3]) - 1.0) > 0.001:
					report.bad_tangent += 1
	return report


func _test_output_valid() -> void:
	tests += 1
	var scene := (load(MOUND) as PackedScene).instantiate()
	var mesh := (scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var source := _validate(mesh, "source")
	print("valid source: %s" % source)
	var stripped := WARRENS.strip_mesh_islands(mesh, 1000)
	var rs := _validate(stripped, "strip")
	print("valid strip: %s" % rs)
	var filled := WARRENS.fill_mesh_holes(stripped, 80)
	var rf := _validate(filled, "fill")
	print("valid fill: %s" % rf)
	for r: Dictionary in [rs, rf]:
		_check(int(r.bad_index) == 0, "no out-of-range index")
		_check(int(r.nonfinite) == 0, "all attributes finite")
		_check(int(r.degenerate) <= int(source.degenerate), "no new zero-area triangles (%d)" % int(r.degenerate))
		_check(int(r.bad_normal) <= int(source.bad_normal), "no new bad normals (%d)" % int(r.bad_normal))
		_check(int(r.bad_tangent) <= int(source.bad_tangent), "no new bad tangents (%d)" % int(r.bad_tangent))
	# Repeat: the repair is deterministic (no random step), so ten runs must
	# give identical counts.
	for run: int in 10:
		var again := WARRENS.fill_mesh_holes(WARRENS.strip_mesh_islands(mesh, 1000), 80)
		_check(_tris(again) == _tris(filled), "run %d identical" % run)
	scene.free()


func _test_config_block() -> void:
	tests += 1
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/burrow_warrens.json"))
	var strip: Dictionary = cfg["bank"]["hill_shell"].get("island_strip", {})
	_check(not strip.is_empty(), "island_strip block present")
	_check(str(strip.get("scope", "")) == "client_presentation", "scope declared")
	_check(int(strip.get("min_tris", 0)) == 1000, "min_tris 1000")
