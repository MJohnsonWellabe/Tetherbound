extends SceneTree

## Placement fingerprint of the Cloudreach look pass. Builds the real
## Cloudreach scene exactly as tests/smoke_cloudreach_look.gd does, dresses it
## with scripts/world/cloudreach_look.gd, then hashes every MultiMesh instance
## transform and every Node3D transform under the look node, in tree order.
## Two builds that place the same tufts/trees/stones print the same hash, so a
## speed-only change to the look pass can be proved output-identical.
##
##   godot --headless --path . --script tests/probe_cloudreach_look_hash.gd
##
## Prints `[look_hash] dress_ms=<n> instances=<n> nodes=<n> sha256=<hex>`.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const LOOK := preload("res://scripts/world/cloudreach_look.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 8:
		await physics_frame
	var look := LOOK.new()
	look.name = "CloudreachLook"
	world.add_child(look)
	var started := Time.get_ticks_msec()
	look.call("dress", world)
	var dress_ms := Time.get_ticks_msec() - started
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var counts := {"instances": 0, "nodes": 0}
	_hash_node(look, ctx, counts)
	var digest := ctx.finish().hex_encode()
	print("[look_hash] dress_ms=%d instances=%d nodes=%d sha256=%s"
		% [dress_ms, counts.instances, counts.nodes, digest])
	quit(0)


func _hash_node(node: Node, ctx: HashingContext, counts: Dictionary) -> void:
	if node is Node3D:
		counts.nodes += 1
		ctx.update(("%s|%s\n" % [node.name, _xf((node as Node3D).transform)]).to_utf8_buffer())
	if node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
		var mm := (node as MultiMeshInstance3D).multimesh
		for i in mm.instance_count:
			counts.instances += 1
			ctx.update((_xf(mm.get_instance_transform(i)) + "\n").to_utf8_buffer())
	for child in node.get_children():
		_hash_node(child, ctx, counts)


func _xf(t: Transform3D) -> String:
	return "%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f" % [
		t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z,
		t.basis.z.x, t.basis.z.y, t.basis.z.z, t.origin.x, t.origin.y, t.origin.z]
