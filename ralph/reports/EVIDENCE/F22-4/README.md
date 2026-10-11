# F22#4: named fights on the new timings, C2 (tb/ev-systems-a)
Command: `godot --headless --path . --fixed-fps 60 --script tests/smoke_f22_pattern_bands.gd -- --seeds=24 --named=<id> --json=<out>`
Pilots: MASHER, READER, SWITCH_READER. Gear: bare. Fixture: flat collider.
Top-trainer bar (COMBAT §7): reader win ≥.75; the masher loses its lead in every run; reader party cost ≤.55× the masher's.

## Veyra (captain_veyra_storm_anchor), 4c74585e5, 15:35–17:02 CT: FAIL
| Starter | reader win | masher lead-faint | party cost reader / switch / masher | verdict |
|---|---|---|---|---|
| terrapup | 1.00 | 0.00 | 0.063 / 0.063 / 0.124 | FAIL: the masher kept its lead |
| ripplet | 1.00 | 1.00 | 0.209 / 0.072 / 0.289 | PASS |
| galewisp | 1.00 | 1.00 | 0.142 / 0.053 / 0.251 | PASS |

- Switch value is partial: the F24 tag combo is off. Switched party cost is 0.063 against 0.139 fixed.
- Rows are in `veyra_storm_anchor_rows.json`.

## Marrow (captain_marrow_dynamo_core): pending
- A worker restart at about 17:10 CT killed the 15:35 run.
- It restarted at 17:11 CT on 17f33eec9. The only changes since 4c74585e5 are evidence files, the `--policies` option and the route helper; the band smoke reads none of them.

C3 for these fights comes from the capture lane (CAPTURE-READY to follow when both rows are in).
