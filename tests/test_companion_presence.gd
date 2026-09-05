extends "res://tests/test_case.gd"
## W12-COMPANION-0904: `scripts/creatures/companion_presence.gd`, the deployed
## creature's contextual-reaction layer, driven through a REAL follower body.
##
## Real fixture, not a mock of the layer: `scenes/creatures/creature.tscn` with
## `follower_creature.gd` on it and the real terrapup GLB, AnimationPlayer and
## skeleton built under its pivot; a Node3D leader three metres away; and the
## layer's own `tick(delta)` called with fixed deltas -- the same call the
## follower makes every physics frame. The guard's witnesses (combat manager,
## interaction arbiter, an input-owning panel) are tiny stub nodes handed in
## through `set_context()` / `input_owner.gd`'s real group, so what is
## exercised is the layer's real guard reading them, exactly as it reads the
## game's.
##
## Detached, because `tests/run_tests.gd` has no live SceneTree for its whole
## life (see `tests/test_party_seam.gd`): the fixture is one `Node3D` world
## whose children's local positions are their world positions, the body's
## `@onready` fields are pointed at its scene children by hand and `_ready()`
## is called directly -- the same code path the tree would run, minus the
## tree. The in-tree half (the `call_group` hooks, physics, the head modifier
## actually bending the bone) is covered by the smokes and
## `tools/_capture_companion_moments.gd`.
##
## Every test here was seen red first by breaking the behaviour it pins
## (ralph/reports/W12-COMPANION-0904/REPORT.md records which line and what
## went red).

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PRESENCE := preload("res://scripts/creatures/companion_presence.gd")
const CAMPFIRE_GLOW := preload("res://scripts/world/campfire_glow.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

const TICK := 0.1

var _root: Node3D = null
var _body: Node3D = null
var _leader: Node3D = null
var _presence: Node = null
var _creature: RefCounted = null
var _combat: Node = null
var _arbiter: Node = null
var _extras: Array[Node] = []


func before_each() -> void:
	_root = Node3D.new()
	_root.name = "World"
	_leader = Node3D.new()
	_leader.name = "Leader"
	_root.add_child(_leader)
	_leader.position = Vector3(0.0, 0.0, 0.0)

	_body = CREATURE_SCENE.instantiate()
	_body.set_script(FOLLOWER)
	_body.name = "TestFollower"
	_root.add_child(_body)
	for field: String in ["_collision:Collision", "_model:Model", "_body:Body", "_head:Head"]:
		var pair: PackedStringArray = field.split(":")
		_body.set(pair[0], _body.get_node(NodePath(pair[1])))
	_body.set("species_id", "terrapup")
	_body.call("_ready")
	_body.position = Vector3(0.0, 0.0, 3.0)
	_body.set("leader", _leader)
	_body.call("set_following", true)
	_body.visible = true

	_creature = SPECIES.spawn("terrapup")
	_presence = _body.call("presence")
	_presence.set("creature_override", _creature)

	_combat = _stub("extends Node\nvar state := 0\nvar fighting := false\nvar aiming := false\nvar result := \"\"\nfunc is_fighting() -> bool: return fighting\nfunc is_aiming() -> bool: return aiming\nfunc outcome() -> String: return result\n")
	_arbiter = _stub("extends Node\nvar on := true\nvar offer := {}\nfunc enabled() -> bool: return on\nfunc winner() -> Dictionary: return offer\n")
	_presence.call("set_context", _combat, null, _arbiter, null)
	# The follower queued a `deploy` acknowledgment on set_following(true);
	# most tests want a quiet creature first, so let that one play out.
	_tick_seconds(6.0)
	assert_eq(_presence.call("state"), "", "the deploy nod has finished before the test body starts")


func after_each() -> void:
	_extras.clear()
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null
	_body = null
	_leader = null
	_presence = null


func _stub(source: String) -> Node:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	var node: Node = script.new()
	_root.add_child(node)
	_extras.append(node)
	return node


func _tick_seconds(seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		_presence.call("tick", TICK)
		t += TICK


## Ticks until `state()` reports `name` or `limit` seconds pass. Returns the
## seconds it took, or -1.
func _tick_until_state(name: String, limit: float) -> float:
	var t := 0.0
	while t < limit:
		_presence.call("tick", TICK)
		t += TICK
		if str(_presence.call("state")) == name:
			return t
	return -1.0


func _cfg() -> Dictionary:
	return PRESENCE.config()


## Ticks `seconds` with the trainer pacing (a half-metre step every tick, so
## the still clock never accumulates), then leaves them standing. Used to let
## the deploy cooldown from `before_each` lapse before a test measures the
## acknowledgment DELAY rather than the cooldown.
func _pace_then_stand(seconds: float) -> void:
	var t := 0.0
	var side := 1.0
	while t < seconds - 0.0001:
		_leader.position.x += 0.5 * side
		side = -side
		_presence.call("tick", TICK)
		t += TICK
	_leader.position.x = 0.0


func _pivot() -> Node3D:
	return _body.call("model_pivot") as Node3D


func _anim() -> AnimationPlayer:
	var players: Array[Node] = _pivot().find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null


func _cross_first_bond_milestone() -> void:
	# bond_milestones.json's first task is `battles_fought`; crediting well past
	# any plausible target completes node 1 whatever the tuned number is.
	_creature.set("battles_fought", 100000)


## A creature that arrives ALREADY deep in the bond ladder -- a loaded save,
## or a party cycle onto a long-held member -- swapped in as the deployed one.
func _swap_in_a_bonded_creature() -> RefCounted:
	var bonded: RefCounted = SPECIES.spawn("terrapup")
	for field: String in ["battles_fought", "landmarks_visited_together", "rest_nights_together", "feeds_together"]:
		bonded.set(field, 100000)
	bonded.set("distance_m_together", 1.0e9)
	_creature = bonded
	_presence.set("creature_override", bonded)
	return bonded


# --- the fixture is real ------------------------------------------------------

func test_the_fixture_is_a_real_rigged_follower() -> void:
	assert_true(bool(_body.call("has_model")), "terrapup's GLB loaded under the pivot")
	assert_true(_anim() != null, "the rig has an AnimationPlayer")
	assert_true(_anim().has_animation("hit") and _anim().has_animation("attack"),
		"the rig carries the two clips the layer reuses (hit as flinch, attack as roar)")
	assert_eq(_presence.get_parent(), _body, "the follower built its Presence child")
	assert_true(_presence.is_in_group(PRESENCE.GROUP), "the layer joined the hook group")
	assert_eq(str(_presence.call("blocked_reason")), "", "a quiet world is a clear context")


# --- acknowledgment -----------------------------------------------------------

func test_acknowledges_a_trainer_who_stands_still_for_the_configured_delay() -> void:
	_pace_then_stand(10.0)
	assert_eq(_presence.call("fired_count", "acknowledge"), 0, "pacing earns no acknowledgment")
	var delay := float(_cfg()["acknowledge"]["still_seconds"])
	_tick_seconds(delay * 0.5)
	assert_eq(_presence.call("state"), "", "half the delay is not yet an acknowledgment")
	var took := _tick_until_state("acknowledge", delay)
	assert_true(took >= 0.0, "standing still for the delay makes the creature acknowledge the trainer")
	assert_almost_eq(took + delay * 0.5, delay, 0.25, "and it is the configured delay that decides when")
	assert_eq(_presence.call("fired_count", "acknowledge"), 1)


func test_a_moving_trainer_resets_the_stillness_clock() -> void:
	var delay := float(_cfg()["acknowledge"]["still_seconds"])
	_tick_seconds(delay * 0.8)
	_leader.position += Vector3(2.0, 0.0, 0.0)
	_presence.call("tick", TICK)
	assert_almost_eq(float(_presence.call("still_seconds")), 0.0, 0.0001,
		"a step resets the still clock")
	_tick_seconds(delay * 0.8)
	assert_eq(_presence.call("state"), "", "no acknowledgment while the trainer keeps moving")


func test_acknowledgment_walks_up_then_holds_the_pivot_and_restores_it() -> void:
	var rest := _pivot().transform
	_tick_until_state("acknowledge", 10.0)
	# Approach phase: the body asked to move toward the leader this frame.
	var requested: Vector3 = _body.get("_requested")
	assert_true(requested.length() > 0.5, "the acknowledgment starts by walking toward the trainer")
	# Skip the walk (the body cannot integrate without physics) and perform.
	_body.position = Vector3(0.0, 0.0, 1.5)
	_tick_seconds(0.9)
	assert_eq(_presence.call("state"), "acknowledge")
	assert_false(_pivot().transform.is_equal_approx(rest), "mid-nod the pivot has left its rest pose")
	_tick_seconds(2.0)
	assert_eq(_presence.call("state"), "", "the acknowledgment ends after its duration")
	assert_true(_pivot().transform.is_equal_approx(rest), "the pivot is back exactly where it rested")
	assert_true(bool(_presence.call("pivot_is_at_rest")))


func test_acknowledgment_respects_its_cooldown() -> void:
	_tick_until_state("acknowledge", 10.0)
	_body.position = Vector3(0.0, 0.0, 1.5)
	_tick_seconds(3.0)
	assert_eq(_presence.call("fired_count", "acknowledge"), 1)
	var cooldown := float(_presence.call("cooldown_left", "acknowledge"))
	assert_true(cooldown > 5.0, "a real cooldown is armed (%.1fs)" % cooldown)
	_tick_seconds(cooldown * 0.5)
	assert_eq(_presence.call("fired_count", "acknowledge"), 1,
		"standing still inside the cooldown does not re-fire")
	_tick_until_state("acknowledge", cooldown + 10.0)
	assert_eq(_presence.call("fired_count", "acknowledge"), 2, "once the cooldown lapses it fires again")


func test_higher_bond_acknowledges_sooner() -> void:
	_pace_then_stand(10.0)
	var low := _tick_until_state("acknowledge", 20.0)
	assert_true(low > 0.0)
	after_each()
	before_each()
	_swap_in_a_bonded_creature()
	_pace_then_stand(10.0)
	assert_true(int(_creature.call("bond_nodes")) >= 4, "the swapped-in creature is deep in the ladder")
	var high := _tick_until_state("acknowledge", 20.0)
	assert_true(high > 0.0)
	assert_true(high < low - 1.0, "bond %d acknowledged in %.1fs, bond 0 in %.1fs" % [
		int(_creature.call("bond_nodes")), high, low])
	assert_true(high >= float(_cfg()["acknowledge"]["still_seconds_min"]) - 0.25,
		"but never under the floor (%.1fs)" % high)


# --- victory ------------------------------------------------------------------

func test_victory_fires_on_the_result_beat_and_hops() -> void:
	# The result beat: combat_manager is RESOLVING (state 2) with outcome won.
	_combat.set("fighting", true)
	_combat.set("state", 2)
	_combat.set("result", "won")
	assert_eq(str(_presence.call("blocked_reason")), "resolving_won")
	_presence.call("on_event", "victory")
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "victory", "the victory reaction plays in the result pause")
	assert_eq(int(_presence.get("last_hops")), int(_cfg()["victory"]["hops"]), "bond 0: the base hop count")
	var rest_y := 0.0
	var peak := 0.0
	for i in 20:
		_presence.call("tick", TICK)
		peak = maxf(peak, _pivot().position.y - rest_y)
	assert_true(peak > 0.05, "the pivot actually rose during the hop (%.3fm)" % peak)


func test_victory_waits_out_a_fight_that_is_still_running() -> void:
	_combat.set("fighting", true)
	_combat.set("state", 1)
	_presence.call("on_event", "victory")
	_tick_seconds(2.0)
	assert_eq(_presence.call("state"), "", "nothing plays while the fight is ACTIVE")
	assert_true((_presence.call("pending") as Array).has("victory"), "the win is remembered")
	_combat.set("fighting", false)
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "victory", "it plays the moment the fight is over")


