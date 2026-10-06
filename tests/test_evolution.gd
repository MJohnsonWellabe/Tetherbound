extends "res://tests/test_case.gd"

## R4.6: the evolution SYSTEM (scripts/creatures/evolution.gd), not the static
## species.json links `tests/test_evolution_links.gd` already pins.
##
## Uses a hand-built `evolution` config (test_progression.gd's own reasoning:
## the shipped numbers in data/config/progression.json are TUNABLE per
## CLAUDE.md, and a test pinning them would fail on every retune), but reads
## the REAL Mudsnout/Tuskroot link off the real species.json — that link
## itself is what `test_evolution_links.gd` guards, so this file only needs
## to prove the SYSTEM built on top of it, not re-derive the link's own
## correctness.

const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const BOND_MILESTONES := preload("res://scripts/creatures/bond_milestones.gd")
const PARTY := preload("res://autoload/party.gd")
const SAVE := preload("res://scripts/save/save_game.gd")

const CFG_NO_ITEM := {
	"evolution": {"mudsnout": {"level": 15, "bond_tier": 3, "item_id": ""}},
}
const CFG_WITH_ITEM := {
	"evolution": {"mudsnout": {"level": 15, "bond_tier": 3, "item_id": "heartstone"}},
}

## OWNER-0901-BOND-MILESTONES: a small, isolated 3-entry ladder so `_mudsnout`
## below can put a creature at an exact tier by setting real instance fields,
## the same "hand-built config, real fields" shape test_bond.gd/
## test_progression.gd already use. Passed as `check()`/`evolve()`'s optional
## `milestones_cfg` argument.
const MILESTONES_CFG := {
	"milestones": [
		{"task": "battles_fought", "target": 1, "name": "wins"},
		{"task": "landmarks_visited_together", "target": 1, "name": "visits"},
		{"task": "rest_nights_together", "target": 1, "name": "nights"},
	],
}


## A minimal stand-in for autoload/inventory.gd -- evolution.gd only ever
## calls `count(id)` and `remove(id, n)` on whatever it is handed, so a real
## Inventory (which needs a real ItemDB to construct) is more than this needs.
class FakeInventory:
	var counts: Dictionary = {}

	func count(id: String) -> int:
		return int(counts.get(id, 0))

	func remove(id: String, n: int) -> bool:
		if int(counts.get(id, 0)) < n:
			return false
		counts[id] = int(counts.get(id, 0)) - n
		return true


## `tier` sets real instance fields against MILESTONES_CFG's own 3-entry
## ladder so it lands the creature at exactly that many milestones completed,
## in order -- 0-3.
func _mudsnout(level: int, tier: int) -> RefCounted:
	var creature: RefCounted = SPECIES.spawn("mudsnout")
	creature.set("level", level)
	if tier >= 1:
		creature.set("battles_fought", 1)
	if tier >= 2:
		creature.set("landmarks_visited_together", 1)
	if tier >= 3:
		creature.set("rest_nights_together", 1)
	return creature


func test_a_species_with_no_evolution_link_reports_ineligible() -> void:
	var creature: RefCounted = SPECIES.spawn("bramblebun")
	var result := EVOLUTION.check(creature, CFG_NO_ITEM)
	assert_false(bool(result.get("eligible")))
	assert_eq(str(result.get("target")), "")


func test_requirements_names_the_real_species_json_target() -> void:
	var req := EVOLUTION.requirements("mudsnout", CFG_NO_ITEM)
	assert_eq(str(req.get("target")), "tuskroot")
	assert_eq(int(req.get("level")), 15)
	assert_eq(int(req.get("bond_tier")), 3)


func test_not_eligible_below_the_level_requirement() -> void:
	var creature := _mudsnout(10, 3)
	var result := EVOLUTION.check(creature, CFG_NO_ITEM, null, MILESTONES_CFG)
	assert_false(bool(result.get("eligible")))
	assert_true(str(result.get("reason")).contains("level"),
		"refusal should explain the level gate: '%s'" % str(result.get("reason")))


