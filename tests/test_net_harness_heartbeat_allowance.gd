extends "res://tests/test_case.gd"

const NET_HARNESS := preload("res://tests/helpers/net_harness.gd")


func test_native_step_completion_cannot_override_a_same_pump_fault() -> void:
	# run_tests itself starts in _init and cannot drive a frame-awaiting step.
	# The isolated child runs the actual coroutine with controlled protocol
	# arrivals; it launches no game peers and makes no co-op proof claim.
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), PackedStringArray([
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/helpers/net_harness_completion_fault.gd",
	]), output, true)
	var log_text := "\n".join(output)
	var result: Dictionary = {}
	for line: String in log_text.split("\n"):
		if line.begins_with("HARNESS_COMPLETION_RESULT="):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("HARNESS_COMPLETION_RESULT="))
			if parsed is Dictionary: result = parsed
	assert_eq(code, 0, log_text)
	assert_eq(result.get("assertions"), 37.0, "all completion/fault controls actually ran")
	assert_eq(result.get("failures"), [], log_text)
	for marker: String in ["SCRIPT ERROR", "Parse Error", "ERROR:"]:
		# The two injected coordinator/peer ERROR lines are expected protocol
		# observations. Native/script diagnostics start their own log line.
		assert_false(log_text.contains("\n" + marker) or log_text.begins_with(marker), log_text)


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


func test_only_named_world_building_steps_defer_the_detector() -> void:
	assert_eq(NET_HARNESS.world_build_allowance_s("production_join"), 90.0)
	assert_eq(NET_HARNESS.world_build_allowance_s("enter_realm"), 150.0,
		"a realm crossing rebuilds a world scene like a production join")
	for other: String in ["join", "host", "leave", "wait", "stick", "probe", ""]:
		assert_eq(NET_HARNESS.world_build_allowance_s(other), 0.0,
			"'%s' keeps the ordinary 15-second detector" % other)


func test_successful_realm_crossing_restarts_the_ordinary_watchdog() -> void:
	var peer := {"last_heartbeat_t": 1.0, "heartbeat_deferred_until_s": 190.0}
	NET_HARNESS._complete_step_heartbeat_allowance(peer, "enter_realm", {"verdict": "PASS"}, 80.0)
	assert_eq(peer["last_heartbeat_t"], 80.0)
	assert_eq(peer["heartbeat_deferred_until_s"], 0.0)
	var failed := {"last_heartbeat_t": 1.0, "heartbeat_deferred_until_s": 190.0}
	NET_HARNESS._complete_step_heartbeat_allowance(failed, "enter_realm", {"verdict": "FAIL"}, 80.0)
	assert_eq(failed["last_heartbeat_t"], 1.0, "a failed crossing earns no liveness credit")


func _crossing_observations() -> Array:
	var host_row := {"peer_id": 1, "character_id": "character_host", "realm": "meadows"}
	var guest_row := {"peer_id": 51, "character_id": "character_guest", "realm": "meadows"}
	return [
		{"role": "client", "last_heartbeat_received_s": 10.0, "session_observation": {
			"available": true, "active": true, "is_host": true, "peer_id": 1, "rows": [host_row]}},
		{"role": "host", "session_observation": {"available": true, "active": true,
			"is_host": false, "snapshot_ready": true, "peer_id": 51, "rows": [host_row.duplicate(true), guest_row]}},
		{"role": "host", "last_heartbeat_received_s": 10.0, "session_observation": {
			"available": true, "active": true, "is_host": true, "peer_id": 1,
			"rows": [{"peer_id": 1, "character_id": "another_host", "realm": "meadows"}]}},
	]


func test_foreign_shell_allowance_selects_only_actual_connected_host_identity() -> void:
	var peers := _crossing_observations()
	assert_eq(NET_HARNESS.host_shell_peer_for_crossing(peers, 1, "enter_realm", {"realm": "stormwood"}, 11.0), 0,
		"the applied client snapshot binds the actual host character, never harness role or matching server peer ID alone")
	for action: String in ["press", "production_join", "wait", "leave", ""]:
		assert_eq(NET_HARNESS.host_shell_peer_for_crossing(peers, 1, action, {"realm": "stormwood"}, 11.0), -1)
	assert_eq(NET_HARNESS.host_shell_peer_for_crossing(peers, 1, "enter_realm", {"realm": "meadows"}, 11.0), -1,
		"a local/no-op destination must not cover host work")
	assert_eq(NET_HARNESS.host_shell_peer_for_crossing(peers, 1, "enter_realm", {"realm": "stormwood"}, 25.01), -1,
		"an already silent host never receives a new allowance")


func test_missing_unadmitted_conflicting_or_departed_session_cannot_borrow_host_allowance() -> void:
	for mutation: String in ["missing", "unadmitted", "wrong_host", "conflicting_guest", "exited", "already_building"]:
		var peers := _crossing_observations()
		match mutation:
			"missing": peers[1].erase("session_observation")
			"unadmitted": peers[1].session_observation.snapshot_ready = false
			"wrong_host": peers[1].session_observation.rows[0].character_id = "not_the_host"
			"conflicting_guest": peers[0].session_observation.rows.append({"peer_id": 51, "character_id": "other_guest", "realm": "meadows"})
			"exited": peers[0].exited = true
			"already_building": peers[0].heartbeat_deferred_until_s = 100.0
		assert_eq(NET_HARNESS.host_shell_peer_for_crossing(peers, 1, "enter_realm", {"realm": "stormwood"}, 11.0), -1, mutation)


func test_host_completion_requires_actual_new_heartbeat_and_never_rewrites_it() -> void:
	var peer := {"host_shell_step_id": "s7", "heartbeat_deferred_until_s": 150.0,
		"last_heartbeat_t": 4.0, "last_heartbeat_received_s": 4.0,
		"last_heartbeat": {"frame": 60, "state_hash": 1234}}
	assert_false(NET_HARNESS.host_shell_heartbeat_resumed(peer, 35.0), "a guest PASS cannot become host liveness")
	NET_HARNESS.clear_host_shell_allowance(peer, "other_step")
	assert_eq(peer.heartbeat_deferred_until_s, 150.0, "another command cannot clear this cut's allowance")
	var before := peer.duplicate(true)
	NET_HARNESS.clear_host_shell_allowance(peer, "s7")
	assert_eq(peer.heartbeat_deferred_until_s, 0.0)
	for field: String in ["last_heartbeat_t", "last_heartbeat_received_s", "last_heartbeat"]:
		assert_eq(peer[field], before[field], "completion/failure must preserve actual heartbeat evidence")
	assert_true(NET_HARNESS.heartbeat_is_silent(35.0, peer.last_heartbeat_t, 0.0, 15.0),
		"clearing must expose a real stale host, not reset its clock")
	peer.last_heartbeat_received_s = 35.0
	assert_true(NET_HARNESS.host_shell_heartbeat_resumed(peer, 35.0), "only a real subsequently received host heartbeat completes attribution")