func test_higher_bond_makes_the_victory_warmer() -> void:
	_swap_in_a_bonded_creature()
	_presence.call("tick", TICK)
	var nodes := int(_creature.call("bond_nodes"))
	assert_true(nodes >= 4, "the fixture creature is deep into the bond ladder (%d nodes)" % nodes)
	_presence.call("on_event", "victory")
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "victory")
	assert_true(int(_presence.get("last_hops")) > int(_cfg()["victory"]["hops"]),
		"more hops at high bond (%d)" % int(_presence.get("last_hops")))
	var base_height := float(_cfg()["victory"]["hop_height_fraction"]) * float(_body.call("body_height"))
	assert_true(float(_presence.get("last_hop_height")) > base_height * 1.3, "and higher hops")


func test_a_victory_cut_by_the_teardown_turns_into_a_greeting_on_redeploy() -> void:
	_combat.set("fighting", true)
	_combat.set("state", 2)
	_combat.set("result", "won")
	_presence.call("on_event", "victory")
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "victory")
	var rest := _pivot().transform
	_presence.call("tick", TICK)
	# combat_manager._finish(): the body is hidden mid-hop.
	_body.visible = false
	_combat.set("fighting", false)
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "", "the hidden body carries no reaction")
	assert_true(_pivot().transform.is_equal_approx(rest) or bool(_presence.call("pivot_is_at_rest")),
		"the pivot was restored when the reaction was cut")
	assert_true((_presence.call("pending") as Array).has("deploy"), "a greeting is queued for the redeploy")
	_body.visible = true
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "acknowledge", "the creature turns to the trainer when it reappears")


