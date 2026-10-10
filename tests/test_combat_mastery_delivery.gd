extends "res://tests/test_case.gd"

## Real admitted-character staging, retained-event codec and disk writers.
## Host hit geometry and live actor-baseline admission are disclosed fixtures.
const DATA := preload("res://tests/test_foundation_resources.gd")
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const E := preload("res://scripts/creatures/essence.gd")
const ACTION_ID := "mastery-proof-1"

class ShellSession extends SAVE.FixtureSession:
	func _authority_character(peer: int) -> String:
		return DATA.CHARACTER if peer == 2 else super._authority_character(peer)

class DetachedShells extends "res://scripts/net/realm_shells.gd":
	func _game() -> Node: return null # World journaling below still uses the real disk writer.

func _duty(before: Dictionary) -> Dictionary:
	var card: Dictionary = before.party[0]
	return {"character_id": DATA.CHARACTER, "action": "combat_mastery",
		"intent": {"action_id": ACTION_ID, "creature_uid": card.uid},
		"context": {"source_key": "combat_mastery:" + ACTION_ID, "event_confirmed": true,
			"world_namespace": "resource-namespace", "session_id": "resource-epoch",
			"encounter_id": "mastery-encounter", "participants": [DATA.CHARACTER],
			"binding": {"character_id": DATA.CHARACTER, "creature_uid": card.uid,
				"deployment_generation": 1, "body_instance_id": 55, "actor_generation": 0},
			"outcome": {"action_id": ACTION_ID, "move_id": card.move_quick,
				"attacker_uid": card.uid, "target_uid": "host-opponent",
				"target_hp_before": 100.0, "applied_damage": 12.0}}}

func _context(duty: Dictionary, retained: Dictionary) -> Dictionary:
	var context: Dictionary = duty.context.duplicate(true)
	context.merge({"character_id": DATA.CHARACTER, "expected_revision": 0,
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
		"retained_event": retained.delivery_id})
	return context

