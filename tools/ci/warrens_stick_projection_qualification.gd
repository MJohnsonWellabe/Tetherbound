extends SceneTree

## UNVALIDATED shutdown checkpoint: driver and native controls are unwritten.
## Preserve this prepared wrapper; do not dispatch it or claim qualification.
## One success-oriented qualification of a materially changed fixture.
## Two historical failure diagnostics are already consumed. This never retries,
## asserts their cause, edits a production flag or substitutes a shorter route.
## Native consumption/refusal controls precede the original ALL/full suite 4.

func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_name() != "Linux":
		printerr("Warrens stick qualification requires the admitted Linux hosted runner")
		quit(2)
		return
	var directory := ProjectSettings.globalize_path("res://ralph/reports/F26/warrens-stick-projection")
	if DirAccess.dir_exists_absolute(directory):
		printerr("Refusing existing qualification data; preserve the original handle")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		printerr("Cannot create retained qualification directory")
		quit(2)
		return
	var controls := PackedStringArray([
		"TB_WARRENS_OBSERVE_STEERING=",
		"XDG_DATA_HOME=" + directory.path_join("controls-xdg"),
		"godot", "--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "tests/smoke_warrens_stick_projection_controls.gd",
	])
	if _child("native-consumption-controls", controls, directory) != 0:
		# A parser/control refusal consumes this qualification. Do not attempt
		# the route with unqualified input, nor dispatch a replacement here.
		quit(1)
		return
	var suite := PackedStringArray([
		"TB_WARRENS_OBSERVE_STEERING=",
		"RUN_SUITE_DIR=" + directory.path_join("suite4"),
		"python3", "tools/ci/run_suite.py", "--suite", "4", "--tier", "full", "--jobs", "|ALL|",
	])
	var suite_exit := _child("original-full-suite4", suite, directory)
	print("Warrens stick qualification finished once; original_suite4_exit=%d; raw evidence needs independent review" % suite_exit)
	quit(0 if suite_exit == 0 else 1)


func _child(label: String, arguments: PackedStringArray, directory: String) -> int:
	print("Warrens stick qualification started: " + label)
	var output: Array = []
	# argv via env; no shell interpolation and no mounted parent-world loop.
	var result := OS.execute("env", arguments, output, true)
	var log := FileAccess.open(directory.path_join(label + ".log"), FileAccess.WRITE)
	if log == null:
		printerr("Could not retain original qualification output: " + label)
		return 2
	for block: Variant in output:
		log.store_string(str(block))
	log.close()
	print("Warrens stick qualification ended: %s exit=%d retained=%s" % [label, result, label + ".log"])
	return result