# --- hurt / tired ----------------------------------------------------------------

func test_low_hp_slows_the_gait_lowers_the_head_and_flinches() -> void:
	assert_almost_eq(float(_presence.call("gait_scale")), 1.0, 0.0001, "healthy: full gait")
	var rest := _pivot().transform
	_creature.set("hp", float(_creature.get("max_hp")) * 0.2)
	_presence.call("tick", TICK)
	assert_true(bool(_presence.call("is_hurt")), "under 30% HP reads as hurt")
	assert_true(float(_presence.call("gait_scale")) < 0.9, "the hurt gait is slower")
	assert_false(_pivot().transform.is_equal_approx(rest), "the head-low pose moved the pivot")
	assert_true(float(_presence.call("anim_speed_scale")) < 1.0, "the idle plays slower")
	# A flinch arrives inside the configured window: the rig's own `hit` clip.
	# The trainer paces meanwhile so no acknowledgment can start and hide the
	# hurt idle behind a reaction (a reaction is what a flinch yields to).
	var window := float(_cfg()["hurt"]["flinch_every_s"]) + float(_cfg()["hurt"]["flinch_jitter_s"]) + 1.0
	var flinched := false
	var t := 0.0
	var side := 1.0
	while t < window and not flinched:
		_leader.position.x += 0.5 * side
		side = -side
		_presence.call("tick", TICK)
		t += TICK
		flinched = _anim().current_animation == "hit"
	assert_true(flinched, "a flinch (the hit clip) played within %.0fs" % window)
	# Healed: everything is handed back.
	_creature.set("hp", float(_creature.get("max_hp")))
	_presence.call("tick", TICK)
	assert_false(bool(_presence.call("is_hurt")))
	assert_almost_eq(float(_presence.call("gait_scale")), 1.0, 0.0001)
	assert_true(_pivot().transform.is_equal_approx(rest), "the pivot is back at rest once healed")
	assert_almost_eq(float(_presence.call("anim_speed_scale")), 1.0, 0.0001)


