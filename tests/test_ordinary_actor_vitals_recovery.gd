extends "res://tests/test_case.gd"

const SESSION := preload("res://scripts/net/session.gd")
const HOST := preload("res://scripts/net/encounter_host.gd")
const ACTOR := preload("res://scripts/net/actor_vitals_delivery.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const ROUND := preload("res://scripts/net/combat_round_reward.gd")
const ACCEPTED := preload("res://scripts/combat/accepted_action_host.gd")
const AUTH := preload("res://scripts/net/character_authority.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ROUND_FIXTURE := preload("res://tests/test_combat_round_reward.gd")

class AckSession extends Node:
	var arbiter: RefCounted
	var fixture_character := "owner_a"
	var refuse_once := true
	var calls := 0
	func host_ack_creature_vitals(_peer: int, uid: String, _revision: int, receipt: Dictionary) -> bool:
		calls += 1
		if refuse_once:
			refuse_once = false
			return false
		return arbiter.call("acknowledge_actor_vitals", str(receipt.encounter_id), fixture_character,
			uid, int(receipt.vitals_revision), receipt) == true

class FixtureGame extends Node:
	var world: RefCounted
	var session: Node
	var save_system: RefCounted
	func is_host() -> bool: return true

class Transport extends "res://scripts/net/ledger_rpc.gd":
	var fixture_game: Node
	var admitted_peer := 2
	var admitted_character := "owner_a"
	func _game() -> Node: return fixture_game
	func _registered_character(peer: int) -> String:
		return admitted_character if peer == admitted_peer else ""

func _fixture() -> Dictionary:
	var host: RefCounted = HOST.new()
	var body := Node.new()
	var owned: Dictionary = {"uid": "owned_a", "hp": 100.0, "max_hp": 100.0, "fainted": false}
	var record: Dictionary = host.call("open", 2, "meadows", "trainer",
		{"hp": 20.0, "owner_npc": "trainer_arden", "card": {"uid": "enemy_a"}, "round": 1}, owned.uid, "owner_a")
	var id: String = record.encounter_id
	assert_true(host.call("bind_actor_body", id, 2, "owner_a", owned, body.get_instance_id()).get("ok") == true)
	var scope: Dictionary = ROUND.scope("namespace_a", "epoch_a", "meadows", "trainer_arden", id)
	record.ordinary_combat_reward_owner = scope.duplicate(true)
	var source: Dictionary = record.duplicate(true)
	var proposal: Dictionary = host.call("stage_actor_vitals", id, 2, owned.uid, 1, 0, "actual_hit_a", "damage", 7.0, 16)
	assert_true(proposal.get("ok") == true)
	var row: Dictionary = ACTOR.next_record("world_a", "namespace_a", "epoch_a", "owner_a", owned.uid,
		100.0, 100.0, false, 93.0, false, 2, proposal.settlement_receipt, null)
	assert_true(ACTOR.valid(row, "owner_a", "namespace_a"))
	return {"host": host, "body": body, "id": id, "source": source, "proposal": proposal, "row": row, "scope": scope}

func _free_fixture(f: Dictionary) -> void:
	f.body.free()

func test_accepted_duplicate_repairs_lost_actual_arbiter_ack_without_world_write() -> void:
	var f: Dictionary = _fixture()
	assert_true(f.host.call("commit_actor_vitals", f.proposal).get("ok") == true)
	var game := FixtureGame.new()
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	var row: Dictionary = f.row.duplicate(true)
	row.status = "accepted" # Fixture begins at the original durable owner decision.
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	var ack := AckSession.new()
	ack.arbiter = f.host
	game.session = ack
	var transport := Transport.new()
	transport.fixture_game = game
	transport.ledger = LEDGER.new(game.world)
	var before: Dictionary = game.world.save_data()
	assert_false(transport._accept_actor_vitals(row.delivery_id, 1, row.receipt, 2))
	assert_eq(f.host.call("pending_actor_vitals", f.id).size(), 1)
	assert_true(transport._accept_actor_vitals(row.delivery_id, 1, row.receipt, 2))
	assert_true(f.host.call("pending_actor_vitals", f.id).is_empty())
	assert_true(transport._accept_actor_vitals(row.delivery_id, 1, row.receipt, 2))
	assert_eq(ack.calls, 3)
	assert_true(ACTOR.equivalent(game.world.save_data(), before), "accepted duplicate never rewrites original row or decision")
	transport.free()
	ack.free()
	game.free()
	_free_fixture(f)

func test_rejoined_stable_owner_repairs_original_ack_and_rejects_foreign_proofs() -> void:
	var f: Dictionary = _fixture()
	assert_true(f.host.call("commit_actor_vitals", f.proposal).get("ok") == true)
	f.host.call("leave", f.id, 2)
	var game := FixtureGame.new()
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	var row: Dictionary = f.row.duplicate(true)
	row.status = "accepted"
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	var ack := AckSession.new()
	ack.arbiter = f.host
	ack.refuse_once = false
	game.session = ack
	var transport := Transport.new()
	transport.fixture_game = game
	transport.ledger = LEDGER.new(game.world)
	transport.admitted_peer = 9
	assert_false(transport._accept_actor_vitals(row.delivery_id, 1, row.receipt, 2))
	assert_false(transport._accept_actor_vitals(row.delivery_id, 2, row.receipt, 9))
	var forged: Dictionary = row.receipt.duplicate(true)
	forged.body_generation = 2
	assert_false(transport._accept_actor_vitals(row.delivery_id, 1, forged, 9))
	transport.admitted_character = "foreign_owner"
	assert_false(transport._accept_actor_vitals(row.delivery_id, 1, row.receipt, 9))
	transport.admitted_character = "owner_a"
	game.world.world_id = "foreign_world"
	assert_false(transport._accept_actor_vitals(row.delivery_id, 1, row.receipt, 9))
	assert_eq(ack.calls, 0)
	game.world.world_id = "world_a"
	assert_true(transport._accept_actor_vitals(row.delivery_id, 1, row.receipt, 9))
	assert_true(f.host.call("pending_actor_vitals", f.id).is_empty())
	assert_true(ACTOR.equivalent(game.world.reward_deliveries[row.delivery_id], row))
	transport.free()
	ack.free()
	game.free()
	_free_fixture(f)

func _settled(f: Dictionary, terminal: Dictionary) -> Dictionary:
	var result: Dictionary = terminal.duplicate(true)
	var actor: Dictionary = result.participants[2].actor_vitals.owned_a
	actor.hp = f.proposal.hp_after
	actor.fainted = f.proposal.fainted
	actor.revision = f.proposal.revision
	actor.settled_revision = f.proposal.revision
	actor.settlement_receipt = f.proposal.settlement_receipt.duplicate(true)
	actor.receipts[f.proposal.action_id] = true
	result.seq = int(terminal.seq) + 1
	return result

func _committed_record(f: Dictionary, terminal: Dictionary) -> Dictionary:
	var next: Dictionary = _settled(f, terminal)
	next.participants[2].actor_vitals.owned_a.settled_revision = 0
	return next

func test_terminal_full_record_requires_exact_original_accepted_hp_transition() -> void:
	var f: Dictionary = _fixture()
	f.host.call("set_phase", f.id, "done")
	var terminal: Dictionary = f.host.call("record", f.id).duplicate(true)
	var settled: Dictionary = _settled(f, terminal)
	var accepted: Dictionary = f.row.duplicate(true)
	accepted.status = "accepted"
	var proof: Dictionary = {"accepted": true, "scope": f.scope, "world_id": "world_a", "character_id": "owner_a",
		"proposal": f.proposal, "source_record": f.source, "accepted_row": accepted,
		"record_before": terminal, "record_after": _committed_record(f, terminal)}
	var proofs: Dictionary = {f.proposal.settlement_receipt.receipt_id: proof}
	var original_before: Dictionary = terminal.duplicate(true)
	assert_true(SESSION._ordinary_combat_settled_record(terminal, settled, proofs))
	assert_true(SESSION._ordinary_combat_settled_record(terminal, settled, proofs), "duplicate original proof is idempotent")
	assert_true(ACTOR.equivalent(terminal, original_before), "original full kill record remains immutable")
	var forged: Dictionary = settled.duplicate(true)
	forged.participants[2].actor_vitals.owned_a.hp -= 1.0
	assert_false(SESSION._ordinary_combat_settled_record(terminal, forged, proofs))
	forged = settled.duplicate(true)
	forged.participants[2].actor_vitals.owned_a.body_generation = 2
	assert_false(SESSION._ordinary_combat_settled_record(terminal, forged, proofs))
	forged = settled.duplicate(true)
	forged.participants[2].character_id = "foreign_owner"
	assert_false(SESSION._ordinary_combat_settled_record(terminal, forged, proofs))
	forged = settled.duplicate(true)
	forged.opponent.card.uid = "foreign_enemy"
	assert_false(SESSION._ordinary_combat_settled_record(terminal, forged, proofs))
	forged = settled.duplicate(true)
	forged.seq += 1
	assert_false(SESSION._ordinary_combat_settled_record(terminal, forged, proofs))
	proof.accepted = false
	assert_false(SESSION._ordinary_combat_settled_record(terminal, settled, proofs))
	proof.accepted = true
	proof.proposal = f.proposal.duplicate(true)
	proof.proposal.peer_id = 9
	assert_false(SESSION._ordinary_combat_settled_record(terminal, settled, proofs))
	_free_fixture(f)

func test_terminal_actual_leave_composes_original_ack_with_global_sequence_proof() -> void:
	var f: Dictionary = _fixture()
	assert_true(f.host.call("commit_actor_vitals", f.proposal).get("ok") == true)
	f.host.call("set_phase", f.id, "done")
	var terminal: Dictionary = f.host.call("record", f.id).duplicate(true)
	assert_true(f.host.call("acknowledge_actor_vitals", f.id, "owner_a", "owned_a", 1, f.proposal.settlement_receipt))
	var accepted: Dictionary = f.row.duplicate(true)
	accepted.status = "accepted"
	var proof: Dictionary = {"accepted": true, "scope": f.scope, "world_id": "world_a", "character_id": "owner_a",
		"proposal": f.proposal, "source_record": f.source, "accepted_row": accepted}
	var proofs: Dictionary = {f.proposal.settlement_receipt.receipt_id: proof}
	var before_leave: Dictionary = f.host.call("record", f.id).duplicate(true)
	f.host.set("seq", int(f.host.get("seq")) + 17) # Another actual arbiter record may advance the global clock.
	var global_seq: int = int(f.host.get("seq"))
	assert_true(f.host.call("leave", f.id, 2).get("ok") == true)
	var departed: Dictionary = f.host.call("record", f.id).duplicate(true)
	var leave: Dictionary = {"encounter_id": f.id, "peer_id": 2, "record_before": before_leave,
		"host_seq_before": global_seq, "record_after": departed}
	assert_true(SESSION._ordinary_combat_settled_record(terminal, departed, proofs, [leave]))
	assert_false(SESSION._ordinary_combat_settled_record(terminal, departed, proofs), "no inferred global departure clock")
	var forged: Dictionary = leave.duplicate(true)
	forged.host_seq_before += 1
	assert_false(SESSION._ordinary_combat_settled_record(terminal, departed, proofs, [forged]))
	forged = leave.duplicate(true)
	forged.peer_id = 9
	assert_false(SESSION._ordinary_combat_settled_record(terminal, departed, proofs, [forged]))
	var foreign: Dictionary = departed.duplicate(true)
	foreign.retained_actor_participants.owner_a.actor_vitals.owned_a.hp += 1.0
	assert_false(SESSION._ordinary_combat_settled_record(terminal, foreign, proofs, [leave]))
	assert_true(ACTOR.equivalent(terminal.participants[2].actor_vitals.owned_a.settled_revision, 0))
	_free_fixture(f)

func test_completion_replays_exact_accepted_round_actor_promotion_without_new_body() -> void:
	var builder: RefCounted = ROUND_FIXTURE.new()
	var initial: Dictionary = RECORD.portable_projection(builder.call("_player").call("save_data"))
	var template: Dictionary = builder.call("_duty", initial)
	assert_false(initial.is_empty(), "canonical five-card fixture must be present")
	assert_false(template.is_empty(), "canonical round duty fixture must be constructed before any promotion test")
	if initial.is_empty() or template.is_empty(): return
	var before: Dictionary = ROUND.settled_before(initial, template.intent, template.context)
	assert_false(before.is_empty(), "canonical original terminal HP projection must validate")
	if before.is_empty(): return
	var character: String = str(before.character_id)
	var uid: String = str(before.party[0].uid)
	var host: RefCounted = ACCEPTED.new()
	var body := Node.new()
	var record: Dictionary = host.call("open", 2, "meadows", "trainer",
		{"hp": 20.0, "owner_npc": "warden_aldis", "card": template.context.enemy_record, "round": 1}, uid, character)
	var id: String = str(record.encounter_id)
	assert_true(host.call("bind_actor_body", id, 2, character, before.party[0], body.get_instance_id()).get("ok") == true)
	var vitals: Array = template.context.settled_vitals.duplicate(true)
	vitals[0].actor_generation = 1
	var binding: Dictionary = {"peer_id": 2, "character_id": character, "active_uid": uid,
		"actor_generation": 1, "settled_vitals": vitals}
	var duty: Dictionary = ROUND.make_duty("resource-namespace", "resource-epoch", "meadows", "warden_aldis",
		id, 1, template.context.enemy_record, binding, [{"peer_id": 2, "character_id": character}])
	assert_false(duty.is_empty())
	if duty.is_empty():
		body.free()
		return
	record.ordinary_combat_reward_owner = duty.context.reward_scope.duplicate(true)
	host.call("set_phase", id, "done")
	var terminal: Dictionary = {"settled_record": host.call("record", id).duplicate(true)}
	var row: Dictionary = builder.call("_row", before, duty)
	assert_true(builder.get("failures").is_empty(), "shared canonical round codec fixture must succeed")
	assert_false(row.is_empty())
	if row.is_empty():
		body.free()
		return
	row.status = "accepted" # Disclosed exact durable post-round authority baseline.
	var world: RefCounted = preload("res://tests/test_foundation_resources.gd").new().call("_world")
	world.get("reward_deliveries")[row.delivery_id] = row.duplicate(true)
	var authority: RefCounted = AUTH.new()
	assert_true(authority.call("bind_world", "resource-namespace"))
	assert_true(authority.call("seed_admitted_character", row.after, character).get("ok") == true)
	assert_true(authority.call("recover_durable_training", character, world.get("reward_deliveries")).get("ok") == true)
	var admitted: Dictionary = authority.call("state", character)
	var revision: int = int(authority.call("revision", character))
	var stage: Dictionary = host.call("stage_actor_training_baseline", row, admitted, revision, "resource-namespace", "resource-slot")
	assert_true(stage.get("ok") == true)
	assert_true(host.call("commit_actor_training_baseline", stage, row, admitted, revision,
		world.get("reward_deliveries"), "resource-namespace", "resource-slot"))
	var current: Dictionary = host.call("record", id).duplicate(true)
	assert_eq(current.participants[2].actor_bound_uid, "")
	assert_eq(current.participants[2].actor_vitals[uid].body_instance_id, 0)
	assert_true(int(current.participants[2].actor_vitals[uid].body_generation) > 1)
	var session: Node = SESSION.new()
	session.set("_character_authority", authority)
	var prior: Dictionary = {"scope": duty.context.reward_scope, "duties": [duty]}
	assert_true(session.call("_ordinary_combat_completion_record", terminal, prior, current, world))
	var forged: Dictionary = current.duplicate(true)
	forged.participants[2].actor_vitals[uid].body_generation += 1
	assert_false(session.call("_ordinary_combat_completion_record", terminal, prior, forged, world))
	forged = current.duplicate(true)
	forged.participants[2].actor_vitals[uid].max_hp += 1.0
	assert_false(session.call("_ordinary_combat_completion_record", terminal, prior, forged, world))
	var wrong: Dictionary = row.duplicate(true)
	wrong.receipt += "_forged"
	world.get("reward_deliveries")[row.delivery_id] = wrong
	assert_false(session.call("_ordinary_combat_completion_record", terminal, prior, current, world))
	session.free()
	body.free()
