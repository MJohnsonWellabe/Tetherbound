extends "res://tools/net/peer_runner.gd"

## Isolated measurement, never the original F48 producer or an earned proof.
## ROOT supplies the original captured host directory + isolated user home,
## exact runtime overlay and the unchanged external 240-second watchdog.
## The inherited hash implementation and real physics callback remain genuine.
const COPY_INPUT := preload("res://tools/net/proof_steps.gd")
const POST_READY_SAMPLES := 5
const MAX_DIAGNOSTIC_SAMPLES := 512
var _diag_rows: Array[Dictionary] = []
var _diag_failures: Array[String] = []
var _diag_checks := 0
var _diag_callbacks := 0
var _diag_post_ready := 0
var _diag_clock: RefCounted
var _diag_started := 0
var _diag_sample_enabled := true
var _diag_loaded := false
var _diag_boot: Dictionary = {}

func _initialize() -> void:
	_diag_run.call_deferred()

func _diag_check(value: bool, detail: String) -> void:
	_diag_checks += 1
	if not value: _diag_failures.append(detail)

func _diag_run() -> void:
	await process_frame # Actual autoload initialization before any save admission.
	_diag_started = Time.get_ticks_usec()
	var source := OS.get_environment("TB_DIAGNOSTIC_SAVE_FROM")
	var output := OS.get_environment("TB_DIAGNOSTIC_OUT")
	var mode := OS.get_environment("TB_DIAGNOSTIC_HASH_MODE")
	_diag_check(mode in ["", "sample", "off"], "unknown diagnostic sampling mode")
	_diag_sample_enabled = mode != "off" # Explicit disclosed comparison control only.
	var game := root.get_node_or_null(^"Game")
	_diag_check(game != null and game.has_method("load_game") and game.has_method("world_snapshot"), "actual Game required")
	_diag_check(not source.is_empty() and DirAccess.dir_exists_absolute(source), "original captured host source required")
	_diag_check(not output.is_empty() and output.is_absolute_path(), "fresh absolute diagnostic output required")
	# Dependency is the reviewed current physics-only clock on ROOT's candidate.
	# Dynamic loading keeps this isolated helper separate from the original runner.
	var clock_script: Script = load("res://tools/net/physics_heartbeat_clock.gd")
	_diag_check(clock_script != null, "actual reviewed physics clock unavailable")
	if not _diag_failures.is_empty():
		_diag_finish(output)
		return
	_diag_clock = clock_script.new()
	_probe = PROBE.new(self)
	var slots := source.path_join("saves")
	if DirAccess.dir_exists_absolute(slots.path_join("redesign-v28")): slots = slots.path_join("redesign-v28")
	var slot_files: Array[String] = []
	var source_dir := DirAccess.open(slots)
	if source_dir != null:
		for file: String in source_dir.get_files():
			if RegEx.create_from_string("^slot_(\\d+)\\.json(\\.gz)?$").search(file) != null: slot_files.append(file)
	_diag_check(slot_files.size() == 1, "exactly one original captured slot required")
	if slot_files.size() != 1:
		_diag_finish(output)
		return
	var match_slot := RegEx.create_from_string("^slot_(\\d+)\\.json(\\.gz)?$").search(slot_files[0])
	var slot := int(match_slot.get_string(1))
	var copied := 0
	for sub: String in COPY_INPUT.SAVE_DIRS:
		copied += COPY_INPUT._copy_tree(source.path_join(sub), OS.get_user_data_dir().path_join(sub), true)
	_diag_check(copied > 0, "actual captured input copy failed")
	if copied == 0:
		_diag_finish(output)
		return
	var load_started := Time.get_ticks_usec()
	print("HASH_BOOT_DIAGNOSTIC BEGIN phase=Game.load_game at_usec=%d" % load_started)
	var loaded: bool = game.call("load_game", slot) == true
	_diag_boot.load_game_usec = Time.get_ticks_usec() - load_started
	print("HASH_BOOT_DIAGNOSTIC END phase=Game.load_game elapsed_usec=%d loaded=%s" % [_diag_boot.load_game_usec, str(loaded)])
	_diag_check(loaded and game.get("current_realm") == "meadows", "original host Meadows Game.load_game refused")
	if not loaded or game.get("current_realm") != "meadows":
		_diag_finish(output)
		return
	_diag_loaded = true
	physics_frame.connect(_diag_physics)
	var boot_started := Time.get_ticks_usec()
	print("HASH_BOOT_DIAGNOSTIC BEGIN phase=actual_world_boot at_usec=%d" % boot_started)
	# This diagnostic has no producer settle requirement. It instead waits for
	# the real original world to finish all authored content and release Player.
	await _boot_scene("world", 0)
	_diag_boot.scene_queued_usec = Time.get_ticks_usec() - boot_started
	while current_scene != null and current_scene.has_method("shell_build_complete") \
		and current_scene.call("shell_build_complete") != true:
		await physics_frame
	_diag_boot.actual_ready_usec = Time.get_ticks_usec() - boot_started
	print("HASH_BOOT_DIAGNOSTIC END phase=actual_world_boot elapsed_usec=%d" % _diag_boot.actual_ready_usec)
	_diag_check(current_scene != null and current_scene.has_method("shell_build_complete") \
		and current_scene.call("shell_build_complete") == true, "actual authored world must finish")
	while _diag_post_ready < POST_READY_SAMPLES and _diag_rows.size() < MAX_DIAGNOSTIC_SAMPLES:
		await physics_frame
	_diag_check(_diag_post_ready >= POST_READY_SAMPLES, "complete initialized physics samples required")
	physics_frame.disconnect(_diag_physics)
	_diag_check(_diag_callbacks > 0 and not _diag_rows.is_empty(), "actual physics callbacks not observed")
	if _diag_sample_enabled:
		_diag_check(_diag_rows.all(func(row: Dictionary) -> bool: return row.get("hash_equal") == true), "every measured original hash must equal fresh sorted payload")
	var scene := current_scene
	current_scene = null
	if scene != null:
		root.remove_child(scene)
		scene.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	_diag_check(scene == null or not is_instance_valid(scene), "complete actual world teardown required")
	_diag_finish(output)

