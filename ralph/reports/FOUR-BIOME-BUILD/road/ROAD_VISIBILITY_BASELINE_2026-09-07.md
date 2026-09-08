# ROAD creature-visibility baseline — 2026-09-07

## Outcome

The new deterministic probe is valid, but the authored populations do not meet the
owner's “visibly multiple” road requirement. No spawn data was changed: closing the
measured gaps would require a broad population redistribution or substantial new
roadside populations, not a conservative local correction. That work must be paired
with the ROSTER result and judged in rendered frames before it can ship.

## Measured criterion

The probe follows the CP-2 rendered calibration already established in prompt 77
section 4. It samples each route continuously every 10 m. A body qualifies when:

- it is in the forward 180-degree horizontal cone;
- its projected height is at least 15 px in the shipped 720p, 70-degree view; and
- its projected height uses the empirical calibration `1 m = 15 px at 40 m`, scaled
  by that species' authored body height and inverse distance.

For a table-driven spawn, the probe uses the smallest legal species in the table.
This prevents a passing claim that depends on a favourable random roll. Meadows is
measured in the owner's fresh-game daytime, clear-weather case. Stormwood uses the
runtime's fixed two-body ordinary group size. The result is a projected authored-data
check, not a substitute for runtime occlusion or a blind frame verdict.

## Exact clean baseline

| Realm | Route | Samples | Failing | Longest failing run |
|---|---|---:|---:|---:|
| Meadows | band1_lower_meadows | 242 | 124 | 130 m |
| Meadows | band2_stone_and_root | 267 | 184 | 320 m |
| Meadows | band3_the_river_lock | 239 | 144 | 160 m |
| Meadows | band4_upper_meadows_ironwood | 345 | 182 | 200 m |
| Meadows | band5_stronghold_approach | 67 | 25 | 60 m |
| Cloudreach | arrival_gate_road | 92 | 92 | 920 m |
| Cloudreach | lower_cliff_road | 69 | 66 | 550 m |
| Cloudreach | broken_causeway_main | 187 | 187 | 1,870 m |
| Cloudreach | windscar_floor_loop | 179 | 171 | 1,640 m |
| Cloudreach | windscar_counterweight_pass | 192 | 192 | 1,920 m |
| Cloudreach | upper_summit_road | 155 | 155 | 1,550 m |
| Stormwood | ash_road | 261 | 225 | 670 m |
| Stormwood | conductor_road | 249 | 242 | 920 m |
| Stormwood | deepwood_road | 300 | 220 | 870 m |

The standalone probe exits 1 because every realm still has failing samples. It
emitted no `ERROR` or `SCRIPT ERROR` after the clean import completed.

## Verification

Godot 4.7 stable was used for all commands.

```text
godot --headless --path . --import
exit 0; 804 assets imported

godot --headless --path . --script tools/gate_f/probe_road_creature_visibility.gd
exit 1 by design; exact baseline above; no ERROR/SCRIPT ERROR

godot --headless --path . --script tests/run_tests.gd -- --only=test_road_creature_visibility.gd
2 tests, 63 assertions, 0 failed
```

The unit test proves the CP-2 calibration directly and records the current baseline,
so an accidental route/table change is visible. When population data is repaired,
the snapshot must be deliberately replaced by the real zero-failure gate; the
standalone probe is already that gate.

## Dependency and stop condition

- Meadows has 659 failing samples across its five roads. Even an ideal fixed 2.1 m
  pair reads only about 84 m away under CP-2. The gaps are repeated across roughly
  11.6 km of route, so a handful of moved clusters cannot meet the bar. Broadly
  moving current clusters would strip off-road ecology; duplicating enough pairs
  would materially raise population and update cost.
- Cloudreach has only six authored wild sites (twelve bodies) for the grounded main
  spine. The runtime site format has no fixed-species override, while its legal table
  rows are owned by ROSTER. Nearly the entire spine fails.
- Stormwood's authored grid and fixed pair size still leave 687 failing samples. Its
  conservative projected range depends on table minima, also a ROSTER dependency.

Therefore ROAD stops at a reviewable measurement tool rather than shipping a
pathological density change. The next content pass needs the final roster, targeted
authored visible anchor pairs that preserve off-road populations, then runtime
active/occlusion validation and an independent blind frame judge.

## Import side effects observed and removed

The first clean Godot 4.7 import rebuilt all 804 assets and rewrote hundreds of
tracked `.import` sidecars, plus generated untracked `.uid` files. The committed
sidecars therefore differ from this worktree's current importer/version/settings
state. Those changes were unrelated to ROAD and were restored/removed before this
commit. BUILD-SIZE should account for this importer churn when changing texture
compression and should review only intentional sidecar deltas.
