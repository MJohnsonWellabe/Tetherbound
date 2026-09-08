# Salt Crown ordinary ecology footing

Status: exact production failures reproduced; three coordinate-only repairs
passed strict production admission and all-table-species footing validation.

The late Water continuous run logged all three ordinary Salt Crown sites as
unsupported: `water_salt_crown_wild_011`, `_012` and `_013`. The focused probe
`tools/probe_water_salt_ordinary_footing.gd` reproduced the same result through
the unchanged production `WaterEncounterDirector` admission loop: all three
sites had zero members, all three entered `_site_failures`, and the probe exited
1. Baseline log:
`%TEMP%/water-salt-ordinary-footing-baseline.log`.

This was not a missing encounter table, random-roll failure or altered count.
Each exact site produced its one-member plan. Its authored centre instead sat
on a cliff-scale footprint: the centre collision normals were only 0.304,
0.434 and 0.530, perimeter rays missed terrain, and sampled height deltas reached
several metres across one creature footprint. `_find_wild_spawn` therefore
returned `Vector3.INF`, as production requires.

The probe measured the nearest fully supported same-island candidates without
changing species, table, count, radius, habitat, purpose or encounter identity:

| Site | Baseline XZ | Candidate XYZ | Move | Probe species | Minimum footprint normal |
|---|---:|---:|---:|---|---:|
| 011 | 78.421, 2214.587 | 75.35953, 38.30613, 2207.196 | 8m | Riptusk | 0.836 |
| 012 | 221.372, 2411.172 | 215.8287, 66.63486, 2413.468 | 6m | Sirenseal | 0.769 |
| 013 | 192.383, 2178.240 | 196.0785, 59.60575, 2179.771 | 4m | Riptusk | 0.721 |

The candidates remain well separated from other ordinary sites. Their nearest
authored neighbours are ROAD ecology at 11.84m, 23.89m and 39.24m respectively;
no count, roam radius or collision rule was changed. The JSON patch updates only
each exact row's matching world/local XYZ coordinates.

Final verdict: the rerun
`godot --headless --path . --log-file %TEMP%/water-salt-ordinary-footing-final.log --script tools/probe_water_salt_ordinary_footing.gd`.
exited 0. All three sites reached one production member (`members: 1`,
`expected: 1`) with no `_site_failures`. Every legal table species --
Sirenseal, Mosshell and Riptusk -- also found supported footing at every repaired
site under its real scaled footprint. The final summary was
`all_table_species_supported: true`, `sites: 3`, `failures: []`. A scan found no
`ERROR` or `SCRIPT ERROR` in the final log. The run took 14.2 seconds including
the preceding parser check; the runtime log is
`%TEMP%/water-salt-ordinary-footing-final.log`.
