extends SceneTree

## GATE-F-LEG-S10AB. What is standing in the Hall's front door.
##
## S10a's very first walk -- "walk in through the Outer Works" -- burned its
## whole 9,000-frame budget and stopped 13.7 m short, oscillating between
## x=6.07 and x=9.92 at z~7546.4 for ~100 seconds of play before the step gave
## up. The player is on the approach ramp at the right height for that z; they
## simply cannot get through the mouth. This names what they are hitting.
##
## Two measurements, because either alone is ambiguous:
##
##   1. every collider whose AABB overlaps the mouth's own box, with its
##      script, its owner and its extent -- a list, not a guess;
##   2. a downward ray sweep over the approach centreline and its flanks, so
##      the walking surface's own profile through the doorway is a table
##      rather than an inference from the ramp's arithmetic.
##
##   godot --headless --path . --script tools/gate_f/probe_hall_threshold.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 420

## The mouth's neighbourhood, in world metres. site.at is (8,7560); the first
## chamber is 20 x 24, so its -z wall spans z 7546.8..7548.0.
const X_LO := 2.0
const X_HI := 14.0
const Z_LO := 7540.0
const Z_HI := 7554.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	print("=== colliders overlapping the mouth box x[%.0f,%.0f] z[%.0f,%.0f] ===" % [X_LO, X_HI, Z_LO, Z_HI])
	var found: Array[Dictionary] = []
	_scan(world, found)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["zlo"]) < float(b["zlo"]))
	for row: Dictionary in found:
		print("  %-38s x[%7.2f,%7.2f] y[%7.2f,%7.2f] z[%9.2f,%9.2f] disabled=%s owner=%s" % [
			str(row["name"]), row["xlo"], row["xhi"], row["ylo"], row["yhi"],
			row["zlo"], row["zhi"], str(row["disabled"]), str(row["owner"])])
	print("  (%d collision shapes)" % found.size())

	print("=== walking surface: ray down from y=+40, by (x, z) ===")
	var space := (world as Node3D).get_world_3d().direct_space_state
	var header := "     z  "
	for x in [4.0, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0]:
		header += "%9.1f" % x
	print(header)
	var z := 7542.0
	while z <= 7552.01:
		var line := "  %7.1f" % z
		for x: float in [4.0, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0]:
			var query := PhysicsRayQueryParameters3D.create(
				Vector3(x, 40.0, z), Vector3(x, -40.0, z))
			var hit := space.intersect_ray(query)
			line += "%9.2f" % (float((hit.get("position", Vector3.ZERO) as Vector3).y) if not hit.is_empty() else NAN)
		print(line)
		z += 0.4

	print("=== what the ray hits ON the centreline (x=8) ===")
	z = 7542.0
	while z <= 7552.01:
		var query := PhysicsRayQueryParameters3D.create(Vector3(8.0, 40.0, z), Vector3(8.0, -40.0, z))
		var hit := space.intersect_ray(query)
		var who: Node = hit.get("collider") as Node if not hit.is_empty() else null
		print("  z=%9.1f y=%7.2f  %s" % [z, (hit.get("position", Vector3.ZERO) as Vector3).y,
			(_path_of(who) if who != null else "NOTHING")])
		z += 0.4

	quit(0)


func _path_of(node: Node) -> String:
	var script: Variant = node.get_script()
	var tag := ""
	if script != null:
		tag = " [%s]" % str(script.resource_path).get_file()
	var owner_tag := ""
	var walk := node.get_parent()
	var depth := 0
	while walk != null and depth < 4:
		owner_tag += "/" + walk.name
		walk = walk.get_parent()
		depth += 1
	return "%s%s  (under%s)" % [node.name, tag, owner_tag]


func _scan(node: Node, out: Array[Dictionary]) -> void:
	if node is CollisionShape3D:
		var cs := node as CollisionShape3D
		if cs.shape != null:
			var aabb := cs.shape.get_debug_mesh().get_aabb() if cs.shape.get_debug_mesh() != null else AABB()
			var box := cs.global_transform * aabb
			if box.position.x <= X_HI and box.end.x >= X_LO \
					and box.position.z <= Z_HI and box.end.z >= Z_LO:
				var parent := cs.get_parent()
				out.append({
					"name": cs.name, "disabled": cs.disabled,
					"owner": _path_of(parent) if parent != null else "",
					"xlo": box.position.x, "xhi": box.end.x,
					"ylo": box.position.y, "yhi": box.end.y,
					"zlo": box.position.z, "zhi": box.end.z,
				})
	for child in node.get_children():
		_scan(child, out)
