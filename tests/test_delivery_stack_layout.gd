extends "res://tests/test_case.gd"

## A saved delivery replays to the same items even when stack capacity changed
## after it was written (bulk tier materials 50 -> 200): the Satchel layout may
## differ, the item totals and the rest of the record may not.
const DELIVERY := preload("res://scripts/net/character_action_delivery.gd")

func _record(inventory: Array, level: int = 10) -> Dictionary:
	return {"character_id": "c", "inventory": inventory, "party": [{"level": level}]}

func test_same_items_in_a_different_stack_layout_match() -> void:
	var saved := _record([{"id": "rootstone", "n": 50}, {"id": "rootstone", "n": 50}, {"id": "rootstone", "n": 20}, {"id": "axe", "n": 1, "durability": 27}])
	var staged := _record([{"id": "rootstone", "n": 120}, {"id": "axe", "n": 1, "durability": 27}, null, null])
	assert_true(DELIVERY.same_after(staged, saved))
	assert_true(DELIVERY.same_after(saved, saved))

func test_a_changed_total_tool_or_record_field_never_matches() -> void:
	var saved := _record([{"id": "rootstone", "n": 50}, {"id": "rootstone", "n": 50}, {"id": "axe", "n": 1, "durability": 27}])
	assert_false(DELIVERY.same_after(_record([{"id": "rootstone", "n": 99}, {"id": "axe", "n": 1, "durability": 27}, null]), saved))
	assert_false(DELIVERY.same_after(_record([{"id": "rootstone", "n": 100}, {"id": "axe", "n": 1, "durability": 30}, null]), saved))
	assert_false(DELIVERY.same_after(_record([{"id": "rootstone", "n": 100}, {"id": "axe", "n": 1, "durability": 27}, null], 11), saved))
	assert_false(DELIVERY.same_after(_record([{"id": "rootstone", "n": 100}, {"id": "axe", "n": 1, "durability": 27}]), saved))
