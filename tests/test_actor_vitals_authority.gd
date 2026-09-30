extends "res://tests/test_case.gd"

const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const ACTOR := preload("res://scripts/net/actor_vitals_delivery.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const CHARACTER := preload("res://scripts/save/character_save.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
const ENCOUNTER := preload("res://scripts/net/encounter_host.gd")
var _dir := ""

class OwnerWriter:
	extends RefCounted
	var store: RefCounted
	var refuse := false
	var writes := 0
	func save_character(game: Node, id: String) -> bool:
		writes += 1
		if refuse:
			return false # Simulate an actual bool-writer refusal, never equality.
		var saved: Dictionary = game.get("local").save_data()
		if not bool(game.get("session").call("_owner_vitals_snapshot_allowed", game.get("local"), saved)):
			return false
		saved.redesign_character = preload("res://scripts/creatures/teaching.gd").character_loadout_mirror(saved.party, saved.redesign_character)
		return bool(store.call("write", id, saved))
	func finish_fallback() -> void:
		pass
	func save_character_prepared(game: Node, id: String) -> bool:
		return save_character(game, id)
	func fallback_busy() -> bool:
		return false
	func save_world_prepared(_game: Node, _id: String) -> bool:
		writes += 1
		return not refuse

class OwnerGame:
	extends Node
	var local: RefCounted
	var world: RefCounted
	var save_system: RefCounted
	var session: Node = preload("res://scripts/net/session.gd").new()
	func is_host() -> bool:
		return true
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE and is_instance_valid(session):
			session.free()

class UnadmittedTransport:
	extends "res://scripts/net/ledger_rpc.gd"
	var fixture: Node
	func _game() -> Node:
		return fixture
	func _registered_character(_peer: int) -> String:
		return ""

class PreparedProbe:
	extends "res://scripts/save/save_game.gd"
	var writes := 0
	var finishes := 0
	var busy := false
	func fallback_busy() -> bool:
		return busy
	func finish_fallback() -> bool:
		finishes += 1
		busy = true # A completion listener has started a replacement fallback.
		return true
	func _write_world_snapshot(_game: Object, _world: String) -> bool:
		writes += 1
		return true
	func _write_character_snapshot(_game: Object, _character: String) -> bool:
		writes += 1
		return true

func before_each() -> void:
	_dir = "user://test_actor_vitals_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	DirAccess.make_dir_recursive_absolute(_dir)

func after_each() -> void:
	FIXTURE.wipe(_dir)

func _player() -> RefCounted:
	var player := PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = "owner_a"
	player.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	return player

func _portable(player: RefCounted) -> Dictionary:
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	return AUTHORITY.portable_projection(saved)

func _receipt(uid: String, ordinal: int) -> Dictionary:
	return {"receipt_id": "host_process:hit_%d" % ordinal, "encounter_id": "encounter_a",
		"creature_uid": uid, "body_generation": 1, "vitals_revision": ordinal}


func test_actual_personal_stat_carriers_admit_defaults_and_refuse_bad_identity_shapes() -> void:
	var player := _player()
	var portable := _portable(player)
	assert_true(AUTHORITY.equipment_errors(portable.equipment).is_empty())
	assert_true(AUTHORITY.heart_selection_errors(portable.realm_hearts).is_empty())
	assert_eq(portable.equipment.size(), 5, "actual PlayerEquipment supplies five empty slots")
	assert_eq(portable.realm_hearts.active_id, "", "fresh actual personal selection is inactive")
	assert_true(AUTHORITY.errors(portable, "owner_a").is_empty())
	var old: Dictionary = player.save_data()
	old.erase("equipment")
	old.erase("realm_hearts")
	var restored := PLAYER.new()
	restored.configure(ITEMS.new())
	restored.load_data(old)
	assert_true(AUTHORITY.errors(_portable(restored), "owner_a").is_empty(), "old28 missing saved carriers use actual PlayerState defaults")
	player.inventory.add("travel_pack", 1)
	assert_true(player.equipment.equip_from_inventory("travel_pack", player.inventory))
	portable = _portable(player)
	assert_eq(portable.equipment.backpack, "travel_pack")
	assert_true(AUTHORITY.errors(portable, "owner_a").is_empty(), "actual owned armor ID uses the authored backpack slot")
	var invalid := portable.duplicate(true)
	invalid.erase("equipment")
	assert_false(AUTHORITY.errors(invalid, "owner_a").is_empty(), "missing received carrier is not a legacy saved default")
	for id: Variant in ["potion_small", "hide_helm", "unknown_pack", 3]:
		invalid = portable.duplicate(true)
		invalid.equipment.backpack = id
		assert_false(AUTHORITY.errors(invalid, "owner_a").is_empty(), "refuse wrong kind/slot/unknown/non-string equipment")
	invalid = portable.duplicate(true)
	invalid.equipment.erase("helmet")
	invalid.equipment["weapon"] = ""
	assert_false(AUTHORITY.errors(invalid, "owner_a").is_empty(), "same-size foreign slot cannot replace a real slot")
	for selection: Variant in [{}, {"active_id": 4}, {"active_id": "biome5"}, {"active_id": "", "power": 9}]:
		invalid = portable.duplicate(true)
		invalid.realm_hearts = selection
		assert_false(AUTHORITY.errors(invalid, "owner_a").is_empty(), "selection carries no client power or reserved ID")
	invalid = portable.duplicate(true)
	invalid["defence"] = 99999
	assert_false(AUTHORITY.errors(invalid, "owner_a").is_empty(), "client-derived stat totals never enter the portable authority shape")


func test_same_admission_retains_personal_sources_but_exposes_only_proved_actor_power() -> void:
	var player := _player()
	player.inventory.add("travel_pack", 1)
	assert_true(player.equipment.equip_from_inventory("travel_pack", player.inventory))
	# Typed storage fixture, not an earned relic: legacy selection cannot power
	# the actor even when the portable array claims that relic is hung.
	player.hearts.load_data({"active_id": "water"})
	player.redesign_character.relics_hung = ["tidewake"]
	var portable := _portable(player)
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("namespace_a"))
	assert_true(authority.seed_admitted_character(portable, "owner_a").ok)
	var original := authority.state("owner_a")
	var actor := authority.actor_stat_state("owner_a")
	assert_eq(actor.equipment.backpack, "travel_pack")
	assert_eq(actor.realm_hearts.active_id, "")
	assert_true(actor.redesign_character.relics_hung.is_empty())
	assert_eq(original.realm_hearts.active_id, "water", "actual portable legacy choice is retained")
	assert_eq(original.redesign_character.relics_hung, ["tidewake"], "typed storage is not rewritten")
	actor.equipment.backpack = ""
	actor.party[0].uid = "foreign_actor"
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), original), "detached read cannot mutate the admitted party or worn IDs")
	assert_true(authority.actor_stat_state("foreign_owner").is_empty())
	var fresh_rejoin := _portable(_player())
	assert_true(authority.seed_admitted_character(fresh_rejoin, "owner_a").already_seeded)
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), original), "new peer/roster/gear cannot replace stable admitted identity")
	player.inventory.add("hide_helm", 1)
	assert_true(player.equipment.equip_from_inventory("hide_helm", player.inventory))
	assert_true(authority.refresh_host_local(_portable(player), "owner_a").ok)
	assert_eq(authority.state("owner_a").equipment.helmet, "", "a later local save read is not an equipped-gear authority CAS")
	assert_eq(authority.state("owner_a").equipment.backpack, "travel_pack")
	assert_eq(player.save_data().realm_hearts.active_id, "water", "inactive combat view never edits the portable source")

