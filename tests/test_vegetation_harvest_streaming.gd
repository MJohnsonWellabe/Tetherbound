extends "res://tests/test_case.gd"

## Realm-load candidate (2026-10-12): harvest-point streaming, OFF by default
## (performance.json harvest_point_stream_radius_m = 0). With a radius, a
## registered point keeps its exact spec and its node exists only near the
## player. Every streamed node must be the node the boot path would have made
## (same position, payout, identity, realm and prompt), harvest and clearing
## must still reach a point whose node is streamed out, and a node mid-claim
## is never freed. tools/_probe_harvest_streaming_parity.gd checks the same
## identity over every point of a real Meadows build.

const VEGETATION := preload("res://scripts/world/vegetation.gd")


func _veg(radius: float) -> Node3D:
	var veg: Node3D = VEGETATION.new()
	veg.set("HARVEST_STREAM_RADIUS", radius)
	(veg.get("_mesh_ids") as Dictionary)["test://tree.glb"] = 3
	return veg


func _spawn(veg: Node3D, index: int, at: Vector3) -> void:
	veg.call("_spawn_harvest_point", {"position": at, "model": "test://tree.glb",
		"harvest_item": "wood", "harvest_amount": 2, "harvest_layer": "trees", "harvest_index": index})


func _identity(node: Node) -> Dictionary:
	var prompt := node.get_node(^"Interactable") as Node3D
	return {"position": (node as Node3D).position, "item": node.call("resource_item"),
		"amount": node.call("resource_amount"), "layer": node.get("_harvest_layer"),
		"index": node.get("_harvest_index"), "realm": node.get("_realm_id"),
		"label": prompt.get("label"), "prompt_at": prompt.position}


func _nodes(veg: Node3D) -> Dictionary:
	return veg.get("_harvest_nodes")


func test_off_by_default_every_point_gets_its_node_at_registration() -> void:
	var veg := _veg(0.0)
	assert_false(veg.call("harvest_streaming_enabled"), "radius 0 means off")
	_spawn(veg, 0, Vector3.ZERO)
	_spawn(veg, 1, Vector3(300.0, 0.0, 0.0))
	assert_eq(_nodes(veg).size(), 2, "boot path makes every node")
	assert_eq((veg.get("_harvest_lookup") as Dictionary).size(), 2, "canonical registry retains both boot points")
	veg.call("update_harvest_streaming", Vector3(1000.0, 0.0, 0.0))
	assert_eq(_nodes(veg).size(), 2, "streaming does nothing when off")
	veg.free()


func test_simulation_harvest_uses_the_placement_id_without_loading_a_render_asset() -> void:
	var veg := _veg(0.0)
	veg.set("simulation_only", true)
	# No render asset exists at this URI. The render cache deliberately has a
	# different ID: using it would also detach harvest removal from the shell's
	# instance-position bookkeeping.
	(veg.get("_sim_mesh_ids") as Dictionary)["test://tree.glb"] = 17
	_spawn(veg, 0, Vector3(3.0, 0.0, 4.0))
	var lookup: Dictionary = veg.get("_harvest_lookup")
	assert_eq(int(lookup["trees#0"].mesh_id), 17, "harvest and placement share the shell ID")
	assert_eq(int(veg.get("_harvest_points")), 1, "the actual gameplay point remains")
	assert_eq(_identity(_nodes(veg)["trees#0"]).amount, 2, "harvest payout remains unchanged")
	assert_eq(int(veg.call("_placement_mesh_id", "test://unloaded.glb")),
		int((veg.get("_sim_mesh_ids") as Dictionary)["test://unloaded.glb"]), "new shell IDs need no model")
	assert_false((veg.get("_mesh_ids") as Dictionary).has("test://unloaded.glb"), "no render registration")
	veg.free()


