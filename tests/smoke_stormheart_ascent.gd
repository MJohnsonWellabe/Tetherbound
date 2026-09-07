extends SceneTree

## Physics-only Stormheart ascent evidence. This stands the production tree
## without Stormwood terrain, walks a CharacterBody3D over its real trimesh,
## and repeats the checks with the host-shell geometry flag enabled.

const STORMHEART := preload("res://scripts/world/stormheart_tree.gd")
const GRAVITY := 24.0
const WALK_SPEED := 7.5
const MAX_WALK_FRAMES := 6000
const CORE_TOLERANCE := 3.5
const TEST_TIME_SCALE := 4.0

var _failures: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	var original_time_scale := Engine.time_scale
	Engine.time_scale = TEST_TIME_SCALE
	for shell in [false, true]:
		var tree := STORMHEART.new()
		tree.name = "StormheartShell" if shell else "StormheartWorld"
		tree.simulation_only = shell
		root.add_child(tree)
		tree.build()
		await physics_frame
		await physics_frame
		_check_surfaces(tree, shell)
		await _walk_ascent(tree, shell)
		tree.queue_free()
		await process_frame
	Engine.time_scale = original_time_scale
	quit(0 if _failures.is_empty() else 1)


func _check_surfaces(tree: Node3D, shell: bool) -> void:
	var mode := "shell" if shell else "world"
	for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var point: Vector3 = tree.ascent_point(fraction) + tree.global_position
		var hit := _down_hit(point + Vector3.UP * 4.0, point - Vector3.UP * 5.0)
		var supported := not hit.is_empty() and float((hit.get("normal", Vector3.ZERO) as Vector3).y) > 0.5
		if fraction > 0.0 and fraction < 1.0:
			supported = supported and str((hit.get("collider") as Node).name) == "HollowTrunkAscent"
		_expect(supported, "%s ascent floor receives downward ray at %.2f" % [mode, fraction])
		if fraction < 1.0:
			var radial := Vector3(point.x, 0.0, point.z).normalized()
			var inner := _ray_hit(point + Vector3.UP * 0.72, point + Vector3.UP * 0.72 - radial * 6.0)
			var outer := _ray_hit(point + Vector3.UP * 0.72, point + Vector3.UP * 0.72 + radial * 6.0)
			_expect(not inner.is_empty() and str((inner.get("collider") as Node).name) == "AscentRailInner",
				"%s inner rail blocks at %.2f" % [mode, fraction])
			_expect(not outer.is_empty() and str((outer.get("collider") as Node).name) == "AscentRailOuter",
				"%s outer rail blocks at %.2f" % [mode, fraction])


func _walk_ascent(tree: Node3D, shell: bool) -> void:
	var mode := "shell" if shell else "world"
	var body := CharacterBody3D.new()
	body.name = "AscentWalker"
	body.floor_max_angle = deg_to_rad(35.0)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.75
	collision.shape = capsule
	body.add_child(collision)
	root.add_child(body)
	body.global_position = tree.global_position + tree.ascent_point(0.0) + Vector3.UP * 0.9
	await physics_frame
	for settle in 20:
		body.velocity.y = -GRAVITY
		body.move_and_slide()
		await physics_frame

	var furthest := 0.0
	var last_progress := 0.0
	for frame in MAX_WALK_FRAMES:
		var progress := clampf((body.global_position.y - (tree.global_position.y + 6.0)) / 144.0, 0.0, 1.0)
		furthest = maxf(furthest, progress)
		var target_fraction := minf(1.0, maxf(progress + 0.008, last_progress + 0.002))
		var target: Vector3 = tree.global_position + tree.ascent_point(target_fraction)
		var direction: Vector3 = target - body.global_position
		direction.y = 0.0
		if direction.length() > 0.05:
			body.velocity.x = direction.normalized().x * WALK_SPEED
			body.velocity.z = direction.normalized().z * WALK_SPEED
		else:
			body.velocity.x = 0.0
			body.velocity.z = 0.0
		body.velocity.y -= GRAVITY / Engine.physics_ticks_per_second
		body.move_and_slide()
		last_progress = maxf(last_progress, progress)
		if frame % 180 == 0:
			print("[stormheart ascent] %s frame=%d fraction=%.3f floor=%s"
				% [mode, frame, furthest, str(body.is_on_floor())])
		var reached_core := body.is_on_floor() and body.global_position.distance_to(tree.core_anchor()) <= CORE_TOLERANCE
		if furthest >= 0.998 and reached_core:
			break
		await physics_frame
	var core: Vector3 = tree.core_anchor()
	var core_distance := body.global_position.distance_to(core)
	_expect(furthest >= 0.998 and body.is_on_floor() and core_distance <= CORE_TOLERANCE,
		"%s CharacterBody3D reaches core by continuous ramp walk (fraction=%.3f core_distance=%.2f)"
		% [mode, furthest, core_distance])
	body.queue_free()
	await process_frame


func _down_hit(from: Vector3, to: Vector3) -> Dictionary:
	return _ray_hit(from, to)


func _ray_hit(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	return root.get_world_3d().direct_space_state.intersect_ray(query)


func _expect(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition:
		_failures.append(message)