func _row(portable: Dictionary, ordinal: int, hp: float, previous: Variant = null) -> Dictionary:
	var owned: Dictionary = portable.party[0]
	return ACTOR.next_record("world_a", "namespace_a", "session_a", "owner_a", owned.uid,
		float(owned.max_hp), float(owned.hp), bool(owned.fainted), hp, hp == 0.0,
		ordinal, _receipt(owned.uid, ordinal), previous)

func test_private_stage_world_failure_restores_hp_revision_and_replay_history() -> void:
	var portable := _portable(_player())
	var owned: Dictionary = portable.party[0]
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("namespace_a"))
	assert_true(authority.seed_admitted_character(portable, "owner_a").ok)
	var before := authority.state("owner_a")
	var stage := authority.stage_creature_vitals("owner_a", owned.uid, 0,
		float(owned.hp), false, float(owned.hp) - 10.0, false, _receipt(owned.uid, 1))
	assert_true(stage.ok)
	assert_false(authority.stage_creature_vitals("owner_a", owned.uid, 1,
		float(owned.hp) - 10.0, false, 1.0, false, _receipt(owned.uid, 2)).ok)
	assert_false(authority.stage_portal_debit("owner_a", "tidewake", "foreign").ok)
	assert_false(authority.commit_creature_mastery("owner_a", owned.uid, 1, {}, {}, {}, {}).ok)
	var tampered := stage.duplicate(true)
	tampered.accepted.hp = 1.0
	assert_eq(authority.staged_creature_vitals(tampered).hp, float(owned.hp) - 10.0)
	assert_true(authority.finish_creature_vitals(stage, false))
	assert_eq(authority.revision("owner_a"), 0)
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), before))
	assert_true(authority.pending_creature_vitals("owner_a").is_empty())
	stage = authority.stage_creature_vitals("owner_a", owned.uid, 0,
		float(owned.hp), false, float(owned.hp) - 10.0, false, _receipt(owned.uid, 1))
	assert_false(bool(stage.get("duplicate", false)), "failed world save cannot become a saved replay")
	assert_true(authority.finish_creature_vitals(stage, true))
	assert_false(authority.finish_creature_vitals(stage, false), "retired stage cannot refund accepted HP")
	assert_true(authority.commit_creature_vitals("owner_a", owned.uid, 0,
		float(owned.hp), false, float(owned.hp) - 10.0, false, _receipt(owned.uid, 1)).durable)

