extends "res://tests/test_case.gd"

const JOIN_DRIVER := preload("res://scripts/mp/join_driver.gd")


class FailureStub extends RefCounted:
	var host_rejected := false
	var reason := ""

	func handshake_rejected_by_host() -> bool:
		return host_rejected

	func handshake_failure_reason() -> String:
		return reason


func test_transport_failure_text_does_not_disable_existing_retry_budget() -> void:
	var failure := FailureStub.new()
	failure.reason = "The connection could not be opened."
	assert_eq(JOIN_DRIVER.terminal_admission_reason(failure), "")


func test_host_admission_reason_is_terminal_and_readable() -> void:
	var failure := FailureStub.new()
	failure.host_rejected = true
	failure.reason = "That character is already connected to this world."
	assert_eq(JOIN_DRIVER.terminal_admission_reason(failure), failure.reason)
