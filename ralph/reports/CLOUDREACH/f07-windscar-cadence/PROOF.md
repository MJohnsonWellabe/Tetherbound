# F07#2 engine re-walk: the Windscar return (the measured 885-second no-action stretch)

The verifier rejected the batch-26 claim for three reasons:
- the "510 → 320 m" ruling figure appeared only in a commit message;
- the data model still showed the Windscar return at 1,276 m with no companion;
- there was no engine walk.

This page is that engine walk, timed.

**Witness:** `tests/smoke_cloudreach_f07_windscar_cadence.gd`.
- It uses the production scene, the real controller and the production encounter director.
- Fixture: post-shrine chapter flags, and the player placed once on the aerie dais after the return glide.
- The owned companion is deployed by real `creature_recall` input, as `smoke_cloudreach_deployed_cadence.gd` does. Without an ally body the director offers no wild Engage.
- The walk is the continuous harness's own `_navigate(Vector3(-720, 700, 3680))`, the call `smoke_cloudreach_continuous.gd` makes after `_return_to_aerie()`.
- "Action" means the harness's own `activity_intervals`: the first actionable offer of each source (each wild body's Engage separately), interactions, battles and flight.
- Gaps are measured in simulated seconds, and the A7 limit is 120 s.

Run on main 51d6dc44 + `tb/cloudreach`, 4 vCPU, accelerated clock:

| Mode | Walked | Wild Engage offers | Longest interval | Over 120 s | Verdict |
|---|---|---|---|---|---|
| shipped (`shipped.json`) | 1,740.7 m | 52 | **29.0 s** | none | PASS |
| control: without the 13 F07/F15 cadence pairs (`control_without_cadence_pairs.json`) | 1,740.9 m | 44 | 56.0 s | none | PASS |
| negative control: no wild offers counted (`control_without_wild_offers.json`) | 1,740.9 m | 0 | **184.0 s** | 1 | **FAIL** |

**What this shows:**
- The 885.87 s stretch (2026-09-05) is gone on the shipped route. The longest no-action interval on the whole aerie → counterweight walk is 29 s.
- The Windscar return's own ROAD pairs (`road_visibility_windscar_floor_loop_return_*`, `windscar_counterweight_return_*`) carry it even without the cadence pairs.
- With no wildlife counted, the same walk has a 184 s gap. That matches the data model's no-companion 1,276 m, and it proves the witness can fail.

**Scope:** this is the F07#2 leg only. F07#3 (every A7 interval on the whole route) still has open data-model gaps. Those gaps are listed in `tests/test_cloudreach_route_cadence.gd` `KNOWN_OPEN`: the bivouac spur, and finale → overlook.

**Route ledger:** refreshed in `ralph/reports/CLOUDREACH-LANE/f07-route-ledger/`. Exit is 34 / 32 32 32 31, meeting the targets.
