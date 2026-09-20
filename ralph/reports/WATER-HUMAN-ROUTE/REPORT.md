# Retained-five Water route

Branch `ralph/water-human-route`, based on PR141/825b49e09. This is a bounded
implementation checkpoint, not four-biome, Water chapter or release acceptance.

## Player outcome and scope

The required Water route can use human swimming without replacing one of the
player's five companions. `data/config/water_world.json::rest_shoals` adds17
physical landings to seven sheltered routes; twelve named islands remain.
The late sheltered routes are461.703/430.709/698.470m long. The previously
reported434.411/405.249/657.182m distances belong to the direct alternatives,
which retain their optional swim-mount contract.

`water_heightfield.gd` compiles the shoals into actual terrain. Their20m shore
radius,1.5m peak and19m shallow beach support a six-metre safe centre. Each
ordinary safe anchor belongs to a named parent island, preserving map/group
consumers. This required a31-region bake including new region[0,6]. The
manifest's four source SHA256 values match the current builder/config/heightfield/
visual files. Rest is ordinary dry-land stamina regeneration; there is no new
heal, refill, boat, teleport, camp, inventory item or save format.

Mandatory sheltered route metadata is human-level-zero with no mount/saddle
requirement. Cradle→Salt Crown uses the shared `water_aquaryn_resolved` fact
(catch or defeat) in the actual dock consumer; other shared departure gates
remain. Optional direct routes retain their equipment/mount metadata. This
does not certify closed-gate flanking, which still needs physical evidence.

`water_rest_shoals.gd` mounts installed nature stones and existing torch props
outside the clear centre. They are presentation only, grounded against baked
terrain; no prop collision or checkpoint state substitutes for land. WORLD
and SYSTEMS now agree on at least20% reserve with15% steering deviation.

## Verification

Stock Godot4.7 stable5b4e0cb0f, Windows, source checkout; no exported package.
Commands use `--headless --path . --script tests/run_tests.gd -- --only=...`:

- `test_water_heightfield`:14tests/10482assertions/0failed, including all17
  shoals, parent membership, safe profile and analytical current/steering/
  acceleration bounds for all seven mandatory sheltered routes.
- `test_water_earned_late_segment`:6tests/57assertions/0failed, including the
  actual Cradle shared gate and optional direct mount routes.
- `test_water_current_field,test_water_dock_rules,test_water_earned_opening_segment,test_water_earned_swimmer_segment,test_water_earned_ending_segment`:
  19tests/203assertions/0failed. The ending negative control deliberately prints
  its missing-world refusal; no script/plain engine errors.
- Terrain builder `--script scripts/world/build_water_terrain.gd` exits0,
  reports31regions, -65..620m. Source manifest matches verified independently.
- Existing production swimming smoke, `--script tests/smoke_water_swimming.gd --
  --rest-route=sluice_isle_to_veilfall_sheltered`, passes18checks:84.147m actual
  swimming,37.918s movement/landing/recovery interval,33.750minimum stamina,
  100health,0.3000largest observed per-physics-frame stamina gain,1.153commanded
  steering ratio. The fixture starts once on the final shoal and explicitly
  sets the departure world fact; subsequent travel uses real movement input.
  It earns the destination safe anchor on actual dry terrain. No mount, saddle,
  resource reset or later position write. This proves one final hop, not earned
  story progression or the entire698m route. Zero script/plain errors; existing
  physics-interpolation deprecation warning only.

The first swimming run reached the endpoint but failed its final regeneration
assertion because ordinary walking ashore had already restored100stamina.
The corrected measurement observes per-frame gains and permits normal cap
saturation; no gameplay tuning was changed to pass it. Exactly one corrected
run followed. Logs remain in OS temp: `tetherbound-water-heightfield-human-route-final.log`,
`tetherbound-water-earned-late-route-contract-final.log`,
`tetherbound-water-human-route-adjacent.log`, `tetherbound-water-human-route-bake.log`,
and `tetherbound_water_rest_route_smoke.log`.

Required `--script tests/smoke_playground.gd` exits0 with `smoke: OK` after
the final source/import, log `tetherbound-water-human-route-playground.log`.
No script errors. Root read the plain engine errors: existing null-material,
dummy-renderer RID/shutdown, PagedAllocator and resources-at-exit categories,
matching the preceding Playground receipt; this is not a clean-engine-log claim.

