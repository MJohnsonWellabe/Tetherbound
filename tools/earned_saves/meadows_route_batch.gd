extends SceneTree

## One artifact retains every ordinary-input piece and its original SaveDocs.
## --mode=generated runs the independently declared Relay and Hall boundaries.
## --mode=earned composes all six pieces through their actual saved predecessors.
## Neither mode claims a continuous fresh-save run, three seeds, or measured
## spacing/recovery: those require their separate complete-route witnesses.
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const DRIVER := "res://tools/earned_saves/earned_chain_runner.gd"
const CHILD_TIMEOUT_SECONDS := 2700
var mode := ""
var output_root := ""
var check_only := false
var failures: Array[String] = []
var pieces: Array = []
var results: Array = []
var source := ""


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode=") and mode.is_empty():
			mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--output-root=") and output_root.is_empty():
			output_root = arg.trim_prefix("--output-root=")
		elif arg == "--check-only" and not check_only:
			check_only = true
		else:
			failures.append("Unknown or duplicate batch option: " + arg)
	if mode not in ["generated", "earned"] or output_root.is_empty():
		failures.append("usage: --mode=generated|earned --output-root=<absent directory> [--check-only]")
	if OS.has_environment("TB_WORLD_SEED"):
		failures.append("Piece batches retain their actual saved populations; no seed override")
	output_root = ProjectSettings.globalize_path(output_root).simplify_path().trim_suffix("/")
	if DirAccess.dir_exists_absolute(output_root) or FileAccess.file_exists(output_root):
		failures.append("Batch output must be absent; refusing to overwrite evidence")
	source = CHECKPOINTS.commit_sha()
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-f]{40}$")
	if pattern.search(source) == null:
		failures.append("Batch requires the exact clean source commit")
	pieces = ["relay", "hall"] if mode == "generated" else HANDOFF.MEADOWS_PIECES.duplicate()
	if not failures.is_empty() or check_only:
		print("MEADOWS BATCH CHECK " + JSON.stringify({"passed": failures.is_empty(),
			"source": source, "mode": mode, "pieces": pieces, "failures": failures,
			"native_play": false, "acceptance_claim": false}))
		quit(0 if failures.is_empty() else 1)
		return
	if DirAccess.make_dir_recursive_absolute(output_root) != OK:
		failures.append("Cannot create new batch output")
		_finish()
		return
	var previous := ""
	for piece: String in pieces:
		var child_root := output_root.path_join(piece + "_run")
		var boundary := child_root.path_join(piece)
		var log_path := output_root.path_join(piece + ".log")
		var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--audio-driver", "Dummy", "--log-file", log_path, "--script", DRIVER, "--",
			"--segment=" + piece, "--save-dir=" + boundary.path_join("save"),
			"--receipt=" + boundary.path_join("receipt.json")])
		if mode == "generated":
			args.append("--generated-fixture")
		elif not previous.is_empty():
			args.append("--handoff-from=" + previous)
		print("MEADOWS BATCH CHILD " + JSON.stringify({"piece": piece, "source": source,
			"args": args, "log": log_path, "input_mode": mode}))
		var started := Time.get_ticks_msec()
		var pid := OS.create_process(OS.get_executable_path(), args)
		if pid <= 0:
			failures.append("Cannot start actual piece: " + piece)
			break
		var deadline := started + CHILD_TIMEOUT_SECONDS * 1000
		while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
			await create_timer(1.0).timeout
		if OS.is_process_running(pid):
			OS.kill(pid)
			failures.append("Actual piece exceeded its bounded time: " + piece)
			results.append({"piece": piece, "passed": false, "timeout": true, "log": log_path})
			break
		var exit_code := OS.get_process_exit_code(pid)
		var raw := FileAccess.get_file_as_string(boundary.path_join("receipt.json"))
		var parsed: Variant = DOCUMENT.parse(raw)
		var errors: Array[String] = []
		if exit_code != 0:
			errors.append("Actual child exit=%d" % exit_code)
		if not parsed is Dictionary:
			errors.append("No readable original actual boundary receipt")
		else:
			var receipt: Dictionary = parsed
			var proof: Dictionary = receipt.get("piece_proof", {})
			if receipt.get("kind") != "earned_meadows_piece" or receipt.get("boundary") != piece \
					or receipt.get("commit") != source or proof.get("passed") != true \
					or not proof.get("failures", ["missing failures"]).is_empty():
				errors.append("Actual receipt must retain exact-source successful ordinary-input piece proof")
			if mode == "generated" and (receipt.get("input_mode") != "generated_fixture" \
					or receipt.get("continuous_fresh_save") != false or not receipt.has("generated_origin")):
				errors.append("Generated predecessor provenance missing")
			if mode == "earned" and (receipt.has("generated_origin") or receipt.has("input_mode")):
				errors.append("Earned composition cannot adopt generated predecessor evidence")
		if not FileAccess.file_exists(log_path):
			errors.append("Actual child log missing")
		else:
			var actual_log := FileAccess.get_file_as_string(log_path)
			for marker: String in ["SCRIPT ERROR:", "ERROR:", "Parse Error:"]:
				if actual_log.contains(marker):
					errors.append("Actual child log contains " + marker)
		var row := {"piece": piece, "source": source, "passed": errors.is_empty(), "exit": exit_code,
			"seconds": (Time.get_ticks_msec() - started) / 1000.0, "boundary": boundary,
			"original_receipt": boundary.path_join("receipt.json"), "log": log_path,
			"receipt_sha256": FileAccess.get_sha256(boundary.path_join("receipt.json")) if not raw.is_empty() else "",
			"failures": errors}
		results.append(row)
		for error: String in errors:
			failures.append(piece + ": " + error)
		if not failures.is_empty():
			break
		previous = boundary
	_finish()


func _finish() -> void:
	var receipt := {"kind": "meadows_ordinary_input_piece_batch", "source": source,
		"mode": mode, "passed": failures.is_empty() and results.size() == pieces.size(),
		"pieces": pieces, "results": results, "failures": failures,
		"continuous_fresh_save": false, "prior_earned_play": mode == "earned",
		"generated_segments_independent": mode == "generated", "config_default_changes": [],
		"feature_flips": 0, "independent_review_required": true,
		"unproven_whole_criteria": ["F02#4 all route reload/reward/recovery", "F02#6 three-seed no repeated wilds",
			"F02#7 same complete route WORLD3.1 spacing and strict A7 recomputation"]}
	var file := FileAccess.open(output_root.path_join("receipt.json"), FileAccess.WRITE)
	if file == null:
		failures.append("Cannot retain batch receipt")
		receipt.passed = false
	else:
		file.store_string(JSON.stringify(receipt, "  "))
		file.close()
	print("MEADOWS BATCH RESULT " + JSON.stringify(receipt))
	quit(0 if receipt.passed else 1)
