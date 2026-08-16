extends "res://tests/test_case.gd"

## R2.4's crafting arithmetic: what a recipe costs, whether it can be
## afforded, and what actually happens to the satchel when it is crafted.
##
## Runs against the REAL data/recipes/recipes.json, the same way
## test_inventory.gd runs against the real items.json — a recipe deleted or
## renamed in the data file fails here rather than silently doing nothing at
## the campfire.
##
## `GAME_STATE` is instantiated directly rather than through the autoload:
## `_ready()` mounts the pause menu scene and touches the live tree, neither
## of which a pure-logic test wants. `items`/`inventory` are wired by hand
## instead, which is enough — `craft()`/`can_craft()`/`recipe_cost_for()`
## only ever read those two, never `_menu` or the scene tree.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const GAME_STATE := preload("res://autoload/game_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

## OF30. The one recipe Tam the blacksmith has to teach before it can be made,
## and the flag his second conversation writes. Named here rather than typed
## into six assertions, so renaming either in the data file fails in one place.
const TAUGHT_RECIPE := "orb_basic"
const TAUGHT_FLAG := "recipe_orb_basic"

var db: RefCounted = null
var bag: RefCounted = null
var progression: RefCounted = null
var state: Node = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)
	# OF30: the flag store is wired by hand for the same reason `items` and
	# `inventory` are — `recipe_known()` reads it, and a bare state with no
	# store treats every gated recipe as still locked. Most cases below are
	# about the arithmetic rather than the gate, so the gate is opened here and
	# closed again by the two tests that are actually about it.
	progression = PROGRESSION_STATE.new()
	progression.set_flag(TAUGHT_FLAG)
	state = GAME_STATE.new()
	state.items = db
	state.inventory = bag
	state.progression = progression


func after_each() -> void:
	if state != null:
		state.free()


func test_the_two_base_recipes_are_defined() -> void:
	for id in ["orb_basic", "potion_small"]:
		var recipe: Dictionary = db.recipe(id)
		assert_false(recipe.is_empty(), "recipes.json is missing '%s'" % id)
		assert_true(recipe.has("cost"), "'%s' names no cost" % id)
		assert_true(recipe.has("output"), "'%s' names no output" % id)


## GAME_DESIGN.md 15 / MEADOWS_PROGRESSION_SPEC.md 10: wood, stone, fiber and
## berries, nothing else, for the BASE tier -- `orb_basic`/`potion_small`,
## the two recipes `data/recipes/recipes.json` itself defines. SD18's
## Rootstone tier lives in a separate file on purpose (that file's own
## `_comment_scope`) precisely so it can cost Rootstone without this test
## flagging it as a violation; named explicitly here rather than filtered out
## of `db.recipe_ids()` by convention, so the base tier staying baseline-only
## is still checked for exactly what it always was.
const BASE_TIER_RECIPES := ["orb_basic", "potion_small"]

## SD18: the Rootstone tier's own recipes, named once here so the tests below
## don't each re-list them and drift apart if a fifth is ever added.
const ROOTSTONE_TIER_RECIPES := ["orb_greater", "reinforce_axe", "reinforce_pickaxe", "saddle_frame"]
## SF31, data/recipes/recipes_ironwood.json -- the second and last tier.
const IRONWOOD_TIER_RECIPES := ["orb_prime", "ironwood_haft_axe", "ironwood_haft_pickaxe", "potion_large"]


func test_recipes_only_use_baseline_materials() -> void:
	const ALLOWED := ["wood", "stone", "fiber", "berries"]
	for id in BASE_TIER_RECIPES:
		var recipe: Dictionary = db.recipe(id)
		for requirement in (recipe.get("cost", []) as Array):
			var ingredient := str((requirement as Dictionary).get("id", ""))
			assert_true(ALLOWED.has(ingredient),
				"'%s' costs '%s', which is not a baseline material" % [id, ingredient])


## Every recipe's cost names a real satchel item, whatever tier it belongs
## to -- unlike the baseline-materials test above, this runs over every
## recipe in the merged book (`db.recipe_ids()`), base tier and Rootstone
## tier alike.
func test_recipe_cost_only_names_real_items() -> void:
	for id in db.recipe_ids():
		var recipe: Dictionary = db.recipe(str(id))
		for requirement in (recipe.get("cost", []) as Array):
			var entry := requirement as Dictionary
			var ingredient := str(entry.get("id", ""))
			assert_true(db.has(ingredient), "'%s' costs unknown item '%s'" % [id, ingredient])
			assert_true(int(entry.get("n", 0)) > 0, "'%s' costs zero or fewer '%s'" % [id, ingredient])