func test_lost_ack_cumulative_recovery_and_latest_ack_reject_foreign_healthy_reseed() -> void:
	var portable := _portable(_player())
	var owned: Dictionary = portable.party[0]
	var first := _row(portable, 1, float(owned.hp) - 10.0)
	var second := _row(portable, 2, float(owned.hp) - 20.0, first)
	assert_eq(second.expected_hp, owned.hp, "earliest unsettled baseline survives a missed ACK")
	var intermediate := first.duplicate(true)
	intermediate.status = "settled"
	var partially_saved := portable.duplicate(true)
	partially_saved.party[0].hp = first.hp
	partially_saved.vitals_escrow[first.delivery_id] = intermediate
	assert_true(ACTOR.personal_baseline_matches(partially_saved.party[0], second, intermediate))
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("namespace_a"))
	assert_true(authority.seed_admitted_character(partially_saved, "owner_a").ok)
	assert_true(authority.recover_durable_vitals("owner_a", {second.delivery_id: second}).ok)
	assert_eq(authority.state("owner_a").party[0].hp, second.hp)
	assert_eq(authority.revision("owner_a"), 2, "restart retains durable revision high-water")
	assert_true(authority.seed_admitted_character(portable, "owner_a").already_seeded)
	assert_eq(authority.state("owner_a").party[0].hp, second.hp, "fresh rejoin cannot heal retained authority")
	assert_false(authority.acknowledge_creature_vitals("owner_a", owned.uid, 1, first.receipt))
	assert_true(authority.acknowledge_creature_vitals("owner_a", owned.uid, 2, second.receipt))
	var before := authority.state("owner_a")
	var foreign := second.duplicate(true)
	foreign.world_namespace = "foreign_world"
	foreign.delivery_id = ACTOR.delivery_id("foreign_world", "owner_a", owned.uid)
	assert_false(authority.recover_durable_vitals("owner_a", {foreign.delivery_id: foreign}).ok)
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), before))
	var old_projection := portable.duplicate(true)
	old_projection.erase("vitals_escrow")
	var old_authority := AUTHORITY.new()
	assert_true(old_authority.bind_world("namespace_a"))
	assert_true(old_authority.seed_admitted_character(old_projection, "owner_a").ok)
	assert_true(old_authority.state("owner_a").vitals_escrow.is_empty(), "old28 projection defaults without resetting fields")
	var empty_ack := {"op": "actor_vitals_accept", "scope": "world", "delivery_id": second.delivery_id,
		"character_id": "", "journal_revision": second.journal_revision, "receipt": second.receipt}
	assert_false(ACTOR.valid_world_op(empty_ack, {second.delivery_id: second}, "namespace_a"))
	var game := OwnerGame.new()
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	game.world.reward_deliveries[second.delivery_id] = second.duplicate(true)
	var writer := OwnerWriter.new()
	game.save_system = writer
	var transport := UnadmittedTransport.new()
	transport.fixture = game
	transport.ledger = LEDGER.new(game.world)
	var before_world: Dictionary = game.world.save_data()
	assert_false(transport._accept_actor_vitals(second.delivery_id, 2, second.receipt, 999))
	assert_eq(writer.writes, 0, "an unadmitted known-receipt ACK must refuse before durable write")
	assert_true(ACTOR.equivalent(game.world.save_data(), before_world), "no mutation of another owner's pending journal")
	transport.free()
	game.free()

