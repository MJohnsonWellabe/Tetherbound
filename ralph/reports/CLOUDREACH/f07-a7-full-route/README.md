# F07#3 full-route A7 — DRY RUN — does not count

`tests/smoke_cloudreach_continuous.gd -- --accelerated --live-combat` from the
harness **fixture start** (declared Meadows-complete flags and a granted L25
five), running the whole live Cloudreach chapter by stick input. Under the
2026-09-27 finish-then-land rule these runs are diagnosis, not proof.

| Run | Verdict | Stretches over the A7 120 s limit |
|---|---|---|
| `before/` (tb/cloudreach 02229683) | PASS, 15.9 km | **161.0 s** aftermath walk (Veyra deck → overlook); **152.0 s** bivouac → Veyra |
| `after-restored-gate/` | FAIL at the final reload check (see below) | **153.0 s** bivouac → Veyra only |
| `confirm-reload-instant/` | FAIL at the final reload check (first, wrong fix) | 152.3 s bivouac → Veyra only |
| `after-json-team-check/` (both fixes) | **PASS**, 15.9 km, live | **152.3 s** bivouac → Veyra only (open design item) |

**Aftermath walk (fixed).** `cloudreach_summit_restored_wild` was gated on
`cloudreach_winds_restored`. The finale sets that flag only on arrival at the
overlook (`cloudreach_finale_controller.gd::witness_restoration`), so the
aftermath pairs `summit_overlook_loop_02/03` could never appear on the walk to
it. With the table gated on `captain_veyra_defeated`, both pairs offer on the
walk: 02 at 3036 s and 03 at 3098 s. The 161 s gap is gone.
`tests/probe_cloudreach_aftermath_pairs.gd` shows both pairs spawn and offer
Engage once the gate holds.

**Bivouac → Veyra (open, design).** The route runs:
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
