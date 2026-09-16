extends TestCase

const EVIDENCE := preload("res://tools/gate_f/phase_evidence.gd")
const HARNESS := preload("res://tools/gate_f/operator_harness.gd")
var _files: Array[String] = []
var _dirs: Array[String] = []


func test_shipped_first_phase_verifies_and_save_wrappers_do_not_pay_metrics() -> void:
	var phase := EVIDENCE.read_json("res://tools/gate_f/segments/S03p1.json")
	var checked := EVIDENCE.verify(phase.phase, phase.id, "user://absent-phase-run", "revision", phase.steps)
	assert_true(checked.ok, str(checked.why))
	var harness := HARNESS.new()
	harness._phase = phase.phase
	harness._steps = phase.steps
	harness._step_index = 0
	assert_true(harness._measures_phase_step())
	assert_eq(harness._phase_event_context(), {"phase_parent": "S03",
		"phase_added": false, "step_id": phase.steps[0].id})
	harness._step_index = phase.steps.size() - 1
	assert_false(harness._measures_phase_step(), "added physical save wrappers cannot inflate route metrics")
	assert_eq(harness._phase_event_context(), {"phase_parent": "S03",
		"phase_added": true, "step_id": phase.steps[-1].id})
	harness._step_index = -1
	assert_eq(harness._phase_event_context(), {"phase_parent": "S03", "phase_added": true})
	harness._phase = {}
	assert_eq(harness._phase_event_context(), {}, "ordinary segments omit inapplicable phase attribution")
	harness.free()


func after_each() -> void:
	_files.reverse()
	for path: String in _files:
		DirAccess.remove_absolute(path)
	_dirs.reverse()
	for path: String in _dirs:
		DirAccess.remove_absolute(path)
	_files.clear()
	_dirs.clear()


func _directory(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path)
	_dirs.append(path)


func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  ") + "\n")
	file.close()
	if not _files.has(path):
		_files.append(path)


func _fixture() -> Dictionary:
	var root := "user://gate_f_phase_test_%d" % Time.get_ticks_usec()
	_directory(root)
	var source := root.path_join("source.json")
	var manifest := root.path_join("manifest.json")
	var source_steps: Array = []
	for index in 3:
		source_steps.append({"id": "S03-%d" % index, "action": "assert",
			"args": {"check": "input_context", "equals": "world"}})
	_write(source, {"id": "S03", "steps": source_steps})
	var source_hash := FileAccess.get_file_as_string(source).replace("\r\n", "\n").sha256_text()
	var order := ["S03p1", "S03p2", "S03p3"]
	var phases: Array = []
	for index in 3:
		phases.append({"parent": "S03", "index": index, "order": order,
			"source_path": source, "source_sha256": source_hash, "manifest_path": manifest,
			"previous_segment": "" if index == 0 else order[index - 1],
			"input_save": "S02-exit.json" if index == 0 else order[index - 1] + "-exit.json",
			"output_save": order[index] + "-exit.json",
			"original_step_ids": [source_steps[index].id], "added_step_ids": []})
	_write(manifest, {"parent": "S03", "source_path": source,
		"source_sha256": source_hash, "order": order, "phases": phases})
	var previous_hash := "seed-receipt"
	for index in 2:
		var directory := root.path_join(order[index])
		_directory(directory)
		_directory(directory.path_join("saves"))
		var save := directory.path_join("saves").path_join(phases[index].output_save)
		_write(save, {"production_save_fixture": index})
		var receipt: Dictionary = phases[index].duplicate(true)
		receipt.input_sha256 = previous_hash
		receipt.output_sha256 = FileAccess.get_sha256(save)
		previous_hash = receipt.output_sha256
		receipt.metrics = {"distance_m": 10.0 if index == 0 else 30.0,
			"dead_travel_m": 3.0, "dead_travel_peak": 5.0,
			"since_interaction_s": 2.0, "trace_rows": 100 * (index + 1)}
		_write(directory.path_join("INVENTORY.json"), {"segment": order[index],
			"sha": "fixture-sha", "complete": true,
			"steps": {"total": 1, "ran": 1, "fail": 0, "skipped": 0, "refused": 0},
			"phase": receipt})
	return {"root": root, "phase": phases[2], "steps": [source_steps[2]],
		"source": source, "manifest": manifest, "expected_hash": previous_hash}


func _verify(f: Dictionary) -> Dictionary:
	return EVIDENCE.verify(f.phase, "S03p3", f.root, "fixture-sha", f.steps)


func test_verified_chain_carries_last_aggregate_without_double_counting() -> void:
	var f := _fixture()
	var result := _verify(f)
	assert_true(result.ok, str(result.why))
	assert_eq(result.metrics.distance_m, 30.0)
	assert_eq(result.metrics.trace_rows, 200)
	assert_eq(result.input_sha256, f.expected_hash)


func test_missing_failed_or_foreign_revision_predecessor_is_refused() -> void:
	for kind: String in ["missing", "failed", "revision", "skipped"]:
		var f := _fixture()
		var path := str(f.root).path_join("S03p1/INVENTORY.json")
		var inv := EVIDENCE.read_json(path)
		match kind:
			"missing": DirAccess.remove_absolute(path)
			"failed":
				inv.steps.fail = 1
				_write(path, inv)
			"revision":
				inv.sha = "different-revision"
				_write(path, inv)
			"skipped":
				inv.steps.skipped = 1
				_write(path, inv)
		assert_false(_verify(f).ok, kind)


func test_save_tamper_and_input_hash_discontinuity_are_refused() -> void:
	var f := _fixture()
	_write(str(f.root).path_join("S03p1/saves/S03p1-exit.json"), {"tampered": true})
	assert_false(_verify(f).ok)
	f = _fixture()
	var path := str(f.root).path_join("S03p2/INVENTORY.json")
	var inv := EVIDENCE.read_json(path)
	inv.phase.input_sha256 = "different-save"
	_write(path, inv)
	assert_false(_verify(f).ok)


func test_input_name_source_change_and_original_step_edits_are_refused() -> void:
	var f := _fixture()
	f.phase.input_save = "unrelated-exit.json"
	assert_false(_verify(f).ok)
	f = _fixture()
	f.steps[0].args.equals = "menu_save"
	assert_false(_verify(f).ok)
	f = _fixture()
	_write(f.source, {"id": "S03", "steps": []})
	assert_false(_verify(f).ok)


func test_invalid_or_regressing_metrics_and_missing_executed_steps_are_refused() -> void:
	var f := _fixture()
	var path := str(f.root).path_join("S03p2/INVENTORY.json")
	var inv := EVIDENCE.read_json(path)
	inv.phase.metrics.distance_m = 5.0
	_write(path, inv)
	assert_false(_verify(f).ok)
	f = _fixture()
	path = str(f.root).path_join("S03p2/INVENTORY.json")
	inv = EVIDENCE.read_json(path)
	inv.phase.metrics.trace_rows = 200.5
	_write(path, inv)
	assert_false(_verify(f).ok)
	f = _fixture()
	assert_false(EVIDENCE.verify(f.phase, "S03p3", f.root, "fixture-sha").ok)