func test_not_eligible_below_the_bond_requirement() -> void:
	var creature := _mudsnout(20, 1)
	var result := EVOLUTION.check(creature, CFG_NO_ITEM, null, MILESTONES_CFG)
	assert_false(bool(result.get("eligible")))


func test_eligible_once_level_and_bond_are_both_met_with_no_item_required() -> void:
	var creature := _mudsnout(15, 3)
	var result := EVOLUTION.check(creature, CFG_NO_ITEM, null, MILESTONES_CFG)
	assert_true(bool(result.get("eligible")))
	assert_eq(str(result.get("target")), "tuskroot")


func test_item_gate_refuses_without_the_item_and_spends_nothing() -> void:
	var creature := _mudsnout(15, 3)
	var inventory := FakeInventory.new()
	var result := EVOLUTION.check(creature, CFG_WITH_ITEM, inventory, MILESTONES_CFG)
	assert_false(bool(result.get("eligible")))
	assert_false(EVOLUTION.evolve(creature, CFG_WITH_ITEM, inventory, MILESTONES_CFG))
	assert_eq(creature.get("species_id"), "mudsnout", "a refused evolve must change nothing")


func test_item_gate_passes_and_consumes_exactly_one_with_the_item_in_hand() -> void:
	var creature := _mudsnout(15, 3)
	var inventory := FakeInventory.new()
	inventory.counts["heartstone"] = 2
	assert_true(bool(EVOLUTION.check(creature, CFG_WITH_ITEM, inventory, MILESTONES_CFG).get("eligible")))
	assert_true(EVOLUTION.evolve(creature, CFG_WITH_ITEM, inventory, MILESTONES_CFG))
	assert_eq(inventory.count("heartstone"), 1, "evolve must consume exactly one catalyst item")


func test_evolve_refuses_and_changes_nothing_when_not_eligible() -> void:
	var creature := _mudsnout(3, 0)
	var before_species: String = creature.get("species_id")
	assert_false(EVOLUTION.evolve(creature, CFG_NO_ITEM, null, MILESTONES_CFG))
	assert_eq(creature.get("species_id"), before_species)


## The core promise: species/stats change, everything the player earned does
## not.
func test_evolve_changes_species_and_stats_but_preserves_what_the_player_earned() -> void:
	var creature := _mudsnout(20, 3)
	# The legacy `bond` field (OWNER-0901-BOND-MILESTONES: no longer gated on,
	# but still just a plain int property) should survive evolution exactly
	# like every other earned field below.
	creature.set("bond", 60)
	creature.set("nickname", "Snorty")
	creature.set("xp", 42)
	creature.set("iv_hp", 0.81)
	creature.set("trait_primary", "sturdy")
	creature.set("move_quick", "root_nibble")

	var hp_fraction_before: float = creature.call("hp_fraction")

	assert_true(EVOLUTION.evolve(creature, CFG_NO_ITEM, null, MILESTONES_CFG))

	assert_eq(creature.get("species_id"), "tuskroot")
	assert_eq(creature.get("display_name"), str(SPECIES.definition("tuskroot").get("display_name")))
	assert_eq(float(creature.get("base_hp")), float(SPECIES.definition("tuskroot").get("base_hp")))

	# Earned state, untouched.
	assert_eq(creature.get("nickname"), "Snorty")
	assert_eq(int(creature.get("level")), 20)
	assert_eq(int(creature.get("xp")), 42)
	assert_eq(int(creature.get("bond")), 60)
	assert_eq(float(creature.get("iv_hp")), 0.81)
	assert_eq(creature.get("trait_primary"), "sturdy")
	assert_eq(creature.get("move_quick"), "root_nibble")

	# D17/D30: the hp FRACTION survives the transition, the same as any
	# level-up -- a Mudsnout mid-fight does not get topped up (or dropped)
	# by evolving.
	assert_almost_eq(float(creature.call("hp_fraction")), hp_fraction_before, 0.001,
		"hp fraction should survive an evolution the same way it survives a level-up")


