extends "res://tests/test_case.gd"

## R7.5: food buffs, driven by the real item data rather than a synthetic
## dict. `test_player_vitals.gd` already proves player_vitals.gd's own
## eat()/buff arithmetic in isolation; this file proves the OTHER half —
## that data/items/items.json's food entries and the real ItemDB actually
## produce sane input to that arithmetic, and that the whole path never
## opens a door to starvation death (GAME_DESIGN.md: "No starvation death",
## D29: satiety only ever softens, never kills).

const VITALS := preload("res://scripts/player/player_vitals.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

var _vitals: RefCounted
var _db: RefCounted


func before_each() -> void:
	_vitals = VITALS.new()
	_vitals.configure({
		"stamina": {"max": 100.0, "sprint_drain_per_second": 10.0, "jump_cost": 8.0,
			"regen_per_second": 20.0, "regen_delay": 1.0, "exhausted_below": 10.0},
		"health": {"max": 100.0},
		"fall_damage": {"safe_speed": 12.0, "lethal_speed": 32.0, "curve": 2.0, "max_damage": 100.0},
	})
	_vitals.configure_satiety(_read_vitals_config())
	_db = ITEM_DB.new()


func _read_vitals_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/vitals.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


## Every item.json entry marked "food" must actually restore satiety. A food
## item with no satiety value would be indistinguishable from any other prop
## and silently do nothing when eaten.
func test_every_food_item_restores_satiety() -> void:
	var saw_a_food_item := false
	for id in _db.ids():
		if _db.kind(str(id)) != "food":
			continue
		saw_a_food_item = true
		var def: Dictionary = _db.definition(str(id))
		assert_true(float(def.get("satiety", 0.0)) > 0.0,
			"%s is kind=food but restores no satiety" % id)
	assert_true(saw_a_food_item, "no food-kind item found in items.json -- nothing to test")


## The real berries entry, fed through the real vitals object with the same
## arguments the UI passes: satiety first, then the buff.
##
## T5-CARE: this comment used to claim the call was made "exactly the way
## tab_backpack.gd's _read_use() does it", and that claim is what let a real
## defect ship under a green test. It was never true of the ROUTE — D68 gave
## berries a `creature_food` key, `_read_use()` tests that before `satiety`, and
## berries are the only item in the game with a satiety value, so from the
## Satchel the player could not eat at all while every assertion here passed.
## A test that calls `eat()` proves the arithmetic and says nothing about
## whether a player can reach it. `tests/smoke_backpack_player_eats.gd` is the
## one that proves the route, with real joypad presses through the real tab;
## this file deliberately stays the arithmetic half and must not be read as
## covering reachability.
func test_eating_real_berries_restores_satiety_and_applies_its_buff() -> void:
	var def: Dictionary = _db.definition("berries")
	assert_eq(str(def.get("kind", "")), "food", "berries must stay a food item")

	_vitals.satiety = 50.0
	var satiety_amount := float(def.get("satiety", 0.0))
	_vitals.call("eat", satiety_amount, def.get("buff", {}))

	assert_almost_eq(_vitals.satiety, 50.0 + satiety_amount, 0.001)

	var buff: Dictionary = def.get("buff", {})
	if not buff.is_empty():
		assert_eq(_vitals.active_buffs.size(), 1, "eating a food item with a buff should apply exactly one")
		assert_eq(_vitals.active_buffs[0]["id"], buff.get("id", ""))
		assert_almost_eq(_vitals.stamina_regen_scale(), float(buff.get("amount", 1.0)), 0.001)


## D29 / GAME_DESIGN.md: satiety softens, it never kills. Whatever the real
## food data says, running satiety to zero and never eating again must never
## produce a dead player.
func test_never_eating_never_kills_the_player() -> void:
	_vitals.tick_satiety(1_000_000.0)
	assert_eq(_vitals.satiety, 0.0)
	assert_false(_vitals.is_dead(), "satiety reaching zero must never be lethal")
	assert_eq(_vitals.health, 100.0, "starvation must never cost health")
	assert_eq(_vitals.hunger_state(), "critical")


## The critical-hunger debuff is real (softer, not fatal) and a real food
## item's buff can still stack on top of it, matching player_vitals.gd's own
## documented multiplier order.
func test_critical_hunger_debuff_survives_alongside_a_real_food_buff() -> void:
	_vitals.tick_satiety(1_000_000.0)   # drive satiety to 0 / "critical"
	var def: Dictionary = _db.definition("berries")
	_vitals.call("eat", float(def.get("satiety", 0.0)), def.get("buff", {}))

	# The eat() call itself raises satiety back out of "critical" for a real
	# food item's restore amount, so this checks the buff multiplies whatever
	# tier the fresh satiety lands in -- never a fixed 1.0 regardless of hunger.
	var expected_tier_scale: float = 1.0 if _vitals.hunger_state() == "ok" else (
		0.6 if _vitals.hunger_state() == "hungry" else 0.35)
	var buff_amount: float = float(def.get("buff", {}).get("amount", 1.0))
	assert_almost_eq(_vitals.stamina_regen_scale(), expected_tier_scale * buff_amount, 0.001)
