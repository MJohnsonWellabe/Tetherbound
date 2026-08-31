extends "res://tests/test_case.gd"

## The opening must hand over an answer to ORDINARY BATTLE DAMAGE, not only to a
## faint.
##
## CAP-2, from the Gate F capstone's second full run
## (`ralph/reports/FINDING-CAP2-NO-HEAL-FOR-LIVING-DAMAGE-2026-08-31.md`, commit
## `1325f887` on `ralph/GATE-F-CAPSTONE-2`). CAP-1 was fixed and verified by that
## run -- and the chapter still stalled one rung further down, for the other half
## of the same 2026-08-28 removal.
##
## `S02-exit.json` carried the starter out of the tutorial ALIVE and at 53.0 of
## 117.6: ordinary damage from a fight the player won their way out of, not a
## wipe. S03's first village training fight then lost, and every route out was
## closed for a reason that is individually correct:
##
##   * a Revive refuses a creature that has not fainted (D40), so the two the
##     opening now hands over are inert against this;
##   * CAP-1's `faint_recovery_fraction` floor is gated on `party.all_fainted()`,
##     and a damaged starter standing beside a healthy party-mate is not a wipe,
##     so the floor correctly never engages;
##   * `heal()` is the mechanism that covers this and the player had nothing that
##     carries it -- `66eb47ec` dropped `give:potion_small:3` along with the
##     Revives, and CAP-1 restored only the Revives;
##   * crafting one is not available either: `potion_small`'s recipe costs
##     `fiber`, `fiber` is `gathered_with` the knife, and the knife is a village
##     tool from after this beat;
##   * and the only full heal in the game is a creature bed, a buildable whose
##     materials need that same knife.
##
## So the starter went down, `all_fainted()` stayed false, the ladder stalled at
## a party of two against a required five, and five home-building flags never
## unset. This file pins the gift and the reasons nothing else substitutes for
## it. What the run cannot pin down on its own is that the kit is still IN the
## data -- which is exactly how it was lost the first time.

const OPENING_DIALOGUE := "res://data/dialogue/opening.json"
const ITEMS := "res://data/items/items.json"
const RECIPES := "res://data/recipes/recipes.json"

## The conversation `66eb47ec` moved the orbs to and CAP-1 moved the Revives to:
## a `give:` effect sits on the beat before its first possible use.
const GIFT_CONVERSATION := "grandpa_first_catch"

## What the capstone's own production save carried into the fight it lost.
## `ralph/reports/FINDING-CAP2-NO-HEAL-FOR-LIVING-DAMAGE-2026-08-31.md` §2.
const CAP2_STARTER_HP := 53.0
const CAP2_STARTER_MAX_HP := 117.6

const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s is missing" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s does not parse as an object" % path)
	return (parsed as Dictionary) if parsed is Dictionary else {}


## Every `give:<id>:<count>` in one opening conversation, as {id: count}.
##
## Read straight off the data rather than through `dialogue_runner.parse_effect`
## for the reason `test_tutorial_faint_floor.gd` reads its config straight: the
## thing that regressed was the FILE, and a test that can only see the file
## through the parser cannot tell a dropped line from a parser that stopped
## finding it.
func _gifts(conversation_id: String) -> Dictionary:
	var conversations: Dictionary = _json(OPENING_DIALOGUE).get("conversations", {})
	assert_true(conversations.has(conversation_id),
		"opening.json has no '%s' conversation" % conversation_id)
	var out: Dictionary = {}
	for raw: Variant in (conversations.get(conversation_id, {}) as Dictionary).get("lines", []) as Array:
		if not (raw is Dictionary):
			continue
		var effects: Array = ((raw as Dictionary).get("effects", []) as Array).duplicate()
		if str((raw as Dictionary).get("effect", "")) != "":
			effects.append(str((raw as Dictionary)["effect"]))
		for effect: Variant in effects:
			var text := str(effect)
			if not text.begins_with("give:"):
				continue
			var pieces := text.substr(len("give:")).split(":")
			if pieces.size() != 2 or not str(pieces[1]).is_valid_int():
				continue
			out[str(pieces[0])] = int(out.get(str(pieces[0]), 0)) + int(str(pieces[1]))
	return out


