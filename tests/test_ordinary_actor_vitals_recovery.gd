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
const SAVE_FIXTURE := preload("res://tests/test_foundation_resource_save.gd")
const DATA_FIXTURE := preload("res://tests/test_foundation_resources.gd")

## Only physical discovery is detached; source epoch/owner hooks remain actual.
class EpochDirector extends Node:
	var _session: Node
	var _encounter_host: RefCounted
	var _manager: Node
	var _ordinary_combat_reward_owners: Dictionary = {}
	func uses_durable_trainer_rewards(id: String) -> bool:
		return _ordinary_combat_reward_owners.has(id) \
			and _ordinary_combat_reward_owners[id].get("session_id") == _session.call("_altar_current_epoch")

class EpochSession extends SAVE_FIXTURE.FixtureSession:
	var fixture_director: Node
	var fixture_epoch: String = "resource-epoch"
	func _altar_current_epoch() -> String: return fixture_epoch
	func _foundation_directors_under(_roots: Array) -> Array[Node]:
		var directors: Array[Node] = []
		if fixture_director != null: directors.append(fixture_director)
		return directors
	func _ordinary_combat_director_live(director: Node) -> bool: return director == fixture_director

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
	var writer := Transport.new()
	var journal_epoch: String = writer.get("_actor_vitals_session_id")
	writer.free()
	var row: Dictionary = ACTOR.next_record("world_a", "namespace_a", journal_epoch, "owner_a", owned.uid,
		100.0, 100.0, false, 93.0, false, 2, proposal.settlement_receipt, null)
	assert_true(ACTOR.valid(row, "owner_a", "namespace_a"))
	return {"host": host, "body": body, "id": id, "source": source, "proposal": proposal, "row": row, "scope": scope}

func _free_fixture(f: Dictionary) -> void:
	f.body.free()

func test_wild_actor_owner_scope_keeps_journal_and_transport_epochs_distinct() -> void:
	# Reuse the existing detached source/index fixture. No mounted combat,
	# guest transport or disk write is claimed by this scope-only check.
	var f := _fixture()
	var rec: Dictionary = f.host.call("record", f.id)
	rec.kind = "wild"
	rec.opponent.owner_npc = ""
	rec.erase("ordinary_combat_reward_owner")
	var scope: Dictionary = preload("res://scripts/net/wild_actor_scope.gd").make("namespace_a", "epoch_a", "meadows", f.id)
	rec["wild_actor_owner"] = scope
	var game := SAVE_FIXTURE.FixtureGame.new()
	game.local = ROUND_FIXTURE.new().call("_player")
	game.local.set("character_id", "owner_a")
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	game.world.reward_deliveries[f.row.delivery_id] = f.row
	var session := EpochSession.new()
	session.fixture = game
	session.fixture_epoch = "epoch_a"
	game.session = session
	var director := EpochDirector.new()
	director._session = session
	director._encounter_host = f.host
	session.fixture_director = director
	var proof := {"scope": scope.duplicate(true), "row": f.row.duplicate(true), "journal_epoch": f.row.session_id,
		"world_id": "world_a", "character_id": "owner_a", "proposal": f.proposal.duplicate(true)}
	director.set_meta("foundation_ordinary_vitals_commits", {f.row.receipt.receipt_id: proof})
	var expected := {"character_id": "owner_a", "world_id": "world_a", "world_namespace": "namespace_a",
		"session_epoch": "epoch_a", "journal_session_id": f.row.session_id}
	assert_ne(f.row.session_id, "epoch_a")
	assert_eq(session._owner_passive_actor_vitals_scope(f.row), expected, "same actual wild source binds both independent lifetimes")
	assert_false(ROUND.scope_valid(scope), "no trainer round capability")
	for defect: String in ["transport", "journal", "record", "proof", "row"]:
		match defect:
			"transport": session.fixture_epoch = "foreign"
			"journal": proof.journal_epoch = "cd".repeat(16)
			"record": rec.kind = "trainer"
			"proof": proof.scope = ROUND.scope("namespace_a", "epoch_a", "meadows", "trainer_arden", f.id)
			"row": game.world.reward_deliveries[f.row.delivery_id] = {}
		assert_true(session._owner_passive_actor_vitals_scope(f.row).is_empty(), defect)
		session.fixture_epoch = "epoch_a"
		proof.journal_epoch = f.row.session_id
		rec.kind = "wild"
		proof.scope = scope.duplicate(true)
		game.world.reward_deliveries[f.row.delivery_id] = f.row
	assert_eq(session._owner_passive_actor_vitals_scope(f.row), expected)
	director.free()
	session.free()
	game.free()
	_free_fixture(f)

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
		"journal_epoch": f.row.session_id, "row": f.row,
		"proposal": f.proposal, "source_record": f.source, "accepted_row": accepted,
		"record_before": terminal, "record_after": _committed_record(f, terminal)}
	var proofs: Dictionary = {f.proposal.settlement_receipt.receipt_id: proof}
	var original_before: Dictionary = terminal.duplicate(true)
	assert_true(SESSION._ordinary_combat_settled_record(terminal, settled, proofs))
	assert_true(SESSION._ordinary_combat_settled_record(terminal, settled, proofs), "duplicate original proof is idempotent")
	assert_ne(f.row.session_id, f.scope.session_id, "actual journal source is distinct from transport")
	var foreign_epoch: Dictionary = accepted.duplicate(true)
	foreign_epoch.session_id = Crypto.new().generate_random_bytes(16).hex_encode()
	proof.accepted_row = foreign_epoch
	assert_false(SESSION._ordinary_combat_settled_record(terminal, settled, proofs), "foreign journal epoch cannot settle")
	proof.accepted_row = accepted
	var foreign_scope: Dictionary = f.scope.duplicate(true)
	foreign_scope.session_id = "foreign_transport"
	proof.scope = foreign_scope
	assert_false(SESSION._ordinary_combat_settled_record(terminal, settled, proofs), "foreign transport cannot settle")
	proof.scope = f.scope
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
		"journal_epoch": f.row.session_id, "row": f.row,
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

