extends SceneTree

## OP-0905-22: "when you fall off the world you just fall forever" (Cloudreach
## Cliffs). Real-scene smoke for `scripts/world/fall_recovery.gd`, mounted by
## `cloudreach_world_runtime.gd::_mount_fall_recovery`. Modeled on
## `smoke_cloudreach_foundation.gd` for how the world is built headless.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("Game")
	game.current_realm = "cloudreach"
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 8:
		await physics_frame
	var failures: Array[String] = []

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var runtime := world.get_node_or_null(^"CloudreachRuntime")
	_expect(player != null, "production Player is absent", failures)
	_expect(runtime != null, "CloudreachRuntime did not mount", failures)
	if player == null or runtime == null:
		return _fail(failures)
	var fall_recovery: Node3D = runtime.get("fall_recovery") as Node3D
	_expect(fall_recovery != null and is_instance_valid(fall_recovery),
		"cloudreach_world_runtime did not mount a FallRecovery node", failures)
	if fall_recovery == null:
		return _fail(failures)
	var kill_volume := fall_recovery.get_node_or_null(^"FallRecoveryKillVolume")
	_expect(kill_volume != null, "FallRecovery did not build its kill volume", failures)

	var config: Dictionary = world.call("config_data")
	var bounds: Dictionary = config.get("realm", {}).get("world_bounds", {})
	var min_x := float(bounds.get("min_x", -1600.0))
	var max_x := float(bounds.get("max_x", 1600.0))
	var min_z := float(bounds.get("min_z", -500.0))
	var max_z := float(bounds.get("max_z", 6000.0))

	# --- Undisturbed control: a body standing on real ground is left alone. ---
	var standing_at := player.global_position
	for _frame in 20:
		await physics_frame
	_expect(player.global_position.distance_to(standing_at) < 1.0,
		"a grounded player was disturbed with no fall (moved %.2fm)" % player.global_position.distance_to(standing_at),
		failures)
	_expect(player.is_on_floor(), "grounded control player is not on_floor before the drop test", failures)

	# Let a fresh last-safe-ground reading land before falling.
	for _frame in 10:
		await physics_frame
	var route_stand := player.global_position

	# --- The actual repro: fall far below the world. ---
	var deep_y: float = float(bounds.get("min_y", -200.0)) - 5000.0
	player.global_position = Vector3(route_stand.x, deep_y, route_stand.z)
	player.velocity = Vector3(0, -50.0, 0)
	var recovered := false
	for _frame in 240:
		await physics_frame
		if player.global_position.y > deep_y + 1000.0:
			recovered = true
			break
	_expect(recovered, "player fell forever and was never recovered", failures)
	if recovered:
		var at := player.global_position
		_expect(at.is_finite(), "recovered position is not finite", failures)
		_expect(at.y > float(bounds.get("min_y", -200.0)), "recovered position is still below the world floor", failures)
		_expect(at.x >= min_x - 1.0 and at.x <= max_x + 1.0 and at.z >= min_z - 1.0 and at.z <= max_z + 1.0,
			"recovered position (%.1f, %.1f) is outside the realm's authored XZ bounds" % [at.x, at.z], failures)
		var ground := float(world.call("ground_height_at", at.x, at.z))
		_expect(is_nan(ground) or at.y >= ground - 2.5,
			"recovered position (%.2f) is below the real ground (%.2f) at (%.1f, %.1f)" % [at.y, ground, at.x, at.z],
			failures)
		# A fresh last-safe reading should recover close to the route stand, not
		# to some distant camp -- proves the local-correction branch, not just
		# the ladder-of-last-resort branch.
		_expect(at.distance_to(route_stand) < 25.0,
			"a fresh fall was not recovered locally (route stand %.1f,%.1f,%.1f -> %.1f,%.1f,%.1f)" % [
				route_stand.x, route_stand.y, route_stand.z, at.x, at.y, at.z],
			failures)
		for _settle in 10:
			await physics_frame
		_expect(player.is_on_floor(), "player did not settle back onto real floor after recovery", failures)

	if failures.is_empty():
		print("CLOUDREACH FALL RECOVERY OK route_stand=%s recovered=%s" % [str(route_stand), str(player.global_position)])
		quit(0)
		return
	_fail(failures)


func _fail(failures: Array[String]) -> void:
	for failure: String in failures:
		push_error("CLOUDREACH FALL RECOVERY: %s" % failure)
	quit(1)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