func test_streamed_nodes_equal_boot_nodes_and_follow_the_player() -> void:
	var off := _veg(0.0)
	var on := _veg(40.0)
	var spots := [Vector3(0.0, 1.0, 0.0), Vector3(30.0, 2.0, -5.0), Vector3(200.0, 3.0, 10.0)]
	for i in spots.size():
		_spawn(off, i, spots[i])
		_spawn(on, i, spots[i])
	assert_eq(_nodes(on).size(), 0, "nothing made at registration when on")
	assert_eq(int(on.get("_harvest_points")), 3, "count unchanged by streaming")
	assert_eq((on.get("_harvest_lookup") as Dictionary).size(), 3, "lookups unchanged by streaming")
	on.call("update_harvest_streaming", Vector3.ZERO)
	assert_eq(_nodes(on).keys().size(), 2, "the two points within 40 m stream in")
	assert_true(_nodes(on).has("trees#0") and _nodes(on).has("trees#1"))
	for key: String in ["trees#0", "trees#1"]:
		assert_eq(_identity(_nodes(on)[key]), _identity(_nodes(off)[key]), "%s streams in as the boot node" % key)
	# Hold a claim on #1, then walk to the far point.
	(_nodes(on)["trees#1"] as Node).set("_claiming", true)
	var near: Node = _nodes(on)["trees#0"]
	on.call("update_harvest_streaming", Vector3(200.0, 0.0, 0.0))
	assert_true(_nodes(on).has("trees#2"), "the far point streams in")
	assert_eq(_identity(_nodes(on)["trees#2"]), _identity(_nodes(off)["trees#2"]))
	assert_false(_nodes(on).has("trees#0"), "a point past 1.25x the radius is freed")
	assert_true(near.is_queued_for_deletion())
	assert_true(_nodes(on).has("trees#1"), "a node mid-claim is never freed")
	# Back home: #0 returns as the same node it was.
	(_nodes(on)["trees#1"] as Node).set("_claiming", false)
	on.call("update_harvest_streaming", Vector3.ZERO)
	assert_eq(_identity(_nodes(on)["trees#0"]), _identity(_nodes(off)["trees#0"]), "re-streamed node unchanged")
	assert_false(_nodes(on).has("trees#2"))
	assert_eq(int(on.get("_harvest_points")), 3, "streaming never changes the count")
	off.free()
	on.free()


func test_harvest_and_clearing_reach_a_streamed_out_point_and_it_never_returns() -> void:
	var veg := _veg(40.0)
	_spawn(veg, 0, Vector3(500.0, 0.0, 0.0))
	_spawn(veg, 1, Vector3(-500.0, 0.0, 0.0))
	_spawn(veg, 2, Vector3(0.0, 0.0, 0.0))
	(veg.get("_harvested") as Dictionary)["trees"] = PackedByteArray([0])
	veg.call("harvest_permanently", "trees", 0)
	assert_false((veg.get("_harvest_lookup") as Dictionary).has("trees#0"), "harvest reaches a streamed-out point")
	assert_eq(int(veg.get("_harvest_points")), 2)
	veg.call("clear_area", Vector3(-500.0, 0.0, 0.0), 5.0)
	assert_false((veg.get("_harvest_lookup") as Dictionary).has("trees#1"), "clearing reaches a streamed-out point")
	assert_eq(int(veg.get("_harvest_points")), 1, "counted once")
	veg.call("update_harvest_streaming", Vector3(500.0, 0.0, 0.0))
	veg.call("update_harvest_streaming", Vector3(-500.0, 0.0, 0.0))
	assert_false(_nodes(veg).has("trees#0"), "a harvested point never streams back")
	assert_false(_nodes(veg).has("trees#1"), "a cleared point never streams back")
	# A cleared point whose node was standing is also counted once.
	veg.call("update_harvest_streaming", Vector3.ZERO)
	assert_true(_nodes(veg).has("trees#2"))
	veg.call("clear_area", Vector3.ZERO, 5.0)
	assert_eq(int(veg.get("_harvest_points")), 0, "standing node counted once")
	assert_false((veg.get("_harvest_lookup") as Dictionary).has("trees#2"), "clearing removes the canonical respawn record")
	veg.call("update_harvest_streaming", Vector3.ZERO)
	assert_false(_nodes(veg).has("trees#2"), "a cleared standing point cannot respawn")
	assert_eq(int(veg.get("_harvest_points")), 0, "revisiting cannot recount the cleared point")
	veg.free()
