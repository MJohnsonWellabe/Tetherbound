extends "res://tests/test_case.gd"

## R7.6: the berry farm beside Grandpa's house, and the hoe.
##
## `scripts/world/farm_logic.gd` is the whole rule set — what a bed may do
## next, when a sown bed ripens, and what a picked one becomes. Pure, so this
## suite pins it without booting a world (docs/decisions/D02); the Node3D that
## draws a bed (`farm_plot.gd`) is exercised by `tests/smoke_playground.gd`
## instead.
##
## Two things here are assertions about DESIGN, not about code, and they are
## the ones to be careful about changing:
##
##   * `test_berries_are_still_never_tool_gated` — docs/decisions/D50. Giving
##     berries a farm did not give them a `gathered_with`, and if a later task
##     adds one it should have to delete this test on purpose.
##   * `test_picking_leaves_the_bed_tilled` — also D50. The hoe is a one-off
##     cost per bed rather than a durability tax on every crop, and that is
##     entirely down to which state a harvest returns to.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const FARM_LOGIC := preload("res://scripts/world/farm_logic.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const FARM_CONFIG := "res://data/config/farm.json"
const ITEMS_PATH := "res://data/items/items.json"
const RECIPES_PATH := "res://data/recipes/recipes.json"

var db: RefCounted = null
var bag: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


# --- the item and the recipes ------------------------------------------------

func test_the_hoe_is_a_real_tool() -> void:
	assert_true(db.has("hoe"), "there is no hoe item; nothing can till")
	assert_eq(db.kind("hoe"), "tool")
	assert_true(db.max_durability("hoe") > 0, "a hoe with no durability never wears")
	assert_true(db.tool_ids().has("hoe"),
		"item_db does not count the hoe as a tool, so harvest_logic's "
		+ "'owns some other tool' branch cannot see it")


func test_berry_seeds_are_a_real_item() -> void:
	assert_true(db.has("berry_seeds"), "there is no seed item; nothing can be sown")
	assert_true(db.stack_size("berry_seeds") > 1, "seeds must stack")


## D50, and the load-bearing half of it. `items.json:9` records berries as the
## one resource that is never tool-gated; the farm did not change that.
func test_berries_are_still_never_tool_gated() -> void:
	assert_eq(db.gathered_with("berries"), "",
		"berries gained a `gathered_with`; D50 says farming must not have done that")
	# And the hoe must gate nothing at all through that mechanism, for any item.
	for id: String in db.ids():
		assert_ne(db.gathered_with(id), "hoe",
			"item '%s' is gathered_with hoe; D50 scopes the hoe to tilling" % id)


func test_the_hoe_and_the_seeds_are_both_obtainable() -> void:
	var recipes := _json(RECIPES_PATH).get("recipes", {}) as Dictionary
	assert_true(recipes.has("hoe"), "no hoe recipe; a player can never make one")
	assert_true(recipes.has("berry_seeds"), "no seed recipe; a player can never sow")
	# The seed recipe has to be net-positive or farming leaks berries.
	var seed_recipe := recipes["berry_seeds"] as Dictionary
	var produced := int((seed_recipe.get("output", {}) as Dictionary).get("n", 0))
	var spent := 0
	for entry: Variant in seed_recipe.get("cost", []):
		spent += int((entry as Dictionary).get("n", 0))
	assert_true(produced > spent,
		"3 berries must buy more than 3 seeds, or a bed can never pay for itself")


# --- the state machine -------------------------------------------------------

func test_a_fresh_bed_is_fallow() -> void:
	assert_eq(FARM_LOGIC.state_of(FARM_LOGIC.fresh(), 1), FARM_LOGIC.FALLOW)


func test_fallow_ground_offers_nothing_without_a_hoe() -> void:
	var plot := FARM_LOGIC.fresh()
	assert_eq(FARM_LOGIC.action_for(plot, 1, false, 9), FARM_LOGIC.ACTION_NONE)
	assert_false(FARM_LOGIC.is_actionable(plot, 1, false, 9))
	# ...but it still SAYS something. A silent bed is the OF20 failure.
	assert_ne(FARM_LOGIC.label_for(plot, 1, false, 9), "")


func test_fallow_ground_offers_tilling_with_a_hoe() -> void:
	var plot := FARM_LOGIC.fresh()
	assert_eq(FARM_LOGIC.action_for(plot, 1, true, 0), FARM_LOGIC.ACTION_TILL)
	assert_true(FARM_LOGIC.is_actionable(plot, 1, true, 0),
		"tilling must not need seeds as well as a hoe")


