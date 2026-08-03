extends SceneTree

## Headless test runner.
##
##   godot --headless --path . --script tests/run_tests.gd
##
## Discovers every `test_*.gd` under res://tests/, instantiates it, and runs
## every method whose name starts with `test_`. Exits non-zero on any failure so
## CI fails the push rather than the owner finding it by playing.

const TESTS_DIR := "res://tests"


func _init() -> void:
	var files := _find_tests(TESTS_DIR)
	files.sort()

	var total := 0
	var failed := 0
	var assertions := 0
	var failure_lines: Array[String] = []

	for path in files:
		var script: GDScript = load(path)
		if script == null:
			failure_lines.append("%s: could not be loaded" % path)
			failed += 1
			continue

		var instance: Object = script.new()
		var file_name := path.get_file()

		for method in _test_methods(script):
			total += 1
			instance.failures.clear()
			instance.before_each()
			instance.callv(method, [])
			instance.after_each()
			assertions += instance.assertion_count
			instance.assertion_count = 0

			if instance.failures.is_empty():
				print("  ok    %s :: %s" % [file_name, method])
			else:
				failed += 1
				print("  FAIL  %s :: %s" % [file_name, method])
				for message in instance.failures:
					print("          %s" % message)
					failure_lines.append("%s :: %s — %s" % [file_name, method, message])

	print("")
	print("%d tests, %d assertions, %d failed" % [total, assertions, failed])
	if failed > 0:
		print("")
		for line in failure_lines:
			print("  %s" % line)
	quit(1 if failed > 0 else 0)


func _find_tests(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := "%s/%s" % [dir_path, entry]
		if dir.current_is_dir():
			if not entry.begins_with("."):
				out.append_array(_find_tests(full))
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return out


func _test_methods(script: GDScript) -> Array[String]:
	var out: Array[String] = []
	for method in script.get_script_method_list():
		var name: String = method.get("name", "")
		if name.begins_with("test_"):
			out.append(name)
	out.sort()
	return out
