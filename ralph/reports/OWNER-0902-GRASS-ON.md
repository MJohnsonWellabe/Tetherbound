# OWNER-0902-GRASS-ON — grass field flipped on, per direct owner directive

`branch: ralph/OWNER-0902-GRASS-ON` · `owner directive: 2026-09-02, verbatim "grass needs to be on"` ·
`harness: tests/run_tests.gd --only=grass_field, tests/smoke_playground.gd, tools/perf_render_stats.gd`

## What changed

`data/config/grass_field.json`'s `enabled` flag: `false` -> `true`. Nothing
else in the file changed. This is a direct owner instruction, not a tuning
call — the prior investigation (`ralph/OWNER-0902-GRASS-RENDER`, landed on
`main` at `d905a0a8`) had already measured and prepared exactly the config
this flips: `tuft_count` 75000, `blades_per_tuft` 4, `blade_segments` 3,
`stones.count` 25000, and the three `cover_tiers` cut 2.5-3.3x — a ~5x
primitive cut against the config that produced the owner's ~10fps
game-breaker report on 2026-09-01, landed unshipped ("enabled stays false...
turning it on is still the owner's call") pending exactly the instruction
this branch now acts on.

A dated comment (`_comment_enabled_ownerplaytest_20260902b`) records the
directive in place, overriding the "still the owner's call" language the
prior note left standing — that call has now been made.

## Verification

**Tests.** `tests/run_tests.gd --only=grass_field`: 10 tests, 63 assertions,
0 failed. The suite's own flag-agnostic test
(`test_the_flag_and_the_suppression_list_agree`) exercises the `enabled=true`
branch for the first time under this flip and passes — the suppression list
(`grass`, `flowers`) still matches `suppressed_layers()` exactly.

**World stand-up.** `tests/smoke_playground.gd` (full run, ~4 minutes
headless): the world boots, the player lands on collision, and the full
smoke path (build, chop/gather, recall prompts, berry farm) completes —
`smoke: OK`. Nothing in the flip broke world stand-up; `[vegetation] grass
field is on; 440318 placements across 2 layers left unbuilt (grass,
flowers)` confirms the suppression is taking effect as designed rather than
double-drawing both systems.

**Primitive count**, `tools/perf_render_stats.gd` at `band1_open`, re-run on
this exact final state (fresh Godot 4.7-stable fetch, fresh import, same
bake):

| config | primitives |
|---|---|
| `enabled: false` (previously shipped) | 9,204,537 (OWNER-0902-GRASS-RENDER) |
| `enabled: true`, this branch's final state | 13,596,583 |
| `enabled: true`, OWNER-0902-GRASS-RENDER's own measurement of the identical config | 13,692,485 |

13,596,583 vs. 13,692,485 is within run-to-run noise from the lattice's own
jitter (`[grass_field] grass ring: 78312 instances... (tuft_count asked for
75000)` — the lattice layering doesn't hit the exact requested count every
run). Confirms flipping the flag did not change what config it submits:
same numbers the prior investigation measured and prepared this flag for.

**Render.** A player-eye-level shot at `band1_open`
(`ralph/reports/OWNER-0902-GRASS-ON/shots/band1_eye_level_grass_on.png`,
captured with the new `tools/_capture_grass_on_band1_open.gd` — same site
coordinates `perf_render_stats.gd` uses for `band1_open`, dropped to a
standing 1.7m eye height instead of that tool's elevated LOD-survey height)
shows real, legible grass: visible tufts and blades at multiple distances
around the player, ground-cover clumps, small white and purple flowers, and
scattered field stones — not a bald or broken field.

## What this is not

Same standing limitations the prior investigation recorded, unchanged by
this flip: `PERF-ROG-GPU` still holds — no container in this project can
measure real GPU frame time on the Ally, and that is the one measurement
that actually decided the 2026-09-01 ~10fps game-breaker. This flip is not a
claim that the Ally will run this well; it is the owner's explicit,
verbatim instruction to ship the on state now, on the numbers already
measured ~5x cheaper than what broke it. Actual per-instance/tile distance
culling (the architectural fix both prior grass reports name) is still
unbuilt. If a future handheld pass says this is still too expensive, the
next lever is the config numbers this same flag already reserves — not a
revert of the flag itself, and the file's own comment records the older,
denser numbers separately in case the owner ever wants those back instead.

## Files changed

- `data/config/grass_field.json` — `enabled: false` -> `true`, one new
  dated comment.
- `tools/_capture_grass_on_band1_open.gd` — new, small purpose-built capture
  script for the player-eye-level shot above.
- `ralph/reports/OWNER-0902-GRASS-ON/shots/band1_eye_level_grass_on.png` —
  the render.
