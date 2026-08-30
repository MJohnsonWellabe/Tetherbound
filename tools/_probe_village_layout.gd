extends SceneTree

## Where the opening's places actually are, measured rather than read off a
## comment.
##
##   godot --headless --path . --script tools/_probe_village_layout.gd
##
## OP-0830-1 asks the gate to keep the player in until the key is found, which
## first needs an honest answer to "in WHERE" -- what the home area contains,
## where its edge is, and which way the road out of it actually runs. Several
## of the coordinates in comments predate the OW5D corridor relocation.
##
## Diagnostic only. Prints; never asserts.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	print("\n--- named nodes in the world root ---")
	var interesting := ["GrandpaHouse", "RoadGate", "GateKey", "Village", "Player",
		"TrailheadSignpost_0", "SigilGate"]
	for name_key: String in interesting:
		var node := world.get_node_or_null(NodePath(name_key)) as Node3D
		if node != null:
			print("  %-22s %s" % [name_key, str(node.global_position.snapped(Vector3.ONE * 0.1))])

	var house := world.get_node_or_null(^"GrandpaHouse")
	if house != null:
		for m: String in ["bed", "grandpa", "door", "outside", "stairs_top", "stairs_bottom"]:
			print("  house marker %-14s %s" % [m, str((house.call("marker", m) as Vector3).snapped(Vector3.ONE * 0.1))])

	print("\n--- every interact prompt within 120m of the village square ---")
	var square := Vector3(10.0, 0.0, -10.0)
	var rows: Array = []
	_collect_prompts(world, square, rows)
	rows.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	for row: Dictionary in rows:
		print("  %6.1fm  %-30s %s" % [float(row["d"]), str(row["label"]),
			str((row["at"] as Vector3).snapped(Vector3.ONE * 0.1))])

	print("\n--- static bodies within 90m of the square (the boundary, if any) ---")
	var bodies: Array = []
	_collect_bodies(world, square, bodies)
	bodies.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	print("  %d static bodies in range" % bodies.size())
	# Coverage by bearing: for each of 36 bearings, the nearest body between 20m
	# and 90m out. A gap is a bearing with nothing at all.
	print("\n--- bearing coverage 20-90m: nearest solid body per 10 degrees ---")
	for step in 36:
		var deg := float(step) * 10.0
		var dir := Vector2(sin(deg_to_rad(deg)), cos(deg_to_rad(deg)))
		var best := 1e9
		var best_name := "-- nothing --"
		for row: Dictionary in bodies:
			var d: float = float(row["d"])
			if d < 20.0 or d > 90.0:
				continue
			var at: Vector3 = row["at"]
			var off := Vector2(at.x - square.x, at.z - square.z)
			if off.normalized().dot(dir) < 0.985:
				continue
			if d < best:
				best = d
				best_name = str(row["name"])
		if best > 1e8:
			print("  %5.1f deg   -- nothing between 20m and 90m --" % deg)
		else:
			print("  %5.1f deg   %5.1fm  %s" % [deg, best, best_name])

	quit(0)


func _collect_prompts(node: Node, from: Vector3, out: Array) -> void:
	for child: Node in node.get_children():
		var script: Script = child.get_script()
		if script != null and str(script.resource_path).ends_with("interactable.gd"):
			var here := child as Node3D
			var d: float = Vector2(here.global_position.x - from.x, here.global_position.z - from.z).length()
			if d <= 120.0 and bool(here.get("enabled")):
				out.append({"d": d, "label": str(here.get("label")), "at": here.global_position})
		_collect_prompts(child, from, out)


func _collect_bodies(node: Node, from: Vector3, out: Array) -> void:
	for child: Node in node.get_children():
		if child is StaticBody3D:
			var here := child as Node3D
			var d: float = Vector2(here.global_position.x - from.x, here.global_position.z - from.z).length()
			if d <= 90.0:
				out.append({"d": d, "at": here.global_position, "name": _path_of(child)})
		_collect_bodies(child, from, out)


func _path_of(node: Node) -> String:
	var parts: Array[String] = []
	var walk := node
	for i in 4:
		if walk == null:
			break
		parts.push_front(str(walk.name))
		walk = walk.get_parent()
	return "/".join(parts)
