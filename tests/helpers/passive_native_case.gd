extends SceneTree

## Only these passive-clock tests need a real initialized SceneTree. The pure
## unit runner runs in _init, so execute each case in a deferred native child.
const RESULT_PREFIX := "PASSIVE_NATIVE_RESULT="

static func run_case(parent: RefCounted, suite: String, method: String, minimum_assertions: int) -> void:
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script",
		ProjectSettings.globalize_path("res://tests/helpers/passive_native_case.gd"),
		"--log-file", ProjectSettings.globalize_path("user://passive-native-" + method + ".log"),
		"--", suite, method], output, true)
	var combined := "\n".join(output)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with(RESULT_PREFIX):
			var parsed: Variant = JSON.parse_string(line.trim_prefix(RESULT_PREFIX))
			if parsed is Dictionary: result = parsed
	parent.assert_eq(result.get("case", ""), method, combined)
	parent.assert_true(result.get("completed") == true, combined)
	parent.assert_eq(result.get("failures", ["missing result"]), [], combined)
	parent.assert_true(int(result.get("assertions", 0)) >= minimum_assertions, combined)
	parent.assert_false(combined.contains("ERROR:") or combined.contains("ObjectDB instances")
		or combined.contains("resources still in use"), combined)
	parent.assert_eq(code, 0, combined)
	print(RESULT_PREFIX + JSON.stringify(result))

func _initialize() -> void:
	call_deferred("_run_native")

func _run_native() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] not in ["res://tests/test_canonical_guest_passive_fence.gd",
		"res://tests/test_passive_clock_lifecycle.gd", "res://tests/test_owner_passive_game_hooks.gd"] or not args[1].begins_with("_native_case_"):
		push_error("Unsupported passive native case")
		quit(2)
		return
	var test: RefCounted = load(args[0]).new()
	if test.has_method("_native_setup"): test.call("_native_setup")
	if not test.has_method("_native_setup") or test.get("_native_ready") == true:
		test.call(args[1])
	if test.has_method("_native_cleanup"): test.call("_native_cleanup")
	# Completion is set at the end of the actual case. An aborted method cannot
	# become a nominal pass just because control returned to this harness.
	var result := {"case": args[1], "assertions": test.get("assertion_count"),
		"failures": test.get("failures"), "completed": test.get("_native_completed")}
	print(RESULT_PREFIX + JSON.stringify(result))
	quit(0 if result.failures.is_empty() and result.completed == true else 1)
