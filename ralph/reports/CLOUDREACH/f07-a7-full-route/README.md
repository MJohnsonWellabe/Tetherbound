# F07#2 / F07#3 full-route A7 — full live continuous chapter (fixture start, disclosed)

`tests/smoke_cloudreach_continuous.gd -- --accelerated --live-combat` from the
harness **fixture start** (declared Meadows-complete flags and a granted L25
five), running the whole live Cloudreach chapter by stick input. The earlier rows were
diagnosis under the old finish-then-land rule. Under the owner ruling of
2026-09-27 (#356), a fixture start and the other harness shortcuts are
disclosed, not disqualifying. `after-summit-camp/` is the run the F07#2 and
F07#3 closes cite.

| Run | Verdict | Stretches over the A7 120 s limit |
|---|---|---|
| `before/` (tb/cloudreach 02229683) | PASS, 15.9 km | **161.0 s** aftermath walk (Veyra deck → overlook); **152.0 s** bivouac → Veyra |
| `after-restored-gate/` | FAIL at the final reload check (see below) | **153.0 s** bivouac → Veyra only |
| `confirm-reload-instant/` | FAIL at the final reload check (first, wrong fix) | 152.3 s bivouac → Veyra only |
| `after-json-team-check/` (both fixes) | **PASS**, 15.9 km, live | **152.3 s** bivouac → Veyra only (open design item) |
| `after-summit-camp/` (camp moved, ruling (a)) | **PASS**, 14.8 km, live | **none** (longest 95.0 s; Windscar return longest 36.4 s over 43 intervals) |

**Aftermath walk (fixed).** `cloudreach_summit_restored_wild` was gated on
`cloudreach_winds_restored`. The finale sets that flag only on arrival at the
overlook (`cloudreach_finale_controller.gd::witness_restoration`), so the
aftermath pairs `summit_overlook_loop_02/03` could never appear on the walk to
it. With the table gated on `captain_veyra_defeated`, both pairs offer on the
walk: 02 at 3036 s and 03 at 3098 s. The 161 s gap is gone.
`tests/probe_cloudreach_aftermath_pairs.gd` shows both pairs spawn and offer
Engage once the gate holds.

**Bivouac → Veyra (fixed by coordinator ruling (a), #356).** The route runs:
1. feed → arena threshold (100, 5350);
2. 620 m west to the summit bivouac (-520, 5300);
3. rest;
4. 620 m back east to Veyra.

On the second pass every body along the corridor has already offered, and no
flag changes between the two passes. The options (move the camp, count re-passed
unfought pairs, or add a rest-dependent beat) are on #356.

**Reload check (harness fixed).** The final team check compared raw floats.
A damage-derived HP such as 50.739446608544 can differ in its binary tail bits
after the JSON save/load round trip while still serializing identically. The
exact field check just above it already treats that case as equal. The team
check now compares the JSON form too. (A first attempt that only moved the
check to the reload instant assumed HP regeneration was the cause; the
confirming run disproved that.)

**Summit camp moved (ruling (a)).** `summit_bivouac` now stands at
(132, 1160, 5342), on the threshold terrace 32 m east of the arena threshold
(`cloudreach_chapter.json` `_why_position_0927`). The finale's safe position
moved with it.
- **Choice.** Of six flat analytic candidates, it is the only one the ordinary
  route walker reached from both the summit feed road (76 s) and the threshold
  (10 s) (`tests/probe_cloudreach_summit_camp_reach.gd`).
- **Way back.** From the camp to the threshold the route runs south round the
  stronghold's east wall and in by the feed road's gap (12 s).
- **Harness waypoints (disclosed).** The continuous harness walks those waypoints
  after resting, because its route-snapping `_navigate` would aim at the loop's
  east leg, which climbs away beside the camp.
- **Results.** The data cadence model now has no known-open interval (route
  11.86 km, longest 63.5 s at walking pace). The route ledger passes: Veyra
  phase 555 m, exit L34 / L32 32 32 32.
