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
