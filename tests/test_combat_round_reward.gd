extends "res://tests/test_case.gd"

## Actual canonical codecs, authority CAS, owner installer and split disk
## writer. Terminal actor/transport admission are disclosed source fixtures;
## these tests do not claim an actual encounter, ENet or controller route.
const ROUND := preload("res://scripts/net/combat_round_reward.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const E := preload("res://scripts/creatures/essence.gd")
const P := preload("res://scripts/creatures/progression.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const PREP := preload("res://scripts/net/owner_passive_preparation.gd")
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const AUTH := preload("res://scripts/net/character_authority.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const ORDER := preload("res://scripts/net/foundation_retry_order.gd")
const MASTERY := preload("res://tests/test_combat_mastery_delivery.gd")
const VITAL_FIXTURE := preload("res://tests/test_actor_vitals_authority.gd")
const VITALS := preload("res://scripts/net/actor_vitals_delivery.gd")
const SERVICE_FIXTURE := preload("res://tests/test_owner_passive_sync.gd")

class VitalsSession extends SAVE.FixtureSession:
	var passive: RefCounted
	var proof: Dictionary = {}
	var messages: Array[Dictionary] = []
	func _owner_passive_send_peer(_peer: int, packet: Dictionary) -> void: messages.append(packet.duplicate(true))
	func _owner_passive_send_host(packet: Dictionary) -> void: messages.append(packet.duplicate(true))
	func _owner_passive_actor_vitals_record(row: Dictionary, saved: bool) -> bool:
		return passive.call("record_vitals", row, saved) == true
	func _owner_passive_actor_vitals_context(peer: int, packet: Dictionary) -> Dictionary:
		# Disclosed authenticated retained original; never read packet HP/core.
		var row: Dictionary = proof.get("row", {})
		if peer != 2 or row.is_empty() or packet.get("delivery_id") != row.delivery_id \
			or packet.get("journal_revision") != row.journal_revision \
			or packet.get("receipt_hash") != PREP.fingerprint(row.receipt): return {}
		if packet.op == "actor_vitals_saved" and row.status != "accepted": return {}
		return proof.duplicate(true)

func _player() -> RefCounted:
	var player: RefCounted = DATA.new()._player()
	for species: String in ["mosshell", "mudsnout", "burrowback", "bramblebun"]:
		player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn(species))
	player.party.at(4).hp = 0.0
	player.party.at(4).fainted = true
	return player

func _duty(before: Dictionary, phase: String = "round") -> Dictionary:
	var vitals: Array = []
	for index: int in before.party.size():
		var card: Dictionary = before.party[index]
		vitals.append({"uid": card.uid, "hp": float(card.hp) * 0.5 if index == 0 else card.hp,
			"max_hp": card.max_hp, "fainted": card.fainted, "actor_generation": 7 if index == 0 else 0})
	var enemy_species := "burrowback"
	var enemy_level := 21
	var round_number := 1
	if phase == "completion":
		var spec: Dictionary = preload("res://scripts/world/trainer_npc.gd").trainer("warden_aldis")
		round_number = spec.team.size()
		enemy_species = str(spec.team.back().species)
		enemy_level = int(spec.team.back().level)
	var actual_enemy: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn(enemy_species)
	actual_enemy.set("level", enemy_level)
	actual_enemy.set("hp", 0.0)
	actual_enemy.set("fainted", true)
	var enemy: Dictionary = preload("res://scripts/save/water_capture_codec.gd").encode(actual_enemy)
	assert_false(enemy.is_empty(), "terminal fixture freezes the actual species card and canonical types")
	var binding := {"peer_id": 2, "character_id": DATA.CHARACTER, "active_uid": before.party[0].uid,
		"actor_generation": 7, "settled_vitals": vitals}
	return ROUND.make_duty("resource-namespace", "resource-epoch", "meadows", "warden_aldis",
		"actual-trainer-fight", round_number, enemy, binding, [{"peer_id": 2, "character_id": DATA.CHARACTER}], phase)

func _event(duty: Dictionary) -> Dictionary:
	return EVENT.make(DATA.new()._world(), "resource-epoch", duty.context.source_key, [duty])

func _row(before: Dictionary, duty: Dictionary, revision: int = 0, previous: Variant = null) -> Dictionary:
	var context: Dictionary = duty.context.duplicate(true)
	context.merge({"character_id": DATA.CHARACTER, "expected_revision": revision, "in_range": true,
		"in_combat": false, "foundation_runtime_authorized": true})
	var proposal := ACTIONS.stage(before, revision, duty.action, duty.intent, context, RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return {}
	proposal.character_revision = revision + 1
	var row := DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch", proposal, previous, RECORD.errors)
	assert_false(row.is_empty())
	return row

func test_actual_settled_HP_and_reduced_round_award_keep_all_five_original_cards() -> void:
	var before := RECORD.portable_projection(_player().save_data())
	var original := var_to_bytes(before)
	var duty := _duty(before)
	assert_false(duty.is_empty())
	if duty.is_empty(): return
	var event := _event(duty)
	assert_true(EVENT.valid(event, "resource-namespace", "resource-slot"))
	var settled := ROUND.settled_before(before, duty.intent, duty.context)
	assert_eq(settled.party[0].hp, float(before.party[0].hp) * 0.5)
	var core: Dictionary = settled.duplicate(true)
	core.party[0].hp = before.party[0].hp
	assert_true(PREP.exact(core, before), "only exact terminal host HP/fainted may differ before award")
	var result := ROUND.stage(before, duty.intent, duty.context)
	assert_true(result.get("ok") == true, str(result))
	if result.get("ok") != true: return
	assert_eq(var_to_bytes(before), original)
	assert_eq(result.state.party.size(), 5)
	assert_eq(result.awards[before.party[0].uid].authored_award, P.scaled_combat_xp(21, P.config(), E.config()))
	assert_eq(result.awards[before.party[1].uid].authored_award, P.scaled_party_combat_xp(21, P.config(), E.config()))
	for index: int in 5:
		assert_eq(result.state.party[index].uid, before.party[index].uid)
		assert_eq(result.state.party[index].battles_fought, before.party[index].battles_fought + (0 if index == 4 else 1))
		assert_true(float(result.state.party[index].level) <= E.creature_cap(before.redesign_character, before.party[index].uid))
		assert_true(absf(float(result.state.party[index].hp) / float(result.state.party[index].max_hp)
			- float(settled.party[index].hp) / float(settled.party[index].max_hp)) < 0.000000001)
	assert_eq(result.state.party[4], before.party[4], "fainted member gains no XP, mood or battle history")
	assert_eq(result.state.redesign_character.transaction_receipts.size(), before.redesign_character.transaction_receipts.size() + 1)
	assert_true(RECORD.errors(result.state, DATA.CHARACTER).is_empty())

func test_terminal_source_and_complete_owner_baseline_refuse_forged_fields() -> void:
	var before := RECORD.portable_projection(_player().save_data())
	var duty := _duty(before)
	for defect: String in ["peer", "character", "generation", "round", "enemy", "enemy_type", "enemy_secondary_type", "epoch", "world", "realm", "HP", "fainted", "participant", "phase"]:
		var bad: Dictionary = duty.duplicate(true)
		match defect:
			"peer": bad.context.binding.peer_id = 99
			"character": bad.character_id = "foreign-character"
			"generation": bad.context.binding.actor_generation += 1
			"round": bad.intent.round += 1
			"enemy": bad.context.enemy_record.uid = "forged-enemy"
			"enemy_type": bad.context.enemy_record.creature_type = "forged-type"
			"enemy_secondary_type": bad.context.enemy_record.secondary_type = "forged-type"
			"epoch": bad.context.session_id = "foreign-epoch"
			"world": bad.context.world_namespace = "foreign-world"
			"realm": bad.context.realm = "water"
			"HP": bad.context.settled_vitals[0].hp = bad.context.settled_vitals[0].max_hp + 1.0
			"fainted": bad.context.settled_vitals[0].fainted = true
			"participant": bad.context.participants = []
			"phase": bad.intent.phase = "completion"
		if defect in ["enemy_type", "enemy_secondary_type"]:
			bad.context.source_key = ROUND.source_id(bad.intent, bad.context)
		assert_false(ROUND.source_valid(bad.intent, bad.context, bad.character_id), defect)
	var bench: Dictionary = duty.context.duplicate(true)
	bench.settled_vitals[1].hp -= 1.0
	assert_true(ROUND.settled_before(before, duty.intent, bench).is_empty(), "undeployed bench cannot acquire claimed damage")
	var row := _row(before, duty)
	if row.is_empty(): return
	var settled := ROUND.settled_before(before, duty.intent, duty.context)
	assert_true(DELIVERY.owner_plan(settled, row, RECORD.errors).ok)
	assert_false(DELIVERY.owner_plan(before, row, RECORD.errors).ok, "unsettled owner HP cannot be imported by award")
	for field: String in ["hp", "xp", "attack", "happiness", "distance_m_together", "battles_fought"]:
		var current: Dictionary = settled.duplicate(true)
		current.party[0][field] += 0.000001 if field not in ["xp", "battles_fought"] else 1
		assert_false(DELIVERY.owner_plan(current, row, RECORD.errors).ok, field)
	assert_true(DELIVERY.owner_plan(row.after, row, RECORD.errors).duplicate)
	row.status = "accepted"
	assert_false(DELIVERY.owner_plan(settled, row, RECORD.errors).ok, "accepted history is never new credit")
	assert_true(DELIVERY.owner_plan(row.after, row, RECORD.errors).duplicate)

func test_full_care_replay_plus_typed_terminal_HP_checkpoint_has_exact_authority_CAS() -> void:
	var before := RECORD.portable_projection(_player().save_data())
	var duty := _duty(before)
	var event := _event(duty)
	var cursor := REPLAY.begin(before, {"meadows": ["already-discovered"]})
	var uids: Array = []
	for card: Dictionary in before.party: uids.append(card.uid)
	var applied := REPLAY.apply(cursor, {"version": 1, "sequence": 1, "op": "condition", "delta": 0.1, "uids": uids},
		{"max_elapsed": 1.0, "max_speed": 20.0, "realm": "meadows", "landmarks": {}})
	assert_true(applied.get("ok") == true, str(applied))
	if applied.get("ok") != true: return
	cursor = applied.cursor
	var prepared := PREP.make(event, duty, before, 0, "resource-epoch", cursor, DATA.TXN)
	assert_false(prepared.is_empty())
	if prepared.is_empty(): return
	assert_true(PREP.valid_host(prepared, event, cursor))
	assert_true(PREP.exact(prepared.after, ROUND.settled_before(cursor.state, duty.intent, duty.context)))
	assert_false(PREP.owner_plan(cursor.state, prepared, event, cursor.discovered).ok)
	assert_true(PREP.owner_plan(prepared.after, prepared, event, cursor.discovered).ok)
	for field: String in ["hp", "xp", "happiness", "distance_m_together"]:
		var altered: Dictionary = cursor.duplicate(true)
		altered.state.party[0][field] += 1
		assert_false(PREP.valid_host(prepared, event, altered), field)
	for field: String in ["hp", "enemy", "round", "peer"]:
		var altered: Dictionary = prepared.duplicate(true)
		match field:
			"hp": altered.duty.context.settled_vitals[0].hp -= 1.0
			"enemy": altered.duty.context.enemy_record.level += 1
			"round": altered.duty.intent.round += 1
			"peer": altered.duty.context.binding.peer_id += 1
		altered.duty.context.source_key = ROUND.source_id(altered.duty.intent, altered.duty.context)
		altered.duty_hash = PREP.fingerprint(altered.duty)
		altered.hash = PREP.preparation_hash(altered)
		assert_false(PREP.valid_host(altered, event, cursor), "retained host source never changes: " + field)
	var authority := AUTH.new()
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(authority.seed_discovered_landmarks(DATA.CHARACTER, cursor.discovered))
	assert_false(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, prepared, event, {}))
	assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, prepared, event, cursor))
	assert_false(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, "f".repeat(64)))
	assert_true(PREP.exact(authority.state(DATA.CHARACTER), before))
	# Explicit authenticated owner BOOL-save seam: no transport/save is forged.
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, prepared.hash))
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, prepared.hash))
	assert_eq(authority.revision(DATA.CHARACTER), 1)
	assert_true(PREP.exact(authority.state(DATA.CHARACTER), prepared.after))
	var row := _row(authority.state(DATA.CHARACTER), duty, 1)
	assert_false(row.is_empty())
	if not row.is_empty(): assert_eq(row.before.party[0].happiness, prepared.after.party[0].happiness)