## --- SD17: the item gate now has a real source in the world ----------------
##
## Everything above uses hand-built configs, deliberately (see this file's own
## header). These three read the SHIPPED data instead, because what changed
## with the Burrow Warrens is not the logic — it is that
## `data/config/progression.json` finally names a catalyst and
## `data/items/items.json` finally defines it. That pairing is exactly the
## class of thing that rots silently: an item id typo'd in one file and never
## in the other locks the biome's one evolution shut with no error anywhere.
## The gate's numbers stay unpinned (tunable); only the LINK is asserted.

func _shipped_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _shipped_items() -> Dictionary:
	var file := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var items: Variant = (parsed as Dictionary).get("items", {})
	return items as Dictionary if items is Dictionary else {}


func test_the_shipped_evolution_catalyst_is_a_real_item() -> void:
	var cfg := _shipped_config()
	var entry: Variant = cfg.get("evolution", {}).get("mudsnout", {})
	var item_id := str((entry as Dictionary).get("item_id", "")) if entry is Dictionary else ""
	if item_id.is_empty():
		# Legal: an empty id means "no catalyst", which is what shipped before
		# SD17. Nothing to check, and nothing broken.
		return
	assert_true(_shipped_items().has(item_id),
		"progression.json's evolution catalyst '%s' is not defined in items.json" % item_id)


## Sets real instance fields to meet the first `tier` entries of the REAL
## shipped data/config/bond_milestones.json, so a creature can be put at a
## real tier without a milestones_cfg override -- needed for any test in this
## section, since they read the real shipped progression.json `cfg` (and so
## real `bond_nodes()` falls back to the real ladder too, unlike `_mudsnout`
## above which only satisfies the small hand-built MILESTONES_CFG).
func _mudsnout_at_real_tier(level: int, tier: int) -> RefCounted:
	var creature: RefCounted = SPECIES.spawn("mudsnout")
	creature.set("level", level)
	var list := BOND_MILESTONES.milestones(BOND_MILESTONES.config())
	for i in mini(tier, list.size()):
		var m := list[i] as Dictionary
		var task := str(m.get("task", ""))
		if task.is_empty():
			continue
		# `distance_m_together` is the one float-typed task; every other
		# shipped task so far is a plain int counter.
		if task == "distance_m_together":
			creature.set(task, float(m.get("target", 0.0)))
		else:
			creature.set(task, int(m.get("target", 0)))
	return creature


## --- D71/T3-SUNSTONE: Mudsnout branches on which stone is held -------------
##
## These read the REAL species.json link (`mudsnout.evolves_into_variants`),
## the same way the file's header already justifies doing for the primary
## Heartstone/Tuskroot link -- this IS the thing that would rot silently if
## nothing exercised it. CFG_WITH_ITEM is reused unchanged: the branch design
## deliberately keeps progression.json's shape exactly as SD17 shipped it,
## only species.json gained a new field.
##
## OWNER-0901-BOND-MILESTONES: these read the real shipped progression.json
## `evolution.mudsnout.bond_tier` (no milestones_cfg override passed to
## `check()`/`evolve()`), so `_mudsnout_at_real_tier` -- not `_mudsnout`,
## which only satisfies the small hand-built MILESTONES_CFG above -- is what
## puts a creature at the real bond_tier requirement.

func test_sunstone_branch_evolves_into_ashtusk_and_consumes_only_the_sunstone() -> void:
	var creature := _mudsnout_at_real_tier(15, 3)
	var inventory := FakeInventory.new()
	inventory.counts["sunstone"] = 1
	var result := EVOLUTION.check(creature, CFG_WITH_ITEM, inventory)
	assert_true(bool(result.get("eligible")), "holding only the Sunstone should open the Ashtusk branch")
	assert_eq(str(result.get("target")), "ashtusk")
	assert_true(EVOLUTION.evolve(creature, CFG_WITH_ITEM, inventory))
	assert_eq(creature.get("species_id"), "ashtusk")
	assert_eq(inventory.count("sunstone"), 0, "evolving must consume the Sunstone")


