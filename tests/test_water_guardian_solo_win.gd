extends "res://tests/test_case.gd"

## F14 (Tidewake): a SOLO Nerissa win journals the same per-participant
## `trainer:water_trainer_nerissa:*` reward_deliveries row for the local
## character that a session win does, through the same ledger path
## (`reward_grant` -> ledger_rpc -> world_ledger). The Guardian's participant
## set is therefore explicit and survives inviting a guest: the host who beat
## her alone may still answer while a guest is connected; the guest may not.
##
## Before this change a solo win paid locally (`_pay_trainer_reward`) and
## journaled nothing, so with a guest connected the empty journal offered
## NOBODY (multi_peer) and the host's begin/refuse answered `not_participant`.
##
## Solo pays exactly once: the ledger delivery replaces the local payout; the
## local payout runs only when nothing could be journaled.

const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const REWARD := preload("res://scripts/world/water_guardian_reward.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const HOST := 1
const GUEST := 424242
const HOST_CHARACTER := "host-a"
const GUEST_CHARACTER := "guest-b"
const NERISSA := "water_trainer_nerissa"
const NERISSA_FLAG := "water_captain_nerissa_defeated"
const PREFIX := "trainer:water_trainer_nerissa:"


class Saver extends RefCounted:
	var fail_world := false
	func save_world(_game: Object, _world_id: String) -> bool:
		return not fail_world
	func save_character(_game: Object, _character_id: String) -> bool:
		return true


## `active` false models no session at all (pure solo); true with one row is a
## one-peer hosted session. Multi-peer once a second row is admitted.
class SessionStub extends Node:
	var active := false
	var rows: RefCounted = PEER_REGISTRY.new()
	func is_active() -> bool: return active
	func is_host() -> bool: return true
	func is_multi_peer() -> bool: return active and int(rows.call("size")) > 1
	func mode() -> String: return "host" if active else ""
	func handshake_snapshot_applied() -> bool: return true
	func snapshot_ready() -> bool: return true
	func local_peer_id() -> int: return HOST
	func registry() -> RefCounted: return rows
	func peers() -> Array: return rows.call("rows")


class GameFixture extends Node:
	var world: RefCounted = WORLD_STATE.new()
	var local: RefCounted = PLAYER_STATE.new()
	var save_system: RefCounted = Saver.new()
	var session: Node = SessionStub.new()
	var messages: Array = []
	func _init() -> void:
		session.name = "Session"
		add_child(session)
	func is_host() -> bool: return true
	func is_multi_peer() -> bool: return bool(session.call("is_multi_peer"))
	func push_world_message(message: String) -> void: messages.append(message)


class RpcFixture extends "res://scripts/net/ledger_rpc.gd":
	var fixture_game: Node
	func _game() -> Node: return fixture_game
	func _can_rpc() -> bool: return false


## The production director, solo: every rule under test runs as shipped; only
## the transport seams and the local payout are captured.
class DirectorFixture extends "res://scripts/combat/encounter_director.gd":
	var ledger_rpc: Node = null
	var progression_store: RefCounted = PROGRESSION_STATE.new()
	var paid_notices: Array = []
	var local_pays := 0
	func _ensure_encounter_arbiters() -> void:
		pass
	func _is_host() -> bool:
		return _session != null and bool(_session.call("is_active"))
	func _is_multi_peer() -> bool:
		return bool(_session.call("is_multi_peer"))
	func _local_peer_id() -> int: return HOST
	func _encounter_realm() -> String: return "water"
	func _tell_participant_they_were_paid(peer_id: int, payload: Dictionary) -> void:
		paid_notices.append({"peer": peer_id, "payload": payload.duplicate(true)})
	func _pay_trainer_reward(_spec: Dictionary) -> void:
		local_pays += 1
	func _progression() -> RefCounted:
		return progression_store
	func _trainer_reward_line(spec: Dictionary) -> String:
		return "%s's reward" % str(spec.get("name", "Trainer"))
	func _submit_reward_intent(intent: Dictionary) -> Dictionary:
		if ledger_rpc == null:
			return {"ok": false, "pending": false, "code": "offline", "paid": []}
		return ledger_rpc.call("submit", intent)


var _game: GameFixture
var _rpc: Node
var _director: DirectorFixture


func before_each() -> void:
	_game = GameFixture.new()
	_game.world.world_id = "slot-0"
	_game.local.configure(ITEM_DB.new())
	_game.local.character_id = HOST_CHARACTER
	_rpc = RpcFixture.new()
	_rpc.set("fixture_game", _game)
	_rpc.set("ledger", WORLD_LEDGER.new(_game.world))
	_director = DirectorFixture.new()
	_director.set("_session", _game.session)
	_director.ledger_rpc = _rpc


func after_each() -> void:
	for node: Node in [_director, _rpc, _game]:
		if is_instance_valid(node):
			node.free()


func _nerissa_spec() -> Dictionary:
	var tuning: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/water_combat.json"))
	var reward: Dictionary = ((tuning.get("reward_tiers", {}) as Dictionary).get(
		"captain", {}) as Dictionary).duplicate(true)
	return {"id": NERISSA, "name": "Captain Nerissa", "rank": "captain",
		"chapter_rank": "captain", "rechallenge": false, "defeat_flag": NERISSA_FLAG,
		"reward": reward,
		"team": [{"trainer_owned": true, "species": "cannonback", "level": 55}]}


func _rows() -> Array:
	var out: Array = []
	for raw: Variant in _game.world.reward_deliveries.values():
		if raw is Dictionary and str((raw as Dictionary).get("source", "")).begins_with(PREFIX):
			out.append(raw)
	return out


func _count(item: String) -> int:
	return int(_game.local.inventory.call("count", item))


func _admit(peer: int, character_id: String) -> void:
	_game.session.active = true
	assert_false((_game.session.rows.add(peer, character_id, "", "water") as Dictionary).is_empty(),
		"fixture peer %d must be admitted" % peer)


## The Guardian is freed (fixture: the world facts after the win and the fight).
func _free_guardian() -> void:
	for flag: String in [NERISSA_FLAG, "water_tether_disabled", "water_guardian_freed"]:
		_game.world.flags.set_flag(flag)


func _assert_solo_win_journals_the_host_and_survives_an_invite(label: String) -> void:
	_director.call("_record_trainer_defeat", _nerissa_spec())
	var rows := _rows()
	assert_false(rows.is_empty(), label + ": a solo Nerissa win journals a delivery row")
	var sources: Array = []
	for row: Dictionary in rows:
		assert_eq(str(row.get("character_id", "")), HOST_CHARACTER, label + ": each row names the local character")
		sources.append(str(row.get("source", "")))
	sources.sort()
	assert_eq(sources, [PREFIX + "coins", PREFIX + "item:revive"],
		label + ": the same per-component rows a session win journals")
	assert_eq(REWARD.participants(_game.world), [HOST_CHARACTER], label + ": the participant set is explicit")
	# Paid exactly once, through the ledger delivery, never also locally.
	assert_eq(_director.local_pays, 0, label + ": the local payout does not also run")
	assert_eq(_count("coin"), 150, label + ": coins delivered once")
	assert_eq(_count("revive"), 2, label + ": revives delivered once")
	assert_eq(_director.paid_notices.map(func(n: Dictionary) -> int: return int(n.peer)), [HOST],
		label + ": the local peer alone is told, once (XP + line)")
	# A repeat defeat (rechallenge off) pays nothing again.
	_director.call("_record_trainer_defeat", _nerissa_spec())
	assert_eq(_count("coin"), 150, label + ": a repeat defeat pays nothing")
	assert_eq(_director.local_pays, 0, label + ": nor locally")
	# The gap: the host invites a guest BEFORE answering the Guardian.
	_free_guardian()
	_admit(HOST, HOST_CHARACTER)
	_admit(GUEST, GUEST_CHARACTER)
	assert_true(REWARD.is_multi_peer(_game), label + ": a guest is connected")
	var found := REWARD.participants(_game.world)
	assert_true(REWARD.may_receive(HOST_CHARACTER, found, HOST_CHARACTER, false, true),
		label + ": the host who won alone may receive with a guest connected")
	assert_false(REWARD.may_receive(GUEST_CHARACTER, found, HOST_CHARACTER, false, true),
		label + ": the guest who did not fight may not")
	assert_true(REWARD.local_may_answer(_game), label + ": the host's prompt is shown")
	var ledger: RefCounted = _rpc.get("ledger")
	var guardian: RefCounted = SPECIES.spawn("water_abyssal_guardian")
	assert_eq(REWARD.begin(_game, ledger, GUEST_CHARACTER, guardian).code, "not_participant",
		label + ": the guest is refused")
	assert_eq(REWARD.refuse(_game, ledger, GUEST_CHARACTER).code, "not_participant",
		label + ": the guest cannot refuse either")
	var began := REWARD.begin(_game, ledger, HOST_CHARACTER, guardian)
	assert_true(began.ok, label + ": the host answers while the guest is connected")
	assert_eq(str(began.get("code", "")), "", label + ": a fresh offer, not a replay")


func test_solo_win_with_no_session_journals_the_local_character() -> void:
	_assert_solo_win_journals_the_host_and_survives_an_invite("no session")


func test_solo_win_in_a_one_peer_session_journals_the_local_character() -> void:
	_admit(HOST, HOST_CHARACTER)
	assert_false(REWARD.is_multi_peer(_game), "one peer is solo")
	_assert_solo_win_journals_the_host_and_survives_an_invite("one-peer session")


## No durable world file: the journal rolls back and journals nothing, so the
## solo payout runs locally exactly as before (once), and the empty-journal
## solo fallback still offers the host.
func test_a_solo_win_that_cannot_journal_pays_locally_once() -> void:
	_game.save_system.fail_world = true
	_director.call("_record_trainer_defeat", _nerissa_spec())
	assert_true(_rows().is_empty(), "nothing journaled")
	assert_eq(_director.local_pays, 1, "paid once, locally")
	assert_eq(_count("coin"), 0, "no ledger delivery landed")
	assert_true(_director.paid_notices.is_empty(), "nobody told a ledger payment")
	assert_true(REWARD.may_receive(HOST_CHARACTER, [], HOST_CHARACTER, false, false),
		"the solo empty-journal fallback still applies")


## Legacy world: Nerissa was beaten before delivery rows existed. The defeat
## flag is already set, so a repeat defeat journals nothing and pays nothing;
## the journal stays empty and the legacy/solo fallback is untouched.
func test_a_legacy_defeat_journals_nothing() -> void:
	_director.progression_store.call("set_flag", NERISSA_FLAG)
	_director.call("_record_trainer_defeat", _nerissa_spec())
	assert_true(_rows().is_empty(), "no rows for a trainer already beaten")
	assert_eq(_director.local_pays, 0, "and no payout")


## Any other trainer's solo win is unchanged: local payout, no journal.
func test_other_trainers_solo_wins_are_unchanged() -> void:
	var spec := _nerissa_spec()
	spec["id"] = "water_trainer_evi"
	spec["defeat_flag"] = "defeated_water_trainer_evi"
	_director.call("_record_trainer_defeat", spec)
	assert_true(_game.world.reward_deliveries.is_empty(), "no journal")
	assert_eq(_director.local_pays, 1, "paid locally, once")
