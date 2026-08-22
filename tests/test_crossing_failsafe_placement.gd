extends "res://tests/test_case.gd"

## A recovery volume has to be where the hole is.
##
## `scripts/world/severed_spokes.gd::_add_carve_failsafe()` places its Area3D in
## WORLD coordinates. That is right for `severed_spokes.gd` itself, whose holder
## sits at the origin. `gated_crossing.gd` reuses that function -- deliberately,
## the geometry took two attempts to get right and there is no second version
## worth having -- but the crossing sets its own `position` to the carve centre
## and `rotation.y` across the trench, so a holder inheriting that transform
## puts the volume somewhere else entirely.
##
## Measured on the real Meadows scene before the fix, with tools/_probe_gully.gd:
##
##     SouthBridge  local=(8.0, -14.7, 1330.0)  GLOBAL=(-1322.0, -17.6, 1338.0)
##
## The South Bridge gully is at x~0, z=1330. Its guard was 1.3km west in open
## meadow. A blind playtest fell into the trench and held forward for 52 seconds
## without moving a metre -- the floor is below the road on both sides, so
## forward and back are walls, and the only exit was ~50m sideways to where the
## carve fades out. A player who died down there left a satchel 1.3km from
## anywhere.
##
## `top_level = true` on the holder is the fix. This test is the reason it stays:
## it is a one-line property whose absence is invisible in every unit test that
## does not build the world, and the failure it causes looks like level design
## rather than like a bug.
##
## Pure logic, per test_case.gd/D02: this asserts the CONTRACT (a holder that
## receives world coordinates must not inherit a transform) by reading the
## script, not by booting a scene. `tools/_probe_gully.gd` is the live check and
## its numbers are quoted above.

const CROSSING_PATH := "res://scripts/world/gated_crossing.gd"


func test_the_crossing_failsafe_holder_ignores_the_crossing_transform() -> void:
	var file := FileAccess.open(CROSSING_PATH, FileAccess.READ)
	assert_true(file != null, "gated_crossing.gd is missing")
	var source := file.get_as_text()

	assert_true(source.contains("_add_carve_failsafe"),
		"gated_crossing.gd no longer reuses severed_spokes.gd's failsafe; this test's subject has moved")

	var hang := source.find("func _hang_failsafe")
	assert_true(hang >= 0, "gated_crossing.gd has no _hang_failsafe(); the subject has moved")
	var body := source.substr(hang)
	var call_site := body.find("_add_carve_failsafe")
	assert_true(call_site >= 0, "_hang_failsafe no longer builds the volume")

	var before_the_call := body.substr(0, call_site)
	assert_true(before_the_call.contains("top_level = true"),
		"the failsafe holder does not set `top_level = true` before placing the volume. "
		+ "`_add_carve_failsafe()` works in WORLD coordinates and this crossing carries its own "
		+ "position and rotation, so without it the volume lands offset by the whole crossing pose -- "
		+ "measured once at 1.3km from the gully it was supposed to guard, which is a trench a player "
		+ "falls into and cannot walk out of")


## The other half: the crossing really does carry a transform. If it ever stops
## doing so, the guard above becomes unnecessary rather than load-bearing, and
## whoever reads it should be told that rather than left guessing.
func test_the_crossing_still_carries_a_transform_that_would_displace_it() -> void:
	var file := FileAccess.open(CROSSING_PATH, FileAccess.READ)
	assert_true(file != null, "gated_crossing.gd is missing")
	var source := file.get_as_text()
	assert_true(source.contains("position = Vector3(centre.x"),
		"the crossing no longer positions itself at the carve centre; re-check whether the failsafe's `top_level` is still needed")
	assert_true(source.contains("rotation.y = atan2"),
		"the crossing no longer rotates itself across the trench; re-check whether the failsafe's `top_level` is still needed")
