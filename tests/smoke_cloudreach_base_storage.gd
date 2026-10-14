extends SceneTree

const COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")
const LEGACY := preload("res://tests/fixtures/cloudreach_base_storage_legacy.gd")
const BUFFER := preload("res://scripts/world/cloudreach_cover_buffer.gd")

class RecordingCover extends COVER:
	var recorded := PackedFloat32Array()
	func _emit_patch_tier(parent: Node3D, label: String, mesh: ArrayMesh,
			material: ShaderMaterial, transforms: PackedFloat32Array, config: Dictionary,
			build_budget: RefCounted = null) -> int:
		recorded = transforms.duplicate() # Test-only witness, never production retention.
		return await super._emit_patch_tier(parent, label, mesh, material, transforms, config, build_budget)

class YieldBudget extends RefCounted:
	var tree: SceneTree
	var calls := 0
	func _init(value: SceneTree) -> void:
		tree = value
	func breathe() -> void:
		calls += 1
		await tree.process_frame

class Crown extends RefCounted:
	func sample(x: float, z: float) -> Vector2:
		return Vector2(8.0 + sin(x * 0.02) + cos(z * 0.03), 0.3 if x < -10.0 else 0.95)

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or args[0] not in ["--placement", "--gpu-buffer"]:
		push_error("Select exactly --placement or --gpu-buffer")
		quit(2)
		return
	if args[0] == "--gpu-buffer" and (DisplayServer.get_name() == "headless" \
			or RenderingServer.get_current_rendering_method() != "forward_plus"):
		push_error("Real Forward+ required for ordered renderer buffer proof")
		quit(2)
		return
	if args[0] == "--placement":
		await _placement()
	else:
		await _gpu_buffer()
	for failure in failures:
		push_error(failure)
	print("CLOUDREACH BASE STORAGE: mode=", args[0], " checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _placement() -> void:
	var mesh := _mesh()
	var material := ShaderMaterial.new()
	var cfg := {"cluster_frequency": 0.16, "cluster_threshold": -10.0,
		"visibility_range_m": 360.0, "path_clearance_m": 1.8}
	var ellipse := {"kind": "ellipse", "centre": Vector3(4, 8, -3),
		"half": Vector2(42, 36), "seed": 71, "height_scale": 1.2}
	var cases: Array[Dictionary] = []
	for count in [0, 1, 2047, 2048, 2049]:
		cases.append({"patch": ellipse.duplicate(true), "count": count, "dense": true})
	var clipped := ellipse.duplicate(true)
	clipped["clip_rect"] = Rect2(-8, -8, 16, 16)
	cases.append({"patch": clipped, "count": 257, "dense": false})
	var crown := ellipse.duplicate(true)
	crown["crown_surface"] = Crown.new()
	cases.append({"patch": crown, "count": 257, "dense": false})
	cases.append({"patch": {"kind": "segment", "a": Vector3(-35, 2, -20),
		"b": Vector3(40, 10, 30), "half_width": 18.0, "path_half_width": 3.0,
		"seed": 99}, "count": 257, "dense": false})
	cases.append({"patch": ellipse.duplicate(true), "count": 17, "dense": false,
		"exclude_all": true})
	for spec in cases:
		for tier in 3:
			var fresh := RecordingCover.new()
			var old := LEGACY.new()
			var a := Node3D.new()
			var b := Node3D.new()
			a.name = "WitnessPatch"
			b.name = "WitnessPatch"
			a.position = fresh._patch_origin(spec.patch)
			b.position = a.position
			var exclusions: Array[Dictionary] = []
			if bool(spec.get("exclude_all", false)):
				exclusions.append({"kind": "rect", "centre": Vector3(4, 8, -3),
					"half": Vector2(100, 100), "rotation": 0.0})
			elif not spec.dense:
				exclusions.append({"kind": "ellipse", "centre": Vector3(4, 8, -3),
					"half": Vector2(4, 6), "rotation": 0.4})
			fresh._active_exclusions = exclusions
			old._active_exclusions = exclusions
			var patch_before: Dictionary = spec.patch.duplicate(true)
			var config_before := cfg.duplicate(true)
			var cells_before: Dictionary = fresh._active_index._cells.duplicate(true)
			var budget := YieldBudget.new(self)
			var result: int = await fresh._build_patch_tier(a, "Tier", spec.patch, mesh,
				material, spec.count, 0.3, 0.95, cfg, 17 + tier, tier, budget)
			var expected: int = await old._build_patch_tier(b, "Tier", spec.patch, mesh,
				material, spec.count, 0.3, 0.95, cfg, 17 + tier, tier)
			_check(result == expected, "same accepted count")
			_check(_unpack(fresh.recorded) == old.recorded, "every unrounded ordered transform equals frozen sampler")
			_check(spec.patch == patch_before and cfg == config_before, "patch/cell metadata and config unchanged")
			_check(fresh._active_index._cells == cells_before, "exclusion cell keys/contents unchanged")
			_check(a.get_child_count() == b.get_child_count(), "same batch count including empty")
			if spec.dense:
				_check(result == spec.count, "dense witness reaches exact requested edge count")
			if bool(spec.get("exclude_all", false)):
				_check(result == 0, "all-excluded witness remains empty")
			if spec.dense and spec.count > 2048:
				_check(budget.calls >= 2, "sampling and bulk upload release the build budget")
			if spec.count > 0 and not bool(spec.get("exclude_all", false)):
				_check(result > 0, "nonempty placement witness exercises transform comparison")
			if result > 0:
				_compare_settings(a.get_child(0) as MultiMeshInstance3D, b.get_child(0) as MultiMeshInstance3D)
			fresh.free()
			old.free()
			a.free()
			b.free()

func _gpu_buffer() -> void:
	var fresh := COVER.new()
	var old := LEGACY.new()
	var mesh := _mesh()
	var material := ShaderMaterial.new()
	var cfg := {"visibility_range_m": 360.0}
	for count in [1, 2048, 2049, 8193]:
		var buffer := PackedFloat32Array()
		var reference: Array[Transform3D] = []
		for i in count:
			var n := float(i)
			var value := Transform3D(Basis.from_euler(Vector3(n * 0.01, n * 0.03, n * 0.02)).scaled(
				Vector3(0.52, 0.95, 1.17)), Vector3(n * 0.125, n * 0.25, -n * 0.0625))
			BUFFER.append(buffer, value)
			reference.append(value)
		var a := Node3D.new()
		var b := Node3D.new()
		var budget := YieldBudget.new(self)
		var written: int = await fresh._emit_patch_tier(a, "Tier", mesh, material, buffer, cfg, budget)
		var expected: int = await old._legacy_emit_patch_tier(b, "Tier", mesh, material, reference, cfg)
		_check(written == count and expected == count, "exact renderer count")
		_check(buffer.is_empty(), "production temporary buffer released")
		for frame in 8:
			await RenderingServer.frame_post_draw
		var actual := a.get_child(0) as MultiMeshInstance3D
		var baseline := b.get_child(0) as MultiMeshInstance3D
		_compare_settings(actual, baseline)
		_check(actual.multimesh.buffer == baseline.multimesh.buffer, "exact ordered renderer floats")
		_check(actual.multimesh.get_aabb() == baseline.multimesh.get_aabb(), "unchanged renderer bounds")
		for i in count:
			_check(actual.multimesh.get_instance_transform(i) == baseline.multimesh.get_instance_transform(i),
				"exact renderer transform %d" % i)
		a.free()
		b.free()
	fresh.free()
	old.free()
	await process_frame
	await process_frame

func _compare_settings(a: MultiMeshInstance3D, b: MultiMeshInstance3D) -> void:
	_check(a.name == b.name and a.transform == b.transform, "same batch name and origin")
	_check(a.multimesh.mesh == b.multimesh.mesh and a.material_override == b.material_override, "same mesh and material")
	_check(a.cast_shadow == b.cast_shadow and a.visibility_range_end == b.visibility_range_end \
		and a.visibility_range_end_margin == b.visibility_range_end_margin \
		and a.visibility_range_fade_mode == b.visibility_range_fade_mode, "same culling/fade/shadows")

func _unpack(buffer: PackedFloat32Array) -> Array[Transform3D]:
	var values: Array[Transform3D] = []
	for offset in range(0, buffer.size(), 12):
		values.append(Transform3D(Basis(
			Vector3(buffer[offset], buffer[offset + 4], buffer[offset + 8]),
			Vector3(buffer[offset + 1], buffer[offset + 5], buffer[offset + 9]),
			Vector3(buffer[offset + 2], buffer[offset + 6], buffer[offset + 10])),
			Vector3(buffer[offset + 3], buffer[offset + 7], buffer[offset + 11])))
	return values

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
