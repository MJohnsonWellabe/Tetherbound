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

	# A fighter climbs back and rejoins the waiting Break.
	session.present[2] = true
	var body := Node3D.new()
	root.add_child(body)
	hub.bodies[2] = body
	controller.begin_for_peer(2)
	for _i in 3:
		await process_frame
	_check(controller.participants == [2], "the returning fighter rejoins Break")
	_check(controller.rules.window_left() < 30.0, "the window runs again once someone is there")
	_check(hub.recoveries() == 1, "no further recovery after rejoining")
	for bank in 4:
		controller.rules.strike_conduit(bank, controller.rules.bank_position(bank), true)
	_check(controller.rules.phase == "released", "the restarted Break can still release the Stormheart")
	controller.set_process(false)
	root.remove_child(controller)
	controller.free()
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
