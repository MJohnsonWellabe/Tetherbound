extends "res://tests/test_case.gd"

## Stage B Wave 5 lane 5.A. The main story advances once for the world, and a
## character who is behind is never locked out.
##
## Pure logic only (D02): the classification a story trigger makes before it
## submits anything, the shape of the intent it submits, the reader a gate uses
## on the delta that comes back, and the two halves `item_gate.try_open()` was
## split into so a commit can sit between them. The PLAYER EXPERIENCE half --
## a peer with no opening progress joining a world whose boss is already dead
## and acting at once -- is `tests/smoke_net_behind_character_joins_ahead_world.gd`,
## because it needs two real processes and this file cannot have them.
##
## Assertion counts are reported by the runner. Every `get()` below is preceded
## by a `has()` assertion on purpose: `int(null)` is 0 in GDScript and a missing
## key aborts a statement rather than failing it, so a test that reads a field
## straight out of a Dictionary can pass while running FEWER assertions than it
## claims to.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const SEQUENCE_DIRECTOR := preload("res://scripts/story/sequence_director.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")

const TRAINER_DIALOGUE_PATH := "res://data/dialogue/trainers.json"


# --- the "world moved on" set -------------------------------------------------

## Directive rule 3 turns on this list being about THE WORLD. A personal id in
## it would mean a player's own tutorial progress opened Grandpa's door for
## them, which is D99's collapse in the other direction: the gate would be right
## for the one who did it and wrong for the friend who did not.
func test_every_moved_on_flag_is_world_scoped() -> void:
	var flags: Array = SEQUENCE_DIRECTOR.WORLD_MOVED_ON_FLAGS
	assert_true(flags.size() >= 3,
		"the 'world moved on' set is too small to recognise a finished chapter")
	for id: Variant in flags:
		var flag := str(id)
		assert_eq(PROGRESSION_STATE.scope_of(flag), PROGRESSION_STATE.SCOPE_WORLD,
			"%s is in WORLD_MOVED_ON_FLAGS but flag_scopes.json does not call it a world flag" % flag)


## The boss flag specifically, because it is the one the net smoke sets.
func test_the_boss_flag_is_a_world_flag_and_is_in_the_set() -> void:
	assert_eq(PROGRESSION_STATE.scope_of("defeated_warden"), PROGRESSION_STATE.SCOPE_WORLD,
		"defeated_warden must be a world flag or a friend's world never says the boss fell")
	assert_true(SEQUENCE_DIRECTOR.WORLD_MOVED_ON_FLAGS.has("defeated_warden"),
		"a world whose boss is dead has moved on")


# --- D99's residual table ------------------------------------------------------

## "Home and creature-bed objectives are player-scoped but granted to EVERY
## connected peer when the world gains the pieces" (D99). Both halves are
## asserted: they are player flags, AND this lane addresses them to everybody.
func test_the_shared_camp_flags_are_player_scoped_and_shared() -> void:
	for id: String in ["home_built", "home_materials_gathered", "creature_bed_built",
			"creature_bed_built_2", "creature_bed_built_3"]:
		assert_eq(PROGRESSION_STATE.scope_of(id), PROGRESSION_STATE.SCOPE_PLAYER,
			"%s is a personal objective flag (D99)" % id)
		assert_true(STORY_LEDGER.is_shared_player_flag(id),
			"%s is one of D99's residual grants: a shared camp is everyone's camp" % id)


## A personal beat is NOT shared. `tam_tools_given` is the counter-example the
## residual table exists to be distinguished from: handing over YOUR tools does
## not hand over your friend's.
func test_an_ordinary_personal_flag_is_not_shared() -> void:
	assert_eq(PROGRESSION_STATE.scope_of("tam_tools_given"), PROGRESSION_STATE.SCOPE_PLAYER)
	assert_false(STORY_LEDGER.is_shared_player_flag("tam_tools_given"),
		"a personal payoff belongs to the player who earned it")
	assert_false(STORY_LEDGER.is_shared_player_flag("opening:beat:house"),
		"another trainer's tutorial beat is not yours")


# --- what the ledger does with each kind ---------------------------------------

