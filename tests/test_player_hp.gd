extends "res://tests/test_case.gd"

## R7.7. The trainer's five armour slots (scripts/player/player_equipment.gd)
## and their one real effect today: softening fall damage
## (scripts/player/player_vitals.gd::apply_landing()'s new `defense`
## parameter). Everything here runs against the REAL data/items/items.json,
## the same way tests/test_trade.gd checks trade.json against a real
## item_db.gd -- a typo'd `armor_slot` or a `defense` value that pushes the
## capped total past MAX_TOTAL_DEFENSE fails here, not just in play.

const PLAYER_EQUIPMENT := preload("res://scripts/player/player_equipment.gd")
const VITALS := preload("res://scripts/player/player_vitals.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

const ARMOR_ITEMS := {
	"helmet": "hide_helm",
	"upper_body": "hide_vest",
	"lower_body": "hide_leggings",
	"boots": "hide_boots",
	"backpack": "travel_pack",
}

var _items: RefCounted = null
var _equipment: RefCounted = null


func before_each() -> void:
	_items = ITEM_DB.new()
	_equipment = PLAYER_EQUIPMENT.new()
	_equipment.call("configure", _items)


## --- the five slots, and only the five slots ------------------------------

func test_every_armor_item_names_one_of_the_five_slots() -> void:
	for slot in ARMOR_ITEMS.keys():
		assert_true(bool(_equipment.call("is_slot", slot)),
			"player_equipment.gd's SLOTS is missing '%s'" % slot)
	for item_id: String in ARMOR_ITEMS.values():
		assert_true(bool(_items.call("has", item_id)), "items.json has no '%s'" % item_id)
		var definition: Dictionary = _items.call("definition", item_id)
		assert_eq(str(definition.get("kind", "")), "armor", "'%s' is not kind: armor" % item_id)
		var slot := str(definition.get("armor_slot", ""))
		assert_true(bool(_equipment.call("is_slot", slot)),
			"'%s' names armor_slot '%s', not one of GAME_DESIGN.md sec18's five" % [item_id, slot])


func test_equipping_a_real_piece_fills_its_own_slot() -> void:
	for slot: String in ARMOR_ITEMS.keys():
		var item_id: String = ARMOR_ITEMS[slot]
		var result: Dictionary = _equipment.call("equip", item_id)
		assert_true(bool(result.get("ok", false)), "equip('%s') was refused" % item_id)
		assert_eq(str(_equipment.call("equipped_in", slot)), item_id)


func test_equipping_a_second_piece_in_the_same_slot_displaces_the_first() -> void:
	_equipment.call("equip", "hide_helm")
	var result: Dictionary = _equipment.call("equip", "hide_vest")
	# hide_vest is upper_body, not helmet -- refused, and hide_helm still equipped.
	assert_false(bool(result.get("ok", false)))
	assert_eq(str(_equipment.call("equipped_in", "helmet")), "hide_helm")


func test_unequip_empties_the_slot_and_returns_what_was_there() -> void:
	_equipment.call("equip", "hide_boots")
	var removed := str(_equipment.call("unequip", "boots"))
	assert_eq(removed, "hide_boots")
	assert_eq(str(_equipment.call("equipped_in", "boots")), "")


## --- refusals: no weapon, no shield, no sixth slot ------------------------

func test_refuses_a_non_armor_item() -> void:
	var result: Dictionary = _equipment.call("equip", "axe")
	assert_false(bool(result.get("ok", false)), "a tool is not armour and must not equip")


func test_refuses_an_unknown_item_id() -> void:
	var result: Dictionary = _equipment.call("equip", "shield_of_definitely_not_allowed")
	assert_false(bool(result.get("ok", false)))


func test_unequip_refuses_a_slot_name_outside_the_five() -> void:
	assert_eq(str(_equipment.call("unequip", "weapon_hand")), "",
		"CLAUDE.md: no shields, the human cannot fight -- there is no sixth slot to refuse INTO, only to reject")


## --- total defense: sums, and caps ----------------------------------------

func test_total_defense_is_zero_unequipped() -> void:
	assert_eq(float(_equipment.call("total_defense")), 0.0)


func test_total_defense_sums_every_equipped_piece() -> void:
	var expected := 0.0
	for item_id: String in ARMOR_ITEMS.values():
		_equipment.call("equip", item_id)
		expected += float((_items.call("definition", item_id) as Dictionary).get("defense", 0.0))
	assert_true(expected > 0.0, "items.json's armour pieces all carry defense 0.0 -- nothing to sum")
	var max_defense: float = PLAYER_EQUIPMENT.MAX_TOTAL_DEFENSE
	var want: float = minf(expected, max_defense)
	assert_almost_eq(float(_equipment.call("total_defense")), want, 0.001)


func test_total_defense_never_exceeds_the_cap() -> void:
	for item_id: String in ARMOR_ITEMS.values():
		_equipment.call("equip", item_id)
	var max_defense: float = PLAYER_EQUIPMENT.MAX_TOTAL_DEFENSE
	assert_true(max_defense < 1.0, "armour must never make a fall free -- it softens, it does not shield")
	assert_true(float(_equipment.call("total_defense")) <= max_defense + 0.0001)


## --- the one real consumer: fall damage ------------------------------------

func _vitals() -> RefCounted:
	var vitals: RefCounted = VITALS.new()
	vitals.call("configure", {
		"stamina": {"max": 100.0},
		"health": {"max": 100.0},
		"fall_damage": {"safe_speed": 12.0, "lethal_speed": 32.0, "curve": 2.0, "max_damage": 100.0},
	})
	return vitals


func test_apply_landing_with_no_defense_matches_pre_r7_7_behaviour() -> void:
	var vitals := _vitals()
	var damage: float = vitals.call("apply_landing", 32.0)
	assert_almost_eq(damage, 100.0, 0.01)


func test_apply_landing_with_defense_reduces_damage_by_that_fraction() -> void:
	var vitals := _vitals()
	var undefended: float = vitals.call("apply_landing", 32.0)
	vitals = _vitals()
	var defended: float = vitals.call("apply_landing", 32.0, 0.5)
	assert_almost_eq(defended, undefended * 0.5, 0.01)


func test_a_full_armor_set_still_lets_a_lethal_fall_hurt() -> void:
	_equipment.call("equip", "hide_helm")
	_equipment.call("equip", "hide_vest")
	_equipment.call("equip", "hide_leggings")
	_equipment.call("equip", "hide_boots")
	_equipment.call("equip", "travel_pack")
	var defense: float = _equipment.call("total_defense")
	var vitals := _vitals()
	var damage: float = vitals.call("apply_landing", 32.0, defense)
	assert_true(damage > 0.0, "a full set must soften a lethal fall, not remove its danger -- no shields")
	assert_true(damage < 100.0, "armour with a positive defense value did nothing")


func test_defense_argument_is_clamped_so_a_bad_caller_cannot_invert_damage() -> void:
	var vitals := _vitals()
	var damage: float = vitals.call("apply_landing", 32.0, 1.5)
	assert_true(damage >= 0.0, "a defense fraction above 1.0 must clamp, never go negative/heal on landing")
