extends "res://tests/test_case.gd"

## Detached journal/channel contract controls only. These do not establish
## actual physics presence, guest transport, enabled content, or disk writes.
const REFINING := preload("res://scripts/world/homestead_refining.gd")
const ACTIONS := preload("res://scripts/build/station_actions.gd")
const ADAPTER := preload("res://scripts/net/foundation_forge.gd")
const FORGE := preload("res://scripts/build/station_forge.gd")

func test_exact_refining_recipe_is_typed_only_and_cannot_be_crafted_without_completed_ticket() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes/recipes_forge.json"))
	var db := preload("res://autoload/item_db.gd").new()
	for id: String in REFINING.REFINING_IDS:
		var recipe := REFINING.transaction_recipe(id)
		assert_eq(recipe.cost, source.recipes[id].cost)
		assert_eq(recipe.output, source.recipes[id].output)
		assert_eq(recipe.station_id, "forge")
		assert_eq(recipe.station_tier, 0, "base refinement cannot require its own ingot-funded attachment")
		assert_true(recipe.requires_manual_refine)
		assert_true(db.recipe(id).is_empty(), "generic instantaneous craft book remains unchanged")
		var intent := {"recipe_id": id, "craft_id": "0123456789abcdef0123456789abcdef"}
		assert_eq(ACTIONS.stage_craft({}, 0, intent, {}, recipe).code, "present_completed_refining_required")
		assert_eq(ACTIONS.stage_craft({}, 0, intent, {"completed_manual_refine": true,
			"manual_unit_ticket": "ffffffffffffffffffffffffffffffff"}, recipe).code, "present_completed_refining_required")
	assert_true(REFINING.transaction_recipe("orb_basic").is_empty())

func test_unit_completion_requires_owner_saved_decision_and_never_counts_pending_or_wrong_ticket() -> void:
	var manual: Node = FORGE.new()
	manual.set("_pending", {"txn_id": "original_ticket", "character_id": "owner_a", "world_id": "world_a"})
	manual.set("_remaining", 2)
	var plan := {"character_id": "owner_a", "world_id": "world_a"}
	var pending := ADAPTER.unit_verdict("original_ticket", plan, {"ok": false, "resolved": false, "durable": true, "saved": false})
	assert_true(manual.call("resolve_pending_unit", pending))
	assert_eq(manual.get("_completed"), 0)
	assert_eq(manual.get("_remaining"), 2)
	var wrong := ADAPTER.unit_verdict("another_ticket", plan, {"ok": true, "saved": true, "resolved": true})
	assert_false(manual.call("resolve_pending_unit", wrong))
	assert_eq(manual.get("_completed"), 0)
	var saved := ADAPTER.unit_verdict("original_ticket", plan, {"ok": true, "saved": true, "resolved": true})
	assert_true(manual.call("resolve_pending_unit", saved))
	assert_eq(manual.get("_completed"), 1)
	assert_false(manual.call("resolve_pending_unit", saved), "duplicate callback cannot grant another completed unit")
	manual.free()
