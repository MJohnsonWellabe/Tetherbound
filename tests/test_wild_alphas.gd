extends "res://tests/test_case.gd"

## WILD-ECOLOGY (prompt 60): "a handful of special encounters across the
## chapter... they need a reason to win even if the player does not catch it."
##
## The 2026-08-22 Gate C audit found this was the largest gap in the gate: no
## `alpha`, `elder`, `special`, `nest` or `rare` field existed in ANY of the five
## band spawn files -- the fields were exactly `order, species, count, centre,
## radius, time, weather`. `grep -rn "PW2"` returned nothing. The only
## hand-placed strong wild in the whole chapter was the Burrow Warrens guardian,
## which is one creature, not a handful.
##
## What this file pins is the SHAPE of the answer, because the shape is what can
## silently rot: an alpha whose bonus is absolute rather than additive drifts out
## of its band the moment `chapter_curve.json` moves, and an alpha in band 1
## turns the tutorial meadow into something prompt 71 says it must not be.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const BAND_DIRS := [
	"band1_lower_meadows",
	"band2_stone_and_root",
	"band3_the_river_lock",
	"band4_upper_meadows_ironwood",
	"band5_stronghold_approach",
]


## Every cluster in the chapter, which is what "a handful" is a handful OF.
func _cluster_count() -> int:
	var total := 0
	for band: String in BAND_DIRS:
		total += _spawns(band).size()
	return total


