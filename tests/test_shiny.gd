extends "res://tests/test_case.gd"

## OF27 — the shiny roll and its odds config. The mechanical half of "shiny
## like Pokemon GO": `creature_instance.gd`'s `shiny` field and the save
## round-trip are covered by tests/test_save_format.gd's VERSION 6 section;
## the actual tint rendering (the part a unit test cannot see, per
## docs/decisions/D02) is covered by smoke_art.gd's own shiny check. This
## file is the roll itself: determinism, odds, and proof the new draw did not
## disturb the draws that already existed.
##
## `encounter_director.gd extends Node`, not RefCounted, so this cannot be
## this file's own base class — same situation test_combat_progression.gd's
## own header explains for CombatManager, and the same fix: build a
## throwaway `EncounterDirector.new()` off-tree (`.new()` never calls
## `_ready()` outside a live SceneTree, so nothing here needs a scene) and
## call `_roll_wild_level` on the typed script instance. Its authored region
## coordinate is explicit so signature drift cannot abort a reflection call
## before the test has asserted anything.

const ENCOUNTER_DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const CREATURE_VISUAL := preload("res://scripts/creatures/creature_visual.gd")

var _wild_bodies: Array[Node3D] = []


func after_each() -> void:
	for wild in _wild_bodies:
		wild.free()
	_wild_bodies.clear()

## A stand-in for the real wild body `_roll_wild_level` drives: only what it
## actually touches (`instance`, `set_shiny`), the same "no scene tree
## needed" shape test_combat_progression.gd's FakeVitals/FakeGame doubles
## already use for save_game.gd and combat_manager.gd.
class FakeWildBody:
	extends Node3D
	var instance: RefCounted = null
	var shiny: bool = false
	var shiny_set_calls: int = 0
	func set_shiny(value: bool) -> void:
		shiny = value
		shiny_set_calls += 1


## One full `_roll_wild_level` call against a fresh rng seeded from
## `seed_string`, exactly the way `encounter_director._spawn_creatures` seeds
## its own per-entry generator (`hash("wild_spawn_%d" % index)`) — the string
## itself does not have to match a real spawns.json entry for this to prove
## anything about the roll's own behaviour.
func _roll(seed_string: String, species: String = "terrapup", centre_z: float = 0.0) -> Dictionary:
	var director := ENCOUNTER_DIRECTOR.new()
	var wild := FakeWildBody.new()
	_wild_bodies.append(wild)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_string)
	# Historical roll fixtures live in Lower Meadows (z=0). The current
	# producer requires authored position to select its chapter level band.
	# A typed call makes future signature drift a parse failure, not an
	# aborted reflection call that the tiny runner can mistake for a pass.
	director._roll_wild_level(wild, species, rng, centre_z)
	director.free()
	assert_true(wild.instance != null, "the real encounter producer must construct the rolled creature")
	return {"wild": wild, "rng": rng}


func test_authored_region_changes_level_without_reordering_the_shiny_or_iv_draws() -> void:
	var lower := _roll("wild_spawn_0", "terrapup", 0.0)["wild"] as FakeWildBody
	var river := _roll("wild_spawn_0", "terrapup", 4000.0)["wild"] as FakeWildBody
	assert_between(int(lower.instance.get("level")), 2, 6)
	assert_between(int(river.instance.get("level")), 9, 12)
	assert_true(int(river.instance.get("level")) > int(lower.instance.get("level")),
		"negative control: the fourth argument must actually select the authored region")
	assert_eq(lower.shiny, river.shiny)
	assert_almost_eq(float(lower.instance.get("iv_hp")), float(river.instance.get("iv_hp")), 0.0000001)


# --- odds read from config --------------------------------------------------