func test_owner_write_loss_keeps_accepted_hp_and_requires_real_retry_write() -> void:
	var game := OwnerGame.new()
	game.local = _player()
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	var writer := OwnerWriter.new()
	writer.store = CHARACTER.new(_dir + "characters/")
	game.save_system = writer
	assert_true(writer.save_character(game, "owner_a"))
	var path: String = writer.store.call("path_for", "owner_a")
	var original := FileAccess.get_file_as_bytes(path)
	var portable := _portable(game.local)
	var row := _row(portable, 1, float(portable.party[0].hp) - 10.0)
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	writer.refuse = true
	assert_false(ACTOR.apply_owner(game, row).ok)
	assert_eq(game.local.party.at(0).hp, row.hp, "accepted live HP never rolls back healthy")
	assert_true(game.local.satchel_escrow.is_empty(), "only the unsaved marker rolls back")
	assert_eq(FileAccess.get_file_as_bytes(path), original)
	assert_false(game.session.call("_owner_vitals_snapshot_allowed", game.local, game.local.save_data()),
		"ordinary autosave cannot persist accepted HP without its failed marker")
	var latest := _row(portable, 2, float(portable.party[0].hp) - 20.0, row)
	game.world.reward_deliveries[latest.delivery_id] = latest.duplicate(true)
	assert_false(ACTOR.apply_owner(game, row).ok, "a superseded delivery cannot write or ACK")
	assert_false(ACTOR.apply_owner(game, latest).ok, "latest-only retry still refuses the injected writer")
	assert_eq(game.local.party.at(0).hp, latest.hp, "validated unsaved prior receipt permits latest cumulative HP")
	assert_true(game.local.satchel_escrow.is_empty())
	assert_eq(FileAccess.get_file_as_bytes(path), original)
	row = latest
	writer.refuse = false
	var writes_before := writer.writes
	assert_true(ACTOR.apply_owner(game, row).ok, "live HP equality still performs a real write")
	assert_eq(writer.writes, writes_before + 1)
	assert_eq(writer.store.call("read", "owner_a").party[0].hp, row.hp)
	assert_true(game.local.satchel_escrow.has(row.delivery_id))
	assert_true(game.session.call("_owner_vitals_snapshot_allowed", game.local, game.local.save_data()),
		"actual successful marker write clears the guarded retry context")
	writes_before = writer.writes
	assert_true(ACTOR.apply_owner(game, row).ok)
	assert_eq(writer.writes, writes_before + 1, "duplicate exact receipt is not a disk-success shortcut")
	game.local.party.at(0).hp = float(row.hp) - 1.0
	assert_false(ACTOR.apply_owner(game, row).ok, "old marker cannot ACK over a newer live accepted hit")
	assert_eq(writer.writes, writes_before + 1)
	game.local.party.at(0).hp = float(row.expected_hp)
	assert_false(ACTOR.apply_owner(game, row).ok, "old exact marker cannot replace legitimate later live healing")
	assert_true(game.session.call("_owner_vitals_snapshot_allowed", game.local, game.local.save_data()),
		"refused exact replay cannot create a new unsaved proof or poison ordinary saves")
	game.free()

