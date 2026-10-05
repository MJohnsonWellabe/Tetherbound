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
