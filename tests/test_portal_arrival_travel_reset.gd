extends "res://tests/test_case.gd"

## F18 #4 (multiplayer-wide 37312829965): a guest's accepted portal/Home Key
## arrival confirms the travel-baseline reset to its owner-passive replay, as
## a fly landing does. Without it the guest's next discovery was refused as
## travel_baseline_mismatch and every later owner-gated action with it.
const ARRIVAL := preload("res://scripts/net/foundation_portal_arrival.gd")

class Lifecycle extends Node:
	var body: Node3D
	func remote_body(_peer: int) -> Node3D: return body

class SessionProbe extends Node:
	var confirmed: Array = []
	func owner_passive_travel_reset_confirmed(peer: int, realm: String, anchor: Vector3, arrival_endpoint: bool = false) -> void:
		confirmed.append([peer, realm, anchor, arrival_endpoint])

func test_an_accepted_guest_arrival_confirms_the_travel_reset_at_its_body() -> void:
	var session := SessionProbe.new()
	var composition := Node.new()
	composition.name = "FoundationComposition"
	session.add_child(composition)
	var lifecycle := Lifecycle.new()
	lifecycle.name = "TravelLifecycle"
	composition.add_child(lifecycle)
	var body := Node3D.new()
	lifecycle.add_child(body)
	body.position = Vector3(12.0, 1.5, -4.0)
	lifecycle.body = body
	ARRIVAL._confirm_travel_reset(session, 7, "meadows")
	assert_eq(session.confirmed.size(), 1)
	assert_eq(session.confirmed[0][0], 7)
	assert_eq(session.confirmed[0][1], "meadows")
	# The anchor is the host's live body (global_position needs the scene
	# tree; smoke_net_f18_travel exercises it end to end).
	assert_true(session.confirmed[0][2] is Vector3)
	assert_true(session.confirmed[0][3], "an arrival-sourced proof")
	lifecycle.body = null
	ARRIVAL._confirm_travel_reset(session, 7, "meadows")
	assert_eq(session.confirmed.size(), 1, "no body, no proof")
	session.free()
