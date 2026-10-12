extends "res://tests/test_case.gd"

## Real admitted-character staging, retained-event codec and disk writers.
## Host hit geometry and live actor-baseline admission are disclosed fixtures.
const RUNS_IN_INITIALIZED_TREE := true
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


## P0 (coordinator, 12 Oct): a long campaign's mastery duties must settle and
## retire, not pile up in world.reward_deliveries (save growth, per-frame
## retry walk). 60 landed hits, each through the real journal, stage, owner
## apply and host accept: no mastery event or settlement entry remains, and
## every landed use is on the card.
func test_sixty_landed_hits_settle_and_retire_every_mastery_event() -> void:
	var fixture := DATA.new()
	var directory := "user://test_mastery_drain_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
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
	var move: String = before.party[0].move_quick
	var landed := 0
	for i in 60:
		var duty := _duty(before)
		var action_id := "mastery-drain-%d" % i
		duty.intent.action_id = action_id
		duty.context.source_key = "combat_mastery:" + action_id
		duty.context.outcome.action_id = action_id
		var retained: Dictionary = rpc.journal_foundation_event("mastery:" + action_id, [duty])
		assert_true(retained.get("durable") == true, "hit %d journal %s" % [i, str(retained)])
		if not (retained.get("durable") == true): break
		var event: Dictionary = game.world.reward_deliveries[retained.delivery_id]
		var context := _context(duty, event)
		context.expected_revision = int(authority.revision(DATA.CHARACTER))
		var token := authority.stage_character_action(DATA.CHARACTER, context.expected_revision, "combat_mastery", duty.intent, context)
		assert_true(token.get("ok") == true, "hit %d stage %s" % [i, str(token)])
		if not (token.get("ok") == true): break
		var journal: Dictionary = rpc.journal_creature_training_prepared(1, DATA.CHARACTER, authority.staged_creature_training(token))
		assert_true(authority.finish_creature_training(token, journal.get("durable") == true))
		assert_true(journal.get("durable") == true, "hit %d training %s" % [i, str(journal)])
		if not (journal.get("durable") == true): break
		var row: Dictionary = game.world.reward_deliveries[journal.delivery_id]
		var applied: Dictionary = OWNER.apply_owner(game, row)
		assert_true(applied.get("saved") == true, "hit %d owner apply %s" % [i, str(applied)])
		var accept: Dictionary = rpc.ledger.accept_creature_training_delivery(row.delivery_id, DATA.CHARACTER,
			int(row.journal_revision), str(row.receipt), 1)
		assert_true(accept.get("ok") == true, "hit %d accept %s" % [i, str(accept)])
		if not (accept.get("ok") == true): break
		assert_false(game.world.reward_deliveries.has(retained.delivery_id), "hit %d: its mastery event retired on accept" % i)
		# The host's own acknowledgement (session.host_ack_creature_training).
		assert_true(authority.acknowledge_creature_training(DATA.CHARACTER, game.world.reward_deliveries[row.delivery_id]) == true, "hit %d ack" % i)
		# ...and the owner's settle, which lifts its input fence (ledger_rpc._process_creature_training).
		assert_true(session._settle_owner_training_accepted(game.local, game.world, game.world.reward_deliveries[row.delivery_id]) == true, "hit %d owner settle" % i)
		landed += 1
	var leftover := 0
	for id: String in game.world.reward_deliveries:
		if id.begins_with("foundation_event:"): leftover += 1
	assert_eq(leftover, 0, "no retained mastery event outlives its accepted decision")
	assert_true((game.world.redesign_world.get("retained_settlement", {}) as Dictionary).is_empty(), "retired events leave no settlement entry")
	assert_eq(landed, 60)
	assert_eq(int(game.local.party.at(0).move_mastery_uses.get(move, 0)), mini(60, _use_cap(move)), "every landed use is kept")
	SAVE.new()._close(game, rpc, directory)


func _use_cap(_move: String) -> int:
	return 1 << 30


