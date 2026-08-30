extends SceneTree
## Grid-search a `GATE_KEY_AT` site: inside the village boundary, clear of
## everything solid and of every other prompt, and as close to the gate as those
## allow.
##
##   godot --headless --path . --script tools/_probe_key_site.gd
##
## Rewritten for OP-0830-1. The version this replaces searched a fixed list of
## seven hand-copied landmark coordinates and reasoned about `seal_half_width`
## wings that no longer exist -- the settlement has an authored fence line now
## (`data/config/village_boundary.json`) and the gate is a hole in it. Two
## things changed in kind, not just in numbers:
##
##   * **INSIDE is now a real question.** The key must be on the village side of
##     the fence: the whole point of OP-0830-1 is that the player is held in
##     until they find it, and a key outside the wall is a key they cannot
##     reach. `village_boundary.gd::contains()` answers it against the same
##     polygon the fence is built from.
##   * **The neighbours are queried live.** Every enabled `interactable.gd` in
##     the world and every fence panel collider, read off the built scene rather
##     than transcribed. The old list went stale the moment anything moved, and
##     a probe that reasons about a world that no longer exists is worse than no
##     probe.
##
## Diagnostic only. Prints; never asserts.

const BOUNDARY := preload("res://scripts/world/village_boundary.gd")

## Two prompts whose radii overlap contest for the one interact line, and the
## nearer always wins -- which is how an earlier key placement became
## unreachable behind "Pick berries". The key's own radius is 2.4m; 5.0m of
## separation clears the widest neighbour prompt in the village (4.0m) with a
## little to spare.
const PROMPT_CLEARANCE := 5.0
## The fence panel colliders are 0.5m thick and the player is a 0.4m capsule; at
## less than this the key is in the ditch behind the fence rather than in the
## grass beside the road.
const FENCE_CLEARANCE := 3.0


func _init() -> void:
	var world: Node = load("res://scenes/world/meadows_playground.tscn").instantiate()
	root.add_child(world)
	for i in 300:
		await physics_frame

	var gate: Node3D = world.find_child("RoadGate", true, false) as Node3D
	if gate == null:
		print("NO RoadGate in the world")
		quit(1)
		return
	var gate_at := Vector2(gate.global_position.x, gate.global_position.z)
	print("gate at (%.2f, %.2f), yaw %.1f deg" % [gate_at.x, gate_at.y, rad_to_deg(gate.rotation.y)])

	var outline := BOUNDARY.outline(BOUNDARY.load_config())
	if outline.size() < 3:
		print("no village boundary outline; nothing to be inside of")
		quit(1)
		return

	var prompts: Array[Vector2] = []
	_collect_prompts(world, prompts)
	var fences: Array[Vector2] = []
	_collect_fences(world, fences)
	print("%d live prompts and %d fence panels in the world" % [prompts.size(), fences.size()])

	var best := Vector2.INF
	var best_d := INF
	for xi in range(-40, 41):
		for zi in range(-40, 41):
			var c := gate_at + Vector2(float(xi) * 0.5, float(zi) * 0.5)
			var d := c.distance_to(gate_at)
			if d < 4.0 or d > 14.0 or d >= best_d:
				continue
			if not BOUNDARY.contains(outline, c):
				continue
			var ground: float = float(world.call("ground_height_at", c.x, c.y))
			if is_nan(ground):
				continue
			if _nearest(prompts, c) < PROMPT_CLEARANCE:
				continue
			if _nearest(fences, c) < FENCE_CLEARANCE:
				continue
			best = c
			best_d = d

	if best_d == INF:
		print("NO feasible site in the searched grid")
		quit(1)
		return
	print("BEST candidate: (%.2f, %.2f), %.2fm from the gate" % [best.x, best.y, best_d])
	print("  inside the boundary: %s" % str(BOUNDARY.contains(outline, best)))
	print("  ground %.2f   nearest prompt %.2fm   nearest fence panel %.2fm" % [
		float(world.call("ground_height_at", best.x, best.y)),
		_nearest(prompts, best), _nearest(fences, best)])
	quit(0)


func _nearest(points: Array[Vector2], at: Vector2) -> float:
	var best := INF
	for p: Vector2 in points:
		best = minf(best, p.distance_to(at))
	return best


func _collect_prompts(node: Node, out: Array[Vector2]) -> void:
	for child: Node in node.get_children():
		var script: Script = child.get_script()
		if script != null and str(script.resource_path).ends_with("interactable.gd"):
			if bool(child.get("enabled")):
				var at: Vector3 = (child as Node3D).global_position
				out.append(Vector2(at.x, at.z))
		_collect_prompts(child, out)


func _collect_fences(node: Node, out: Array[Vector2]) -> void:
	for child: Node in node.get_children():
		if child is StaticBody3D and str(child.name).begins_with("FencePanelCollision"):
			var at: Vector3 = (child as Node3D).global_position
			out.append(Vector2(at.x, at.z))
		_collect_fences(child, out)