func test_prepared_writer_never_flushes_a_reentrant_replacement_fallback() -> void:
	var saver := PreparedProbe.new()
	assert_true(saver.save_world_prepared(null, "world_a"))
	assert_eq(saver.writes, 1)
	assert_eq(saver.finishes, 0, "frozen prepared CAS cannot emit fallback completion")
	saver.finish_fallback()
	assert_false(saver.save_world_prepared(null, "world_a"))
	assert_eq(saver.writes, 1, "replacement fallback fails closed before the writer")
	assert_eq(saver.finishes, 1, "prepared refusal does not flush or reemit")
	assert_false(saver.save_character_prepared(null, "owner_a"))
	assert_eq(saver.writes, 1, "owner writer refuses the same reentrant replacement")
	saver.busy = false
	assert_true(saver.save_character_prepared(null, "owner_a"))
	assert_eq(saver.writes, 2)
	assert_eq(saver.finishes, 1, "prepared owner save never emits completion inside receipt freeze")


func test_actor_alias_and_pooled_body_rejoin_require_current_unique_generation() -> void:
	var player := _player()
	player.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	var saved := _portable(player)
	var first: Dictionary = saved.party[0]
	var second: Dictionary = saved.party[1]
	var host := ENCOUNTER.new()
	var rec := host.open(1, "meadows", "wild", {"hp": 100.0, "hp_max": 100.0}, first.uid, "owner_a")
	var id := str(rec.encounter_id)
	var before := rec.duplicate(true)
	assert_eq(host.join(id, 2, second.uid, "owner_a").code, "duplicate_character")
	assert_eq(rec, before, "a second peer cannot alias the same stable character before binding")
	assert_true(host.join(id, 9, "other_uid", "owner_b").ok)
	var body := Node.new()
	assert_eq(host.bind_actor_body(id, 1, "owner_a", first, body.get_instance_id()).vitals.body_generation, 1)
	assert_eq(host.bind_actor_body(id, 1, "owner_a", second, body.get_instance_id()).vitals.body_generation, 2)
	assert_eq(host.bind_actor_body(id, 1, "owner_a", first, body.get_instance_id()).vitals.body_generation, 3)
	host.leave(id, 1)
	assert_true(host.join(id, 2, second.uid, "owner_a").ok)
	assert_eq(host.bind_actor_body(id, 2, "owner_a", second, body.get_instance_id()).vitals.body_generation, 4,
		"rejoin's active-UID label cannot conceal a switch on the same pooled ObjectID")
	assert_true(host.actor_vitals(id, 2, second.uid, 2).is_empty(), "old generation is not current authority")
	var participant: Dictionary = rec.participants[2]
	rec.participants[3] = participant.duplicate(true)
	assert_true(host.actor_vitals(id, 2, second.uid, 4).is_empty(), "corrupt same-record aliases fail closed")
	rec.participants.erase(3)
	var competing := host.open(4, "meadows", "wild", {"hp": 100.0}, second.uid, "owner_a")
	assert_false(host.actor_encounter_is_current(id, 2, "owner_a"), "another active fight cannot share owner authority")
	host.close(str(competing.encounter_id))
	assert_true(host.actor_encounter_is_current(id, 2, "owner_a"))
	participant.actor_generation = 2147483647
	var replacement := Node.new()
	before = rec.duplicate(true)
	assert_eq(host.bind_actor_body(id, 2, "owner_a", second, replacement.get_instance_id()).code, "generation_exhausted")
	assert_eq(rec, before, "exhausted generation cannot remint or mutate accepted actor state")
	replacement.free()
	body.free()


