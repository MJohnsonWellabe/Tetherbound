extends SceneTree

## GATE-F-LEG-S10CDE. Verifies the new gorge-carve failsafe: boots the real
## world, confirms the four CarveFailsafe volumes exist under the Sigil
## Gate, then places the player at the exact position S10c/S10d got
## permanently pinned at (inside sigil_gate_gorge_west_wing) and confirms
## it gets rescued rather than staying stuck.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PIN_POINT := Vector3(19.0, -7.0, 7372.0)

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame

	var gate: Node = world.get_node_or_null(^"SigilGate")
	if gate == null:
		print("FAIL: no SigilGate node")
		quit(1)
		return
	print("=== CarveFailsafe children under SigilGate ===")
	var found := 0
	for child in gate.get_children():
		if child.name.begins_with("GorgeFailsafe_"):
			found += 1
			var area := child.get_node_or_null(^"CarveFailsafe") as Area3D
			if area == null:
				print("  %s: NO CarveFailsafe area child" % child.name)
			else:
				print("  %s: CarveFailsafe at %s, recover_to=%s" % [
					child.name, area.global_position, area.get_meta("recover_to", "?")])
	print("found %d GorgeFailsafe holders (expected 4)" % found)

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player == null:
		print("FAIL: no Player node")
		quit(1)
		return

	print("")
	print("=== placing player at the historical pin point %s ===" % PIN_POINT)
	player.global_position = PIN_POINT
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO

	var rescued := false
	for i in 400:
		await physics_frame
		if i % 20 == 0:
			print("f=%3d pos=%s" % [i, player.global_position])
		if player.global_position.distance_to(PIN_POINT) > 20.0:
			rescued = true
			print("RESCUED at f=%d, now at %s" % [i, player.global_position])
			break

	if rescued:
		print("PASS: player was moved out of the pin point within 400 frames")
	else:
		print("FAIL: player still within 20m of the pin point after 400 frames: %s" % player.global_position)
	quit(0 if rescued else 1)
