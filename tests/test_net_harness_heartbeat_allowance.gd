extends "res://tests/test_case.gd"

const NET_HARNESS := preload("res://tests/helpers/net_harness.gd")


func test_successful_production_join_restarts_the_ordinary_watchdog() -> void:
	var peer := {
		"last_heartbeat_t": 1.0,
		"heartbeat_deferred_until_s": 190.0,
		"last_heartbeat": {"frame": 60, "state_hash": 1234},
	}
	NET_HARNESS._complete_step_heartbeat_allowance(
		peer, "production_join", {"verdict": "PASS"}, 125.0)

	assert_eq(peer["last_heartbeat_t"], 125.0,
		"the received production-join completion becomes the new liveness reference")
	assert_eq(peer["heartbeat_deferred_until_s"], 0.0,
		"the build allowance ends when the step completes")
	assert_eq(peer["last_heartbeat"], {"frame": 60, "state_hash": 1234},
		"a step verdict must not fabricate or replace the last heartbeat payload")
	assert_false(NET_HARNESS.heartbeat_is_silent(125.001, peer["last_heartbeat_t"],
		peer["heartbeat_deferred_until_s"], NET_HARNESS.HEARTBEAT_SILENT_TIMEOUT_S),
		"completion before the next heartbeat is not immediately called silent")
	assert_true(NET_HARNESS.heartbeat_is_silent(140.001, peer["last_heartbeat_t"],
		peer["heartbeat_deferred_until_s"], NET_HARNESS.HEARTBEAT_SILENT_TIMEOUT_S),
		"the ordinary 15-second watchdog still applies after completion")


func test_nonpass_and_unrelated_completions_receive_no_liveness_credit() -> void:
	for completion: Dictionary in [
		{"action": "production_join", "verdict": "FAIL"},
		{"action": "production_join", "verdict": "ERROR"},
		{"action": "join", "verdict": "PASS"},
	]:
		var peer := {"last_heartbeat_t": 4.0, "heartbeat_deferred_until_s": 90.0}
		NET_HARNESS._complete_step_heartbeat_allowance(peer, completion["action"],
			{"verdict": completion["verdict"]}, 50.0)
		assert_eq(peer["last_heartbeat_t"], 4.0,
			"%s/%s must keep the real heartbeat reference"
				% [completion["action"], completion["verdict"]])
		assert_eq(peer["heartbeat_deferred_until_s"], 0.0,
			"%s/%s must not retain a build allowance"
				% [completion["action"], completion["verdict"]])
