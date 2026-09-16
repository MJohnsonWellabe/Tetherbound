extends RefCounted

## Explicit physical-save phases retain one source definition and cumulative
## original-step metrics. Added save/load wrappers never pay pacing assertions.
static func read_json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return value if value is Dictionary else {}


static func clean_inventory(inv: Dictionary) -> bool:
	if not bool(inv.get("complete", false)):
		return false
	var steps: Dictionary = inv.get("steps", {})
	for key: String in ["total", "ran", "fail", "skipped", "refused"]:
		var count: Variant = steps.get(key)
		if typeof(count) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(count)) \
				or float(count) < 0.0 or floorf(float(count)) != float(count):
			return false
	if int(steps.get("total", 0)) <= 0 or int(steps.get("ran", -1)) != int(steps.get("total", 0)):
		return false
	for key: String in ["fail", "skipped", "refused"]:
		if int(steps.get(key, -1)) != 0:
			return false
	return str(inv.get("blocked", "")).is_empty() and str(inv.get("derailed", "")).is_empty() \
		and (inv.get("derails", []) as Array).is_empty() and (inv.get("harness_errors", []) as Array).is_empty()


static func safe_name(value: String) -> bool:
	return not value.is_empty() and value == value.get_file() and value not in [".", ".."] \
		and not value.contains("/") and not value.contains("\\")


static func declaration_matches(actual: Dictionary, expected: Dictionary) -> bool:
	for key: String in ["parent", "index", "order", "source_path", "source_sha256", "previous_segment",
			"input_save", "output_save", "original_step_ids", "added_step_ids"]:
		if not actual.has(key) or actual[key] != expected.get(key):
			return false
	for key: String in ["terminal_capture", "template_source_path", "template_source_sha256"]:
		if actual.get(key) != expected.get(key):
			return false
	return true


