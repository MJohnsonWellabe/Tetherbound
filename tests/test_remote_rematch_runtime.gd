extends "res://tests/test_case.gd"

## Focused authority/round/event contracts using the real AcceptedActionHost.
## These fixtures do not claim network presentation, an earned fight or saves.
const RUNTIME := preload("res://scripts/combat/remote_rematch_runtime.gd")
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")
const BOSSES := preload("res://scripts/net/foundation_rematches.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const WORLD := preload("res://autoload/world_state.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")

func test_guest_start_accepts_only_intent_identity_and_registered_profile_tag() -> void:
	var uid: String = preload("res://scripts/creatures/creature_instance.gd").mint_uid()
	var intent := {"trainer_id": "relay_captain", "tier": "r1", "creature_uid": uid, "action_id": "0123456789abcdef0123456789abcdef"}
	assert_true(BOSSES.valid_start_intent(intent))
	for field: String in ["position", "team", "flags", "character_id", "damage"]:
		var forged := intent.duplicate(true)
		forged[field] = "packet-claim"
		assert_false(BOSSES.valid_start_intent(forged), field)
	for field: String in ["trainer_id", "tier", "creature_uid", "action_id"]:
		var malformed := intent.duplicate(true)
		malformed[field] = ""
		assert_false(BOSSES.valid_start_intent(malformed), field)
	var record := {"kind": "trainer", "opponent": {"owner_npc": "relay_captain", "rematch": {"trainer_id": "relay_captain", "tier": "r1"}}}
	assert_true(DIRECTOR._record_is_remote_rematch(record))
	record.opponent.rematch.trainer_id = "master_t4"
	assert_false(DIRECTOR._record_is_remote_rematch(record))

class TrackedHost extends "res://scripts/combat/accepted_action_host.gd":
	func _tracking_enabled() -> bool:
		return true

func _action_fixture(second_participant: bool = false) -> Dictionary:
	var host := TrackedHost.new(1)
	var rec: Dictionary = host.open(2, "meadows", "trainer", {
		"species_id": "bramblebun", "owner_npc": "relay_captain", "hp": 30.0, "hp_max": 30.0,
		"position": Vector3(2, 0, 0), "body_generation": 1, "round": 1, "round_continues": true,
		"card": {"uid": "opponent-a"}}, "owned-a", "guest-a")
	var id: String = str(rec.encounter_id)
	if second_participant: assert_true(host.join(id, 3, "owned-b", "guest-b").get("ok") == true)
	var owned := {"uid": "owned-a", "hp": 100.0, "max_hp": 100.0, "fainted": false}
	var bound: Dictionary = host.bind_actor_body(id, 2, "guest-a", owned, 202)
	var generation: int = int(bound.vitals.body_generation)
	var binding := {"character_id": "guest-a", "creature_uid": "owned-a", "actor_generation": generation,
		"deployment_generation": generation, "body_instance_id": 202}
	var intent := {"encounter_id": id, "action": 1, "move_id": "tackle", "slot": "quick", "facing": Vector3.RIGHT,
		"move": {"range": 2.6, "cone_degrees": 90.0, "power": 9.0, "is_quick": true}}
	var verdict: Dictionary = host.validate_strike(intent, 2,
		{"now_ms": 10000, "origin": Vector3.ZERO, "bodies": [], "f22_actor_binding": binding})
	var begun: Dictionary = host.begin_move_action_resolution(id, 2, 1, binding, "opponent-a", 1)
	return {"host": host, "id": id, "binding": binding, "verdict": verdict, "begun": begun, "owned": owned}

func _record_kill(fixture: Dictionary) -> void:
	var rolled := {"hp": 0.0, "hp_max": 30.0, "damage": 80.0, "killed": true}
	fixture.verdict.delta.merge(rolled, true)
	fixture.host.set_opponent_hp(fixture.id, 0.0, 30.0, rolled)
	assert_true(fixture.host.record_move_action_outcome(fixture.id, 2, fixture.begun.action_id, rolled, fixture.verdict))

func test_terminal_requires_exact_committed_action_actor_and_roster_generation() -> void:
	var fixture := _action_fixture()
	assert_true(fixture.verdict.get("ok") == true and fixture.begun.get("ok") == true)
	var original: Dictionary = fixture.host.move_action_original(fixture.id, 2, fixture.begun.action_id)
	assert_false(RUNTIME.accepted_terminal_matches(original, fixture.id, 2, fixture.begun.action_id, "opponent-a", 1, fixture.binding, fixture.verdict))
	_record_kill(fixture)
	original = fixture.host.move_action_original(fixture.id, 2, fixture.begun.action_id)
	assert_true(RUNTIME.accepted_terminal_matches(original, fixture.id, 2, fixture.begun.action_id, "opponent-a", 1, fixture.binding, fixture.verdict))
	assert_false(RUNTIME.accepted_terminal_matches(original, fixture.id, 1, fixture.begun.action_id, "opponent-a", 1, fixture.binding, fixture.verdict), "host actor cannot replace guest")
	assert_false(RUNTIME.accepted_terminal_matches(original, fixture.id, 2, fixture.begun.action_id, "opponent-b", 1, fixture.binding, fixture.verdict), "old projectile cannot defeat a replacement")
	assert_false(RUNTIME.accepted_terminal_matches(original, fixture.id, 2, fixture.begun.action_id, "opponent-a", 2, fixture.binding, fixture.verdict))
	var changed: Dictionary = fixture.binding.duplicate(true)
	changed.character_id = "other-character"
	assert_false(RUNTIME.accepted_terminal_matches(original, fixture.id, 2, fixture.begun.action_id, "opponent-a", 1, changed, fixture.verdict))
	var forged: Dictionary = fixture.verdict.duplicate(true)
	forged.delta.hp = 1.0
	assert_false(RUNTIME.accepted_terminal_matches(original, fixture.id, 2, fixture.begun.action_id, "opponent-a", 1, fixture.binding, forged))
	assert_false(RUNTIME.accepted_terminal_matches({}, fixture.id, 2, fixture.begun.action_id, "opponent-a", 1, fixture.binding, fixture.verdict), "HP alone is no accepted original")

func test_round_advance_preserves_real_record_participants_and_refuses_replay() -> void:
	var fixture := _action_fixture(true)
	_record_kill(fixture)
	var next := {"species_id": "burrowback", "owner_npc": "relay_captain", "hp": 45.0, "hp_max": 45.0,
		"position": Vector3(2, 0, 0), "body_generation": 2, "round": 2, "round_continues": false, "card": {"uid": "opponent-b"}}
	assert_false(RUNTIME.advance_record(fixture.host, fixture.id, "opponent-a", 1, next), "pending body publication fences roster replacement")
	assert_true(fixture.host.publish_move_action_terminal(fixture.id, 2, fixture.begun.action_id, "done"))
	assert_false(RUNTIME.advance_record(fixture.host, fixture.id, "opponent-a", 1, next))
	assert_true(fixture.host.acknowledge_move_action_publication(fixture.id, 2, fixture.begun.action_id, fixture.verdict))
	var participants: Dictionary = fixture.host.record(fixture.id).participants.duplicate(true)
	var skipped := next.duplicate(true)
	skipped.round = 3
	assert_false(RUNTIME.advance_record(fixture.host, fixture.id, "opponent-a", 1, skipped))
	assert_true(RUNTIME.advance_record(fixture.host, fixture.id, "opponent-a", 1, next))
	assert_eq(fixture.host.record(fixture.id).encounter_id, fixture.id)
	assert_eq(fixture.host.record(fixture.id).participants, participants, "round two keeps both owners and original actor vitals")
	assert_eq(fixture.host.record(fixture.id).opponent.card.uid, "opponent-b")
	assert_false(RUNTIME.advance_record(fixture.host, fixture.id, "opponent-a", 1, next), "replay cannot reset the new opponent")
	assert_false(fixture.host.begin_move_action_resolution(fixture.id, 2, 1, fixture.binding, "opponent-a", 1).get("ok") == true)

func test_frozen_obligations_use_each_admitted_owner_and_existing_event_codec() -> void:
	var mount := BOSSES.new()
	var canonical: Dictionary = mount.call("_canonical_boss", "captain_veyra_storm_anchor")
	mount.free()
	var rematch := RULES.encounter_spec(canonical, "endgame")
	var admissions := {
		"guest-a": {"character_id": "guest-a", "world_flags": [], "personal_flags": ["regional_credits_seen"], "bounty_instances": ["a".sha256_text()]},
		"guest-b": {"character_id": "guest-b", "world_flags": [], "personal_flags": ["regional_credits_seen"], "bounty_instances": ["b".sha256_text()]}}
	var outcome := RUNTIME.outcome_obligations(rematch, "1:9", "world-a", "epoch-a", 1500, admissions)
	assert_eq(outcome.duties.size(), 4)
	assert_eq(outcome.duties[0].context.participants, ["guest-a", "guest-b"])
	assert_eq(outcome.duties[1].context.biome, "cloudreach", "visiting Halda does not change boss-region bounty identity")
	assert_eq(outcome.duties[1].context.issued_instances, ["a".sha256_text()])
	assert_eq(outcome.duties[3].context.issued_instances, ["b".sha256_text()])
	var world := WORLD.new()
	world.world_id = "save-a"
	world.reward_delivery_namespace = "world-a"
	var retained := EVENT.make(world, "epoch-a", outcome.source_id, outcome.duties)
	assert_false(retained.is_empty(), "the existing Foundation event codec admits the actual duty shape")
	admissions["guest-a"].bounty_instances.clear()
	assert_eq(outcome.duties[1].context.issued_instances, ["a".sha256_text()], "later rotation cannot rewrite this terminal")
	admissions["guest-b"].personal_flags.clear()
	assert_eq(RUNTIME.outcome_obligations(rematch, "1:9", "world-a", "epoch-a", 1500, admissions), {}, "host credits cannot qualify another character")
	var master := RULES.encounter_spec(RULES.master_spec("master_t1"), "endgame")
	assert_eq(RUNTIME.outcome_obligations(master, "1:10", "world-a", "epoch-a", 1500, admissions, "owned-a"), {}, "a Master never admits two owners")

func test_unbound_runtime_and_missing_grounded_arena_refuse() -> void:
	var runtime := RUNTIME.new()
	assert_false(runtime.start(2, null, "relay_captain", "r1").get("ok") == true)
	assert_false(runtime.bind_director(null, Callable()))
	assert_false(RUNTIME.arena_valid({}))
	assert_false(RUNTIME.arena_valid({"arena_centre": Vector3.ZERO, "opponent_spot": Vector3(12, 0, 0), "arena_radius_m": 10.0}))
	assert_false(RUNTIME.arena_valid({"arena_centre": Vector3.ZERO, "opponent_spot": Vector3.ZERO, "arena_radius_m": NAN}))
	assert_true(RUNTIME.arena_valid({"arena_centre": Vector3.ZERO, "opponent_spot": Vector3(2, 0, 0), "arena_radius_m": 10.0}))
	runtime.free()