func test_departed_actor_hp_waits_for_exact_durable_handoff_and_stays_private() -> void:
	var owned: Dictionary = _portable(_player()).party[0]
	var host := ENCOUNTER.new()
	var rec := host.open(1, "meadows", "wild", {"hp": 100.0}, owned.uid, "owner_a")
	var id := str(rec.encounter_id)
	host.join(id, 9, "other_uid", "owner_b")
	var body := Node.new()
	assert_true(host.bind_actor_body(id, 1, "owner_a", owned, body.get_instance_id()).ok)
	var before := rec.duplicate(true)
	var proposal := host.stage_actor_vitals(id, 1, owned.uid, 1, 0, "actual_hit", "damage", 1.0, 16)
	assert_true(proposal.ok)
	assert_eq(rec, before, "pre-durability staging cannot publish HP or cost")
	assert_true(host.commit_actor_vitals(proposal).ok)
	assert_eq(host.actor_vitals(id, 1, owned.uid, 1).hp, float(owned.hp) - 1.0)
	assert_false(host.commit_actor_vitals(proposal).ok, "an exact accepted hit cannot debit twice")
	var projected := ENCOUNTER.presentation_snapshot(rec)
	var wire_actor: Dictionary = projected.participants[1].actor_vitals[owned.uid]
	for private_key: String in ["body_instance_id", "receipts", "settlement_receipt", "settled_revision"]:
		assert_false(wire_actor.has(private_key), "presentation cannot become host replay or settlement authority")
	assert_false(projected.participants[1].has("actor_bound_uid"))
	wire_actor.hp = 999.0
	assert_eq(host.actor_vitals(id, 1, owned.uid, 1).hp, float(owned.hp) - 1.0, "wire view is detached")
	host.leave(id, 1)
	host.forget(id)
	assert_false(host.record(id).is_empty(), "departure cannot discard accepted HP before durable handoff")
	assert_eq(host.pending_actor_vitals(id)[0].hp, float(owned.hp) - 1.0)
	assert_false(ENCOUNTER.presentation_snapshot(rec).has("retained_actor_participants"))
	assert_true(host.join(id, 2, owned.uid, "owner_a").ok)
	assert_true(host.bind_actor_body(id, 2, "owner_a", owned, body.get_instance_id()).ok)
	assert_eq(host.actor_vitals(id, 2, owned.uid, 1).hp, float(owned.hp) - 1.0,
		"healthy portable baseline cannot reseed accepted damage on reconnect")
	assert_false(host.acknowledge_actor_vitals(id, "foreign_owner", owned.uid, 1, proposal.settlement_receipt))
	assert_false(host.acknowledge_actor_vitals(id, "owner_a", owned.uid, 0, proposal.settlement_receipt))
	var wrong := proposal.settlement_receipt.duplicate(true)
	wrong.receipt_id += "_forged"
	assert_false(host.acknowledge_actor_vitals(id, "owner_a", owned.uid, 1, wrong))
	assert_true(host.acknowledge_actor_vitals(id, "owner_a", owned.uid, 1, proposal.settlement_receipt),
		"this internal ACK is durable world handoff, not an owner-save-success claim")
	assert_true(host.pending_actor_vitals(id).is_empty())
	host.close(id)
	host.forget(id)
	assert_true(host.record(id).is_empty())
	body.free()


