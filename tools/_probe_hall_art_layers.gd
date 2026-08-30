extends SceneTree

## T1-HALL-ART: did the ruin layer and the retrofit layer actually build?
##
##   godot --headless --path . --script tools/_probe_hall_art_layers.gd
##
## WHY THIS EXISTS. A render answers "does it look right" and a smoke test answers
## "is the route intact", but neither answers "did the 574 ivy and rubble instances
## and the 19 props actually get placed, or did `_load_prop` quietly warn and
## return null 19 times?" `stronghold.gd::_load_prop` pushes a WARNING and returns
## null on a missing model, and a warning in a 5000-line capture log is invisible.
## This counts what is really in the tree and prints the draw-call arithmetic the
## lane is budgeted against, so the claim in the handover is a measurement rather
## than an intention.

const STRONGHOLD := preload("res://scripts/world/stronghold.gd")


func _init() -> void:
	var hold: Node3D = STRONGHOLD.new()
	get_root().add_child(hold)
	if not hold.call("build", get_root(), null, null):
		print("[hall-art] the Hall did not build; nothing to probe")
		quit(1)
		return

	var reclaim: Node = hold.get_node_or_null(^"RuinReclaim")
	var retrofit: Node = hold.get_node_or_null(^"TetherRetrofit")
	var pipes: Node = hold.get_node_or_null(^"TetherPipes")

	var instances := 0
	var batches := 0
	if reclaim != null:
		for child in reclaim.get_children():
			if child is MultiMeshInstance3D:
				batches += 1
				instances += (child as MultiMeshInstance3D).multimesh.instance_count
	print("[hall-art] ruin reclaim: %d instances in %d MultiMesh batches (%d draw calls)"
		% [instances, batches, batches])

	var props := 0
	var prop_surfaces := 0
	var cores := 0
	var lights := 0
	if retrofit != null:
		for child in retrofit.get_children():
			props += 1
			prop_surfaces += _surfaces(child)
			if child.find_child("TT_RiftCore", true, false) != null:
				cores += 1
			for sub in child.get_children():
				if sub is OmniLight3D:
					lights += 1
	print("[hall-art] retrofit: %d props, %d surfaces, %d siphon cores found, %d lights"
		% [props, prop_surfaces, cores, lights])

	var pipe_pieces := 0
	var pipe_surfaces := 0
	if pipes != null:
		for child in pipes.get_children():
			pipe_pieces += 1
			pipe_surfaces += _surfaces(child)
	print("[hall-art] pipe runs: %d pieces, %d surfaces" % [pipe_pieces, pipe_surfaces])

	print("[hall-art] TOTAL DRAW CALLS ADDED BY THIS LANE: %d"
		% [batches + prop_surfaces + pipe_surfaces])

	# A siphon whose core was not found is a siphon with no glow, and it would look
	# like an ordinary dark box. Name it loudly rather than letting it pass.
	var siphons := 0
	if retrofit != null:
		for child in retrofit.get_children():
			if str(child.name).begins_with("rift_siphon"):
				siphons += 1
	if siphons != cores:
		print("[hall-art] WARNING: %d siphons but only %d cores resolved -- the "
			% [siphons, cores] + "TT_RiftCore lookup is wrong and the glow is missing")
	quit(0)


func _surfaces(node: Node) -> int:
	var total := 0
	if node is MeshInstance3D:
		var mesh: Mesh = (node as MeshInstance3D).mesh
		if mesh != null:
			total += mesh.get_surface_count()
	for child in node.get_children():
		total += _surfaces(child)
	return total
