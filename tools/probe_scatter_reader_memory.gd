extends SceneTree

## Root-admitted, reader-only memory comparison. Never loads a world or model.
## Run legacy and compact in separate supervised processes on identical inputs.
## Phase markers identify one-second plateaus for external process-memory samples.
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const MANIFEST := "res://data/scatter/playground/manifest.json"
const GRASS_CONFIG := "res://data/config/grass_field.json"
const VEGETATION_CONFIG := "res://data/config/vegetation.json"
const HOLD_SECONDS := 1.0
var _receipt_path := ""
var _arm := ""
var _receipt: Dictionary = {}
var _started := 0
var _isolated_autoloads: Dictionary = {}


func _init() -> void:
	# A --script SceneTree still receives project autoloads. The script instance
	# is constructed before that loader; remove them only in this process, never
	# save project settings. The empty-root check below verifies the isolation.
	for property: Dictionary in ProjectSettings.get_property_list():
		var key := str(property.name)
		if key.begins_with("autoload/"):
			_isolated_autoloads[key] = ProjectSettings.get_setting(key)
			ProjectSettings.set_setting(key, null)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_started = Time.get_ticks_usec()
	var args := {}
	for arg: String in OS.get_cmdline_user_args():
		var split := arg.find("=")
		if split < 0:
			push_error("Reader probe requires explicit --key=value arguments")
			quit(2)
			return
		var key := arg.substr(0, split)
		if key not in ["--arm", "--receipt", "--source-commit"] or args.has(key):
			push_error("Unknown or duplicate reader probe argument: " + key)
			quit(2)
			return
		args[key] = arg.substr(split + 1)
	_arm = str(args.get("--arm", ""))
	_receipt_path = str(args.get("--receipt", ""))
	var source := str(args.get("--source-commit", ""))
	if _arm not in ["legacy", "compact"] or source.length() != 40 \
			or not source.is_valid_hex_number(false) or OS.get_environment("TB_NATIVE_SOURCE_SHA") != source:
		push_error("Reader probe requires arm and source matching TB_NATIVE_SOURCE_SHA")
		quit(2)
		return
	if not _receipt_path.is_absolute_path() or _receipt_path.begins_with("res://") \
			or _receipt_path.begins_with("user://") or FileAccess.file_exists(_receipt_path):
		push_error("Reader probe needs a fresh absolute receipt path outside res:// and user://")
		quit(2)
		return
	var project_root := ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path().to_lower().trim_suffix("/") + "/"
	if _receipt_path.replace("\\", "/").simplify_path().to_lower().begins_with(project_root):
		push_error("Reader receipt must be outside the project checkout")
		quit(2)
		return
	_receipt = {"schema": 1, "scope": "SCATTER_READER_ONLY", "status": "RUNNING",
		"arm": _arm, "source_commit": source, "pid": OS.get_process_id(),
		"godot_version": str(Engine.get_version_info().get("string", "")),
		"started_utc": Time.get_datetime_string_from_system(true), "stages": [],
		"scene_loaded": false, "visual_acceptance": false, "memory_acceptance": false,
		"isolated_autoloads": _isolated_autoloads, "root_children": root.get_child_count(),
		"source_sha256": {}, "region_sha256": {}}
	if current_scene != null or root.get_child_count() != 0:
		_receipt["scene_loaded"] = true
		_fail("Reader isolation failed: unexpected scene or autoload node")
		return
	for path: String in [MANIFEST, GRASS_CONFIG, VEGETATION_CONFIG,
			"res://scripts/world/scatter_bake.gd", "res://scripts/world/terrain_bake.gd",
			"res://scripts/data/band_content.gd", "res://project.godot",
			"res://tools/probe_scatter_reader_memory.gd"]:
		_receipt.source_sha256[path] = FileAccess.get_sha256(path)
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var grass: Variant = JSON.parse_string(FileAccess.get_file_as_string(GRASS_CONFIG))
	var vegetation: Variant = JSON.parse_string(FileAccess.get_file_as_string(VEGETATION_CONFIG))
	if not manifest is Dictionary or not grass is Dictionary or not vegetation is Dictionary:
		_fail("Missing or invalid reader input configuration")
		return
	if not BAKE.is_usable("playground", int(vegetation.get("seed", 1)), -1):
		_fail("Production bake is not usable; never substitute procedural recomputation")
		return
	var suppressed := {}
	if bool(grass.get("enabled", false)):
		for layer: Variant in grass.get("suppress_scatter_layers", []):
			suppressed[str(layer)] = true
	_receipt["suppressed_layers"] = suppressed
	var regions: Array[Vector2i] = []
	for pair: Array in manifest.get("regions", []):
		regions.append(Vector2i(int(pair[0]), int(pair[1])))
	regions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	if regions.is_empty():
		_fail("Empty region catalog")
		return
	_receipt["regions"] = regions.size()
	if not await _phase("ready"):
		return
	var kept := {}
	var drained := {}
	var skipped := {}
	for region in regions:
		var path := BAKE._region_path("playground", region)
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			_fail("Missing region: " + path)
			return
		_receipt.region_sha256[path] = FileAccess.get_sha256(path)
		if file.get_32() != BAKE.MAGIC or file.get_32() != BAKE.FORMAT_VERSION:
			file.close()
			_fail("Invalid region header: " + path)
			return
		file.seek(0)
		BAKE._read_region(file, kept, drained, suppressed, skipped, _arm == "compact")
		if file.get_position() != file.get_length():
			file.close()
			_fail("Region decoder did not consume exact file: " + path)
			return
		file.close()
	_receipt["skipped_counts"] = skipped
	if not await _phase("decoded"):
		return
	# Hash individual orders only after the decoded plateau, without making a
	# second world-sized array or serializing the whole input into a byte buffer.
	_receipt["raw_orders"] = {"kept": _order_hashes(kept), "drained": _order_hashes(drained)}
	var bounds := BAKE.stable_identity_bounds(manifest, suppressed)
	_receipt["identity_bounds"] = bounds
	var output := {}
	for layer: String in bounds:
		output[layer] = []
	var drained_output := {}
	for layer: String in kept.keys():
		var bound := int((manifest.get("identity_high_water", {}) as Dictionary).get(layer, -1)) + 1
		output[layer] = _reorder(kept[layer], bool(manifest.get("stable_harvest_ids", false)), bound)
		if _arm == "compact":
			kept.erase(layer)
		if not await _phase("reordered_kept:" + layer):
			return
	for layer: String in drained.keys():
		drained_output[layer] = _reorder(drained[layer], false, 0)
		if _arm == "compact":
			drained.erase(layer)
		if not await _phase("reordered_drained:" + layer):
			return
	# Legacy load_all retains all wrappers until its function returns. Do not
	# grant that arm compact's per-layer release policy during the comparison.
	kept.clear()
	drained.clear()
	if not await _phase("retained_output"):
		return
	_receipt["output_hashes"] = {"kept": _placement_hashes(output), "drained": _placement_hashes(drained_output)}
	_receipt["status"] = "COMPLETE"
	_receipt["ended_utc"] = Time.get_datetime_string_from_system(true)
	if not _write_receipt():
		quit(2)
		return
	print("SCATTER_READER_COMPLETE " + _receipt_path)
	quit(0)


