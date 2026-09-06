extends SceneTree

## Lane MP-REALM-REOPEN. THE REPRODUCTION THAT CORRECTED D97.
##
## D97's "The measurement the hold was waiting for" section reports
## `add_child_ms=0` for a realm shell and concludes that the world root's
## `_ready()` already runs as a coroutine, so the build already spreads across
## frames and the fix is not to make it asynchronous.
##
## That reading is an artifact of WHERE the measurement was taken.
## `tools/net/_probe_6a_shell.gd` calls `root.add_child()` from
## `SceneTree._init()`, before the root window has entered the tree -- and
## Godot does not propagate `_ready()` into a node whose parent is not inside
## the tree yet. The build was simply deferred to the first frame, which is
## why the same probe reads a 21.9 s SINGLE FRAME straight afterwards.
##
## `realm_shells.gd` calls `add_child()` from a live tree. This probe does the
## same, and measures:
##
##   tree is live; root.is_inside_tree()=true
##   LIVE add_child_ms=21037
##
## Twenty-one seconds inside one call, on the host every other player depends
## on. D97's FIRST diagnosis was right about the mechanism after all, and the
## fix really is to build the shell across frames --
## `scripts/world/shell_build_budget.gd`.
##
##   ~/godot-bin/godot --headless --path . --script tools/net/_probe_addchild_live.gd
##
## Run it against a tree with the slicing removed to see the 21 s again; with
## the slicing in place `add_child` returns in tens of milliseconds and the
## build shows up as frames afterwards, which is the whole point.

func _init() -> void:
	await _run()


func _run() -> void:
	await process_frame
	await process_frame
	print("tree is live; root.is_inside_tree()=%s" % root.is_inside_tree())
	var packed: PackedScene = load("res://scenes/world/cloudreach_cliffs.tscn")
	var world: Node = packed.instantiate()
	world.set("simulation_only", true)
	world.set("shell_realm", "cloudreach")
	var t := Time.get_ticks_msec()
	root.add_child(world)
	print("LIVE add_child_ms=%d" % (Time.get_ticks_msec() - t))
	for i in 40:
		var f := Time.get_ticks_usec()
		await physics_frame
		var ms := (Time.get_ticks_usec() - f) / 1000.0
		if ms > 200.0:
			print("  frame %d: %.0f ms" % [i, ms])
	quit(0)