func test_tilled_ground_offers_sowing_only_with_seeds() -> void:
	var plot := FARM_LOGIC.tilled(FARM_LOGIC.fresh())
	assert_eq(FARM_LOGIC.state_of(plot, 1), FARM_LOGIC.TILLED)
	assert_eq(FARM_LOGIC.action_for(plot, 1, true, 0), FARM_LOGIC.ACTION_NONE)
	assert_eq(FARM_LOGIC.action_for(plot, 1, true, 1), FARM_LOGIC.ACTION_SOW)
	# Sowing is not hoe-gated. D50.
	assert_eq(FARM_LOGIC.action_for(plot, 1, false, 1), FARM_LOGIC.ACTION_SOW)


func test_a_sown_bed_is_not_ripe_on_the_day_it_was_sown() -> void:
	var plot: Dictionary = FARM_LOGIC.sown(FARM_LOGIC.fresh(), 3, 1)
	assert_eq(FARM_LOGIC.state_of(plot, 3), FARM_LOGIC.SOWN,
		"a crop sown on day 3 must not be pickable on day 3 -- "
		+ "R7.6's done-when is 'on a LATER day'")
	assert_eq(FARM_LOGIC.action_for(plot, 3, true, 9), FARM_LOGIC.ACTION_NONE)


func test_a_sown_bed_ripens_on_a_later_day() -> void:
	var plot: Dictionary = FARM_LOGIC.sown(FARM_LOGIC.fresh(), 3, 1)
	assert_eq(FARM_LOGIC.state_of(plot, 4), FARM_LOGIC.RIPE)
	assert_eq(FARM_LOGIC.action_for(plot, 4, false, 0), FARM_LOGIC.ACTION_HARVEST,
		"picking must need neither a hoe nor seeds")


## Sleeping through several days must not un-ripen a crop, which is what a
## "has exactly N days passed" check would do.
func test_a_ripe_bed_stays_ripe_however_long_it_is_left() -> void:
	var plot: Dictionary = FARM_LOGIC.sown(FARM_LOGIC.fresh(), 3, 1)
	assert_eq(FARM_LOGIC.state_of(plot, 40), FARM_LOGIC.RIPE)


## A grow time of zero would make "wait" meaningless; farm_logic clamps it.
func test_grow_days_is_clamped_to_at_least_one() -> void:
	var plot: Dictionary = FARM_LOGIC.sown(FARM_LOGIC.fresh(), 5, 0)
	assert_eq(FARM_LOGIC.state_of(plot, 5), FARM_LOGIC.SOWN)
	assert_eq(FARM_LOGIC.state_of(plot, 6), FARM_LOGIC.RIPE)


## D50's corollary. If this ever returns FALLOW, the hoe becomes a durability
## tax on every single crop and §21's "no chores" is broken.
func test_picking_leaves_the_bed_tilled() -> void:
	var ripe: Dictionary = FARM_LOGIC.sown(FARM_LOGIC.fresh(), 1, 1)
	assert_eq(FARM_LOGIC.state_of(ripe, 2), FARM_LOGIC.RIPE)
	var after: Dictionary = FARM_LOGIC.harvested(ripe)
	assert_eq(FARM_LOGIC.state_of(after, 2), FARM_LOGIC.TILLED,
		"a picked bed must stay worked soil, not go back to raw sod")
	assert_eq(FARM_LOGIC.action_for(after, 2, false, 1), FARM_LOGIC.ACTION_SOW,
		"and must be re-sowable with no hoe in the satchel")


## The transitions hand back new dictionaries. A transition that edited its
## argument would write the new state into the caller's saved copy before the
## caller had decided the action succeeded.
func test_transitions_do_not_mutate_their_argument() -> void:
	var plot := FARM_LOGIC.fresh()
	FARM_LOGIC.tilled(plot)
	FARM_LOGIC.sown(plot, 1, 1)
	FARM_LOGIC.harvested(plot)
	assert_eq(str(plot["state"]), FARM_LOGIC.FALLOW)


func test_a_nonsense_saved_plot_comes_back_fallow() -> void:
	assert_eq(str(FARM_LOGIC.sanitised("not a plot")["state"]), FARM_LOGIC.FALLOW)
	assert_eq(str(FARM_LOGIC.sanitised({"state": "orchard"})["state"]), FARM_LOGIC.FALLOW)
	# A real one survives intact.
	var real := {"state": FARM_LOGIC.SOWN, "ripe_on_day": 7}
	assert_eq(int(FARM_LOGIC.sanitised(real)["ripe_on_day"]), 7)


# --- the shared gather body --------------------------------------------------

## The fourth caller of `harvest_logic.gather()`, alongside harvest_node.gd
## and vegetation_harvest_point.gd. Berries are un-gated, so a bare-handed
## pick must pay the FULL yield and wear nothing down.
func test_picking_a_bed_pays_full_yield_bare_handed() -> void:
	var result: Dictionary = HARVEST_LOGIC.gather("berries", 4, bag, db)
	assert_eq(int(result["amount"]), 4)
	assert_eq(int(result["required_slot"]), -1, "nothing should wear down picking berries")


