extends "res://tests/test_case.gd"

## OW7 — a gather point has to show the resource, not just mark the spot.
##
## The owner played the build and reported it plainly: "wood to pick up doesn't
## look like wood, it's just random yellow glowing spots." Rendering the frame
## showed exactly that — gold blobs hanging in open air over grass. The cause
## was structural rather than a tuning miss: a "wood" gather point is bolted
## onto one of `vegetation.gd`'s own LIVING scattered trees, so there was no
## wood-shaped object anywhere near it for the glint to be marking. Three
## earlier rounds all tuned how the glint looked and none of them could have
## fixed it.
##
## So the property under test is not "is there a marker" — there always was
## one — but "is there something that looks like the resource, and is the
## marker attached to it".

const HARVEST_POINT := preload("res://scripts/world/vegetation_harvest_point.gd")

var _point: Node3D = null


func after_each() -> void:
	if _point != null:
		_point.free()
		_point = null


func _make(item: String) -> Node3D:
	_point = HARVEST_POINT.new()
	_point.call("setup", {
		"item": item,
		"amount": 3,
		"respawn_seconds": 90.0,
		"prompt_height": 1.8,
		"label": "Gather",
		"prop_offset": Vector3(1.3, -0.2, 0.4),
		"prop_yaw": 0.9,
	})
	return _point


func test_a_wood_point_stands_a_real_woodpile_on_the_ground() -> void:
	var point := _make("wood")
	var pile: Node3D = point.get_node_or_null(^"Woodpile") as Node3D
	assert_true(pile != null, "a wood gather point should build a Woodpile; the tree it sits on is not wood a player can recognise")
	if pile == null:
		return

	# Not just a node: real geometry. An empty Node3D named Woodpile would
	# satisfy the check above and render exactly the nothing this item is about
	# (the OF20 trap, where a PackedScene assigned to a Mesh property left
	# every authored harvest node silently invisible for weeks).
	var meshes := 0
	var stack: Array[Node] = [pile]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			meshes += 1
		for child in node.get_children():
			stack.append(child)
	assert_true(meshes >= 3, "the pile should be several logs with real meshes, got %d" % meshes)

	# On the offset it was given, which vegetation.gd sampled the ground for.
	assert_almost_eq(pile.position.x, 1.3, 0.001, "the pile should stand where the offset put it")
	assert_almost_eq(pile.position.y, -0.2, 0.001, "the pile should sit on the sampled ground, not the tree's own height")


func test_the_glint_sits_on_the_pile_rather_than_floating_beside_it() -> void:
	var point := _make("wood")
	var pile: Node3D = point.get_node_or_null(^"Woodpile") as Node3D
	var glint: Node3D = point.get_node_or_null(^"Glint") as Node3D
	assert_true(glint != null, "the gather point should still carry its glint")
	if glint == null or pile == null:
		return
	# Directly over the pile in plan, and just above its crown -- the glow and
	# the thing it marks have to read as one object. Floating a metre and a
	# third away over open grass is the reported defect itself.
	assert_almost_eq(glint.position.x, pile.position.x, 0.001, "the glint should be over the pile, not off on its own bearing")
	assert_almost_eq(glint.position.z, pile.position.z, 0.001, "the glint should be over the pile, not off on its own bearing")
	var above := glint.position.y - pile.position.y
	assert_between(above, 0.2, 1.0,
		"the glint should sit just clear of the pile's crown; %.2fm above it is either buried or floating" % above)


func test_a_stone_point_keeps_the_rock_it_already_had() -> void:
	# Stone is the item that never had this problem: its gather point is ON the
	# scattered rock, so the object is already there and already reads as stone.
	# Building a woodpile at one would be actively wrong.
	var point := _make("stone")
	assert_true(point.get_node_or_null(^"Woodpile") == null,
		"a stone gather point should not grow a woodpile")
	assert_true(point.get_node_or_null(^"Glint") != null,
		"a stone gather point should still carry its glint")