func test_authored_completion_bonus_is_separate_without_an_extra_victory() -> void:
	var before := RECORD.portable_projection(_player().save_data())
	var duty := _duty(before, "completion")
	assert_false(duty.is_empty())
	if duty.is_empty(): return
	assert_true(EVENT.valid(_event(duty), "resource-namespace", "resource-slot"))
	assert_true(ROUND.source_id(duty.intent, duty.context) != _duty(before).context.source_key)
	var result := ROUND.stage(before, duty.intent, duty.context)
	assert_true(result.get("ok") == true, str(result))
	if result.get("ok") != true: return
	var claimed: Dictionary = duty.context.duplicate(true)
	claimed.xp_bonus = 999999
	assert_eq(ROUND.stage(before, duty.intent, claimed).awards, result.awards, "packet bonus never changes authored lookup")
	var settled := ROUND.settled_before(before, duty.intent, duty.context)
	for index: int in 5:
		var card: Dictionary = settled.party[index]
		assert_eq(result.state.party[index].battles_fought, card.battles_fought)
		if card.fainted:
			assert_eq(result.state.party[index], card)
			continue
		assert_eq(result.awards[card.uid], 400, "exact authored Warden bonus")
		var expected := P.staged_xp(card, E.creature_cap(before.redesign_character, card.uid), 400, P.config(), E._canonical_trait_maximum.bind(before.redesign_character.creatures))
		expected = P.staged_training_condition(expected, int(expected.level) - int(card.level), false)
		assert_eq(result.state.party[index].level, expected.level)
		assert_eq(result.state.party[index].xp, expected.xp)
		assert_eq(result.state.party[index].happiness, expected.happiness, "level mood only, no second victory mood")
	var bad: Dictionary = duty.duplicate(true)
	bad.context.actual_host_trainer_won = false
	assert_false(ROUND.source_valid(bad.intent, bad.context, DATA.CHARACTER))
	bad = duty.duplicate(true)
	bad.intent.round -= 1
	bad.context.source_key = ROUND.source_id(bad.intent, bad.context)
	assert_false(ROUND.source_valid(bad.intent, bad.context, DATA.CHARACTER), "completion requires authored final round")
	assert_false(ROUND.stage(result.state, duty.intent, duty.context).ok, "original receipt cannot pay bonus twice")

