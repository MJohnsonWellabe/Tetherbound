extends TestCase

## The trainer's bag, their five equipment slots, and what eating does.
##
## `tests/test_inventory.gd` already proves the container — slots, stacks,
## all-or-nothing adds, durability, free repair. Nothing here re-tests any of
## that. What is under test is the M9 layer on top: the interface other systems
## call by name, the food buffs, the armour slots, and the one rule that has to
## survive every future edit — THERE IS NO HUNGER.
##
## Node-free wherever the rules are node-free (D02). `TrainerInventory` is a Node
## because it has to be in the scene and in the save file, so the tests that need
## one build it with `.new()` and never a scene; `equipment.gd` and
## `player_vitals.gd` are RefCounted and need nothing at all.

const BAG := preload("res://scripts/player/trainer_inventory.gd")
const EQUIPMENT := preload("res://scripts/player/equipment.gd")
const INVENTORY := preload("res://scripts/items/inventory.gd")
const VITALS := preload("res://scripts/player/player_vitals.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")

const SURVIVAL_PATH := "res://data/config/survival.json"

var _bag: Node = null


func before_each() -> void:
	_bag = BAG.new()
	# `_ready()` is what builds the inventory and hands over the starting kit, and
	# it does not run for a node that is never added to a tree. Called directly so
	# every test below starts from the state a new game starts from.
	_bag._ready()


func after_each() -> void:
	if _bag != null:
		_bag.free()
		_bag = null


