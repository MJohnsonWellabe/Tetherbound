extends "res://tests/test_case.gd"

## The STANDING half of RG9's chop-then-gather split.
##
## `vegetation_harvest_point.gd` used to be the whole gather point -- prompt,
## resource prop (a woodpile for wood, the rock itself for stone) and the
## R2.3/OW7 glint. RG9 (owner directive: "you shouldn't be able to gather a
## standing tree, you should have to chop it, then it becomes downed wood")
## split that in two: this node is now only the CHOP -- a living tree or rock
## with an interact prompt and nothing bolted onto it -- and `felled_resource.gd`
## is the thing a chop stands afterward, which is where the woodpile prop and
## its own tests moved to (`test_felled_resource.gd`). RG10 (owner directive,
## superseding R2.3/OW7's own glint entirely) means neither stage lights up.

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
		"prompt_height": 1.8,
		"harvest_layer": "trees",
		"harvest_index": 0,
	})
	return _point


## RG9: the standing tree/rock has nothing on it any more -- no woodpile
## (a living tree has no cut logs at its base), no glint (RG10). The
## tree/rock itself, drawn by `vegetation.gd`'s own scatter, is the whole
## visual; this node contributes only the interact prompt and the group
## membership a swing needs.
func test_a_standing_wood_point_builds_no_prop() -> void:
	var point := _make("wood")
	assert_true(point.get_node_or_null(^"Woodpile") == null,
		"a standing wood point should build no woodpile (RG9: that moved to the felled stage)")
	assert_true(point.get_node_or_null(^"Glint") == null,
		"a standing wood point should carry no glint marker (RG10)")
	assert_true(point.get_node_or_null(^"Interactable") != null,
		"a standing wood point should still carry its interact prompt")


func test_a_standing_stone_point_builds_no_prop() -> void:
	var point := _make("stone")
	assert_true(point.get_node_or_null(^"Woodpile") == null,
		"a standing stone point should never grow a woodpile")
	assert_true(point.get_node_or_null(^"Glint") == null,
		"a standing stone point should carry no glint marker (RG10)")
	assert_true(point.get_node_or_null(^"Interactable") != null,
		"a standing stone point should still carry its interact prompt")


## RG9: the standing prompt reads as a CHOP now, not a gather -- the owner's
## own word for the first stage ("you should have to chop it").
func test_the_standing_prompt_defaults_to_chop() -> void:
	var point := _make("wood")
	var prompt: Node3D = point.get_node_or_null(^"Interactable")
	assert_true(prompt != null)
	if prompt == null:
		return
	assert_eq(str(prompt.get("label")), "Chop")
