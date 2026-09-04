extends "res://tests/test_case.gd"

## G-2, docs/specs/GATE3_ENCOUNTER_CONTRACTS.md -- the per-encounter behaviour
## override, and the two conditions the contract says it fails on.
##
## Why this is worth a build. Before G-2, `wild_creature.gd::set_engaged()`
## loaded `combat.json`'s ONE global `enemy` block for every opponent in the
## game: a field bramblebun, a relay picket, a Sigil captain and the Warden all
## shared a brain and differed only in level and roster. Two of this chapter's
## own acceptance bullets are unreachable in that world -- prompt 63's Warrens
## guardian "memorable, not standard fight + HP", and prompt 69's Warden with "a
## recognizable combat identity, not simply the largest numbers" -- and the
## repo had already convinced itself otherwise once: `burrow_warrens.json`
## documents a signature Earth Fist at length, and it only ever reached a player
## who CAUGHT the guardian, because the charged slot is read through a
## player-side profile that the wild AI never consults.
##
## The failure mode this file guards is not a crash. An override that quietly
## stopped applying would put the chapter back to one brain with nothing
## visibly broken, and the only instrument that would notice is a human playing
## four hours and reporting that every fight felt the same.

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const _WALL := {"telegraph": 0.85, "recovery": 1.1, "power": 12.0, "chase_speed": 3.4}


func _config_for(override: Dictionary) -> Dictionary:
	var body := WILD.new()
	body.combat_override = override
	var cfg: Dictionary = body._enemy_config_for_this_body()
	body.free()
	return cfg


func test_an_absent_block_changes_nothing_at_all() -> void:
	# The contract's own words: "absent block means today's behaviour, byte for
	# byte, for every creature in the game". Asserted against the shipped
	# `enemy` block rather than a copy of its values, so this keeps holding when
	# combat.json is retuned.
	var shipped: Dictionary = MATH.config().get("enemy", {})
	var got := _config_for({})
	assert_eq(got, shipped,
		"a creature with no combat override must be handed the shipped enemy block unchanged")


func test_an_override_lays_over_the_shipped_block_without_erasing_it() -> void:
	var shipped: Dictionary = MATH.config().get("enemy", {})
	var got := _config_for(_WALL.duplicate())
	for key: String in _WALL:
		assert_eq(got.get(key), _WALL[key],
			"the override's %s should win over the shipped enemy block" % key)
	# A merge, not a replacement: every key the override does NOT name has to
	# survive, or an encounter that tunes one number silently loses the rest of
	# the fight model and falls back to whatever `.get()`'s defaults happen to be.
	for key: String in shipped:
		if _WALL.has(key) or key.begins_with("_comment"):
			continue
		assert_eq(got.get(key), shipped[key],
			"%s was not overridden and must survive the merge" % key)


func test_a_key_the_enemy_block_does_not_own_is_dropped() -> void:
	# The override is authored in content data by a band lane. A typo that
	# silently became a live tuning value would be a content bug presenting as
	# a physics bug, which is among the harder things to trace in this repo.
	var got := _config_for({"power": 12.0, "pwoer": 999.0, "_comment": "why"})
	assert_eq(got.get("power"), 12.0, "the correctly spelled key still applies")
	assert_false(got.has("pwoer"), "a key outside the enemy block's own must not reach the AI")
	assert_false(got.has("_comment") and str(got.get("_comment")) == "why",
		"a rationale comment must not be treated as a tuning value")


func test_an_override_cannot_leak_onto_a_body_that_did_not_author_one() -> void:
	# The contract's other failure condition. Both bodies are built the same
	# way a spawn builds them; only one is given a block.
	var named := _config_for(_WALL.duplicate())
	var ordinary := _config_for({})
	assert_eq(named.get("telegraph"), 0.85, "the named opponent keeps its own telegraph")
	assert_eq(ordinary.get("telegraph"), MATH.config().get("enemy", {}).get("telegraph"),
		"the ordinary creature beside it must be untouched")


func test_the_warrens_guardian_authors_a_real_profile() -> void:
	# The encounter this whole mechanism was found through. Asserted as "it
	# authors one and it differs from the default", not as specific numbers:
	# the contract calls its values TUNABLE and pinning them here would make
	# every tuning round a test edit.
	var warrens: Dictionary = _read_json("res://data/config/burrow_warrens.json")
	var guardian: Dictionary = warrens.get("guardian", {})
	var combat: Dictionary = guardian.get("combat", {})
	assert_false(combat.is_empty(),
		"the Warrens guardian must author a combat block or prompt 63's "
		+ "'memorable, not standard fight + HP' has no mechanism behind it")
	var shipped: Dictionary = MATH.config().get("enemy", {})
	var differs := false
	for key: String in combat:
		if shipped.has(key) and shipped[key] != combat[key]:
			differs = true
	assert_true(differs, "a guardian profile identical to the default is not a profile")


func _read_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	return parsed as Dictionary if parsed is Dictionary else {}
