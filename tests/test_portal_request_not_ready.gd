extends "res://tests/test_case.gd"

## F11#3 #43 (2026-10-12): a guest's well-formed portal request that reached
## the host while it was transiently unready (no host world mid-swap, or the
## guest's character not bound yet mid-rejoin) was dropped with no reply, and
## the guest's arch waited out its whole budget. It is now answered NOT_READY
## with the exact reason the arch and Home Key hold and resend; the resend
## after the swap is served. A malformed or foreign request still drops.

const SESSION := preload("res://scripts/net/session.gd")
const WORLD := preload("res://autoload/world_state.gd")
const ARCH := preload("res://scripts/world/portal_arch.gd")
const HOME_KEY := preload("res://scripts/world/home_key.gd")


class GameFixture extends Node:
	var world: RefCounted = null


class PolicyStub extends RefCounted:
	var evaluated := 0
	func bind_world(_id: String) -> void: pass
	func open_channels() -> Array[Dictionary]: return []
	func evaluate(_payload: Dictionary, _context: Dictionary, _cfg: Dictionary, _stones: Dictionary, _now: int) -> Dictionary:
		evaluated += 1
		return {"ok": true}


class HostFixture extends SESSION:
	var game := GameFixture.new()
	var bound := ""
	var delivered: Array[Dictionary] = []
	func is_host() -> bool: return true
	func local_peer_id() -> int: return 1
	func portal_runtime_ready() -> bool: return true
	func _game() -> Node: return game
	func _authority_character(peer: int) -> String: return bound if peer == 2 else "host_a"
	func _host_portal_context(_peer: int) -> Dictionary: return {"realm": "meadows"}
	func _deliver_portal_reply(peer: int, reply: Dictionary) -> void:
		delivered.append({"peer": peer, "reply": reply.duplicate(true)})


func _host() -> HostFixture:
	var host := HostFixture.new()
	host.set("_portal_policy", PolicyStub.new())
	return host


func _envelope(host: HostFixture, serial: int, kind: String = "home_key_begin") -> Dictionary:
	var epoch := str(host.get("_altar_epoch"))
	return {"request_id": "%s:%d" % [epoch, serial], "world_instance_id": "world_a",
		"session_epoch": epoch, "character_id": "guest_a",
		"payload": {"kind": kind, "arch_id": "stormwood"} if kind == "portal_enter" else {"kind": kind}}


func _swap_done(host: HostFixture) -> void:
	var world := WORLD.new()
	world.reward_delivery_namespace = "world_a"
	host.game.world = world
	host.bound = "guest_a"


func test_a_request_during_the_host_swap_is_not_ready_and_the_resend_succeeds() -> void:
	var host := _host()
	var first := _envelope(host, 1)
	host.call("_host_portal_action", 2, first)
	assert_eq(host.delivered.size(), 1, "a request mid-swap is answered, not dropped")
	var reply: Dictionary = host.delivered[0].reply
	assert_eq(host.delivered[0].peer, 2)
	assert_false(bool(reply.get("ok", true)))
	assert_eq(str(reply.get("reason")), ARCH.NOT_READY, "the exact reason the arch holds and resends")
	assert_eq(str(reply.get("reason")), HOME_KEY.NOT_READY, "and the Home Key")
	for key: String in ["request_id", "character_id", "world_instance_id", "session_epoch"]:
		assert_eq(reply.get(key), first[key], "the reply correlates to the original %s" % key)
	assert_eq(str(reply.get("kind")), "home_key_begin")
	assert_eq((host.get("_portal_policy") as PolicyStub).evaluated, 0, "nothing was evaluated while unready")
	# The swap finishes; the requester's resend is a new request id.
	_swap_done(host)
	host.call("_host_portal_action", 2, _envelope(host, 2))
	assert_eq(host.delivered.size(), 2)
	assert_true(bool(host.delivered[1].reply.get("ok", false)), "the resend after the swap is served")
	assert_eq((host.get("_portal_policy") as PolicyStub).evaluated, 1)
	host.game.free()
	host.free()


func test_a_request_before_the_rejoined_character_is_bound_is_not_ready() -> void:
	var host := _host()
	_swap_done(host)
	host.bound = ""
	host.call("_host_portal_action", 2, _envelope(host, 1, "portal_enter"))
	assert_eq(host.delivered.size(), 1)
	assert_eq(str(host.delivered[0].reply.get("reason")), ARCH.NOT_READY)
	assert_eq(str(host.delivered[0].reply.get("kind")), "portal_enter", "the arch holds only its own portal_enter")
	host.game.free()
	host.free()


func test_invalid_requests_still_drop_without_a_reply() -> void:
	var host := _host()
	var bad: Array[Dictionary] = []
	var foreign_epoch := _envelope(host, 1)
	foreign_epoch.session_epoch = "another_session"
	bad.append(foreign_epoch)
	var foreign_id := _envelope(host, 2)
	foreign_id.request_id = "another_session:2"
	bad.append(foreign_id)
	var extra := _envelope(host, 3)
	extra["extra"] = true
	bad.append(extra)
	var bad_payload := _envelope(host, 4)
	bad_payload.payload = {"kind": "not_a_portal_action"}
	bad.append(bad_payload)
	var no_character := _envelope(host, 5)
	no_character.character_id = ""
	bad.append(no_character)
	# Unready host: each is still invalid, not NOT_READY.
	for envelope: Dictionary in bad:
		host.call("_host_portal_action", 2, envelope)
	assert_eq(host.delivered.size(), 0, "malformed or foreign requests drop while unready")
	# Ready host: the same, plus a request for another character or world.
	_swap_done(host)
	var other_character := _envelope(host, 6)
	other_character.character_id = "guest_b"
	bad.append(other_character)
	var other_world := _envelope(host, 7)
	other_world.world_instance_id = "world_b"
	bad.append(other_world)
	for envelope: Dictionary in bad:
		host.call("_host_portal_action", 2, envelope)
	assert_eq(host.delivered.size(), 0, "malformed, foreign or mismatched requests drop when ready")
	assert_eq((host.get("_portal_policy") as PolicyStub).evaluated, 0)
	host.game.free()
	host.free()


func test_valid_disposition_is_exactly_the_old_validity_rule() -> void:
	# The old rule: epoch-prefixed id, epoch, bound character, world, payload.
	var epoch := "e1"
	var good := {"request_id": "e1:1", "world_instance_id": "w", "session_epoch": "e1",
		"character_id": "c", "payload": {"kind": "portal_enter", "arch_id": "stormwood"}}
	assert_eq(SESSION.portal_request_disposition(good, epoch, "w", "c"), SESSION.PORTAL_REQUEST_VALID)
	assert_eq(SESSION.portal_request_disposition(good, epoch, null, "c"), SESSION.PORTAL_REQUEST_NOT_READY)
	assert_eq(SESSION.portal_request_disposition(good, epoch, "w", ""), SESSION.PORTAL_REQUEST_NOT_READY)
	assert_eq(SESSION.portal_request_disposition(good, epoch, "w", "d"), SESSION.PORTAL_REQUEST_INVALID)
	assert_eq(SESSION.portal_request_disposition(good, epoch, "x", "c"), SESSION.PORTAL_REQUEST_INVALID)
	assert_eq(SESSION.portal_request_disposition(good, "e2", "w", "c"), SESSION.PORTAL_REQUEST_INVALID)
