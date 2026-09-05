extends "res://tests/test_case.gd"

## Candy progression safety (docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md §B):
## the level cap clamps WITH a visible message rather than silent waste; +2/+3
## across the cap grants what it can and says so; a candy cannot go to a
## fainted creature; and Rare Candy is ONE `level_up` on the feed with
## `levels_gained == 3` -- the same event a fight produces (§A2: "candy level
## gains use the same core feedback language rather than a separate silent
## path"). Everything runs the real instance and the real Satchel-screen
## eligibility/message code; nothing greps a script.

const FEED := preload("res://scripts/creatures/progression_feed.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BACKPACK := preload("res://scripts/ui/tab_backpack.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}


func before_each() -> void:
	FEED.clear()


func _creature() -> RefCounted:
	return CREATURE.from_species("terrapup", DEFINITION)


func _cfg() -> Dictionary:
	return PROGRESSION.config()


func _cap() -> int:
	return int(_cfg().get("level", {}).get("cap", 50))


func _candy_levels(id: String) -> int:
	var db := ITEM_DB.new()
	return int((db.call("definition", id) as Dictionary).get("level_up", 0))


## A Satchel screen with the Rare Candy picker armed, never added to a tree:
## `_eligible()` / `_ineligible_reason()` read `_targeting_level_up` and the
## creature alone.
func _armed_backpack(candy_id: String) -> Object:
	var tab: Object = BACKPACK.new()
	tab.set("_targeting_level_up", candy_id)
	return tab


# --- the shipped items ------------------------------------------------------------

func test_the_three_candies_grant_one_two_and_three_levels() -> void:
	assert_eq(_candy_levels("good_candy"), 1)
	assert_eq(_candy_levels("great_candy"), 2)
	assert_eq(_candy_levels("rare_candy"), 3)


# --- the cap clamps, and says so ----------------------------------------------------

func test_a_rare_candy_one_below_the_cap_grants_one_level_and_stops_at_the_cap() -> void:
	var c := _creature()
	c.set_level(_cap() - 1, _cfg())
	var gained: int = c.gain_levels(3, _cfg())
	assert_eq(gained, 1, "+3 across the cap grants only what fits")
	assert_eq(int(c.level), _cap(), "and never passes the cap")


func test_a_great_candy_two_below_the_cap_grants_both() -> void:
	var c := _creature()
	c.set_level(_cap() - 2, _cfg())
	assert_eq(c.gain_levels(2, _cfg()), 2)
	assert_eq(int(c.level), _cap())


func test_a_candy_at_the_cap_grants_nothing_and_pushes_nothing() -> void:
	var c := _creature()
	c.set_level(_cap(), _cfg())
	FEED.clear()
	assert_eq(c.gain_levels(3, _cfg()), 0)
	assert_eq(int(c.level), _cap())
	assert_eq(FEED.events().size(), 0, "no level changed, so no level_up is announced")


func test_the_satchel_refuses_a_creature_already_at_the_cap_with_a_reason() -> void:
	var c := _creature()
	c.set_level(_cap(), _cfg())
	var tab := _armed_backpack("rare_candy")
	assert_false(bool(tab.call("_eligible", c, 0.0, 0.0, "")),
		"a creature at the cap must not be a candy target")
	assert_eq(str(tab.call("_ineligible_reason", c, 0.0, 0.0, "")), "already at the level cap",
		"the row says WHY, in words, not just a greyed button")
	tab.free()


func test_the_satchel_line_says_the_cap_clamped_a_partial_candy() -> void:
	var line: String = BACKPACK.candy_result_line("Tup", 49, 50, 3, 50)
	assert_true(line.contains("+1 of +3"), "a clamped candy must say how much was granted: '%s'" % line)
	assert_true(line.contains("level cap"), "and that the cap is why: '%s'" % line)
	var full: String = BACKPACK.candy_result_line("Tup", 10, 13, 3, 50)
	assert_false(full.contains("cap"), "a full grant does not mention the cap: '%s'" % full)
	assert_true(full.contains("13"), "the new level is named: '%s'" % full)


# --- fainted creatures --------------------------------------------------------------

func test_a_candy_cannot_target_a_fainted_creature() -> void:
	var c := _creature()
	c.take_damage(c.max_hp)
	assert_true(c.fainted, "sanity")
	var tab := _armed_backpack("good_candy")
	assert_false(bool(tab.call("_eligible", c, 0.0, 0.0, "")))
	assert_eq(str(tab.call("_ineligible_reason", c, 0.0, 0.0, "")), "fainted")
	tab.free()


func test_a_candy_keeps_the_hp_fraction_and_the_banked_xp() -> void:
	var c := _creature()
	c.set_level(10, _cfg())
	c.hp = c.max_hp * 0.5
	c.xp = 17
	c.gain_levels(2, _cfg())
	assert_almost_eq(c.hp_fraction(), 0.5, 0.001,
		"a candy is a level-up, not a heal: the hp FRACTION survives like gain_xp's own loop")
	assert_eq(int(c.xp), 17, "xp banked toward the next level is not thrown away")
	assert_eq(int(c.level), 12)


# --- the feed sees one event ---------------------------------------------------------

func test_rare_candy_is_one_level_up_with_levels_gained_three() -> void:
	var c := _creature()
	c.set_level(10, _cfg())
	FEED.clear()
	c.gain_levels(_candy_levels("rare_candy"), _cfg())
	var ups: Array = []
	for event: Variant in FEED.events():
		if str((event as Dictionary).get("kind", "")) == "level_up":
			ups.append(event)
	assert_eq(ups.size(), 1, "Rare Candy must be ONE level_up, not three")
	assert_eq(int((ups[0] as Dictionary).get("levels_gained", 0)), 3)
	assert_eq(int((ups[0] as Dictionary).get("new_level", 0)), 13)


func test_a_clamped_candy_announces_only_the_levels_it_granted() -> void:
	var c := _creature()
	c.set_level(_cap() - 1, _cfg())
	FEED.clear()
	c.gain_levels(3, _cfg())
	var event: Dictionary = FEED.events()[0]
	assert_eq(str(event.get("kind", "")), "level_up")
	assert_eq(int(event.get("levels_gained", 0)), 1, "the banner must not claim +3 when +1 landed")
	assert_eq(int(event.get("new_level", 0)), _cap())