func test_original_round_owner_BOOL_failure_retries_disk_once_without_replacing_creatures() -> void:
	var directory := "user://test_combat_round_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = _player()
	game.world = DATA.new()._world()
	var session := SAVE.FixtureSession.new()
	session.fixture = game
	game.session = session
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var authority := AUTH.new()
	session.set("_character_authority", authority)
	var before := RECORD.portable_projection(game.local.save_data())
	var duty := _duty(before)
	var row := _row(before, duty)
	if row.is_empty():
		session.free()
		game.free()
		preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)
		return
	var ledger := LEDGER.new(game.world)
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(writer.save_character_prepared(game, DATA.CHARACTER))
	var path: String = writer.character_store.call("path_for", DATA.CHARACTER)
	var old_disk := FileAccess.get_file_as_bytes(path)
	assert_true(ledger.commit_creature_training_delivery(row, 2).ok)
	assert_true(writer.save_world_prepared(game, "resource-slot"))
	# Controlled terminal actor fixture; actual typed HP BOOL/ACK is exercised
	# separately by the interleaved care/HP test below.
	game.local.party.at(0).hp = float(duty.context.settled_vitals[0].hp)
	var instances: Array = game.local.party.members().duplicate()
	writer.refuse_owner = true
	var failed := OWNER.apply_owner(game, row)
	assert_eq(failed.get("code"), "owner_action_save_failed", str(failed))
	assert_true(failed.get("pending") == true and failed.get("saved") == false)
	assert_true(PREP.exact(RECORD.portable_projection(game.local.save_data()), row.after))
	assert_eq(FileAccess.get_file_as_bytes(path), old_disk)
	assert_true(session.owns_input(), "original unsaved decision retains mutation fence")
	writer.refuse_owner = false
	var retry := OWNER.apply_owner(game, row)
	assert_true(retry.get("ok") == true and retry.get("saved") == true and retry.get("duplicate") == true, str(retry))
	for index: int in 5: assert_eq(game.local.party.at(index), instances[index])
	var saved: Dictionary = writer.character_store.call("read", DATA.CHARACTER)
	assert_true(PREP.exact(RECORD.portable_projection(saved), row.after))
	assert_true(session.owns_input(), "successful disk write alone never fabricates remote ACK")
	assert_false(ledger.commit_creature_training_delivery(row, 2).ok)
	assert_false(ledger.accept_creature_training_delivery(row.delivery_id, DATA.CHARACTER, row.journal_revision + 1, row.receipt, 2).ok)
	assert_false(ledger.accept_creature_training_delivery(row.delivery_id, "foreign-owner", row.journal_revision, row.receipt, 2).ok)
	assert_true(ledger.accept_creature_training_delivery(row.delivery_id, DATA.CHARACTER, row.journal_revision, row.receipt, 2).ok)
	assert_false(ledger.accept_creature_training_delivery(row.delivery_id, DATA.CHARACTER, row.journal_revision, row.receipt, 2).ok)
	session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)

