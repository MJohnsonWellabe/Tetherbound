extends SceneTree

## Does OP-0830-1's village fence bisect the opening's practice cluster, and does
## it actually seal where it crosses the walk to it?
##
##   godot --headless --path . --script tools/_probe_fence_vs_cluster.gd
##
## Established already by `tools/_probe_engage_walk.gd` and
## `tools/_probe_engage_obstacle.gd`: the straight walk from the catch harnesses'
## shared start point (48, -58) reaches `Wild_bramblebun_0_1` and
## `Wild_bramblebun_0_3` but grinds to a halt 8.9m short of `Wild_bramblebun_0_2`,
## with `FencePanelCollision_35` the only thing on that line.
##
## `data/config/village_boundary.json`'s outline puts the cluster's authored
## centre (30, 0, -40) 6.0m inside the line while `data/config/bands/
## band1_lower_meadows/spawns.json` gives it a 15m radius -- so the disc the
## opening's first catch draws from straddles the wall the player is confined
## behind until `open_road_gate`, which `data/progression/objectives.json` puts
## AFTER `opening_first_catch`.
##
## Two things follow that a coordinate check cannot decide, and this measures
## both against the built world rather than against the config:
##
##   1. Where does the fence actually stand? Panel bodies, with their spans, so
##      "the outline says X" stops being the claim.
##   2. Is the line the harness walks sealed? A shape sweep along each of the
##      three walks, naming the first body it touches. A walk that crosses the
##      outline and touches no panel is a HOLE in a fence whose whole purpose is
##      to hold the player in.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const START := Vector3(48.0, 0.0, -58.0)


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var director := world.get_node_or_null(^"EncounterDirector")
	if player == null or director == null:
		print("missing Player/EncounterDirector")
		quit(1)
		return

	var start := START
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	for i in 600:
		await physics_frame
		var candidate := director.call("wild_creature") as Node3D
		if candidate != null and candidate.visible and bool(candidate.call("is_alive")):
			break

	var nodes := _walk_tree(world)

	# --- where the fence actually stands ---------------------------------------
	var panels: Array[Node3D] = []
	for node in nodes:
		if node is Node3D and str(node.name).begins_with("FencePanelCollision_"):
			panels.append(node as Node3D)
	print("village fence: %d panel bodies" % panels.size())
	panels.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.z < b.global_position.z)
	print("the eight standing furthest south (the stretch the practice cluster sits on):")
	for i in mini(8, panels.size()):
		var p := panels[i]
		print("   %-26s at %7.1f, %6.2f, %7.1f" % [
			str(p.name), p.global_position.x, p.global_position.y, p.global_position.z])
	print("")

	# --- is each walk sealed ---------------------------------------------------
	var members: Array[Node3D] = []
	for node in nodes:
		if node is Node3D and str(node.name).begins_with("Wild_bramblebun_0_"):
			members.append(node as Node3D)
	members.sort_custom(func(a: Node3D, b: Node3D) -> bool: return str(a.name) < str(b.name))

	for m: Node3D in members:
		var to := m.global_position - start
		to.y = 0.0
		var dir := to.normalized()
		print("%s at %.1f, %.1f -- %.1fm from the start" % [
			str(m.name), m.global_position.x, m.global_position.z, to.length()])
		var touched := {}
		for i in int(to.length() / 0.4):
			var at := player.global_transform
			at.origin = start + dir * (float(i) * 0.4)
			at.origin.y = float(world.call("ground_height_at", at.origin.x, at.origin.z)) + 0.35
			var name := _shape_hit(player, at, dir * 0.4)
			if name != "" and not touched.has(name):
				touched[name] = float(i) * 0.4
				print("      %6.1fm along: %s" % [float(i) * 0.4, name])
		var sealed := false
		for name: String in touched:
			if name.begins_with("FencePanelCollision_"):
				sealed = true
		print("      -> a fence panel stands on this line: %s" % str(sealed))
		print("")

	player.global_position = start
	for i in 5:
		await physics_frame
	quit(0)


func _shape_hit(player: CharacterBody3D, at: Transform3D, motion: Vector3) -> String:
	var was := player.global_transform
	player.global_transform = at
	var info := KinematicCollision3D.new()
	var touched := player.test_move(at, motion, info)
	player.global_transform = was
	if not touched:
		return ""
	var collider: Object = info.get_collider()
	var node := collider as Node
	return str(node.name) if node != null else "<unnamed>"


func _walk_tree(from: Node) -> Array[Node]:
	var out: Array[Node] = [from]
	for child in from.get_children():
		out.append_array(_walk_tree(child))
	return out
