extends SceneTree

## T5-CARE probe: are there columns near the opening's build area with no
## floor under them?
##
##   godot --headless --path . --script tools/_probe_t5_holes.gd
##
## `tests/smoke_gate_a_build_segment_meadows.gd` failed on `ralph/LAND-0830I`
## with the WORLD's own recovery message -- not the harness's --
##
##   [world_perimeter_corridor] player fell below the world at 14, -133, -19
##
## `tools/_probe_t5_ground.gd` then showed `ground_height_at` agreeing with a
## downward raycast at every authored waypoint, so the height query is not
## lying. That leaves the other possibility: the floor is not RESIDENT
## everywhere the player walks. `playground_world.gd` streams prop collision
## ("137/52893 collision resident") and the terrain itself is chunked, so this
## sweeps a grid over the village-to-Practice-Meadow corridor and reports every
## column a body would fall through.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
## The corridor the opening walks: village square through the road bend to the
## Practice Meadow clearing, with margin on both sides.
const X_MIN := -10.0
const X_MAX := 40.0
const Z_MIN := -50.0
const Z_MAX := 5.0
const STEP := 2.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as Node3D
	var space := world.get_world_3d().direct_space_state

	var holes: Array[Vector2] = []
	var tested := 0
	var x := X_MIN
	while x <= X_MAX:
		var z := Z_MIN
		while z <= Z_MAX:
			tested += 1
			var params := PhysicsRayQueryParameters3D.create(
				Vector3(x, 400.0, z), Vector3(x, -400.0, z))
			params.collide_with_areas = false
			if space.intersect_ray(params).is_empty():
				holes.append(Vector2(x, z))
			z += STEP
		x += STEP

	print("")
	print("=== T5 hole sweep (player at %s) ===" % (str(player.global_position) if player != null else "?"))
	print("  tested %d columns over the village -> Practice Meadow corridor" % tested)
	if holes.is_empty():
		print("  NO HOLES: every column has a floor with the player parked at spawn.")
	else:
		print("  %d column(s) with NO floor at all:" % holes.size())
		for h in holes:
			print("    (%.0f, %.0f)" % [h.x, h.y])

	# Now the same sweep with the player STOOD at the build entry, because
	# collision residency follows the player.
	if player != null:
		player.global_position = Vector3(10.0, 2.0, -13.0)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		for i in 120:
			await physics_frame
		print("  after standing the player at the Village Square apron: player now at %s" % str(player.global_position))
		var holes2: Array[Vector2] = []
		x = X_MIN
		while x <= X_MAX:
			var z := Z_MIN
			while z <= Z_MAX:
				var p2 := PhysicsRayQueryParameters3D.create(
					Vector3(x, 400.0, z), Vector3(x, -400.0, z))
				p2.collide_with_areas = false
				if space.intersect_ray(p2).is_empty():
					holes2.append(Vector2(x, z))
				z += STEP
			x += STEP
		print("  %d column(s) with no floor from there" % holes2.size())
		for h in holes2:
			print("    (%.0f, %.0f)" % [h.x, h.y])
	quit(0)