func test_holding_both_stones_refuses_as_ambiguous_and_spends_nothing() -> void:
	var creature := _mudsnout_at_real_tier(15, 3)
	var inventory := FakeInventory.new()
	inventory.counts["heartstone"] = 1
	inventory.counts["sunstone"] = 1
	var result := EVOLUTION.check(creature, CFG_WITH_ITEM, inventory)
	assert_false(bool(result.get("eligible")), "carrying both catalysts must refuse rather than silently pick one")
	assert_true(str(result.get("reason")).length() > 0, "the refusal must say what is wrong, not fail silently")
	assert_false(EVOLUTION.evolve(creature, CFG_WITH_ITEM, inventory))
	assert_eq(creature.get("species_id"), "mudsnout", "a refused evolve must change nothing")
	assert_eq(inventory.count("heartstone"), 1, "a refused evolve must spend nothing")
	assert_eq(inventory.count("sunstone"), 1, "a refused evolve must spend nothing")


func test_holding_neither_stone_still_reports_tuskroot_as_the_default_target() -> void:
	# Unchanged behaviour for the common case: a Mudsnout with no catalyst in
	# hand still shows the primary (Heartstone) path as its target, exactly as
	# it did before this species gained a second branch.
	var req := EVOLUTION.requirements("mudsnout", CFG_WITH_ITEM)
	assert_eq(str(req.get("target")), "tuskroot")


func test_refusal_with_no_catalyst_names_both_stones() -> void:
	var creature := _mudsnout_at_real_tier(15, 3)
	var result := EVOLUTION.check(creature, CFG_WITH_ITEM, FakeInventory.new())
	assert_false(bool(result.get("eligible")))
	var reason := str(result.get("reason"))
	assert_true(reason.contains("Heartstone") and reason.contains("Sunstone"),
		"a refusal with no stone held should name the whole fork, not one branch of it: '%s'" % reason)


func test_the_shipped_gate_refuses_held_stone_shortcut_and_preserves_the_catalyst() -> void:
	var cfg := _shipped_config()
	var entry: Dictionary = cfg.get("evolution", {}).get("mudsnout", {}) as Dictionary
	var item_id := str(entry.get("item_id", ""))
	if item_id.is_empty():
		return
	var creature := _mudsnout_at_real_tier(
		int(entry.get("level", 15)) + 5, int(entry.get("bond_tier", 3))
	)
	var inventory := FakeInventory.new()
	var without := EVOLUTION.check(creature, cfg, inventory)
	assert_false(bool(without.get("eligible")),
		"a level+bond-ready Mudsnout must still be refused without the catalyst")
	assert_true(str(without.get("reason")).length() > 0,
		"the refusal must say what is missing, not fail silently")
	inventory.counts[item_id] = 1
	assert_eq(cfg.get("evolution_mode"), "breakthrough")
	assert_false(bool(EVOLUTION.check(creature, cfg, inventory).get("eligible")),
		"a held stone cannot bypass the Kitchen feast and explicit choice")
	assert_false(EVOLUTION.evolve(creature, cfg, inventory))
	assert_eq(inventory.count(item_id), 1, "shortcut refusal must preserve the stone")
	assert_eq(creature.species_id, "mudsnout")


