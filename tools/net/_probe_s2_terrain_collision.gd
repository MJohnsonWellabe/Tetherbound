extends SceneTree

## Spike S2, question 5: Terrain3D collision alternatives D-MP2 rejected.
##
## Reference only — throwaway instrument for
## docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md Wave 0 lane 0.D.
##
## Two experiments, one boot:
##
##   (1) Does dynamic collision (collision_mode=1, the shipping mode set by
##       `playground_world.gd::_apply_dynamic_collision()`) really follow
##       the render camera, and not a host-simulated body far from it? A
##       second Camera3D is created 2 km up the corridor, handed to
##       `Terrain.set_camera()`, and `PhysicsDirectSpaceState3D.intersect_ray`
##       (the same primitive `build_placer.gd`/`orb.gd` already use in this
##       codebase) probes both the original spawn point and the distant point
##       from +50 m, before and after the camera moves.
##   (2) `collision_mode = 3` (FULL_GAME, real shapes for the whole terrain,
##       built at once) — the alternative `docs/specs/MEADOWS_MACRO_LAYOUT.md`
##       §8.2 already costed at ~16.8 MB of shape data across the corridor's
##       64 regions. This re-measures it live: RSS delta and whether it
##       actually built (read back `collision_mode`, then confirm the once-
##       unreachable-without-a-nearby-camera distant point now hits too).
##
##   godot --headless --path . --script tools/net/_probe_s2_terrain_collision.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const STREAM_WAIT_FRAMES := 180
const COLLISION_DYNAMIC_GAME := 1
const COLLISION_FULL_GAME := 3

## Far up the authored corridor (world_bounds z goes to 15*512=7680; see
## data/config/terrain_playground.json), well outside collision_radius (<=256m
## granted, per playground_world.gd's own comment) from the spawn-area camera.
const DISTANT_POINT := Vector2(0.0, 7000.0)
const SPAWN_AREA_POINT := Vector2(40.0, -62.0)


func _init() -> void:
	await _run()


func _run() -> void:
	print("=== S2 terrain-collision-alternatives probe: %s ===" % Time.get_datetime_string_from_system())

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)

	for i in SETTLE_FRAMES:
		await physics_frame

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain == null:
		push_error("no Terrain node; probe cannot measure anything")
		quit(1)
		return

	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var mode0: int = int(terrain.get("collision_mode"))
	var radius0: int = int(terrain.get("collision_radius"))
	print("baseline collision_mode=%d (want %d Dynamic/Game) collision_radius=%d" % [
		mode0, COLLISION_DYNAMIC_GAME, radius0
	])

	print("")
	print("--- experiment 1: does dynamic collision follow the camera? ---")
	var hit_spawn_before := _raycast_hits(space, SPAWN_AREA_POINT, world)
	var hit_distant_before := _raycast_hits(space, DISTANT_POINT, world)
	print("BEFORE moving camera: spawn-area collision=%s   distant-point collision=%s" % [
		hit_spawn_before, hit_distant_before
	])

	var far_ground: float = float(world.call("ground_height_at", DISTANT_POINT.x, DISTANT_POINT.y))
	var far_camera := Camera3D.new()
	far_camera.name = "S2ProbeFarCamera"
	far_camera.position = Vector3(DISTANT_POINT.x, far_ground + 20.0, DISTANT_POINT.y)
	world.add_child(far_camera)

	if terrain.has_method("set_camera"):
		terrain.call("set_camera", far_camera)
	else:
		push_error("Terrain node has no set_camera method")

	for i in STREAM_WAIT_FRAMES:
		await physics_frame

	var hit_spawn_after := _raycast_hits(space, SPAWN_AREA_POINT, world)
	var hit_distant_after := _raycast_hits(space, DISTANT_POINT, world)
	print("AFTER moving camera 2km+ away: spawn-area collision=%s   distant-point collision=%s" % [
		hit_spawn_after, hit_distant_after
	])
	print("interpretation: dynamic collision follows the camera=%s" % [
		(hit_distant_before == false and hit_distant_after == true)
	])

	print("")
	print("--- experiment 2: collision_mode = FULL_GAME (3) ---")
	var static_before := OS.get_static_memory_usage()
	var vmhwm_before := _read_vm_hwm_kb()
	var t0 := Time.get_ticks_msec()

	terrain.set("collision_mode", COLLISION_FULL_GAME)
	# FULL_GAME collision is built synchronously as part of the property
	# setter on some Terrain3D builds and asynchronously (over several
	# frames) on others -- wait rather than assume, then read back.
	for i in STREAM_WAIT_FRAMES:
		await physics_frame

	var t1 := Time.get_ticks_msec()
	var mode_after: int = int(terrain.get("collision_mode"))
	var built: bool = (mode_after == COLLISION_FULL_GAME)
	print("collision_mode read back as %d (requested %d) -- built=%s" % [
		mode_after, COLLISION_FULL_GAME, built
	])
	print("time to apply + settle: %d ms" % (t1 - t0))

	var static_after := OS.get_static_memory_usage()
	var vmhwm_after := _read_vm_hwm_kb()
	print("static_mem delta: %+.1f MB (before %.1f, after %.1f)" % [
		(static_after - static_before) / 1048576.0, static_before / 1048576.0, static_after / 1048576.0
	])
	print("VmHWM: before %.1f MB, after %.1f MB" % [vmhwm_before / 1024.0, vmhwm_after / 1024.0])

	# Re-point the camera back near spawn so this checks "FULL_GAME covers
	# the whole map regardless of camera position", the actual claim under
	# test -- not just "the point the dynamic camera already happened to be
	# near a moment ago".
	var near_camera: Node = world.get_node_or_null(^"CameraRig/Camera3D")
	if near_camera != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", near_camera)
		for i in 30:
			await physics_frame
	var hit_distant_full := _raycast_hits(space, DISTANT_POINT, world)
	print("distant point collision under FULL_GAME with camera back near spawn=%s" % hit_distant_full)

	print("")
	print("=== summary ===")
	print("dynamic collision follows camera (not fixed to spawn): %s" % [
		(hit_distant_before == false and hit_distant_after == true)
	])
	print("FULL_GAME built and covers a point far from the camera: %s (mem +%.1f MB, %d ms)" % [
		(built and hit_distant_full), (static_after - static_before) / 1048576.0, t1 - t0
	])

	quit(0)


## Raycasts straight down through (x, ?, z) from ground_height_at()+50m to
## ground_height_at()-5m, using the analytic heightfield only to PLACE the
## ray (never to answer the question) -- the question is whether PHYSICS
## collision exists there, which is exactly what intersect_ray tests.
func _raycast_hits(space: PhysicsDirectSpaceState3D, xz: Vector2, world: Node) -> bool:
	var ground: float = float(world.call("ground_height_at", xz.x, xz.y))
	if is_nan(ground):
		push_warning("ground_height_at(%.1f, %.1f) is NaN; outside the authored corridor" % [xz.x, xz.y])
		ground = 0.0
	var from := Vector3(xz.x, ground + 50.0, xz.y)
	var to := Vector3(xz.x, ground - 5.0, xz.y)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit: Dictionary = space.intersect_ray(query)
	return not hit.is_empty()


func _read_vm_hwm_kb() -> int:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return -1
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("VmHWM:"):
			var digits := line.replace("VmHWM:", "").replace("kB", "").strip_edges()
			return int(digits)
	return -1