func test_round_priority_keeps_all_190_originals_and_pending_or_invalid_order() -> void:
	var before := RECORD.portable_projection(_player().save_data())
	var world: RefCounted = DATA.new()._world()
	for index: int in 190:
		var duty: Dictionary = MASTERY.new()._duty(before)
		duty.intent.action_id = "before-terminal-%d" % index
		duty.context.source_key = "combat_mastery:" + str(duty.intent.action_id)
		duty.context.outcome.action_id = duty.intent.action_id
		var event := EVENT.make(world, "resource-epoch", "mastery:" + str(duty.intent.action_id), [duty])
		assert_false(event.is_empty())
		world.reward_deliveries[event.delivery_id] = event
	var terminal := _event(_duty(before))
	world.reward_deliveries[terminal.delivery_id] = terminal
	var original := var_to_bytes(world.reward_deliveries)
	var work := ORDER.ordered(world.reward_deliveries, "resource-namespace", "resource-slot")
	assert_eq(work.size(), 191)
	assert_eq(work[0].event.delivery_id, terminal.delivery_id, "first round has no latest row but owns immediate award")
	assert_eq(var_to_bytes(world.reward_deliveries), original)
	var row := _row(before, terminal.duties[0])
	if row.is_empty(): return
	world.reward_deliveries[row.delivery_id] = row
	work = ORDER.ordered(world.reward_deliveries, "resource-namespace", "resource-slot")
	assert_eq(work[0].duty.action, "combat_mastery", "pending original retains conservative original ordering")
	row.status = "accepted"
	work = ORDER.ordered(world.reward_deliveries, "resource-namespace", "resource-slot")
	assert_eq(work[0].event.delivery_id, terminal.delivery_id)
	row.after.party[0].xp += 1
	work = ORDER.ordered(world.reward_deliveries, "resource-namespace", "resource-slot")
	assert_eq(work[0].duty.action, "combat_mastery", "invalid latest row cannot authorize priority")

