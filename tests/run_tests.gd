extends SceneTree

## Headless test runner.
##
##   godot --headless --path . --script tests/run_tests.gd
##   godot --headless --path . --script tests/run_tests.gd -- --shard=1/2
##
## Discovers every `test_*.gd` under res://tests/, instantiates it, and runs
## every method whose name starts with `test_`. Exits non-zero on any failure so
## CI fails the push rather than the owner finding it by playing.
##
## ## Sharding
##
## `--shard=I/N` runs only the Ith of N slices of the discovered files. With no
## flag the runner behaves exactly as it always has and runs everything, so
## every local invocation and every doc that predates this stays correct.
##
## Why this exists: the suite outgrew its CI budget. `verify-unit-tests` was
## raised 10 -> 12 minutes on 2026-08-18 and clipped again at 13m14s the same
## evening, taking a fully green bundle down with it. GitHub reports a
## `timeout-minutes` kill as **cancelled**, not failed, and `ralph-merge`
## refuses a cancelled run forever -- so an overrun of seconds costs a whole
## re-run and reads like something aborted the build. Raising the number again
## just moves that cliff; splitting the work halves the wall-clock instead.
##
## The slice is **round-robin (`index % count`), not contiguous**, on purpose.
## Contiguous halves split an alphabetically-sorted list, and this suite's cost
## is not evenly spread across the alphabet -- the runs that clipped both died
## inside `test_veg_corridor.gd`, the last file by name. Round-robin interleaves
## the expensive tail across every shard instead of stacking it in the last one.

const TESTS_DIR := "res://tests"


func _init() -> void:
	var files := _find_tests(TESTS_DIR)
	files.sort()
	files = _apply_shard(files)

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


## Returns the caller's slice of `files`, or all of them when no `--shard=I/N`
## was passed after a `--` separator. A malformed or out-of-range value is a
## hard error rather than a silent full run: a shard flag that quietly stopped
## sharding would show up as CI passing in half the time, which is exactly the
## symptom you would not investigate.
func _apply_shard(files: Array[String]) -> Array[String]:
	# `quit()` only requests a shutdown; the function still has to return a
	# value of the declared type, and a bare `[]` does not satisfy Array[String].
	var empty: Array[String] = []
	var spec := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shard="):
			spec = argument.substr("--shard=".length())
	if spec == "":
		return files

	var parts := spec.split("/")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		push_error("--shard expects I/N, for example --shard=1/2; got '%s'" % spec)
		quit(2)
		return empty

	var index := int(parts[0])
	var count := int(parts[1])
	if count < 1 or index < 1 or index > count:
		push_error("--shard=%d/%d is out of range" % [index, count])
		quit(2)
		return empty

	var slice: Array[String] = []
	for position in files.size():
		if position % count == index - 1:
			slice.append(files[position])
	print("shard %d/%d: %d of %d test files" % [index, count, slice.size(), files.size()])
	return slice


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