func test_retained_hit_rejects_forged_binding_damage_or_epoch_and_preserves_hp() -> void:
	var fixture := DATA.new()
	var before: Dictionary = fixture._before()
	var world: RefCounted = fixture._world()
	var duty := _duty(before)
	var row := EVENT.make(world, "resource-epoch", "mastery:" + ACTION_ID, [duty])
	assert_false(row.is_empty())
	if row.is_empty(): return
	assert_true(EVENT.valid(JSON.parse_string(JSON.stringify(row)), "resource-namespace", "resource-slot"))
	for defect: String in ["binding", "damage", "epoch", "target", "extra"]:
		var bad: Dictionary = row.duplicate(true)
		match defect:
			"binding": bad.duties[0].context.binding.creature_uid = "foreign-owned-creature"
			"damage": bad.duties[0].context.outcome.applied_damage = 101.0
			"epoch": bad.duties[0].context.session_id = "foreign-epoch"
			"target": bad.duties[0].context.outcome.target_uid = before.party[0].uid
			"extra": bad.duties[0].context.outcome.snapshot_replay = true
		assert_false(EVENT.valid(bad, "resource-namespace", "resource-slot"), defect)
	var context := _context(duty, row)
	var proposal := ACTIONS.stage(before, 0, "combat_mastery", duty.intent, context, RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return
	var move: String = before.party[0].move_quick
	assert_eq(proposal.state.party[0].move_mastery_uses[move], 1)
	assert_eq(proposal.state.party[0].hp, before.party[0].hp)
	assert_eq(proposal.state.party[0].move_mastery_receipts[move], [ACTION_ID])
	proposal.character_revision = 1
	var delivery := DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch", proposal, null, RECORD.errors)
	assert_true(DELIVERY.valid(JSON.parse_string(JSON.stringify(delivery)), RECORD.errors))
	context.in_combat = true
	assert_false(ACTIONS.stage(before, 0, "combat_mastery", duty.intent, context, RECORD.errors).ok)
	# Tag retains one command parent and two ordinary creature-owned uses.
	# These are codec/owner-plan fixtures; the live host still owns HP writes.
	var player: RefCounted = fixture._player()
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	before = RECORD.portable_projection(player.save_data())
	assert_eq(RECORD.errors(before, DATA.CHARACTER), [] as Array[String], "both cards use the canonical owned save projection")
	var parent := "command:mastery-encounter:%s:1:7" % DATA.CHARACTER
	var duties: Array = []
	for index in 2:
		var part := "outgoing" if index == 0 else "incoming"
		var tag := _duty(before)
		var card: Dictionary = before.party[index]
		var child := JSON.stringify([parent, part, card.uid, index + 1]).sha256_text()
		tag.intent = {"action_id":child, "creature_uid":card.uid}
		tag.context.source_key = "combat_mastery:" + child
		tag.context.parent_action_id = parent
		tag.context.tag_part = part
		tag.context.binding.creature_uid = card.uid
		tag.context.binding.deployment_generation = index + 1
		tag.context.outcome.action_id = child
		tag.context.outcome.attacker_uid = card.uid
		duties.append(tag)
	var joint := EVENT.make(world, "resource-epoch", "mastery:" + parent, duties)
	assert_false(joint.is_empty(), "both owned quicks share the one retained command parent")
	if joint.is_empty(): return
	assert_true(EVENT.valid(JSON.parse_string(JSON.stringify(joint)), "resource-namespace", "resource-slot"))
	for defect: String in ["parent", "part", "generation", "uid", "target", "duplicate", "third", "missing"]:
		var bad: Dictionary = joint.duplicate(true)
		match defect:
			"parent": bad.duties[1].context.parent_action_id = "command:other:owner:1:7"
			"part": bad.duties[1].context.tag_part = "outgoing"
			"generation": bad.duties[1].context.binding.deployment_generation = 3
			"uid": bad.duties[1].intent.creature_uid = "foreign-owned"
			"target": bad.duties[1].context.outcome.target_uid = "other-opponent"
			"duplicate": bad.duties[1] = bad.duties[0].duplicate(true)
			"third": bad.duties.append(bad.duties[0].duplicate(true))
			"missing": bad.duties[1].context.erase("tag_part")
		assert_false(EVENT.valid(bad, "resource-namespace", "resource-slot"), defect)
	var state := before.duplicate(true)
	for index in 2:
		var tag: Dictionary = duties[index]
		var tag_context := _context(tag, joint)
		tag_context.expected_revision = index
		var accepted := ACTIONS.stage(state, index, "combat_mastery", tag.intent, tag_context, RECORD.errors)
		assert_true(accepted.get("ok") == true, str(accepted))
		if accepted.get("ok") != true: return
		accepted.character_revision = index + 1
		var child_row := DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch", accepted, null, RECORD.errors)
		assert_true(DELIVERY.valid(JSON.parse_string(JSON.stringify(child_row)), RECORD.errors))
		var owned_plan := DELIVERY.owner_plan(state, child_row, RECORD.errors)
		assert_true(owned_plan.get("ok") == true and owned_plan.get("requires_owner_save") == true)
		state = owned_plan.state
		assert_eq(state.party[index].move_mastery_uses[move], 1)
		assert_eq(state.party[index].move_mastery_receipts[move], [tag.intent.action_id])
		assert_eq(state.party[index].hp, before.party[index].hp)
		var wrong := tag_context.duplicate(true)
		wrong.parent_action_id = "command:other:owner:1:7"
		assert_false(ACTIONS.stage(before, 0, "combat_mastery", tag.intent, wrong, RECORD.errors).ok)
	var directory := "user://test_tag_mastery_children_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var store := preload("res://scripts/save/character_save.gd").new(directory)
	assert_true(store.write(DATA.CHARACTER, state), "real CharacterSave BOOL persists the two owned child uses")
	var reloaded: Dictionary = store.read(DATA.CHARACTER)
	assert_eq(RECORD.portable_projection(reloaded).party, state.party)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path_for(DATA.CHARACTER)))

func test_character_snapshot_without_world_id_accepts_a_valid_retained_event() -> void:
	# A character snapshot carries world identity in its split envelope, so the
	# save validator calls errors() with an empty world_id. A valid retained row
	# must pass then (it used to refuse every host save after any Foundation
	# event); a named world still has to match, and a forged row still fails.
	var fixture := DATA.new()
	var before: Dictionary = fixture._before()
	var row := EVENT.make(fixture._world(), "resource-epoch", "mastery:" + ACTION_ID, [_duty(before)])
	assert_false(row.is_empty())
	if row.is_empty(): return
	var rows := {row.delivery_id: JSON.parse_string(JSON.stringify(row))}
	assert_eq(EVENT.errors(rows, "resource-namespace", ""), [] as Array[String])
	assert_eq(EVENT.errors(rows, "resource-namespace", "resource-slot"), [] as Array[String])
	assert_eq(EVENT.errors(rows, "resource-namespace", "another-world").size(), 1)
	var forged: Dictionary = row.duplicate(true)
	forged.duties[0].context.outcome.applied_damage = 101.0
	assert_eq(EVENT.errors({row.delivery_id: forged}, "resource-namespace", "").size(), 1)
	var nameless: Dictionary = row.duplicate(true)
	nameless.world_id = ""
	assert_eq(EVENT.errors({row.delivery_id: nameless}, "resource-namespace", "").size(), 1)

