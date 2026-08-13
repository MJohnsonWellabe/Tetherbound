extends "res://tests/test_case.gd"

## Pal progression (D30): the level curve, stat growth, wild level rolls, and
## bond — both the pure arithmetic in scripts/pals/progression.gd and the
## instance methods on scripts/pals/pal_instance.gd that call it.
##
## Like test_combat_math.gd, these pin the PROPERTIES a level-up has to have
## (strictly more xp needed each level, stats never shrink, an hp fraction
## survives a level-up) rather than specific tuned numbers from the shipped
## config — that file is TUNABLE (CLAUDE.md) and a test that pins its exact
## curve would fail every time the owner retunes it on the Ally. Where a test
## needs a concrete curve to assert exact level-up thresholds against, it
## builds its own small config rather than reading the shipped one.

const PROGRESSION := preload("res://scripts/pals/progression.gd")
const PAL := preload("res://scripts/pals/pal_instance.gd")

## A small, hand-built config with round numbers, so gain_xp's level-up
## thresholds and stat growth can be asserted exactly rather than merely
## "increased". xp_to_next_base=10, exponent=1.0 makes level N cost exactly
## 10*N xp — level 1->2 costs 10, 2->3 costs 20, and so on.
const CFG := {
	"level": {
		"cap": 5,
		"wild_band": [2, 6],
		"starter_level": 3,
		"xp_to_next_base": 10.0,
		"xp_to_next_exponent": 1.0,
		"growth_per_level": {"hp": 0.1, "attack": 0.1, "defence": 0.1},
	},
	"xp_award": {"base": 18, "per_enemy_level": 6, "party_share": 0.35},
	"bond": {
		"max": 100,
		"thresholds": [10, 30, 55, 80, 100],
		"effects_per_node": {"attack_scale": 0.01, "defence_scale": 0.01},
	},
}

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}


func _pal() -> RefCounted:
	return PAL.from_species("terrapup", DEFINITION)


# --- the pure curve (scripts/pals/progression.gd) ---------------------------

func test_xp_curve_is_strictly_increasing() -> void:
	var cfg := PROGRESSION.config()
	var previous := 0
	for level in range(1, 15):
		var next_threshold: int = PROGRESSION.xp_to_next(level, cfg)
		assert_true(next_threshold > previous,
			"level %d needs %d xp, which does not exceed level %d's %d" %
				[level, next_threshold, level - 1, previous])
		previous = next_threshold


func test_stat_at_level_one_equals_base_regardless_of_growth() -> void:
	assert_almost_eq(PROGRESSION.stat_at_level(100.0, 1, 0.06), 100.0, 0.0001)
	assert_almost_eq(PROGRESSION.stat_at_level(100.0, 1, 0.0), 100.0, 0.0001)


func test_stat_at_level_grows_with_level() -> void:
	var low := PROGRESSION.stat_at_level(100.0, 1, 0.05)
	var high := PROGRESSION.stat_at_level(100.0, 10, 0.05)
	assert_true(high > low, "a higher level should never have a lower stat")


func test_roll_wild_level_spans_the_configured_band() -> void:
	var cfg := PROGRESSION.config()
	var band: Array = cfg.get("level", {}).get("wild_band", [1, 1])
	assert_eq(PROGRESSION.roll_wild_level(cfg, 0.0), int(band[0]), "roll 0.0 should be the band's floor")
	assert_eq(PROGRESSION.roll_wild_level(cfg, 1.0), int(band[1]), "roll 1.0 should be the band's ceiling")


func test_bond_node_thresholds_match_the_shipped_boundaries() -> void:
	var cfg := PROGRESSION.config()
	assert_eq(PROGRESSION.bond_nodes(9, cfg), 0, "just under the first threshold should earn nothing")
	assert_eq(PROGRESSION.bond_nodes(10, cfg), 1, "hitting the first threshold should earn one node")
	assert_eq(PROGRESSION.bond_nodes(100, cfg), 5, "maxed bond should earn every node")


func test_bond_stat_scale_is_one_at_zero_nodes() -> void:
	var cfg := PROGRESSION.config()
	assert_almost_eq(PROGRESSION.bond_stat_scale(0, "attack_scale", cfg), 1.0, 0.0001,
		"a pal with no bond nodes should fight at its plain stats")


func test_bond_stat_scale_grows_with_nodes() -> void:
	var cfg := PROGRESSION.config()
	var per_node := float(cfg.get("bond", {}).get("effects_per_node", {}).get("attack_scale", 0.0))
	var scaled := PROGRESSION.bond_stat_scale(3, "attack_scale", cfg)
	assert_almost_eq(scaled, 1.0 + 3.0 * per_node, 0.0001)


func test_xp_award_for_grows_with_enemy_level() -> void:
	var cfg := PROGRESSION.config()
	var low: int = PROGRESSION.xp_award_for(2, cfg)
	var high: int = PROGRESSION.xp_award_for(6, cfg)
	assert_true(high > low, "a tougher enemy should pay out more xp")


func test_party_share_floors_the_split() -> void:
	var cfg := PROGRESSION.config()
	var share := float(cfg.get("xp_award", {}).get("party_share", 0.35))
	assert_eq(PROGRESSION.party_share(10, cfg), int(floor(10.0 * share)))


# --- pal_instance.gd: from_species compatibility -----------------------------

