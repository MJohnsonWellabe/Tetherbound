extends "res://tests/test_case.gd"

## GAME-F2. The chapter's teaching fight is pinned to level 2, and this is the
## instrument that says so independently of anything that can be reverted
## alongside it.
##
## The history this exists for, in one paragraph. GAME-11 pinned the Practice
## Meadow cluster to level 2 (`b02f6e8f`) because Gate F run 6 measured the
## unpinned fight over five fresh saves and the level-3 starter FAINTED in four
## of them: band1's `wild_band` is [2,6], so the fight that TEACHES combat was
## rolling anything up to level 6. `cfce9d54` then restored the whole pre-pin
## entry to move the cluster back to its authored centre and took the pin with
## it -- while its own commit message asserted the pin was untouched.
## `encounter_director.gd` treats an absent `level` as "roll it", so nothing
## errored. And the pin had been mirrored into
## `tests/fixtures/band_split_baseline/spawns.json` precisely so a drift would
## fail `test_band_content.gd` -- but the mirror was reverted alongside the live
## file, so the two agreed on the unpinned value and the suite stayed green.
##
## **A baseline that moves with the thing it baselines cannot catch a
## regression in it.** That is the whole reason this file is not another
## fixture comparison. The number below is written here, in a test, where
## reverting the data file does not also revert the expectation.
##
## `progression.json`'s award comment is where the number comes from -- the
## chapter's enemy levels "run 2 at the practice fight to 22 in the stronghold
## gauntlet" -- so this is not a new balance decision, it is the curve the repo
## already wrote down.

const SPAWNS_PATH := "res://data/config/bands/band1_lower_meadows/spawns.json"
const BASELINE_PATH := "res://tests/fixtures/band_split_baseline/spawns.json"
const PROGRESSION_PATH := "res://data/config/progression.json"

## The chapter's own documented opening enemy level. TUNABLE, but tune it HERE
## and in `progression.json`'s curve prose together -- that is the point.
const PRACTICE_FIGHT_LEVEL := 2

## The cluster is identified by what it IS, not by its index: `spawns.json`'s
## `roles.practice` names the species and the Practice Meadow is the cluster of
## that species standing at the authored centre below.
const PRACTICE_CENTRE := Vector2(30.0, -40.0)


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s is missing" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s is not a JSON object" % path)
	return parsed if parsed is Dictionary else {}


## The practice cluster, found by centre rather than by array position so a
## renumbering cannot silently make this test check a different population.
func _practice_cluster(path: String) -> Dictionary:
	for raw: Variant in (_read(path).get("spawns", []) as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw
		var centre: Array = entry.get("centre", []) as Array
		if centre.size() < 3:
			continue
		var at := Vector2(float(centre[0]), float(centre[2]))
		if at.distance_to(PRACTICE_CENTRE) < 0.01:
			return entry
	return {}


func test_the_practice_cluster_still_exists_where_the_opening_walks_to_it() -> void:
	var cluster := _practice_cluster(SPAWNS_PATH)
	assert_false(cluster.is_empty(),
		"no band-1 cluster stands at the Practice Meadow centre (%.1f, %.1f) -- the opening walks the player to a fight that is not there" % [PRACTICE_CENTRE.x, PRACTICE_CENTRE.y])


## The assertion GAME-F2 exists for.
func test_the_teaching_fight_is_pinned_and_does_not_roll_the_band() -> void:
	var cluster := _practice_cluster(SPAWNS_PATH)
	if cluster.is_empty():
		return
	assert_true(cluster.has("level"),
		"the Practice Meadow cluster carries no `level`, so encounter_director.gd rolls it from band1's wild_band [2,6] -- the chapter's TEACHING fight can field a level-6 opponent against a level-3 starter. This is GAME-11, and GAME-F2 is it happening a second time.")
	assert_eq(int(cluster.get("level", 0)), PRACTICE_FIGHT_LEVEL,
		"the Practice Meadow cluster is pinned to level %d; progression.json's own award curve says the chapter's enemy levels 'run 2 at the practice fight to 22 in the stronghold gauntlet'" % PRACTICE_FIGHT_LEVEL)


## The mirror is still required to agree -- but this test, not the mirror, is
## now what holds the number.
func test_the_band_split_baseline_mirrors_the_pin() -> void:
	var cluster := _practice_cluster(BASELINE_PATH)
	assert_false(cluster.is_empty(),
		"the band-split baseline has no Practice Meadow cluster to mirror")
	if cluster.is_empty():
		return
	assert_eq(int(cluster.get("level", 0)), PRACTICE_FIGHT_LEVEL,
		"tests/fixtures/band_split_baseline/spawns.json disagrees with the live file about the practice fight's level; mirror the pin per that fixture's TRACKED MIRROR policy")


## The curve prose and the pin are two statements of one number, and GAME-F2's
## own suggested second fix is that they must not be able to drift apart
## silently. This reads the number out of the prose.
func test_the_progression_curve_still_documents_the_same_opening_level() -> void:
	var text := JSON.stringify(_read(PROGRESSION_PATH))
	var needle := "run %d at the practice fight" % PRACTICE_FIGHT_LEVEL
	assert_true(text.find(needle) != -1,
		"progression.json no longer says \"%s\" -- the award curve and the practice cluster's pin are the same number stated twice, and one of them has moved. Reconcile them rather than deleting this check." % needle)
