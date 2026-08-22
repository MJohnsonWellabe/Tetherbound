extends SceneTree

## Run a single `tests/test_*.gd` file, for a lane iterating on one test.
##
##   godot --headless --path . --script tools/run_one_test.gd -- res://tests/test_x.gd
##
## `tests/run_tests.gd` is the real runner and CI's; this exists because the
## full suite takes many minutes and a lane fixing one file should not have to
## sit through the other hundred to find out whether it worked. Same discovery
## and reporting shape, one file's worth.


func _init() -> void:
	var path := ""
	for arg in OS.get_cmdline_user_args():
		path = str(arg)
	if path.is_empty():
		print("usage: --script tools/run_one_test.gd -- res://tests/test_x.gd")
		quit(2)
		return

	var script: GDScript = load(path)
	if script == null or not script.can_instantiate():
		print("  FAIL  %s :: could not be parsed" % path)
		quit(1)
		return

	var instance: Object = script.new()
	var failed := 0
	var total := 0
	for method in instance.get_method_list():
		var name := str(method.get("name", ""))
		if not name.begins_with("test_"):
			continue
		total += 1
		instance.set("failures", [] as Array[String])
		instance.call("before_each")
		instance.call(name)
		instance.call("after_each")
		var failures: Array = instance.get("failures")
		if failures.is_empty():
			print("  ok    %s" % name)
			continue
		failed += 1
		print("  FAIL  %s" % name)
		for line: String in failures:
			print("          %s" % line)

	print("\n%d test(s), %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