## P0 batch (12 Oct): the host's own queued mastery duties drain in one scan
## with deferred writes. The result must equal the one-by-one drain exactly.
class DeferringWriter extends SAVE.BoolWriter:
	# Mirrors save_game.gd's owed scopes: inside a step writes are owed; the
	# flush (or any outside world write) lands characters before the world.
	var deferring := false
	var owed_world := false
	var owed_owner := false
	var world_writes := 0
	var owner_writes := 0
	var order: Array = []
	var game_ref: Node
	func begin_deferred_writes() -> bool:
		deferring = true
		return true
	func end_deferred_scope() -> void:
		deferring = false
	func deferring_writes() -> bool:
		return deferring or owed_world or owed_owner
	func flush_deferred_writes() -> bool:
		deferring = false
		if owed_owner and not save_character_prepared(game_ref, DATA.CHARACTER): return false
		if owed_world and not save_world_prepared(game_ref, "resource-slot"): return false
		return true
	func save_world_prepared(game: Node, id: String) -> bool:
		if deferring:
			owed_world = true
			return true
		if owed_owner and not save_character_prepared(game, DATA.CHARACTER): return false
		var ok := super.save_world_prepared(game, id)
		if ok:
			owed_world = false
			world_writes += 1
			order.append("world")
		return ok
	func save_character_prepared(game: Node, id: String) -> bool:
		if deferring:
			owed_owner = true
			return true
		var ok := super.save_character_prepared(game, id)
		if ok:
			owed_owner = false
			owner_writes += 1
			order.append("owner")
		return ok

class ScanSession extends SAVE.FixtureSession:
	var batch_max := 64
	var budget_ms := 600000
	var min_hits := 8
	var frame_budget_ms := 600000
	var flush_idle_s := 1000000.0
	var flush_cap_hits := 1000000
	var rebase_frames := 20
	var fence_frames := 600
	func _cfg(key: String, fallback: Variant) -> Variant:
		if key == "training_conflict_rebase_frames": return rebase_frames
		if key == "training_fence_watchdog_frames": return fence_frames
		if key == "foundation_mastery_batch_max": return batch_max
		if key == "foundation_mastery_batch_budget_ms": return budget_ms
		if key == "foundation_mastery_batch_min_hits": return min_hits
		if key == "foundation_mastery_frame_budget_ms": return frame_budget_ms
		if key == "foundation_mastery_flush_idle_s": return flush_idle_s
		if key == "foundation_mastery_flush_cap_hits": return flush_cap_hits
		if key == "foundation_mastery_flush_cap_s": return 1000000.0
		return super._cfg(key, fallback)
	func _altar_peer_in_combat(_peer: int) -> bool: return false
	func _retry_combat_mastery_sources() -> void: pass
	# Disclosed fixture, as FixtureSession.training_actor_baseline_ready: no
	# live encounter actors, so no actor baselines to commit with the ACK.
	func _training_actor_baseline_proposals(_peer: int, _row: Dictionary) -> Dictionary: return {"ok": true, "proposals": []}

class ScanRpc extends SAVE.FixtureRpc:
	var sent: Array = []
	func _registered_character(peer: int) -> String: return DATA.CHARACTER if peer == 1 else ""
	func _send_remote_delta(delta: Dictionary) -> void: sent.append(delta)

var _frames := 0
func _scan_and_pump(session: Node) -> void:
	session._retry_foundation_events()
	_frames += 1
	for step in 10000:
		if (session.get("_mastery_job") as Dictionary).is_empty(): break
		session._advance_mastery_job(int(session.get("frame_budget_ms")))
		session._tick_mastery_owed()
		_frames += 1
	# A natural pause (menu, rest, transition) lands what is still owed.
	session.flush_mastery_owed("pause")

