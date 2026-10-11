# F47#1 — essence/material ledgers: no mandatory grinding; optional grinding measurably speeds progress — FAIL (regression)

systems-a, Sun 11 Oct 2026 ~12:45 PM CT. Commands (Node 22, no Godot):
`node --test tests/test_f27_route_ledger.mjs tests/test_economy_ledger.mjs tests/test_economy_difficulty.mjs` and `node tools/f27_route_ledger.mjs`.

| Commit | Tests | mandatory_repeat_grinding | optional_grind_faster_every_biome | Cloudreach reached | Stormwood grind lvl/h |
|---|---|---|---|---|---|
| `c0f02fca` (before the Cloudreach XP change) | 7/7 route-ledger pass | false | **true** | L44.8 | 2.2 |
| `bd3c20ba` (merged tb/ev-coordinator incl. `0d323864` Senn/Maela XP) | 21/22; FAIL `optional grinding pays in every biome…: stormwood grind rate` | false | **false** | L50 | 0 |

- Half 1 holds: no checkpoint deficit (break-even engagement of wild sites 0.38).
- Half 2 fails after `0d323864`. The ordinary path now reaches Stormwood entry at L50 (target 42) and hits the L60 pass ceiling before the exit (target 55). Grinding in Stormwood can add no levels, so no Stormwood loop is "measurably faster".
- The ledger's own findings list the same overshoot: tidewake_entry 24 vs 20, cloudreach_entry 34 vs 31, stormwood_entry 50 vs 42, finale 60 vs 54.
- Fix belongs to F47 curve tuning or to the Cloudreach XP lane's bonus sizes; it is not an evidence-lane change.

Disclosed: arithmetic ledger on authored data, `acceptance_verified:false` by design; no real-route stock measured (the gap's "observed route stock" input does not exist yet).

Verdict: FAIL