func test_hunger_reads_as_tired_too() -> void:
	_creature.set("nourishment", 0.0)
	_presence.call("tick", TICK)
	assert_true(bool(_presence.call("is_hurt")), "an empty nourishment meter is the tired state")
	assert_true(float(_presence.call("gait_scale")) < 1.0)


# --- camp / rest ------------------------------------------------------------------

func test_settles_beside_a_lit_campfire_and_stands_up_to_move() -> void:
	var fire: Node3D = CAMPFIRE_GLOW.new(true)
	_root.add_child(fire)
	_extras.append(fire)
	fire.position = _body.position + Vector3(2.5, 0.0, 0.0)
	var rest := _pivot().transform
	_presence.call("tick", TICK)
	assert_true(bool(_presence.call("is_camp_near")), "the campfire_glow overlay is found by the scan")
	assert_false(bool(_presence.call("is_camped")), "it does not drop the instant it arrives")
	_tick_seconds(float(_cfg()["camp"]["settle_seconds"]) + 0.5)
	assert_true(bool(_presence.call("is_camped")), "after standing a moment it settles")
	assert_false(_pivot().transform.is_equal_approx(rest), "the rest pose rolled/sank the pivot")
	assert_true(_pivot().rotation.z != 0.0 or _pivot().position.y < 0.0, "rolled toward its species rest pose")
	assert_true(float(_presence.call("anim_speed_scale")) < 1.0, "the idle slows to a resting pace")
	# The trainer walks off: the follower must be able to stand and go.
	_leader.position += Vector3(30.0, 0.0, 0.0)
	_presence.call("tick", TICK)
	assert_false(bool(_presence.call("is_camped")), "the trainer leaving ends the rest")
	assert_true(_pivot().transform.is_equal_approx(rest), "and the pivot stands back up")
	assert_almost_eq(float(_presence.call("anim_speed_scale")), 1.0, 0.0001)