func _config() -> Dictionary:
	var file := FileAccess.open(SURVIVAL_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


# --- the interface other systems were written against ------------------------

## M8's gathering and its build costs were written against these five names
## before this file existed. A rename is a silent breakage in somebody else's
## milestone, so the contract is a test rather than a comment.
func test_the_interface_other_systems_call_exists_by_name() -> void:
	for method: String in ["inventory", "add", "remove", "count_of", "last_refusal"]:
		assert_true(_bag.has_method(method), "TrainerInventory lost %s()" % method)


func test_inventory_hands_back_the_container_itself() -> void:
	var held: RefCounted = _bag.inventory()
	assert_ne(held, null)
	assert_true(held.has_method("slot_count"), "inventory() did not return an inventory")
	# The SAME object every time. A new one per call would give every caller its
	# own bag and the player's wood would land in whichever one asked last.
	assert_eq(_bag.inventory(), held)


func test_adding_and_spending_go_through_the_same_bag() -> void:
	assert_true(bool(_bag.add("wood", 12)))
	assert_eq(_bag.count_of("wood"), 12)
	assert_true(bool(_bag.remove("wood", 5)))
	assert_eq(_bag.count_of("wood"), 7)
	# What a build cost sees when it asks the container directly rather than the
	# node — the two must never be able to disagree.
	assert_eq(int(_bag.inventory().count_of("wood")), 7)


func test_a_refusal_says_why_and_is_forgotten_afterwards() -> void:
	assert_false(bool(_bag.remove("wood", 1)), "spent wood it did not have")
	assert_eq(_bag.last_refusal(), INVENTORY.REFUSED_NOT_ENOUGH)
	assert_true(bool(_bag.add("wood", 1)))
	# A stale reason is worse than none: a UI reading `last_refusal()` after a
	# success would explain a failure that did not happen.
	assert_eq(_bag.last_refusal(), "")


func test_no_refusal_this_file_can_produce_is_about_weight() -> void:
	# The same tripwire `tests/test_inventory.gd` puts on the container, on the
	# layer above it. CLAUDE.md forbids a carry-weight system twice over, and a
	# banned system does not come back under its own name — it comes back as "too
	# heavy to carry" in a refusal token nobody reviewed.
	var tokens: Array = [
		BAG.REFUSED_EMPTY_SLOT, BAG.REFUSED_NOT_FOOD, BAG.REFUSED_NO_TRAINER,
		BAG.REFUSED_BAD_FOOD_DATA, BAG.REFUSED_NOT_DURABLE, BAG.REFUSED_NOT_AT_HOME,
	]
	tokens.append_array(EQUIPMENT.REFUSALS)
	for entry: Variant in tokens:
		var token := str(entry)
		for banned: String in ["weight", "heavy", "mass", "bulk", "encumb", "overload"]:
			assert_false(token.contains(banned), "refusal '%s' is about carry weight" % token)


# --- the starting kit ---------------------------------------------------------

func test_a_new_game_starts_with_the_kit_from_the_config() -> void:
	var kit: Dictionary = _config().get("starting_kit", {}).get("items", {})
	assert_false(kit.is_empty(), "survival.json declares no starting kit")
	for item_id: String in kit.keys():
		if item_id.begins_with("_"):
			continue
		assert_eq(_bag.count_of(item_id), int(kit[item_id]), "starting kit: %s" % item_id)


func test_the_revival_draughts_recovery_used_to_seed_are_in_the_bag() -> void:
	# `recovery.gd` seeded three draughts into a private bag of its own because
	# nothing in the scene owned an inventory. Its `inventory_path` points here
	# now, so if this is ever zero the pal beds become the only route back from a
	# faint and nobody would notice until they needed one.
	assert_true(_bag.count_of("revival_draught") > 0,
		"the trainer starts with no revival draughts; §16's item route is unreachable")


func test_a_loaded_game_is_not_handed_a_second_kit() -> void:
	_bag.load_data({"slots": [], "worn": []})
	assert_eq(_bag.inventory().used_slots(), 0, "a spent bag came back full of new gear")
	assert_eq(_bag.count_of("axe"), 0)


# --- persistence --------------------------------------------------------------

func test_the_bag_survives_a_save_and_a_load_with_its_wear_intact() -> void:
	_bag.inventory().clear()
	_bag.add("axe", 1)
	_bag.add("berries", 7)
	_bag.use_tool(_slot_of("axe"), 40)
	var worn_to: int = int(_bag.at(_slot_of("axe")).durability)

	var record: Dictionary = _bag.save_data()
	var second: Node = BAG.new()
	second._ready()
	second.load_data(record)
	assert_eq(second.count_of("berries"), 7)
	assert_eq(int(second.at(_slot_of_in(second, "axe")).durability), worn_to,
		"the axe was polished by the save file")
	second.free()


func _slot_of(item_id: String) -> int:
	return _slot_of_in(_bag, item_id)


func _slot_of_in(bag: Node, item_id: String) -> int:
	for i in bag.slot_count():
		var stack: RefCounted = bag.at(i)
		if stack != null and str(stack.item_id) == item_id:
			return i
	return -1


# --- food: a buff, and never a meter -----------------------------------------

func test_berries_are_food_and_say_what_they_do() -> void:
	assert_true(DEFS.is_food("berries"), "berries are not food; §18's buff has nothing to eat")
	var block := DEFS.food("berries")
	assert_true(float(block.get("seconds", 0.0)) > 0.0, "a food with no duration")
	var total := 0.0
	for key: String in VITALS.FOOD_BONUSES:
		total += float(block.get(key, 0.0))
	assert_true(total > 0.0, "eating berries would do nothing at all")


func test_eating_raises_the_ceilings_for_a_while_and_then_stops() -> void:
	var vitals: RefCounted = VITALS.new()
	vitals.configure({})
	var health_before: float = vitals.max_health
	var stamina_before: float = vitals.max_stamina

	assert_true(bool(vitals.eat("berries", {"seconds": 10.0, "max_health": 12.0, "max_stamina": 15.0})))
	assert_almost_eq(vitals.max_health, health_before + 12.0, 0.001)
	assert_almost_eq(vitals.max_stamina, stamina_before + 15.0, 0.001)

	for _i in 11:
		vitals.tick(1.0, false)
	assert_almost_eq(vitals.max_health, health_before, 0.001, "the meal never ended")
	assert_almost_eq(vitals.max_stamina, stamina_before, 0.001)
	assert_false(vitals.is_fed())


func test_a_meal_ending_cannot_kill_you() -> void:
	# The one way a buff could become a penalty: health above the base maximum when
	# the ceiling drops. It clamps DOWN and never below one, because dying to a
	# berry timer is a death nobody could explain.
	var vitals: RefCounted = VITALS.new()
	vitals.configure({})
	vitals.eat("berries", {"seconds": 1.0, "max_health": 20.0})
	vitals.health = vitals.max_health
	vitals.tick(2.0, false)
	assert_true(vitals.health > 0.0, "a food buff running out killed the trainer")
	assert_true(vitals.health <= vitals.max_health, "health is above its own maximum")


func test_eating_the_same_thing_again_refreshes_rather_than_stacks() -> void:
	var vitals: RefCounted = VITALS.new()
	vitals.configure({})
	var base: float = vitals.max_health
	vitals.eat("berries", {"seconds": 10.0, "max_health": 12.0})
	vitals.tick(6.0, false)
	vitals.eat("berries", {"seconds": 10.0, "max_health": 12.0})
	assert_almost_eq(vitals.max_health, base + 12.0, 0.001, "two berries stacked into one ceiling")
	assert_almost_eq(vitals.food_seconds_left("berries"), 10.0, 0.001, "the clock did not reset")
	assert_eq(vitals.food_buffs().size(), 1)


func test_two_different_foods_stack() -> void:
	var vitals: RefCounted = VITALS.new()
	vitals.configure({})
	var base: float = vitals.max_stamina
	vitals.eat("berries", {"seconds": 10.0, "max_stamina": 15.0})
	vitals.eat("something_else", {"seconds": 10.0, "max_stamina": 5.0})
	assert_almost_eq(vitals.max_stamina, base + 20.0, 0.001)
	assert_eq(vitals.food_buffs().size(), 2)


func test_not_eating_costs_nothing_ever() -> void:
	# THE HARD RULE, as a test. CLAUDE.md: "Food buffs; no starvation-death meter",
	# and "adding mandatory hunger/thirst" is on the list of decisions an agent may
	# not take. A trainer who eats nothing for an hour of game time must come out
	# of it with exactly the numbers they went in with.
	var vitals: RefCounted = VITALS.new()
	vitals.configure({})
	var health: float = vitals.health
	var max_health: float = vitals.max_health
	var max_stamina: float = vitals.max_stamina
	for _i in 3600:
		vitals.tick(1.0, false)
	assert_almost_eq(vitals.health, health, 0.001, "something drained health over time")
	assert_almost_eq(vitals.max_health, max_health, 0.001)
	assert_almost_eq(vitals.max_stamina, max_stamina, 0.001)
	assert_false(vitals.is_dead(), "an hour without eating killed the trainer")


func test_nothing_in_the_survival_config_is_a_hunger_meter() -> void:
	# The other half of the tripwire. A starvation system does not arrive named
	# `starvation`; it arrives as `hunger_per_second` in a config nobody reviewed,
	# and one number is all it takes.
	#
	# The COMMENTS are excluded, deliberately: survival.json's `_comment_no_hunger`
	# says at length that there is no hunger block, and a test that failed on the
	# explanation would delete the explanation.
	var text := JSON.stringify(_without_comments(_config())).to_lower()
	assert_false(text.is_empty())
	for banned: String in ["hunger", "starv", "thirst", "satiat", "calorie", "nourish", "decay"]:
		assert_false(text.contains(banned),
			"survival.json declares '%s'; that is the meter CLAUDE.md forbids" % banned)


func _without_comments(entry: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in entry.keys():
		if key.begins_with("_"):
			continue
		var value: Variant = entry[key]
		out[key] = _without_comments(value as Dictionary) if value is Dictionary else value
	return out


func test_eating_spends_exactly_one_and_only_when_it_worked() -> void:
	_bag.inventory().clear()
	_bag.add("berries", 3)
	var slot := _slot_of("berries")
	# No trainer is wired, so the meal cannot land — and the berry must not be
	# eaten anyway. A refusal that still consumes the item is the worst of both.
	assert_false(bool(_bag.eat(slot)))
	assert_eq(_bag.count_of("berries"), 3)
	assert_eq(_bag.last_refusal(), BAG.REFUSED_NO_TRAINER)


func test_a_tool_is_not_food() -> void:
	_bag.inventory().clear()
	_bag.add("axe", 1)
	assert_false(bool(_bag.eat(_slot_of("axe"))))
	assert_eq(_bag.last_refusal(), BAG.REFUSED_NOT_FOOD)


func test_the_revival_draught_is_a_consumable_but_not_a_meal() -> void:
	# §16 spends it on a fainted pal. "Consumable" means used up, not eaten, and
	# the trainer swallowing the party's only way back would be a real loss.
	assert_true(DEFS.is_consumable("revival_draught"))
	assert_false(DEFS.is_food("revival_draught"))


# --- free repair --------------------------------------------------------------

func test_repair_is_free_and_whole() -> void:
	_bag.inventory().clear()
	_bag.add("axe", 1)
	var slot := _slot_of("axe")
	var wood_before: int = _bag.count_of("wood")
	_bag.use_tool(slot, 90)
	assert_true(int(_bag.at(slot).durability) < DEFS.max_durability("axe"))
	assert_true(bool(_bag.repair(slot)))
	assert_eq(int(_bag.at(slot).durability), DEFS.max_durability("axe"))
	# §19: repair is FREE. Nothing may be spent for it, now or later.
	assert_eq(_bag.count_of("wood"), wood_before)


func test_a_broken_tool_is_broken_and_not_gone() -> void:
	# D17: at zero durability a tool keeps its slot and repairs free. A tool that
	# deleted itself would put §19's free repair out of reach precisely when it is
	# needed.
	_bag.inventory().clear()
	_bag.add("axe", 1)
	var slot := _slot_of("axe")
	_bag.use_tool(slot, DEFS.max_durability("axe"))
	assert_ne(_bag.at(slot), null, "the broken axe vanished from the bag")
	assert_true(bool(_bag.at(slot).is_broken()))
	assert_false(bool(_bag.use_tool(slot, 1)), "a broken axe kept chopping")
	assert_true(bool(_bag.repair(slot)))


# --- the five equipment slots -------------------------------------------------

func test_there_are_exactly_the_five_slots_the_design_names() -> void:
	# GAME_DESIGN.md §18: Helmet, Upper body, Lower body, Boots, Backpack. Five,
	# named, and in code rather than in data so a sixth is a conversation.
	assert_eq(EQUIPMENT.SLOTS.size(), 5)
	for slot: String in EQUIPMENT.SLOTS:
		assert_false(EQUIPMENT.slot_name(slot).is_empty(), "slot '%s' has no name" % slot)


func test_the_wardrobe_starts_empty_and_says_so() -> void:
	var equipment: RefCounted = _bag.equipment()
	assert_true(equipment.is_empty())
	assert_eq(equipment.worn_count(), 0)


func test_nothing_in_the_game_can_be_worn_yet_and_the_refusal_says_which_no_it_is() -> void:
	# There is no armour in the Meadows. Every item in both tables must refuse,
	# and refuse as "not wearable" rather than as some accident — the day a garment
	# declares an `equip_slot`, this test starts failing and that is correct.
	var equipment: RefCounted = _bag.equipment()
	for item_id: String in DEFS.ids():
		assert_false(EQUIPMENT.is_wearable(item_id), "%s claims to be armour" % item_id)
		assert_false(equipment.can_equip(item_id))
		assert_eq(equipment.last_refusal(), EQUIPMENT.REFUSED_NOT_WEARABLE)


func test_equipment_declares_no_stats_for_garments_that_do_not_exist() -> void:
	# The milestone asks for "armor slots architecture" — the structure, not
	# invented numbers. A defence value, a resistance or a slot bonus here would be
	# balance for an item nobody has drawn.
	var source := FileAccess.open("res://scripts/player/equipment.gd", FileAccess.READ)
	assert_ne(source, null)
	var text := source.get_as_text().to_lower()
	for banned: String in ["armour_value", "armor_value", "damage_reduction", "resistance ="]:
		assert_false(text.contains(banned), "equipment.gd invented a stat: %s" % banned)


func test_the_wardrobe_survives_a_save_even_though_it_is_empty() -> void:
	var records: Array = _bag.equipment().to_records()
	assert_eq(records.size(), 0)
	var restored: RefCounted = EQUIPMENT.from_records(records)
	assert_true(restored.is_empty())
	assert_eq(restored.slots().size(), 5)


func test_a_garment_in_a_save_naming_a_slot_that_is_gone_costs_one_garment() -> void:
	# Defensive in the same way `inventory.from_records` is: a save file is a text
	# file that will eventually be hand-edited.
	var restored: RefCounted = EQUIPMENT.from_records([
		{"item": "axe", "count": 1, "slot": "tail"},
		{"item": "nonexistent_hat", "count": 1, "slot": EQUIPMENT.SLOT_HEAD},
	])
	assert_true(restored.is_empty(), "a bad equipment record was restored anyway")
	assert_eq(restored.worn_count(), 0)


# --- the item tables are one table -------------------------------------------

func test_the_two_item_files_merge_without_either_losing_anything() -> void:
	# `consumables.json` extends `berries`, which `items.json` declares. The merge
	# has to keep items.json's display name and stack limit AND take the new
	# category and the food block, or one of the two files is quietly ignored.
	assert_eq(DEFS.display_name("berries"), "Berries")
	assert_true(DEFS.stack_limit("berries") > 1, "berries lost their stack limit in the merge")
	assert_eq(DEFS.category("berries"), DEFS.CATEGORY_CONSUMABLE)
	assert_false(DEFS.food("berries").is_empty())


func test_every_item_lands_in_a_category_the_code_knows() -> void:
	for item_id: String in DEFS.ids():
		assert_true(DEFS.CATEGORIES.has(DEFS.category(item_id)),
			"%s is a '%s', which is not a category" % [item_id, DEFS.category(item_id)])


func test_no_comment_key_survives_into_an_item_or_its_food_block() -> void:
	# Both files invite `_comment_<topic>` keys inline. One written a level too
	# high used to become a real item; one written inside a `food` block would
	# become a bonus.
	for item_id: String in DEFS.ids():
		assert_false(item_id.begins_with("_"), "'%s' is a comment, not an item" % item_id)
		for key: String in DEFS.definition(item_id).keys():
			assert_false(key.begins_with("_"), "%s carries a comment key '%s'" % [item_id, key])
		for key: String in DEFS.food(item_id).keys():
			assert_false(key.begins_with("_"), "%s's food block carries '%s'" % [item_id, key])