func test_world_and_owner_save_refusal_retry_retains_one_landed_use() -> void:
	var fixture := DATA.new()
	var directory := "user://test_mastery_save_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = fixture._player()
	game.world = fixture._world()
	var session := SAVE.FixtureSession.new()
	session.fixture = game
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := SAVE.FixtureRpc.new()
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(writer.save_world_prepared(game, "resource-slot"))
	assert_true(writer.save_character_prepared(game, DATA.CHARACTER))
	var world_path: String = writer.world_store.call("path_for", "resource-slot")
	var owner_path: String = writer.character_store.call("path_for", DATA.CHARACTER)
	var old_world := FileAccess.get_file_as_bytes(world_path)
	var old_owner := FileAccess.get_file_as_bytes(owner_path)
	var duty := _duty(before)
	writer.refuse_world = true
	assert_false(rpc.journal_foundation_event("mastery:" + ACTION_ID, [duty]).durable)
	assert_true(game.world.reward_deliveries.is_empty())
	assert_eq(FileAccess.get_file_as_bytes(world_path), old_world)
	writer.refuse_world = false
	var retained: Dictionary = rpc.journal_foundation_event("mastery:" + ACTION_ID, [duty])
	assert_true(retained.get("durable") == true, str(retained))
	if retained.get("durable") != true:
		SAVE.new()._close(game, rpc, directory)
		return
	var event: Dictionary = game.world.reward_deliveries[retained.delivery_id]
	var context := _context(duty, event)
	var token := authority.stage_character_action(DATA.CHARACTER, 0, "combat_mastery", duty.intent, context)
	assert_true(token.get("ok") == true, str(token))
	if token.get("ok") != true:
		SAVE.new()._close(game, rpc, directory)
		return
	writer.refuse_world = true
	var failed: Dictionary = rpc.journal_creature_training_prepared(1, DATA.CHARACTER, authority.staged_creature_training(token))
	assert_eq(failed.get("code"), "training_journal_failed")
	assert_true(authority.finish_creature_training(token, false))
	assert_eq(authority.state(DATA.CHARACTER), before)
	assert_true(game.world.reward_deliveries.has(event.delivery_id), "failed personal staging retains original hit")
	writer.refuse_world = false
	token = authority.stage_character_action(DATA.CHARACTER, 0, "combat_mastery", duty.intent, context)
	var journal: Dictionary = rpc.journal_creature_training_prepared(1, DATA.CHARACTER, authority.staged_creature_training(token))
	assert_true(journal.get("durable") == true, str(journal))
	assert_true(authority.finish_creature_training(token, journal.get("durable") == true))
	if journal.get("durable") != true:
		SAVE.new()._close(game, rpc, directory)
		return
	var row: Dictionary = game.world.reward_deliveries[journal.delivery_id]
	var move: String = before.party[0].move_quick
	assert_eq(int(game.local.party.at(0).move_mastery_uses.get(move, 0)), 0)
	var recovered: RefCounted = fixture._world()
	recovered.load_data(writer.world_store.call("read", "resource-slot"))
	assert_true(E._equivalent(recovered.reward_deliveries[row.delivery_id], row))
	writer.refuse_owner = true
	var unsaved := OWNER.apply_owner(game, row)
	assert_eq(unsaved.get("code"), "owner_action_save_failed")
	assert_eq(game.local.party.at(0).move_mastery_uses[move], 1)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), old_owner)
	assert_true(session.owns_input(), "pending owner save retains mutation fence")
	writer.refuse_owner = false
	var retry := OWNER.apply_owner(game, row)
	assert_true(retry.get("saved") == true and retry.get("duplicate") == true, str(retry))
	assert_eq(game.local.party.at(0).move_mastery_uses[move], 1)
	assert_eq(game.local.party.at(0).hp, before.party[0].hp)
	assert_true(E._equivalent(RECORD.portable_projection(writer.character_store.call("read", DATA.CHARACTER)), row.after))
	assert_true(session.owns_input(), "saved owner still needs real host acknowledgement")
	assert_false(rpc.ledger.commit_creature_training_delivery(row, 1).ok)
	assert_true(rpc.journal_foundation_event("mastery:" + ACTION_ID, [duty]).durable)
	assert_eq(game.local.party.at(0).move_mastery_uses[move], 1)
	SAVE.new()._close(game, rpc, directory)

