extends "res://tests/test_case.gd"

## R2.3: real tree/rock harvesting on the vegetation itself, not just
## harvest_node.gd's ~10 authored tutorial spots.
##
## harvest_logic.gd is the pure tool/durability gating both harvest systems
## now share; scripts/world/vegetation.gd's own selection of which SCATTERED
## instances become gather points is data-driven from vegetation.json and
## tested here directly, without paying for a full mesh-loading build().

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const VEGETATION := preload("res://scripts/world/vegetation.gd")

var db: RefCounted = null
var bag: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)


# --- harvest_logic.gd: the shared tool/durability gate ---------------------

func test_gather_with_the_right_tool_pays_the_full_amount() -> void:
	bag.add("axe", 1)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	assert_eq(int(result["amount"]), 3)
	assert_eq(int(result["required_slot"]), bag.find_slot("axe"))


func test_gather_bare_handed_falls_back_to_the_reduced_rate() -> void:
	var with_tool: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	bag.add("axe", 1)
	var with_axe: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	assert_true(int(with_tool["amount"]) > 0, "bare-handed must still pay something")
	assert_true(int(with_tool["amount"]) < int(with_axe["amount"]),
		"bare-handed must pay less than the right tool")
	assert_eq(int(with_tool["required_slot"]), -1, "no tool in hand, nothing to damage")


func test_gather_with_the_wrong_tool_pays_nothing() -> void:
	bag.add("pickaxe", 1)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	assert_eq(int(result["amount"]), 0, "owning some OTHER tool must refuse, not fall back")


func test_gather_with_a_broken_required_tool_falls_back_rather_than_refusing() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	bag.damage_tool(slot, db.max_durability("axe") + 50)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	assert_true(int(result["amount"]) > 0, "a broken axe must still pay the bare-handed rate")
	assert_eq(int(result["required_slot"]), -1, "a broken tool must not be the one that wears down")


func test_gather_of_an_untool_gated_resource_always_pays_the_full_amount() -> void:
	var result: Dictionary = HARVEST_LOGIC.gather("berries", 5, bag, db)
	assert_eq(int(result["amount"]), 5)
	assert_eq(int(result["required_slot"]), -1)


# --- vegetation.json data integrity ------------------------------------

func test_every_harvest_item_named_in_vegetation_json_is_a_real_tool_gated_resource() -> void:
	var layers: Dictionary = RULES.config().get("layers", {})
	for name: String in layers.keys():
		if name.begins_with("_"):
			continue
		var layer: Dictionary = layers[name]
		var item_id := str(layer.get("harvest_item", ""))
		if item_id == "":
			continue
		assert_true(not db.definition(item_id).is_empty(), "layer '%s' names a harvest_item that is not a real item: %s" % [name, item_id])
		assert_false(db.gathered_with(item_id).is_empty(),
			"layer '%s's harvest_item '%s' has no gathered_with tool; a real-world resource with no tool gate has nothing distinguishing a gathered instance from harvest_node.gd's own bare_handed rate" % [name, item_id])
		assert_between(float(layer.get("harvest_fraction", 0.0)), 0.0, 1.0,
			"layer '%s's harvest_fraction must be a fraction" % name)
		assert_true(int(layer.get("harvest_amount", 0)) > 0, "layer '%s's harvest_amount must be positive" % name)


# --- selection: scripts/world/vegetation.gd's _mark_harvestable ------------

func _placements() -> Dictionary:
	var field: RefCounted = HEIGHTFIELD.new()
	var world_size: float = float(HEIGHTFIELD.load_config().get("world_size", 512))
	var cfg: Dictionary = RULES.config()
	return RULES.all_placements(field, world_size, int(cfg.get("seed", 1)))


func test_marking_produces_a_sane_slice_of_the_configured_layers() -> void:
	var veg: Node3D = VEGETATION.new()
	var by_layer := _placements()
	veg.call("_mark_harvestable", by_layer)

	var trees: Array = by_layer.get("trees", [])
	var marked := 0
	for p: Dictionary in trees:
		if p.has("harvest_item"):
			marked += 1
			assert_eq(str(p["harvest_item"]), "wood")
	var fraction := float(RULES.config()["layers"]["trees"].get("harvest_fraction", 0.0))
	var expected := int(trees.size() * fraction)
	# A stride selection, not a perfectly exact count -- within a rounding
	# tooth of the configured fraction is the real guarantee.
	assert_true(marked > 0, "no tree in the whole layer was marked harvestable")
	assert_true(absi(marked - expected) <= maxi(2, int(expected * 0.4)),
		"marked %d of %d trees, expected roughly %d (fraction %.3f)" % [marked, trees.size(), expected, fraction]
	)
	veg.free()


func test_marking_leaves_layers_with_no_harvest_item_untouched() -> void:
	var veg: Node3D = VEGETATION.new()
	var by_layer := _placements()
	veg.call("_mark_harvestable", by_layer)

	for name: String in ["flowers", "grass", "drygrass", "bushes"]:
		for p: Dictionary in (by_layer.get(name, []) as Array):
			assert_false((p as Dictionary).has("harvest_item"),
				"layer '%s' has no harvest_item configured and must never be marked" % name)
	veg.free()


func test_marking_is_deterministic_for_the_same_seed() -> void:
	var veg: Node3D = VEGETATION.new()
	var first := _placements()
	veg.call("_mark_harvestable", first)
	var first_marked: Array = []
	for p: Dictionary in (first.get("rocks", []) as Array):
		first_marked.append(p.has("harvest_item"))

	var second := _placements()
	veg.call("_mark_harvestable", second)
	var second_marked: Array = []
	for p: Dictionary in (second.get("rocks", []) as Array):
		second_marked.append(p.has("harvest_item"))

	assert_eq(first_marked, second_marked, "the same seed must mark the same instances every run")
	veg.free()