## SD18: a `reinforce` recipe (see `recipes_rootstone.json`) upgrades a tool
## already in the satchel instead of granting a new item, so it carries no
## `output` at all -- skipped here, and covered by its own tests below
## instead.
func test_recipe_output_is_a_real_item() -> void:
	for id in db.recipe_ids():
		var recipe: Dictionary = db.recipe(str(id))
		if not (recipe.get("reinforce", {}) as Dictionary).is_empty():
			continue
		var output: Dictionary = recipe.get("output", {})
		var output_id := str(output.get("id", ""))
		assert_true(db.has(output_id), "'%s' produces unknown item '%s'" % [id, output_id])
		assert_true(int(output.get("n", 0)) > 0, "'%s' produces zero or fewer" % id)


func test_recipe_cost_for_matches_the_data_file() -> void:
	var cost: Array = state.recipe_cost_for("orb_basic")
	assert_false(cost.is_empty(), "orb_basic should cost something")
	assert_eq(cost, db.recipe("orb_basic").get("cost", []))


func test_recipe_cost_for_unknown_recipe_is_empty() -> void:
	assert_eq(state.recipe_cost_for("not_a_real_recipe"), [])


func test_cannot_craft_with_an_empty_satchel() -> void:
	assert_false(state.can_craft("orb_basic"))
	assert_false(state.can_craft("potion_small"))


func test_can_craft_once_every_ingredient_is_in_hand() -> void:
	for requirement in state.recipe_cost_for("orb_basic"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.can_craft("orb_basic"))


func test_can_craft_is_false_short_of_even_one_ingredient() -> void:
	var cost: Array = state.recipe_cost_for("orb_basic")
	for i in cost.size():
		var requirement := cost[i] as Dictionary
		var short: int = int(requirement.get("n", 0)) - 1
		if short > 0:
			bag.add(str(requirement.get("id", "")), short)
	assert_false(state.can_craft("orb_basic"), "one ingredient short must refuse the whole craft")


func test_can_craft_refuses_an_unknown_recipe_however_rich_you_are() -> void:
	bag.add("wood", 999)
	bag.add("stone", 999)
	bag.add("fiber", 999)
	bag.add("berries", 999)
	assert_false(state.can_craft("legendary_orb"))


