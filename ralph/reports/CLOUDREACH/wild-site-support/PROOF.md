# Cloudreach wild sites `road_visibility_windscar_floor_loop_05/06` dropped as unsupported

Base: main 32bd33079. Probe: `tests/probe_cloudreach_wild_site_support.gd` boots
`cloudreach_cliffs.tscn` with the production runtime mounted (`Game.current_realm = "cloudreach"`),
takes the runtime's own `CloudreachEncounterDirector` and its resolved `wild_sites` (centres
re-grounded by `cloudreach_world_runtime.gd::resolved_encounter_data` → `_resource_position`), and
for each ground site spawns **every ordered species pair its table can roll** through the
production `spawn_wild` with the same offsets/anchor `_spawn_available_sites` uses.

## Root cause
Both sites were authored 5.5 m off the `windscar_floor_loop` centre line **over the
`windscar_chain_bridge` span** (polyline points 1→2 are the bridge). The runtime snaps them onto the
3.5 m chain deck segment surface, where no pair's 9-sample footprint and path check can pass, so
`_spawn_available_sites` fails the site closed ("Cloudreach wild site has unsupported placements").
A pair on the only ground route's bridge would also stand in the walker's way (the F07#2 stall site).

## Fix (data only, `data/config/cloudreach_encounters.json`)
| site | authored before | authored after | where |
|---|---|---|---|
| `_05` | (-481.94, 435.701, 2796.692) | (-524.85, 430.0, 2718.85) | bridge's west landing crown, 5 m from pad centre, away from road and bridge head |
| `_06` | (-417.456, 443.199, 2886.169) | (-422.384, 439.429, 2651.918) | approach road ribbon, 2.5 m off centre, opposite side from `_04`, between `_03` and `_04` |
Same table, count and radius; no draw-distance/budget change.

## Results
| | main | branch |
|---|---|---|
| ground wild sites supported (runtime-mounted probe) | 98 / 100 (`_05`, `_06` fail) | **100 / 100** (`failed_sites=0`) |
| `test_cloudreach_route_ledger`, `_route_cadence`, `_encounters`, `_chapter_data` | – | 37 tests / 6714 assertions / 0 failed |
| route ledger exit levels | – | 34 32 32 32 31 (lead target 33, others ≥ 30) |
| cadence longest gap (non-over-limit) | 320.0 m (`aftermath_overlook`) | 433.3 m (`maela_trial`, west landing → east landing across the chain bridge); over-limit set unchanged (bivouac 627 m) |

The cadence change is honest accounting: on main the two unspawnable sites on the span were
counted as cadence beats that never appear in play.

Note (bare-world probe caveat): without the runtime mounted, 69 sites "fail" because
`_resource_position` re-grounding has not run; that earlier reading was a probe artefact, not a
game defect. Files: `before_main_runtime.txt`, `after_branch_runtime.txt`,
`floor_loop_05_candidates.txt` (8 m pad point re-snaps beside the deck; 5 m and road points pass),
`cadence_main.txt`, `cadence_ledger_branch.txt`.
