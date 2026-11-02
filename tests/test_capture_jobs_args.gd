extends "res://tests/test_case.gd"

## Capture-speed lane: `--jobs=<json>` / `--job=` turn N single launches of the
## phase2 capture tools into one boot. Each job must parse to exactly the
## output and args its single launch would have had.

const LOCATIONS := preload("res://tools/phase2_capture_locations.gd")


func _files(map: Dictionary) -> Callable:
	return func(path: String) -> String: return str(map.get(path, ""))


func test_no_job_args_means_single_launch() -> void:
	var jobs := LOCATIONS.parse_jobs(PackedStringArray(["--biome=meadows", "--subset=mira", "--output=res://out/a"]))
	assert_eq(jobs.size(), 0, "plain launch is not a batch")


func test_inline_jobs_keep_output_and_args() -> void:
	var jobs := LOCATIONS.parse_jobs(PackedStringArray([
		"--biome=cloudreach", "--seed=2042",
		"--job=res://out/iven|--subset=cloudreach__inventory__character__iven",
		"--job=res://out/voss|--subset=voss|--gamepad"]))
	assert_eq(jobs.size(), 2, "two inline jobs")
	assert_eq(str(jobs[0].output), "res://out/iven", "first output")
	assert_eq(Array(jobs[0].args), ["--subset=cloudreach__inventory__character__iven"], "first args")
	assert_eq(str(jobs[1].output), "res://out/voss", "second output")
	assert_eq(Array(jobs[1].args), ["--subset=voss", "--gamepad"], "flags ride with their job")


func test_json_jobs_accept_object_or_array_and_output_arg() -> void:
	var files := {
		"res://a.json": JSON.stringify({"jobs": [
			{"output": "res://out/one", "args": ["--subset=one"]},
			{"args": ["--subset=two", "--output=res://out/two"]}]}),
		"res://b.json": JSON.stringify([{"output": "res://out/three", "args": []}]),
	}
	var jobs := LOCATIONS.parse_jobs(PackedStringArray(["--jobs=res://a.json"]), _files(files))
	assert_eq(jobs.size(), 2, "object form")
	assert_eq(str(jobs[1].output), "res://out/two", "--output inside args becomes the job output")
	assert_eq(Array(jobs[1].args), ["--subset=two"], "--output is removed from the job args")
	jobs = LOCATIONS.parse_jobs(PackedStringArray(["--jobs=res://b.json"]), _files(files))
	assert_eq(jobs.size(), 1, "bare array form")
	assert_eq(Array(jobs[0].args), [], "a job may add no args")


func test_jobs_file_and_inline_jobs_combine_in_order() -> void:
	var files := {"res://a.json": JSON.stringify([{"output": "res://out/one", "args": ["--subset=one"]}])}
	var jobs := LOCATIONS.parse_jobs(PackedStringArray([
		"--jobs=res://a.json", "--job=res://out/two|--subset=two"]), _files(files))
	assert_eq(jobs.map(func(job: Dictionary) -> String: return str(job.output)),
		["res://out/one", "res://out/two"], "file jobs then inline jobs")


func _assert_refused(args: Array, files: Dictionary, why: String) -> void:
	var jobs := LOCATIONS.parse_jobs(PackedStringArray(args), _files(files))
	assert_eq(jobs.size(), 1, why + " (single error entry)")
	assert_true(jobs.size() == 1 and jobs[0].has("error"), why)


func test_malformed_jobs_are_refused() -> void:
	_assert_refused(["--job=res://out/a|--subset=a", "--job=res://out/a|--subset=b"], {},
		"two jobs may not share an output")
	_assert_refused(["--job=|--subset=a"], {}, "a job needs an output")
	_assert_refused(["--job=res://out/a|--biome=water"], {}, "a job may not change the biome")
	_assert_refused(["--job=res://out/a|--preset=High"], {}, "a job may not change the preset")
	_assert_refused(["--job=res://out/a|--seed=7"], {}, "a job may not change the seed")
	_assert_refused(["--job=res://out/a|--character=kael"], {}, "a job may not change the character")
	_assert_refused(["--job=res://out/a|--output=res://out/b"], {}, "a job gives one output")
	_assert_refused(["--jobs=res://missing.json"], {}, "missing jobs file")
	_assert_refused(["--jobs=res://empty.json"], {"res://empty.json": "[]"}, "empty jobs file")
	_assert_refused(["--jobs=res://bad.json"], {"res://bad.json": "[\"--subset=a\"]"},
		"jobs must be objects")
	_assert_refused(["--jobs=res://bad.json"], {"res://bad.json": "[{\"output\": \"res://o\", \"args\": \"--subset=a\"}]"},
		"job args must be a list")