func test_caught_water_mosshell_requires_choice_and_keeps_the_water_form_and_individual() -> void:
	var creature := SPECIES.spawn("water_mosshell")
	creature.set("level", 30)
	creature.set("nickname", "Reed")
	creature.set("bond", 37)
	creature.set("iv_hp", 0.21)
	creature.set("iv_attack", 0.63)
	creature.set("iv_defence", 0.87)
	creature.set("boost_hp", 4)
	creature.set("battles_fought", 17)
	creature.set("distance_m_together", 2400.0)
	creature.set("caught_on_day", 9)
	creature.set("trait_primary", "sturdy")
	var quick := str(creature.get("move_quick"))
	creature.set("move_mastery_uses", {quick: 2})
	creature.set("move_mastery_receipts", {quick: ["water-prior-use-1", "water-prior-use-2"]})
	var party := PARTY.new()
	assert_true(party.add(creature))
	var save := SAVE.new()
	var card: Dictionary = save._party_to_array(party)[0]
	card.evolution_choices = {}
	var before := card.duplicate(true)
	var offer := EVOLUTION.feast_offer(card, 3)
	assert_true(bool(offer.get("ok")))
	assert_true(bool(offer.get("choice_required")), "caught Water IDs must find the authored line")
	assert_eq(offer.branches.size(), 1)
	if offer.branches.size() != 1: return
	assert_eq(offer.branches[0].id, "mosshell_cannonback")
	assert_eq(offer.branches[0].source, "water_mosshell")
	assert_eq(offer.branches[0].target, "water_cannonback")
	assert_eq(offer.branches[0].extra_ingredient, "")
	assert_eq(EVOLUTION.prepare_feast_choice(card, 3, "", "").code, "evolution_choice_required")
	var result := EVOLUTION.prepare_feast_choice(card, 3, "evolve", "")
	assert_true(bool(result.get("ok")))
	if not bool(result.get("ok")): return
	assert_eq(card, before, "planning must leave the saved input unchanged")
	assert_eq(result.creature.species_id, "water_cannonback")
	assert_eq(result.creature.evolution_choices, {"3": "water_cannonback"})
	assert_eq(result.choice_record, {"tier": "3", "value": "water_cannonback"})
	assert_eq(result.debit, {}, "a cooked feast never debits another catalyst")
	for field: String in before:
		if not result.species_patch.has(field) and field != "evolution_choices":
			assert_eq(result.creature[field], before[field], "individual field survives: " + field)
	assert_almost_eq(float(result.creature.hp) / float(result.creature.max_hp), float(card.hp) / float(card.max_hp), 0.000001)
	var durable: Dictionary = JSON.parse_string(JSON.stringify(result.creature))
	assert_eq(durable.species_id, "water_cannonback")
	assert_eq(durable.evolution_choices, {"3": "water_cannonback"})
	assert_eq(durable.move_mastery_receipts, card.move_mastery_receipts)
	assert_eq(EVOLUTION.feast_offer(durable, 3).code, "evolution_choice_permanent")
	var target := SPECIES.definition(durable.species_id)
	assert_true(bool(target.swim_mount.compatible))
	assert_false((target.water_mount_geometry as Dictionary).is_empty())
	assert_true(SPECIES.is_rideable(durable.species_id))
	assert_false(SPECIES.definition("cannonback").has("water_mount_geometry"))
	var guidance := EVOLUTION.check(creature, _shipped_config())
	assert_false(bool(guidance.eligible))
	assert_true(str(guidance.reason).contains("Lv 30 Ascension Feast"))
	assert_true(str(guidance.reason).contains("evolve or stay"))


func test_water_mosshell_stay_is_permanent_and_canonical_mosshell_stays_canonical() -> void:
	var party := PARTY.new()
	var creature := SPECIES.spawn("water_mosshell")
	creature.set("level", 30)
	assert_true(party.add(creature))
	var card: Dictionary = SAVE.new()._party_to_array(party)[0]
	card.evolution_choices = {}
	var before := card.duplicate(true)
	var stay := EVOLUTION.prepare_feast_choice(card, 3, "stay", "")
	assert_true(bool(stay.get("ok")))
	if not bool(stay.get("ok")): return
	assert_eq(stay.creature.species_id, "water_mosshell")
	assert_eq(stay.choice_record, {"tier": "3", "value": "stay"})
	var durable: Dictionary = JSON.parse_string(JSON.stringify(stay.creature))
	assert_eq(EVOLUTION.prepare_feast_choice(durable, 3, "evolve", "").code, "evolution_choice_permanent")
	assert_eq(card, before)
	assert_eq(EVOLUTION.feast_offer(card, 2).code, "evolution_wrong_level")
	card.species_id = "water_unknown_mosshell"
	assert_eq(EVOLUTION.feast_offer(card, 3).code, "evolution_species_invalid")
	card.species_id = "mosshell"
	var canonical := EVOLUTION.feast_offer(card, 3)
	assert_true(bool(canonical.get("ok")))
	assert_eq(canonical.branches.size(), 1)
	if canonical.branches.size() != 1: return
	assert_eq(canonical.branches[0].source, "mosshell")
	assert_eq(canonical.branches[0].target, "cannonback")
	assert_eq(EVOLUTION.prepare_feast_choice(card, 3, "evolve", "").creature.species_id, "cannonback")