func _drain_fixture(batch_max: int, hits: int, bad_hit: int = -1, refuse_first_flush := false, decided: Array = [], budget_ms := 600000, min_hits := 8, frame_budget_ms := 600000) -> Dictionary:
	var fixture := DATA.new()
	var directory := "user://test_mastery_batch_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = fixture._player()
	game.world = fixture._world()
	var session := ScanSession.new()
	session.batch_max = batch_max
	session.budget_ms = budget_ms
	session.min_hits = min_hits
	session.frame_budget_ms = frame_budget_ms
	session.fixture = game
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	var writer := DeferringWriter.new()
	writer.game_ref = game
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := ScanRpc.new()
	rpc.fixture = game
	rpc.name = "LedgerRpc"
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	session.add_child(rpc)
	session.get("_registry").call("add", 1, DATA.CHARACTER)
	for i: int in decided:
		# The crash window: a batch's character write landed, its world write
		# did not. The character already holds these hits' receipts and uses.
		var held_receipt := "craft:combat_mastery_%s:%s" % [("mastery-batch-%d" % i).sha256_text(), DATA.CHARACTER]
		game.local.redesign_character.transaction_receipts.append(held_receipt)
	var before := RECORD.portable_projection(game.local.save_data())
	authority.bind_world("resource-namespace")
	authority.seed_admitted_character(before, DATA.CHARACTER)
	writer.save_world_prepared(game, "resource-slot")
	writer.save_character_prepared(game, DATA.CHARACTER)
	for i in hits:
		var duty := _duty(before)
		var action_id := "mastery-batch-%d" % i
		duty.intent.action_id = action_id
		duty.context.source_key = "combat_mastery:" + action_id
		duty.context.outcome.action_id = action_id
		if i == bad_hit:
			# A hit by a creature this character no longer owns: refused (not_owned).
			duty.intent.creature_uid = "creature-not-owned"
			duty.context.outcome.attacker_uid = "creature-not-owned"
			duty.context.binding.creature_uid = "creature-not-owned"
		var journaled: Dictionary = rpc.journal_foundation_event("mastery:" + action_id, [duty])
		assert_true(journaled.get("durable") == true, "hit %d journals" % i)
	_frames = 0
	writer.world_writes = 0
	writer.owner_writes = 0
	writer.order.clear()
	var scans := 0
	var flush_retry := {}
	if refuse_first_flush:
		writer.refuse_owner = true
		_scan_and_pump(session)
		scans += 1
		var held := 0
		for id: String in game.world.reward_deliveries:
			if id.begins_with("foundation_event:"): held += 1
		flush_retry = {"unflushed": not (session.get("_mastery_owed") as Dictionary).is_empty(), "events_in_memory": held,
			"owner_writes": writer.owner_writes, "world_writes": writer.world_writes}
		_scan_and_pump(session) # Still refused: nothing else runs.
		scans += 1
		flush_retry["second_scan_owner_writes"] = writer.owner_writes
		writer.refuse_owner = false
		_scan_and_pump(session) # The next frames retry the owed writes.
		scans += 1
	while scans < hits * 4:
		var left := 0
		for id: String in game.world.reward_deliveries:
			if id.begins_with("foundation_event:"): left += 1
		if left == 0: break
		_scan_and_pump(session)
		scans += 1
	var receipts: Array = (game.local.redesign_character.transaction_receipts as Array).filter(func(r: String) -> bool: return r.begins_with("craft:combat_mastery_"))
	receipts.sort()
	var events := 0
	var half_applied := 0
	var held_receipts: Array = game.local.redesign_character.transaction_receipts
	for i in hits:
		var receipt := "craft:combat_mastery_%s:%s" % [("mastery-batch-%d" % i).sha256_text(), DATA.CHARACTER]
		var retired := true
		for id: String in game.world.reward_deliveries:
			var row: Dictionary = game.world.reward_deliveries[id]
			if id.begins_with("foundation_event:") and str(row.duties[0].intent.action_id) == "mastery-batch-%d" % i: retired = false
		if retired != held_receipts.has(receipt): half_applied += 1
	for id: String in game.world.reward_deliveries:
		if id.begins_with("foundation_event:"): events += 1
	var on_disk: Dictionary = writer.character_store.call("read", DATA.CHARACTER)
	var out := {"frames": _frames, "half_applied": half_applied, "flush_retry": flush_retry,
		"disk_receipts": (on_disk.get("redesign_character", on_disk.get("payload", {}).get("redesign_character", {})).get("transaction_receipts", []) as Array).size(),"uses": (game.local.party.at(0).move_mastery_uses as Dictionary).duplicate(true), "receipts": receipts,
		"events": events, "scans": scans, "world_writes": writer.world_writes, "owner_writes": writer.owner_writes,
		"order": writer.order.duplicate()}
	rpc.free()
	session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)
	return out

