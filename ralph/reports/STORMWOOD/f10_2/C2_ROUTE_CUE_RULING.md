# F10#2 C2: Capacitor Alpha under the interim route-cue ruling (option a)

Ruling: coordinator 5860078626, option (a): the body cannot be staggered during the route cue.
Harness: `tests/smoke_stormwood_b_named_c2c3.gd --seeds=24` (headless, --fixed-fps 60), unchanged. Bar: reader/masher lead-cost ratio <= 0.55.

| Variant | terrapup | ripplet | galewisp | Record |
|---|---|---|---|---|
| Before the ruling (88b921f3 regression record) | — | inf FAIL | 3.61 FAIL | `../b/f10_2` history |
| a1: cue hits drain poise to a 1-point floor | PASS | inf FAIL | 3.49 FAIL | `RUN_c2c3_route_cue_a.txt` (all-fight run; the other named fights were unchanged) |
| **a2 (kept): cue hits drain no poise** | **0.42 PASS** | **0.98 FAIL** | **0.71 FAIL** | `RUN_c2c3_route_cue_a2.txt` |
| a2 + poise_max 70 (rejected, reverted) | 0.40 PASS | 1.97 FAIL | 0.50 PASS | `RUN_c2c3_poise70_rejected.txt` |

a1 left the break one hit into the tell proper, so the masher still cancelled every dive. a2 is what the code now does (`wild_creature.gd::apply_poise_damage`). Raising poise_max traded galewisp for ripplet and was not monotonic, so it was reverted after the second tuning attempt (two-strike rule). Ripplet and galewisp remain over the bar; closing them needs a further rules/tuning decision, not more harness work.
