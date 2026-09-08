# Brine Steps ordinary ecology footing

Status: original rejection reproduced for 010/011. Both common candidates now
pass fresh authored admission and all-species footing. Site 010's ordinary
approach failed; its candidate is rejected and original row restored. Site
011's independent human walk reached its stance but produced no Engage offer.
Both authored rows are restored; no completed repair is claimed.

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

## Common-coordinate diagnostic (not final admission proof)

The fixture-disclosed diagnostic `tests/smoke_water_brine_candidate_footing.gd`
searched the live production world for one exact XZ per rejected site that
supports all three legal species at the inherited production margin. It also
required at least 4.9875 m from the authored exploration-spine centre (player
radius + Riptusk radius + the full 2.5 m roam radius + 0.6 m), then walked the
affected road segment with a real-size inert Riptusk seated at the candidate.

Two reproducible runs selected the same candidates:

| Site | Candidate ground XYZ | Route clearance | All-species direct/spawn | Ordinary spine walk |
|---|---:|---:|---|---|
| 010 | 340.8148, 58.2118, 638.7739 | 19.1203 m | 3/3 pass | pass, 1.259 m final gap, 0 resets |
| 011 | 473.6123, 41.1299, 747.8559 | 6.7376 m | 3/3 pass | pass, 1.249 m final gap, 0 resets |

