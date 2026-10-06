extends TestCase

## Tonics: creature_instance.gd's timed buffs (the potions board's temporary
## half; the permanent half is D47's elixirs and tests/test_progression.gd's
## drink_elixir coverage).
##
## Pure logic per D02 -- apply/refresh/expiry/product arithmetic, plus the two
## multiplication points a fight actually reads. Whether a tonic FEELS right
## is a play question; whether it stacks, leaks or survives its own clock is
## exactly what a unit can pin.

const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}

var creature: RefCounted = null


func before_each() -> void:
	creature = CREATURE_INSTANCE.from_species("terrapup", DEFINITION)


func test_no_buffs_means_scale_one() -> void:
	assert_almost_eq(float(creature.buff_scale("attack")), 1.0, 0.0001,
		"an unbuffed creature must multiply by exactly 1.0")


func test_apply_buff_scales_the_named_stat_only() -> void:
	assert_true(creature.apply_buff("attack_tonic", "attack", 1.2, 90.0))
	assert_almost_eq(float(creature.buff_scale("attack")), 1.2, 0.0001)
	assert_almost_eq(float(creature.buff_scale("defence")), 1.0, 0.0001,
		"an attack tonic must not touch defence")


func test_effective_attack_reads_the_buff() -> void:
	var cfg := PROGRESSION.config()
	var before: float = float(creature.effective_attack(cfg))
	creature.apply_buff("attack_tonic", "attack", 1.2, 90.0)
	assert_almost_eq(float(creature.effective_attack(cfg)), before * 1.2, 0.01,
		"effective_attack must carry the tonic's multiplier")


func test_effective_defence_reads_the_buff() -> void:
	var cfg := PROGRESSION.config()
	var before: float = float(creature.effective_defence(cfg))
	creature.apply_buff("stoneguard_brew", "defence", 1.2, 90.0)
	assert_almost_eq(float(creature.effective_defence(cfg)), before * 1.2, 0.01)


func test_redrinking_refreshes_the_clock_not_the_multiplier() -> void:
	creature.apply_buff("attack_tonic", "attack", 1.2, 90.0)
	creature.tick_buffs(60.0)
	creature.apply_buff("attack_tonic", "attack", 1.2, 90.0)
	assert_almost_eq(float(creature.buff_scale("attack")), 1.2, 0.0001,
		"re-drinking must refresh, never stack -- 1.2, not 1.44")
	creature.tick_buffs(60.0)
	assert_almost_eq(float(creature.buff_scale("attack")), 1.2, 0.0001,
		"the refreshed clock must still be running at what would have been expiry")


func test_two_different_tonics_multiply_together_on_one_stat() -> void:
	creature.apply_buff("attack_tonic", "attack", 1.2, 90.0)
	creature.apply_buff("war_drum", "attack", 1.1, 90.0)
	assert_almost_eq(float(creature.buff_scale("attack")), 1.32, 0.0001,
		"distinct buff ids on one stat are a product, not a max")


func test_a_buff_expires_on_its_clock() -> void:
	creature.apply_buff("attack_tonic", "attack", 1.2, 90.0)
	creature.tick_buffs(89.9)
	assert_almost_eq(float(creature.buff_scale("attack")), 1.2, 0.0001, "still live at 89.9s")
	creature.tick_buffs(0.2)
	assert_almost_eq(float(creature.buff_scale("attack")), 1.0, 0.0001, "gone past 90s")
	assert_eq((creature.get("active_buffs") as Array).size(), 0, "the expired entry must be removed")


func test_garbage_is_refused_without_a_trace() -> void:
	assert_false(creature.apply_buff("", "attack", 1.2, 90.0), "empty id refused")
	assert_false(creature.apply_buff("x", "", 1.2, 90.0), "empty stat refused")
	assert_false(creature.apply_buff("x", "attack", 0.0, 90.0), "zero scale refused")
	assert_false(creature.apply_buff("x", "attack", 1.2, 0.0), "zero duration refused")
	assert_eq((creature.get("active_buffs") as Array).size(), 0)


func test_ticking_with_no_buffs_is_a_no_op() -> void:
	creature.tick_buffs(5.0)
	assert_eq((creature.get("active_buffs") as Array).size(), 0)


func test_authored_mushrooms_boost_the_drinker_refresh_expire_and_remain_unsaved() -> void:
	var items := preload("res://autoload/item_db.gd").new()
	var commands := preload("res://scripts/combat/tether_commands.gd")
	var party := preload("res://autoload/party.gd").new()
	assert_true(party.add(creature))
	var saver := preload("res://scripts/save/save_game.gd").new()
	var before: Array = saver._party_to_array(party)
	var cfg := PROGRESSION.config()
	var attack_before: float = creature.effective_attack(cfg)
	var defence_before: float = creature.effective_defence(cfg)
	for item: String in ["speed_mushroom", "wild_mushroom"]:
		var definition: Dictionary = items.definition(item)
		assert_true(commands.support_item(definition), "the real authored consumable is supported in the command pouch")
		var buff: Dictionary = definition.creature_buff
		assert_true(creature.apply_buff(str(buff.id), str(buff.stat), float(buff.scale), float(buff.duration_s)))
		assert_true(float(creature.buff_scale(str(buff.stat))) > 1.0, item + " promises faster or stronger, so must increase the stat")
		if buff.stat == "attack":
			assert_true(float(creature.effective_attack(cfg)) > attack_before, "the real attack consumer must become stronger")
			assert_almost_eq(float(creature.effective_attack(cfg)), attack_before * float(buff.scale), 0.001)
		assert_almost_eq(float(creature.effective_defence(cfg)), defence_before, 0.001)
		creature.tick_buffs(float(buff.duration_s) / 2.0)
		assert_true(creature.apply_buff(str(buff.id), str(buff.stat), float(buff.scale), float(buff.duration_s)))
		assert_eq(creature.active_buffs.size(), 1, "re-drinking refreshes the same effect")
		assert_almost_eq(float(creature.buff_scale(str(buff.stat))), float(buff.scale), 0.0001, "refresh cannot stack the multiplier")
		assert_eq(saver._party_to_array(party), before, "temporary stats never change the complete saved creature row")
		creature.tick_buffs(float(buff.duration_s) - 0.1)
		assert_almost_eq(float(creature.buff_scale(str(buff.stat))), float(buff.scale), 0.0001)
		creature.tick_buffs(0.2)
		assert_true(creature.active_buffs.is_empty())
		assert_almost_eq(float(creature.buff_scale(str(buff.stat))), 1.0, 0.0001)
		assert_almost_eq(float(creature.effective_attack(cfg)), attack_before, 0.001)
