extends SceneTree

## T5-CARE probe: does the world's own height query agree with the collision
## the player actually stands on, at the places the chapter builds?
##
##   godot --headless --path . --script tools/_probe_t5_ground.gd
##
## Written after `tests/smoke_gate_a_build_segment_meadows.gd` failed on
## `ralph/LAND-0830I` with the world itself reporting
##
##   [world_perimeter_corridor] player fell below the world at 14, -133, -19
##
## and then three walk attempts stopping ~28m short of a waypoint whose ground
## height had resolved to **-16**. A build patch the player falls through is a
## section H failure before any question about snapping or ghosts.
##
## Compares, at each authored point the opening actually uses:
##   * `world.ground_height_at(x, z)` -- what the build placer and every
##     harness fixture ask
##   * a straight physics raycast down the same column -- what the player's
##     own body will land on

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300

## The opening's own coordinates: spawn, the Village Square apron, the
## Practice Meadow road bend and the build clearing.
const POINTS: Array = [
	["spawn area", Vector2(0.0, 0.0)],
	["Village Square apron", Vector2(10.0, -13.0)],
	["Practice Meadow road bend", Vector2(18.0, -24.0)],
	["Practice Meadow clearing", Vector2(30.0, -40.0)],
	["village well", Vector2(10.0, -10.0)],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as Node3D
	print("")
	print("=== T5 ground probe ===")
	if player != null:
		print("  player rests at %s" % str(player.global_position))
	var space := world.get_world_3d().direct_space_state
	for entry: Variant in POINTS:
		var name := str((entry as Array)[0])
		var xz := (entry as Array)[1] as Vector2
		var reported := 0.0
		if world.has_method("ground_height_at"):
			reported = float(world.call("ground_height_at", xz.x, xz.y))
		# Cast from well above anything the Meadows builds down through the floor.
		var params := PhysicsRayQueryParameters3D.create(
			Vector3(xz.x, 400.0, xz.y), Vector3(xz.x, -400.0, xz.y))
		params.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(params)
		if hit.is_empty():
			print("  %-28s reported %8.2f   RAY HIT NOTHING — open column, the player falls" % [
				name, reported])
			continue
		var actual := float((hit["position"] as Vector3).y)
		var collider := str((hit["collider"] as Node).name) if hit.has("collider") else "?"
		var delta := reported - actual
		var flag := "" if absf(delta) < 1.0 else "   <-- MISMATCH %.2fm" % delta
		print("  %-28s reported %8.2f   ray %8.2f  on '%s'%s" % [
			name, reported, actual, collider, flag])
	quit(0)