func test_shiny_chance_reads_the_shipped_config_value() -> void:
	# data/config/creatures_visual.json's own shipped shiny_chance, so a
	# future retune of the file is what this test would actually catch
	# drifting, not a hardcoded copy of it.
	var file := FileAccess.open(CREATURE_VISUAL.CONFIG_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var configured := float((parsed as Dictionary).get("shiny_chance"))
	assert_almost_eq(CREATURE_VISUAL.shiny_chance(), configured, 0.0000001)
	assert_true(configured > 0.0 and configured < 1.0, "shiny_chance must be real odds, not 0 or 1")


func test_shiny_chance_falls_back_when_config_is_unreadable() -> void:
	# Same "never fatal, degrade to a sane default" contract combat_math.gd/
	# progression.gd/catch_math.gd already give a missing config file.
	assert_almost_eq(
		CREATURE_VISUAL.DEFAULT_SHINY_CHANCE, 0.0078, 0.0000001,
		"the coded fallback should match Pokemon GO's own 1/128, per the owner's report"
	)


# --- determinism: same seed -> same shiny outcome --------------------------

func test_same_seed_rolls_the_same_shiny_outcome_every_time() -> void:
	var first := (_roll("wild_spawn_determinism_check")["wild"] as FakeWildBody)
	var second := (_roll("wild_spawn_determinism_check")["wild"] as FakeWildBody)
	assert_eq(first.shiny, second.shiny, "the same seed must roll the same shiny outcome every boot")
	assert_eq(bool(first.instance.get("shiny")), bool(second.instance.get("shiny")))


func test_a_seed_below_the_odds_threshold_rolls_shiny() -> void:
	# Captured directly from the shipped roll sequence (3 IV draws, 2 trait
	# draws, 1 level draw, then this shiny draw): seed
	# "wild_spawn_scan_188" draws 0.00557978404686 as its 7th randf(), which
	# is below the shipped 0.0078 shiny_chance -- a known positive case,
	# not a hope that some random seed happens to land under the odds.
	var wild := _roll("wild_spawn_scan_188")["wild"] as FakeWildBody
	assert_true(wild.shiny, "seed 'wild_spawn_scan_188' should roll shiny at the shipped odds")
	assert_true(bool(wild.instance.get("shiny")), "the instance's own shiny field should agree with the body's")
	assert_eq(wild.shiny_set_calls, 1, "the body should be told its shiny status exactly once")


func test_a_seed_above_the_odds_threshold_does_not_roll_shiny() -> void:
	# Same capture as above: seed "wild_spawn_0" draws 0.34124219417572 as
	# its 7th randf(), well above 0.0078.
	var wild := _roll("wild_spawn_0")["wild"] as FakeWildBody
	assert_false(wild.shiny, "seed 'wild_spawn_0' should not roll shiny at the shipped odds")
	assert_false(bool(wild.instance.get("shiny")))
	assert_eq(wild.shiny_set_calls, 1, "the body should be told its (non-)shiny status exactly once")


# --- existing draws are unchanged: the whole reason shiny is drawn LAST ----

func test_existing_level_and_individuality_draws_are_unchanged_by_the_shiny_roll() -> void:
	# Captured from the ACTUAL pre-OF27 code, before `_roll_wild_level` grew
	# its extra rng.randf(), for seed "wild_spawn_0" against terrapup: level
	# 5, these exact IV rolls, this exact trait pair. OF27 adds its draw at
	# the END of the stream; if it had instead been mixed in earlier, or the
	# order of the existing draws had changed, these numbers would have
	# moved and this test would catch it -- which is the whole reason the
	# shiny draw is appended rather than interleaved.
	var instance: RefCounted = (_roll("wild_spawn_0")["wild"] as FakeWildBody).instance
	assert_eq(int(instance.get("level")), 5)
	assert_almost_eq(float(instance.get("iv_hp")), 0.35000461339951, 0.0000001)
	assert_almost_eq(float(instance.get("iv_attack")), 0.86640173196793, 0.0000001)
	assert_almost_eq(float(instance.get("iv_defence")), 0.72596281766891, 0.0000001)
	assert_eq(str(instance.get("trait_primary")), "gentle")
	assert_eq(str(instance.get("trait_secondary")), "stubborn")


func test_existing_level_and_individuality_draws_are_unchanged_for_a_second_seed() -> void:
	# A second pinned seed (the same one used for the "rolls shiny" case
	# above), so the "draws unchanged" proof does not rest on a single
	# example that happens not to roll shiny.
	var instance: RefCounted = (_roll("wild_spawn_scan_188")["wild"] as FakeWildBody).instance
	assert_eq(int(instance.get("level")), 2)
	assert_almost_eq(float(instance.get("iv_hp")), 0.20173750817776, 0.0000001)
	assert_almost_eq(float(instance.get("iv_attack")), 0.2114565372467, 0.0000001)
	assert_almost_eq(float(instance.get("iv_defence")), 0.25383248925209, 0.0000001)
	assert_eq(str(instance.get("trait_primary")), "stubborn")
	assert_eq(str(instance.get("trait_secondary")), "bold")
