extends "res://tests/test_case.gd"

## ROADMAP F08 #2 / MULTIPLAYER §2 "Presentation cannot ... write a world flag"
## and D103: a CLIENT's Veyra win is a host-journaled `trainer_victory`, never a
## local world-flag write.
##
## Integrated, tree-free: the REAL Cloudreach encounter director on each side.
## Only the process edges are stood in for, each at the narrowest seam the
## runtime itself exposes:
##   * the session (a Node with `Session`'s is_active/is_host/is_multi_peer/
##     local_peer_id/peers surface);
##   * the wire (`_send_realm_rpc` records what would go to peer 1, and the test
##     hands it to the host director's own `_host_commit_encounter`, then hands
##     the verdict back to the client's own `_receive_trainer_victory_verdict`);
##   * `Game.progression` (the real `merged_progression.gd` over a real
##     `world_state.gd` / `player_state` flag store on each side);
##   * `Game.ledger` on the host (the real `world_ledger.gd`, filled the way
##     `ledger_rpc.gd` fills a host commit: world id and reward recipients from
##     the session registry), whose committed deltas the test applies to the
##     client's own real `world_ledger.gd` -- the path `apply_remote_delta` takes.

const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const MERGED := preload("res://autoload/merged_progression.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const VEYRA := "captain_veyra_storm_anchor"
const VEYRA_FLAG := "captain_veyra_defeated"
const GUEST_PEER := 424242
const HOST_CHARACTER := "character-host0000000000000000000000000001"
const GUEST_CHARACTER := "character-guest000000000000000000000000002"


## `Session`'s read surface, as the director asks it.
class FakeSession extends Node:
	var host := false
	var local := 1
	var rows: Array = []

	func is_active() -> bool:
		return true

	func is_host() -> bool:
		return host

	func is_multi_peer() -> bool:
		return true

	func local_peer_id() -> int:
		return local

	func peers() -> Array:
		return rows.duplicate(true)


## A real flag store that also logs every write, so "the client wrote nothing
## to its world half" is observable rather than inferred from the end state.
class LoggedFlags extends "res://autoload/progression_state.gd":
	var writes: Array = []

	func set_flag(id: String, value: bool = true) -> void:
		writes.append([id, value])
		super.set_flag(id, value)


## One peer's `Game.progression`: the real merged view over a real world store
## and a real player store.
static func _peer_stores() -> Dictionary:
	var world := WORLD_STATE.new()
	var logged := LoggedFlags.new()
	world.flags = logged
	var player := FLAGS.new()
	return {"world": world, "world_flags": logged, "player_flags": player,
		"progression": MERGED.new(logged, player)}


## The CLIENT: the real director. Edges only.
class ClientDirector extends "res://scripts/combat/cloudreach_encounter_director.gd":
	var progression: RefCounted = null
	var wire: Array = []
	var self_paid := 0

	func _can_encounter_rpc() -> bool:
		return true

	func _send_realm_rpc(peer: int, method: String, arguments: Array, _completing: bool = false) -> bool:
		wire.append({"peer": peer, "method": method, "arguments": arguments.duplicate(true)})
		return true

	func _encounter_realm() -> String:
		return "cloudreach"

	func _progression() -> RefCounted:
		return progression

	func _pay_trainer_reward(_spec: Dictionary) -> void:
		self_paid += 1


## The HOST: the real director. Edges only; `_is_host()` is forced because a
## tree-free node is never "inside the tree" the base asks about.
class HostDirector extends "res://scripts/combat/cloudreach_encounter_director.gd":
	var progression: RefCounted = null
	var ledger: RefCounted = null
	var deltas: Array = []
	var told: Array = []

	func _is_host() -> bool:
		return true

	func _can_encounter_rpc() -> bool:
		return false

	func _encounter_realm() -> String:
		return "cloudreach"

	func _progression() -> RefCounted:
		return progression

	func _tell_participant_they_were_paid(peer_id: int, _payload: Dictionary) -> void:
		told.append(peer_id)

	func _trainer_reward_line(_spec: Dictionary) -> String:
		return "" # reads `/root/Game`'s item catalogue: presentation only

	## `ledger_rpc.gd::_host_submit`'s shape for a host-originated intent.
	func _submit_reward_intent(intent: Dictionary) -> Dictionary:
		var out := intent.duplicate(true)
		if str(out.get("kind", "")) == "reward_grant":
			out["world_id"] = str(ledger.world.get("world_id"))
			var recipients: Array = []
			for raw: Variant in (out.get("peers", []) as Array):
				for row: Dictionary in (_session.call("peers") as Array):
					if int(row["peer_id"]) == int(raw):
						recipients.append({"peer": int(raw), "character_id": str(row["character_id"])})
			out["_reward_recipients"] = recipients
		out["_actor_character_id"] = HOST_CHARACTER
		var verdict: Dictionary = ledger.call("commit", out, 1)
		var delta: Dictionary = verdict.get("delta", {}) as Dictionary
		if bool(verdict.get("ok", false)) and not (delta.get("ops", []) as Array).is_empty():
			deltas.append(delta.duplicate(true))
		return verdict


var _host: HostDirector
var _client: ClientDirector
var _host_side: Dictionary
var _client_side: Dictionary
var _client_ledger: RefCounted
var _victories: Array = []


func _build() -> void:
	_victories.clear()
	var rows := [
		{"peer_id": 1, "character_id": HOST_CHARACTER, "realm": "cloudreach"},
		{"peer_id": GUEST_PEER, "character_id": GUEST_CHARACTER, "realm": "cloudreach"},
	]
	_host_side = _peer_stores()
	(_host_side["world"] as RefCounted).set("world_id", "world-f08-host")
	_host = HostDirector.new()
	_host.setup(null)
	_host.progression = _host_side["progression"]
	_host.ledger = LEDGER.new(_host_side["world"])
	var host_session := FakeSession.new()
	host_session.host = true
	host_session.local = 1
	host_session.rows = rows
	_host._session = host_session

	_client_side = _peer_stores()
	_client_ledger = LEDGER.new(_client_side["world"])
	_client = ClientDirector.new()
	_client.setup(null)
	_client.progression = _client_side["progression"]
	var client_session := FakeSession.new()
	client_session.local = GUEST_PEER
	client_session.rows = rows
	_client._session = client_session
	# The production subscriber (`cloudreach_world_runtime.gd::_trainer_won` ->
	# finale) submits its own intent on a client and gets `pending`; it writes
	# nothing locally. Recording the emit is all this seam needs.
	_client.trainer_victory.connect(func(id: String) -> void: _victories.append(id))


func _teardown() -> void:
	for director: Node in [_host, _client]:
		var session: Node = director._session
		director.free()
		if session != null:
			session.free()


func _veyra(director: Node) -> Dictionary:
	return (director.get("trainer_specs") as Dictionary)[VEYRA]


## Hand the client's queued `_rpc_encounter_intent` calls to the host director's
## real dispatcher, and each verdict back to the client's real receiver.
func _deliver_to_host() -> Array:
	var verdicts: Array = []
	var queued := _client.wire.duplicate()
	_client.wire.clear()
	for message: Dictionary in queued:
		if str(message["method"]) != "_rpc_encounter_intent":
			continue
		var intent: Dictionary = (message["arguments"] as Array)[0]
		var verdict: Dictionary = _host._host_commit_encounter(intent, GUEST_PEER)
		verdicts.append(verdict)
		_client._receive_trainer_victory_verdict(verdict)
	return verdicts


## `ledger_rpc.gd::apply_remote_delta`: the client's own ledger applies each
## committed delta to the client's world store.
func _host_deltas_reach_client() -> void:
	for delta: Dictionary in _host.deltas:
		_client_ledger.call("apply", delta)
	_host.deltas.clear()


func _journal_rows(world: RefCounted, character: String) -> Array:
	var out: Array = []
	for raw: Variant in (world.get("reward_deliveries") as Dictionary).values():
		if raw is Dictionary and str((raw as Dictionary).get("character_id", "")) == character \
				and str((raw as Dictionary).get("source", "")).begins_with("trainer:%s:" % VEYRA):
			out.append(raw)
	return out


func test_client_veyra_win_writes_no_local_world_flag_and_lands_from_the_host_delta() -> void:
	_build()
	var client_world_flags: LoggedFlags = _client_side["world_flags"]
	var spec := _veyra(_client)
	assert_eq(str(spec.get("defeat_flag", "")), VEYRA_FLAG)

	_client._record_trainer_defeat(spec)

	# --- before the host answers: an intent in flight, nothing written ------------
	assert_eq(_victories, [VEYRA], "the finale hook fires once")
	assert_eq(_client.wire.size(), 1, "exactly one request leaves for the host")
	var sent: Dictionary = (_client.wire[0]["arguments"] as Array)[0] if _client.wire.size() == 1 else {}
	assert_eq(int(_client.wire[0]["peer"]) if _client.wire.size() == 1 else 0, 1, "addressed to the host")
	assert_eq(str(sent.get("kind", "")), "trainer_victory", "the host-journaled route")
	assert_eq(str(sent.get("trainer_id", "")), VEYRA)
	assert_true(client_world_flags.writes.is_empty(),
		"the client wrote nothing into its world store while the intent is pending (got %s)"
			% str(client_world_flags.writes))
	assert_false((_client_side["progression"] as RefCounted).call("has", VEYRA_FLAG),
		"Veyra's world flag is not readable on the client before the host commits it")
	assert_eq(_client.self_paid, 0, "the client pays itself nothing")

	# A repeat before the host answers asks nothing again and re-announces nothing.
	_client._record_trainer_defeat(spec)
	assert_eq(_client.wire.size(), 1, "a pending repeat sends nothing new")
	assert_eq(_victories.size(), 1, "a pending repeat does not fire the finale hook again")
	assert_true(client_world_flags.writes.is_empty(), "a pending repeat writes nothing either")

	# --- the host journals it -----------------------------------------------------
	var verdicts := _deliver_to_host()
	assert_eq(verdicts.size(), 1)
	assert_true(bool((verdicts[0] as Dictionary).get("ok", false)) if verdicts.size() == 1 else false,
		"the host accepts the guest's win (%s)" % str(verdicts))
	var host_world: RefCounted = _host_side["world"]
	assert_true((host_world.get("flags") as RefCounted).call("has", VEYRA_FLAG),
		"the host world holds Veyra's defeat")
	assert_eq(_journal_rows(host_world, GUEST_CHARACTER).size(), 2,
		"coins and rare candy journaled once each for the guest's character")
	assert_eq(_journal_rows(host_world, HOST_CHARACTER).size(), 0, "nothing for the host, who did not fight")
	assert_eq(_host.told, [GUEST_PEER], "the guest is told once")
	assert_true(client_world_flags.writes.is_empty(), "the verdict alone writes nothing on the client")
	assert_false((_client_side["progression"] as RefCounted).call("has", VEYRA_FLAG),
		"still nothing until the committed delta arrives")

	# --- the delta lands ----------------------------------------------------------
	_host_deltas_reach_client()
	assert_true((_client_side["progression"] as RefCounted).call("has", VEYRA_FLAG),
		"Veyra's flag arrives with the host's committed delta")
	assert_eq(_journal_rows(_client_side["world"], GUEST_CHARACTER).size(), 2,
		"the client mirrors the same journal")

	# --- no double grant ----------------------------------------------------------
	_client._record_trainer_defeat(spec)
	assert_eq(_client.wire.size(), 0, "after the delta a repeat asks nothing")
	assert_eq(_victories.size(), 1)
	var again: Dictionary = _host._host_commit_encounter({"kind": "trainer_victory", "trainer_id": VEYRA}, GUEST_PEER)
	assert_eq(str(again.get("code", "")), "noop", "a duplicate packet pays nobody (got %s)" % str(again))
	assert_eq(_journal_rows(host_world, GUEST_CHARACTER).size(), 2, "still exactly two journal rows")
	assert_eq(_host.told, [GUEST_PEER], "nobody is told twice")
	_teardown()


func test_refused_client_win_leaves_the_world_unbeaten() -> void:
	# Negative control for the route: a host that refuses (the guest is in
	# another realm) commits nothing, and the client's world still reads
	# unbeaten -- nothing optimistic to undo, because nothing was written.
	_build()
	(_host._session as FakeSession).rows = [
		{"peer_id": 1, "character_id": HOST_CHARACTER, "realm": "cloudreach"},
		{"peer_id": GUEST_PEER, "character_id": GUEST_CHARACTER, "realm": "meadows"},
	]
	var client_world_flags: LoggedFlags = _client_side["world_flags"]
	_client._record_trainer_defeat(_veyra(_client))
	var verdicts := _deliver_to_host()
	assert_eq(verdicts.size(), 1)
	assert_eq(str((verdicts[0] as Dictionary).get("code", "")) if verdicts.size() == 1 else "", "wrong_realm")
	_host_deltas_reach_client()
	assert_false((_host_side["progression"] as RefCounted).call("has", VEYRA_FLAG), "the host world is unchanged")
	assert_false((_client_side["progression"] as RefCounted).call("has", VEYRA_FLAG), "the client world is unchanged")
	assert_true(client_world_flags.writes.is_empty(),
		"no write and no compensating clear on the client (got %s)" % str(client_world_flags.writes))
	# The refusal releases the pending send, so a real re-win may ask again.
	_client._record_trainer_defeat(_veyra(_client))
	assert_eq(_client.wire.size(), 1, "after a refusal the next win asks the host again")
	_teardown()


func test_solo_veyra_win_still_writes_locally_once() -> void:
	# Solo is unchanged: no session, the local store owns the flag.
	var side := _peer_stores()
	var director := ClientDirector.new()
	director.setup(null)
	director.progression = side["progression"]
	director._record_trainer_defeat(director.trainer_specs[VEYRA])
	assert_true((side["progression"] as RefCounted).call("has", VEYRA_FLAG), "solo records the defeat")
	assert_eq(director.self_paid, 1, "solo pays once")
	assert_true(director.wire.is_empty(), "solo sends nothing")
	director._record_trainer_defeat(director.trainer_specs[VEYRA])
	assert_eq(director.self_paid, 1, "solo repeat pays nothing")
	director.free()