func test_actual_heal_stages_no_cost_then_commits_once_with_per_creature_cooldown() -> void:
	var player := _player()
	player.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	var saved := _portable(player)
	var first: Dictionary = saved.party[0].duplicate(true)
	var second: Dictionary = saved.party[1].duplicate(true)
	# Actual canonical saved creatures with injured/full/fainted storage fixtures;
	# this proves the host door, not earned ownership of an equipped Heal Pulse.
	var host := ENCOUNTER.new()
	var rec := host.open(1, "meadows", "wild", {"hp": 100.0}, first.uid, "owner_a")
	var id := str(rec.encounter_id)
	var body := Node.new()
	var intent := {"encounter_id": id, "action": 1}
	var view := {"source_uid": first.uid, "source_generation": 1, "now_ms": 1000, "origin": Vector3.ZERO}
	var profile := {"max": 100.0, "regen_per_second": 0.0}
	assert_true(host.bind_actor_body(id, 1, "owner_a", first, body.get_instance_id()).ok)
	var before := rec.duplicate(true)
	assert_false(host.stage_actor_heal_utility(intent, 1, view, "heal_pulse", profile, 16).ok)
	assert_eq(rec, before, "full actor refuses before action/Wind/status changes")
	# A separate fainted owned row is refused without changing its life state.
	second.hp = 0.0
	second.fainted = true
	assert_true(host.bind_actor_body(id, 1, "owner_a", second, body.get_instance_id()).ok)
	view.source_uid = second.uid
	view.source_generation = 2
	before = rec.duplicate(true)
	assert_false(host.stage_actor_heal_utility(intent, 1, view, "heal_pulse", profile, 16).ok)
	assert_eq(rec, before, "Heal Pulse cannot revive or spend on a fainted actor")
	assert_true(host.bind_actor_body(id, 1, "owner_a", first, body.get_instance_id()).ok)
	view.source_uid = first.uid
	view.source_generation = 3
	var injury := host.stage_actor_vitals(id, 1, first.uid, 3, 0, "injure_first", "damage", float(first.max_hp) * 0.5, 16)
	assert_true(host.commit_actor_vitals(injury).ok)
	host.preview_wind(id, 1, profile, 0.0, 1000)
	rec.participants[1].wind = 0.0
	before = rec.duplicate(true)
	assert_eq(host.stage_actor_heal_utility(intent, 1, view, "heal_pulse", profile, 16).code, "insufficient_wind")
	assert_eq(rec, before, "refused uncommitted heal cannot charge Wind or HP")
	rec.participants[1].wind = 100.0
	before = rec.duplicate(true)
	var bundle := host.stage_actor_heal_utility(intent, 1, view, "heal_pulse", profile, 16)
	assert_true(bundle.ok)
	assert_eq(rec, before, "world-write refusal can discard the whole staged bundle without rollback")
	var accepted := host.commit_actor_heal_utility(bundle)
	assert_true(accepted.ok)
	assert_almost_eq(float(accepted.vitals.hp), float(first.max_hp) * 0.62)
	assert_almost_eq(float(rec.participants[1].wind), 76.0, 0.0001, "authored Heal Pulse spends 24 Wind exactly once")
	before = rec.duplicate(true)
	assert_false(host.commit_actor_heal_utility(bundle).ok)
	assert_eq(rec, before, "replayed or stale staged heal cannot debit again")
	# Bind a different actually owned injured creature on the same pooled body.
	var third := INSTANCE.from_species("terrapup", SPECIES.table().terrapup)
	player.party.add(third)
	var third_row: Dictionary = _portable(player).party[2]
	third_row.hp = float(third_row.max_hp) * 0.5
	assert_true(host.bind_actor_body(id, 1, "owner_a", third_row, body.get_instance_id()).ok)
	view.source_uid = third_row.uid
	view.source_generation = 4
	view.now_ms = 1800
	intent.action = 2
	var switched := host.stage_actor_heal_utility(intent, 1, view, "heal_pulse", profile, 16)
	assert_true(switched.ok, "after shared recovery a different UID does not inherit the first UID's ten-second cooldown")
	assert_true(host.commit_actor_heal_utility(switched).ok)
	assert_almost_eq(float(rec.participants[1].wind), 52.0)
	assert_true(host.bind_actor_body(id, 1, "owner_a", first, body.get_instance_id()).ok)
	view.source_uid = first.uid
	view.source_generation = 5
	view.now_ms = 3000
	intent.action = 3
	before = rec.duplicate(true)
	assert_eq(host.stage_actor_heal_utility(intent, 1, view, "heal_pulse", profile, 16).code, "cooldown")
	assert_eq(rec, before, "switching away and back cannot erase that creature's own utility cooldown")
	body.free()
