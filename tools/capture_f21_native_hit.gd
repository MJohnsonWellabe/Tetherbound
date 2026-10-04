extends "res://tools/capture_f21_hit_presentation.gd"

## Native F21 handoff overlay; run against the coordinator's clean source pin.
## --rendering-method forward_plus --resolution 1920x1080 --script <this file>
## -- --preset=Medium --source-commit=<pin> --out=<fresh dir> --sequence
## Add --baseline for the matched impact-layer-off set. Never use --fast or
## --fixed-fps. Relative audit helpers allow this script to live outside the
## pinned project without editing that project's source.
const NATIVE_BOOTSTRAP := preload("lookdev_capture_bootstrap.gd")
const NATIVE_GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const NATIVE_WRITER := preload("capture_manifest_writer.gd")
const NATIVE_SEED := 210617239
var _native_profile: Dictionary = {}


func _run() -> void:
	await process_frame
	var arguments := OS.get_cmdline_user_args()
	if DisplayServer.get_name() == "headless":
		print("F21 native hit capture requires a real renderer; headless refused.")
		quit(2)
		return
	var accelerated := arguments.has("--fast")
	for argument: String in OS.get_cmdline_args():
		accelerated = accelerated or argument.begins_with("--fixed-fps")
	if not arguments.has("--sequence") or not arguments.has("--preset=Medium") \
			or accelerated or not is_equal_approx(Engine.time_scale, 1.0) \
			or Engine.physics_ticks_per_second != 60 or not RenderingServer.render_loop_enabled:
		print("F21 native hit capture requires Medium, full sequence and ordinary continuously drawn time.")
		quit(2)
		return
	# Earlier parent versions lack matched sequences/timing. Do not silently
	# turn an old source into a different capture or manufacture its missing data.
	var properties := {}
	for property: Dictionary in get_property_list():
		properties[str(property.name)] = true
	for name: String in ["_sequence", "_baseline", "_fast", "_frame_times"]:
		if not properties.has(name):
			print("F21 native hit capture requires the coordinator's updated parent tool.")
			quit(2)
			return
	_native_profile = NATIVE_BOOTSTRAP.prepare(self, "--out=")
	if _native_profile.is_empty() or _native_profile.get("preset") != "Medium":
		quit(2)
		return
	seed(NATIVE_SEED)
	await super._run()


func _finish() -> void:
	super._finish()
	var path := _out.path_join("receipts.json")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("F21 native hit capture could not read the parent receipt")
		quit(1)
		return
	var receipt: Dictionary = parsed
	var samples: Variant = receipt.get("frame_times_ms", [])
	if not samples is Array or samples.size() != 300:
		_failures.append("Native parent timing must retain all 300 drawn fight frames")
	else:
		for sample: Variant in samples:
			if not sample is float and not sample is int:
				_failures.append("Native frame timing is not numeric")
				break
			var ms := float(sample)
			if is_nan(ms) or is_inf(ms) or ms <= 0.0:
				_failures.append("Native frame timing is not finite and positive")
				break
	if NATIVE_GRAPHICS.selected() != "Medium" \
			or RenderingServer.get_current_rendering_method() != "forward_plus":
		_failures.append("Native Medium/Forward+ settings changed during capture")
	var files: Array[Dictionary] = []
	var roles := {}
	var image_paths := {}
	for row: Dictionary in _log:
		var role := str(row.get("shot", ""))
		if roles.has(role):
			_failures.append("Native hit sequence role is duplicated: " + role)
		roles[role] = true
		var impact: Dictionary = row.get("receipt", {})
		var expected_slot := "charged" if role == "charged" else "quick"
		if not role in ["quick", "charged", "crit", "incoming"] \
				or bool(row.get("on_enemy", false)) != (role != "incoming") \
				or str(impact.get("slot", "")) != expected_slot \
				or not impact.has("critical") \
				or (role != "incoming" and bool(impact.critical) != (role == "crit")):
			_failures.append("Native shot label does not match its confirmed impact receipt: " + role)
		var sequence: Array = row.get("sequence_png", [])
		if sequence.size() != 7:
			_failures.append("Native hit sequence must contain seven images per role")
		for filename: String in sequence:
			if image_paths.has(filename):
				_failures.append("Native hit sequence image is duplicated: " + filename)
			image_paths[filename] = true
			if not FileAccess.file_exists(filename):
				_failures.append("Native hit sequence image is missing: " + filename)
				continue
			var image := Image.load_from_file(filename)
			if image == null or image.get_size() != Vector2i(1920, 1080):
				_failures.append("Native hit sequence image is not 1920x1080: " + filename)
			var digest := FileAccess.get_sha256(filename)
			if digest.length() != 64:
				_failures.append("Native hit sequence image could not be hashed: " + filename)
			files.append({"path": filename, "sha256": digest})
	for role: String in ["quick", "charged", "crit", "incoming"]:
		if not roles.has(role):
			_failures.append("Native hit sequence role is missing: " + role)
	receipt["source_commit"] = _native_profile.get("source_commit", "")
	receipt["graphics_capture"] = _native_profile
	receipt["graphics_values"] = NATIVE_GRAPHICS.values()
	receipt["global_rng_seed"] = NATIVE_SEED
	receipt["pairing_scope"] = "Only the global RNG is seeded. Production nodes also randomize private generators; matched contact outcomes and damage are unproved and require cross-run review. Capture completeness does not certify a matched A/B pair."
	receipt["sequence_files"] = files
	receipt["timing_scope"] = "Parent's 300 continuously drawn process-frame intervals in the entered live fight before the scripted contact sequences. PNG I/O is outside this interval; not GPU-only timing or hit-sequence frame-time proof."
	receipt["scope"] = "Existing parent fixture, same global RNG seed/preset/source for comparison inputs; its baseline disables the impact layer in memory. Sequence offsets are 0,2,4,6,10,16,24 after confirmed contact; no pre-contact frame. No actor rescale, accelerated or hidden rendering, earned campaign or Ally acceptance. Independent pairing/image/full-feature review remains required."
	receipt["failures"] = _failures
	receipt["complete"] = _failures.is_empty()
	var error := NATIVE_WRITER.write_json(path, receipt)
	if error != OK:
		push_error("F21 native hit receipt publication failed: " + error_string(error))
	for failure: String in _failures:
		printerr("[f21-native] FAIL ", failure)
	quit(0 if error == OK and _failures.is_empty() else 1)
