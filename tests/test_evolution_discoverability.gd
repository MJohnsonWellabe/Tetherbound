extends "res://tests/test_case.gd"

## OP-0905-18 (docs/owner/OWNER_PLAYTEST_2026-09-05.md): "When and how does
## the pig evolve?" -- the gate itself (`tests/test_evolution.gd`) was always
## real; nothing ever told the player it existed. This proves the fix:
##
##   * `progression_feed.gd::evolution_eligibility_event()` fires exactly
##     once per creature, the moment `evolution.gd::check()` first reports
##     every requirement met (level, bond tier AND the catalyst item) --
##     never before the item is actually held, and never a second time for
##     the same creature.
##   * `progression_feed.gd::catalyst_pickup_text()`/`announce_catalyst_pickup()`
##     name the real shipped gate (level, bond tier, the pre-evolution
##     species) for a known evolution catalyst, and say nothing for an
##     ordinary item.
##   * `tab_creatures.gd`'s Team-tab detail text names every requirement a
##     creature has NOT yet met, with its current value beside it, instead of
##     the old line that only ever quoted the level gate.
##
## Reads the REAL shipped `progression.json`/`species.json`/
## `bond_milestones.json` throughout (like `test_evolution.gd`'s own SD17
## section) rather than a hand-built config, because the whole point is
## whether a player reading these exact words learns the REAL rule.