func test_craft_spends_the_cost_and_grants_the_output() -> void:
	for requirement in state.recipe_cost_for("potion_small"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_eq(bag.count("potion_small"), 0)

	assert_true(state.craft("potion_small"))
	assert_eq(bag.count("potion_small"), 1)
	for requirement in db.recipe("potion_small").get("cost", []):
		var entry := requirement as Dictionary
		assert_eq(bag.count(str(entry.get("id", ""))), 0,
			"'%s' should have been fully spent" % str(entry.get("id", "")))


func test_craft_fails_all_or_nothing_when_short() -> void:
	# One wood short of orb_basic's cost. A craft that ate the fiber anyway and
	# then refused would be a satchel silently losing materials for nothing.
	var cost: Array = state.recipe_cost_for("orb_basic")
	for requirement in cost:
		var entry := requirement as Dictionary
		var id := str(entry.get("id", ""))
		var need := int(entry.get("n", 0))
		bag.add(id, need - 1 if id == str((cost[0] as Dictionary).get("id", "")) else need)

	var before := {}
	for requirement in cost:
		var id: String = str((requirement as Dictionary).get("id", ""))
		before[id] = bag.count(id)

	assert_false(state.craft("orb_basic"))
	for requirement in cost:
		var id: String = str((requirement as Dictionary).get("id", ""))
		assert_eq(bag.count(id), int(before[id]), "'%s' must be untouched by a failed craft" % id)


func test_craft_never_touches_free_build() -> void:
	# docs/decisions/D16 scopes free_build to BUILDING costs. Crafting has its
	# own materials loop and must not become a second, undocumented cheat.
	state.free_build = true
	assert_false(state.can_craft("orb_basic"), "free_build must not waive crafting costs")


## --- OF30: what Tam has to teach you before you can make it ------------------

## Owner-reported: "Then he'll give you the recipe for basic orbs." The gate is
## a plain progression flag named by the recipe itself (recipes.json's
## `unlocked_by`); see docs/decisions/D43.
func test_the_orb_recipe_names_the_flag_that_unlocks_it() -> void:
	assert_eq(db.recipe_unlock_flag(TAUGHT_RECIPE), TAUGHT_FLAG,
		"recipes.json's '%s' should wait on '%s'" % [TAUGHT_RECIPE, TAUGHT_FLAG])


func test_a_recipe_with_no_unlock_flag_is_known_from_the_first_minute() -> void:
	assert_eq(db.recipe_unlock_flag("potion_small"), "",
		"potion_small is nobody's to hand over and must not be gated")
	progression.set_flag(TAUGHT_FLAG, false)
	assert_true(state.recipe_known("potion_small"))


func test_the_orb_recipe_is_unknown_until_the_flag_is_set() -> void:
	progression.set_flag(TAUGHT_FLAG, false)
	assert_false(state.recipe_known(TAUGHT_RECIPE))
	progression.set_flag(TAUGHT_FLAG)
	assert_true(state.recipe_known(TAUGHT_RECIPE))


## The gate is a real refusal, not just a hidden row. A full satchel and an
## untaught recipe still make nothing.
func test_an_untaught_recipe_refuses_however_full_the_satchel_is() -> void:
	progression.set_flag(TAUGHT_FLAG, false)
	for requirement in db.recipe(TAUGHT_RECIPE).get("cost", []):
		bag.add(str((requirement as Dictionary).get("id", "")), 99)
	assert_false(state.can_craft(TAUGHT_RECIPE), "an untaught recipe must refuse")
	assert_false(state.craft(TAUGHT_RECIPE), "an untaught recipe must craft nothing")
	assert_eq(bag.count("orb_basic"), 0)


## And once taught, it crafts — the other half of OF30's "the orb recipe
## unlocks and crafts" done-when.
func test_once_taught_the_orb_recipe_crafts() -> void:
	for requirement in state.recipe_cost_for(TAUGHT_RECIPE):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.can_craft(TAUGHT_RECIPE))
	assert_true(state.craft(TAUGHT_RECIPE))
	assert_eq(bag.count("orb_basic"), 1)


func test_the_known_list_grows_by_exactly_the_taught_recipe() -> void:
	progression.set_flag(TAUGHT_FLAG, false)
	var locked: Array = state.known_recipe_ids()
	assert_false(locked.has(TAUGHT_RECIPE), "the orb recipe should not be listed before it is taught")
	assert_true(locked.has("potion_small"), "the craft screen must never be empty")

	progression.set_flag(TAUGHT_FLAG)
	var unlocked: Array = state.known_recipe_ids()
	assert_true(unlocked.has(TAUGHT_RECIPE))
	assert_eq(unlocked.size(), locked.size() + 1, "one flag should unlock exactly one recipe")


## A state with no flag store at all cannot answer "have you been taught this",
## and must not guess yes -- see recipe_known()'s own comment.
func test_a_state_with_no_flag_store_treats_a_gated_recipe_as_locked() -> void:
	state.progression = null
	assert_false(state.recipe_known(TAUGHT_RECIPE))
	assert_true(state.recipe_known("potion_small"), "an ungated recipe needs no store to be known")


func test_every_unlock_flag_named_by_a_recipe_is_actually_written_by_something() -> void:
	# A recipe gated behind a flag nothing ever sets is a recipe that is
	# unreachable forever, and it fails silently: the craft screen simply never
	# grows the row. Checked against the dialogue table, which is where every
	# `flag:` effect in the game lives today.
	const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
	var written: Array[String] = []
	for id: String in RUNNER.table():
		var conversation: Dictionary = RUNNER.table()[id]
		for raw: Variant in conversation.get("lines", []) as Array:
			if not raw is Dictionary:
				continue
			var line: Dictionary = raw
			var effects: Array = (line.get("effects", []) as Array).duplicate()
			if str(line.get("effect", "")) != "":
				effects.append(str(line["effect"]))
			for effect: Variant in effects:
				var parts: Array = RUNNER.parse_effect(str(effect))
				if str(parts[0]) == "flag":
					written.append(str(parts[1]))

	for id in db.recipe_ids():
		var flag: String = str(db.recipe_unlock_flag(str(id)))
		if flag == "":
			continue
		assert_true(written.has(flag),
			"recipe '%s' waits on flag '%s', which no conversation ever sets" % [id, flag])