func _item(id: String) -> Dictionary:
	var items: Dictionary = _json(ITEMS).get("items", {})
	assert_true(items.has(id), "items.json has no '%s'" % id)
	return items.get(id, {}) as Dictionary


# --- the kit -----------------------------------------------------------------

## The gift itself. Named by BEHAVIOUR (`heal`), not by item id, because what the
## opening owes the player here is the ability to top up a living creature -- if
## a later pass renames the item or swaps in a different one, that is fine and
## this test should still pass. What it must not do is silently hand over none.
func test_the_opening_hands_over_something_that_heals_a_living_creature() -> void:
	var gifts := _gifts(GIFT_CONVERSATION)
	var healers: Array = []
	for id: String in gifts:
		if float(_item(id).get("heal", 0.0)) > 0.0:
			healers.append(id)
	assert_true(not healers.is_empty(),
		"the opening's gift beat hands over nothing with a `heal` field. A Revive "
		+ "refuses a creature that has not fainted (D40) and CAP-1's faint floor "
		+ "only fires on a full wipe, so a starter carried out of the tutorial "
		+ "merely DAMAGED -- which is the ordinary outcome -- has no answer at all "
		+ "before the village tools (CAP-2)")


## And enough of it to matter. The bar is not a round number: it is the deficit
## the capstone's own production save actually carried into the fight it lost.
func test_the_healing_gift_covers_the_damage_the_capstone_carried_out_of_s02() -> void:
	var gifts := _gifts(GIFT_CONVERSATION)
	var granted := 0.0
	for id: String in gifts:
		granted += float(_item(id).get("heal", 0.0)) * float(gifts[id])

	# Scaled off the live species table rather than hardcoding 117.6, so a
	# rebalance of the starter moves the bar with it.
	var starter: RefCounted = SPECIES.spawn("ripplet")
	assert_true(starter != null, "the opening's starter species is gone from species.json")
	if starter == null:
		return
	var missing_fraction := 1.0 - (CAP2_STARTER_HP / CAP2_STARTER_MAX_HP)
	var deficit := float(starter.get("max_hp")) * missing_fraction

	assert_true(granted >= deficit,
		("the opening's healing gift restores %.1f in total against the %.1f the "
		+ "capstone's starter was actually missing (%.1f of %.1f). A gift that "
		+ "cannot close the gap the tutorial itself opens is not a fix for CAP-2")
		% [granted, deficit, CAP2_STARTER_HP, CAP2_STARTER_MAX_HP])


## The third item in the pack. `docs/OPENING_SEQUENCE.md` beat 3 names it as
## "orbs, potions, berries" and `66eb47ec` took all three; berries are also the
## bulk of `potion_small`'s own recipe, so they are the renewable half of the
## answer above once the knife arrives.
func test_the_opening_hands_over_food() -> void:
	var gifts := _gifts(GIFT_CONVERSATION)
	var fed := false
	for id: String in gifts:
		var definition := _item(id)
		if float(definition.get("satiety", 0.0)) > 0.0 \
				or not (definition.get("creature_food", {}) as Dictionary).is_empty():
			fed = true
	assert_true(fed,
		"the opening's gift beat hands over no food. OPENING_SEQUENCE.md beat 3 is "
		+ "explicit that the pack is orbs, potions AND berries, and the tournament "
		+ "ladder's own `tournament_team_fed` rung expects the player to have some")


# --- why nothing else covers it ----------------------------------------------

