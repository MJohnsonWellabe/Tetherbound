extends "res://tests/test_case.gd"

## `GF-B-004`: "a solid black unshaded sphere hangs in the Meadows Hall
## gateway", at the threshold of the chapter's climactic location.
##
## It is neither a missing mesh nor an unassigned material. It is the tether
## lamp's own iron housing (`stronghold_occupation.gd::_build_tether_lamps()`),
## correctly built and correctly materialled, pointed at the camera: an
## `IRON_COLOUR` (`#2a2622`, deliberately below the castle's darkest stone) disc
## that was WIDER than the lens it backs and stood PROUD of that lens's front
## pole, so from one side along the lamp's axis it hid the lens completely and
## from the other it ringed it in black.
##
## Pure arithmetic, deliberately: this is a relationship between four numbers,
## and it can be checked without a stronghold, a terrain or a renderer (D02).
## The frame is the other half and cannot be retaken from the camera that
## reported it — `tools/gate_f/segments/X07.json`'s `hall` block faces the
## player 180 degrees from the approach, which is separately why a camera
## reconstructed from that pose lands inside the masonry.

const OCCUPATION := preload("res://scripts/world/stronghold_occupation.gd")

## `_build_tether_lamps()`'s own `can.height = radius * 0.9`. Duplicated here
## rather than exported: if that line changes, this constant stops matching and
## the test below starts describing a housing the game does not build, which is
## exactly the failure a named constant would hide.
const HOUSING_HEIGHT_RATIO := 0.9


## The lamp's axis is local Z. The LENS side is -Z (the side the lamp is meant
## to be read from, and the side its `OmniLight3D` throws toward); the housing
## sits at +Z, mounting it to the stone behind. Both faces are named for where
## they are on that axis, not for which one a particular viewer sees first --
## a first version of this file called the -Z face "front" and then asserted
## against it from the +Z side, which is the one relationship that does not
## matter.
func _housing_lens_side_face() -> float:
	return float(OCCUPATION.HOUSING_OFFSET_RATIO) - HOUSING_HEIGHT_RATIO * 0.5


func _housing_far_face() -> float:
	return float(OCCUPATION.HOUSING_OFFSET_RATIO) + HOUSING_HEIGHT_RATIO * 0.5


func test_housing_is_narrower_than_the_lens() -> void:
	# A housing wider than the lens draws a black ring around it from the front,
	# whatever else is true. `STRONGHOLD-R2` read the lamp as "a flat pale disc
	# with a dark ring round it -- a coin stuck on the tower" and spent its fix
	# on emission energy; the ring was this.
	assert_true(
		float(OCCUPATION.HOUSING_RADIUS_RATIO) < 1.0,
		"the lamp housing is %.2f of the lens radius; wider than the lens, it rings the lens in black" % [
			float(OCCUPATION.HOUSING_RADIUS_RATIO)]
	)


func test_the_lamp_still_shows_teal_from_directly_behind() -> void:
	# THE FAILURE THAT PRODUCED GF-B-004's FRAME, stated exactly.
	#
	# Looking down the axis from +Z, the nearest surface is the housing's far
	# face, at `_housing_far_face()` with radius `HOUSING_RADIUS_RATIO`; the
	# lens behind it presents a silhouette of exactly 1.0 lens radii. If the
	# housing is at least as wide as that silhouette it covers the lens
	# completely and the lamp renders as a solid black circle -- which is what
	# Gate F photographed. Narrower, and teal shows around it from every angle
	# including this one.
	#
	# The old numbers (1.25 wide, offset 0.8) fail here: a 1.25 disc standing at
	# 1.25 lens radii, in front of a 1.0 silhouette.
	assert_true(
		float(OCCUPATION.HOUSING_RADIUS_RATIO) < 1.0,
		"the housing is %.2f lens radii wide and its far face stands at %.2f; it covers the lens's whole %.2f silhouette from behind and the lamp renders as a black disc" % [
			float(OCCUPATION.HOUSING_RADIUS_RATIO), _housing_far_face(), 1.0]
	)


func test_the_lens_hides_the_housing_from_the_front() -> void:
	# Stronger than "not in front of": the housing's front face must be inside
	# the sphere's silhouette at its own depth, or a rim of it shows around the
	# lens from a shallow angle. The sphere's radius at depth `z` is
	# sqrt(1 - z^2) in lens radii.
	var near := _housing_lens_side_face()
	var lens_radius_there := sqrt(maxf(0.0, 1.0 - near * near))
	assert_true(
		float(OCCUPATION.HOUSING_RADIUS_RATIO) <= lens_radius_there + 0.001,
		"the housing is %.2f lens radii wide where the lens is only %.2f wide (at depth %.2f), so it shows around the lamp" % [
			float(OCCUPATION.HOUSING_RADIUS_RATIO), lens_radius_there, near]
	)


func test_the_housing_still_reaches_behind_the_lens() -> void:
	# The housing exists so a lamp reads as bolted to the stone rather than as
	# a glowing ball floating off the wall -- pushing it back far enough to stop
	# occluding must not push it inside the sphere entirely, or it stops doing
	# its job. Its back face has to emerge past the lens.
	assert_true(
		_housing_far_face() > 1.0,
		"the lamp housing's far face is at %.2f lens radii, inside the lens itself -- nothing mounts the lamp to the wall" % [
			_housing_far_face()]
	)
