extends SceneTree
## Realm-load candidate check (2026-10-12): harvest-point streaming against
## the boot path over a real Meadows build. Builds once with streaming OFF and
## records every harvest-point node (position, payout, identity, realm,
## prompt), then again with harvest_point_stream_radius_m set, and walks a
## grid whose cells all lie inside the radius. Every recorded point must
## stream in as the identical node, its prompt live in the interaction
## arbiter. One point per layer is then chopped through the real gather path
## with streaming on and must leave the scatter (the boot path's chop is
## covered by the existing harvest tests; chopping in both builds would change
## the second build's ledger). Prints
## PARITY_RESULT pass|fail with counts; exit 1 on any mismatch.
##   godot --headless --path . --script tools/_probe_harvest_streaming_parity.gd -- --radius=60

const PERF_CONFIG := preload("res://scripts/world/performance_config.gd")

var _fail := 0


func _initialize() -> void:
	_run.call_deferred()


func _radius() -> float:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--radius="):
			return float(arg.get_slice("=", 1))
	return 60.0


func _run() -> void:
	await process_frame
	var radius := _radius()
	PERF_CONFIG.config()["harvest_point_stream_radius_m"] = 0.0
	var off: Dictionary = await _build(false, radius)
	PERF_CONFIG.config()["harvest_point_stream_radius_m"] = radius
	var on: Dictionary = await _build(true, radius)
	_check(off["identities"].size() > 50000, "boot build recorded %d points" % off["identities"].size())
	_check(off["identities"].keys().size() == on["identities"].keys().size(),
		"streamed %d of %d points" % [on["identities"].size(), off["identities"].size()])
	var mismatched := 0
	for key: String in off["identities"]:
		if not on["identities"].has(key) or on["identities"][key] != off["identities"][key]:
			mismatched += 1
			if mismatched <= 5:
				print("MISMATCH %s off=%s on=%s" % [key, off["identities"][key], on["identities"].get(key)])
	_check(mismatched == 0, "%d streamed nodes differ from the boot node" % mismatched)
	_check(on["dead_prompts"] == 0, "%d streamed prompts not live" % on["dead_prompts"])
	var chopped := 0
	for layer: String in on["chops"]:
		chopped += 1 if on["chops"][layer] == "gone" else 0
	_check(chopped > 0 and chopped == on["chops"].size(), "every layer's streamed point chops: %s" % on["chops"])
	print("PARITY_BUILD_MS off=%d on=%d" % [off["build_ms"], on["build_ms"]])
	print("PARITY_RESULT %s points=%d mismatched=%d dead_prompts=%d max_streamed=%d chops=%s" % [
		"pass" if _fail == 0 else "fail", off["identities"].size(), mismatched, on["dead_prompts"],
		on["max_streamed"], on["chops"]])
	quit(0 if _fail == 0 else 1)


func _check(ok: bool, what: String) -> void:
	print("%s %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		_fail += 1


func _identity(node: Node) -> Array:
	var prompt := node.get_node(^"Interactable") as Node3D
	return [(node as Node3D).position, node.call("resource_item"), node.call("resource_amount"),
		node.get("_harvest_layer"), node.get("_harvest_index"), node.get("_realm_id"),
		prompt.get("label"), prompt.get("radius"), prompt.position]


func _build(streaming: bool, radius: float) -> Dictionary:
	var started := Time.get_ticks_msec()
	var world := (load("res://scenes/world/meadows_playground.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	while not (world.has_method("shell_build_complete") and bool(world.call("shell_build_complete"))):
		await process_frame
	var out := {"build_ms": Time.get_ticks_msec() - started, "identities": {}, "dead_prompts": 0,
		"max_streamed": 0, "chops": {}}
	var veg := world.get_node(^"Vegetation")
	_check(bool(veg.call("harvest_streaming_enabled")) == streaming, "streaming=%s" % streaming)
	var lookup: Dictionary = veg.get("_harvest_lookup")
	var nodes: Dictionary = veg.get("_harvest_nodes")
	if not streaming:
		for key: String in nodes:
			out["identities"][key] = _identity(nodes[key])
	else:
		_check(nodes.size() < lookup.size() / 10, "only nearby nodes exist after the build (%d)" % nodes.size())
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for key: String in lookup:
			var at: Vector3 = lookup[key]["position"]
			lo = Vector2(minf(lo.x, at.x), minf(lo.y, at.z))
			hi = Vector2(maxf(hi.x, at.x), maxf(hi.y, at.z))
		# Grid spacing radius*1.4 puts every point within 0.99 radius of a centre.
		var step := radius * 1.4
		var cells := {}
		for key: String in lookup:
			var at: Vector3 = lookup[key]["position"]
			var cell := Vector2i(floori((at.x - lo.x) / step), floori((at.z - lo.y) / step))
			if not cells.has(cell):
				cells[cell] = []
			cells[cell].append(key)
		for cell: Vector2i in cells:
			var centre := Vector3(lo.x + (cell.x + 0.5) * step, 0.0, lo.y + (cell.y + 0.5) * step)
			veg.call("update_harvest_streaming", centre)
			out["max_streamed"] = maxi(out["max_streamed"], nodes.size())
			for key: String in cells[cell]:
				if not nodes.has(key):
					continue
				var node: Node = nodes[key]
				out["identities"][key] = _identity(node)
				var prompt := node.get_node(^"Interactable")
				if not (prompt.is_inside_tree() and bool(prompt.get("enabled"))):
					out["dead_prompts"] += 1
			await process_frame # let freed nodes go
	if streaming:
		out["chops"] = await _chop_one_per_layer(veg)
	world.queue_free()
	for _frame in 30:
		await process_frame
	return out


## The real gather path, the right tool in hand: the point must leave the
## lookup (the committed deplete delta reached vegetation.gd).
func _chop_one_per_layer(veg: Node) -> Dictionary:
	var game := root.get_node(^"/root/Game")
	var items: RefCounted = game.get("items")
	var inventory: RefCounted = game.get("inventory")
	var lookup: Dictionary = veg.get("_harvest_lookup")
	var picked := {}
	var keys: Array = lookup.keys()
	keys.sort()
	for key: String in keys:
		var layer := key.get_slice("#", 0)
		if not picked.has(layer):
			picked[layer] = key
	var result := {}
	for layer: String in picked:
		var key: String = picked[layer]
		veg.call("update_harvest_streaming", lookup[key]["position"])
		var node: Node = veg.get("_harvest_nodes").get(key)
		if node == null:
			result[layer] = "no_node"
			continue
		var tool := str(items.call("gathered_with", node.call("resource_item")))
		if not tool.is_empty() and int(inventory.call("count", tool)) <= 0:
			inventory.call("add", tool, 1)
		node.call("gather", tool if not tool.is_empty() else null)
		for _frame in 10:
			await process_frame
		result[layer] = "gone" if not lookup.has(key) else "standing"
	return result
