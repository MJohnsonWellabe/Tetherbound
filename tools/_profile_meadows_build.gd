extends SceneTree
## Realm-load profiling: builds the Meadows world once, as a joining guest's
## realm swap does (headless, like the two-peer proofs), and quits. Timings
## land in user://boot_log.txt via BOOT_LOG.phase.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var started := Time.get_ticks_msec()
	var world := (load("res://scenes/world/meadows_playground.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	while not (world.has_method("shell_build_complete") and bool(world.call("shell_build_complete"))):
		await process_frame
		if Time.get_ticks_msec() - started > 600000: break
	print("MEADOWS_BUILD_MS %d" % (Time.get_ticks_msec() - started))
	quit(0)
