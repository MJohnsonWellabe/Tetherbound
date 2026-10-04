extends SceneTree

## Budget.begin needs a real in-tree world. Run after SceneTree initialization,
## rather than inside the pure unit runner's _init, before a main loop exists.
var checks := preload("res://tests/test_case.gd").new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	test_real_begin_preserves_legacy_default_and_requires_strict_opt_in()
	test_existing_shell_and_live_session_paths_keep_their_slicing_policy()
	for failure: String in checks.failures:
		printerr("FAIL: ", failure)
	print("startup CPU gate: 2 cases, %d assertions, %d failures" % [checks.assertion_count, checks.failures.size()])
	quit(0 if checks.failures.is_empty() else 1)

const PERF := preload("res://scripts/world/performance_config.gd")

class Budget extends "res://scripts/world/shell_build_budget.gd":
	var live_session := false
	func _in_live_session(_world: Node) -> bool:
		return live_session

func test_real_begin_preserves_legacy_default_and_requires_strict_opt_in() -> void:
	var cfg := PERF.config()
	checks.assert_eq(cfg.get("responsive_startup_cpu_slicing"), false)
	var world := Node.new()
	root.add_child(world)
	for value: Variant in [false, null, 0, 1, "true", [], {}]:
		cfg["responsive_startup_cpu_slicing"] = value
		var budget := Budget.new()
		budget.begin(world, false)
		checks.assert_false(budget.is_slicing(), "unfinished startup must not activate: %s" % str(value))
		checks.assert_false(budget.uses_multiplayer_staging())
		checks.assert_false(budget.needs_render_release())
	cfg.erase("responsive_startup_cpu_slicing")
	var absent := Budget.new()
	absent.begin(world, false)
	checks.assert_false(absent.is_slicing())
	cfg["responsive_startup_cpu_slicing"] = true
	var opted_in := Budget.new()
	opted_in.begin(world, false)
	checks.assert_true(opted_in.is_slicing())
	checks.assert_false(opted_in.uses_multiplayer_staging(), "opt-in cannot grant network placeholder policy")
	checks.assert_false(opted_in.needs_render_release())
	cfg["responsive_startup_cpu_slicing"] = false
	world.free()

func test_existing_shell_and_live_session_paths_keep_their_slicing_policy() -> void:
	var cfg := PERF.config()
	checks.assert_eq(cfg.get("responsive_startup_cpu_slicing"), false)
	var world := Node.new()
	root.add_child(world)
	var shell := Budget.new()
	shell.begin(world, true)
	checks.assert_true(shell.is_slicing())
	checks.assert_true(shell.uses_multiplayer_staging())
	checks.assert_false(shell.needs_render_release())
	checks.assert_eq(int(shell.get("_budget_ms")), int(cfg.get("shell_build_budget_ms")))
	var live := Budget.new()
	live.live_session = true
	live.begin(world, false)
	checks.assert_true(live.is_slicing())
	checks.assert_true(live.uses_multiplayer_staging())
	checks.assert_false(live.needs_render_release())
	checks.assert_eq(int(live.get("_budget_ms")), int(cfg.get("crossing_build_budget_ms")))
	world.free()