## Owning a hoe must not change what a berry bed pays. `harvest_yield`'s
## "owns some other tool but not the right one gives nothing" branch only
## fires for a gated resource, and berries are not one — but the hoe is a new
## entry in `tool_ids()`, so this is worth pinning rather than assuming.
func test_owning_a_hoe_does_not_change_what_berries_pay() -> void:
	var bare: Dictionary = HARVEST_LOGIC.gather("berries", 4, bag, db)
	bag.add("hoe", 1)
	var with_hoe: Dictionary = HARVEST_LOGIC.gather("berries", 4, bag, db)
	assert_eq(int(with_hoe["amount"]), int(bare["amount"]))


# --- harvest_logic.tool_slot(), which the till step shares --------------------

func test_tool_slot_finds_a_working_hoe() -> void:
	assert_eq(HARVEST_LOGIC.tool_slot("hoe", bag), -1, "no hoe owned")
	bag.add("hoe", 1)
	assert_eq(HARVEST_LOGIC.tool_slot("hoe", bag), bag.find_slot("hoe"))


## R2.2's rule, which tilling inherits by using the same lookup: a broken tool
## does not count as owned until it is repaired.
func test_a_broken_hoe_cannot_till() -> void:
	bag.add("hoe", 1)
	var slot: int = bag.find_slot("hoe")
	bag.damage_tool(slot, db.max_durability("hoe"))
	assert_eq(bag.durability_at(slot), 0)
	assert_eq(HARVEST_LOGIC.tool_slot("hoe", bag), -1,
		"a broken hoe must not till; R2.2 says repair it first")
	bag.repair_tool(slot)
	assert_eq(HARVEST_LOGIC.tool_slot("hoe", bag), slot)


func test_tool_slot_ignores_an_empty_tool_id() -> void:
	assert_eq(HARVEST_LOGIC.tool_slot("", bag), -1)


# --- the authored farm -------------------------------------------------------

func test_farm_json_places_beds_where_r7_6_allows() -> void:
	var config := _json(FARM_CONFIG)
	var plots: Array = config.get("plots", [])
	assert_true(plots.size() > 0, "farm.json places no beds at all")
	assert_true(int(config.get("grow_days", 0)) >= 1, "grow_days must be at least a day")
	assert_true(int(config.get("yield", 0)) >= 1, "a bed that yields nothing is not a farm")
	assert_true(db.has(str(config.get("seed_item", ""))), "farm.json names an unknown seed item")
	assert_true(db.has(str(config.get("crop_item", ""))), "farm.json names an unknown crop item")

	# R7.6's stated constraints: beside Grandpa's house at [-22,-16], clear of
	# the square flat at [10,-10] r18 and of the fence run at [3,-18]. Also
	# inside the house pad's own full-flatten radius (r14), or a bed stands on
	# the skirt and tilts.
	var house := Vector2(-22.0, -16.0)
	var square := Vector2(10.0, -10.0)
	var fence := Vector2(3.0, -18.0)
	for entry: Variant in plots:
		var at: Array = (entry as Dictionary).get("at", [])
		assert_eq(at.size(), 2, "a farm plot has no [x, z]")
		var here := Vector2(float(at[0]), float(at[1]))
		assert_true(here.distance_to(house) <= 14.0,
			"bed at %s is outside the house pad's flatten radius" % str(here))
		assert_true(here.distance_to(square) > 18.0,
			"bed at %s intrudes on the square flat" % str(here))
		assert_true(here.distance_to(fence) > 4.0,
			"bed at %s sits on the fence run" % str(here))


## Two beds close enough to share the arbiter's attention is fine (nearest
## wins), but two beds on the SAME spot would make one of them unreachable.
func test_no_two_beds_occupy_the_same_ground() -> void:
	var plots: Array = _json(FARM_CONFIG).get("plots", [])
	var seen: Array[Vector2] = []
	for entry: Variant in plots:
		var at: Array = (entry as Dictionary).get("at", [])
		var here := Vector2(float(at[0]), float(at[1]))
		for other: Vector2 in seen:
			assert_true(here.distance_to(other) > 1.0,
				"two farm beds within a metre of each other at %s" % str(here))
		seen.append(here)


# --- persistence -------------------------------------------------------------

## A crop is the only state in this game that advances while the player is
## somewhere else, so it has to be in the save file rather than rebuilt on
## load. VERSION 9.
func test_the_save_format_carries_farm_plots() -> void:
	var save := SAVE_GAME.new("user://test_farming_saves/")
	assert_true(SAVE_GAME.VERSION >= 9, "the farm needs at least save VERSION 9")
	var migrated: Dictionary = save.call("_migrate_v8", {"version": 8})
	assert_eq(int(migrated["version"]), 9)
	assert_true(migrated.has("farm_plots"), "_migrate_v8 wrote no farm_plots key")
	assert_true((migrated["farm_plots"] as Array).is_empty(),
		"a save from before the farm existed must load as unworked ground")
