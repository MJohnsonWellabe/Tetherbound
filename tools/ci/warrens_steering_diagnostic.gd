extends SceneTree

## One hosted diagnostic handle, no retry and no geometry/cause acceptance.
## run_suite.py retains its original ALL/full suite-4 plan and step bodies,
## including the two parallel lanes, preceding world steps and catching tail.
## The old CI artifact omitted lane XDG, so a fresh PASS cannot prove its cause.

func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_name() != "Linux":
		printerr("Warrens diagnostic requires the admitted Linux hosted runner")
		quit(2)
		return
	# upload-artifact@v4 omits every descendant of hidden directories. Keep
	# controls, the original suite logs and lane XDG in a visible report root.
	var directory := ProjectSettings.globalize_path("res://ralph/reports/F26/warrens-steering-diagnostic")
	if DirAccess.dir_exists_absolute(directory):
		printerr("Refusing existing diagnostic data; this handle must start once")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		printerr("Cannot create retained diagnostic directory")
		quit(2)
		return
	var controls := PackedStringArray([
		"TB_WARRENS_OBSERVE_STEERING=",
		"XDG_DATA_HOME=" + directory.path_join("controls-xdg"),
		"godot", "--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "tests/run_tests.gd", "--", "--only=test_warrens_walk_observer.gd",
	])
	var controls_exit := _child("observer-component-controls", controls, directory)
	if controls_exit != 0:
		# A failed qualification consumes this handle; never attempt the route
		# with an unqualified observer or retry a parser/component failure.
		quit(1)
		return
	var suite := PackedStringArray([
		"TB_WARRENS_OBSERVE_STEERING=readonly-v1",
		"RUN_SUITE_DIR=" + directory.path_join("suite4"),
		"python3", "tools/ci/run_suite.py", "--suite", "4", "--tier", "full", "--jobs", "|ALL|",
	])
	var suite_exit := _child("original-suite4-observed", suite, directory)
	print("Warrens diagnostic finished once; suite_exit=%d; geometry and cause need independent review" % suite_exit)
	quit(0 if suite_exit == 0 else 1)


func _child(label: String, arguments: PackedStringArray, directory: String) -> int:
	print("Warrens diagnostic started: " + label)
	var output: Array = []
	# argv via env, never shell interpolation. Parent SceneTree is blocked and
	# mounts no world; actual suite children own their independent lane XDG.
	var result := OS.execute("env", arguments, output, true)
	var log := FileAccess.open(directory.path_join(label + ".log"), FileAccess.WRITE)
	if log == null:
		printerr("Could not retain original child output: " + label)
		return 2
	for block: Variant in output:
		log.store_string(str(block))
	log.close()
	print("Warrens diagnostic ended: %s exit=%d retained=%s" % [label, result, label + ".log"])
	return result
