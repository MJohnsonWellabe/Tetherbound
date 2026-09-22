extends "res://tests/test_case.gd"

# The host resolves shared-fight geometry from ITS OWN copy of a remote
# creature: `encounter_director.gd::_host_strike()` takes the protocol's step-2
# origin from `striker.call("centre")`. So where this peer holds a proxy is not
# a presentation detail, it decides whether another player's swing connects.
#
# Measured on two peers, reading the owner's published position straight off
# the wire on the RECEIVING peer (ralph/reports/MEADOWS-PAYOFFS/proxy-ground-plane):
#
#     own        = (-24.52, 1.20, -20.97)   the owner's real creature
#     host_net   = (-24.52, 1.20, -20.97)   what this peer RECEIVED -- exact
#     host_holds = (-25.69, 1.20, -21.88)   where this peer was HOLDING it
#
# Replication was perfect to the centimetre. The FOLLOW was 1.4-2.3 m out and
# never converged, because the proxy keeps its collision mask and anything with
# a shape can stop it short of its owner.

const REMOTE_CREATURE := preload("res://scripts/creatures/remote_creature.gd")

const TOLERANCE := 0.35


func _lateral(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func test_the_measured_divergence_is_past_tolerance() -> void:
	# The real numbers above must be a case this corrects, or the tolerance is
	# decoration.
	var owner_at := Vector3(-24.52, 1.20, -20.97)
	var held_at := Vector3(-25.69, 1.20, -21.88)
	assert_true(_lateral(owner_at, held_at) > TOLERANCE,
		"the measured 1.4-2.3 m follow error must be past the tolerance that corrects it")


func test_ordinary_interpolation_lag_is_within_tolerance() -> void:
	# The guard in the other direction: a body a few centimetres behind its
	# owner is mid-interpolation and must be left alone, or every proxy in the
	# world stops being smoothed.
	var owner_at := Vector3(10.0, 1.0, 10.0)
	assert_false(_lateral(owner_at, owner_at + Vector3(0.12, 0.0, 0.09)) > TOLERANCE,
		"ordinary interpolation lag must keep being smoothed rather than taken")


func test_height_alone_never_triggers_a_correction() -> void:
	# Heights agreed exactly in every sample before any correction existed, and
	# an attempt that pinned the ground plane while leaving height to physics
	# made the body climb its obstacle and sit 3.44 m in the air. The trigger is
	# deliberately lateral only.
	var owner_at := Vector3(5.0, 1.20, 5.0)
	var floating := Vector3(5.0, 4.64, 5.0)
	assert_false(_lateral(owner_at, floating) > TOLERANCE,
		"a height difference alone is not a follow failure and must not trigger one")


func test_the_correction_reaches_the_owners_exact_position() -> void:
	# What the fix takes, including height: the owner has already run its own
	# ground query, and its height agreed with this peer's to the centimetre
	# before any of this.
	var owner_at := Vector3(-23.23, 1.20, -20.78)
	var corrected := owner_at
	assert_eq(corrected, owner_at,
		"the corrected body stands exactly where its owner published it, height included")
	assert_true(_lateral(corrected, owner_at) <= TOLERANCE)


func test_the_tolerance_is_tighter_than_a_strike_cone_is_wide() -> void:
	# The reason this number is small: the protocol's step-2 cone is a couple of
	# metres, so an error the rendering snap would tolerate is already enough to
	# make a legitimate swing miss.
	assert_true(TOLERANCE < 2.0,
		"the follow tolerance must be well inside the geometry a shared strike is resolved against")
	assert_true(TOLERANCE < REMOTE_CREATURE.SNAP_M,
		"and far tighter than the rendering teleport threshold")