func _diag_physics() -> void:
	# Only this genuine SceneTree.physics_frame callback invokes measurement.
	_diag_callbacks += 1
	if not _diag_loaded or not _diag_clock.call("physics_callback", _diag_callbacks, Time.get_ticks_msec(), HEARTBEAT_FRAMES): return
	var ready: bool = current_scene != null and current_scene.has_method("shell_build_complete") \
		and current_scene.call("shell_build_complete") == true
	if ready: _diag_post_ready += 1
	if _diag_rows.size() >= MAX_DIAGNOSTIC_SAMPLES:
		_diag_failures.append("diagnostic sample carrier exhausted")
		return
	var row := {"callback": _diag_callbacks, "physics_frame": Engine.get_physics_frames(),
		"process_frame": Engine.get_process_frames(), "at_usec": Time.get_ticks_usec(), "world_ready": ready,
		"sample_enabled": _diag_sample_enabled}
	if _diag_sample_enabled:
		var game := root.get_node_or_null(^"Game")
		var context_started := Time.get_ticks_usec()
		print("HASH_BOOT_DIAGNOSTIC BEGIN callback=%d phase=input_context at_usec=%d" % [_diag_callbacks, context_started])
		row.input_context = _probe.call("input_context")
		row.input_context_usec = Time.get_ticks_usec() - context_started
		var hash_started := Time.get_ticks_usec()
		print("HASH_BOOT_DIAGNOSTIC BEGIN callback=%d phase=original_hash at_usec=%d" % [_diag_callbacks, hash_started])
		var actual_hash: Variant = _compute_state_hash() # Actual inherited production sampler.
		row.original_hash_usec = Time.get_ticks_usec() - hash_started
		var snapshot_started := Time.get_ticks_usec()
		print("HASH_BOOT_DIAGNOSTIC BEGIN callback=%d phase=world_snapshot at_usec=%d" % [_diag_callbacks, snapshot_started])
		var full: Dictionary = game.call("world_snapshot")
		row.world_snapshot_usec = Time.get_ticks_usec() - snapshot_started
		var serialization_started := Time.get_ticks_usec()
		print("HASH_BOOT_DIAGNOSTIC BEGIN callback=%d phase=sorted_json_hash at_usec=%d" % [_diag_callbacks, serialization_started])
		var selected := hashed_subset(full)
		var sorted_json := JSON.stringify(selected, "", true)
		var expected_hash := hash(sorted_json)
		row.sorted_json_hash_usec = Time.get_ticks_usec() - serialization_started
		row.original_hash = actual_hash
		row.expected_hash = expected_hash
		row.hash_equal = actual_hash != null and actual_hash == expected_hash
		row.world_snapshot = full.duplicate(true)
		row.selected_payload = selected.duplicate(true)
		row.sorted_json = sorted_json
		var selected_keys := selected.keys()
		selected_keys.sort()
		var expected_keys := HASHED_KEYS.duplicate()
		expected_keys.sort()
		_diag_check(selected_keys == expected_keys, "exact original seven hashed world keys required")
		for excluded: String in EXCLUDED_KEYS:
			_diag_check(not selected.has(excluded), "original excluded field selected: " + excluded)
		_diag_check(not selected.has("world_seed"), "original erased world_seed must stay erased")
		_diag_check(row.hash_equal, "actual inherited sampler mismatch")
		print("HASH_BOOT_DIAGNOSTIC SAMPLE " + JSON.stringify({"callback": row.callback, "world_ready": ready,
			"process_frame": row.process_frame, "physics_frame": row.physics_frame,
			"input_context_usec": row.input_context_usec, "original_hash_usec": row.original_hash_usec,
			"world_snapshot_usec": row.world_snapshot_usec, "sorted_json_hash_usec": row.sorted_json_hash_usec,
			"hash_equal": row.hash_equal}))
	_diag_rows.append(row)

