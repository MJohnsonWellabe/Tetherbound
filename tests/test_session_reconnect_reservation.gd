extends "res://tests/test_case.gd"

## X05 / MULTIPLAYER §1.1 and §5: a dropped joiner's character keeps its seat
## for `session.reconnect_window_s`.

const REGISTRY := preload("res://scripts/net/peer_registry.gd")
const T0 := 1_000_000
const WINDOW := 120_000


func _full_two_seat_registry_with_one_drop() -> RefCounted:
	var reg := REGISTRY.new()
	reg.add(1, "host-char")
	reg.add(222, "friend-char")
	reg.remove(222)
	assert_true(reg.reserve("friend-char", T0 + WINDOW))
	return reg


func test_held_seat_refuses_a_different_character_with_a_readable_reason() -> void:
	var reg := _full_two_seat_registry_with_one_drop()
	var verdict: Dictionary = reg.admission_verdict(333, "stranger-char", 2, T0 + 1000)
	assert_false(bool(verdict["ok"]))
	assert_eq(verdict["code"], "session_full")
	assert_true(str(verdict["reason"]).contains("A seat is being held for a player who is reconnecting"),
		str(verdict["reason"]))
	assert_true(str(verdict["reason"]).begins_with("This session is full (2/2)."), str(verdict["reason"]))


func test_returning_character_reclaims_its_held_seat_under_a_new_peer_id() -> void:
	var reg := _full_two_seat_registry_with_one_drop()
	var verdict: Dictionary = reg.admission_verdict(444, "friend-char", 2, T0 + WINDOW - 1)
	assert_true(bool(verdict["ok"]), str(verdict))
	assert_false(reg.add(444, "friend-char").is_empty())
	assert_false(reg.has_reservation("friend-char", T0 + WINDOW - 1), "the rejoin consumed the seat")
	assert_eq(reg.size(), 2)
	var after: Dictionary = reg.admission_verdict(555, "stranger-char", 2, T0 + WINDOW - 1)
	assert_eq(after["reason"], "This session is full (2/2).", "no seat is held any more")


func test_held_seat_lapses_at_the_window() -> void:
	var reg := _full_two_seat_registry_with_one_drop()
	assert_eq(reg.reservation_count(T0 + WINDOW - 1), 1)
	var verdict: Dictionary = reg.admission_verdict(333, "stranger-char", 2, T0 + WINDOW)
	assert_true(bool(verdict["ok"]), "the seat is free once the window has passed")
	assert_eq(reg.reservation_count(T0 + WINDOW), 0)


func test_reservation_counts_only_against_others_when_seats_remain() -> void:
	var reg := REGISTRY.new()
	reg.add(1, "host-char")
	reg.add(222, "a")
	reg.remove(222)
	reg.reserve("a", T0 + WINDOW)
	assert_true(bool(reg.admission_verdict(333, "b", 4, T0)["ok"]), "1 live + 1 held of 4 leaves room")
	reg.add(333, "b")
	assert_true(bool(reg.admission_verdict(444, "c", 4, T0)["ok"]))
	reg.add(444, "c")
	assert_false(bool(reg.admission_verdict(555, "d", 4, T0)["ok"]), "3 live + 1 held fills 4")
	assert_true(bool(reg.admission_verdict(556, "a", 4, T0)["ok"]), "but 'a' still has its seat")


func test_reservation_is_host_bookkeeping_not_replicated_state() -> void:
	var reg := _full_two_seat_registry_with_one_drop()
	var shape: Dictionary = reg.save_data()
	assert_eq((shape["rows"] as Array).size(), 1)
	assert_false(JSON.stringify(shape).contains("friend-char"), "the held seat is not on the wire")
	var bare := REGISTRY.new()
	bare.add(1, "host-char")
	assert_eq(reg.fingerprint(), bare.fingerprint())


func test_live_or_empty_characters_are_not_reserved_and_clear_drops_seats() -> void:
	var reg := REGISTRY.new()
	reg.add(1, "host-char")
	assert_false(reg.reserve("", T0 + WINDOW))
	assert_false(reg.reserve("host-char", T0 + WINDOW), "a connected character needs no seat")
	assert_true(reg.reserve("gone", T0 + WINDOW))
	reg.clear()
	assert_eq(reg.reservation_count(T0), 0, "ending the session releases every held seat")