func test_typed_faint_applies_original_condition_once_with_full_core_CAS() -> void:
	var before := RECORD.portable_projection(_player().save_data())
	before.party[0].rested = true
	before.party[0].rested_seconds_left = 60.0
	var duty := _duty(before)
	duty.context.settled_vitals[0].hp = 0.0
	duty.context.settled_vitals[0].fainted = true
	var settled := ROUND.settled_before(before, duty.intent, duty.context)
	var snapshot := P.TrainingConditionSnapshot.new()
	snapshot.values = before.party[0].duplicate(true)
	var condition: Script = preload("res://scripts/creatures/creature_condition.gd")
	condition.call("note_faint", snapshot, condition.call("config"))
	assert_eq(settled.party[0].happiness, snapshot.values.happiness)
	assert_eq(settled.party[0].rested, snapshot.values.rested)
	assert_eq(settled.party[0].rested_seconds_left, snapshot.values.rested_seconds_left)
	assert_eq(settled.party[0].hp, 0.0)
	assert_true(settled.party[0].fainted)
	assert_eq(settled.party[4], before.party[4], "already fainted bench never spends condition again")
	assert_true(PREP.exact(ROUND.settled_before(settled, duty.intent, duty.context), settled))
	var authority := AUTH.new()
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	var receipt := {"receipt_id": "actual-first-faint", "encounter_id": "actual-trainer-fight",
		"creature_uid": before.party[0].uid, "body_generation": 7, "vitals_revision": 1}
	var stage := authority.stage_creature_vitals(DATA.CHARACTER, before.party[0].uid, 0,
		float(before.party[0].hp), false, 0.0, true, receipt)
	assert_true(stage.get("ok") == true, str(stage))
	if stage.get("ok") != true: return
	assert_eq(authority.state(DATA.CHARACTER).party[0], settled.party[0])
	assert_true(authority.finish_creature_vitals(stage, false), "failed world BOOL restores full original condition as well as HP")
	assert_true(PREP.exact(authority.state(DATA.CHARACTER), before))
	stage = authority.stage_creature_vitals(DATA.CHARACTER, before.party[0].uid, 0,
		float(before.party[0].hp), false, 0.0, true, receipt)
	assert_true(authority.finish_creature_vitals(stage, true))
	var again := authority.commit_creature_vitals(DATA.CHARACTER, before.party[0].uid, 0,
		float(before.party[0].hp), false, 0.0, true, receipt)
	assert_true(again.get("duplicate") == true)
	assert_eq(authority.state(DATA.CHARACTER).party[0], settled.party[0])