## The world half, end to end through the real ledger: one commit, one world op,
## and a second identical commit is a `noop` rather than a refusal -- a story
## trigger that fires twice must be harmless, because with two players it will.
func test_a_world_flag_commits_once_and_is_a_noop_the_second_time() -> void:
	var world := WORLD_STATE.new()
	var ledger := WORLD_LEDGER.new(world)
	var first: Dictionary = ledger.commit(
		{"kind": "set_world_flag", "realm": "meadows", "id": "south_bridge_open"}, 7)
	assert_true(first.has("ok"), "the verdict always carries 'ok'")
	assert_true(bool(first["ok"]), "the first commit of a world flag lands")
	assert_true(first.has("delta"), "a committed verdict always carries its delta")
	var ops: Array = (first["delta"] as Dictionary).get("ops", []) as Array
	assert_eq(ops.size(), 1, "one world flag is one op")
	var op: Dictionary = ops[0]
	assert_true(op.has("scope"), "every op declares its scope")
	assert_eq(str(op["scope"]), "world", "a gate opening is the world's")
	assert_true(world.flags.has("south_bridge_open"),
		"the delta was applied, so the world itself says the bridge is open")

	var second: Dictionary = ledger.commit(
		{"kind": "set_world_flag", "realm": "meadows", "id": "south_bridge_open"}, 9)
	assert_true(second.has("code"), "the verdict always carries 'code'")
	assert_eq(str(second["code"]), "noop",
		"a second peer opening an already-open gate is harmless, not refused")
	assert_true(bool(second["ok"]), "and it is still an 'ok'")


## The personal half: addressed to the peers named, and to NOBODY else. This is
## the assertion that would catch a personal beat being broadcast, which is the
## bug that makes a friend's tutorial already done.
func test_a_personal_flag_reaches_only_the_peer_it_names() -> void:
	var ledger := WORLD_LEDGER.new(WORLD_STATE.new())
	var verdict: Dictionary = ledger.commit(
		{"kind": "grant_player_flag", "realm": "meadows", "id": "tournament_entered"}, 42)
	assert_true(verdict.has("ok") and bool(verdict["ok"]), "the grant commits")
	assert_true(verdict.has("delta"))
	var delta: Dictionary = verdict["delta"]
	assert_eq(WORLD_LEDGER.player_ops_for(delta, 42).size(), 1,
		"the player who was standing there gets it")
	assert_eq(WORLD_LEDGER.player_ops_for(delta, 43).size(), 0,
		"and the player who was not, does not")


## The shared half of the same intent: everybody named, so a camp built by one
## peer retires the objective for both.
func test_a_shared_camp_flag_reaches_every_named_peer() -> void:
	var ledger := WORLD_LEDGER.new(WORLD_STATE.new())
	var verdict: Dictionary = ledger.commit({
		"kind": "grant_player_flag", "realm": "meadows", "id": "home_built",
		"peers": [1, 77],
	}, 1)
	assert_true(verdict.has("ok") and bool(verdict["ok"]))
	assert_true(verdict.has("delta"))
	var delta: Dictionary = verdict["delta"]
	assert_eq(WORLD_LEDGER.player_ops_for(delta, 1).size(), 1, "the builder gets it")
	assert_eq(WORLD_LEDGER.player_ops_for(delta, 77).size(), 1, "so does their friend")
	assert_eq(WORLD_LEDGER.player_ops_for(delta, 5).size(), 0,
		"and nobody who is not in the session does")


# --- the readers a restore path uses on a delta ---------------------------------

func test_the_delta_readers_tell_a_world_flag_from_everything_else() -> void:
	var world_delta := {"seq": 3, "realm": "meadows", "ops": [
		{"op": "flag", "scope": "world", "id": "road_gate_open", "value": true},
	]}
	assert_true(STORY_LEDGER.delta_has_world_flag(world_delta))
	assert_true(STORY_LEDGER.delta_sets_world_flag(world_delta, "road_gate_open"))
	assert_false(STORY_LEDGER.delta_sets_world_flag(world_delta, "south_bridge_open"),
		"a gate must not open on somebody else's flag")

	var player_delta := {"seq": 4, "realm": "meadows", "ops": [
		{"op": "flag", "scope": "player", "id": "road_gate_open", "value": true, "peers": [1]},
	]}
	assert_false(STORY_LEDGER.delta_has_world_flag(player_delta),
		"a player-scope op is not the world saying anything")
	assert_false(STORY_LEDGER.delta_sets_world_flag(player_delta, "road_gate_open"),
		"and it must never open a gate")

	var building_delta := {"seq": 5, "realm": "meadows", "ops": [
		{"op": "building", "scope": "world", "id": "camp"},
	]}
	assert_false(STORY_LEDGER.delta_has_world_flag(building_delta),
		"a placed building is a world op but not a world FLAG")


# --- item_gate's two halves ------------------------------------------------------