## Remaining acceptance

Production Compatibility captures at1280x720 use the actual player CameraRig,
HUD, world terrain and day/night lighting. Fixture places the player on the
last shoal's approach and centre; no story/visual content is substituted. The
HUD consequently retains the initial First Shore objective; this is disclosed
capture setup, not earned Water navigation. Four frames are represented in
`_sheet_navigation.png`. The completed capture exits0 without script/plain
errors. An initial OS-temp capture script had inferred-type parse errors;
explicit types fixed it before the single successful capture. Import exits0.

Code-blind Luna reviewer, images only: **POLISH for navigation**. All four
views distinguish land/water and show a plausible opposite landing. Night
shore contrast is weaker; the foreground marker competes with the route view;
HUD occupies substantial lower-right space without covering this crossing.
Root independently inspected the day arrival and night onward view: usable
local geography, visibly rough surrounding terrain, no commercial art pass.
This checkpoint deliberately stops short of another prop-polish loop.

All-route earned travel, closed-gate flanks, co-op recovery and real device
readability remain open. These shoals solve distances; they do not establish
that repetitive crossings are enjoyable or that Water's complete ending and
homecoming work. No terrain-wide visual pass or commercial-quality claim.

## CI placement correction

PR142/58f3aaaec CI35495270170 completed with24successful jobs,2failed unit
shards and3skipped jobs. The route count expectation was stale: eight island
spines plus11required water routes make19, after the three late direct routes
became optional. `test_road_creature_visibility.gd` now names all19required
routes and retains every forward-visibility assertion.

The surface-grounding failure was a real regression. Five existing surface
pairs overlapped the new rest-shoal profiles; the original aggregate deep-water
assertion was retained. `water_encounters.json` moves only those five pairs,
with consistent island-local offsets. IDs, species tables, pair counts, levels,
surface Y, activation range, six-metre roam radius and terrain remain unchanged.

| Surface site suffix (all prefixed `road_visibility_`) | Final X,Z |
|---|---|
| shellwatch_to_tidal_cradle_sheltered_01 |505.05,1322.65|
| tidal_cradle_to_salt_crown_sheltered_01 |515,1785|
| salt_crown_to_sluice_isle_sheltered_02 |447.25,2689.45|
| sluice_isle_to_veilfall_sheltered_01 |604.3,3289.4|
| sluice_isle_to_veilfall_sheltered_05 |420,3660|

The first manual coordinate candidates cleared their centres but broke forward
visibility; no ROAD threshold was relaxed. A bounded in-memory search against
the existing heightfield and visibility model found feasible positions. Source
review then checked the actual two-member offsets (±3.3m) plus each member's6m
wander radius, rather than treating the site centre as the whole occupied area.
The existing runtime-data test now checks each moved centre, consistent offsets,
and16rim samples plus centre per member at least1m below the waterline. This is
sampled analytical clearance, not a claim of a played/rendered Water encounter.

Final stock-Godot4.7 focused command:
`--headless --path . --script tests/run_tests.gd --
--only=test_road_creature_visibility.gd,test_water_encounter_runtime_data.gd`
passes **15tests /2,666assertions /0failed**, without script/plain errors.
OS-temp log: `tetherbound-water-placement-focused.log`. Root reviewed the final
diff and log. All required Water ROAD samples retain at least two forward
visible creatures under the existing calibrated model. No new harness or bake.

Surface-site count remains17;16centres are more than1m deep. Dense analytical
sampling around the two actual member homes gives worst floor heights of
-1.044,-4.413,-1.053,-1.104,-2.140m for the five rows above (sea level0).
The existing shallow-site allowance is retained; the regression specifically
protects these five new-shoal conflicts.

Required `tests/smoke_playground.gd` exits0 with `smoke: OK` and no SCRIPT ERROR.
OS-temp log: `tetherbound-water-placement-playground.log`. Root compared its
distinct plain-error set against `tetherbound-water-human-route-playground.log`:
identical null-material and headless dummy renderer RID/resource/PagedAllocator
shutdown lines. This is a passing world boot with disclosed baseline errors,
not a clean-engine-log claim or a played Water ecology/whole-route acceptance.