## --- SD18: the Rootstone tier (data/recipes/recipes_rootstone.json) --------

func test_the_rootstone_tier_recipes_are_defined() -> void:
	for id in ROOTSTONE_TIER_RECIPES:
		var recipe: Dictionary = db.recipe(id)
		assert_false(recipe.is_empty(), "recipes_rootstone.json is missing '%s'" % id)
		assert_true(recipe.has("cost"), "'%s' names no cost" % id)


## Every recipe in this tier costs Rootstone -- otherwise it does not belong
## here, per SD18's own done-when ("every recipe that consumes Rootstone
## improves something the player already owns").
func test_every_rootstone_tier_recipe_actually_costs_rootstone() -> void:
	for id in ROOTSTONE_TIER_RECIPES:
		var names_rootstone := false
		for requirement in (db.recipe(id).get("cost", []) as Array):
			if str((requirement as Dictionary).get("id", "")) == "rootstone":
				names_rootstone = true
		assert_true(names_rootstone, "'%s' does not cost rootstone" % id)


## Unlike orb_basic (Tam has to teach it), nothing in this tier waits on a
## flag -- recipes_rootstone.json's own `_comment_unlock` makes owning
## Rootstone itself the real gate. Checked against a state that has never had
## ANY flag set, so this is not just "no flag happens to be set right now".
func test_the_rootstone_tier_needs_no_unlock_flag() -> void:
	for id in ROOTSTONE_TIER_RECIPES:
		assert_eq(db.recipe_unlock_flag(id), "",
			"'%s' should be known from the first minute, gated by owning Rootstone" % id)
		assert_true(state.recipe_known(id), "'%s' must be known with no flag ever set" % id)


## R4.9 shipped `orb_greater` (the tier ladder's mechanic and item) with no
## way to actually make one, naming this exact recipe as the thing that would
## close that gap. Closed: crafting it produces a real orb_greater that
## catch_math.gd's tier ladder correctly ranks above orb_basic.
func test_orb_greater_is_craftable_and_reaches_the_tier_ladder() -> void:
	const CATCH := preload("res://scripts/combat/catch_math.gd")
	for requirement in state.recipe_cost_for("orb_greater"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.can_craft("orb_greater"))
	assert_true(state.craft("orb_greater"))
	assert_eq(bag.count("orb_greater"), 1)
	assert_eq(CATCH.best_orb({"orb_basic": 3, "orb_greater": 1}), "orb_greater",
		"a crafted orb_greater should outrank orb_basic the same way a found one would")


## `saddle_frame` the recipe makes `saddle_frame` the item -- R6.2's future
## saddle recipe has something real to consume once it exists.
func test_saddle_frame_recipe_crafts_a_real_saddle_frame() -> void:
	for requirement in state.recipe_cost_for("saddle_frame"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.craft("saddle_frame"))
	assert_eq(bag.count("saddle_frame"), 1)


## --- SD18: reinforced tools (inventory.gd::reinforce_tool) -----------------

