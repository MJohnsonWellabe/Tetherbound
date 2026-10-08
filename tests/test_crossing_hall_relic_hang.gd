extends "res://tests/test_case.gd"

## F18-reported co-op gap: an ordinary guest shrine press did nothing. A
## guest's request must carry the refreshed character revision (personal view
## requested and completed first), and the host's later saved decision must
## reach the player. Detached hall and session doubles; no transport proof
## (the F18 net smoke covers the live path once the portal runtime is on).
const HALL := preload("res://scripts/world/crossing_hall.gd")

class SessionDouble extends Node:
	signal homestead_personal_view_completed
	signal homestead_action_completed(op: String, intent: Dictionary, result: Dictionary)
	var host := false
	var runtime := true
	var answer_view := true
	var calls: Array[String] = []
	var revision := -1
	var sent_revision := -2
	var hang_result: Dictionary = {}
	var inline_result: Dictionary = {}
	func is_host() -> bool: return host
	func portal_runtime_ready() -> bool: return runtime
	func homestead_personal_view() -> Dictionary:
		calls.append("view")
		if answer_view:
			revision = 7
			homestead_personal_view_completed.emit()
		return {"registry_revision": revision}
	func request_relic_hang(biome: String) -> Dictionary:
		calls.append("hang:" + biome)
		sent_revision = revision
		if not inline_result.is_empty():
			homestead_action_completed.emit("relic_hang", {"biome": biome}, inline_result.duplicate(true))
		if not hang_result.is_empty(): return hang_result.duplicate(true)
		if host:
			return {"ok": false, "code": "personal_relic_required", "resolved": true}
		return {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}

class GameDouble extends Node:
	var session: Node
	var messages: Array[String] = []
	func push_world_message(text: String) -> void: messages.append(text)


func _rig(host: bool) -> Array:
	var game := GameDouble.new()
	var session := SessionDouble.new()
	session.host = host
	game.session = session
	return [HALL.new(), game, session]


func test_guest_refreshes_view_before_sending_and_hears_the_host_decision() -> void:
	var rig := _rig(false)
	var hall: Node3D = rig[0]
	var game: GameDouble = rig[1]
	var session: SessionDouble = rig[2]
	hall.call("hang_relic", "meadows", game)
	assert_eq(session.calls, ["view", "hang:meadows"] as Array[String], "the view is refreshed before the request")
	assert_eq(session.sent_revision, 7, "the request carries the refreshed revision, never -1")
	assert_true(game.messages.is_empty(), "no message while the host decides")
	session.homestead_action_completed.emit("relic_hang", {"biome": "meadows"}, {"ok": false, "code": "personal_relic_required"})
	assert_eq(game.messages, ["You have no relic for this shrine yet."] as Array[String], "the host's refusal reaches the guest")
	hall.call("hang_relic", "meadows", game)
	assert_eq(session.calls.size(), 4, "a decided press does not lock later presses")


func test_guest_with_no_view_reply_does_not_send_a_stale_request() -> void:
	var rig := _rig(false)
	var session: SessionDouble = rig[2]
	session.answer_view = false
	rig[0].call("hang_relic", "meadows", rig[1])
	assert_eq(session.calls, ["view"] as Array[String], "nothing is sent until the view arrives")


func test_host_sends_directly_and_surfaces_refusal() -> void:
	var rig := _rig(true)
	var hall: Node3D = rig[0]
	var game: GameDouble = rig[1]
	var session: SessionDouble = rig[2]
	hall.call("hang_relic", "meadows", game)
	assert_eq(session.calls, ["hang:meadows"] as Array[String])
	assert_eq(game.messages, ["You have no relic for this shrine yet."] as Array[String])
	assert_false(session.is_connected("homestead_action_completed", Callable(hall, "_relic_reply")), "synchronous refusal disconnects")
	session.hang_result = {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}
	hall.call("hang_relic", "meadows", game)
	assert_eq(session.calls, ["hang:meadows", "hang:meadows"] as Array[String], "host still sends directly without a guest view refresh")
	assert_eq(hall.get("_relic_pending"), "meadows")
	assert_true(session.is_connected("homestead_action_completed", Callable(hall, "_relic_reply")), "host waits for its actual saved decision")
	hall.call("hang_relic", "meadows", game)
	assert_eq(session.calls.size(), 2, "an in-flight hang cannot submit again")
	session.homestead_action_completed.emit("relic_hang", {"biome": "water"}, {"ok": true})
	session.homestead_action_completed.emit("relic_power", {"biome": "meadows"}, {"ok": true})
	session.homestead_action_completed.emit("relic_hang", {"biome": "meadows"}, {"ok": false, "resolved": false, "code": "owner_passive_checkpoint_pending"})
	assert_eq(hall.get("_relic_pending"), "meadows", "foreign and checkpoint replies cannot finish the original")
	assert_eq(game.messages.size(), 1)
	assert_true(session.is_connected("homestead_action_completed", Callable(hall, "_relic_reply")))
	session.homestead_action_completed.emit("relic_hang", {"biome": "meadows"}, {"ok": false, "resolved": true, "code": "personal_relic_required"})
	assert_eq(game.messages.size(), 2, "asynchronous host refusal is surfaced once")
	assert_eq(hall.get("_relic_pending"), "")
	assert_false(session.is_connected("homestead_action_completed", Callable(hall, "_relic_reply")))
	hall.call("hang_relic", "meadows", game)
	var saved := {"ok": true, "resolved": true, "durable": true, "owner_saved": true, "owner_acknowledged": true}
	session.homestead_action_completed.emit("relic_hang", {"biome": "meadows"}, saved)
	assert_eq(hall.get("_relic_pending"), "", "saved host success releases the original")
	assert_false(session.is_connected("homestead_action_completed", Callable(hall, "_relic_reply")))
	assert_eq(game.messages.size(), 2)
	# The detached hall does not render a power panel. A contradictory immediate
	# return detects re-processing after the inline final callback without UI.
	session.inline_result = saved
	session.hang_result = {"ok": false, "resolved": true, "code": "personal_relic_required"}
	hall.call("hang_relic", "meadows", game)
	assert_eq(game.messages.size(), 2, "inline final success is not replaced by the returned verdict")
	assert_eq(hall.get("_relic_pending"), "")
	assert_false(session.is_connected("homestead_action_completed", Callable(hall, "_relic_reply")))
	session.inline_result = session.hang_result.duplicate(true)
	hall.call("hang_relic", "meadows", game)
	assert_eq(game.messages.size(), 3, "inline final refusal and immediate return present only once")
	assert_eq(hall.get("_relic_pending"), "")
	assert_false(session.is_connected("homestead_action_completed", Callable(hall, "_relic_reply")))
	hall.free()
	game.free()
	session.free()


func test_disabled_portal_runtime_explains_instead_of_sending() -> void:
	var rig := _rig(false)
	var game: GameDouble = rig[1]
	var session: SessionDouble = rig[2]
	session.runtime = false
	rig[0].call("hang_relic", "meadows", game)
	assert_true(session.calls.is_empty(), "no request while the shrine runtime is off")
	assert_eq(game.messages.size(), 1)
