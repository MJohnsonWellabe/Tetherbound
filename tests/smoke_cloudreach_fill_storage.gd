extends SceneTree

const LOOK := preload("res://scripts/world/cloudreach_look.gd")
const FIXTURE := preload("res://tests/fixtures/cloudreach_fill_storage_fixture.gd")
const BUFFER := preload("res://scripts/world/cloudreach_cover_buffer.gd")
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
		push_error("GPU buffer proof requires real Forward+")
		quit(2)
		return
	_check_placement()
	if args[0] == "--gpu-buffer":
		await _check_gpu_buffer()
	for failure in failures:
		push_error(failure)
	print("CLOUDREACH FILL STORAGE: mode=", args[0], " checks=", checks,
		" failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _check_placement() -> void:
	var materials: Array[Material] = [StandardMaterial3D.new(), StandardMaterial3D.new(),
		StandardMaterial3D.new(), StandardMaterial3D.new()]
	var mesh := ArrayMesh.new()
	var parent := Node3D.new()
	# Both capped and uncapped density branches, all four output buckets,
	# fractional requests, zero budget and empty output.
	for cap in [0, 17, 900000]:
		var cfg := {"far_visibility_range_m": 900.0, "turf_fill": {
			"enabled": true, "instance_cap": cap, "density_per_m2": 0.35,
			"far_density_per_m2": 0.13, "seed": 90607}}
		var packed := FIXTURE.new()
		var legacy := FIXTURE.new()
		packed._dress_turf_fill(parent, [{}], cfg, 220000, mesh,
			materials[0], materials[1], materials[2], materials[3], -2.0)
		legacy.legacy_fill(parent, [{}], cfg, 220000, mesh,
			materials[0], materials[1], materials[2], materials[3], -2.0)
		_check(packed.recorded == legacy.recorded, "exact ordered transforms/materials/ranges cap=%d" % cap)
		_check(packed._cover_fill_count == legacy._cover_fill_count, "count cap=%d" % cap)
		_check(packed._cover_fill_grid == legacy._cover_fill_grid, "cells/surfaces/density cap=%d" % cap)
		_check(packed._cover_fill_probes == legacy._cover_fill_probes, "probes cap=%d" % cap)
		if cap == 900000:
			_check(packed.recorded.size() == 4, "all four batches retained")
			for batch: Dictionary in packed.recorded.values():
				_check(not (batch.transforms as Array).is_empty(), "every batch has placement witnesses")
		packed.free()
		legacy.free()
	parent.free()

func _check_gpu_buffer() -> void:
	var look := LOOK.new()
	var parent := Node3D.new()
	root.add_child(parent)
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	# Cross a typical 2048 boundary, include empty/single, and exercise the
	# production append helper and actual _commit_tufts upload together.
	for count in [0, 1, 8193]:
		var buffer := PackedFloat32Array()
		var reference := MultiMesh.new()
		reference.transform_format = MultiMesh.TRANSFORM_3D
		reference.mesh = mesh
		reference.instance_count = count
		for i in count:
			var n := float(i)
			var value := Transform3D(Basis.from_euler(Vector3(n * 0.01, n * 0.03, n * 0.02)).scaled(
				Vector3(0.52, 0.95, 1.17)), Vector3(n * 0.125, n * 0.25, -n * 0.0625))
			BUFFER.append(buffer, value)
			reference.set_instance_transform(i, value)
		var before := parent.get_child_count()
		var written := look._commit_tufts(parent, "Batch%d" % count, buffer, mesh, material, 900.0)
		buffer.clear()
		_check(written == count, "exact uploaded count")
		if count == 0:
			_check(parent.get_child_count() == before, "empty batch creates no instance")
			continue
		for frame in 8:
			await RenderingServer.frame_post_draw
		var node := parent.get_child(parent.get_child_count() - 1) as MultiMeshInstance3D
		_check(node.multimesh.buffer == reference.buffer, "exact renderer float buffer after source clear")
		_check(node.multimesh.mesh == mesh and node.material_override == material, "same resources")
		_check(node.position == Vector3.ZERO and node.visibility_range_end == 900.0 \
			and node.visibility_range_end_margin == 40.0, "same origin and range")
		_check(node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
			and node.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF,
			"same shadow and fade")
		for i in count:
			_check(node.multimesh.get_instance_transform(i) == reference.get_instance_transform(i),
				"exact renderer transform %d" % i)
		parent.remove_child(node)
		node.free()
	look.free()
	parent.queue_free()
	await process_frame
	await process_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