func _reorder(value: Variant, stable: bool, bound: int) -> Array[Dictionary]:
	return BAKE._reorder_column(value, stable, bound) if _arm == "compact" else BAKE._reorder(value, stable, bound)


func _order_hashes(layers: Dictionary) -> Dictionary:
	var result := {}
	for layer: String in layers:
		var digest := HashingContext.new()
		digest.start(HashingContext.HASH_SHA256)
		var count := 0
		if _arm == "compact":
			var column: BAKE.PlacementColumn = layers[layer]
			count = column.orders.size()
			for order: int in column.orders:
				digest.update(var_to_bytes(order))
		else:
			count = (layers[layer] as Array).size()
			for row: Dictionary in layers[layer]:
				digest.update(var_to_bytes(int(row.order)))
		result[layer] = {"records": count, "sha256": digest.finish().hex_encode()}
	return result


func _placement_hashes(layers: Dictionary) -> Dictionary:
	var result := {}
	for layer: String in layers:
		var digest := HashingContext.new()
		digest.start(HashingContext.HASH_SHA256)
		for placement: Dictionary in layers[layer]:
			# Both decoders share the same field insertion order. Include every
			# field and its type, including optional normals and stable IDs.
			digest.update(var_to_bytes(placement))
		result[layer] = {"records": (layers[layer] as Array).size(), "sha256": digest.finish().hex_encode()}
	return result


func _phase(name: String) -> bool:
	if current_scene != null or root.get_child_count() != 0:
		_receipt["scene_loaded"] = true
		_fail("Reader isolation changed during measurement")
		return false
	var stage := {"name": name, "elapsed_usec": Time.get_ticks_usec() - _started,
		"memory_static_bytes": OS.get_static_memory_usage()}
	_receipt.stages.append(stage)
	print("SCATTER_READER_PHASE " + JSON.stringify({"arm": _arm, "pid": OS.get_process_id(), "stage": stage}))
	if not _write_receipt():
		quit(2)
		return false
	await create_timer(HOLD_SECONDS).timeout
	return true


func _write_receipt() -> bool:
	var file := FileAccess.open(_receipt_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write reader receipt: " + _receipt_path)
		return false
	file.store_string(JSON.stringify(_receipt, "\t"))
	file.close()
	return true


func _fail(reason: String) -> void:
	_receipt["status"] = "FAILED"
	_receipt["failure"] = reason
	_write_receipt()
	push_error(reason)
	quit(1)
