extends SceneTree

## GATE-D4: fast confirmation of just the two files whose assertions this
## package's fixes touched (test_band_vegetation.gd's stale exact-count check,
## test_spawns_data.gd's evolved-form-in-the-wild check), plus the curve/roster
## tests that read the expanded spawn table. Skips test_harvest.gd on purpose --
## it is proven green by the full-suite run already on record and its own
## gltf-loading tests are slow for reasons unrelated to this package.
##
##   godot --headless --path . --script tools/_run_d4_tests_fast.gd

const FILES := [
	"res://tests/test_band_content.gd",
	"res://tests/test_band_vegetation.gd",
	"res://tests/test_spawns_data.gd",
	"res://tests/test_trainers_data.gd",
	"res://tests/test_chapter_curve.gd",
	"res://tests/test_chapter_content_map.gd",
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
	for path: String in FILES:
		var script: GDScript = load(path)
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
	print("")
	print("%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
