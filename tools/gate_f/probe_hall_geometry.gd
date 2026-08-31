extends SceneTree

## GATE-F-LEG-S10AB. Where the Hall's own content ACTUALLY stands, measured in
## the booted world rather than read off a config comment.
##
## S10a/S10b's step-scripts drive the finale by literal world coordinates
## (`move_to {"at": [x, z]}`). Those coordinates were transcribed out of
## `data/config/bands/band5_stronghold_approach/trainers.json`'s `position`
## rows -- which that same file labels, in its own `_position_note`,
## "FALLBACK ONLY ... stronghold.gd places this row from
## data/config/stronghold.json's `gauntlet` block". So the step-script walks
## to where a trainer would stand if the building failed to build, not to
## where the trainer stands when it does.
##
## This prints the live answer for every place either segment has to reach, so
## the step-scripts can be corrected against a measurement instead of against
## arithmetic over a rotated local frame.
##
##   godot --headless --path . --script tools/gate_f/probe_hall_geometry.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 420


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var stronghold := _find_by_script(world, "stronghold.gd")
	if stronghold == null:
		print("PROBE FAIL: no stronghold node in the booted world")
		quit(1)
		return
	var s3 := stronghold as Node3D
	print("=== stronghold node ===")
	print("  name=%s global_position=%s yaw_deg=%.2f" % [
		stronghold.name, str(s3.global_position), rad_to_deg(s3.rotation.y)])
	print("  route: %s" % str(stronghold.call("route")))
	print("  gauntlet placed: %d" % int(stronghold.call("gauntlet_size")))

	print("=== markers (world x, y, z) ===")
	var names: Array = stronghold.call("marker_names")
	names.sort()
	for key: Variant in names:
		var p: Vector3 = stronghold.call("marker", str(key))
		print("  %-28s (%8.2f, %7.2f, %9.2f)" % [str(key), p.x, p.y, p.z])

	print("=== live trainer bodies ===")
	for placer: Node in _all_nodes_by_script(world, "trainer_npc.gd"):
		print("  placer '%s' placed %d" % [placer.name, int(placer.call("placed"))])
		for child in placer.get_children():
			var body := child as Node3D
			if body == null:
				continue
			print("    %-30s id=%-24s (%8.2f, %7.2f, %9.2f)" % [
				body.name, str(body.get_meta("trainer_id", "")),
				body.global_position.x, body.global_position.y, body.global_position.z])

	print("=== climax ===")
	var climax := _find_by_script(world, "stronghold_climax.gd")
	if climax == null:
		print("  NO stronghold_climax node in the world")
	else:
		var warden: Node3D = climax.call("warden_body")
		print("  warden_body: %s" % (str(warden.global_position) if warden != null else "NULL"))
		var legendary: Node3D = climax.call("legendary_body")
		print("  legendary_body: %s" % (str(legendary.global_position) if legendary != null else "NULL"))
		for child in (climax as Node).get_children():
			if child is Node3D:
				print("  child %-22s %s" % [child.name, str((child as Node3D).global_position)])

	print("=== recovery bed ===")
	var bed: Node3D = stronghold.call("recovery_point")
	print("  recovery_point: %s" % (str(bed.global_position) if bed != null else "NULL"))

	quit(0)


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Variant = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null


func _all_nodes_by_script(node: Node, suffix: String) -> Array[Node]:
	var out: Array[Node] = []
	_collect(node, suffix, out)
	return out


func _all_by_script(node: Node, suffix: String) -> Array[Node3D]:
	var out: Array[Node] = []
	_collect(node, suffix, out)
	var typed: Array[Node3D] = []
	for n in out:
		if n is Node3D:
			typed.append(n as Node3D)
	return typed


func _collect(node: Node, suffix: String, out: Array[Node]) -> void:
	var script: Variant = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		out.append(node)
	for child in node.get_children():
		_collect(child, suffix, out)