func test_actual_prepared_damage_fixture_heal_BOOL_retry_next_damage_and_round_projection() -> void:
	# Physical/PeerRunner authorization is deliberately absent in this detached
	# canonical writer fixture. Actual F48 owns that source proof separately.
	var directory: String = "user://test_fixture_topup_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var builder: RefCounted = ROUND_FIXTURE.new()
	var game := SAVE_FIXTURE.FixtureGame.new()
	game.local = builder.call("_player")
	game.world = DATA_FIXTURE.new().call("_world")
	var session := EpochSession.new()
	session.fixture = game
	game.session = session
	var authority: RefCounted = AUTH.new()
	session.set("_character_authority", authority)
	var writer := SAVE_FIXTURE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := SAVE_FIXTURE.FixtureRpc.new()
	rpc.fixture = game
	rpc.ledger = LEDGER.new(game.world)
	rpc.name = "LedgerRpc"
	session.add_child(rpc)
	var journal_epoch: String = rpc.get("_actor_vitals_session_id")
	assert_ne(journal_epoch, session.call("_altar_current_epoch"))
	assert_eq(session.call("_ordinary_actor_vitals_journal_epoch"), journal_epoch)
	var initial: Dictionary = RECORD.portable_projection(game.local.call("save_data"))
	var character: String = str(initial.character_id)
	var uid: String = str(initial.party[0].uid)
	assert_true(authority.call("bind_world", "resource-namespace"))
	assert_true(authority.call("seed_admitted_character", initial, character).get("ok") == true)
	assert_true(writer.save_character_prepared(game, character))
	var host: RefCounted = ACCEPTED.new()
	var body := Node.new()
	var final_template: Dictionary = builder.call("_duty", initial, "completion")
	assert_false(final_template.is_empty())
	if final_template.is_empty():
		body.free()
		SAVE_FIXTURE.new().call("_close", game, rpc, directory)
		return
	var record: Dictionary = host.call("open", 1, "meadows", "boss", {"hp": 20.0,
		"owner_npc": "warden_aldis", "card": final_template.context.enemy_record,
		"round": final_template.intent.round}, uid, character)
	var id: String = str(record.encounter_id)
	record.ordinary_combat_reward_owner = ROUND.scope("resource-namespace", "resource-epoch", "meadows", "warden_aldis", id)
	var director := EpochDirector.new()
	director._session = session
	director._encounter_host = host
	director._ordinary_combat_reward_owners[id] = record.ordinary_combat_reward_owner
	session.fixture_director = director
	assert_true(host.call("bind_actor_body", id, 1, character, initial.party[0], body.get_instance_id()).get("ok") == true)
	var owner_path: String = writer.character_store.call("path_for", character)
	for action: String in ["damage_a", "fixture_heal", "damage_b"]:
		var source: Dictionary = host.call("record", id).duplicate(true)
		var actor: Dictionary = source.participants[1].actor_vitals[uid]
		var heal: bool = action == "fixture_heal"
		var amount: float = float(actor.max_hp) - float(actor.hp) if heal else (7.0 if action == "damage_a" else 5.0)
		var proposal: Dictionary = host.call("stage_actor_vitals", id, 1, uid, int(actor.body_generation),
			int(actor.revision), action, "heal" if heal else "damage", amount, 16)
		assert_true(proposal.get("ok") == true)
		if proposal.get("ok") != true: break
		var frozen: PackedByteArray = var_to_bytes(proposal)
		var previous_hp: float = float(authority.call("state", character).party[0].hp)
		var character_revision: int = int(authority.call("revision", character))
		if heal:
			assert_true(host.call("verify_original_fixture_actor_topup", proposal, source))
			writer.refuse_world = true
			var failed_stage: Dictionary = authority.call("stage_creature_vitals", character, uid, character_revision,
				float(proposal.hp_before), false, float(proposal.hp_after), false, proposal.settlement_receipt)
			assert_true(failed_stage.get("ok") == true)
			var failed: Dictionary = rpc.journal_actor_vitals_prepared(1, character, authority.call("staged_creature_vitals", failed_stage))
			assert_false(failed.get("durable", true))
			assert_true(authority.call("finish_creature_vitals", failed_stage, false))
			assert_eq(authority.call("state", character).party[0].hp, previous_hp)
			assert_eq(host.call("record", id), source, "world refusal never privately heals")
			writer.refuse_world = false
		var stage: Dictionary = authority.call("stage_creature_vitals", character, uid, character_revision,
			float(proposal.hp_before), false, float(proposal.hp_after), false, proposal.settlement_receipt)
		assert_true(stage.get("ok") == true)
		var journal: Dictionary = rpc.journal_actor_vitals_prepared(1, character, authority.call("staged_creature_vitals", stage))
		assert_true(journal.get("ok") == true and journal.get("durable") == true)
		assert_true(authority.call("finish_creature_vitals", stage, true))
		var committed: Dictionary = host.call("commit_original_fixture_actor_topup", proposal, source) if heal \
			else host.call("commit_original_actor_vitals", proposal, source)
		assert_true(committed.get("ok") == true)
		var row: Dictionary = game.world.get("reward_deliveries")[journal.delivery_id].duplicate(true)
		assert_eq(row.session_id, journal_epoch, "actual LedgerRpc stamps its original journal epoch")
		var proof: Dictionary = {"scope": record.ordinary_combat_reward_owner.duplicate(true), "world_id": game.world.world_id,
			"character_id": character, "journal_epoch": journal_epoch, "row": row.duplicate(true), "proposal": proposal,
			"source_record": source, "revision_before": character_revision}
		director.set_meta("foundation_ordinary_vitals_commits", {row.receipt.receipt_id: proof})
		assert_true(session.call("_owner_passive_actor_vitals_record", row, false), "actual Session hook accepts distinct authenticated epochs")
		session.fixture_epoch = "changed_actual_transport"
		assert_false(director.uses_durable_trainer_rewards(id), "current readiness is lost while original owned source remains retained")
		assert_true(session.call("_owner_passive_actor_vitals_scope", row).is_empty())
		assert_false(session.call("_owner_passive_actor_vitals_record", row, false), "stale transport cannot downgrade an owned source to legacy")
		director._ordinary_combat_reward_owners.erase(id)
		assert_false(session.call("_owner_passive_actor_vitals_record", row, false), "retained exact proof still forbids legacy downgrade if current owner map is gone")
		director._ordinary_combat_reward_owners[id] = record.ordinary_combat_reward_owner
		session.fixture_epoch = "resource-epoch"
		assert_true(director.uses_durable_trainer_rewards(id))
		var original_scope: Dictionary = director._ordinary_combat_reward_owners[id]
		director._ordinary_combat_reward_owners[id] = original_scope.duplicate(true)
		director._ordinary_combat_reward_owners[id].session_id = "foreign_transport"
		assert_false(session.call("_owner_passive_actor_vitals_record", row, false))
		director._ordinary_combat_reward_owners[id] = original_scope
		var foreign_row: Dictionary = row.duplicate(true)
		foreign_row.session_id = Crypto.new().generate_random_bytes(16).hex_encode()
		game.world.reward_deliveries[row.delivery_id] = foreign_row
		assert_false(session.call("_owner_passive_actor_vitals_record", foreign_row, false), "even a substituted world row cannot change original journal")
		game.world.reward_deliveries[row.delivery_id] = row
		var replacement := SAVE_FIXTURE.FixtureRpc.new()
		replacement.fixture = game
		replacement.ledger = LEDGER.new(game.world)
		replacement.name = "LedgerRpc"
		session.remove_child(rpc)
		session.add_child(replacement)
		assert_ne(session.call("_ordinary_actor_vitals_journal_epoch"), journal_epoch)
		assert_true(session.call("_owner_passive_actor_vitals_record", row, false), "durable original remains bound across writer replacement, never rebased")
		session.remove_child(replacement)
		replacement.free()
		session.add_child(rpc)
		if heal:
			var old_disk: PackedByteArray = FileAccess.get_file_as_bytes(owner_path)
			writer.refuse_owner = true
			assert_true(rpc.call("publish_actor_vitals", 1, character, uid, row.receipt), "actual first publication runs only after the original row is pinned")
			assert_false(ACTOR.apply_owner(game, row).get("ok", false))
			assert_eq(game.local.party.at(0).hp, proposal.hp_after, "accepted live heal waits real BOOL without rolling back")
			assert_eq(FileAccess.get_file_as_bytes(owner_path), old_disk)
			assert_false(host.call("pending_actor_vitals", id).is_empty())
			writer.refuse_owner = false
		assert_true(ACTOR.apply_owner(game, row).get("ok", false))
		assert_eq(writer.character_store.call("read", character).party[0].hp, proposal.hp_after)
		var original_proof_scope: Dictionary = proof.scope
		proof.scope = original_proof_scope.duplicate(true)
		proof.scope.session_id = "foreign_transport"
		var accepted_candidate: Dictionary = row.duplicate(true)
		accepted_candidate.status = "accepted"
		game.world.reward_deliveries[row.delivery_id] = accepted_candidate
		assert_false(session.call("host_ack_creature_vitals", 1, uid, int(row.character_revision), row.receipt))
		assert_false(authority.call("pending_creature_vitals", character).is_empty(), "foreign transport cannot release the pending authority CAS")
		proof.scope = original_proof_scope
		director.set_meta("foundation_ordinary_vitals_commits", {})
		assert_false(session.call("host_ack_creature_vitals", 1, uid, int(row.character_revision), row.receipt), "retained ownership requires its original ACK proof")
		assert_false(authority.call("pending_creature_vitals", character).is_empty())
		director.set_meta("foundation_ordinary_vitals_commits", {row.receipt.receipt_id: proof})
		game.world.reward_deliveries[row.delivery_id] = row
		assert_true(rpc.call("_accept_actor_vitals", row.delivery_id, int(row.journal_revision), row.receipt, 1), "actual world BOOL and Session ACK settle original separate epochs")
		var accepted: Dictionary = game.world.get("reward_deliveries")[row.delivery_id]
		assert_eq(accepted.status, "accepted")
		assert_true(director.get_meta("foundation_ordinary_vitals_commits")[row.receipt.receipt_id].get("accepted") == true)
		assert_true(host.call("pending_actor_vitals", id).is_empty())
		assert_eq(var_to_bytes(proposal), frozen, "all failed-write retries preserve the original source")
		assert_true(RECORD.errors(authority.call("state", character), character).is_empty())
		if heal:
			assert_false(host.call("commit_original_fixture_actor_topup", proposal, source).get("ok", false), "no duplicate heal commit")
	var before_round: Dictionary = authority.call("state", character)
	assert_true(ACTOR.equivalent(before_round, RECORD.portable_projection(game.local.call("save_data"))), "actual saved typed history remains full-card equal")
	var actor: Dictionary = host.call("record", id).participants[1].actor_vitals[uid]
	var vitals: Array = []
	for card: Dictionary in before_round.party:
		vitals.append({"uid": card.uid, "hp": card.hp, "max_hp": card.max_hp, "fainted": card.fainted,
			"actor_generation": int(actor.body_generation) if card.uid == uid else 0})
	var binding: Dictionary = {"peer_id": 1, "character_id": character, "active_uid": uid,
		"actor_generation": int(actor.body_generation), "settled_vitals": vitals}
	for phase: String in ["round", "completion"]:
		var duty: Dictionary = ROUND.make_duty("resource-namespace", "resource-epoch", "meadows", "warden_aldis", id,
			int(final_template.intent.round), final_template.context.enemy_record, binding,
			[{"peer_id": 1, "character_id": character}], phase)
		assert_false(duty.is_empty())
		if duty.is_empty(): continue
		assert_true(ACTOR.equivalent(ROUND.settled_before(before_round, duty.intent, duty.context), before_round))
		assert_true(ROUND.stage(before_round, duty.intent, duty.context).get("ok") == true, "original healed then damaged core is admissible for each actual phase")
	body.free()
	director.free()
	SAVE_FIXTURE.new().call("_close", game, rpc, directory)

