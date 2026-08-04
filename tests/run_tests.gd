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
		# A script with a parse error still loads as a GDScript object; it just
		# cannot be instantiated. Checking for null alone let a broken test file
		# through and the runner then spun on a null instance instead of failing.
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			print("  FAIL  %s :: could not be parsed or instantiated" % path.get_file())
			failure_lines.append("%s: parse error, see SCRIPT ERROR above" % path)
			failed += 1
			total += 1
			continue

		var instance: Object = script.new()
		if instance == null:
			print("  FAIL  %s :: instantiation returned null" % path.get_file())
			failure_lines.append("%s: instantiation returned null" % path)
			failed += 1
			total += 1
			continue
		var file_name := path.get_file()

		for method in _test_methods(script):
			total += 1
			instance.failures.clear()
			instance.before_each()
			instance.callv(method, [])
			instance.after_each()
			var made: int = instance.assertion_count
			assertions += made
			instance.assertion_count = 0

			# A METHOD THAT ASSERTED NOTHING IS A FAILURE, not a pass.
			#
			# This runner used to report `ok` for any method whose failure list was
			# empty, and a method that dies on its first line has an empty failure
			# list. GDScript does not raise a catchable error — a bad call prints to
			# stderr, the method stops, and this loop sees a clean run.
			#
			# It cost a real bug: a static `is_tool()` on an item loader collided
			# with `Script.is_tool()`, every call failed with "expected 0 arguments",
			# and the test covering it printed `ok` for as long as it existed. The
			# suite was green over a function that could not be called at all.
			#
			# Zero assertions does not prove a method died — it might be a stub —
			# but there is no reason to have either, and both should be loud.
			if made == 0:
				failed += 1
				print("  FAIL  %s :: %s" % [file_name, method])
				print("          asserted nothing — a stub, or it died before its first assertion")
				failure_lines.append("%s :: %s — asserted nothing" % [file_name, method])
			elif instance.failures.is_empty():
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
