extends SceneTree

## GATE-D4 ad-hoc runner: only the files this package's report names, so a
## quick local check does not have to pay for the whole suite under sibling
## CPU contention. Same instantiate/call-every-test_ pattern as
## tests/run_tests.gd, just without discovery or sharding.
##
##   godot --headless --path . --script tools/_run_d4_tests.gd

const FILES := [
	"res://tests/test_band_content.gd",
	"res://tests/test_band_vegetation.gd",
	"res://tests/test_spawns_data.gd",
	"res://tests/test_trainers_data.gd",
	"res://tests/test_chapter_curve.gd",
	"res://tests/test_chapter_content_map.gd",
	"res://tests/test_harvest.gd",
]


func _test_methods(script: GDScript) -> Array[String]:
	var out: Array[String] = []
	for method: Dictionary in script.get_script_method_list():
		var name: String = method.get("name", "")
		if name.begins_with("test_"):
			out.append(name)
	return out


func _init() -> void:
	var total := 0
	var failed := 0
	var failure_lines: Array[String] = []
	for path: String in FILES:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			print("  FAIL  %s :: could not be parsed or instantiated" % path.get_file())
			failed += 1
			total += 1
			continue
		var instance: Object = script.new()
		var file_name := path.get_file()
		for method: String in _test_methods(script):
			total += 1
			instance.failures.clear()
			instance.before_each()
			instance.callv(method, [])
			instance.after_each()
			if instance.failures.is_empty():
				print("  ok    %s :: %s" % [file_name, method])
			else:
				failed += 1
				print("  FAIL  %s :: %s" % [file_name, method])
				for message: String in instance.failures:
					print("          %s" % message)
					failure_lines.append("%s :: %s — %s" % [file_name, method, message])
	print("")
	print("%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
