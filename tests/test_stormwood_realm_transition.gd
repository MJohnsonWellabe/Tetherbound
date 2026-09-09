extends "res://tests/test_case.gd"

const HOSTED := preload("res://scripts/combat/stormwood_hosted_trainer.gd")
const TRANSITION := preload("res://scripts/net/realm_transition.gd")

class RecordingHub extends "res://scripts/world/stormwood_encounter_hub.gd":
	var messages: Array = []
	func publish(_fight: Node, event: Dictionary) -> void:
		messages.append(event.duplicate(true))
	func trainer_finished(_fight: Node, _won: bool) -> void:
		pass

class Director extends "res://scripts/combat/encounter_director.gd":
	func _is_host() -> bool:
		return true
	func _host_after_encounter_change(_id: String, _author: int = 0) -> void:
		pass

class RecordingSession extends "res://scripts/net/session.gd":
	var dispatched: Array = []
	var identity := 20
	func is_host() -> bool:
		return true
	func is_active() -> bool:
		return true
	func local_peer_id() -> int:
		return identity
	func _dispatch_stormwood_encounter(_peer: int, intent: Dictionary) -> void:
		dispatched.append(intent.duplicate(true))

class InboundSession extends "res://scripts/net/session.gd":
	var gate_calls: Array = []
	func realm_of(_peer: int) -> String:
		return "stormwood"
	func _stormwood_transition_allowed(peer: int, completing: bool) -> bool:
		gate_calls.append([peer, completing])
		return false

func _roster_case(between: bool) -> void:
	var world := Node.new()
	var director := Director.new()
	world.add_child(director)
	var hub := RecordingHub.new()
	hub.name = "StormwoodEncounterHub"
	hub.director = director
	world.add_child(hub)
	director.set("_encounter_host", hub.authority)
	var fight := HOSTED.new()
	hub.add_child(fight)
	fight.hub = hub
	fight.authority = hub.authority
	fight.spec = {"id": "fixture"}
	fight.participants = [20, 30] as Array[int]
	fight.record = hub.authority.open(20, "stormwood", "trainer", {"hp": 100.0, "hp_max": 100.0})
	hub.authority.join(str(fight.record.encounter_id), 30)
	if between:
		fight.record.phase = "done"
		fight.set("_between", 2.0)
	hub.fights["fixture"] = fight
	director.realm_transition_departing(20)
	assert_false(fight.participants.has(20), "real hosted roster must retire before response fence")
	assert_true(fight.participants.has(30), "staying participant survives")
	assert_false(hub.authority.participants_of(str(fight.record.encounter_id)).has(20))
	assert_false(fight.finished, "remaining player's roster stays live")
	assert_eq(hub.messages.size(), 1, "roster response is produced synchronously before callback returns")
	director.realm_transition_departing(20)
	assert_eq(hub.messages.size(), 1, "duplicate departure does not republish roster")
	world.free()

func test_active_hosted_roster_retires_before_response_fence() -> void:
	_roster_case(false)

func test_between_round_roster_retires_before_response_fence() -> void:
	_roster_case(true)

func test_local_hosted_intents_stop_but_completion_can_settle() -> void:
	var session := RecordingSession.new()
	var transition := TRANSITION.new()
	session.add_child(transition)
	session.realm_transition = transition
	transition.transactions["t"] = {"mover": 20, "from": "stormwood", "to": "water", "phase": "requests_closed"}
	session.request_stormwood_encounter({"kind": "start"})
	session.request_stormwood_encounter({"kind": "strike_intent"})
	assert_eq(session.dispatched.size(), 0, "new intents cannot be produced after request closure")
	session.request_stormwood_encounter({"kind": "disengage"})
	session.request_stormwood_encounter({"kind": "finalized_death_withdrawal"})
	assert_eq(session.dispatched.size(), 2, "existing completion intent names remain compatible")
	transition.transactions["t"].phase = "closed"
	session.request_stormwood_encounter({"kind": "disengage"})
	assert_eq(session.dispatched.size(), 2, "no completion after response closure")
	session.identity = 30
	session.request_stormwood_encounter({"kind": "start"})
	assert_eq(session.dispatched.size(), 3, "unrelated participant retains baseline")
	session.free()

func test_inbound_prefence_and_outbound_results_respect_receiver_phase() -> void:
	var session := RecordingSession.new()
	session.identity = 1
	var transition := TRANSITION.new()
	session.add_child(transition)
	session.realm_transition = transition
	assert_true(session._stormwood_transition_allowed(20, true), "ordinary join/snapshot baseline")
	transition.transactions["t"] = {"mover": 20, "from": "stormwood", "to": "water", "phase": "requests_closed"}
	assert_true(session._stormwood_transition_allowed(20, true), "already queued incoming request can precede sender fence")
	assert_true(session._stormwood_transition_allowed(30, true), "staying receiver continues")
	transition.transactions["t"].phase = "closed"
	assert_false(session._stormwood_transition_allowed(20, true), "host cannot enqueue later results to departing receiver")
	assert_true(session._stormwood_transition_allowed(30, true))
	transition.transactions["t"].phase = "draining"
	assert_false(session._stormwood_transition_allowed(20, true), "late inbound callbacks cannot reopen hosted activity")
	transition.transactions.clear()
	transition.retired_receivers[20] = {"stormwood": "t"}
	assert_false(session._stormwood_transition_allowed(20, true), "completed source remains denied")
	transition.reset()
	assert_true(session._stormwood_transition_allowed(20, true), "session reset restores baseline")
	session.free()

func test_actual_local_response_emission_stops_after_response_closure() -> void:
	var session := RecordingSession.new()
	var transition := TRANSITION.new()
	session.add_child(transition)
	session.realm_transition = transition
	var received: Array = []
	session.stormwood_encounter_message.connect(func(event: Dictionary) -> void: received.append(event))
	transition.transactions["t"] = {"mover": 20, "from": "stormwood", "to": "water", "phase": "requests_closed"}
	session.send_stormwood_encounter(20, {"kind": "state"})
	assert_eq(received.size(), 1, "final roster state is delivered before response fences")
	transition.transactions["t"].phase = "closed"
	session.send_stormwood_encounter(20, {"kind": "state"})
	assert_eq(received.size(), 1, "later roster state cannot reach closed receiver")
	session.free()

func test_actual_inbound_dispatch_calls_receiver_gate_before_hub_lookup() -> void:
	var session := InboundSession.new()
	session._dispatch_stormwood_encounter(20, {"kind": "start"})
	assert_eq(session.gate_calls, [[20, true]], "inherited dispatch must gate prior to accessing world hub")
	session.free()