func _spawns(band: String) -> Array:
	var file := FileAccess.open(
		"res://data/config/bands/%s/spawns.json" % band, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return []
	var d: Dictionary = parsed
	return d.get("clusters", d.get("spawns", []))


func _alphas() -> Array:
	var out: Array = []
	for band: String in BAND_DIRS:
		for entry: Variant in _spawns(band):
			if entry is Dictionary and (entry as Dictionary).has("alpha"):
				out.append({"band": band, "entry": entry})
	return out


func test_the_chapter_fields_a_handful_of_alphas() -> void:
	var found := _alphas()
	assert_true(found.size() >= 3,
		"the chapter has %d alpha encounters; prompt 60 asks for a handful across "
		% found.size() + "the chapter, and one guardian is not a handful")
	# A handful, not a population. If every cluster grew an alpha the word would
	# stop meaning anything and the band's own level band would stop describing
	# what the player meets.
	#
	# AMENDED by T3-ENCOUNTER: this was `<= 8`, an absolute number written when
	# the chapter had 8 authored alphas. It is a share now, measured against the
	# chapter's own cluster count, for two reasons.
	#
	# First, an absolute cap goes stale every time content lands and then fails
	# for a reason it never meant to catch. T3-CREATURES added four aspect
	# variants -- the four rarest creatures in the game, one individual each,
	# three of them behind time or weather gates, and two of them Alphas because
	# the owner's brief names them as such ("Nightburrow and Stormtrail
	# specifically should be treated as Alpha variants"). That is the *opposite*
	# of the dilution this test guards, and it tripped the cap.
	#
	# Second, the sentence above is already a statement about proportion -- "if
	# EVERY CLUSTER grew an alpha". 6% is the strictest bound that admits what
	# the chapter actually ships (12 of 266 clusters, 4.5%) while still failing
	# well before an alpha stops being a thing you remember. It also tightens
	# automatically as regions gain ordinary wildlife, which an absolute number
	# does the wrong way round.
	var ceiling := int(float(_cluster_count()) * 0.06)
	assert_true(found.size() <= ceiling,
		"%d of %d clusters carry an alpha (%.1f%%); past 6%% they stop reading as special"
		% [found.size(), _cluster_count(), float(found.size()) / float(_cluster_count()) * 100.0])


## PROMPT-71, ORIGINAL: band 1 has no alpha at all -- the opening meadow's
## baseline stays gentle, and the first wild creature a player meets must not
## be an oversized one.
##
## SUPERSEDED IN PART by OWNER PLAYTEST OP-0905-06 (2026-09-05), verbatim:
## "Isn't there supposed to be an alpha at the pond? Shouldn't I be directed
## to go there?" -- CLAUDE.md's precedence puts the newest owner directive
## ahead of a prompt's original framing, so band 1 now fields one alpha (the
## pond mosshell, order 1900; see its own `_why_alpha`). What this test still
## protects is prompt 71's REAL intent, not its literal "zero" count: the
## opening practice meadow itself -- the first few minutes out of Grandpa's
## house -- stays free of an oversized wild. Two checks stand in for that:
## every band 1 alpha sits well clear of the village centre (the pond alpha
## is ~500m out, nowhere near the opening walk), and none of them is the
## first cluster a player reaches walking the road out of the village --
## proven by ORDER (the low, single/double-digit orders are the village's
## immediate surroundings; see order 0/1/10/12 above, all under z=100) and by
## POSITION (all of those early clusters sit under 100m out; the pond alpha
## is hundreds of metres further along).
const VILLAGE_CENTRE := Vector2(6.0, -22.0)
const TUTORIAL_ALPHA_CLEARANCE_M := 350.0


func test_the_tutorial_meadow_has_no_alpha() -> void:
	for row: Variant in _alphas():
		if str((row as Dictionary)["band"]) != "band1_lower_meadows":
			continue
		var entry: Dictionary = (row as Dictionary)["entry"]
		var centre: Array = entry.get("centre", [0.0, 0.0, 0.0])
		var pos := Vector2(float(centre[0]), float(centre[2]))
		var distance := pos.distance_to(VILLAGE_CENTRE)
		assert_true(distance >= TUTORIAL_ALPHA_CLEARANCE_M,
			("band 1's alpha at order %s sits %.0fm from the village centre; OP-0905-06 asks "
			+ "for an alpha at the pond, not in the opening practice meadow -- keep it at "
			+ "least %.0fm out") % [str(entry.get("order")), distance, TUTORIAL_ALPHA_CLEARANCE_M])
		# Not the first thing on the road either: the earliest-authored clusters
		# (order 0/1/10/12, all under z=100 -- see the ordering probed in this
		# file's own header) are the village's immediate surroundings. An alpha
		# with one of those low orders, or sitting that close in, would be the
		# very first wild creature a player meets -- exactly what prompt 71
		# forbids even after OP-0905-06.
		assert_true(int(entry.get("order", 0)) > 100,
			"band 1's alpha at order %s is a low-order cluster -- that is the road's "
			% str(entry.get("order")) + "immediate village surroundings, not the pond, "
			+ "and would be the first wild creature on the walk out")
		assert_true(abs(float(centre[2])) >= 100.0,
			"band 1's alpha at order %s sits within 100m of the village on the z axis -- "
			% str(entry.get("order")) + "too close to be anything but the first cluster "
			+ "on the road")


func test_every_alpha_is_a_bonus_over_its_band_not_an_absolute_level() -> void:
	for row: Variant in _alphas():
		var entry: Dictionary = (row as Dictionary)["entry"]
		var alpha: Dictionary = entry.get("alpha", {})
		assert_true(alpha.has("level_bonus"),
			"an alpha in %s carries no level_bonus" % str((row as Dictionary)["band"]))
		assert_false(alpha.has("level"),
			"an alpha in %s names an absolute `level`; it must be a BONUS over the "
			% str((row as Dictionary)["band"]) + "band's own roll, or it drifts out "
			+ "of range the moment chapter_curve.json moves")
		var bonus := int(alpha.get("level_bonus", 0))
		assert_true(bonus >= 1 and bonus <= 6,
			"alpha level_bonus of %d in %s is outside the range that reads as "
			% [bonus, str((row as Dictionary)["band"])] + "'older and stronger' "
			+ "rather than 'a trainer fight in a creature's body'")


## AMENDED by T3-ENCOUNTER, and deliberately made STRONGER rather than looser.
##
## This asserted `alpha.scale > 1.0`. That was the whole story when every alpha
## was an ordinary species promoted in the spawn table -- the multiplier was the
## only place size could come from. T3-CREATURES then landed four ASPECT
## VARIANTS which are their own species entries carrying their own
## `placeholder.height`: a Nightburrow is 2.10m where a Burrowback is 1.70m, and
## its `alpha` block is deliberately `scale: 1.0` because scaling again would
## apply the owner's own 15-25% band TWICE. So three creatures that are plainly,
## measurably bigger than anything else of their kind failed a check asking
## whether they were bigger.
##
## The property this test exists to protect has never been "the scale field is
## above one". It is the sentence below it: **an alpha the player cannot pick out
## is not an encounter, it is a stat block.** So it now measures the size the
## player actually meets -- the spawn table's multiplier TIMES the species' own
## height over the height of the species it is a variant of.
##
## That is strictly more coverage, and it earned it immediately: it caught
## **Ashtusk**, whose sheet says "VARIANT RECOLOR + VFX" rather than RESIZE, so
## its height is 2.15m -- identical to Tuskroot's -- and which shipped at
## `scale: 1.0`. It was the one alpha in the chapter with no size signal at all,
## and the old assertion would have gone on passing the moment anyone gave the
## other three a token multiplier. Fixed in data (band 5, order 5100), not here.
func test_every_alpha_is_visibly_bigger() -> void:
	for row: Variant in _alphas():
		var entry: Dictionary = (row as Dictionary)["entry"]
		var alpha: Dictionary = entry.get("alpha", {})
		var scale := float(alpha.get("scale", 1.0))
		var size := scale * _variant_size_ratio(str(entry.get("species", "")))
		assert_true(size > 1.0,
			("an alpha in %s stands %.2fx an ordinary member of its own kind; nothing tells "
			+ "the player it is different before the fight starts")
			% [str((row as Dictionary)["band"]), size])
		assert_true(size <= 1.6,
			("an alpha in %s stands %.2fx; past modest it stops matching the species and "
			+ "starts reading as a different creature, which CLAUDE.md's no-new-meshes rule "
			+ "exists to avoid") % [str((row as Dictionary)["band"]), size])


## How much bigger this species already is than the species it is a variant of,
## or 1.0 for an ordinary species (and for a variant that did not resize, which
## is a real and legitimate case -- sheets 7 and 8 say recolour, not resize).
func _variant_size_ratio(species_id: String) -> float:
	var definition: Dictionary = SPECIES.definition(species_id)
	var base := str(definition.get("variant_of", ""))
	if base == "":
		return 1.0
	var own := float((definition.get("placeholder", {}) as Dictionary).get("height", 0.0))
	var base_height := float(
		(SPECIES.definition(base).get("placeholder", {}) as Dictionary).get("height", 0.0))
	if own <= 0.0 or base_height <= 0.0:
		return 1.0
	return own / base_height


func test_every_alpha_says_why_it_is_there() -> void:
	for row: Variant in _alphas():
		var entry: Dictionary = (row as Dictionary)["entry"]
		assert_true(entry.has("_why_alpha"),
			"the alpha in %s has no _why_alpha; prompt 60 asks for the siting "
			% str((row as Dictionary)["band"]) + "rationale, and an unexplained "
			+ "special encounter is the thing the next tuning pass deletes")


func test_the_director_applies_the_bonus_additively() -> void:
	var file := FileAccess.open("res://scripts/combat/encounter_director.gd", FileAccess.READ)
	assert_true(file != null, "encounter_director.gd is missing")
	if file == null:
		return
	var source := file.get_as_text()
	var start := source.find("func _make_alpha(")
	assert_true(start >= 0, "encounter_director.gd has no _make_alpha")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	assert_true(body.contains("+ bonus"),
		"_make_alpha does not add the bonus to the rolled level; an alpha that "
		+ "SETS a level ignores the region curve it stands in")
	assert_true(body.contains("set_meta"),
		"_make_alpha does not mark the body as an alpha, so nothing downstream "
		+ "(a log line, a test, a future presentation pass) can tell it apart")
	# The bug this test did not catch the first time.
	#
	# The original `_make_alpha` set `wild.scale`, which grows only the ART.
	# `creature_body.gd` builds the capsule, the collider, the hit cone's reach
	# and `body_radius()` -- which feeds the catch accuracy bonus -- from
	# `_height` and `_radius`, and node scale touches none of them. A 1.35x alpha
	# would have LOOKED 35% bigger while resolving throws against an ordinary
	# body, so a throw that visually struck it would come back an edge hit or a
	# miss. That is `reticle_outside_body`.
	#
	# Every other check in this file reads data or source text, which is why
	# none of them saw it. This one names the mechanism.
	# Searched over CODE ONLY. `_make_alpha`'s comment explains why node scale is
	# wrong and therefore contains the words -- and the first version of this
	# assertion matched its own explanation and failed correct code. That is the
	# same mistake `test_crossing_failsafe_placement` made earlier on this branch,
	# matching `_add_carve_failsafe` inside the comment that described it.
	assert_false(_code_only(body).contains("wild.scale"),
		"_make_alpha sets node scale, which grows the art and leaves body_radius() "
		+ "and centre() reporting the ordinary body; throws that visually hit an "
		+ "alpha would resolve as misses")
	assert_true(body.contains("apply_size_multiplier"),
		"_make_alpha does not grow the GAMEPLAY size; an alpha has to fight as "
		+ "big as it looks")


## The multiplier has to move the number the catch maths actually reads.
func test_growing_a_body_grows_the_radius_the_catch_maths_uses() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/creatures/creature_body.gd")
	assert_ne(source, "", "creature_body.gd could not be read")
	var start := source.find("func apply_size_multiplier(")
	assert_true(start >= 0,
		"creature_body.gd has no apply_size_multiplier; the alpha tier has no way "
		+ "to grow a creature without desyncing its art from its hitbox")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	for field: String in ["_height", "_radius"]:
		assert_true(body.contains("%s *=" % field),
			"apply_size_multiplier does not scale %s, which drives the capsule, "
			% field + "the collider and the hit cone")
	assert_true(body.contains("_collision.shape"),
		"apply_size_multiplier does not rebuild the collider, so the alpha would "
		+ "fight inside an ordinary creature's hitbox")
	assert_true(body.contains("_build_model") or body.contains("_build_capsule"),
		"apply_size_multiplier does not rebuild the visible body, so the alpha "
		+ "would be bigger only in the numbers")


## A source block with its comment lines removed.
##
## Every string search in this file is about what the code DOES. A comment that
## explains a hazard necessarily names it, so searching raw source makes a
## well-documented function look like the bug it is documenting.
func _code_only(source: String) -> String:
	var out: PackedStringArray = []
	for line: String in source.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("#"):
			continue
		var hash_at := line.find("#")
		out.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(out)
