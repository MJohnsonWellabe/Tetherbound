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

const BAND_DIRS := [
	"band1_lower_meadows",
	"band2_stone_and_root",
	"band3_the_river_lock",
	"band4_upper_meadows_ironwood",
	"band5_stronghold_approach",
]


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
	assert_true(found.size() <= 8,
		"%d alpha encounters is not a handful; they would stop reading as special"
		% found.size())


func test_the_tutorial_meadow_has_no_alpha() -> void:
	for row: Variant in _alphas():
		assert_ne(str((row as Dictionary)["band"]), "band1_lower_meadows",
			"band 1 has an alpha. It is the opening meadow -- prompt 71 keeps that "
			+ "baseline gentle, and the first wild creature a player meets must not "
			+ "be an oversized one")


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


func test_every_alpha_is_visibly_bigger() -> void:
	for row: Variant in _alphas():
		var alpha: Dictionary = ((row as Dictionary)["entry"] as Dictionary).get("alpha", {})
		var scale := float(alpha.get("scale", 1.0))
		# CLAUDE.md bans new creature meshes for the Meadows and names scale as
		# one of the sanctioned differentiators. An alpha the player cannot pick
		# out of its own cluster is not an encounter, it is a stat block.
		assert_true(scale > 1.0,
			"an alpha in %s is not scaled up; nothing tells the player it is "
			% str((row as Dictionary)["band"]) + "different before the fight starts")
		assert_true(scale <= 1.6,
			"an alpha in %s is scaled %.2f; past modest it stops matching the "
			% [str((row as Dictionary)["band"]), scale] + "species and starts "
			+ "reading as a different creature, which CLAUDE.md's no-new-meshes "
			+ "rule exists to avoid")


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
