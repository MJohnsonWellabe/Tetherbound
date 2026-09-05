extends "res://tests/test_case.gd"

## W23-DIFFICULTY (docs/decisions/D77) -- the two code paths the baseline
## retune added, and the one ordering rule that keeps the G-2 profiles honest.
##
## Why this is worth a build. The owner reproduced "beating creatures and
## other trainers is way too easy" on hardware, and the fix is three numbers
## and two merges: `combat.json`'s `enemy_trainer` overlay (a trainer's body
## fights off a drilled baseline), `enemy.damage_scale` (every opponent hits
## harder by one ratio, applied AFTER the per-body merge so the authored
## profiles keep their shapes), and the aggressor's chase speed. None of them
## crash when they stop applying: the overlay silently not reaching a trainer
## body, or the scale being authored away by a band file, puts the chapter
## straight back to the fight the owner called trivial, with every smoke
## still green. tests/smoke_combat_baseline.gd measures the outcome; this file
## pins the mechanism.

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")

const _CURRENT := {"attack_cooldown": 0.7, "recovery": 0.55, "reposition_time": 0.5, "power": 6.4}


func _config_for(override: Dictionary, trainer_owned: bool) -> Dictionary:
	var body := WILD.new()
	body.combat_override = override
	body.trainer_owned = trainer_owned
	var cfg: Dictionary = body._enemy_config_for_this_body()
	body.free()
	return cfg