## The whole point of a `reinforce` recipe: it does not add a new item to the
## satchel, it raises the ceiling on the tool already there and tops it up to
## match, in one step.
func test_reinforce_axe_raises_durability_ceiling_and_tops_up() -> void:
	bag.add("axe", 1)
	for requirement in state.recipe_cost_for("reinforce_axe"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	var slot: int = bag.find_slot("axe")
	var base_max: int = bag.max_durability_at(slot)

	assert_true(state.can_craft("reinforce_axe"))
	assert_true(state.craft("reinforce_axe"))

	assert_eq(bag.count("axe"), 1, "reinforcing must not duplicate the tool")
	assert_eq(bag.max_durability_at(slot), base_max + 20)
	assert_eq(bag.durability_at(slot), base_max + 20, "a fresh axe reinforced should end up full at the new max")


## A worn tool is topped up by the bonus relative to where it WAS, not reset
## to the new max -- reinforcing is not a free repair in disguise.
func test_reinforce_pickaxe_tops_up_from_current_durability_not_from_full() -> void:
	bag.add("pickaxe", 1)
	var slot: int = bag.find_slot("pickaxe")
	bag.damage_tool(slot, 30)
	var worn: int = bag.durability_at(slot)
	assert_true(worn < bag.max_durability_at(slot))

	for requirement in state.recipe_cost_for("reinforce_pickaxe"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.craft("reinforce_pickaxe"))

	assert_eq(bag.durability_at(slot), worn + 20)


## Rootstone and wood in hand are not enough on their own -- there has to be
## an axe to reinforce, the same way `orb_basic` refuses without fiber.
func test_reinforce_axe_refuses_without_owning_an_axe() -> void:
	for requirement in state.recipe_cost_for("reinforce_axe"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_false(state.can_craft("reinforce_axe"), "no axe in the satchel should refuse the reinforce")
	assert_false(state.craft("reinforce_axe"))
	assert_eq(bag.count("rootstone"), int(state.recipe_cost_for("reinforce_axe")[0].get("n", 0)),
		"a refused craft must not have spent anything")


## Short of Rootstone, a reinforce refuses the same all-or-nothing way any
## other recipe does, and touches neither the satchel nor the tool.
func test_reinforce_axe_fails_all_or_nothing_when_short_of_rootstone() -> void:
	bag.add("axe", 1)
	bag.add("wood", 2)  # the recipe's wood cost, in full -- only rootstone is short
	var slot: int = bag.find_slot("axe")
	var before_max: int = bag.max_durability_at(slot)

	assert_false(state.can_craft("reinforce_axe"))
	assert_false(state.craft("reinforce_axe"))

	assert_eq(bag.count("wood"), 2, "a refused craft must not spend the wood it did have")
	assert_eq(bag.max_durability_at(slot), before_max, "a refused reinforce must not touch the tool")


## --- SF31: the Ironwood tier (data/recipes/recipes_ironwood.json) ----------

func test_the_ironwood_tier_recipes_are_defined() -> void:
	for id in IRONWOOD_TIER_RECIPES:
		var recipe: Dictionary = db.recipe(id)
		assert_false(recipe.is_empty(), "recipes_ironwood.json is missing '%s'" % id)
		assert_true(recipe.has("cost"), "'%s' names no cost" % id)


func test_every_ironwood_tier_recipe_actually_costs_ironwood() -> void:
	for id in IRONWOOD_TIER_RECIPES:
		var names_ironwood := false
		for requirement in (db.recipe(id).get("cost", []) as Array):
			if str((requirement as Dictionary).get("id", "")) == "ironwood":
				names_ironwood = true
		assert_true(names_ironwood, "'%s' does not cost ironwood" % id)


func test_the_ironwood_tier_needs_no_unlock_flag() -> void:
	for id in IRONWOOD_TIER_RECIPES:
		assert_eq(db.recipe_unlock_flag(id), "",
			"'%s' should be known from the first minute, gated by owning Ironwood" % id)
		assert_true(state.recipe_known(id), "'%s' must be known with no flag ever set" % id)


## SF31's DONE-WHEN, asserted directly and over the WHOLE recipe book rather
## than one tier: spec §10 lists exactly six materials for the Meadows
## (wood/stone/fiber/berries baseline, rootstone, ironwood) plus items crafted
## from them. A seventh gathered material appearing in any cost -- the "third
## new material" SF31 exists to prevent -- fails here, whichever file added it.
func test_no_recipe_anywhere_needs_a_third_progression_material() -> void:
	const MATERIALS := ["wood", "stone", "fiber", "berries", "rootstone", "ironwood"]
	# Ids a recipe may legitimately cost that are NOT raw materials: things the
	# player crafts or is handed. Kept explicit so a genuinely new material
	# cannot hide in it.
	const CRAFTED_OR_GIVEN := ["saddle_frame", "orb_basic", "orb_greater", "orb_prime",
		"potion_small", "potion_large", "revive", "coin", "axe", "pickaxe", "hammer",
		"knife", "fishing_rod"]
	for id in db.recipe_ids():
		for requirement in (db.recipe(str(id)).get("cost", []) as Array):
			var ingredient := str((requirement as Dictionary).get("id", ""))
			assert_true(MATERIALS.has(ingredient) or CRAFTED_OR_GIVEN.has(ingredient),
				"'%s' costs '%s', a material outside spec §10's list -- SF31's done-when is that nothing needed for the stronghold requires a third new material" % [id, ingredient])


## The three recipe files are merged into one book by item_db.gd, and a
## duplicate id would silently let whichever merged last win. Asserted here
## rather than growing a runtime conflict check.
func test_no_recipe_id_is_defined_in_two_tier_files() -> void:
	var seen: Array[String] = []
	for path in ["res://data/recipes/recipes.json", "res://data/recipes/recipes_rootstone.json",
			"res://data/recipes/recipes_ironwood.json"]:
		var file := FileAccess.open(path, FileAccess.READ)
		assert_true(file != null, "%s is missing" % path)
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		assert_true(parsed is Dictionary, "%s is not a JSON object" % path)
		for id: Variant in ((parsed as Dictionary).get("recipes", {}) as Dictionary):
			assert_false(seen.has(str(id)), "recipe '%s' is defined in two files" % str(id))
			seen.append(str(id))


func test_orb_prime_is_craftable_and_tops_the_tier_ladder() -> void:
	const CATCH := preload("res://scripts/combat/catch_math.gd")
	for requirement in state.recipe_cost_for("orb_prime"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.can_craft("orb_prime"))
	assert_true(state.craft("orb_prime"))
	assert_eq(bag.count("orb_prime"), 1)
	assert_eq(CATCH.best_orb({"orb_basic": 3, "orb_greater": 2, "orb_prime": 1}), "orb_prime",
		"a crafted orb_prime should outrank both tiers under it")


func test_the_ridge_tonic_crafts_and_heals_more_than_a_small_potion() -> void:
	for requirement in state.recipe_cost_for("potion_large"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.craft("potion_large"))
	assert_eq(bag.count("potion_large"), 1)
	assert_true(int(db.definition("potion_large").get("heal", 0)) > int(db.definition("potion_small").get("heal", 0)),
		"the Band 4 tonic must actually be the bigger dose, or the recipe is decoration")


## The Ironwood haft is the SECOND rung on the same tool: reinforcing stacks
## on top of the Rootstone tier rather than replacing it (recipes_ironwood's
## own comment says so), so an axe worked through both tiers ends at
## base + 20 + 30.
func test_the_two_tool_tiers_stack_on_the_same_axe() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	var base_max: int = bag.max_durability_at(slot)
	for requirement in state.recipe_cost_for("reinforce_axe"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.craft("reinforce_axe"))
	for requirement in state.recipe_cost_for("ironwood_haft_axe"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.craft("ironwood_haft_axe"))
	assert_eq(bag.count("axe"), 1, "reinforcing must never duplicate the tool")
	assert_eq(bag.max_durability_at(slot), base_max + 20 + 30)


func test_the_ironwood_haft_refuses_without_owning_the_tool() -> void:
	for requirement in state.recipe_cost_for("ironwood_haft_pickaxe"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_false(state.can_craft("ironwood_haft_pickaxe"), "no pickaxe should refuse the reinforce")
	assert_false(state.craft("ironwood_haft_pickaxe"))
	assert_eq(bag.count("ironwood"), int(state.recipe_cost_for("ironwood_haft_pickaxe")[0].get("n", 0)),
		"a refused craft must not have spent anything")


## SF31's source half: ironwood is a real gathered resource with real nodes in
## the world, felled with the axe. A tier with recipes and no deposits is a
## craft screen full of rows nobody can fill.
func test_ironwood_is_gathered_with_the_axe_and_really_grows_somewhere() -> void:
	assert_eq(str(db.definition("ironwood").get("gathered_with", "")), "axe")
	var file := FileAccess.open("res://data/config/harvest.json", FileAccess.READ)
	assert_true(file != null, "harvest.json is missing")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var stands := 0
	for raw: Variant in ((parsed as Dictionary).get("nodes", []) as Array):
		if str((raw as Dictionary).get("item", "")) == "ironwood":
			stands += 1
	assert_true(stands >= 3, "only %d ironwood nodes stand in the world" % stands)
