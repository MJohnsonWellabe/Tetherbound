extends SceneTree

## Scratch diagnostic: does the BAKED Terrain3D data at the South Bridge
## village-side approach match the PROCEDURAL height_at() the config says it
## should be? Prints a grid of both, plus their difference.

const HF := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const CX := 8.0
const CZ := 1319.0

func _init() -> void:
	_run()

func _run() -> void:
	var f: RefCounted = HF.new()
	print("--- procedural height_at, 1m grid around (%.1f,%.1f) ---" % [CX, CZ])
	var head := "      "
	for dx in range(-8, 9):
		head += "%7d" % (int(CX) + dx)
	print(head)
	for dz in range(-8, 9):
		var row := "z%+4d " % (int(CZ) + dz)
		for dx in range(-8, 9):
			row += "%7.2f" % float(f.call("height_at", CX + float(dx), CZ + float(dz)))
		print(row)

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in 240:
		await physics_frame

	print("")
	print("--- BAKED ground_height_at, 1m grid around (%.1f,%.1f) ---" % [CX, CZ])
	print(head)
	for dz in range(-8, 9):
		var row := "z%+4d " % (int(CZ) + dz)
		for dx in range(-8, 9):
			var h := float(world.call("ground_height_at", CX + float(dx), CZ + float(dz)))
			row += "%7.2f" % h
		print(row)

	print("")
	print("--- DIFFERENCE (baked - procedural) ---")
	print(head)
	var max_diff := 0.0
	var max_at := Vector2.ZERO
	for dz in range(-8, 9):
		var row := "z%+4d " % (int(CZ) + dz)
		for dx in range(-8, 9):
			var proc := float(f.call("height_at", CX + float(dx), CZ + float(dz)))
			var baked := float(world.call("ground_height_at", CX + float(dx), CZ + float(dz)))
			var diff := baked - proc
			if absf(diff) > absf(max_diff):
				max_diff = diff
				max_at = Vector2(CX + float(dx), CZ + float(dz))
			row += "%7.2f" % diff
		print(row)
	print("max |diff| = %.3f at (%.1f, %.1f)" % [max_diff, max_at.x, max_at.y])

	# Also check the SouthBridge node's own placement and the player's spawn.
	var bridge: Node3D = world.get_node_or_null(^"SouthBridge") as Node3D
	if bridge != null:
		print("")
		print("SouthBridge global_position = %s" % str(bridge.global_position))
		var near: Vector2 = bridge.call("near_point", 11.0)
		print("near_point(11.0) = %s   ground_height_at there = %.3f" % [
			str(near), float(world.call("ground_height_at", near.x, near.y))])

	quit(0)
