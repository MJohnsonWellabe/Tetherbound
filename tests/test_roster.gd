extends TestCase

## Is the Meadows roster the thing it claims to be?
##
## Not "does it look good" — that is a human's call from rendered frames and
## `tools/preview_roster_ingame.gd` exists to produce them. These are the parts
## of a roster that are mechanical, and every one of them is a defect that
## actually happened rather than a rule invented here:
##
##   * A creature whose art does not fit the collider gameplay reaches with.
##     `pal_body._fit()` clamps a long body by its footprint allowance, and when
##     the clamp bites the creature renders shorter than it claims to be. The
##     owner found that in a screenshot before any test did (`smoke_art`).
##   * An evolution that SHRINKS. At the pack's own uniform scale the ShibaInu
##     is 0.94m and the Wolf is 0.80m, so the canine line got smaller as it grew
##     up.
##   * A cast with no size range. MA-04 measured 1.8x against Palworld's ~6x and
##     failed the roster on it, with nothing small enough to be underfoot and
##     nothing larger than the trainer.
##   * A creature the colour of the ground. The Wolf ships pale grey at the
##     meadow's own value and the Frog ships green; MA-02's phrase for it was
##     "your own pal is the least readable object in your own fight".
##
## Every assertion below reads data. None of them opens a scene, per D02.

const SPECIES := preload("res://scripts/pals/pal_species.gd")

## The project's ruler, and the trainer's height (`data/config/art.json`).
const TRAINER := 1.80

## GAME_DESIGN.md §8. Locked, and the only legal values for `type`.
const TYPES := ["ground", "water", "air", "fire", "electric", "ice", "psychic", "dark"]

## The meadow's ground, in HSV, sampled from a REAL GAME FRAME rather than from
## the texture on disk or from memory — eight points across
## `shots/combat/02-arena-opens.png` gave hue 74-81°, saturation 0.62-0.81,
## value 0.49-0.67. What matters is what comes out of the tonemapper, and it is
## a long way from what goes in.
##
## The first version of this test used hue 70° at value 0.36, which was the
## ground as it looked several milestones ago. The meadow is live work belonging
## to another milestone and it moved; a readability rule written against a
## remembered colour is a rule about nothing.
const GROUND_HUE := 77.0
const GROUND_VALUE := 0.58
## Half-width of the hue band a creature may not sit in, in degrees.
const HUE_EXCLUSION := 30.0