func test_typed_faint_owner_disk_loss_retry_and_recovery_do_not_repeat_condition() -> void:
	var directory := "user://test_round_faint_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var fixture := VITAL_FIXTURE.new()
	var game := VITAL_FIXTURE.OwnerGame.new()
	game.local = fixture._player()
	game.local.party.at(0).rested = true
	game.local.party.at(0).rested_seconds_left = 60.0
	game.world = DATA.new()._world()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	var writer := VITAL_FIXTURE.OwnerWriter.new()
	writer.store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	assert_true(writer.save_character(game, "owner_a"))
	var path: String = writer.store.call("path_for", "owner_a")
	var old_disk := FileAccess.get_file_as_bytes(path)
	var before: Dictionary = fixture._portable(game.local)
	var row: Dictionary = fixture._row(before, 1, 0.0)
	assert_false(row.is_empty())
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	var expected := VITALS.settled_card(before.party[0], 0.0, true)
	writer.refuse = true
	assert_false(VITALS.apply_owner(game, row).ok)
	assert_eq(fixture._portable(game.local).party[0], expected)
	assert_eq(FileAccess.get_file_as_bytes(path), old_disk)
	assert_true(game.local.satchel_escrow.is_empty())
	assert_false(VITALS.apply_owner(game, row).ok)
	assert_eq(fixture._portable(game.local).party[0], expected, "failed BOOL retry never subtracts faint mood twice")
	writer.refuse = false
	var writes := writer.writes
	assert_true(VITALS.apply_owner(game, row).ok)
	assert_eq(writer.writes, writes + 1)
	var saved: Dictionary = writer.store.call("read", "owner_a")
	assert_eq(saved.party[0], expected)
	assert_true(VITALS.apply_owner(game, row).duplicate)
	assert_eq(fixture._portable(game.local).party[0], expected)
	var authority := AUTH.new()
	assert_true(authority.bind_world("namespace_a"))
	assert_true(authority.seed_admitted_character(before, "owner_a").ok)
	assert_true(authority.recover_durable_vitals("owner_a", {row.delivery_id: row}).ok)
	assert_eq(authority.state("owner_a").party[0], expected)
	assert_true(authority.recover_durable_vitals("owner_a", {row.delivery_id: row}).ok)
	assert_eq(authority.state("owner_a").party[0], expected)
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)

