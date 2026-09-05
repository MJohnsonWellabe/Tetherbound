extends "res://tests/test_case.gd"

## PROGRESSION-VISIBLE (docs/prompts/73 §4, D76): the progression feed.
##
## Every kind in §2.1 is pushed exactly once by its single source; a 3-level
## jump is ONE `level_up` with `levels_gained == 3`; a non-active party
## member's award is in the feed; draining empties it and bumps the revision.
## Everything here RUNS the real producers (`creature_instance.gain_xp`,
## `bond_milestones.credit`) and reads the log back -- nothing greps a script.

const FEED := preload("res://scripts/creatures/progression_feed.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const BOND := preload("res://scripts/creatures/bond_milestones.gd")
const PARTY := preload("res://autoload/party.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}

## A flat curve so the arithmetic is legible: level L needs 10*L xp, so a
## fresh level-1 creature reaches level 4 on exactly 10 + 20 + 30 = 60 xp.
const CFG := {
	"level": {
		"cap": 50, "xp_to_next_base": 10.0, "xp_to_next_exponent": 1.0,
		"growth_per_level": {"hp": 0.06, "attack": 0.05, "defence": 0.05},
	},
	"xp_award": {"base": 30, "per_enemy_level": 16, "party_share": 0.5},
	"bond": {"effects_per_node": {"attack_scale": 0.01, "defence_scale": 0.01}},
	"traits": {"unlock_bond_nodes": 3},
	"evolution": {},
	"milestones": [
		{"task": "battles_fought", "target": 4, "name": "wild creatures defeated together"},
		{"task": "landmarks_visited_together", "target": 1, "name": "landmarks discovered together"},
		{"task": "feeds_together", "target": 3, "name": "meals fed together"},
	],
}


func before_each() -> void:
	FEED.clear()


func _creature(name: String = "") -> RefCounted:
	var c: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	c.nickname = name
	return c


func _of_kind(kind: String) -> Array:
	var out: Array = []
	for event: Variant in FEED.events():
		if str((event as Dictionary).get("kind", "")) == kind:
			out.append(event)
	return out


# --- xp_gained / level_up: one source, creature_instance.gain_xp -----------

func test_an_award_without_a_level_pushes_exactly_one_xp_gained_and_no_level_up() -> void:
	var c := _creature("Tup")
	c.gain_xp(5, CFG)
	var xp := _of_kind("xp_gained")
	assert_eq(xp.size(), 1, "one award, one xp_gained")
	assert_eq(_of_kind("level_up").size(), 0, "no level was gained")
	var event: Dictionary = xp[0]
	assert_eq(int(event.get("amount", 0)), 5)
	assert_eq(int(event.get("xp", -1)), 5)
	assert_eq(int(event.get("xp_to_next", 0)), 10)
	assert_eq(int(event.get("level", 0)), 1)
	assert_eq(str(event.get("name", "")), "Tup", "the event names the creature")
	assert_eq(int(event.get("creature_id", 0)), c.get_instance_id(), "the event carries the instance id")


func test_a_three_level_jump_pushes_one_level_up_with_levels_gained_three() -> void:
	var c := _creature("Tup")
	var hp_before: float = c.max_hp
	c.gain_xp(60, CFG)
	assert_eq(int(c.level), 4, "sanity: 60 xp on the flat curve is exactly three levels")
	var ups := _of_kind("level_up")
	assert_eq(ups.size(), 1, "three levels in one award must be ONE level_up, never three")
	var event: Dictionary = ups[0]
	assert_eq(int(event.get("levels_gained", 0)), 3)
	assert_eq(int(event.get("old_level", 0)), 1)
	assert_eq(int(event.get("new_level", 0)), 4)
	assert_almost_eq(float(event.get("hp_delta", 0.0)), c.max_hp - hp_before, 0.001,
		"the event carries the stat delta the level actually produced")
	assert_true(float(event.get("attack_delta", 0.0)) > 0.0, "attack grew and the event says so")
	assert_eq(_of_kind("xp_gained").size(), 1, "the xp_gained still fires once alongside it")


func test_a_zero_or_negative_award_pushes_nothing() -> void:
	var c := _creature()
	c.gain_xp(0, CFG)
	c.gain_xp(-4, CFG)
	assert_eq(FEED.events().size(), 0)


func test_level_up_reports_the_second_trait_when_bond_reveals_one() -> void:
	var c := _creature("Tup")
	c.trait_secondary = "keen"
	# CFG's trait unlock is 3 nodes; give the creature all three tasks first.
	c.battles_fought = 4
	c.landmarks_visited_together = 1
	c.feeds_together = 3
	c.gain_xp(10, CFG)
	var event: Dictionary = _of_kind("level_up")[0]
	assert_true(bool(event.get("trait_unlocked", false)),
		"a creature whose bond reveals its second trait must say so on the level_up")
	var lonely := _creature("Solo")
	lonely.gain_xp(10, CFG)
	var quiet: Dictionary = _of_kind("level_up")[1]
	assert_false(bool(quiet.get("trait_unlocked", true)),
		"a creature with no second trait to reveal must not claim one")


func test_level_up_reports_the_evolution_gate() -> void:
	var cfg := CFG.duplicate(true)
	cfg["evolution"] = {"terrapup": {"level": 3, "bond_tier": 1, "item_id": ""}}
	var c := _creature("Tup")
	c.gain_xp(30, cfg)  # 1 -> 3, crossing the level gate, bond tier 0
	var first: Dictionary = _of_kind("level_up")[0]
	assert_true(bool(first.get("evolution_level_reached", false)),
		"crossing the evolution level must be reported")
	assert_false(bool(first.get("evolution_ready", true)),
		"level met but bond tier 0 of 1: not ready yet")
	c.landmarks_visited_together = 1  # tier 1
	c.gain_xp(30, cfg)  # 3 -> 4
	var second: Dictionary = _of_kind("level_up")[1]
	assert_true(bool(second.get("evolution_ready", false)),
		"level and bond both met: the level_up says evolution is ready")
	assert_false(bool(second.get("evolution_level_reached", true)),
		"the level gate was crossed on the previous jump, not this one")


func test_candy_gain_levels_pushes_one_level_up_with_the_candy_source() -> void:
	var c := _creature("Tup")
	c.xp = 7
	var gained: int = c.gain_levels(3, CFG)
	assert_eq(gained, 3)
	assert_eq(int(c.level), 4)
	assert_eq(int(c.xp), 7, "banked xp survives a candy (it is not the spawn jump)")
	var ups := _of_kind("level_up")
	assert_eq(ups.size(), 1, "Rare Candy is one level_up, levels_gained 3")
	assert_eq(int((ups[0] as Dictionary).get("levels_gained", 0)), 3)
	assert_eq(str((ups[0] as Dictionary).get("source", "")), "candy")
	assert_eq(_of_kind("xp_gained").size(), 0, "a candy grants levels, not xp")


func test_set_level_is_the_silent_spawn_jump() -> void:
	var c := _creature()
	c.set_level(12, CFG)
	assert_eq(FEED.events().size(), 0,
		"set_level is the starter/trainer/trade spawn path and must not announce (D76 §3)")


# --- the bond kinds: one source, bond_milestones.credit --------------------

func test_each_crediting_helper_pushes_exactly_one_bond_credit() -> void:
	var c := _creature("Tup")
	BOND.credit_battle(c)
	assert_eq(_of_kind("bond_credit").size(), 1, "a won fight is one bond_credit")
	assert_eq(str((_of_kind("bond_credit")[0] as Dictionary).get("task", "")), "battles_fought")
	BOND.credit_landmark_visit(c)
	assert_eq(_of_kind("bond_credit").size(), 2)
	BOND.credit_rest_night(c)
	assert_eq(_of_kind("bond_credit").size(), 3)
	BOND.credit_feed(c)
	assert_eq(_of_kind("bond_credit").size(), 4)
	var last: Dictionary = _of_kind("bond_credit")[3]
	assert_eq(str(last.get("task", "")), "feeds_together")
	assert_eq(int(last.get("before", -1)), 0)
	assert_eq(int(last.get("after", -1)), 1)
	assert_eq(int(c.feeds_together), 1, "the counter itself moved")


func test_distance_ticks_once_per_configured_step_not_per_poll() -> void:
	var c := _creature("Tup")
	var step := float(FEED.config().get("distance_tick_m", 250))
	# Forty small polls that together cross one step exactly once.
	for i in 40:
		BOND.credit_distance(c, step / 40.0 + 0.001)
	assert_eq(_of_kind("bond_credit").size(), 1,
		"distance is credited every poll but must TICK only once per %d m" % int(step))
	assert_true(float(c.distance_m_together) > step, "the metres themselves all landed")


func test_bond_credit_via_the_creature_battle_method_is_the_same_path() -> void:
	var c := _creature("Tup")
	c.credit_battle_fought()
	assert_eq(int(c.battles_fought), 1)
	assert_eq(_of_kind("bond_credit").size(), 1)


func test_bond_near_fires_at_the_configured_remaining_count_and_not_before() -> void:
	var c := _creature("Tup")
	var threshold := int(FEED.near_threshold("feeds_together"))
	var target := 0
	for entry: Variant in BOND.milestones(BOND.config()):
		if str((entry as Dictionary).get("task", "")) == "feeds_together":
			target = int((entry as Dictionary).get("target", 0))
	assert_true(threshold > 0 and target > threshold, "sanity: the shipped feeds task has a near band")
	for i in target - threshold - 1:
		BOND.credit_feed(c)
	assert_eq(_of_kind("bond_near").size(), 0,
		"%d of %d meals is more than %d short: not near yet" % [c.feeds_together, target, threshold])
	BOND.credit_feed(c)
	var near := _of_kind("bond_near")
	assert_eq(near.size(), 1, "exactly %d short of the target is the near line" % threshold)
	assert_eq(int((near[0] as Dictionary).get("remaining", -1)), threshold)
	assert_eq(str((near[0] as Dictionary).get("task", "")), "feeds_together")


func test_bond_milestone_fires_once_when_a_task_completes_and_carries_the_benefit() -> void:
	var c := _creature("Tup")
	var result := {}
	for i in 3:
		result = BOND.credit(c, "feeds_together", 1.0, CFG)
	assert_true(bool(result.get("milestone", false)), "the third meal completed CFG's meals task")
	var milestones := _of_kind("bond_milestone")
	assert_eq(milestones.size(), 1, "one completion, one bond_milestone")
	var event: Dictionary = milestones[0]
	assert_eq(int(event.get("node", 0)), 1)
	assert_eq(int(event.get("total", 0)), 3)
	assert_eq(str(event.get("task", "")), "feeds_together")
	assert_true(str(event.get("benefit", "")).contains("attack and defence"),
		"the milestone says what it changed: '%s'" % str(event.get("benefit", "")))
	BOND.credit(c, "feeds_together", 1.0, CFG)
	assert_eq(_of_kind("bond_milestone").size(), 1, "overshooting a done task is not a second milestone")


# --- the party: nobody is dropped --------------------------------------------

func test_a_non_active_party_members_award_is_present_in_the_feed() -> void:
	var party := PARTY.new()
	var lead := _creature("Lead")
	var bench := _creature("Bench")
	party.add(lead)
	party.add(bench)
	party.set_active(0)
	lead.gain_xp(4, CFG)
	bench.gain_xp(2, CFG)
	var names: Array = []
	for event: Variant in _of_kind("xp_gained"):
		names.append(str((event as Dictionary).get("name", "")))
	assert_true(names.has("Bench"),
		"the bench member's award must be in the feed -- it is what the party strip renders")
	assert_true(names.has("Lead"))


# --- the log itself ---------------------------------------------------------------

func test_draining_empties_the_feed_and_bumps_the_revision() -> void:
	var c := _creature()
	c.gain_xp(3, CFG)
	var before := FEED.revision()
	var drained := FEED.drain()
	assert_eq(drained.size(), 1)
	assert_eq(FEED.events().size(), 0, "drained")
	assert_true(FEED.revision() > before, "a drain is a change a poller must see")


func test_peek_since_returns_only_newer_events_and_leaves_them_in_place() -> void:
	var c := _creature()
	c.gain_xp(1, CFG)
	var cursor := FEED.latest_seq()
	c.gain_xp(1, CFG)
	c.gain_xp(1, CFG)
	var newer := FEED.peek_since(cursor)
	assert_eq(newer.size(), 2)
	assert_eq(FEED.events().size(), 3, "peeking does not consume")
	assert_true(int((newer[0] as Dictionary).get("seq", 0)) > cursor)


func test_the_log_is_bounded() -> void:
	var c := _creature()
	var cap := int(FEED.config().get("max_events", 64))
	for i in cap + 10:
		c.gain_xp(1, CFG)
	assert_true(FEED.events().size() <= cap, "the log must never grow past max_events")


func test_clear_resets_sequence_and_revision() -> void:
	var c := _creature()
	c.gain_xp(1, CFG)
	FEED.clear()
	assert_eq(FEED.latest_seq(), 0)
	assert_eq(FEED.revision(), 0)
	assert_eq(FEED.events().size(), 0)


# --- derived readouts ------------------------------------------------------------

func test_xp_near_is_within_one_level_matched_fight() -> void:
	var c := _creature()
	c.set_level(5, CFG)
	# xp_to_next(5) = 50; one level-matched win pays 30 + 16*5 = 110 -> always near.
	assert_true(FEED.xp_near(c, CFG))
	var big := CFG.duplicate(true)
	big["level"]["xp_to_next_base"] = 1000.0  # level 5 now needs 5000
	assert_false(FEED.xp_near(c, big), "5000 xp short is not one fight away")
	c.xp = 4950
	assert_true(FEED.xp_near(c, big), "50 short IS within one fight")
	c.set_level(50, big)
	assert_false(FEED.xp_near(c, big), "at the cap there is no next level to be near")


func test_tick_and_moment_text_name_the_creature_and_the_change() -> void:
	var c := _creature("Tup")
	c.gain_xp(60, CFG)
	var tick := FEED.tick_label(_of_kind("xp_gained")[0])
	assert_eq(tick, "+60 XP")
	var moment := FEED.moment_text(_of_kind("level_up")[0])
	assert_true(str(moment.get("title", "")).begins_with("Tup reached Lv 4"), str(moment.get("title", "")))
	assert_true(str(moment.get("detail", "")).contains("HP"), "the detail line carries the stat change")
	BOND.credit_feed(c)
	assert_eq(FEED.tick_label(_of_kind("bond_credit")[0]), "+bond · fed")
