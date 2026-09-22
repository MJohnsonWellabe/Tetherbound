extends "res://tests/test_case.gd"

# The host resolves shared-fight geometry against its OWN copy of a remote
# body, never against the position the client claimed:
# `encounter_director.gd::_host_strike()` takes `striker.call("centre")` for
# the protocol's step-2 origin, and `remote_trainer.gd::_anchor_params()` reads
# `global_position` with a comment saying why.
#
# Both proxies are driven toward `_render_position` with `move_and_slide()`, so
# the host's own collision can pin the BODY while `_render_position` goes on
# tracking `net_position` perfectly. The original snap test compared only
# `_render_position` to `net_position`, so in exactly that case it never fired
# again and the body stayed where it snagged for the rest of the session.
#
# Measured consequence, before the fix: a guest seated 1.4 m from a shared
# opponent was held 8.86 m away by the host after 28 placements; the host
# ACCEPTED its strike -- valid receipt, right encounter, right peer id -- and
# scored `hit = false`, for 0 of 6 landed swings against a host that landed
# first try every time. See `ralph/reports/MEADOWS-PAYOFFS/tournament` and
# `ralph/reports/MEADOWS-PAYOFFS/river-sela-mill`.

const REMOTE_CREATURE := preload("res://scripts/creatures/remote_creature.gd")
const REMOTE_TRAINER := preload("res://scripts/net/remote_trainer.gd")

const SNAP_M := 6.0


func test_a_pinned_body_is_snapped_even_though_its_render_target_is_current() -> void:
	# The regression. The render target is on top of the owner -- interpolation
	# is working perfectly -- but the body is pinned metres away, which is the
	# position the host actually resolves a strike against.
	var owner_at := Vector3(-23.45, 2.23, -22.70)
	var render_at := owner_at
	var pinned_body := owner_at + Vector3(8.86, 0.0, 0.0)
	assert_true(REMOTE_CREATURE.needs_snap(render_at, pinned_body, owner_at, SNAP_M),
		"a body the host's collision has pinned 8.86 m from its owner must be placed, "
		+ "not left behind while its render target reports no error at all")


func test_an_ordinary_interpolating_proxy_is_not_snapped() -> void:
	# The case the snap must stay out of: both the render target and the body
	# are close behind the owner, which is just late packets.
	var owner_at := Vector3(10.0, 1.0, 10.0)
	assert_false(REMOTE_CREATURE.needs_snap(owner_at + Vector3(0.4, 0.0, 0.0),
		owner_at + Vector3(0.9, 0.0, 0.0), owner_at, SNAP_M),
		"ordinary interpolation lag must keep being smoothed rather than teleported")


func test_a_ground_offset_under_the_owner_is_not_a_snap() -> void:
	# A proxy standing on real ground sits a little below the replicated point.
	# That must never read as divergence.
	var owner_at := Vector3(0.0, 3.0, 0.0)
	assert_false(REMOTE_CREATURE.needs_snap(owner_at, owner_at - Vector3(0.0, 1.03, 0.0),
		owner_at, SNAP_M),
		"a metre of ground contact offset is not a pinned body")


func test_a_teleport_still_snaps_on_the_render_target_alone() -> void:
	# The original condition still has to hold: the owner jumped, and the body
	# happens to still be sitting on the render target.
	var owner_at := Vector3(500.0, 4.0, 500.0)
	var stale := Vector3(10.0, 4.0, 10.0)
	assert_true(REMOTE_CREATURE.needs_snap(stale, stale, owner_at, SNAP_M),
		"a teleport must keep snapping, which is what this test guarded before")


func test_the_trainer_proxy_uses_the_same_rule() -> void:
	# `remote_trainer.gd` reads the shared helper rather than restating it, so
	# the trainer and the creature cannot drift apart on this decision.
	var owner_at := Vector3(-330.97, 30.02, 429.29)
	var pinned := owner_at + Vector3(0.0, 0.0, 9.5)
	assert_true(REMOTE_TRAINER.REMOTE_CREATURE.needs_snap(owner_at, pinned, owner_at, SNAP_M),
		"a pinned trainer proxy refuses its peer's legitimate claims from a stale place")