func test_from_species_with_no_new_args_reproduces_old_behavior() -> void:
	var pal := PAL.from_species("terrapup", DEFINITION)
	assert_eq(pal.level, 1)
	assert_eq(pal.xp, 0)
	assert_eq(pal.bond, 0)
	assert_almost_eq(pal.max_hp, 100.0, 0.0001)
	assert_almost_eq(pal.attack, 20.0, 0.0001)
	assert_almost_eq(pal.defence, 20.0, 0.0001)
	assert_eq(pal.hp, pal.max_hp)


func test_from_species_with_only_a_roll_and_no_cfg_stays_level_one() -> void:
	# A roll with nothing to read the wild band from must not guess.
	var pal := PAL.from_species("terrapup", DEFINITION, 1.0)
	assert_eq(pal.level, 1)


func test_from_species_with_a_roll_and_cfg_levels_up_the_spawn() -> void:
	var pal := PAL.from_species("terrapup", DEFINITION, 1.0, CFG)
	assert_eq(pal.level, 6, "roll 1.0 against wild_band [2, 6] should spawn at the top")
	assert_almost_eq(pal.max_hp, 150.0, 0.0001, "level 6 at growth 0.1 should be 100 * (1 + 0.1*5)")
	assert_eq(pal.hp, pal.max_hp, "a fresh spawn should be whole regardless of its rolled level")


func test_from_species_moves_come_from_the_species_definition() -> void:
	var definition := DEFINITION.duplicate(true)
	definition["moves"] = {"quick": "pebble_toss", "charged": "stone_rush"}
	var pal := PAL.from_species("terrapup", definition)
	assert_eq(pal.move_quick, "pebble_toss")
	assert_eq(pal.move_charged, "stone_rush")


func test_from_species_with_no_moves_field_degrades_to_empty_strings() -> void:
	var pal := PAL.from_species("terrapup", DEFINITION)
	assert_eq(pal.move_quick, "")
	assert_eq(pal.move_charged, "")


# --- pal_instance.gd: gain_xp -------------------------------------------------

func test_gain_xp_does_not_level_up_below_the_threshold() -> void:
	var pal := _pal()
	var gained: int = pal.gain_xp(9, CFG)
	assert_eq(gained, 0)
	assert_eq(pal.level, 1)
	assert_eq(pal.xp, 9)


func test_gain_xp_levels_up_at_the_exact_threshold() -> void:
	var pal := _pal()
	pal.gain_xp(9, CFG)
	var gained: int = pal.gain_xp(1, CFG)
	assert_eq(gained, 1)
	assert_eq(pal.level, 2)
	assert_eq(pal.xp, 0, "the spent xp should be removed, not just flagged")


func test_gain_xp_can_chain_multiple_level_ups_in_one_award() -> void:
	var pal := _pal()
	# 10 to reach level 2, 20 more to reach level 3: 30 total.
	var gained: int = pal.gain_xp(30, CFG)
	assert_eq(gained, 2)
	assert_eq(pal.level, 3)
	assert_eq(pal.xp, 0)


func test_gain_xp_grows_stats_by_the_configured_growth() -> void:
	var pal := _pal()
	pal.gain_xp(10, CFG)
	assert_eq(pal.level, 2)
	assert_almost_eq(pal.max_hp, 110.0, 0.0001)
	assert_almost_eq(pal.attack, 22.0, 0.0001)
	assert_almost_eq(pal.defence, 22.0, 0.0001)


func test_gain_xp_preserves_hp_fraction_through_a_level_up() -> void:
	var pal := _pal()
	pal.take_damage(50.0)
	assert_almost_eq(pal.hp_fraction(), 0.5, 0.0001)
	pal.gain_xp(10, CFG)
	assert_almost_eq(pal.hp_fraction(), 0.5, 0.0001, "a level-up must not top up or waste hp")
	assert_almost_eq(pal.hp, 55.0, 0.0001, "50% of the new, larger max_hp")


func test_gain_xp_respects_the_level_cap() -> void:
	var pal := _pal()
	pal.gain_xp(100000, CFG)
	assert_eq(pal.level, 5, "the cap in CFG is 5")


func test_gain_xp_of_zero_or_negative_does_nothing() -> void:
	var pal := _pal()
	assert_eq(pal.gain_xp(0, CFG), 0)
	assert_eq(pal.gain_xp(-5, CFG), 0)
	assert_eq(pal.xp, 0)
	assert_eq(pal.level, 1)


func test_xp_to_next_matches_the_static_curve() -> void:
	var pal := _pal()
	assert_eq(pal.xp_to_next(CFG), PROGRESSION.xp_to_next(pal.level, CFG))


# --- pal_instance.gd: bond ----------------------------------------------------

func test_gain_bond_accumulates() -> void:
	var pal := _pal()
	pal.gain_bond(4, CFG)
	pal.gain_bond(4, CFG)
	assert_eq(pal.bond, 8)


func test_gain_bond_clamps_at_the_configured_max() -> void:
	var pal := _pal()
	pal.gain_bond(1000, CFG)
	assert_eq(pal.bond, 100)


func test_gain_bond_of_zero_or_negative_does_nothing() -> void:
	var pal := _pal()
	pal.gain_bond(10, CFG)
	pal.gain_bond(0, CFG)
	pal.gain_bond(-50, CFG)
	assert_eq(pal.bond, 10)


func test_pal_bond_nodes_matches_the_static_function() -> void:
	var pal := _pal()
	pal.bond = 55
	assert_eq(pal.bond_nodes(CFG), PROGRESSION.bond_nodes(55, CFG))
