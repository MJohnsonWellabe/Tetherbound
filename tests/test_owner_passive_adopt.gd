extends "res://tests/test_case.gd"

## Owner side of a rejoin whose record differs beyond passive drift (owner
## ruling STATE §0: the host world's held record wins inside it). The real
## PlayerState and Party adopt the held record through
## owner_passive_sync._adopt_held_record:
## - an offline catch leaves the party (its deployed body put away first);
##   offline levels revert; kept creatures stay the SAME instances (a deployed
##   body drives them) and keep their runtime-only buffs; the active slot
##   follows its creature;
## - the payout rows the host folded into the held record are marked settled
##   (_settle_folded, on every readmit), so their redelivery cannot pay twice;
## - all or nothing: with a saved companion decision settling it waits and
##   changes nothing; a record that cannot be applied restores the owner exactly.
## Disclosed fixtures: a Game node with the real local character, a director
## double holding the deployed creature, a Session double returning the game.

const SYNC := preload("res://scripts/net/owner_passive_sync.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const SATCHEL := preload("res://scripts/world/death_satchel_rules.gd")
const E := preload("res://scripts/creatures/essence.gd")
const NS := "0123456789abcdef0123456789abcdef"

class GameFixture extends Node:
	var local: RefCounted
	var party: RefCounted
	var world: RefCounted
	var save_system: RefCounted
	var _travel_pos_valid := true
	var _discovery_elapsed := 0.0
	var messages: Array[String] = []
	func push_world_message(text: String) -> void: messages.append(text)

class WorldFixture extends RefCounted:
	var world_id := "world-1"
	var reward_delivery_namespace := "0123456789abcdef0123456789abcdef"

class Writer extends RefCounted:
	var accept := false
	var writes := 0
	func fallback_busy() -> bool: return false
	func save_character_prepared(_game: Node, _character: String) -> bool:
		writes += 1
		return accept

class SessionFixture extends Node:
	var game: Node
	var sent: Array[Dictionary] = []
	func _game() -> Node: return game
	func snapshot_ready() -> bool: return true
	func _altar_current_epoch() -> String: return "epoch"
	func _owner_passive_send_host(packet: Dictionary) -> void: sent.append(packet.duplicate(true))

class Service extends SYNC:
	var directors: Array = []
	func _portal_directors(_game: Node) -> Array: return directors

class Director extends Node:
	var _ally: RefCounted
	var _ally_body: Node
	var dismissed := 0
	var fighting := false
	func trainer_battle_active() -> bool: return fighting
	func dismiss_active_creature() -> bool:
		if fighting: return false
		dismissed += 1
		_ally_body.free()
		_ally_body = null
		_ally = null
		return true

var game: GameFixture
var session: SessionFixture
var service: RefCounted
var director: Director
var held: Dictionary
var caught: RefCounted


func before_each() -> void:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = "character-adopt-owner"
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	game = GameFixture.new()
	game.local = player
	game.party = player.party
	game.world = WorldFixture.new()
	game.save_system = Writer.new()
	session = SessionFixture.new()
	session.game = game
	service = Service.new(session)
	held = RECORD.portable_projection(player.save_data())
	# Offline: a third creature caught, the first gained a level, berries found.
	caught = preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
	player.party.add(caught)
	(player.party.at(0) as RefCounted).level += 1
	player.inventory.add("berries", 4)
	director = Director.new()
	director._ally = caught
	director._ally_body = Node.new()
	service.directors = [director]


func after_each() -> void:
	for node: Variant in [game, session, director, director._ally_body if director != null else null]:
		if node is Node and is_instance_valid(node): (node as Node).free()


func _core(record: Dictionary) -> Dictionary:
	return REPLAY._core(record)


func test_adopts_the_held_record_keeping_instances_and_dropping_the_offline_catch() -> void:
	var first: RefCounted = game.party.at(0)
	var buffs: Array[Dictionary] = [{"stat": "attack", "left": 30.0}]
	first.set("active_buffs", buffs)
	assert_eq((first.get("active_buffs") as Array).size(), 1, "fixture: a tonic is active")
	game.party.set("_active", 1)
	var second: RefCounted = game.party.at(1)
	var outcome: String = service.call("_adopt_held_record", held)
	assert_eq(outcome, "ok", "adopted")
	assert_true(E._equivalent(_core(service.call("_projection")), _core(held)), "the owner now holds the host's record")
	assert_eq(game.party.call("members").size(), 2, "the offline catch left the party")
	assert_eq(director.dismissed, 1, "its deployed body was put away first")
	assert_true(game.party.at(0) == first and game.party.at(1) == second, "kept creatures are the same instances")
	assert_eq(int(first.get("level")), int(held.party[0].level), "the offline level reverted")
	assert_eq((first.get("active_buffs") as Array).size(), 1, "runtime-only buffs stay on the instance")
	assert_eq(int(game.party.get("_active")), 1, "the active slot follows its creature")
	assert_eq(int(game.local.inventory.call("count", "berries")), 0, "the offline find is not in this world's record")
	assert_true(game.messages.back().contains("This world keeps your character"), "the player is told (%s)" % str(game.messages))


func test_folded_payouts_are_marked_settled_and_never_paid_twice() -> void:
	var row := REWARD.make_record("world-1", NS, "pickup:a", "character-adopt-owner", "berries", 3)
	row.status = "pending"
	var bag := SATCHEL.inventory_from(held.inventory)
	bag.call("add", "berries", 3)
	held.inventory = SATCHEL.slots(bag)
	assert_eq(service.call("_adopt_held_record", held), "ok")
	service.call("_settle_folded", [row]) # the readmit's folded rows
	var escrow: Dictionary = game.local.satchel_escrow.get(row.delivery_id, {})
	assert_eq(escrow.get("status"), "settled", "the folded payout is settled in the owner's escrow")
	assert_eq(int(game.local.inventory.call("count", "berries")), 3, "its berries came with the held record")
	var redelivered: Dictionary = REWARD.apply(game.local, row)
	assert_true(bool(redelivered.get("settled")) and not bool(redelivered.get("changed")), "its redelivery is acknowledged without paying")
	assert_eq(int(game.local.inventory.call("count", "berries")), 3, "never twice")


func test_waits_without_change_while_a_companion_decision_settles() -> void:
	var blocked := [true] # a box: a lambda captures locals by value
	game.party.call("bind_owner_mutation_guard", func() -> bool: return blocked[0])
	var before: Dictionary = game.local.save_data()
	var outcome: String = service.call("_adopt_held_record", held)
	assert_true(outcome != "ok", "it waits (%s)" % outcome)
	assert_true(E._equivalent(game.local.save_data(), before), "and changed nothing")
	assert_eq(director.dismissed, 0, "no body was put away")
	blocked[0] = false
	assert_eq(service.call("_adopt_held_record", held), "ok", "once settled it adopts")


func test_a_record_that_cannot_apply_restores_the_owner_exactly() -> void:
	var first: RefCounted = game.party.at(0)
	var before: Dictionary = game.local.save_data()
	var broken := held.duplicate(true)
	broken.inventory = [{"id": "berries", "n": 3}, {"id": "not-an-item-anywhere", "n": 1}]
	var outcome: String = service.call("_adopt_held_record", broken)
	assert_true(outcome != "ok", "refused (%s)" % outcome)
	var after: Dictionary = game.local.save_data()
	assert_true(E._equivalent(_core(RECORD.portable_projection(after)), _core(RECORD.portable_projection(before))),
		"the owner's record is exactly as before")
	assert_eq(game.party.call("members").size(), 3, "with all three creatures")
	assert_true(game.party.at(0) == first, "as the same instances")
	assert_eq(int(first.get("level")), int(before.party[0].level), "and their own values")


func test_a_companion_fighting_waits_and_changes_nothing() -> void:
	director.fighting = true
	var before: Dictionary = game.local.save_data()
	assert_true(service.call("_adopt_held_record", held) != "ok", "it waits while the catch fights")
	assert_true(E._equivalent(game.local.save_data(), before), "nothing changed")
	# A stale ally reference with no body never blocks (review L1).
	director._ally_body.free()
	director._ally_body = null
	assert_eq(service.call("_adopt_held_record", held), "ok", "no body: adoption proceeds")


func test_a_grant_due_escrow_row_the_held_record_holds_is_settled() -> void:
	# Re-review H-1: the owner ACKed a payout with a full bag (grant_due); the
	# host folded it into the held record. Settling it stops the grant_due
	# loop from paying it again.
	var row := REWARD.make_record("world-1", NS, "pickup:full", "character-adopt-owner", "berries", 2)
	var due := row.duplicate(true)
	due.kind = "reward_delivery"
	due.status = "grant_due"
	game.local.satchel_escrow[row.delivery_id] = due
	assert_eq(service.call("_adopt_held_record", held), "ok")
	assert_eq(service.call("_settle_folded", [row]), 1, "settled")
	assert_eq(game.local.satchel_escrow[row.delivery_id].status, "settled")
	var berries := int(game.local.inventory.call("count", "berries"))
	REWARD.apply(game.local, row)
	assert_eq(int(game.local.inventory.call("count", "berries")), berries, "the grant_due loop pays nothing more")


func test_the_readmit_is_confirmed_only_after_its_settlement_is_saved() -> void:
	# Re-review M-1: adoption and settled payouts are saved before
	# "readmitted"; a failed save puts the owner back exactly and sends nothing
	# (the host resends the readmit), then a good save confirms.
	var row := REWARD.make_record("world-1", NS, "pickup:saved", "character-adopt-owner", "berries", 2)
	row.status = "pending"
	var bag := SATCHEL.inventory_from(held.inventory)
	bag.call("add", "berries", 2)
	held.inventory = SATCHEL.slots(bag)
	service.call("arm_owner", service.call("_projection"), {})
	var hash := preload("res://scripts/net/research_passive_preparation.gd")
	var packet := {"op": "readmit", "baseline": held, "baseline_hash": hash.fingerprint(held),
		"discoveries_hash": hash.fingerprint({"discovered": {}}), "discovered": {}, "adopt": true, "folded": [row]}
	var before: Dictionary = game.local.save_data()
	var first: RefCounted = game.party.at(0)
	service.call("_readmit_owner", packet)
	assert_eq(game.save_system.writes, 1, "a save was attempted")
	assert_true(session.sent.filter(func(p: Dictionary) -> bool: return p.get("op") == "readmitted").is_empty(), "nothing confirmed on a failed save")
	assert_true(E._equivalent(_core(RECORD.portable_projection(game.local.save_data())), _core(RECORD.portable_projection(before))), "the owner is put back")
	assert_false(game.local.satchel_escrow.has(row.delivery_id), "with no settled row")
	assert_eq(game.party.call("members").size(), 3, "and its creatures")
	assert_true(game.party.at(0) == first, "as the same instances")
	game.save_system.accept = true
	service.call("_readmit_owner", packet)
	assert_eq(session.sent.filter(func(p: Dictionary) -> bool: return p.get("op") == "readmitted").size(), 1, "confirmed after a good save")
	assert_eq(game.local.satchel_escrow[row.delivery_id].status, "settled", "the payout is settled")
	assert_true(E._equivalent(_core(service.call("_projection")), _core(held)), "and the held record adopted")
