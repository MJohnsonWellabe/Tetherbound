extends SceneTree

## Where can the catch harness stand and reach ALL THREE practice bramblebuns?
##
##   godot --headless --path . --script tools/_probe_catch_stand.gd
##
## `smoke_party_count_after_catches.gd` needs three catches out of the one
## three-member cluster, and it stages the player at (48, 0, -58) -- a point
## chosen by `smoke_catching.gd::_leave_the_farmhouse()` long before T5-OPENING
## (7da75ac7) gave the village an edge. That stand is now OUTSIDE the fence
## while the cluster is centred inside it, so two of the three members sit
## behind a wall and the test catches one.
##
## Moving the cluster is NOT the fix: it is authored content the opening's own
## walk depends on, and `smoke_gate_a_opening_segment.gd` fails the moment the
## tutorial bramblebun stops being where the natural walk from the house
## reaches. So the stand moves instead. This tries candidates and reports, for
## each, how many of the three are reachable by a straight shape-swept line.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const CANDIDATES: Array[Vector2] = [
	Vector2(48.0, -58.0),   # today's stand, for comparison
	Vector2(30.0, -28.0),
	Vector2(30.0, -30.0),
	Vector2(26.0, -30.0),
	Vector2(34.0, -30.0),
	Vector2(30.0, -25.0),
]


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		print("no Player")
		quit(1)
		return

	var targets: Array[Node3D] = []
	for node in _walk(world):
		if node is Node3D and str(node.name).begins_with("Wild_bramblebun_0_"):
			targets.append(node as Node3D)
	targets.sort_custom(func(a, b): return str(a.name) < str(b.name))
	print("cluster members:")
	for t in targets:
		print("   %-24s at %6.1f, %6.1f" % [t.name, t.global_position.x, t.global_position.z])
	print("")

	for spot in CANDIDATES:
		var y := float(world.call("ground_height_at", spot.x, spot.y)) + 1.0
		var from := Vector3(spot.x, y, spot.y)
		var reached := 0
		var notes: Array[String] = []
		for t in targets:
			var blocker := _first_blocker(player, world, from, t.global_position)
			if blocker == "":
				reached += 1
			else:
				notes.append("%s blocked by %s" % [str(t.name).right(3), blocker])
		print("stand %7.1f, %7.1f -> %d/%d reachable   %s" % [
			spot.x, spot.y, reached, targets.size(), "; ".join(notes)])
	quit(0)


## Sweep the player's own shape along the straight line and name the first
## thing that is not the target itself.
func _first_blocker(player: CharacterBody3D, world: Node, from: Vector3, to: Vector3) -> String:
	var flat := to - from
	flat.y = 0.0
	var dir := flat.normalized()
	var scan := player.global_transform
	scan.basis = Basis.IDENTITY
	var was := player.global_transform
	for i in int(flat.length() / 0.5):
		var here := from + dir * (float(i) * 0.5)
		here.y = float(world.call("ground_height_at", here.x, here.z)) + 0.35
		scan.origin = here
		var info := KinematicCollision3D.new()
		if not player.test_move(scan, dir * 0.5, info):
			continue
		var node := info.get_collider() as Node
		if node == null:
			continue
		var name := str(node.name)
		if name.begins_with("Wild_"):
			continue
		player.global_transform = was
		return "%s at %.1fm" % [name, float(i) * 0.5]
	player.global_transform = was
	return ""


func _walk(node: Node, out: Array[Node] = []) -> Array[Node]:
	out.append(node)
	for child in node.get_children():
		_walk(child, out)
	return out