func test_a_refused_hit_stops_the_batch_exactly_where_one_by_one_stops() -> void:
	var single := _drain_fixture(1, 60, 30)
	var batched := _drain_fixture(64, 60, 30)
	assert_eq(batched.uses, single.uses, "identical uses up to the refused hit")
	assert_eq(batched.receipts, single.receipts, "identical receipts")
	assert_eq((batched.receipts as Array).size(), 30, "hits 0..29 applied")
	assert_eq(batched.events, single.events, "the same events still owed")
	assert_eq(batched.events, 30, "the refused hit and everything after it remain owed, untouched")
	assert_eq(batched.half_applied, 0, "every hit is either fully applied (receipt held, event retired) or untouched")
	assert_eq(single.half_applied, 0)

func test_hits_the_character_already_holds_settle_by_receipt_and_the_rest_drain() -> void:
	for batch_max: int in [1, 64]:
		var out := _drain_fixture(batch_max, 12, -1, false, [0, 1, 2, 3, 4])
		assert_eq(out.events, 0, "batch %d: decided hits settle by receipt and retire; the rest drain (%s)" % [batch_max, str(out)])
		assert_eq((out.receipts as Array).size(), 12, "batch %d: each hit's receipt once" % batch_max)
		assert_eq(out.half_applied, 0)
		assert_eq(int(out.uses.values()[0]) if not (out.uses as Dictionary).is_empty() else 0, 7, "batch %d: only the 7 undecided hits add a use" % batch_max)




func test_sixty_hits_by_job_equal_one_by_one_and_land_once_at_the_pause() -> void:
	var single := _drain_fixture(1, 60)
	var job := _drain_fixture(64, 60)
	assert_eq(single.events, 0, "one-by-one drains every event: %s" % str(single))
	assert_eq(job.events, 0, "the job drains every event: %s" % str(job))
	assert_eq(job.uses, single.uses, "identical mastery uses")
	assert_eq(job.receipts, single.receipts, "identical per-hit receipts")
	assert_eq((job.receipts as Array).size(), 60)
	assert_eq(int(job.owner_writes), 1, "one owed character write, at the pause")
	assert_eq(int(job.world_writes), 1, "one owed world write, at the pause")
	assert_eq(job.order, ["owner", "world"], "the character lands before the world")
	assert_eq(job.half_applied, 0)

func test_a_refused_flush_waits_with_the_job_intact_and_retries_character_before_world() -> void:
	var out := _drain_fixture(64, 20, -1, true, [], 600000, 64)
	var retry: Dictionary = out.flush_retry
	assert_true(retry.get("unflushed") == true, "a refused write leaves the job waiting in its flush")
	assert_eq(int(retry.get("events_in_memory", -1)), 0, "the in-memory job is intact (every event retired in memory)")
	assert_eq(int(retry.get("world_writes", -1)), 0, "no world write ahead of the character")
	assert_eq(int(retry.get("second_scan_owner_writes", -1)), int(retry.get("owner_writes", -2)), "nothing else lands while the flush is owed")
	assert_eq(out.events, 0)
	assert_eq((out.receipts as Array).size(), 20)
	assert_eq(out.half_applied, 0)
	assert_eq(out.order, ["owner", "world"], "the retried flush still lands the character before the world")

