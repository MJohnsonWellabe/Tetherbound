## CLOUDREACH-HIGH-PERCHES-0909: prove the production landmark retained its
## six needles/caps and gained visible, non-colliding keeper structure.
##
##   godot --headless --path . --script tools/_probe_cloudreach_high_perches.gd
extends SceneTree

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game != null and game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
		game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 12:
		await process_frame

	var needles := world.find_children("*RoostNeedle*", "", true, false)
	var caps := world.find_children("*PerchCap*", "", true, false)
	var footings := world.find_children("*RoostFooting*", "", true, false)
	var collars := world.find_children("*RoostCollar*", "", true, false)
	var arms := world.find_children("*RoostRestArm*", "", true, false)
	var braces := world.find_children("*RoostKneeBrace*", "", true, false)
	var rigging := world.find_children("*RoostRigging*", "", true, false)
	var collision_count := 0
	var additions: Array = footings + collars + arms + braces + rigging
	for addition: Node in additions:
		if addition is StaticBody3D:
			collision_count += 1
		collision_count += addition.find_children("*", "StaticBody3D", true, false).size()
	var ok := needles.size() == 6 and caps.size() == 6 and footings.size() == 6 \
		and collars.size() == 12 and arms.size() == 6 and braces.size() == 12 \
		and rigging.size() == 12 and collision_count == 0
	print("CLOUDREACH HIGH PERCHES %s needles=%d caps=%d footings=%d collars=%d arms=%d braces=%d rigging=%d collisions=%d" % [
		"PASS" if ok else "FAIL", needles.size(), caps.size(), footings.size(), collars.size(),
		arms.size(), braces.size(), rigging.size(), collision_count])
	quit(0 if ok else 1)