func test_remote_shell_retains_failed_hit_and_retries_before_release() -> void:
	var fixture := DATA.new()
	var directory := "user://test_remote_mastery_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = fixture._player()
	game.world = fixture._world()
	var session := ShellSession.new()
	session.fixture = game
	game.session = session
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := SAVE.FixtureRpc.new()
	rpc.name = "LedgerRpc"
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	session.add_child(rpc)
	var shells := DetachedShells.new()
	session.set("_realms", shells)
	session.add_child(shells)
	var remote := Node3D.new()
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	remote.add_child(director)
	director.set("_session", session)
	director.call("_ensure_encounter_arbiters")
	shells.set("_shells", {"cloudreach": remote})
	assert_eq(session._foundation_realm_roots(), [remote], "registered hosted shell is outside current_scene")
	var host: RefCounted = director.get("_encounter_host")
	var before := RECORD.portable_projection(game.local.save_data())
	var owned: Dictionary = before.party[0]
	var rec: Dictionary = host.open(2, "cloudreach", "wild", {"hp": 100.0, "hp_max": 100.0,
		"position": [2.0, 0.0, 0.0]}, owned.uid, DATA.CHARACTER)
	var admitted: Dictionary = host.bind_actor_body(rec.encounter_id, 2, DATA.CHARACTER, owned, 55)
	assert_true(admitted.get("ok") == true, "remote mastery fixture admits its owned actor")
	var binding := {"character_id": DATA.CHARACTER, "creature_uid": owned.uid,
		"deployment_generation": 1, "body_instance_id": 55, "actor_generation": int(admitted.get("vitals", {}).get("body_generation", 0))}
	var move := {"move_id": owned.move_quick, "slot": "quick", "range": 3.0, "cone_degrees": 100.0,
		"windup": 0.3, "recovery": 0.2, "wind_cost": 12.0,
		"mastery_context": {"world_namespace": "resource-namespace", "session_id": "resource-epoch"}}
	assert_true(host.authorize_move_start({"encounter_id": rec.encounter_id, "action": 1, "slot": "quick"},
		2, owned, binding, move, {"max": 100.0, "regen_per_second": 18.0}, 1000).ok)
	var start: Dictionary = host.move_commit(rec.encounter_id, 2, 1)
	assert_true(host.validate_strike({"encounter_id": rec.encounter_id, "action": 1, "slot": "quick",
		"move_id": owned.move_quick, "move": start.move, "facing": Vector3.RIGHT}, 2,
		{"now_ms": 1300, "origin": Vector3.ZERO, "bodies": [], "move_actor_binding": binding,
			"f22_actor_binding": binding}).ok)
	host.credit_move_hit(rec.encounter_id, 2, 1, 12.0, "remote-opponent", 100.0)
	writer.refuse_world = true
	assert_false(session.foundation_combat_mastery(director, rec.encounter_id, 2, 1).durable)
	assert_eq(host.pending_move_mastery().size(), 1)
	shells._tear_down("cloudreach")
	assert_true(shells.has_shell("cloudreach"))
	assert_false(remote.is_queued_for_deletion(), "failed first world write retains actual authority")
	var crossing := preload("res://autoload/game_state.gd").new()
	crossing.session = session
	crossing.current_realm = "meadows"
	assert_false(crossing._realm_destination_results_settled("cloudreach"), "host cannot occupy the retained shell's root")
	assert_true(crossing._realm_destination_results_settled("water"), "unrelated destination is unaffected")
	assert_eq(crossing.current_realm, "meadows")
	assert_true(session._altar_peer_in_combat(2))
	assert_false(session._altar_peer_in_combat(3), "unrelated guest is not this pending hit's owner")
	writer.refuse_world = false
	session._retry_combat_mastery_sources()
	assert_true(host.pending_move_mastery().is_empty())
	assert_true(crossing._realm_destination_results_settled("cloudreach"))
	assert_eq(game.world.reward_deliveries.size(), 1)
	var event: Dictionary = game.world.reward_deliveries.values()[0]
	assert_eq(event.duties[0].context.outcome.action_id, start.action_id)
	var loaded: Dictionary = writer.world_store.call("read", "resource-slot")
	assert_true(E._equivalent(loaded.reward_deliveries[event.delivery_id], event))
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	var duty: Dictionary = event.duties[0]
	var token := authority.stage_character_action(DATA.CHARACTER, 0, "combat_mastery", duty.intent, _context(duty, event))
	assert_true(token.get("ok") == true, str(token))
	var delivery := DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch",
		authority.staged_creature_training(token), null, RECORD.errors)
	assert_eq(session._training_actor_baseline_proposals(2, delivery).get("code"), "training_actor_still_active")
	host.close(rec.encounter_id)
	assert_true(session._training_actor_baseline_proposals(2, delivery).ok)
	shells._tear_down("cloudreach")
	assert_false(shells.has_shell("cloudreach"))
	assert_true(remote.is_queued_for_deletion(), "durable original permits shell release")
	remote.free()
	crossing.session = null
	crossing.free()
	SAVE.new()._close(game, rpc, directory)

