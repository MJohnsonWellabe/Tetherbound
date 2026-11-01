extends "res://tests/test_case.gd"

## Owner 31 Oct 2026, Cloudreach "big cylinders that don't touch the ground":
## the cliff-wall bulge case. With the flag on, a _mesa wall never overhangs
## going down or tucks under its crown edge.

const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const GROUNDING := preload("res://scripts/world/cloudreach_grounding.gd")


func test_flag_defaults_off() -> void:
	assert_false(bool(GROUNDING.read_config().get("monotonic_walls", true)),
		"monotonic_walls ships off until the GPU verdict")


func test_wall_pushes_never_overhang() -> void:
	var seeds := 0
	for seed_value in range(0, 400, 7):
		for step in 48:
			var angle := TAU * float(step) / 48.0
			var upper := 1.04 + 0.18 * sin(angle * 4.0 + seed_value)
			var lower := 1.24 + 0.27 * cos(angle * 3.0 - seed_value * 0.7)
			var bottom := minf(1.55 + 0.22 * sin(angle * 3.0 + seed_value),
				1.55 + 0.20 * cos(angle * 5.0 - seed_value))
			var pushes: Vector2 = WORLD.monotonic_wall_pushes(upper, lower, bottom)
			assert_true(pushes.x <= pushes.y + 1e-6, "upper ring must not overhang the lower ring")
			assert_true(pushes.y <= bottom + 1e-6, "lower ring must not overhang the bottom ring")
			assert_true(pushes.x >= 1.0 - 1e-6, "upper ring never tucks under the crown edge")
			assert_true(pushes.y <= maxf(lower, 1.0) + 1e-6, "lower ring never moves out past its own push")
			assert_true(pushes.x <= 1.22 + 1e-6, "upper ring stays inside its original range")
			seeds += 1
	assert_true(seeds > 0)
