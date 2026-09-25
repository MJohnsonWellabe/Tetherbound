extends SceneTree

## BOSSES §4.7: "A full-party faint restores everyone at Ember Bivouac and
## resets only the Break attempt." The real Dynamo controller and rules run
## with stub session/hub/arena; the fight and the recovery teleport are not
## played here.
const CONTROLLER := preload("res://scripts/world/stormwood_dynamo.gd")
const RULES := preload("res://scripts/world/stormwood_dynamo_rules.gd")

var failures: Array[String] = []
var assertions := 0


class SessionStub extends Node:
	var present := {}

	func is_host() -> bool:
		return true

	func is_active() -> bool:
		return false

	func local_peer_id() -> int:
		return 1

	func realm_of(peer: int) -> String:
		return "stormwood" if present.has(peer) else ""

	func peers_in_realm(_realm: String) -> Array:
		return present.keys()


class HubStub extends Node:
	var sent: Array = []
	var bodies := {}

	func send_to(peer: int, event: Dictionary) -> void:
		sent.append({"peer": peer, "kind": str(event.get("kind", ""))})

	func body_for(peer: int) -> Node3D:
		return bodies.get(peer, null)

	func recoveries() -> int:
		return sent.filter(func(row: Dictionary) -> bool: return row.kind == "dynamo_recovery").size()


class ArenaStub extends Node3D:
	func show_state(_state: Dictionary) -> void:
		pass


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var session := SessionStub.new()
	var hub := HubStub.new()
	var arena := ArenaStub.new()
	root.add_child(session)
	root.add_child(hub)
	root.add_child(arena)
	var controller := CONTROLLER.new()
	controller.session = session
	controller.hub = hub
	controller.arena = arena
	controller.rules = RULES.new()
	controller.rules.update_team(0, 5)
	controller.phase = "break_core"
	controller.participants = [2]
	controller.contributors = [2]
	root.add_child(controller)
	_check(controller.rules.strike_conduit(0, controller.rules.bank_position(0), true), "one conduit struck before the wipe")

	# The only fighter faints out of the realm: a full-party loss during Break.
	for _i in 5:
		await process_frame
	_check(hub.recoveries() == 1, "the party is sent to Ember Bivouac exactly once, not every frame")
	_check(controller.rules.phase == "break_core", "the captain win stands: Break, not a fresh captain fight")
	_check(controller.rules.conduits.is_empty(), "the partial conduit set clears")
	_check(controller.contributors == [2], "the captain win's contributors are kept for the release")
	var frozen: float = controller.rules.window_left()
	for _i in 5:
		await process_frame
	_check(is_equal_approx(controller.rules.window_left(), frozen) and is_equal_approx(frozen, 30.0),
		"Break waits with a fresh 30 s window while nobody is there")

	# Reloading a waiting Break neither replays the wipe nor loses the wait.
	var saved: Dictionary = controller.save_payload()
	var reloaded := CONTROLLER.new()
	reloaded.rules = RULES.new()
	reloaded.load_payload(saved.duplicate(true))
	_check(reloaded.get("_awaiting_break_party") == true and reloaded.participants.is_empty()
		and reloaded.rules.phase == "break_core", "a reload keeps Break waiting with no stale fighters")
	reloaded.free()

	# A fighter climbs back: their creature reaches the arena edge, where the
	# field control takes it over short of Marrow's prompt, and joins Break.
	session.present[2] = true
	var body := Node3D.new()
	root.add_child(body)
	hub.bodies[2] = body
	body.global_position = controller.global_position + Vector3(0, 0, CONTROLLER.BREAK_JOIN_RADIUS_M + 20.0)
	for _i in 3:
		await process_frame
	_check(controller.participants.is_empty(), "a creature still outside the arena does not join")
	body.global_position = controller.global_position + Vector3(0, 0, CONTROLLER.BREAK_JOIN_RADIUS_M - 2.0)
	for _i in 3:
		await process_frame
	_check(controller.participants == [2], "the returning fighter's creature at the arena edge rejoins Break")
	_check(controller.rules.window_left() < 30.0, "the window runs again once someone is there")
	_check(hub.recoveries() == 1, "no further recovery after rejoining")

	# A bystander who never fought the captain team: a join from far away is
	# refused; once their creature is in the arena they strike conduits but do
	# not enter the captain win's reward ledger.
	session.present[3] = true
	var bystander := Node3D.new()
	root.add_child(bystander)
	hub.bodies[3] = bystander
	bystander.global_position = controller.global_position + Vector3(0, 0, CONTROLLER.BREAK_JOIN_RADIUS_M + 30.0)
	controller.dispatch(3, {"kind": "dynamo_join"})
	await process_frame
	_check(not controller.participants.has(3), "a dynamo_join from outside the arena is refused")
	bystander.global_position = controller.global_position + Vector3(10, 0, 0)
	controller.dispatch(3, {"kind": "dynamo_join"})
	for _i in 2:
		await process_frame
	_check(controller.participants.has(3) and not controller.contributors.has(3),
		"a Break arrival strikes conduits but earns no captain-win reward")
	for bank in 4:
		controller.rules.strike_conduit(bank, controller.rules.bank_position(bank), true)
	_check(controller.rules.phase == "released", "the restarted Break can still release the Stormheart")
	controller.set_process(false)
	root.remove_child(controller)
	controller.free()

	# A save taken mid-Break reloads with fighter ids from the old session:
	# they are dropped quietly and Break waits; nobody is thrown back.
	var stale := CONTROLLER.new()
	stale.session = session
	stale.hub = hub
	stale.arena = arena
	stale.rules = RULES.new()
	var mid := RULES.new()
	mid.update_team(0, 5)
	mid.strike_conduit(1, mid.bank_position(1), true)
	stale.load_payload({"rules": mid.save_data(), "participants": [9], "contributors": [9]})
	stale.phase = "break_core"
	hub.bodies.erase(2)
	hub.bodies.erase(3)
	var before := hub.recoveries()
	root.add_child(stale)
	for _i in 5:
		await process_frame
	_check(hub.recoveries() == before and stale.rules.conduits == [1] and stale.participants.is_empty()
		and stale.get("_awaiting_break_party") == true,
		"a reloaded Break with stale fighter ids waits without a recovery or a reset")
	stale.set_process(false)
	root.remove_child(stale)
	stale.free()
	_finish()


func _check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _finish() -> void:
	for failure: String in failures:
		push_error("FAIL: " + failure)
	print("STORMWOOD DYNAMO BREAK FAINT %s: %d assertions, %d failures" % [
		"OK" if failures.is_empty() else "FAILED", assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
