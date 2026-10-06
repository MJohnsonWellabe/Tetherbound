extends "res://tests/test_case.gd"

## F18#4 co-op arrival: a second trainer arriving at an occupied anchor takes
## a fixed, host-authored slot. The list is config only; the anchor is first.
const ARRIVAL := preload("res://scripts/net/foundation_portal_arrival.gd")

func test_anchor_first_then_distinct_authored_offsets() -> void:
	var anchor := Vector3(10.0, 2.0, -4.0)
	var slots: Array[Vector3] = ARRIVAL.arrival_slots(anchor)
	assert_eq(slots[0], anchor, "the authored anchor is always tried first")
	assert_true(slots.size() >= 4, "room for a four-player session")
	var seen := {}
	for slot: Vector3 in slots:
		assert_eq(slot.y, anchor.y, "slots are horizontal offsets; ground is sampled per slot")
		assert_true(Vector2(slot.x - anchor.x, slot.z - anchor.z).length() <= 3.0, "slots stay beside the anchor")
		assert_false(seen.has(slot), "no duplicate slot")
		seen[slot] = true

func test_slots_are_deterministic_for_owner_and_host() -> void:
	var anchor := Vector3(-3.5, 0.0, 7.25)
	assert_eq(ARRIVAL.arrival_slots(anchor), ARRIVAL.arrival_slots(anchor))