func test_first_noncombat_resource_stage_initializes_same_real_arbiter() -> void:
	var fixture := DATA.new()
	var game := SAVE.FixtureGame.new()
	game.local = fixture._player()
	game.world = fixture._world()
	var session := ShellSession.new()
	session.fixture = game
	game.session = session
	var shells := DetachedShells.new()
	session.set("_realms", shells)
	session.add_child(shells)
	var remote := Node3D.new()
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	remote.add_child(director)
	director.set("_session", session)
	shells.set("_shells", {"cloudreach": remote})
	assert_eq(director.get("_encounter_host"), null)
	var before := RECORD.portable_projection(game.local.save_data())
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	var token := authority.stage_character_action(DATA.CHARACTER, 0, "resource", fixture._intent(), fixture._context())
	var delivery := DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch",
		authority.staged_creature_training(token), null, RECORD.errors)
	var checked := session._training_actor_baseline_proposals(2, delivery)
	assert_true(checked.get("ok") == true, str(checked))
	var host: RefCounted = director.get("_encounter_host")
	assert_true(host != null)
	if host != null:
		assert_true(host.encounters.is_empty(), "baseline admission did not fabricate a fight")
		assert_true(session._training_actor_baseline_proposals(2, delivery).ok)
		assert_eq(director.get("_encounter_host"), host, "repeat admission reuses the sole arbiter")
	shells.set("_shells", {})
	remote.free()
	session.free()
	game.free()


## Passive care the owner accrues between the host's stage and the owner apply
## (walking bond, landmarks, nourishment) survives the install and its save;
## the row's own decided change still lands.
func test_passive_care_gained_between_stage_and_apply_is_kept() -> void:
	var fixture := DATA.new()
	var directory := "user://test_mastery_passive_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = fixture._player()
	game.world = fixture._world()
	var session := SAVE.FixtureSession.new()
	session.fixture = game
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := SAVE.FixtureRpc.new()
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(writer.save_world_prepared(game, "resource-slot"))
	var duty := _duty(before)
	var retained: Dictionary = rpc.journal_foundation_event("mastery:" + ACTION_ID, [duty])
	var event: Dictionary = game.world.reward_deliveries[retained.delivery_id]
	var token := authority.stage_character_action(DATA.CHARACTER, 0, "combat_mastery", duty.intent, _context(duty, event))
	var journal: Dictionary = rpc.journal_creature_training_prepared(1, DATA.CHARACTER, authority.staged_creature_training(token))
	assert_true(authority.finish_creature_training(token, journal.get("durable") == true))
	if journal.get("durable") != true:
		SAVE.new()._close(game, rpc, directory)
		return
	var row: Dictionary = game.world.reward_deliveries[journal.delivery_id]
	# The stage -> apply window: the owner keeps walking and getting hungry.
	var creature: RefCounted = game.local.party.at(0)
	var walked := float(creature.distance_m_together) + 37.5
	var landmarks := int(creature.landmarks_visited_together) + 2
	var fed := maxf(0.0, float(creature.nourishment) - 4.25)
	creature.distance_m_together = walked
	creature.landmarks_visited_together = landmarks
	creature.nourishment = fed
	var applied := OWNER.apply_owner(game, row)
	assert_true(applied.get("ok") == true and applied.get("saved") == true, "the row installs and saves over passive drift " + str(applied))
	var move: String = before.party[0].move_quick
	assert_eq(int(game.local.party.at(0).move_mastery_uses.get(move, 0)), 1, "the row's decided change landed")
	assert_eq(float(game.local.party.at(0).distance_m_together), walked, "walking bond is not rolled back")
	assert_eq(int(game.local.party.at(0).landmarks_visited_together), landmarks, "landmarks are not rolled back")
	assert_eq(float(game.local.party.at(0).nourishment), fed, "nourishment is not rolled back")
	var saved: Dictionary = writer.character_store.call("read", DATA.CHARACTER)
	assert_eq(float(saved.party[0].distance_m_together), walked, "the saved owner keeps it too")
	assert_true(E.owner_matches_after(RECORD.portable_projection(saved), row.after), "and is otherwise exactly the row")
	SAVE.new()._close(game, rpc, directory)
