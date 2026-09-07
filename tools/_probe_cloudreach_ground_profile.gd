extends SceneTree
## Is the ground under a stand actually flat, and what is holding it flat?
## Samples a transect and reports height, collider name and the reason the
## crown relief did or did not apply there. Cheap: no render.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")

const TRANSECTS := [
	{"name": "05-upper-cliffhold, camera -> target", "from": Vector2(-400.0, 3890.0), "to": Vector2(-340.0, 3970.0)},
	{"name": "05-upper-cliffhold, across the plane", "from": Vector2(-460.0, 3890.0), "to": Vector2(-300.0, 3890.0)},
	{"name": "01-arrival, camera -> target", "from": Vector2(0.0, -260.0), "to": Vector2(0.0, -130.0)},
]


func _initialize() -> void:
	var world: Node3D = SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var look: Node = _find(world, "CloudreachLook")
	if look == null:
		print("no look node")
		quit(1)
		return
	for raw: Variant in TRANSECTS:
		var t: Dictionary = raw
		print("\n=== %s ===" % str(t["name"]))
		var a: Vector2 = t["from"]
		var b: Vector2 = t["to"]
		var heights: Array[float] = []
		var seen := {}
		for i in 41:
			var at := a.lerp(b, float(i) / 40.0)
			var hit: Dictionary = look.call("probe_turf_at", at)
			var collider := str(hit.get("collider", ""))
			var verdict := str(hit.get("verdict", ""))
			if hit.has("y"):
				heights.append(float(hit["y"]))
			var key := "%s/%s" % [collider, verdict]
			seen[key] = int(seen.get(key, 0)) + 1
		if heights.is_empty():
			print("  no ground found along the transect")
			continue
		var lo := heights[0]
		var hi := heights[0]
		for h: float in heights:
			lo = minf(lo, h)
			hi = maxf(hi, h)
		print("  %d ground samples, y from %.2f to %.2f, RANGE %.2f m" % [heights.size(), lo, hi, hi - lo])
		print("  collider/verdict: ", seen)
	quit(0)


func _find(node: Node, needle: String) -> Node:
	if node.name.contains(needle):
		return node
	for child in node.get_children():
		var found := _find(child, needle)
		if found != null:
			return found
	return null