func test_a_zero_frame_budget_runs_one_whole_hit_per_frame_with_the_same_result() -> void:
	var single := _drain_fixture(1, 12)
	var spread := _drain_fixture(64, 12, -1, false, [], 600000, 8, 0)
	assert_eq(spread.events, 0, str(spread))
	assert_eq(spread.uses, single.uses)
	assert_eq(spread.receipts, single.receipts)
	assert_true(int(spread.frames) >= 12, "one whole hit per frame (%d frames)" % int(spread.frames))
	assert_eq(spread.half_applied, 0)


## OWED-WRITE SCOPE (coordinator decision (c), session.gd): the job's writes
## and deltas stay owed until a natural pause, never during a live fight.
class FakeFight extends Node:
	var fighting := true
	func is_fighting() -> bool: return fighting

func _owed_fixture(hits: int, cap_hits := 1000000, run_job := true) -> Dictionary:
	var fixture := DATA.new()
	var directory := "user://test_mastery_owed_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := SAVE.FixtureGame.new()
	game.local = fixture._player()
	game.world = fixture._world()
	var session := ScanSession.new()
	session.flush_cap_hits = cap_hits
	session.fixture = game
	game.session = session
	var authority := AUTHORITY.new()
	session.set("_character_authority", authority)
	var writer := DeferringWriter.new()
	writer.game_ref = game
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := ScanRpc.new()
	rpc.fixture = game
	rpc.name = "LedgerRpc"
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	session.add_child(rpc)
	(Engine.get_main_loop() as SceneTree).root.add_child(session)
	session.get("_registry").call("add", 1, DATA.CHARACTER)
	var before := RECORD.portable_projection(game.local.save_data())
	authority.bind_world("resource-namespace")
	authority.seed_admitted_character(before, DATA.CHARACTER)
	writer.save_world_prepared(game, "resource-slot")
	writer.save_character_prepared(game, DATA.CHARACTER)
	for i in hits:
		var duty := _duty(before)
		var action_id := "mastery-owed-%d" % i
		duty.intent.action_id = action_id
		duty.context.source_key = "combat_mastery:" + action_id
		duty.context.outcome.action_id = action_id
		rpc.journal_foundation_event("mastery:" + action_id, [duty])
	writer.world_writes = 0
	writer.owner_writes = 0
	writer.order.clear()
	rpc.sent.clear()
	var fight := FakeFight.new()
	fight.add_to_group(&"foundation_combat_managers")
	session.add_child(fight)
	fight.fighting = false
	if run_job:
		session._retry_foundation_events()
		for step in 1000:
			if (session.get("_mastery_job") as Dictionary).is_empty(): break
			session._advance_mastery_job(600000)
	return {"game": game, "session": session, "writer": writer, "rpc": rpc, "fight": fight, "directory": directory}

func _close_owed(f: Dictionary) -> void:
	f.session.get_parent().remove_child(f.session)
	f.session.free()
	f.game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(f.directory)

func test_no_flush_during_a_live_fight_then_it_lands_at_resolve() -> void:
	var f := _owed_fixture(6)
	assert_false((f.session.get("_mastery_owed") as Dictionary).is_empty(), "six hits are owed")
	f.fight.fighting = true
	for frame in 30: f.session._tick_mastery_owed()
	assert_eq(int(f.writer.owner_writes) + int(f.writer.world_writes), 0, "no owed write lands during a live fight")
	assert_true(int(f.rpc.held_publication_count()) > 0, "the job's deltas stay held")
	f.fight.fighting = false
	f.session._tick_mastery_owed()
	assert_eq(f.writer.order, ["owner", "world"], "the frame the fight resolves lands character, then world")
	assert_true((f.session.get("_mastery_owed") as Dictionary).is_empty())
	_close_owed(f)

