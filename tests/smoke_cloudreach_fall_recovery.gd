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

	# --- F06#2: a fall with NO fresh standing reading (a glide that sank past
	# the cloud sea; a long drop) returns to the last verified landing, not to
	# a distant camp. Hold the trainer airborne past LAST_SAFE_MAX_AGE_S above
	# where it last stood, then drop it through the kill plane.
	# Stand somewhere well away from the realm entry first (the ladder's own
	# answer here), so the last landing and a camp/entry recovery differ.
	for offset: Vector2 in [Vector2(0, 120), Vector2(-60, 160), Vector2(60, 200), Vector2(-90, 90), Vector2(0, 240)]:
		var gy := float(world.call("ground_height_at", route_stand.x + offset.x, route_stand.z + offset.y))
		if is_nan(gy):
			continue
		player.global_position = Vector3(route_stand.x + offset.x, gy + 1.0, route_stand.z + offset.y)
		player.velocity = Vector3.ZERO
		for _frame in 30:
			await physics_frame
		if player.is_on_floor() and player.global_position.distance_to(route_stand) > 40.0:
			break
	_expect(player.is_on_floor() and player.global_position.distance_to(route_stand) > 40.0,
		"no standing ground 40 m from the realm entry for the stale-fall check", failures)
	var landing := player.global_position
	var fly: Node = player.get_node_or_null(^"FlyController")
	_expect(fly != null and (fly.get("safe_anchor") as Vector3).distance_to(landing) < 2.0,
		"Fly did not hold the trainer's last landing as its anchor", failures)
	# A real glide (Maela's loaner after the unlock: the party here has no
	# carrier), held aloft past the freshness window, then sinking through the
	# cloud sea with stamina left -- Fly's own exhausted recovery never fires.
	game.progression.set_flag("fly_traversal_unlocked")
	player.global_position = landing + Vector3.UP * 300.0
	player.velocity = Vector3.ZERO
	await physics_frame
	if fly != null:
		fly.call("_launch")
	_expect(fly != null and bool(fly.call("is_flying")), "the trainer could not launch a glide for the stale-fall check", failures)
	var held_frames := int(ceil((fall_recovery.LAST_SAFE_MAX_AGE_S + 1.0) * Engine.physics_ticks_per_second))
	for _frame in held_frames:
		player.global_position = landing + Vector3.UP * 300.0
		player.velocity = Vector3.ZERO
		await physics_frame
	_expect(fly != null and str(fly.get("state")) == "glide", "the glide did not hold (state %s)" % str(fly.get("state") if fly != null else ""), failures)
	# Just above the kill volume: the glide sinks into it on its own.
	var plane_y := float(fall_recovery.get("_kill_plane_y"))
	player.global_position = Vector3(landing.x, plane_y + fall_recovery.KILL_PLANE_THICKNESS * 0.5 + 4.0, landing.z)
	var returned := false
	for _frame in 600:
		await physics_frame
		if player.global_position.y > plane_y + 200.0:
			returned = true
			break
	_expect(returned, "a stale fall was never recovered", failures)
	if returned:
		_expect(player.global_position.distance_to(landing) < 3.0,
			"a stale fall went to %s, not the last verified landing %s" % [str(player.global_position), str(landing)], failures)
		_expect(fly == null or not bool(fly.call("is_flying")), "recovery left the trainer flying", failures)
		_expect(player.velocity.length() < 0.5, "recovery kept the fall's velocity", failures)
		for _settle in 10:
			await physics_frame
		_expect(player.is_on_floor(), "player did not settle on its last landing", failures)

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
