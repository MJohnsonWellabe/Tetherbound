extends "res://tests/smoke_cloudreach_continuous.gd"

## F07#3: which summit camp spots does the continuous harness's ordinary
## `_navigate` reach from BOTH the summit feed (where the route arrives before
## resting) and the arena threshold? Fixture starts; diagnosis only.
##
##   godot --headless --path . --script tests/probe_cloudreach_summit_camp_reach.gd -- --spots=x,z;x,z

const FEED := Vector3(298.0, 1080.0, 5104.0)
const THRESHOLD := Vector3(100.0, 1160.0, 5350.0)
const FLAGS: Array[String] = ["realm_key_cloudreach", "cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete",
	"cloudreach_upper_anchors_disabled", "storm_anchor_summit_feed_disabled"]


func _run() -> void:
	var spots: Array[Vector2] = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--spots="):
			for pair: String in arg.trim_prefix("--spots=").split(";"):
				spots.append(Vector2(float(pair.get_slice(",", 0)), float(pair.get_slice(",", 1))))
	start_usec = Time.get_ticks_usec()
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	accelerated = true
	output_dir = "user://summit_camp_reach"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(30, PROGRESSION.config())
		game.party.add(member)
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	physics_frame.connect(_record_frame)
	await _frames(20)
	var out: Array = []
	for spot: Vector2 in spots:
		var ground := float(world.call("ground_height_near", Vector3(spot.x, 1160.0, spot.y)))
		var target := Vector3(spot.x, ground if is_finite(ground) else 1160.0, spot.y)
		var row := {"spot": [spot.x, spot.y], "ground": ground}
		for start_name: String in ["feed", "threshold"]:
			var start: Vector3 = FEED if start_name == "feed" else THRESHOLD
			var g := float(world.call("ground_height_near", start))
			player.global_position = Vector3(start.x, (g if is_finite(g) else start.y) + 1.2, start.z)
			player.velocity = Vector3.ZERO
			failed = false
			await _frames(20)
			var t0 := simulated_seconds
			var ok := await _navigate(target)
			_release()
			row[start_name] = {"reached": ok and not failed, "seconds": snappedf(simulated_seconds - t0, 0.1),
				"end": str(player.global_position)}
		out.append(row)
	# `--from-camp=x,z` with `--paths=x,z|x,z;...`: ordinary `_walk` from the
	# camp through each path's waypoints to the threshold (the way back).
	var camp := Vector2.INF
	var paths: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from-camp="):
			var c := arg.trim_prefix("--from-camp=")
			camp = Vector2(float(c.get_slice(",", 0)), float(c.get_slice(",", 1)))
		elif arg.begins_with("--paths="):
			for path_text: String in arg.trim_prefix("--paths=").split(";"):
				var wps: Array[Vector2] = []
				for wp: String in path_text.split("|", false):
					wps.append(Vector2(float(wp.get_slice(",", 0)), float(wp.get_slice(",", 1))))
				paths.append(wps)
	for wps: Array in paths:
		var g := float(world.call("ground_height_near", Vector3(camp.x, 1160.0, camp.y)))
		player.global_position = Vector3(camp.x, (g if is_finite(g) else 1160.0) + 1.2, camp.y)
		player.velocity = Vector3.ZERO
		failed = false
		await _frames(20)
		var t0 := simulated_seconds
		var ok := true
		for wp: Vector2 in wps + [Vector2(THRESHOLD.x, THRESHOLD.z)]:
			var wy := float(world.call("ground_height_near", Vector3(wp.x, 1160.0, wp.y)))
			ok = ok and await _walk(Vector3(wp.x, wy if is_finite(wy) else 1160.0, wp.y))
			if not ok:
				break
		_release()
		out.append({"back_via": str(wps), "reached": ok and not failed, "seconds": snappedf(simulated_seconds - t0, 0.1),
			"end": str(player.global_position)})
	print("SUMMIT CAMP REACH " + JSON.stringify(out))
	quit(0)