func test_interleaved_real_care_typed_HP_disk_retry_ACK_and_round_checkpoint_preserve_stream() -> void:
	var directory := "user://test_round_stream_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = _player()
	game.world = DATA.new()._world()
	var session := VitalsSession.new()
	session.fixture = game
	game.session = session
	var authority := AUTH.new()
	session.set("_character_authority", authority)
	var writer := VITAL_FIXTURE.OwnerWriter.new()
	writer.store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(writer.save_character(game, DATA.CHARACTER))
	var path: String = writer.store.call("path_for", DATA.CHARACTER)
	var old_disk := FileAccess.get_file_as_bytes(path)
	var service := SERVICE_FIXTURE.Service.new(session)
	session.passive = service
	service.arm_owner(before, {})
	assert_true(service._add_host(2, DATA.CHARACTER, service.local.id, before, {}))
	var stream: Dictionary = service.hosts[DATA.CHARACTER]
	var uids: Array = []
	for card: Dictionary in before.party: uids.append(card.uid)
	var condition: Script = preload("res://scripts/creatures/creature_condition.gd")
	for member: RefCounted in game.local.party.members(): condition.call("tick", member, condition.call("config"), 0.1)
	service.record_input({"op": "condition", "delta": 0.1, "uids": uids})
	service._inputs_host(2, stream, {"inputs": service.local.inputs.duplicate(true)})
	assert_eq(stream.cursor.sequence, 1)
	var original_prefix: String = stream.cursor.prefix_hash
	var receipt := {"receipt_id": "interleaved-host-hit", "encounter_id": "actual-trainer-fight",
		"creature_uid": before.party[0].uid, "body_generation": 7, "vitals_revision": 1}
	var hp := float(before.party[0].hp) * 0.5
	var stage := authority.stage_creature_vitals(DATA.CHARACTER, before.party[0].uid, 0,
		float(before.party[0].hp), false, hp, false, receipt)
	assert_true(stage.get("ok") == true, str(stage))
	var row := VITALS.next_record("resource-slot", "resource-namespace", "resource-epoch", DATA.CHARACTER,
		before.party[0].uid, float(before.party[0].max_hp), float(before.party[0].hp), false,
		hp, false, 1, receipt, null)
	assert_false(row.is_empty())
	var ledger := LEDGER.new(game.world)
	assert_true(ledger.commit_actor_vitals_delivery(row, 2).ok)
	assert_true(authority.finish_creature_vitals(stage, true))
	session.proof = {"row": row.duplicate(true), "hp_before": before.party[0].hp, "fainted_before": false, "revision_before": 0}
	writer.refuse = true
	assert_false(VITALS.apply_owner(game, row).ok)
	assert_eq(service.local.sequence, 2, "actual failed BOOL still records the authenticated live HP transition")
	assert_eq(FileAccess.get_file_as_bytes(path), old_disk)
	service._inputs_host(2, stream, {"inputs": service.local.inputs.duplicate(true)})
	assert_eq(stream.cursor.sequence, 2)
	assert_eq(stream.revision, 1)
	assert_true(PREP.exact(stream.cursor.base, authority.state(DATA.CHARACTER)))
	assert_true(PREP.exact(stream.cursor.state, RECORD.portable_projection(game.local.save_data())))
	assert_true(stream.cursor.prefix_hash != original_prefix)
	for member: RefCounted in game.local.party.members(): condition.call("tick", member, condition.call("config"), 0.2)
	service.record_input({"op": "condition", "delta": 0.2, "uids": uids})
	writer.refuse = false
	assert_true(VITALS.apply_owner(game, row).ok)
	assert_eq(service.local.sequence, 4, "one original applied transition, one later actual BOOL marker")
	service._inputs_host(2, stream, {"inputs": service.local.inputs.duplicate(true)})
	assert_eq(stream.cursor.sequence, 3, "saved marker waits exact authenticated original world ACK")
	assert_true(stream.cursor.state.vitals_escrow.is_empty())
	assert_false(authority.promote_accepted_vitals_marker(DATA.CHARACTER, row))
	assert_true(ledger.accept_actor_vitals_delivery(row.delivery_id, DATA.CHARACTER, 1, receipt, 2).ok)
	var accepted: Dictionary = game.world.reward_deliveries[row.delivery_id]
	assert_true(authority.promote_accepted_vitals_marker(DATA.CHARACTER, accepted))
	assert_true(authority.acknowledge_creature_vitals(DATA.CHARACTER, before.party[0].uid, 1, receipt))
	session.proof.row = accepted.duplicate(true)
	service._inputs_host(2, stream, {"inputs": service.local.inputs.duplicate(true)})
	assert_eq(stream.error, "")
	assert_eq(stream.cursor.sequence, 4)
	assert_eq(stream.cursor.elapsed, 0.1 + 0.2)
	assert_true(PREP.exact(stream.cursor.base, authority.state(DATA.CHARACTER)))
	assert_true(PREP.exact(stream.cursor.state, RECORD.portable_projection(game.local.save_data())))
	assert_eq(stream.cursor.prefix_hash, service.local.prefix_hash)
	assert_eq(service.local.id, stream.id, "typed ACK never resets stream, travel or discoveries")
	var duty := _duty(authority.state(DATA.CHARACTER))
	# Terminal arbiter retains the same current HP, not a second invented hit.
	duty.context.settled_vitals[0].hp = hp
	var event := _event(duty)
	var prepared := PREP.make(event, duty, authority.state(DATA.CHARACTER), 1, "resource-epoch", stream.cursor, DATA.TXN)
	assert_false(prepared.is_empty())
	if not prepared.is_empty():
		assert_true(PREP.valid_host(prepared, event, stream.cursor))
		assert_true(PREP.owner_plan(RECORD.portable_projection(game.local.save_data()), prepared, event, {}).ok)
		assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, prepared, event, stream.cursor))
		assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, prepared.hash))
		assert_false(_row(authority.state(DATA.CHARACTER), duty, 2).is_empty())
	session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)