func test_the_cap_forces_a_flush_on_the_next_fight_free_frame() -> void:
	var f := _owed_fixture(6, 4)
	f.fight.fighting = true
	f.session._tick_mastery_owed()
	assert_eq(int(f.writer.owner_writes), 0, "even over the cap, never during a fight")
	f.session.set("_mastery_was_fighting", false) # Not a resolve: only the cap applies.
	f.fight.fighting = false
	f.session.set("_mastery_last_combat_ms", Time.get_ticks_msec())
	f.session.set("_mastery_was_fighting", false)
	f.session._tick_mastery_owed()
	assert_eq(f.writer.order, ["owner", "world"], "six owed hits over a cap of four flush at once")
	_close_owed(f)

func test_a_save_mid_fight_lands_owed_characters_first_and_releases_the_deltas() -> void:
	var f := _owed_fixture(5)
	f.fight.fighting = true
	f.session._tick_mastery_owed()
	assert_eq(int(f.writer.owner_writes), 0)
	assert_true(f.writer.save_world_prepared(f.game, "resource-slot"), "an ordinary save mid-fight")
	assert_eq(f.writer.order, ["owner", "world"], "the owed character lands before that world write")
	f.session._tick_mastery_owed()
	assert_true((f.session.get("_mastery_owed") as Dictionary).is_empty(), "the landed writes release the owed state")
	assert_eq(int(f.rpc.held_publication_count()), 0, "held deltas go out once durable")
	_close_owed(f)

func test_coop_peers_receive_the_jobs_deltas_only_after_the_flush() -> void:
	var f := _owed_fixture(4)
	f.fight.fighting = true
	f.session._tick_mastery_owed()
	assert_eq((f.rpc.sent as Array).size(), 0, "no job delta reaches a peer before the owed writes land")
	var held: int = f.rpc.held_publication_count()
	assert_true(held >= 4 * 2, "the journal and accept deltas of four hits are held (%d)" % held)
	f.fight.fighting = false
	f.session._tick_mastery_owed()
	assert_eq((f.rpc.sent as Array).size(), held, "every held delta is sent, in order, after the flush")
	assert_eq(f.writer.order, ["owner", "world"])
	_close_owed(f)

func test_idle_never_flushes_a_running_job_once_per_hit() -> void:
	var f := _owed_fixture(0)
	f.session.flush_idle_s = 0.0 # Idle is due on every frame.
	var job_owed_before: int = int(f.writer.owner_writes)
	# Re-run with a fresh queue, ticking between every protocol step.
	var game: Node = f.game
	var before := RECORD.portable_projection(game.local.save_data())
	for i in 10:
		var duty := _duty(before)
		var action_id := "mastery-idle-%d" % i
		duty.intent.action_id = action_id
		duty.context.source_key = "combat_mastery:" + action_id
		duty.context.outcome.action_id = action_id
		f.rpc.journal_foundation_event("mastery:" + action_id, [duty])
	f.writer.owner_writes = 0
	f.writer.world_writes = 0
	f.writer.order.clear()
	f.session._retry_foundation_events()
	for step in 1000:
		if (f.session.get("_mastery_job") as Dictionary).is_empty(): break
		f.session._advance_mastery_job(0)
		f.session._tick_mastery_owed()
	assert_eq(int(f.writer.owner_writes), 0, "no idle flush while the job runs")
	f.session._tick_mastery_owed()
	assert_eq(f.writer.order, ["owner", "world"], "one idle flush once the job has finished")
	_close_owed(f)


## routes-east (still_grove bed): between commit and accept a hit's training
## row is pending, which makes Session an input owner. A hit must never leave
## that fence up across a frame, or the player's presses are dropped.
func test_the_job_never_leaves_the_input_fence_up_between_frames() -> void:
	var f := _owed_fixture(10, 1000000, false)
	f.session.frame_budget_ms = 0
	f.session._retry_foundation_events()
	var frames := 0
	while not (f.session.get("_mastery_job") as Dictionary).is_empty() and frames < 200:
		assert_false(f.session.owns_input(), "frame %d: no owner-mutation fence between frames" % frames)
		f.session._advance_mastery_job(0)
		frames += 1
	assert_false(f.session.owns_input(), "the fence is down once the job ends")
	assert_true(frames >= 9, "the job spread over frames (%d)" % frames)
	_close_owed(f)