func test_fixture_full_heal_refuses_foreign_peer_generation_epoch_amount_pending_and_terminal_sources() -> void:
	var host: RefCounted = ACCEPTED.new()
	var body := Node.new()
	var owned: Dictionary = {"uid": "owned_a", "hp": 100.0, "max_hp": 100.0, "fainted": false}
	var record: Dictionary = host.call("open", 1, "meadows", "boss",
		{"hp": 20.0, "owner_npc": "warden_aldis", "card": {"uid": "enemy_a"}, "body_generation": 1}, owned.uid, "owner_a")
	var id: String = str(record.encounter_id)
	record.ordinary_combat_reward_owner = ROUND.scope("namespace_a", "epoch_a", "meadows", "warden_aldis", id)
	assert_true(host.call("bind_actor_body", id, 1, "owner_a", owned, body.get_instance_id()).get("ok") == true)
	var damage: Dictionary = host.call("stage_actor_vitals", id, 1, owned.uid, 1, 0, "actual_damage", "damage", 7.0, 16)
	assert_true(host.call("commit_actor_vitals", damage).get("ok") == true)
	assert_true(host.call("acknowledge_actor_vitals", id, "owner_a", owned.uid, 1, damage.settlement_receipt))
	var source: Dictionary = host.call("record", id).duplicate(true)
	var heal: Dictionary = host.call("stage_actor_vitals", id, 1, owned.uid, 1, 1, "actual_fixture_topup", "heal", 7.0, 16)
	assert_true(heal.get("ok") == true)
	assert_true(host.call("verify_original_fixture_actor_topup", heal, source))
	for defect: String in ["peer", "generation", "amount", "uid", "epoch", "terminal_source", "fainted_source", "full_source"]:
		var proposal: Dictionary = heal.duplicate(true)
		var original: Dictionary = source.duplicate(true)
		match defect:
			"peer": proposal.peer_id = 9
			"generation": proposal.body_generation = 2
			"amount": proposal.amount -= 1.0
			"uid": proposal.creature_uid = "foreign_uid"
			"epoch": original.ordinary_combat_reward_owner.session_id = "foreign_epoch"
			"terminal_source": original.phase = "done"
			"fainted_source":
				original.participants[1].actor_vitals.owned_a.hp = 0.0
				original.participants[1].actor_vitals.owned_a.fainted = true
			"full_source": original.participants[1].actor_vitals.owned_a.hp = 100.0
		assert_false(host.call("verify_original_fixture_actor_topup", proposal, original), defect)
	var session: Node = SESSION.new()
	var foreign_provider := Node.new()
	var foreign_director := Node.new()
	assert_false(session.call("ordinary_fixture_actor_topup_commit", foreign_provider, foreign_director, id, 1, heal).get("ok", true))
	host.call("set_phase", id, "done")
	assert_false(host.call("stage_actor_vitals", id, 1, owned.uid, 1, 1, "fresh_done_heal", "heal", 7.0, 16).get("ok", true))
	assert_true(host.call("verify_original_fixture_actor_topup", heal, source), "only the retained original active source survives terminal")
	assert_true(host.call("commit_original_fixture_actor_topup", heal, source).get("ok") == true)
	assert_false(host.call("commit_original_fixture_actor_topup", heal, source).get("ok", true))
	assert_false(host.call("pending_actor_vitals", id).is_empty(), "typed heal remains unresolved until its exact real saved ACK")
	assert_true(host.call("acknowledge_actor_vitals", id, "owner_a", owned.uid, 2, heal.settlement_receipt))
	assert_true(host.call("pending_actor_vitals", id).is_empty())
	session.free()
	foreign_provider.free()
	foreign_director.free()
	body.free()