func _diag_finish(output: String) -> void:
	var result := {"schema_version": 1, "diagnostic_only": true, "acceptance_credit": false,
		"sample_enabled": _diag_sample_enabled, "checks": _diag_checks, "failures": _diag_failures.duplicate(),
		"boot": _diag_boot.duplicate(true), "samples": _diag_rows.duplicate(true), "callbacks": _diag_callbacks,
		"post_ready_samples": _diag_post_ready, "elapsed_usec": Time.get_ticks_usec() - _diag_started}
	var artifact := output.path_join("physics-hash-boot-diagnostic.json")
	var serialized := JSON.stringify(result, "\t", true)
	var artifact_ok := not output.is_empty() and output.is_absolute_path() and not FileAccess.file_exists(artifact) \
		and DirAccess.make_dir_recursive_absolute(output) == OK
	if artifact_ok:
		var file := FileAccess.open(artifact, FileAccess.WRITE)
		artifact_ok = file != null
		if file != null:
			file.store_string(serialized)
			file.close()
			artifact_ok = FileAccess.get_file_as_string(artifact) == serialized
	print("HASH_BOOT_DIAGNOSTIC_SUMMARY " + JSON.stringify({"completed": 1, "checks": _diag_checks,
		"failures": _diag_failures, "sample_enabled": _diag_sample_enabled, "samples": _diag_rows.size(),
		"post_ready_samples": _diag_post_ready, "artifact_ok": artifact_ok, "artifact": artifact,
		"artifact_sha256": serialized.sha256_text() if artifact_ok else "", "diagnostic_only": true,
		"acceptance_credit": false}))
	quit(0 if _diag_failures.is_empty() and artifact_ok else 1)
