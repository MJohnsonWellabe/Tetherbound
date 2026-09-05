extends SceneTree

func _init() -> void:
	print("before")
	_inner()
	print("after")
	quit(0)


func _inner() -> void:
	print("inner start")
	var d := {"a": {"x": 1}, "b": "oops", "c": {"y": 2}}
	for v: Dictionary in d.values():
		print("loop iter: %s" % v)
	print("inner end")