func test_the_camp_group_is_an_opt_in_camp_source() -> void:
	var bed := Node3D.new()
	bed.add_to_group(PRESENCE.CAMP_GROUP)
	_root.add_child(bed)
	_extras.append(bed)
	bed.position = _body.position + Vector3(0.0, 0.0, 2.0)
	_presence.call("tick", TICK)
	assert_true(bool(_presence.call("is_camp_near")))


func test_the_camp_scan_costs_nothing_while_the_creature_is_moving() -> void:
	var bed := Node3D.new()
	bed.add_to_group(PRESENCE.CAMP_GROUP)
	_root.add_child(bed)
	_extras.append(bed)
	bed.position = _body.position + Vector3(0.0, 0.0, 2.0)
	# Walking: the follower is closing the gap to a trainer who moved off.
	_leader.position = Vector3(0.0, 0.0, -40.0)
	_body.set("_closing", true)
	_presence.set("last_camp_scan_nodes", 0)
	_tick_seconds(float(_cfg()["camp"]["scan_every_s"]) * 3.0)
	assert_false(bool(_presence.call("is_camp_near")),
		"a creature under way does not settle, so the world tree is not walked")
	assert_eq(int(_presence.get("last_camp_scan_nodes")), 0,
		"three scan intervals of travel and not one scan happened")
	# Standing again: the scan runs on the next tick and finds the same bed.
	_body.set("_closing", false)
	_leader.position = _body.position + Vector3(0.0, 0.0, 2.0)
	_presence.call("tick", TICK)
	assert_true(bool(_presence.call("is_camp_near")))
	assert_true(int(_presence.get("last_camp_scan_nodes")) > 0, "and it walked a bounded tree")


func test_far_from_any_camp_nothing_settles() -> void:
	_tick_seconds(float(_cfg()["camp"]["settle_seconds"]) + 1.0)
	assert_false(bool(_presence.call("is_camp_near")))
	assert_false(bool(_presence.call("is_camped")))


# --- care -----------------------------------------------------------------------

func test_care_from_the_satchel_waits_for_the_menu_to_close() -> void:
	var panel := _stub("extends Node\nvar open := true\nfunc is_open() -> bool: return open\n")
	panel.add_to_group(INPUT_OWNER.GROUP)
	assert_eq(str(_presence.call("blocked_reason")), "menu", "an open panel owns input")
	_presence.call("on_care", _creature, "feed")
	_tick_seconds(1.0)
	assert_eq(_presence.call("state"), "", "nothing plays over the open satchel")
	panel.set("open", false)
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "care", "the thank-you plays the moment the satchel closes")
	assert_eq(_presence.call("fired_count", "care"), 1)


func test_care_for_a_different_creature_is_not_this_creatures_moment() -> void:
	var other: RefCounted = SPECIES.spawn("ripplet")
	_presence.call("on_care", other, "heal")
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "")
	assert_false((_presence.call("pending") as Array).has("care"))


func test_each_care_kind_has_its_own_motion() -> void:
	_presence.call("on_care", _creature, "revive")
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "care")
	_body.position = Vector3(0.0, 0.0, 1.5)  # skip the walk-up
	var yawed := false
	for i in 12:
		_presence.call("tick", TICK)
		if absf(_pivot().rotation.y) > 0.01:
			yawed = true
	assert_true(yawed, "a revive is a head shake (yaw on the pivot)")


func test_care_respects_its_cooldown() -> void:
	_presence.call("on_care", _creature, "feed")
	_presence.call("tick", TICK)
	_body.position = Vector3(0.0, 0.0, 1.5)
	_tick_seconds(3.0)
	assert_eq(_presence.call("state"), "")
	_presence.call("on_care", _creature, "feed")
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "", "a second feed inside the cooldown waits")
	assert_true((_presence.call("pending") as Array).has("care"), "but is not forgotten")


# --- bond milestone ------------------------------------------------------------------

func test_a_bond_node_completing_is_the_strongest_moment() -> void:
	_presence.call("tick", TICK)  # prime the poll at 0 nodes
	_cross_first_bond_milestone()
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "bond_milestone", "polling bond_nodes() catches the completion")
	assert_true(int(_presence.get("last_hops")) >= int(_cfg()["victory"]["hops"]) + 1,
		"more hops than an ordinary victory")


func test_the_bond_milestone_hook_is_the_same_entry() -> void:
	_presence.call("on_event", "bond_milestone")
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "bond_milestone")


