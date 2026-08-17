extends "res://tests/test_case.gd"

## MQ1B. `character_model.gd::apply_terrain_adaptation()` is pure Node3D
## transform math over plain floats — no `_art`, no `AnimationPlayer`, no
## scene tree needed — so it is cheap to pin here the same way
## `test_gait_anatomy.gd` pins the baked clips' own anatomy. Exists because a
## first version of this method double-negated its own sign (pre-negated the
## lean target AND negated again at the rotation write, which cancelled out
## to the WRONG sign — the body leaned away from a climb instead of into
## it) and nothing but a render caught it. This test is the regression
## guard a render pass cannot be, every push, in milliseconds.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")

var _model: Node3D = null


func before_each() -> void:
	_model = Node3D.new()
	_model.set_script(CHARACTER_MODEL)


func after_each() -> void:
	if _model != null:
		_model.free()
		_model = null


## Cresting a rise dead ahead (h_forward > h_back, h_left == h_right): the
## body must pitch FORWARD into the climb. `character_model.gd`'s own
## apply_momentum_tilt() comment fixes the rig's convention: forward lean is
## NEGATIVE rotation.x on this +Z-facing model.
func test_climbing_a_rise_pitches_the_body_forward() -> void:
	for i in 30:
		_model.call("apply_terrain_adaptation",
			0.0, 1.0, 1.0, 1.2, 1.0,   # centre_delta, h_left, h_right, h_forward, h_back
			0.18, 0.22, 1.0 / 60.0, {})
	assert_true(_model.rotation.x < -0.01,
		"climbing a rise must pitch the body forward (negative rotation.x); got %.4f" % _model.rotation.x)


## The mirror case: ground falling away ahead (descending) must pitch the
## body BACKWARD (positive rotation.x) — a hiker leans back on a downhill,
## not forward into empty air.
func test_descending_pitches_the_body_backward() -> void:
	for i in 30:
		_model.call("apply_terrain_adaptation",
			0.0, 1.0, 1.0, 0.8, 1.0,
			0.18, 0.22, 1.0 / 60.0, {})
	assert_true(_model.rotation.x > 0.01,
		"descending must pitch the body backward (positive rotation.x); got %.4f" % _model.rotation.x)


## Dead flat ground on every probe: no lean, ever — the neutral case must
## stay neutral, not drift from floating-point noise or a stray default.
func test_flat_ground_produces_no_lean() -> void:
	for i in 30:
		_model.call("apply_terrain_adaptation",
			0.0, 1.0, 1.0, 1.0, 1.0,
			0.18, 0.22, 1.0 / 60.0, {})
	assert_almost_eq(_model.rotation.x, 0.0, 0.001)
	assert_almost_eq(_model.rotation.z, 0.0, 0.001)


## A NAN probe (no ground under a sample point — a doorway, a cliff edge)
## must be a no-op, never a lurch toward a garbage angle.
func test_nan_probe_is_a_no_op() -> void:
	_model.call("apply_terrain_adaptation",
		0.0, NAN, 1.0, 1.0, 1.0,
		0.18, 0.22, 1.0 / 60.0, {})
	assert_almost_eq(_model.rotation.x, 0.0, 0.0001)
	assert_almost_eq(_model.rotation.z, 0.0, 0.0001)


## The lean must never exceed movement.json's own configured limit, however
## extreme the probe geometry -- a cliff edge must clamp, not snap the model
## onto its face.
func test_pitch_never_exceeds_the_configured_limit() -> void:
	for i in 60:
		_model.call("apply_terrain_adaptation",
			0.0, 1.0, 1.0, 50.0, 1.0,   # an absurd, cliff-edge probe delta
			0.18, 0.22, 1.0 / 60.0, {"terrain_pitch_limit_deg": 18.0, "terrain_lean_scale": 1.0})
	assert_true(absf(rad_to_deg(_model.rotation.x)) <= 18.0 + 0.01,
		"pitch exceeded its own configured limit: %.2f deg" % rad_to_deg(_model.rotation.x))


## Root height settles toward the ground under the model's own feet, and
## never past its own clamp (a kerb-sized bump, not a floor detaching from
## the capsule that carries it).
func test_height_settles_toward_ground_and_stays_clamped() -> void:
	for i in 30:
		_model.call("apply_terrain_adaptation",
			0.08, 1.0, 1.0, 1.0, 1.0,
			0.18, 0.22, 1.0 / 60.0, {})
	assert_almost_eq(_model.position.y, 0.08, 0.005)

	_model.position.y = 0.0
	for i in 60:
		_model.call("apply_terrain_adaptation",
			5.0, 1.0, 1.0, 1.0, 1.0,   # an absurd centre_delta
			0.18, 0.22, 1.0 / 60.0, {})
	assert_true(_model.position.y <= 0.12 + 0.001,
		"height offset exceeded its own +-0.12m clamp: %.4f" % _model.position.y)