## D40's two halves, stated as the thing CAP-2 turns on: the Revives the opening
## already hands over are inert against a creature that is still standing, and a
## potion is inert against one that is not. Neither item covers the other's case,
## which is why dropping one of them left a real hole.
func test_a_revive_does_nothing_for_a_creature_that_is_merely_hurt() -> void:
	var starter: RefCounted = SPECIES.spawn("ripplet")
	var full := float(starter.get("max_hp"))
	starter.call("take_damage", full * (1.0 - (CAP2_STARTER_HP / CAP2_STARTER_MAX_HP)))
	assert_false(bool(starter.get("fainted")),
		"the capstone's starter walked out of S02 damaged, not fainted; this test's "
		+ "premise is that ordinary battle damage leaves a creature standing")
	var hurt := float(starter.get("hp"))
	assert_true(hurt < full)

	assert_almost_eq(float(starter.call("revive", 1.0)), 0.0, 0.0001,
		"revive() acted on a creature that had not fainted, so D40's split is gone "
		+ "and this test no longer describes the game")
	assert_almost_eq(float(starter.get("hp")), hurt,
		0.0001, "the refused Revive still moved the creature's HP")

	# And the item that IS for this case works on it.
	assert_true(float(starter.call("heal", full)) > 0.0,
		"heal() restored nothing to a living damaged creature; the gift above has "
		+ "nothing to act through")
	assert_almost_eq(float(starter.get("hp")), full)


## CAP-1's floor is deliberately gated on a full wipe -- `_hold_the_tutorial_team_floor()`
## reads `party.all_fainted()` -- and CAP-2's party is the shape that predicate is
## built to say NO to. This is not a defect in the floor; it is why the floor
## could not be the answer here and the kit had to be.
func test_the_faint_floor_correctly_does_not_fire_for_cap2s_party() -> void:
	var party: RefCounted = PARTY.new()
	var starter: RefCounted = SPECIES.spawn("ripplet")
	var caught: RefCounted = SPECIES.spawn("bramblebun")
	party.call("add", starter)
	party.call("add", caught)

	# The exact S03 entry state: the starter hurt, the caught bramblebun fine.
	starter.call("take_damage",
		float(starter.get("max_hp")) * (1.0 - (CAP2_STARTER_HP / CAP2_STARTER_MAX_HP)))
	assert_false(bool(starter.get("fainted")))
	assert_false(bool(party.call("all_fainted")),
		"a damaged starter beside a healthy party-mate now reads as a wipe. The "
		+ "opening's faint floor would start handing out free heals mid-chapter")

	# And it stays false through the faint that ends the training fight, which is
	# the part the capstone recorded and the part that surprises: the party is
	# down to nothing that can fight, and it is still not a wipe.
	starter.call("take_damage", float(starter.get("max_hp")) * 10.0)
	assert_true(bool(starter.get("fainted")))
	assert_false(bool(party.call("all_fainted")),
		"CAP-2's whole shape is that the starter is down and all_fainted() is still "
		+ "false, because the caught creature is standing. If this ever flips, the "
		+ "faint floor starts covering this case and this file needs re-reading")


## The other route a reader reaches for: craft one. `potion_small` is known from
## the first minute (no `unlocked_by`, per recipes.json's own comment) -- but its
## cost is gated behind a tool the opening does not hand over, so a player who
## starts with no potion cannot make one before the fight that needs it.
func test_a_potion_cannot_be_crafted_before_the_village_tools() -> void:
	var recipe: Dictionary = (_json(RECIPES).get("recipes", {}) as Dictionary).get("potion_small", {})
	assert_true(not recipe.is_empty(), "recipes.json no longer carries potion_small")
	var tools_needed: Array = []
	for entry: Variant in recipe.get("cost", []) as Array:
		var id := str((entry as Dictionary).get("id", ""))
		var tool_id := str(_item(id).get("gathered_with", ""))
		if tool_id != "" and not tools_needed.has(tool_id):
			tools_needed.append(tool_id)

	if tools_needed.is_empty():
		# Not a failure -- it would mean the hole closed itself, and a future
		# reader should be told that rather than left with a green test that
		# quietly stopped describing anything.
		print("NOTE: potion_small's cost no longer needs a gathered_with tool; "
			+ "CAP-2's 'cannot craft one either' leg has gone away on its own")
		return

	var gifts := _gifts(GIFT_CONVERSATION)
	for tool_id: String in tools_needed:
		assert_false(gifts.has(tool_id),
			("the opening now hands over the %s, so crafting a potion IS available "
			+ "during the opening and this file's reasoning about why the gift is "
			+ "load-bearing needs revisiting") % tool_id)
