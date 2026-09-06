extends SceneTree

## Lane MP-REALM-REOPEN. WHAT THE CROSSING PEER ITSELF PAYS.
##
## The host's realm shell is only half of a realm transition. The other half is
## the player who actually walks through the gate: their process frees a whole
## world and builds another, and while it does, neither ENet nor the net
## harness hears from them. `smoke_net_split_realms` failed on exactly that --
## on the CLIENT, peer 1 -- once the host-side shell freeze was fixed, and the
## failure was in LEAVING the Meadows rather than in building Cloudreach.
##
##   ~/godot-bin/godot --headless --path . --script tools/net/_probe_realm_crossing.gd
##
## `--free-per-child` frees the outgoing world's children one at a time instead
## of freeing its root. That is not a fix, it is the DIAGNOSTIC that found one:
## the arbiter is an early child, so freeing forward frees it first and the
## 24,461 interactables behind it skip `unregister()` entirely. Root free
## 43.0 s, per-child free 1.8 s, same world -- which is what named
## `interaction_arbiter.gd::unregister()`'s O(n) `Array.erase()` as the cost.

const FROM := "res://scenes/world/meadows_playground.tscn"
const TO := "res://scenes/world/cloudreach_cliffs.tscn"
const HEARTBEAT_FRAMES := 60


func _init() -> void:
	await _run()


func _run() -> void:
	var per_child := false
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--free-per-child":
			per_child = true
	await process_frame
	var world: Node = (load(FROM) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	print("--- outgoing world standing; settling ---")
	for i in 240:
		await physics_frame

	print("--- freeing it and building the destination (per_child=%s) ---" % per_child)
	var t_free := Time.get_ticks_msec()
	if per_child:
		for child: Node in world.get_children():
			child.free()
	world.free()
	var free_ms := Time.get_ticks_msec() - t_free
	print("FREE of the outgoing world: %d ms (one synchronous call)" % free_ms)

	var t_build := Time.get_ticks_msec()
	var incoming: Node = (load(TO) as PackedScene).instantiate()
	var t_add := Time.get_ticks_msec()
	root.add_child(incoming)
	current_scene = incoming
	var add_ms := Time.get_ticks_msec() - t_add
	var frames: Array[float] = []
	for i in 400:
		var t := Time.get_ticks_usec()
		await physics_frame
		frames.append((Time.get_ticks_usec() - t) / 1000.0)
	print("load+instantiate of the destination: %d ms; add_child: %d ms; total build %.1f s"
		% [t_add - t_build, add_ms, (Time.get_ticks_msec() - t_build) / 1000.0])

	var worst := float(free_ms)
	for f: float in frames:
		worst = maxf(worst, f)
	var window := 0.0
	var worst_window := float(free_ms + add_ms)
	for i in frames.size():
		window += frames[i]
		if i >= HEARTBEAT_FRAMES:
			window -= frames[i - HEARTBEAT_FRAMES]
		if i >= HEARTBEAT_FRAMES - 1:
			worst_window = maxf(worst_window, window)
	print("CROSSING worst single frame %.0f ms (the free counted as one), worst 60-frame window %.1f s"
		% [worst, worst_window / 1000.0])
	quit(0)