func _movement() -> Dictionary:
	var file := FileAccess.open("res://data/config/movement.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


# --- the trainer overlay -----------------------------------------------------

func test_the_shipped_trainer_overlay_exists_and_only_uses_enemy_keys() -> void:
	var overlay: Dictionary = MATH.config().get("enemy_trainer", {})
	assert_false(overlay.is_empty(), "combat.json has no `enemy_trainer` block; a trainer's creature fights exactly like a field animal again")
	var enemy: Dictionary = MATH.config().get("enemy", {})
	for key: String in overlay:
		if key.begins_with("_comment"):
			continue
		assert_true(enemy.has(key), "enemy_trainer.%s is not a key of the `enemy` block and can never reach the AI" % key)


func test_a_wild_body_never_sees_the_trainer_overlay() -> void:
	# G-2's own contract: an ordinary wild's fight is the shipped `enemy` block,
	# byte for byte. The overlay is a trainer's, and a wild is not owned.
	var shipped: Dictionary = MATH.config().get("enemy", {})
	assert_eq(_config_for({}, false), shipped,
		"a wild body with no override must still get the shipped enemy block unchanged")


func test_a_trainers_body_fights_off_the_overlay() -> void:
	var overlay: Dictionary = MATH.config().get("enemy_trainer", {})
	var got := _config_for({}, true)
	var applied := 0
	for key: String in overlay:
		if key.begins_with("_comment"):
			continue
		assert_eq(got.get(key), overlay[key],
			"a trainer-owned body should fight with enemy_trainer.%s, not the wild baseline" % key)
		applied += 1
	assert_true(applied > 0, "the overlay changed nothing; a trainer's creature is a wild with a person behind it")
	# And everything the overlay does not name is still the wild baseline.
	var shipped: Dictionary = MATH.config().get("enemy", {})
	for key: String in shipped:
		if overlay.has(key) or key.begins_with("_comment"):
			continue
		assert_eq(got.get(key), shipped[key], "the overlay erased enemy.%s instead of laying over it" % key)


func test_a_members_own_profile_wins_over_the_trainer_overlay() -> void:
	# The Warden's Brooktail is CURRENT: short cooldown, small hits. The
	# overlay is the baseline UNDER it, never a voice over it -- if the overlay
	# won, every profile would quietly become the same drilled grunt.
	var got := _config_for(_CURRENT.duplicate(), true)
	for key: String in _CURRENT:
		assert_eq(got.get(key), _CURRENT[key],
			"the member's authored %s must win over enemy_trainer's" % key)
	var overlay: Dictionary = MATH.config().get("enemy_trainer", {})
	for key: String in overlay:
		if key.begins_with("_comment") or _CURRENT.has(key):
			continue
		assert_eq(got.get(key), overlay[key],
			"a key the profile does not name should still come from the overlay (%s)" % key)


# --- damage_scale ------------------------------------------------------------

func test_damage_scale_multiplies_the_power_the_strike_actually_uses() -> void:
	var cfg := {"power": 8.0, "damage_scale": 1.5, "preferred_range": 2.1, "range": 2.6, "body_clearance": 2.0}
	var spaced: Dictionary = WILD.spaced_config_for(cfg, 0.5, 0.5)
	assert_almost_eq(float(spaced["power"]), 12.0, 0.0001,
		"spaced power should be power x damage_scale (8 x 1.5)")
	# And absent, byte for byte the old arithmetic: the scale defaults to 1.
	var plain: Dictionary = WILD.spaced_config_for({"power": 8.0, "body_clearance": 2.0}, 0.5, 0.5)
	assert_almost_eq(float(plain["power"]), 8.0, 0.0001, "no damage_scale means the authored power, unchanged")


func test_damage_scale_keeps_the_profiles_ratios() -> void:
	# The whole reason it is a separate key: WALL authors 12.0 against the 8.0
	# baseline. Scaled, a WALL still hits 1.5x a wild -- never less.
	var base: Dictionary = MATH.config().get("enemy", {})
	var wild: Dictionary = WILD.spaced_config_for(_config_for({}, false), 0.5, 0.5)
	var wall: Dictionary = WILD.spaced_config_for(_config_for({"power": 12.0}, false), 0.5, 0.5)
	var ratio := float(wall["power"]) / float(wild["power"])
	assert_almost_eq(ratio, 12.0 / float(base.get("power", 8.0)), 0.0001,
		"a WALL's hit should stay exactly its authored ratio over a wild's after the scale")
	assert_true(float(wild["power"]) > float(base.get("power", 8.0)),
		"the shipped damage_scale should make a wild hit HARDER than the raw `power` (%.1f), or D77 did not land" % float(base.get("power", 8.0)))


func test_no_band_file_can_author_damage_scale() -> void:
	# An override may say `power`; it may not reach for the chapter-wide scale.
	var got := _config_for({"damage_scale": 99.0}, false)
	assert_almost_eq(float(got.get("damage_scale", 1.0)), float(MATH.config().get("enemy", {}).get("damage_scale", 1.0)), 0.0001,
		"an override authored damage_scale and it reached the body; the scale is one chapter-wide number, not an encounter's")


func test_the_shipped_scale_one_shots_nothing_at_band_entry() -> void:
	# G-3's own fails-if, on the heaviest authored hit in the chapter (the
	# Warden's ACE, power 14.4) against the lowest-health creature of the
	# region's entry level. Deliberately generous to the defender: the ACE
	# has attack 24 at base; a pipwing at level 17 has 78 base hp.
	var prog: Dictionary = preload("res://scripts/creatures/progression.gd").config()
	var growth: Dictionary = (prog.get("level", {}) as Dictionary).get("growth_per_level", {})
	var pipwing_hp := 78.0 * (1.0 + float(growth.get("hp", 0.06)) * 16.0)
	var ace_attack := 24.0 * (1.0 + float(growth.get("attack", 0.05)) * 19.0)
	var pipwing_def := 10.0 * (1.0 + float(growth.get("defence", 0.05)) * 16.0)
	var scale := float(MATH.config().get("enemy", {}).get("damage_scale", 1.0))
	# rock_throw 1.15 x the worst-case 1.1 variance roll.
	var hit := MATH.base_damage(14.4 * scale, ace_attack, pipwing_def, 1.15) * 1.1
	assert_true(hit < pipwing_hp * 0.5,
		"the ACE's hardest hit (%.1f) takes more than half a level-17 Pipwing (%.1f hp); G-3 says a one-shot is a fail and this is on the way to one" % [hit, pipwing_hp])


# --- the aggressor --------------------------------------------------------------

func test_an_aggressive_creature_can_catch_a_walking_trainer() -> void:
	# GAME_DESIGN.md pillar 3: the aggressive kind INITIATES. It cannot if it
	# is slower than a walk -- catching.json shipped chase_speed 3.4 against a
	# 5.0 walk for the whole chapter, so the ambush was scenery. It must still
	# be escapable: slower than a sprint.
	var chase := float(CATCH.config().get("aggression", {}).get("chase_speed", 0.0))
	var loco: Dictionary = _movement().get("locomotion", {})
	assert_true(chase > float(loco.get("walk_speed", 5.0)),
		"an aggressor chases at %.1f m/s and the trainer walks at %.1f; it can never start the fight it exists to start" % [chase, float(loco.get("walk_speed", 5.0))])
	assert_true(chase < float(loco.get("sprint_speed", 8.6)),
		"an aggressor chases at %.1f m/s, faster than the %.1f sprint; there is no escaping it, which is a corridor, not danger" % [chase, float(loco.get("sprint_speed", 8.6))])
