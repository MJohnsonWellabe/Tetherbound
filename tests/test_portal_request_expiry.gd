extends "res://tests/test_case.gd"

## Unanswered guest waystone-touch retries expire; travel requests do not.
const SESSION := preload("res://scripts/net/session.gd")

func test_stale_touch_requests_expire_and_travel_requests_stay() -> void:
	var session: Node = SESSION.new()
	var now := Time.get_ticks_msec()
	var old := now - SESSION.PORTAL_TOUCH_REQUEST_TTL_MS - 1
	session._portal_requests = {
		"e:1": {"request_id": "e:1", "payload": {"kind": "waystone_touch"}},
		"e:2": {"request_id": "e:2", "payload": {"kind": "waystone_touch"}},
		"e:3": {"request_id": "e:3", "payload": {"kind": "home_key_finish"}},
	}
	session._portal_request_at = {"e:1": old, "e:2": now, "e:3": old, "e:gone": old}
	session._prune_portal_touch_requests()
	assert_false(session._portal_requests.has("e:1"), "an unanswered old touch retry expires")
	assert_true(session._portal_requests.has("e:2"), "a recent touch keeps waiting for its reply")
	assert_true(session._portal_requests.has("e:3"), "travel keeps its own lifecycle")
	assert_false(session._portal_request_at.has("e:gone"), "answered requests drop their timestamp")
	session.free()


class Authority extends RefCounted:
	var recorded: Array = []
	func record_personal_flag(character: String, flag: String, value: bool) -> void: recorded.append([character, flag, value])

func test_recording_a_guest_walk_out_arms_the_legacy_home_key_check() -> void:
	var session: Node = SESSION.new()
	session._config = {"redesign_portal_runtime_enabled": true} # As shipped (F18 flip).
	assert_true(session.call("portal_runtime_ready") and session.call("is_host"))
	session._character_authority = Authority.new()
	session._legacy_home_key_due.clear()
	session.foundation_record_personal_flags({"ops": [
		{"scope": "player", "op": "flag", "id": "opening:beat:road", "value": true, "peers": [7]}]})
	assert_false(session._legacy_home_key_due.has(7), "other beats do not arm it")
	session.foundation_record_personal_flags({"ops": [
		{"scope": "player", "op": "flag", "id": "opening:beat:walk_out", "value": true, "peers": [7]}]})
	assert_true(session._legacy_home_key_due.has(7), "passing the first catch arms the reconcile for that guest")
	session.free()


class World extends RefCounted:
	var reward_delivery_namespace := "expiry-world"

class GameStub extends Node:
	var world: RefCounted = World.new()

class TickSession extends "res://scripts/net/session.gd":
	var flags: Dictionary = {}
	var game_stub := GameStub.new()
	func _game() -> Node: return game_stub
	func local_peer_id() -> int: return 7
	func _authority_character(peer: int) -> String: return "character-seven" if peer == 7 else ""
	func _foundation_flags(_peer: int) -> Dictionary: return flags.duplicate()

## Review findings 1 and 3: the arm survives while the character is not yet
## past the first catch (its beat may still be on its way), ends with its
## window, and ends at once when the key is already given. A verified gift
## request arms it for that character.
func test_the_reconcile_arm_waits_for_the_first_catch_and_ends_with_its_window() -> void:
	var session := TickSession.new()
	session._config = {"redesign_portal_runtime_enabled": true}
	session.note_opening_gift_requested(7)
	assert_true(session.opening_gift_requested(7), "the host remembers the verified gift request")
	assert_true(session._legacy_home_key_due.has(7), "and arms the reconcile for that character")
	session._opening_gift_requested.clear()
	session._legacy_home_key_left = 0.0
	session._tick_legacy_home_keys(0.0)
	assert_true(session._legacy_home_key_due.has(7), "not past the first catch yet: the arm waits")
	session._legacy_home_key_due[7] = Time.get_ticks_msec() - SESSION.LEGACY_HOME_KEY_WINDOW_MS - 1
	session._legacy_home_key_left = 0.0
	session._tick_legacy_home_keys(0.0)
	assert_false(session._legacy_home_key_due.has(7), "the window bounds the wait")
	session.flags = {"home_key_given": true}
	session.arm_legacy_home_key_check(7)
	session._legacy_home_key_left = 0.0
	session._tick_legacy_home_keys(0.0)
	assert_false(session._legacy_home_key_due.has(7), "a given key ends the arm at once")
	session.game_stub.free()
	session.free()