The second run used:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --log-file %TEMP%/water-brine-common-candidate-engine-20260908-r2.log --script tests/smoke_water_brine_candidate_footing.gd
```

Wrapper output is `%TEMP%/water-brine-common-candidate-stdout-20260908-r2.log`.
It exited 1 at the final admission assertion, and that result is not evidence
against the candidates. The inherited director's `_ready()` first awaits a
process frame and `_spawn_creatures()` then awaits a physics frame. The harness
waited only one physics/process pair after Water reported shell-ready. The
director's pending initial spawn resumed later, after the diagnostic had moved
the player onto the original 010 route but before the in-memory candidate was
installed. Original 010 therefore entered the director's deliberately sticky
`_site_failures`; `water_encounter_director.gd::_spawn_available_sites()` then
correctly skipped the same ID during the final candidate call. Both runs show
the backtrace `_spawn_creatures -> _spawn_available_sites` before the successful
walk records, followed by `failed=true`, `members=0` for 010.

Next proof must wait for `population_ready` while the player remains at First
Shore and then assert both target IDs are pristine before moving, or use fresh
fixture-only duplicate IDs that preserve the production plan semantics. It must
not clear `_site_failures`, because that would bypass the fail-closed gameplay
contract. No encounter coordinate has been edited or claimed production-ready.

## Wave 5: fresh authored admission and actual shelf approach

Both common candidates were installed in authored JSON before constructing a
fresh isolated Water world. Existing `tools/probe_water_salt_ordinary_footing.gd`
with `--site=water_brine_steps_wild_010,water_brine_steps_wild_011` passed exit 0:
both IDs spawned exactly one member, neither entered `_site_failures`, and all
three permitted species passed the inherited production footprint admission.
No failure state was cleared. Logs:
`.artifacts/wave5-brine-authored-{console,engine}.log`.

The authorized artifact-only approach wrapper reuses the actual Player,
stick navigator, terrain, living site body and arbiter. A prepared Bramblebun
and initial road position are explicit synthetic diagnostic setup; it is not
campaign continuity. The existing candidate diagnostic's `max(2400,
distance*80)` movement budget and 1.3 m arrival tolerance are retained.
The outside stance derives from the actual wild radius plus player radius
and 0.5 m clearance. No creature or terrain is moved during the approach.

Site 010 FAILED the ordinary approach in
`.artifacts/wave5-brine-approach-ready-{console,engine}.log`, exit 1:

- Nearest road start: (321.7824, 27.08192, 640.6049).
- Authored candidate: (340.8148, 58.21178, 638.7739), 19.1202 m off the spine
  but 31.1299 m above that start.
- Final human: (326.4995, 25.576, 625.4788), grounded, zero navigator resets.
- Actual wild: (341.5842, 58.69777, 638.999).
- 2400 movement frames plus 12 settling frames; arrived=false,
  exact_engage=false, no offer. No fight was attempted.

This proves why support alone was insufficient. No alternative 010 approach,
terrain change, larger budget or reach was attempted. The 010 authored row is
restored to its pre-change form; the old failure is retained rather than
replaced with a claim of reachable content. The first approach wrapper attempt
failed before movement because Water constructs EncounterDirector asynchronously;
that invalid fixture log is retained as `.artifacts/wave5-brine-approach-*`.
The corrected wrapper waits for the node and population readiness.

Existing Water data/residency checks passed 12 tests / 2213 assertions after
candidate installation (`.artifacts/wave5-brine-data-tests-*`). Default owner
slot 0 and slot 3 hashes were unchanged across native admission and the 010
approach; before/after records are `.artifacts/wave5-brine-authored-owner-*.json`.

### Site 011 independent approach

After restoring only 010, the same artifact wrapper was restricted to 011 in
a separate fresh isolated world. This was a different candidate, not a retry
of 010. `.artifacts/wave5-brine011-approach-{console,engine}.log` exited 1:

- Road start: (472.1694, 39.96681, 754.4372), 6.7376 m lateral from the site.
- Authored candidate: (473.6123, 41.12988, 747.8559).
- Final human: (472.9339, 39.8756, 750.9517), grounded, zero resets.
- Actual wild: (473.6123, 41.45721, 747.8559).
- Arrived=true after 43 movement frames plus 12 settling frames, against the
  same 2400 movement budget. Exact Engage=false; arbiter offer empty.

This supports physical reachability of 011's shelf but does not establish
its requested interaction. The final gap is within production's 6 m Engage
range; the wrapper did not capture the missing admission precondition, so
neither an unreachable-site claim nor a production input defect is justified.
No extra approach, direct callback or fight was attempted. Site 011 is also
restored to its original authored row; `water_encounters.json` has no remaining
diff from this lane. No ERROR/SCRIPT ERROR was emitted during either completed
approach run. Existing terrain mipmap/deprecation warnings remain disclosed.
Owner slot hashes again matched the original before record
(`.artifacts/wave5-brine011-owner-after.json`); all Godot processes ended.

### Site 011 corrected production-input validation

Read-only source review found a concrete diagnostic mismatch: Water's
`water_scene_encounters.gd::build` does not register its director with the
InteractionArbiter. The director retains its production fallback:
`encounter_director.gd::_update_prompt` supplies its own Engage text and
`_read_engage_input` reads physical Interact. Therefore the old wrapper's
`arbiter.winning_provider() == director` condition was impossible; its empty
arbiter offer did not establish failed encounter admission. The old failure
logs above remain unchanged.

Only 011's supported candidate was reapplied. One corrected isolated-world
run (`.artifacts/wave5-brine011-direct-{console,engine}.log`, exit 0) retained
the same road start, 2400-frame movement budget and six-minute watchdog.
Before input, the exact candidate was the intended authored Riptusk, the
production director prompt was `Engage Riptusk`, AllyCreature was deployed,
and the manager was inactive. One physical Interact then started actual
combat; `manager.enemy_body()` was the very same site 011 object. The human
reached the stance, remained grounded, and required zero navigator resets;
85 observed frames included movement, settling, input and combat-start settle.
All-three-species footing and initial production admission remain supported
by the earlier authored probe. This validates reachable, engageable placement,
not a completed fight. The inherited terminal footer incorrectly says
'no combat attempted'; the explicit PRE/POST participant telemetry above is
the actual result. It also says 'both' though this run selected only 011.

Site 011 is now the sole retained data correction; 010 stays original and
unresolved. Counts, table, radius, roam distance and species are unchanged.
The stale optional slope metadata is removed, not a validation requirement.
No ERROR/SCRIPT ERROR occurred; existing terrain warnings remain. Owner
fingerprints matched (`.artifacts/wave5-brine011-direct-owner-{before,after}.json`)
and no Godot processes remained at RAM release. Water's apparent lack of the
usual CombatHUD mount is a source-review concern for a later gameplay review;
this non-rendered diagnostic establishes neither HUD visibility nor a HUD
bug. No production input/runtime changes were made to satisfy the diagnostic.

Final retained-011-only data passed the existing runtime-data/residency checks:
12 tests / 2213 assertions, zero failures, exit 0, no engine errors
(.artifacts/wave5-brine011-final-tests-{console,engine}.log).