## routes-east r19: the player changed the character between job frames
## (bedded a creature); a hit staged on the stale record was refused by the
## owner apply (baseline conflict) and held the input fence forever. Each hit
## now re-admits the live character first.
func test_a_character_change_between_job_frames_never_conflicts_or_holds_the_fence() -> void:
	var f := _owed_fixture(8, 1000000, false)
	f.session.frame_budget_ms = 0
	f.session._retry_foundation_events()
	var frames := 0
	while not (f.session.get("_mastery_job") as Dictionary).is_empty() and frames < 100:
		f.game.local.inventory.add("essence_ground", 1) # An ordinary owner change between frames.
		f.session._advance_mastery_job(0)
		frames += 1
	var left := 0
	for id: String in f.game.world.reward_deliveries:
		if id.begins_with("foundation_event:"): left += 1
	assert_eq(left, 0, "every hit lands despite the owner changing the character between frames")
	assert_false(f.session.owns_input(), "no refused owner apply leaves the input fence up")
	assert_true(frames >= 7, "the drain spanned frames (%d)" % frames)
	_close_owed(f)

## routes-east r19, one-by-one path: the owner beds a creature between a
## hit's commit and its deferred owner apply. The delivery must complete with
## the bed kept, and the input fence must drop.
func test_bedding_a_creature_mid_delivery_completes_and_frees_input() -> void:
	var f := _owed_fixture(1, 1000000, false)
	f.session.batch_max = 1 # The ordinary one-by-one scan path.
	f.session._retry_foundation_events()
	var id := E.training_delivery_id(f.game.world.reward_delivery_namespace, DATA.CHARACTER)
	var row: Dictionary = f.game.world.reward_deliveries.get(id, {})
	assert_eq(row.get("status"), "pending", "the hit is journaled and awaits its owner apply")
	var creature: RefCounted = f.game.local.party.at(0)
	creature.set("resting", true) # The camp bed, by ordinary input.
	creature.set("rest_bed_index", -34)
	assert_true(f.session.owns_input(), "the fence is up while the row is pending")
	f.rpc._process_creature_training(row.duplicate(true)) # The deferred owner apply.
	var settled: Dictionary = f.game.world.reward_deliveries.get(id, {})
	assert_eq(settled.get("status"), "accepted", "the delivery completes despite the bedding")
	assert_false(f.session.owns_input(), "input is free afterwards")
	assert_true(bool(creature.get("resting")) and int(creature.get("rest_bed_index")) == -34, "the owner's bed is kept")
	_close_owed(f)


## An unfenced owner write (a legacy XP award) on a path the row does not own
## after the stage: the owner record no longer matches the row's baseline.
func _conflicted_one_by_one() -> Dictionary:
	var f := _owed_fixture(1, 1000000, false)
	f.session.batch_max = 1
	f.session._retry_foundation_events()
	f.id = E.training_delivery_id(f.game.world.reward_delivery_namespace, DATA.CHARACTER)
	f.row = (f.game.world.reward_deliveries.get(f.id, {}) as Dictionary).duplicate(true)
	assert_eq(f.row.get("status"), "pending", "the hit is journaled and awaits its owner apply")
	var creature: RefCounted = f.game.local.party.at(0)
	creature.set("xp", int(creature.get("xp")) + 7)
	return f


func test_injected_baseline_conflict_rebases_and_frees_input() -> void:
	var f := _conflicted_one_by_one()
	f.session.rebase_frames = 1000000
	f.rpc._process_creature_training(f.row.duplicate(true))
	assert_eq(f.game.world.reward_deliveries[f.id].status, "pending", "inside the grace the conflict waits (a transient may still settle)")
	assert_true(f.session.owns_input(), "the fence holds while it waits")
	f.session.rebase_frames = 0
	f.rpc._process_creature_training(f.row.duplicate(true))
	assert_eq(f.game.world.reward_deliveries[f.id].status, "accepted", "a lasting conflict installs the decided record and is accepted")
	assert_false(f.session.owns_input(), "input is free afterwards")
	var after_xp: int = int((f.row.after.party[0] as Dictionary).get("xp"))
	assert_eq(int(f.game.local.party.at(0).get("xp")), after_xp, "the authority's decided record wins; the lost path was logged")
	assert_true(E.owner_matches_after(RECORD.portable_projection(f.game.local.save_data()), f.row.after),
		"owner and authority agree, so the next row's baseline holds")
	_close_owed(f)


