extends "res://tests/helpers/net_harness.gd"

## Deterministic protocol regression for the real asynchronous step() loop.
## No game peers, saves, ENet link or gameplay success are represented here.
## The injected pump delivers a completion and a fault in the same frame.

var _case_name := ""
var _sent_step: Dictionary = {}
var _regression_failures: Array[String] = []
var _regression_checks := 0


func _initialize() -> void:
	call_deferred("_run_completion_cases")


func _run_completion_cases() -> void:
	while Time.get_ticks_msec() <= 1:
		await process_frame
	for mode: String in ["healthy", "host_error", "guest_exit", "budget", "host_error_plain"]:
		_case_name = mode
		_fatal_reason = ""
		_step_phase_deadline_ms = 0.0
		var host_row := {"peer_id": 1, "character_id": "regression_host", "realm": "meadows"}
		var guest_row := {"peer_id": 51, "character_id": "regression_guest", "realm": "meadows"}
		_peers = [
			{"index": 0, "last_heartbeat_received_s": Time.get_ticks_msec() / 1000.0,
				"session_observation": {"available": true, "active": true, "is_host": true,
					"peer_id": 1, "rows": [host_row, guest_row]}},
			{"index": 1, "last_heartbeat_t": 0.125,
				"last_heartbeat": {"frame": 7, "state_hash": 23},
				"session_observation": {"available": true, "active": true, "is_host": false,
					"snapshot_ready": true, "peer_id": 51, "rows": [host_row, guest_row]}},
		]
		# The plain completion control has no host-heartbeat wait, so the old
		# PASS-before-fault ordering fails deterministically regardless of the
		# millisecond in which the two crossing packets happen to be decoded.
		var action := "production_join" if mode == "host_error_plain" else "enter_realm"
		var result: Dictionary = await step(1, action, {"realm": "stormwood"})
		_expect(result.get("verdict") == ("PASS" if mode == "healthy" else "ERROR"), mode + ": terminal verdict")
		_expect(result.get("id") == _sent_step.id, mode + ": command correlation")
		_expect(_peers[1].last_verdict.verdict == "PASS", mode + ": actual received packet retained")
		_expect(_peers[1].heartbeat_deferred_until_s == 0.0, mode + ": guest allowance cleared")
		_expect(_peers[0].get("heartbeat_deferred_until_s", 0.0) == 0.0 and not _peers[0].has("host_shell_step_id"),
			mode + ": host allowance cleared")
		if mode != "healthy":
			_expect(_peers[1].last_heartbeat_t == 0.125, mode + ": failed run earns no completion credit")
			_expect(_peers[1].last_heartbeat == {"frame": 7, "state_hash": 23}, mode + ": heartbeat payload unchanged")
			var expected := "peer 0 reported ERROR" if mode.begins_with("host_error") else (
				"peer 1 exited" if mode == "guest_exit" else "smoke budget exceeded")
			_expect(str(result.get("detail", "")).contains(expected), mode + ": original fault retained")
	_peers.clear()
	_step_phase_deadline_ms = 0.0
	_fatal_reason = ""
	print("HARNESS_COMPLETION_RESULT=" + JSON.stringify({"assertions": _regression_checks, "failures": _regression_failures}))
	quit(0 if _regression_failures.is_empty() and _regression_checks == 37 else 1)


func _send_to(_peer: Dictionary, message: Dictionary) -> void:
	_sent_step = message.duplicate(true)


func _pump_once() -> void:
	# Exercise the shipping decoder and budget detector, without sockets or
	# child processes. A real pump can observe all these events before step()
	# resumes; guest_exit supplies the state set by its OS liveness check.
	_handle_peer_line(_peers[0], JSON.stringify({"type": "heartbeat", "frame": 10, "state_hash": 23}))
	_handle_peer_line(_peers[1], JSON.stringify({"type": "verdict", "id": _sent_step.id, "verdict": "PASS"}))
	match _case_name:
		"host_error", "host_error_plain":
			_handle_peer_line(_peers[0], JSON.stringify({"type": "verdict", "id": "host-fault",
				"verdict": "ERROR", "detail": "regression injected host fault"}))
		"guest_exit":
			_peers[1].exited = true
		"budget":
			_step_phase_deadline_ms = 1.0
			_check_step_budget()


func _expect(condition: bool, label: String) -> void:
	_regression_checks += 1
	if not condition:
		_regression_failures.append(label)
