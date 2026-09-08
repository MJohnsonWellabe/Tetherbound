# Brine Steps ordinary ecology footing

Status: exact production rejection reproduced for sites 010/011 and nearby
supported candidates measured; no candidate coordinate has been applied or
proved through final production admission/player-path checks.

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

## Static warning, corrected by production evidence

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
changed no project data or production source. These deltas were initially
suspected to trip the 4 m stratum guard. The production run disproved that
specific mechanism: `water_encounter_runtime_data.gd::_grounded()` replaces a
ground site's authored Y with live `ground_height_at(x,z)` during setup. The
director therefore evaluated 010 at Y 37.3560 and 011 at Y 44.0364, not at the
raw JSON heights. The stale Y values are authoring evidence, not the live reason
admission failed.

The live failure is instead the subsequent physical footprint contract. Both
current analytic centre slopes are steeper than its ray-normal requirement
(`normal.y >= 0.7`, roughly a 45-degree ceiling), and each legal species has a
different real footprint. The production measurements below identify the exact
failing rays.

Production uses `body_radius() + WILD_FOOT_MARGIN`, with the inherited margin
equal to 0.25 m. The table's current body radii make the required diagnostic
radii 1.7375 m for Riptusk, 1.2825 m for Cragclaw and 1.44 m for Mangrove
Monitor. The targeted probe previously used 0.15 m only for its supplemental
sample/candidate telemetry; root corrected that helper to read the production
margin. Its actual `_find_wild_spawn()` calls already used the production
margin internally, so this correction does not reopen prior production
admission results.

## Production baseline and candidate measurement

The corrected targeted probe ran with an explicit unique engine log:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --log-file %TEMP%/water-brine-ordinary-footing-baseline.log --script tools/probe_water_salt_ordinary_footing.gd -- --site=water_brine_steps_wild_010,water_brine_steps_wild_011
```

For each exact site, retain the current production-plan verdict, all three
legal species' `_find_wild_spawn()` results, every production-radius footprint
ray (hit, normal and expected height), and the nearest fully supported
same-island candidate.

The probe exited 1, reproducing the intended baseline. Both sites entered
production `_site_failures`, with zero members against an expected count of
one. After seating each diagnostic body's centre at the current graded Y,
`_find_wild_spawn(body, centre, centre)` still returned `Vector3.INF` for all
three legal species. This proves the rejection is physical footing, not the
stale stored Y:

- Site 010's physical centre normal was 0.322. Depending on species footprint,
  perimeter height deltas reached +5.17/-4.61 m and multiple rays missed the
  production Terrain3D collision entirely.
- Site 011's physical centre normal was 0.652. Its rings included misses and
  normals below 0.7; the largest footprint ranged from -1.81 to +2.14 m around
  the centre.

The stable nearest-supported search produced these per-species measurements:

| Site | Species | Raw candidate XYZ | Supported seat Y | Move |
|---|---|---:|---:|---:|
| 010 | Riptusk | 323.616, 26.8183, 639.8845 | 27.1811 | 8 m |
| 010 | Cragclaw | 325.3501, 27.5085, 642.4799 | 28.3035 | 8 m |
| 010 | Mangrove Monitor | 325.3501, 27.5085, 642.4799 | 28.4528 | 8 m |
| 011 | Riptusk | 472.9207, 40.8542, 748.2255 | 42.1628 | 4 m |
| 011 | Cragclaw | 474.2184, 41.5379, 747.3585 | 42.6288 | 4 m |
| 011 | Mangrove Monitor | 472.9207, 40.8542, 748.2255 | 41.8982 | 4 m |

For each site, the Riptusk row is the largest-footprint candidate, but that
does not by itself prove smaller species at the same exact XZ: their perimeter
rays land at different points. The Riptusk 010 candidate is 1.894 m from the
exploration spine and at least 86.1 m from another Brine wild site; the 011
candidate is 6.228 m from the spine and at least 82.9 m from another site.
They are 113.9 m and 78.6 m from Tovin's reused production body respectively.
Those distances establish plausible route context, not player-path proof.

The engine and wrapper logs are:

```text
%TEMP%/water-brine-ordinary-footing-baseline-engine-20260908.log
%TEMP%/water-brine-ordinary-footing-baseline-stdout-20260908.log
```

The expected site warnings were present; scans found no `SCRIPT ERROR` or
`ERROR:`. A coordinate-only repair is justified only after one reviewed exact
coordinate per site is checked for all three species, then passes the unchanged
production admission loop and Tovin's ordinary route. No coordinate is claimed
fixed in this report.