static func verify(phase: Dictionary, segment: String, run_root: String, sha: String,
		steps: Array = []) -> Dictionary:
	var failure := {"ok": false, "why": "invalid phase declaration", "metrics": {}}
	var order: Array = phase.get("order", [])
	var index := int(phase.get("index", -1))
	if sha.is_empty() or not safe_name(str(phase.get("parent", ""))) \
			or index < 0 or index >= order.size() or str(order[index]) != segment:
		return failure
	var seen_names := {}
	for name: Variant in order:
		if not safe_name(str(name)) or seen_names.has(str(name).to_lower()):
			return failure
		seen_names[str(name).to_lower()] = true
	var source := str(phase.get("source_path", ""))
	if not FileAccess.file_exists(source):
		failure.why = "phase source is missing"
		return failure
	var source_hash := FileAccess.get_file_as_string(source).replace("\r\n", "\n").sha256_text()
	if source_hash != str(phase.get("source_sha256", "")):
		failure.why = "phase source changed; regenerate phases before running"
		return failure
	var original := read_json(source)
	var manifest := read_json(str(phase.get("manifest_path", "")))
	var template_path := str(phase.get("template_source_path", ""))
	var template_hash := str(phase.get("template_source_sha256", ""))
	var template_source := original
	if not template_path.is_empty():
		if not FileAccess.file_exists(template_path) \
				or FileAccess.get_file_as_string(template_path).replace("\r\n", "\n").sha256_text() != template_hash \
				or str(manifest.get("template_source_path", "")) != template_path \
				or str(manifest.get("template_source_sha256", "")) != template_hash:
			failure.why = "external production template changed or lacks matching provenance"
			return failure
		template_source = read_json(template_path)
	elif not template_hash.is_empty() or manifest.has("template_source_path"):
		return failure
	if str(original.get("id", "")) != str(phase.get("parent", "")) \
			or str(manifest.get("parent", "")) != str(phase.get("parent", "")) \
			or str(manifest.get("source_path", "")) != source \
			or str(manifest.get("source_sha256", "")) != source_hash or manifest.get("order", []) != order:
		failure.why = "phase manifest does not match its canonical source"
		return failure
	var declarations: Array = manifest.get("phases", [])
	if declarations.size() != order.size():
		return failure
	var source_steps: Array = original.get("steps", [])
	var source_by_id := {}
	var source_ids: Array = []
	var template_by_id := {}
	for template_step: Dictionary in template_source.get("steps", []):
		var template_id := str(template_step.get("id", ""))
		if template_id.is_empty() or template_by_id.has(template_id):
			return failure
		template_by_id[template_id] = template_step
	for step: Dictionary in source_steps:
		var id := str(step.get("id", ""))
		if id.is_empty() or source_by_id.has(id):
			return failure
		source_by_id[id] = step
		source_ids.append(id)
	var partition: Array = []
	for position in declarations.size():
		var declaration: Dictionary = declarations[position]
		if declaration.has("terminal_capture") and typeof(declaration.terminal_capture) != TYPE_BOOL:
			return failure
		var terminal := bool(declaration.get("terminal_capture", false))
		if terminal and (position != order.size() - 1 or str(original.get("evidence_lane", "")) != "capture" \
				or not bool(manifest.get("terminal_capture", false)) or str(declaration.get("output_save", "")) != ""):
			failure.why = "only final capture phase may omit its output save"
			return failure
		if int(declaration.get("index", -1)) != position or declaration.get("order", []) != order \
				or str(declaration.get("parent", "")) != str(phase.parent) \
				or str(declaration.get("source_sha256", "")) != source_hash \
				or str(declaration.get("source_path", "")) != source \
				or not safe_name(str(declaration.get("input_save", ""))) \
				or (not terminal and not safe_name(str(declaration.get("output_save", "")))) \
				or str(declaration.get("template_source_path", "")) != template_path \
				or str(declaration.get("template_source_sha256", "")) != template_hash:
			return failure
		var previous_name := "" if position == 0 else str(order[position - 1])
		if str(declaration.get("previous_segment", "")) != previous_name:
			return failure
		if position > 0 and str(declaration.input_save) != str(declarations[position - 1].output_save):
			failure.why = "phase input save does not match predecessor output name"
			return failure
		partition.append_array(declaration.get("original_step_ids", []))
	if partition != source_ids or not declaration_matches(phase, declarations[index]):
		failure.why = "phase step partition or declaration differs from manifest/source"
		return failure
	var actual_original: Array = []
	var actual_added: Array = []
	var seen_ids := {}
	for step: Dictionary in steps:
		var id := str(step.get("id", ""))
		if seen_ids.has(id):
			failure.why = "duplicate phase step ID"
			return failure
		seen_ids[id] = true
		if step.has("_phase_added"):
			var added: Dictionary = step["_phase_added"]
			var template_id := str(added.get("template_step", ""))
			var kind := str(added.get("kind", ""))
			if not template_by_id.has(template_id) or kind not in ["load", "save"] \
					or str(added.get("template_source_path", "")) != template_path \
					or str(added.get("template_source_sha256", "")) != template_hash:
				failure.why = "phase-added step has no canonical Save/Load template"
				return failure
			var template: Dictionary = template_by_id[template_id].duplicate(true)
			template.id = id
			template["_phase_added"] = added
			if str(template.action) == "seed_save":
				template.args["from"] = "run://" + str(phase.input_save)
			elif str(template.action) == "save_out":
				template.args.name = str(phase.output_save)
			var observed := step.duplicate(true)
			template.erase("expected")
			observed.erase("expected")
			if observed != template:
				failure.why = "phase-added step differs from its production template"
				return failure
			actual_added.append(id)
		else:
			if not source_by_id.has(id) or step != source_by_id[id]:
				failure.why = "phase original step %s differs from canonical source" % id
				return failure
			actual_original.append(id)
	if actual_original != phase.get("original_step_ids", []) or actual_added != phase.get("added_step_ids", []):
		failure.why = "phase executed step IDs differ from the declared partition"
		return failure
	var metrics := {}
	var previous_output_hash := ""
	var previous_metrics := {}
	for position in index:
		var name := str(order[position])
		var inv := read_json(run_root.path_join(name).path_join("INVENTORY.json"))
		if not clean_inventory(inv) or str(inv.get("sha", "")) != sha or str(inv.get("segment", "")) != name:
			failure.why = "phase predecessor %s is missing, failed, incomplete, or from another revision" % name
			return failure
		var receipt: Dictionary = inv.get("phase", {})
		if not declaration_matches(receipt, declarations[position]) \
				or str(receipt.get("input_sha256", "")).is_empty() \
				or int(inv.steps.total) != (receipt.original_step_ids as Array).size() + (receipt.added_step_ids as Array).size():
			failure.why = "phase predecessor %s has incompatible provenance" % name
			return failure
		var output := str(receipt.get("output_save", ""))
		if not safe_name(output):
			return failure
		var path := run_root.path_join(name).path_join("saves").path_join(output)
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != str(receipt.get("output_sha256", "")):
			failure.why = "phase predecessor %s save is missing or its hash changed" % name
			return failure
		if position > 0 and str(receipt.get("input_sha256", "")) != previous_output_hash:
			failure.why = "phase predecessor %s broke save continuity" % name
			return failure
		previous_output_hash = FileAccess.get_sha256(path)
		metrics = receipt.get("metrics", {})
		for key: String in ["distance_m", "dead_travel_m", "dead_travel_peak", "since_interaction_s", "trace_rows"]:
			if not metrics.has(key) or typeof(metrics[key]) not in [TYPE_INT, TYPE_FLOAT] \
					or not is_finite(float(metrics[key])) or float(metrics[key]) < 0.0:
				failure.why = "phase predecessor %s lacks valid aggregate metrics" % name
				return failure
		if float(metrics.trace_rows) != floorf(float(metrics.trace_rows)) \
				or float(metrics.dead_travel_peak) < float(metrics.dead_travel_m):
			failure.why = "phase predecessor metrics are inconsistent"
			return failure
		for key: String in ["distance_m", "dead_travel_peak", "trace_rows"]:
			if previous_metrics.has(key) and float(metrics[key]) < float(previous_metrics[key]):
				failure.why = "phase predecessor aggregate metrics moved backwards"
				return failure
		previous_metrics = metrics
	return {"ok": true, "why": "verified phase predecessor chain", "metrics": metrics,
		"input_sha256": previous_output_hash}