const FEED := preload("res://scripts/creatures/progression_feed.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BOND_MILESTONES := preload("res://scripts/creatures/bond_milestones.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TAB_CREATURES := preload("res://scripts/ui/tab_creatures.gd")


## A minimal stand-in for autoload/inventory.gd, the same shape
## `test_evolution.gd::FakeInventory` already uses -- `evolution.gd` only
## ever calls `count(id)` on whatever it is handed.
class FakeInventory:
	var counts: Dictionary = {}

	func count(id: String) -> int:
		return int(counts.get(id, 0))

	func remove(id: String, n: int) -> bool:
		if int(counts.get(id, 0)) < n:
			return false
		counts[id] = int(counts.get(id, 0)) - n
		return true


func before_each() -> void:
	FEED.clear()


func _of_kind(kind: String) -> Array:
	var out: Array = []
	for event: Variant in FEED.events():
		if str((event as Dictionary).get("kind", "")) == kind:
			out.append(event)
	return out


## A fresh Mudsnout put at exactly `tier` real bond-milestone nodes, the same
## helper `test_evolution.gd::_mudsnout_at_real_tier` uses -- needed because
## `evolution_eligibility_event()`/`_evolution_missing_text()` both read
## `bond_nodes()` with no override, i.e. the real shipped ladder.
func _mudsnout(level: int, tier: int) -> RefCounted:
	var creature: RefCounted = SPECIES.spawn("mudsnout")
	creature.set("level", level)
	var list := BOND_MILESTONES.milestones(BOND_MILESTONES.config())
	for i in mini(tier, list.size()):
		var m := list[i] as Dictionary
		var task := str(m.get("task", ""))
		if task.is_empty():
			continue
		if task == "distance_m_together":
			creature.set(task, float(m.get("target", 0.0)))
		else:
			creature.set(task, int(m.get("target", 0)))
	return creature


# --- evolution_eligibility_event: fires once, only once every gate is met --

func test_evolution_eligible_fires_once_for_a_creature_that_crosses_every_gate() -> void:
	var cfg := PROGRESSION.config()
	var entry: Dictionary = cfg.get("evolution", {}).get("mudsnout", {}) as Dictionary
	var level: int = int(entry.get("level", 15))
	var bond_tier: int = int(entry.get("bond_tier", 3))
	var item_id := str(entry.get("item_id", ""))
	var creature := _mudsnout(level, bond_tier)
	var inventory := FakeInventory.new()
	if item_id != "":
		inventory.counts[item_id] = 1

	var event := FEED.evolution_eligibility_event(creature, cfg, inventory)
	assert_false(event.is_empty(), "a fully-eligible creature must be announced")
	assert_eq(str(event.get("kind", "")), "evolution_eligible")
	assert_eq(str(event.get("target", "")), "tuskroot")
	assert_eq(_of_kind("evolution_eligible").size(), 1)

	var again := FEED.evolution_eligibility_event(creature, cfg, inventory)
	assert_true(again.is_empty(), "the same creature must not be announced twice")
	assert_eq(_of_kind("evolution_eligible").size(), 1,
		"a second eligible check on the same creature must not push a second event")


func test_evolution_eligible_does_not_fire_while_the_catalyst_is_missing() -> void:
	var cfg := PROGRESSION.config()
	var entry: Dictionary = cfg.get("evolution", {}).get("mudsnout", {}) as Dictionary
	var item_id := str(entry.get("item_id", ""))
	if item_id == "":
		return  # nothing to withhold; the shipped gate is level+bond only right now
	var creature := _mudsnout(int(entry.get("level", 15)), int(entry.get("bond_tier", 3)))
	var event := FEED.evolution_eligibility_event(creature, cfg, FakeInventory.new())
	assert_true(event.is_empty(), "level and bond met but no catalyst held must not announce eligibility")
	assert_eq(_of_kind("evolution_eligible").size(), 0)


func test_evolution_eligible_does_not_fire_below_the_level_or_bond_gate() -> void:
	var cfg := PROGRESSION.config()
	var creature := _mudsnout(3, 0)
	var event := FEED.evolution_eligibility_event(creature, cfg, FakeInventory.new())
	assert_true(event.is_empty())
	assert_eq(_of_kind("evolution_eligible").size(), 0)


func test_a_species_with_no_evolution_link_is_never_announced() -> void:
	var creature: RefCounted = SPECIES.spawn("bramblebun")
	creature.set("level", 50)
	var event := FEED.evolution_eligibility_event(creature, PROGRESSION.config(), null)
	assert_true(event.is_empty())


# --- catalyst_pickup_text / announce_catalyst_pickup ------------------------

func test_catalyst_pickup_text_names_the_real_gate_for_both_shipped_stones() -> void:
	var cfg := PROGRESSION.config()
	var heartstone := FEED.catalyst_pickup_text("heartstone", cfg)
	assert_true(heartstone.contains("Heartstone"), heartstone)
	assert_true(heartstone.contains("Lv 15"), heartstone)
	assert_true(heartstone.contains("bond tier 3"), heartstone)
	assert_true(heartstone.contains("Mudsnout"), heartstone)

	var sunstone := FEED.catalyst_pickup_text("sunstone", cfg)
	assert_true(sunstone.contains("Sunstone"), sunstone)
	assert_true(sunstone.contains("Mudsnout"), sunstone)


func test_catalyst_pickup_text_is_empty_for_an_ordinary_item() -> void:
	assert_eq(FEED.catalyst_pickup_text("good_candy", PROGRESSION.config()), "")
	assert_eq(FEED.catalyst_pickup_text("", PROGRESSION.config()), "")


func test_announce_catalyst_pickup_pushes_one_catalyst_found_event_for_a_real_catalyst() -> void:
	FEED.announce_catalyst_pickup("heartstone")
	var found := _of_kind("catalyst_found")
	assert_eq(found.size(), 1)
	assert_eq(str((found[0] as Dictionary).get("item_id", "")), "heartstone")
	assert_true(str((found[0] as Dictionary).get("text", "")).contains("Mudsnout"))


func test_announce_catalyst_pickup_is_silent_for_an_ordinary_item() -> void:
	FEED.announce_catalyst_pickup("good_candy")
	assert_eq(_of_kind("catalyst_found").size(), 0, "an ordinary pickup must not announce a catalyst find")


# --- the two new feed kinds present themselves as moments -------------------

func test_evolution_eligible_and_catalyst_found_are_moments_with_the_actual_verb() -> void:
	var eligible := {"kind": "evolution_eligible", "name": "Snorty", "target": "tuskroot"}
	assert_true(FEED.is_moment(eligible))
	var moment := FEED.moment_text(eligible)
	assert_eq(str(moment.get("title", "")), "Snorty can evolve")
	assert_true(str(moment.get("detail", "")).contains("G evolve"),
		"the banner must name the Team tab's own evolve legend, not a vaguer nudge")

	var catalyst := {"kind": "catalyst_found", "item_id": "heartstone", "text": "held against a creature..."}
	assert_true(FEED.is_moment(catalyst))
	assert_eq(str(FEED.moment_text(catalyst).get("title", "")), "Heartstone found")


# --- tab_creatures.gd: every unmet requirement, with the current value -----

func test_missing_text_names_all_three_unmet_requirements_with_current_values() -> void:
	var creature := _mudsnout(11, 2)
	var text := TAB_CREATURES._evolution_missing_text(creature, PROGRESSION.config(), null)
	assert_true(text.contains("Lv 15 (now 11)"), text)
	assert_true(text.contains("Bond tier 3 (now 2)"), text)
	assert_true(text.contains("needs Heartstone"), text)


func test_missing_text_names_only_what_is_actually_unmet() -> void:
	var cfg := PROGRESSION.config()
	var entry: Dictionary = cfg.get("evolution", {}).get("mudsnout", {}) as Dictionary
	var creature := _mudsnout(int(entry.get("level", 15)), int(entry.get("bond_tier", 3)))
	var text := TAB_CREATURES._evolution_missing_text(creature, cfg, null)
	assert_false(text.contains("Lv"), "level is already met and must not be listed: '%s'" % text)
	assert_false(text.contains("Bond tier"), "bond is already met and must not be listed: '%s'" % text)
	assert_true(text.contains("needs Heartstone"), text)


func test_missing_text_is_empty_once_every_requirement_including_the_item_is_met() -> void:
	var cfg := PROGRESSION.config()
	var entry: Dictionary = cfg.get("evolution", {}).get("mudsnout", {}) as Dictionary
	var creature := _mudsnout(int(entry.get("level", 15)), int(entry.get("bond_tier", 3)))
	var inventory := FakeInventory.new()
	var item_id := str(entry.get("item_id", ""))
	if item_id != "":
		inventory.counts[item_id] = 1
	assert_eq(TAB_CREATURES._evolution_missing_text(creature, cfg, inventory), "")


func test_missing_text_is_empty_for_a_species_that_does_not_evolve() -> void:
	var creature: RefCounted = SPECIES.spawn("bramblebun")
	assert_eq(TAB_CREATURES._evolution_missing_text(creature, PROGRESSION.config(), null), "")


func test_xp_next_line_reports_ready_to_evolve_once_every_gate_is_met() -> void:
	var cfg := PROGRESSION.config()
	var entry: Dictionary = cfg.get("evolution", {}).get("mudsnout", {}) as Dictionary
	var creature := _mudsnout(int(entry.get("level", 15)), int(entry.get("bond_tier", 3)))
	var inventory := FakeInventory.new()
	var item_id := str(entry.get("item_id", ""))
	if item_id != "":
		inventory.counts[item_id] = 1
	var line := TAB_CREATURES._xp_next_line(creature, cfg, inventory)
	assert_true(line.contains("ready to evolve"), line)


func test_xp_next_line_names_missing_requirements_when_not_yet_eligible() -> void:
	var creature := _mudsnout(5, 0)
	var line := TAB_CREATURES._xp_next_line(creature, PROGRESSION.config(), null)
	assert_true(line.contains("Lv 15 (now 5)"), line)
