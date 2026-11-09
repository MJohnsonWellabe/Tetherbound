extends "res://tests/test_case.gd"

## F39#21 (LANE-MESHY, 9 Nov 2026): Nerissa's Mirejaw could never be sent out
## in the Veilfall Heart Chamber, because the authored side margin capped the
## ring at 10.2 m against an 11.38 m rendered reach. The ring may grow to the
## rendered need only while it stays the visible clearance inside the walls.

const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const VEILFALL := preload("res://scripts/world/water_veilfall.gd")


func test_growth_fits_rendered_need_inside_measured_walls() -> void:
	# Heart Chamber repro numbers: walls about 15.2 m out, Mirejaw needs about 12 m.
	var grown := COMBAT.room_wall_growth_radius(8.0, 7.4, 0.6, 15.2)
	assert_true(is_equal_approx(grown, 12.0), "the ring grows to half gap + footprint + clearance")


func test_growth_refused_when_walls_are_too_close_or_unknown() -> void:
	assert_eq(COMBAT.room_wall_growth_radius(8.0, 7.4, 0.6, 12.4), -1.0, "the grown ring must keep the clearance to the wall")
	assert_eq(COMBAT.room_wall_growth_radius(8.0, 7.4, 0.6, -1.0), -1.0, "no wall measurement, no growth")
	assert_eq(COMBAT.room_wall_growth_radius(8.0, 7.4, 0.6, NAN), -1.0)
	assert_eq(COMBAT.room_wall_growth_radius(30.0, 20.0, 0.6, 60.0), -1.0, "never past the 26 m ring cap")


func test_wall_bound_is_the_margin_free_room_measure() -> void:
	var room := {"center_xz": [0.0, 50.0], "size_xz": [40.0, 60.0]}
	var local := Vector2(7.0, 50.0)
	var walls := VEILFALL.room_arena_bound(local, room, 0.0, 0.0)
	var capped := VEILFALL.room_arena_bound(local, room, 5.0, 1.0)
	assert_true(is_equal_approx(walls, 13.0), "13 m to the east wall")
	assert_true(is_equal_approx(capped, 8.0), "the authored margin keeps 5 m back")
	assert_true(walls > capped)
