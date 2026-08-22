extends SceneTree

## PERF-2. Fast isolated read of vegetation.gd's own instrumented boot-phase
## print (see build()'s "[vegetation] boot phases" line) -- no screenshot
## capture, no luma preflight loop, just load the real scene and let it
## finish standing up. Much cheaper than a capture harness for a pure
## timing question.
##
##   godot --headless --path . --script tools/_probe_veg_boot_phases.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 60


func _init() -> void:
	_run()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var packed: PackedScene = load(SCENE)
	if packed == null:
		print("FAIL: could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var t1 := Time.get_ticks_msec()
	print("[probe] total wall time to %d settle frames: %dms" % [SETTLE_FRAMES, t1 - t0])
	quit(0)
