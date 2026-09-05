extends "res://tests/test_case.gd"

## The boxes the route strip measures its subjects with, against the real
## `species.json` numbers and the real arena geometry.
##
## W01-ROUTE-STRIP run 5: every bearing of a galecrest fight was refused for
## "overlap on screen by 74-80% of the smaller one", and nothing was actually
## hidden. The strip was sizing each creature's box the way
## `_capture_life.gd`'s bbox check does -- `radius * max(1, footprint_allowance
## * 0.65)` -- and `footprint_allowance` is a spawn-spacing number, not a
## visual width: it turns a galecrest's 1.30 m body into a 3.55 m box, so two
## creatures standing a fight apart overlap as boxes while nothing overlaps in
## the picture. A height fraction tolerates that error; an occlusion test does
## not, and the frame the run refused was a frame worth keeping.
##
## These tests read the shipped species data rather than fixtures, so a future
## edit to a creature's radius or allowance is measured here rather than
## discovered by a refused capture thirty minutes into a render.

const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const FOV := 70.0
const SIZE := Vector2(1280.0, 720.0)
## `data/config/combat.json` arena.separation -- where `_place_fighters()`
## stands the two fighters when a fight opens.
const ARENA_SEPARATION := 5.0
## What a fight has closed to by the time a capture's camera settle is over,
## measured by `tools/_capture_combat_moments.gd` ("a real fight was measured
## sitting at ~2m by the time these shots fire, not 5m").
const CLOSED_IN := 2.0


func _box(species_id: String, at: Vector3) -> AABB:
	var placeholder: Dictionary = SPECIES.placeholder(species_id)
	return CAPTURE_CHECK.body_box(at, float(placeholder.get("height", 1.0)),
		float(placeholder.get("radius", 0.4)))


## A camera `back` metres from the origin on +Z, looking at the origin, eye
## `up` metres above the ground the bodies stand on.
func _camera(back: float, up: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0.0, up, back)).looking_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)


func test_a_creature_box_is_its_own_body_not_its_spawn_allowance() -> void:
	# galecrest: radius 0.65, footprint_allowance 4.2. The body is 1.30m wide.
	var box := _box("galecrest", Vector3.ZERO)
	assert_almost_eq(box.size.x, 1.30, 0.01, "the box is two radii wide, not a spawn footprint")
	assert_almost_eq(box.size.z, 1.30, 0.01)
	var placeholder: Dictionary = SPECIES.placeholder("galecrest")
	assert_true(float(placeholder.get("footprint_allowance", 0.0)) > 3.0,
		"this species really does carry a large allowance, or this test proves nothing")
	assert_almost_eq(box.size.y, float(placeholder.get("height", 0.0)), 0.01)
	assert_almost_eq(box.position.y, 0.0, 0.01, "a standing body's box starts at the ground")


func test_two_fighters_at_the_arenas_own_separation_do_not_read_as_overlapping() -> void:
	var ally := {"name": "companion:terrapup", "aabb": _box("terrapup", Vector3(0.0, 0.0, 0.0))}
	var wild := {"name": "opponent:galecrest", "aabb": _box("galecrest", Vector3(ARENA_SEPARATION, 0.0, 0.0))}
	# Broadside: the camera is off to the side of the line between them, which
	# is the bearing the strip tries first for exactly this reason.
	var cam := _camera(9.0, 2.4)
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(cam, FOV, SIZE, [ally, wild])
	assert_eq(problems.size(), 0, str(problems))


func test_two_fighters_closed_to_melee_still_do_not_read_as_overlapping() -> void:
	# The run-5 case: the AI has closed the gap, and the frame is still honest.
	var ally := {"name": "companion:terrapup", "aabb": _box("terrapup", Vector3(0.0, 0.0, 0.0))}
	var wild := {"name": "opponent:galecrest", "aabb": _box("galecrest", Vector3(CLOSED_IN, 0.0, 0.0))}
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(6.2, 2.4), FOV, SIZE, [ally, wild])
	assert_eq(problems.size(), 0, str(problems))


func test_one_fighter_directly_behind_the_other_is_still_reported() -> void:
	# The rule must keep catching what it was written for: the same two bodies,
	# one standing behind the other along the camera's own axis.
	var ally := {"name": "companion:terrapup", "aabb": _box("terrapup", Vector3(0.0, 0.0, 0.0))}
	var wild := {"name": "opponent:galecrest", "aabb": _box("galecrest", Vector3(0.0, 0.0, -CLOSED_IN))}
	var problems: Array[String] = CAPTURE_CHECK.readable_problems(_camera(6.2, 2.4), FOV, SIZE, [ally, wild])
	assert_eq(problems.size(), 1, str(problems))
	assert_true(problems[0].contains("overlap on screen"), problems[0])

