extends "res://tests/test_case.gd"

const FEED := preload("res://scripts/creatures/progression_feed.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BOND := preload("res://scripts/creatures/bond_milestones.gd")
const REST := preload("res://scripts/creatures/home_recovery.gd")
const HUD := preload("res://scripts/ui/progression_feedback_hud.gd")
const GAME := preload("res://autoload/game_state.gd")


func _creature(feed: RefCounted) -> RefCounted:
	var creature: RefCounted = SPECIES.spawn("mudsnout")
	creature.set_meta("progression_sink", feed.push_event)
	return creature


func _kind(events: Array, kind: String) -> Array:
	return events.filter(func(event: Dictionary) -> bool: return str(event.kind) == kind)


func test_three_level_jump_produces_one_transition_and_one_xp_event() -> void:
	var feed := FEED.new()
	var creature := _creature(feed)
	var amount := 0
	for level in range(int(creature.level), int(creature.level) + 3):
		amount += PROGRESSION.xp_to_next(level, PROGRESSION.config())
	assert_eq(creature.gain_xp(amount, PROGRESSION.config()), 3)
	var events := feed.drain()
	assert_eq(_kind(events, "xp_gained").size(), 1)
	var moments := _kind(events, "level_up")
	assert_eq(moments.size(), 1)
	assert_eq(moments[0].levels_gained, 3)
	assert_true(float(moments[0].stat_deltas.hp) > 0)
	assert_false(moments[0].trait_unlocked)
	var revision := feed.revision
	assert_true(feed.drain().is_empty())
	assert_eq(feed.revision, revision)
	assert_eq(feed.latest_for(creature.get_instance_id(), "level_up"), moments[0])


func test_candy_and_rest_use_the_same_instance_event_source() -> void:
	var feed := FEED.new()
	var creature := _creature(feed)
	creature.set_level(int(creature.level) + 1, PROGRESSION.config())
	var events := feed.drain()
	assert_eq(_kind(events, "xp_gained").size(), 1)
	assert_eq(_kind(events, "level_up").size(), 1)
	assert_eq(events[0].source, "level_item")
	REST.rest(creature, PROGRESSION.config())
	assert_eq(_kind(feed.drain(), "xp_gained").size(), 1)


func test_all_five_actions_emit_credit_even_before_their_ordered_turn() -> void:
	var feed := FEED.new()
	var creature := _creature(feed)
	BOND.credit_battle(creature)
	BOND.credit_landmark_visit(creature)
	BOND.credit_distance(creature, 12)
	BOND.credit_rest_night(creature)
	BOND.credit_feed(creature)
	assert_eq(_kind(feed.drain(), "bond_credit").size(), 5)
	assert_eq(BOND.tier(creature, BOND.config()), 0)
	var description := BOND.all_progress_text(creature)
	assert_true(description.contains("1/50"))
	assert_true(description.contains("1/10"))
	assert_true(description.contains("next"))
	assert_true(description.contains("counts now; later node"))


func test_near_threshold_and_milestone_benefit_emit_once_on_crossing() -> void:
	var feed := FEED.new()
	var creature := _creature(feed)
	creature.battles_fought = 43
	BOND.credit_battle(creature)
	assert_true(_kind(feed.drain(), "bond_near").is_empty())
	BOND.credit_battle(creature)
	var near := _kind(feed.drain(), "bond_near")
	assert_eq(near.size(), 1)
	assert_eq(near[0].remaining, 5.0)
	BOND.credit_battle(creature)
	assert_true(_kind(feed.drain(), "bond_near").is_empty())
	creature.battles_fought = 49
	BOND.credit_battle(creature)
	var moments := _kind(feed.drain(), "bond_milestone")
	assert_eq(moments.size(), 1)
	assert_eq(moments[0].node_index, 1)
	assert_true(str(moments[0].benefit).contains("+1% attack and defence"))
	BOND.credit_battle(creature)
	assert_true(_kind(feed.drain(), "bond_milestone").is_empty())


func test_game_feed_keeps_nonactive_owned_members_and_rejects_trainer_spawns() -> void:
	var game := GAME.new()
	game.reset_for_new_game()
	var active := SPECIES.spawn("mudsnout")
	var other := SPECIES.spawn("bramblebun")
	var trainer := SPECIES.spawn("galecrest")
	game.party.add(active)
	game.party.add(other)
	game.push_progression_event(other, {"kind": "xp_gained", "instance_id": other.get_instance_id(), "display_name": other.label(), "amount": 5})
	game.push_progression_event(trainer, {"kind": "xp_gained", "instance_id": trainer.get_instance_id(), "display_name": trainer.label(), "amount": 5})
	var before: int = game.progression_feed.revision
	var events: Array = game.drain_progression_events()
	assert_eq(events.size(), 1)
	assert_eq(events[0].instance_id, other.get_instance_id())
	assert_true(game.progression_feed.revision > before)
	assert_eq(game.party.size(), 2)
	game.free()
