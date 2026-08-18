extends "res://tests/test_case.gd"

## The FELLED half of RG9's chop-then-gather split.
##
## `felled_resource.gd` is what a chop (`vegetation_harvest_point.gd`, via
## `vegetation.gd::fell()`) stands where a tree or rock used to be -- the
## woodpile that used to sit on a still-standing tree (OW7) moved here, since
## a pile of cut logs belongs on the ground after a chop, not at a living
## tree's base. `gather()`'s own inventory half needs the real `/root/Game`
## autoload this runner never boots (see `test_harvest.gd`'s header on the
## same limit for `harvest_node.gd`), so that half is exercised by
## `tests/smoke_playground.gd` instead; this file covers what stands alone:
## the visual construction, which item gets which visual, and `setup()`'s own
## bookkeeping.

const FELLED_RESOURCE := preload("res://scripts/world/felled_resource.gd")

var _node: Node3D = null


func after_each() -> void:
	if _node != null:
		_node.free()
		_node = null


func _make(item: String, amount: int = 3) -> Node3D:
	_node = FELLED_RESOURCE.new()
	_node.call("setup", {"item": item, "amount": amount, "felled_key": "trees#0"})
	return _node


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_walk(child))
	return out


func _has_a_populated_mesh_instance(node: Node) -> bool:
	for descendant in _walk(node):
		if descendant is MeshInstance3D and (descendant as MeshInstance3D).mesh != null:
			return true
	return false


## Moved from `test_gather_point_props.gd`'s own
## `test_a_wood_point_stands_a_real_woodpile_on_the_ground` -- the assertions
## are unchanged, only WHICH node builds the pile changed with RG9.
func test_wood_stands_a_real_woodpile_with_several_logs() -> void:
	var node := _make("wood")
	var pile: Node3D = node.get_node_or_null(^"Woodpile")
	assert_true(pile != null, "a felled wood pickup should build a Woodpile")
	if pile == null:
		return
	assert_true(_has_a_populated_mesh_instance(pile),
		"the pile should be real geometry, not an empty Node3D (the OF20 trap)")

	var meshes := 0
	for descendant in _walk(pile):
		if descendant is MeshInstance3D and (descendant as MeshInstance3D).mesh != null:
			meshes += 1
	assert_true(meshes >= 3, "the pile should be several logs with real meshes, got %d" % meshes)


## RG9: stone has no vendored rubble mesh (D24 forbids a new asset family for
## one pickup), so it gets a small primitive mound instead -- real geometry,
## not nothing, and not a woodpile (wood's own visual would be actively wrong
## for a broken chunk of rock).
func test_stone_stands_a_rubble_mound_not_a_woodpile() -> void:
	var node := _make("stone")
	assert_true(node.get_node_or_null(^"Woodpile") == null,
		"a felled stone pickup should not grow a woodpile")
	var rubble: Node3D = node.get_node_or_null(^"Rubble")
	assert_true(rubble != null, "a felled stone pickup should build a Rubble mound")
	if rubble == null:
		return
	assert_true(_has_a_populated_mesh_instance(rubble),
		"the rubble mound should be real geometry, not an empty Node3D")


## RG10, owner directive: neither felled pickup lights up.
func test_neither_felled_kind_carries_a_glint() -> void:
	for item in ["wood", "stone"]:
		var node := _make(item)
		assert_true(node.get_node_or_null(^"Glint") == null,
			"a felled %s pickup should carry no glint marker (RG10)" % item)
		after_each()


func test_setup_carries_the_prompt_and_the_felled_key() -> void:
	var node := _make("wood", 5)
	assert_true(node.get_node_or_null(^"Interactable") != null,
		"a felled pickup should carry an interact prompt")
	assert_eq(str(node.get("_item_id")), "wood")
	assert_eq(int(node.get("_amount")), 5)
	assert_eq(str(node.get("_felled_key")), "trees#0")


## `gather()` is public so a tool swing (`tool_hold.gd`) and the interact
## prompt drive the identical path -- the same contract
## `vegetation_harvest_point.gd`/`harvest_node.gd` both already carry.
func test_gather_is_exposed_for_a_swing_to_call() -> void:
	var node := _make("wood")
	assert_true(node.has_method("gather"), "felled_resource.gd must expose gather() for tool_hold.gd's swing")