func _art() -> Dictionary:
	var file := FileAccess.open("res://data/config/art.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _retints() -> Dictionary:
	return _art().get("creatures", {}).get("retint", {})


# --- the shape of the roster ------------------------------------------------

func test_the_roster_is_not_empty_and_every_species_is_complete() -> void:
	var ids := SPECIES.ids()
	assert_true(ids.size() >= 6,
		"a roster of %d is not a biome; §26 wants sixteen and the pack covers eight" % ids.size())
	for id in ids:
		var definition: Dictionary = SPECIES.definition(id)
		assert_true(definition.has("display_name"), "species '%s' has no display_name" % id)
		assert_true(float(definition.get("base_hp", 0.0)) > 0.0, "'%s' has no base_hp" % id)
		assert_true(float(definition.get("base_attack", 0.0)) > 0.0, "'%s' has no base_attack" % id)
		assert_true(float(definition.get("base_defence", 0.0)) > 0.0, "'%s' has no base_defence" % id)


func test_the_ids_the_rest_of_the_game_names_still_exist() -> void:
	# `encounter_director.STARTER_SPECIES` and `WILD_SPAWNS` name these three
	# literally, as do six test files. M11 re-pointed all three at new models and
	# new sizes and kept the ids, because breaking them is a rename in files this
	# milestone does not own.
	for id in ["starter_ground", "wild_rabbit", "wild_bristler"]:
		assert_true(SPECIES.has(id), "'%s' is spawned by name elsewhere and is missing" % id)


func test_every_species_names_a_model_that_exists() -> void:
	for id in SPECIES.ids():
		var path := str(SPECIES.placeholder(id).get("model", ""))
		assert_true(ResourceLoader.exists(path),
			"'%s' names a model at '%s' that does not exist" % [id, path])


# --- types (§8) --------------------------------------------------------------

func test_every_species_declares_one_of_the_eight_locked_types() -> void:
	# The field is INERT — no chart, no multipliers, no same-type bonus — and is
	# asserted anyway, because the cost of a typo is that the chart, when it is
	# built, quietly treats a species as Ground.
	for id in SPECIES.ids():
		var declared := SPECIES.type_of(id)
		assert_true(TYPES.has(declared),
			"'%s' is type '%s', which is not one of §8's eight" % [id, declared])


func test_the_meadows_is_a_ground_biome_with_something_that_is_not_ground() -> void:
	# §9: each biome has a dominant type, and other types appear where
	# ecologically sensible. A roster that is 100% one type makes the field
	# meaningless even once the chart exists.
	var ground := 0
	var other := 0
	for id in SPECIES.ids():
		if SPECIES.type_of(id) == "ground":
			ground += 1
		else:
			other += 1
	assert_true(ground > other, "Ground is meant to be the Meadows' dominant type")
	assert_true(other >= 1, "every species in the biome is Ground; the type field says nothing")


# --- size (§26 "pal size should vary substantially", MA-04) ------------------

func test_the_cast_spans_a_real_range_of_sizes() -> void:
	var smallest := INF
	var largest := 0.0
	for id in SPECIES.ids():
		var h := SPECIES.body_height(id)
		smallest = minf(smallest, h)
		largest = maxf(largest, h)
	# MA-04 measured 1.8x and failed the roster on it, against Palworld's ~6x.
	assert_true(largest / smallest >= 4.0,
		"the cast spans %.2f-%.2fm, a %.1fx range" % [smallest, largest, largest / smallest])
	assert_true(smallest <= 0.5,
		"the smallest creature is %.2fm; nothing is small enough to be underfoot" % smallest)
	assert_true(largest > TRAINER,
		"the largest creature is %.2fm against a %.2fm trainer; nothing looms" % [largest, TRAINER])


func test_no_species_claims_a_size_its_collider_cannot_carry() -> void:
	# A capsule's height is clamped up to its own diameter, so a radius above
	# half the height produces a collider taller than the creature — gameplay
	# reaching further than anything the player can see.
	for id in SPECIES.ids():
		var look: Dictionary = SPECIES.placeholder(id)
		var height := float(look.get("height", 1.0))
		var radius := float(look.get("radius", 0.4))
		assert_true(radius > 0.0 and radius < height,
			"'%s' is %.2fm tall with a %.2fm collider radius" % [id, height, radius])


func test_every_long_bodied_creature_is_allowed_to_be_as_long_as_it_is() -> void:
	# The failure this exists for: `pal_body._fit()` scales a model DOWN when its
	# footprint exceeds `radius * 2 * footprint_allowance`, and the creature then
	# renders shorter than the collider it fights with. It hid behind 0.35m of
	# slack in smoke_art until the owner spotted it in a screenshot.
	#
	# This cannot measure a model without a scene, so it asserts the weaker thing
	# that is still worth asserting: a species whose body is longer than it is
	# tall has to have said so. The default allowance is written for compact
	# creatures and every quadruped in this pack exceeds it.
	for id in SPECIES.ids():
		var look: Dictionary = SPECIES.placeholder(id)
		var declared := float(look.get("footprint_allowance", 0.0))
		assert_true(declared > 0.0,
			"'%s' does not declare a footprint_allowance; it will use the compact default" % id)


# --- evolution (§11) ---------------------------------------------------------

func test_an_evolved_form_is_bigger_and_stronger_than_what_it_evolved_from() -> void:
	# THE DEFECT THIS EXISTS FOR: at the pack's uniform 0.32 scale the ShibaInu
	# measures 0.94m and the Wolf 0.80m, so the canine evolution shrank. §11
	# wants evolution to "visually make sense", and a creature that gets smaller
	# and no more dangerous is not a reward.
	var pairs := 0
	for id in SPECIES.ids():
		var into := SPECIES.evolves_into(id)
		if into == "":
			continue
		pairs += 1
		assert_true(SPECIES.has(into), "'%s' evolves into '%s', which does not exist" % [id, into])
		if not SPECIES.has(into):
			continue
		assert_true(SPECIES.body_height(into) > SPECIES.body_height(id) * 1.2,
			"%s is %.2fm and evolves into %s at %.2fm" % [
				SPECIES.display_name(id), SPECIES.body_height(id),
				SPECIES.display_name(into), SPECIES.body_height(into)])
		for stat in ["base_hp", "base_attack", "base_defence"]:
			assert_true(
				float(SPECIES.definition(into).get(stat, 0.0))
					> float(SPECIES.definition(id).get(stat, 0.0)),
				"%s does not beat %s on %s" % [
					SPECIES.display_name(into), SPECIES.display_name(id), stat])
	assert_true(pairs >= 1, "§26 wants at least one evolved form and there are none")


func test_starters_do_not_evolve() -> void:
	# §11, verbatim: "Starters do not evolve."
	assert_eq(SPECIES.evolves_into("starter_ground"), "",
		"the Ground starter declares an evolution")


# --- roles, read out of the numbers (§26) -----------------------------------

func test_the_tutorial_creature_is_the_weakest_thing_in_the_biome() -> void:
	# §26 calls the rabbit role "common/tutorial" and §27 wants the first fight
	# winnable. If anything catchable is softer than the creature the player is
	# taught on, the teaching order is wrong.
	var tutorial := _stat_total("wild_rabbit")
	for id in SPECIES.ids():
		if id == "wild_rabbit" or id == "starter_ground":
			continue
		assert_true(_stat_total(id) > tutorial,
			"%s totals %.0f against the tutorial creature's %.0f" % [
				SPECIES.display_name(id), _stat_total(id), tutorial])


func test_the_ground_starter_is_durable_and_forgiving_rather_than_strong() -> void:
	# §26: "Ground = durable / forgiving". Legible from the numbers or it is not
	# a role, it is a label.
	var starter: Dictionary = SPECIES.definition("starter_ground")
	assert_true(float(starter["base_defence"]) > float(starter["base_attack"]),
		"the durable starter hits harder than it holds")
	var tougher := 0
	for id in SPECIES.ids():
		if float(SPECIES.definition(id).get("base_attack", 0.0)) > float(starter["base_attack"]):
			tougher += 1
	assert_true(tougher >= 3,
		"only %d species out-hit the starter; 'forgiving' should not also mean 'best'" % tougher)


func test_the_ambusher_is_worth_more_than_the_creature_that_ignores_you() -> void:
	# `encounter_director.xp_for_defeating` weighs a species by its stat total,
	# and nothing sets wild levels yet, so this IS the difference between a fight
	# that matters and one that does not. tests/test_combat_rewards.gd asserts
	# the payout; this asserts the input it reads.
	assert_true(_stat_total("wild_bristler") > _stat_total("wild_rabbit"),
		"the Thornback is no heavier than the Meadow Hopper")
	assert_true(SPECIES.is_aggressive("wild_bristler"),
		"the creature the playground places as an ambush does not start fights")
	assert_false(SPECIES.is_aggressive("wild_rabbit"),
		"§14 forbids the peaceful tutorial creature initiating")


func _stat_total(id: String) -> float:
	var definition: Dictionary = SPECIES.definition(id)
	return float(definition.get("base_hp", 0.0)) \
		+ float(definition.get("base_attack", 0.0)) \
		+ float(definition.get("base_defence", 0.0))


# --- readability (MA-02, MA-04) ---------------------------------------------

func test_every_species_is_repainted_and_none_of_it_is_the_colour_of_grass() -> void:
	# The two defects by name: the Wolf ships #777972 — saturation 0.03 at the
	# ground's own value — and the Frog ships #80a960, which is the meadow's hue.
	# Both are naturalistic animal colours in a game that is not naturalistic,
	# and no amount of lighting reaches either.
	var retints := _retints()
	assert_true(retints.size() >= SPECIES.ids().size(),
		"%d species and %d retint entries" % [SPECIES.ids().size(), retints.size()])

	for id in SPECIES.ids():
		var entry: Variant = retints.get(id)
		assert_true(entry is Dictionary and not (entry as Dictionary).is_empty(),
			"'%s' has no entry in art.json creatures.retint" % id)
		if not (entry is Dictionary):
			continue
		var checked := 0
		for key: String in (entry as Dictionary).keys():
			if key.begins_with("_"):
				continue
			var colour := Color(str((entry as Dictionary)[key]))
			checked += 1
			# Only the LARGE zones have to clear the grass; an eye or a hoof may
			# be any colour it likes, and a name is the only way to tell them
			# apart in a pack with no textures.
			if not key.begins_with("Main") and key != "Green" and key != "Pink" \
					and key != "Material" and key != "Material.003":
				continue
			var hue := colour.h * 360.0
			var away_from_grass: bool = absf(hue - GROUND_HUE) > HUE_EXCLUSION \
				or absf(colour.v - GROUND_VALUE) > 0.25
			assert_true(away_from_grass,
				"'%s' paints '%s' %s — hue %.0f°, value %.2f, which is the ground" % [
					id, key, colour.to_html(false), hue, colour.v])
		assert_true(checked > 0, "'%s' has a retint entry with no colours in it" % id)


func test_the_creature_you_own_is_the_loudest_thing_on_the_field() -> void:
	# MA-02's finding, as a rule: "your own pal is the least readable object in
	# your own fight". The starter is in every frame the player will ever look
	# at, so it gets the highest saturation in the roster.
	var retints := _retints()
	var mine := Color(str(retints.get("starter_ground", {}).get("Main", "#000000")))
	for id: String in retints.keys():
		if id == "starter_ground":
			continue
		var entry: Dictionary = retints[id]
		for key: String in entry.keys():
			if not key.begins_with("Main") and key != "Green":
				continue
			var theirs := Color(str(entry[key]))
			assert_true(theirs.s <= mine.s,
				"%s's '%s' is more saturated (%.2f) than the pal you own (%.2f)" % [
					id, key, theirs.s, mine.s])