## `try_open()` spends and writes in one call, which a client cannot do: the
## write is a world fact and takes a round trip. `can_open()`/`spend()` are the
## same two halves told apart so a commit can sit between them -- and `spend()`
## must never take anything it cannot take in full.
func test_can_open_and_spend_are_all_or_nothing() -> void:
	var gate := ITEM_GATE.new(["sigil_a", "sigil_b"], "hall_approach_open")
	var satchel := _FakeInventory.new()
	satchel.counts["sigil_a"] = 1

	assert_false(gate.can_open(satchel), "two of three is as shut as none of three")
	assert_false(gate.spend(satchel), "and it spends nothing")
	assert_eq(satchel.removed.size(), 0, "the player still has what they walked up with")

	satchel.counts["sigil_b"] = 1
	assert_true(gate.can_open(satchel), "both keys in hand")
	assert_true(gate.spend(satchel))
	assert_eq(satchel.removed.size(), 2, "one of each, and one only")


## And `spend()` writes no flag: who records an open gate is the caller's
## business now, because on a client the answer is "the host does".
func test_spend_records_nothing() -> void:
	var gate := ITEM_GATE.new("south_bridge_key", "south_bridge_open")
	var satchel := _FakeInventory.new()
	satchel.counts["south_bridge_key"] = 1
	var progression := PROGRESSION_STATE.new()
	assert_true(gate.spend(satchel))
	assert_false(progression.has("south_bridge_open"),
		"spend() takes the key and says nothing about the world")
	assert_false(gate.is_open(progression))


## `try_open()` itself is unchanged -- every solo caller and every existing test
## still goes through it.
func test_try_open_still_spends_and_records_together() -> void:
	var gate := ITEM_GATE.new("south_bridge_key", "south_bridge_open")
	var satchel := _FakeInventory.new()
	satchel.counts["south_bridge_key"] = 1
	var progression := PROGRESSION_STATE.new()
	assert_true(gate.try_open(satchel, progression))
	assert_true(progression.has("south_bridge_open"))
	assert_eq(satchel.removed.size(), 1)


# --- a beaten trainer still speaks ------------------------------------------------

## Rule 3's "no dialogue that refuses to start". A trainer whose spec names no
## `defeated` conversation used to answer a beaten-trainer press with silence,
## which solo is nearly unreachable and with a second player is the ordinary
## case.
func test_the_generic_beaten_conversation_exists() -> void:
	var file := FileAccess.open(TRAINER_DIALOGUE_PATH, FileAccess.READ)
	assert_true(file != null, "data/dialogue/trainers.json is readable")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "trainers.json parses")
	if not parsed is Dictionary:
		return
	var conversations: Variant = (parsed as Dictionary).get("conversations", {})
	assert_true(conversations is Dictionary, "trainers.json has a conversations block")
	if not conversations is Dictionary:
		return
	var id := str(TRAINER_NPC.ALREADY_BEATEN_CONVERSATION)
	assert_true((conversations as Dictionary).has(id),
		"trainer_npc.gd falls back to '%s'; trainers.json must define it" % id)
	if not (conversations as Dictionary).has(id):
		return
	var body: Dictionary = (conversations as Dictionary)[id]
	assert_true(body.has("lines"), "the fallback conversation has lines to say")
	assert_true((body.get("lines", []) as Array).size() > 0,
		"a conversation with no lines is the same silence it was written to replace")


## A defeat flag is a WORLD flag, which is what makes a trainer your friend beat
## read as beaten for you -- and what makes `trainer_npc.gd`'s relabel poll
## (`merged_progression.revision`, the SUM of both stores) notice it.
func test_a_defeat_flag_is_a_world_flag() -> void:
	for id: String in ["trainer_defeated_practice", "defeated_mira", "defeated_warden",
			"relay_captain_defeated"]:
		assert_eq(PROGRESSION_STATE.scope_of(id), PROGRESSION_STATE.SCOPE_WORLD,
			"%s: a trainer only has to be beaten once, by anybody" % id)


# --- fixtures ---------------------------------------------------------------------

## `item_gate.gd` only ever asks an inventory two things. A real `Inventory`
## needs the item database and a slot layout; this needs neither, and keeping
## the double this small is what makes the all-or-nothing assertion above about
## the GATE rather than about stacking.
class _FakeInventory extends RefCounted:
	var counts: Dictionary = {}
	var removed: Array = []

	func count(item_id: String) -> int:
		return int(counts.get(item_id, 0))

	func remove(item_id: String, n: int = 1) -> int:
		removed.append(item_id)
		counts[item_id] = maxi(0, int(counts.get(item_id, 0)) - n)
		return n