func test_a_loaded_save_or_party_swap_does_not_celebrate_old_bond() -> void:
	_presence.call("tick", TICK)  # bond 0 is what the layer has seen so far
	_swap_in_a_bonded_creature()
	_tick_seconds(1.0)
	assert_ne(_presence.call("state"), "bond_milestone",
		"a creature that arrives already bonded is old news, not a milestone")
	assert_false((_presence.call("pending") as Array).has("bond_milestone"))
	# And from here, a genuinely NEW node on that creature would still count:
	# the poll is now keyed to it.
	assert_true(int(_creature.call("bond_nodes")) >= 4)


# --- the guard ----------------------------------------------------------------------

func test_nothing_starts_in_combat_and_a_running_reaction_is_cut() -> void:
	var rest := _pivot().transform
	_tick_until_state("acknowledge", 10.0)
	_body.position = Vector3(0.0, 0.0, 1.5)
	_tick_seconds(0.8)
	assert_eq(_presence.call("state"), "acknowledge")
	_combat.set("fighting", true)
	_combat.set("state", 1)
	_presence.call("tick", TICK)
	assert_eq(_presence.call("state"), "", "the fight cut the reaction")
	assert_true(_pivot().transform.is_equal_approx(rest), "and restored the pivot the same frame")
	_tick_seconds(30.0)
	assert_eq(_presence.call("state"), "", "nothing starts however long the trainer stands in a fight")


func test_aiming_riding_prompts_lockout_and_build_ghosts_all_block() -> void:
	_combat.set("aiming", true)
	assert_eq(str(_presence.call("blocked_reason")), "aiming")
	_combat.set("aiming", false)

	var riding := _stub("extends Node\nvar mounted := true\nfunc is_mounted() -> bool: return mounted\n")
	var game := _stub("extends Node\nvar pending_build := \"\"\nvar party = null\n")
	_presence.call("set_context", _combat, riding, _arbiter, game)
	assert_eq(str(_presence.call("blocked_reason")), "riding")
	riding.set("mounted", false)

	_arbiter.set("offer", {"label": "Talk", "actionable": true})
	assert_eq(str(_presence.call("blocked_reason")), "prompt", "a live interact prompt blocks")
	_arbiter.set("offer", {"label": "Put Bud away", "actionable": false})
	assert_eq(str(_presence.call("blocked_reason")), "", "the recall legend is not a prompt")
	_arbiter.set("offer", {})

	_arbiter.set("on", false)
	assert_eq(str(_presence.call("blocked_reason")), "locked", "the sequence director's lockout blocks")
	_arbiter.set("on", true)

	game.set("pending_build", "campfire")
	assert_eq(str(_presence.call("blocked_reason")), "build", "an armed build ghost blocks")
	game.set("pending_build", "")
	assert_eq(str(_presence.call("blocked_reason")), "")


func test_a_dialogue_panel_blocks_and_hurt_pose_lets_go_under_it() -> void:
	_creature.set("hp", 1.0)
	_presence.call("tick", TICK)
	assert_true(bool(_presence.call("is_hurt")))
	var rest_held := not bool(_presence.call("pivot_is_at_rest"))
	assert_true(rest_held, "the hurt pose holds the pivot")
	var dialogue := _stub("extends Node\nfunc is_open() -> bool: return true\n")
	dialogue.add_to_group(INPUT_OWNER.GROUP)
	_presence.call("tick", TICK)
	assert_eq(str(_presence.call("blocked_reason")), "menu")
	assert_true(bool(_presence.call("pivot_is_at_rest")), "a dialogue releases every pose")
	assert_false(bool(_presence.call("is_looking")))


func test_the_head_turns_toward_a_near_trainer_and_not_a_far_one() -> void:
	_presence.call("tick", TICK)
	assert_true(bool(_presence.call("is_looking")), "standing 3m from the trainer, the head bone tracks them")
	var look := _pivot().find_children("CompanionLook", "LookAtModifier3D", true, false)
	assert_eq(look.size(), 1, "one LookAtModifier3D under the skeleton")
	assert_true((look[0] as LookAtModifier3D).get_parent() is Skeleton3D)
	_leader.position += Vector3(0.0, 0.0, -20.0)
	_presence.call("tick", TICK)
	assert_false(bool(_presence.call("is_looking")), "out of range, the head is the idle's own again")
