extends SceneTree

## Headless test runner.
##
##   godot --headless --path . --script tests/run_tests.gd
##   godot --headless --path . --script tests/run_tests.gd -- --shard=1/2
##   godot --headless --path . --script tests/run_tests.gd -- --only=veg_corridor
##   godot --headless --path . --script tests/run_tests.gd -- --only=test_veg_corridor.gd::test_specific_case
##
## Discovers every `test_*.gd` under res://tests/, instantiates it, and runs
## every method whose name starts with `test_`. Exits non-zero on any failure so
## CI fails the push rather than the owner finding it by playing.
##
## ## Filtering a run to specific tests
##
## `--only=` takes a comma-separated list of selectors. Each selector is a
## substring match against a test file's name, optionally followed by
## `::<method-substring>` to also narrow which `test_*` methods in that file
## run. `--only=veg_corridor` runs every method in every file whose name
## contains "veg_corridor"; `--only=test_veg_corridor.gd::test_specific_case`
## additionally narrows to methods containing "test_specific_case". A selector
## that matches no file is a hard error, same reasoning as `--shard` below: a
## typo'd `--only` that quietly ran the whole suite would read as "everything
## passed" when nothing you asked for actually ran.
##
## `--only` and `--shard` compose: `--only` narrows the file list first, then
## `--shard` slices what's left. Passing neither runs every file exactly as
## before this flag existed.
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

## Parsed `--only=` selectors, each `{"file": String, "method": String}` with
## `method` empty meaning "every method in this file". Empty array means no
## `--only` was passed, so every downstream filter is a no-op.
var _only_selectors: Array = []

## Set by `_apply_only`/`_apply_shard` right before `quit(2)` on a malformed or
## empty-matching flag. `quit()` only *requests* a shutdown -- `_init` keeps
## running afterward -- so without this, the unconditional `quit(1 if failed >
## 0 else 0)` at the end of `_init` overwrites exit code 2 with 0 on every
## invalid-flag run and the "hard error" documented above silently isn't one.
var _aborted := false


func _init() -> void:
	var files := _find_tests(TESTS_DIR)
	files.sort()
	files = _apply_only(files)
	if _aborted:
		return
	files = _apply_skip(files)
	if _aborted:
		return
	files = _apply_shard(files)
	if _aborted:
		return

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

		for method in _filter_methods(file_name, _test_methods(script)):
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


## Returns `files` narrowed to those matching a `--only=` selector, or every
## file unchanged when no `--only` was passed after a `--` separator. A
## selector that matches nothing is a hard error, same reasoning as
## `--shard`'s range check: silently running the whole suite on a typo would
## look identical to a passing filtered run.
func _apply_only(files: Array[String]) -> Array[String]:
	var empty: Array[String] = []
	var spec := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			spec = argument.substr("--only=".length())
	if spec == "":
		return files

	for raw_selector in spec.split(","):
		var pieces := raw_selector.split("::")
		var file_part: String = pieces[0]
		var method_part: String = pieces[1] if pieces.size() > 1 else ""
		if file_part == "":
			push_error("--only selector '%s' has no file part" % raw_selector)
			_aborted = true
			quit(2)
			return empty
		_only_selectors.append({"file": file_part, "method": method_part})

	var matched: Array[String] = []
	for path in files:
		var file_name := path.get_file()
		for selector in _only_selectors:
			if file_name.contains(selector["file"]):
				matched.append(path)
				break

	if matched.is_empty():
		push_error("--only=%s matched no test files" % spec)
		_aborted = true
		quit(2)
		return empty

	print("only %s: %d of %d test files" % [spec, matched.size(), files.size()])
	return matched


## Returns `files` with any file matching a `--skip=` selector removed, or
## every file unchanged when no `--skip` was passed. Comma-separated, matched
## as a substring of the file name, the same way `--only=` matches.
##
## WHY THIS EXISTS. `test_veg_corridor.gd` costs ~10 minutes by itself against
## `verify-unit-tests`' 12-minute ceiling -- measured 10m11s on
## ralph/WORLD-GRASS, 6 tests, 1,341,749 assertions, 0 failed. Its two
## whole-config `RULES.all_placements()` calls are real regression checks and
## were deliberately left unshrunk when the other layer-reading tests were
## fixed; see that file's own comments. Once one FILE exceeds the ceiling, more
## shards cannot help -- sharding distributes files and cannot split one -- so
## ci.yml runs it in its own job and skips it here. That is this workflow's own
## stated remedy ("splitting run_tests.gd into two jobs, not raising this
## further"), applied to the file that actually costs the time.
##
## A selector matching nothing is a hard error, and so is skipping every file:
## both would otherwise look identical to a healthy run, which is the same
## reasoning `--only=` and `--shard=` already use.
func _apply_skip(files: Array[String]) -> Array[String]:
	var empty: Array[String] = []
	var spec := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--skip="):
			spec = argument.substr("--skip=".length())
	if spec == "":
		return files

	var selectors: Array[String] = []
	for raw_selector in spec.split(","):
		var selector := raw_selector.strip_edges()
		if selector == "":
			push_error("--skip selector in '%s' is empty" % spec)
			_aborted = true
			quit(2)
			return empty
		selectors.append(selector)

	var kept: Array[String] = []
	var skipped := 0
	for path in files:
		var file_name := path.get_file()
		var drop := false
		for selector in selectors:
			if file_name.contains(selector):
				drop = true
				break
		if drop:
			skipped += 1
		else:
			kept.append(path)

	if skipped == 0:
		push_error("--skip=%s matched no test files" % spec)
		_aborted = true
		quit(2)
		return empty
	if kept.is_empty():
		push_error("--skip=%s skipped every test file" % spec)
		_aborted = true
		quit(2)
		return empty

	print("skip %s: %d of %d test files removed" % [spec, skipped, files.size()])
	return kept


## Returns `methods` narrowed to whichever `--only=` selectors matched
## `file_name`, if any of them also carry a `::method` part. A file only
## reaches this once `_apply_only` has already matched it against at least
## one selector, so an empty `applicable` here is unreachable in practice; the
## fallback still returns `methods` unfiltered rather than nothing, matching
## how a file-only selector (no `::method`) behaves.
func _filter_methods(file_name: String, methods: Array[String]) -> Array[String]:
	if _only_selectors.is_empty():
		return methods

	var applicable: Array = []
	for selector in _only_selectors:
		if file_name.contains(selector["file"]):
			applicable.append(selector)
	if applicable.is_empty():
		return methods

	for selector in applicable:
		if selector["method"] == "":
			return methods

	var out: Array[String] = []
	for method in methods:
		for selector in applicable:
			if method.contains(selector["method"]):
				out.append(method)
				break
	return out


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
		_aborted = true
		quit(2)
		return empty

	var index := int(parts[0])
	var count := int(parts[1])
	if count < 1 or index < 1 or index > count:
		push_error("--shard=%d/%d is out of range" % [index, count])
		_aborted = true
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
