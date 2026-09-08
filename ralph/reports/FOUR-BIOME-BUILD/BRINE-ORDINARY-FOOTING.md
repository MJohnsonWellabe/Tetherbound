# Brine Steps ordinary ecology footing

Status: exact source-level rejection mechanism identified for sites 010/011;
production candidate coordinates remain unmeasured and unproven.

## Observed production failure

The ordinary opening-to-Brine run reached Brine Steps through the real human
crossing, then production emitted footing/admission warnings for:

- `water_brine_steps_wild_010`
- `water_brine_steps_wild_011`

Evidence: `%TEMP%/water-opening-brine-first.log`, lines 51-63. The warnings
originate at `water_encounter_director.gd::_spawn_available_sites`, where a
site is marked failed unless its plan count and successfully spawned member
count both equal the authored count.

These rows are ordinary one-member land sites with no named replacement. Their
`water_brine_steps_land` table is non-empty and has positive weights for
Riptusk, Cragclaw and Mangrove Monitor. `site_spawn_plans()` therefore produces
one deterministic plan for every seed; there is no missing-table or named-link
explanation here.

## Exact source-level mechanism

Both authored rows still carry the explicit status
`analytic_spawn_footprint_only_arena_and_navigation_unproven`. Their stored Y
and slope describe the pre-grading radial island surface, but both XZ positions
sit about 9.5 m off the authored `brine_steps_exploration_spine`. The current
heightfield applies the spine's feathered trail grade there.

A lightweight call to the same production `water_heightfield.gd` produced:

| Site | Stored Y | Current graded Y | Delta | Current analytic slope |
|---|---:|---:|---:|---:|
| 010 | 53.5604 | 37.3555 | -16.2049 m | 70.6883 degrees |
| 011 | 50.1310 | 44.0235 | -6.1075 m | 49.0980 degrees |

The temporary read-only probe was removed after recording these values; it
changed no project data or production source.

This is already sufficient to explain both observed rejections.
`water_encounter_director.gd::_wild_support_impl()` rejects before ray/footprint
evaluation when `abs(ground - authored_y) > WILD_STRATUM_TOLERANCE`; the
tolerance is 4 m. Both deltas exceed it. Merely updating Y would still be
insufficient evidence: both current analytic centre slopes are steeper than
the subsequent physical-ray normal requirement (`normal.y >= 0.7`, roughly a
45-degree ceiling), and each of the three legal species has a different real
footprint.

Production uses `body_radius() + WILD_FOOT_MARGIN`, with the inherited margin
equal to 0.25 m. The table's current body radii make the required diagnostic
radii 1.7375 m for Riptusk, 1.2825 m for Cragclaw and 1.44 m for Mangrove
Monitor. The targeted probe previously used 0.15 m only for its supplemental
sample/candidate telemetry; root corrected that helper to read the production
margin. Its actual `_find_wild_spawn()` calls already used the production
margin internally, so this correction does not reopen prior production
admission results.

## Required production measurement

Do not move either row from the analytic numbers above alone. After the current
player-path world run releases the serialized Terrain3D slot, run the corrected
targeted probe with an explicit unique engine log:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --log-file %TEMP%/water-brine-ordinary-footing-baseline.log --script tools/probe_water_salt_ordinary_footing.gd -- --site=water_brine_steps_wild_010,water_brine_steps_wild_011
```

For each exact site, retain the current production-plan verdict, all three
legal species' `_find_wild_spawn()` results, every production-radius footprint
ray (hit, normal and expected height), and the nearest fully supported
same-island candidate. A coordinate-only repair is justified only after that
candidate is also checked against the authored exploration spine, other nearby
encounters and Tovin's ordinary approach, then passes the unchanged production
admission loop. No coordinate is claimed fixed in this report.
