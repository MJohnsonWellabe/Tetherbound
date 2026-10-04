# F17#2 and F17#3 re-proof — R1 (tb/f17)

Base: origin/tb/integration 826d273c3 plus tb/f17 test fixes (commit 09efb3b4). Headless,
Godot 4.7-stable, parsed joypad move/look, real collision; one disclosed initial farmhouse placement.

## F17#2 Hall circuit — PASS

    godot --headless --path . --script tests/smoke_crossing_hall_circuit.gd   # exit 0

`hall-circuit.txt`: farmhouse door → Main Street → nave, then all 8 arches and all 8 pedestals reached
on floor within 0.75 m. **0 sidesteps.**

The first re-run on unchanged code also passed but logged two sidesteps, at (116.1, 17.4) after
arch biome5 and at (106.6, 12.1) before the shrine doorway, with no body or blocker nearby. Both came
right after a 160–170° reversal: the walker's 1.5 s stall clock counted turning in place. The fix
(tests/smoke_crossing_hall_circuit.gd `_walk_to_target`) faces each leg with the look stick before
walking, so a stall now means blocked movement. No tolerance changed.

## F17#3 village services, day and night — PASS

    godot --headless --path . --script tests/smoke_village_services_redesign.gd   # exit 0

`services-day-night.txt`: eight unique lived-in houses; Mira, Tam, Bram, Oskar, Maren, Halda and
the tournament board reached with their prompts winning, day and night.

The first re-run on unchanged code FAILED: "no progress for 3.0s at (78.6, 28.4)" on the day
tournament-keeper leg. The leg went road → (arena.x = 78, road) → arena, which runs exactly along
the orchard house's west wall (collider x 77.8–78.2, z 22.8–29.2). Earlier runs slid along the
outside of the wall; this one went in through the door and stalled at the back wall. A physics
shape probe showed that the column at x ≤ 77.3 is clear. The fix (`_clear_column`) walks the
nearest column that the actual static colliders leave clear; here x = 76.5. No tolerance changed.