func test_fence_watchdog_resolves_a_stuck_row_loudly() -> void:
	var f := _conflicted_one_by_one()
	f.session.rebase_frames = 1000000 # The delivery path alone would keep waiting.
	f.session.fence_frames = 0
	f.rpc._process_creature_training(f.row.duplicate(true))
	assert_true(f.session.owns_input(), "the stuck row holds the fence")
	f.session._watch_training_fence() # Records the unchanged hold.
	assert_eq(f.session.fence_watchdog_fired, 0, "a hold is not stuck the first frame it is seen")
	f.session._watch_training_fence()
	assert_eq(f.session.fence_watchdog_fired, 1, "an unchanged hold past the period fires the watchdog")
	assert_eq(f.game.world.reward_deliveries[f.id].status, "accepted", "the watchdog resolves the row")
	assert_false(f.session.owns_input(), "input is free afterwards")
	f.session._watch_training_fence()
	assert_eq(f.session.fence_watchdog_fired, 1, "nothing fires once the fence is down")
	_close_owed(f)


func test_watchdog_leaves_a_row_the_job_is_driving() -> void:
	var f := _owed_fixture(3, 1000000, false)
	f.session.fence_frames = 0
	f.session.min_hits = 1
	f.session.frame_budget_ms = 0 # One whole hit per frame: the job outlives the scan.
	f.session._retry_foundation_events()
	assert_false(f.session._mastery_job.is_empty(), "the job has hits left after its first frame")
	# Whole hits per frame never leave a row pending between frames; stop the
	# job by hand between its commit and owner steps to model one mid-hit.
	while not f.session._mastery_job.is_empty() and str(f.session._mastery_job.phase) == "commit" and f.session._mastery_job_step(): pass
	var id := E.training_delivery_id(f.game.world.reward_delivery_namespace, DATA.CHARACTER)
	var row: Dictionary = f.game.world.reward_deliveries.get(id, {})
	assert_true(f.session.owns_input() and f.session.mastery_job_owns(row), "the job holds a pending row mid-hit")
	for i: int in 2: f.session._watch_training_fence()
	assert_eq(f.session.fence_watchdog_fired, 0, "a row the mastery job owns is being driven, not stuck")
	_close_owed(f)



func test_owner_local_card_writes_mid_delivery_are_kept_and_free_input() -> void:
	var f := _owed_fixture(1, 1000000, false)
	f.session.batch_max = 1
	f.session.rebase_frames = 1000000 # Only the owner-local merge may settle this; no forced rebase.
	f.session._retry_foundation_events()
	var id := E.training_delivery_id(f.game.world.reward_delivery_namespace, DATA.CHARACTER)
	var row: Dictionary = (f.game.world.reward_deliveries.get(id, {}) as Dictionary).duplicate(true)
	var creature: RefCounted = f.game.local.party.at(0)
	creature.set("nickname", "Pip") # Rename (party_seam).
	creature.set("swim_stamina_fraction", 0.25) # Swimming.
	f.rpc._process_creature_training(row)
	assert_eq(f.game.world.reward_deliveries[id].status, "accepted", "owner-local card writes never conflict with the row")
	assert_false(f.session.owns_input(), "input is free afterwards")
	assert_eq(str(creature.get("nickname")), "Pip", "the rename is kept")
	assert_eq(float(creature.get("swim_stamina_fraction")), 0.25, "swim stamina is kept")
	_close_owed(f)
