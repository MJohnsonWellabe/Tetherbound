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


## Human guidance and late story prerequisites

Branch `ralph/water-crossing-gates`, based on PR143/1c818ee9a. The inherited
shoals do not by themselves establish legal/usable Water progression. Two
bounded movement checks used stock Godot4.7 and the actual Water world, with
one disclosed initial placement at the Cradle safe anchor per run; all later
movement used normal forward/camera input. No campaign walker or retained new
probe framework was added.

**Closed Cradle gate:** shared `water_aquaryn_resolved` stayed false. Straight
travel stopped at(559.132,1.459574,1732.160),4.396m along the departure from
anchor(560.542,1.929+0.15,1727.776). Walking around the barrier passed it at
(563.5809,-0.002667,1751.223),17.411m along/15.995m lateral, with no current
and full health/stamina. This is a reproduced physical dock flank, against
WORLD§6.1. A longer continuation ended at(494.476,-0.054372,1796.438),19.96m
from the first shoal centre,3.483stamina/100health. It missed its offset
waypoint by16.29m and timed out. It proves neither arrival nor a complete
closed crossing/story skip. Its final point was outside both current strips:
12.233m from sheltered centreline against9m halfwidth,14.425m from direct
centreline against14m halfwidth. Log `tetherbound-closed-cradle-gate-probe.log`
in OS temp; exit1 for that continuation miss, no SCRIPT/plain ERROR, one
Terrain3D deprecation. The physical gate remains unfixed.

**Open Cradle to first shoal:** shared resolution was explicitly fixture-set,
then20frames allowed barrier removal before one initial anchor placement.
The target was the actual shoal centre(474.539,1.5,1795.468). Real swimming was
observed at(543.609,-0.700,1746.843),native ground-2.575/depth2.574,mode1,
forward input true; maximum observed depth12.142m. Open current magnitude
was0.2m/s. The first recorded dry-floor sample had49.204stamina; this is not
a measured per-frame minimum or a15% steering-reserve result. Arrival was
(474.8213,1.500845,1795.26),native ground1.5,floor true,mode0,input false,
velocity zero,health/stamina100 through ordinary land regeneration. Log
`tetherbound-cradle-first-shoal-probe.log`; exit0/FIRST SHOAL PROBE OK,
no SCRIPT/plain ERROR, same deprecation. The previous closed continuation
miss is not evidence that this shoal cannot be landed on.

**Player-facing correction:** `water_objectives.json::main` now has11steps:
shared Aquaryn catch-or-defeat resolution replaces the two mandatory personal
Stone/recipe steps. Sheltered shoals/dry recovery guide onward travel.
`local` has one optional recipe hint revealed by personal Swim Stone ownership;
it is not a completed three-step local chain. `data/dialogue/water.json`
removes Otto's forced catch/release advice, makes Iona's mount lesson optional,
and places pre-crossing preparation at Sluice camp. Lastlight is on Veilfall
(`water_characters.json::water_halen`), so it cannot be the camp before that
crossing. Conversation IDs, counts, portraits and reward/effect IDs remain.
No entitlement, mount, recipe cost or capture limit changed.

**Host prerequisites:** Bex/Calder now require the Salt Crown chart through
`water_characters.json::requires_flags`, consumed by the inherited encounter
director `can_challenge`. Both Sluice controls require that chart plus their
trainer victory in `water_dock_actions.json`; `water_dock_rules.gd::evaluate`
refuses without producing operations. `water_veilfall.json` requires combined
Sluice completion before intake; `water_veilfall.gd::host_commit` checks it
before ledger writes. Existing return-sluice→Nerissa→Guardian dependencies
remain. Completed legacy flags are preserved, with no retroactive reset.
These story guards do not fix or accept the physical shoreline flank.

Root reproduced the guidance failure against old data:1test/7assertions/
1failed (`tetherbound-water-guidance-red.log`). New guidance passes the whole
QuestLog batch:45tests/890assertions. Root separately restored only the three
old gate configs temporarily, preserving/restoring modified bytes in a
try/finally:3tests/41assertions/3failed, including old intake accepting before
Sluice completion and dock operations before the chart
(`tetherbound-water-gates-red.log`).

Final stock-Godot focused command:
`--headless --path . --script tests/run_tests.gd --
--only=test_quest_log.gd,test_water_dock_rules.gd,
test_water_earned_late_segment.gd,test_water_veilfall_geometry.gd,
test_water_dialogue_delivery.gd,test_flag_scopes.gd`.
**67tests/1,302assertions/0failed**, no SCRIPT/plain ERROR, in
`tetherbound-water-gates-guidance-green.log`. Initialized geometry/dialogue
child cases run inside their existing wrappers; geometry includes357child
assertions. Expected negative-control diagnostics are not failed tests.
Root inspected the source diff and independent logs; these are not a remote
host-admission, earned campaign, physical-gate or ending acceptance claim.


Runtime dock smoke initially had47checks/1failure: its old-slot load expected
old inventory9reed/7driftwood. Portable character saves correctly retain the
latest3/3 after the open-world save. The single assertion now matches portable
character semantics; flags, costs, gate physics, currents and save/load checks
remain. Final `tests/smoke_water_dock_actions.gd` passes47checks/0failures,
no SCRIPT/plain ERROR, one existing Terrain3D deprecation. OS-temp logs:
`tetherbound-water-dock-actions-final.log` (old expectation) and
`tetherbound-water-dock-actions-green.log` (corrected expectation).

The unchanged isolated `tests/smoke_water_veilfall_captain.gd` did **not** pass:
12checks/2failures, only two of four authored opponents reached within its
existing180second deadline. The fight remained active, captain victory was
not awarded, and the first Mosshell retained501.308/551.2HP. It seeds the two
interior controls, so it does not exercise the newly added intake prerequisite.
Log `tetherbound-water-veilfall-captain-final.log`, no SCRIPT/plain ERROR.
No fight tuning or deadline relaxation follows from this diagnostic. An
out-of-scope combat-driver experiment was excluded; this checkpoint preserves
the existing Captain smoke and reports the incomplete fight honestly.

Inherited PR143 CI35497191759 has a separate failure in multiplayer shard1,
job106042696113: `smoke_net_shared_wild_fight.gd` expected `friendly_target`
for action9003, but the host accepted an opponent hit (HP52.008→43.108), and
subsequent polls returned `replayed_action`. Host telemetry shows both opponent
and friendly creature inside the cone, at2.544m and8.122m respectively. This
is not evidence of a revive failure or a diagnosed flake. Source review found `_friendly_body_struck` in
`scripts/net/encounter_host.gd` deliberately selects the closest connecting
body: an opponent nearer than a teammate is a legal opponent hit. The smoke
places/aims at the teammate but only asserts friendly reach; it never excludes
the nearer opponent from that cone (`smoke_net_shared_wild_fight.gd`, action
9003 setup). Root verified those lines and the host telemetry. Correcting the
fixture is separate pending work; no gameplay change is justified by this
receipt and no full-stack green or merge is claimed. PR142 CI remains in progress.


Required `tests/smoke_playground.gd` exits0 with `smoke: OK`, no SCRIPT ERROR.
Log `tetherbound-playground-water-gate-final.log`. Root compared its complete
set of distinct plain ERROR lines to the preceding placement smoke: identical
null-material, headless dummy RID/resource and PagedAllocator exit errors.
This is a passing world boot with disclosed baseline errors, not a clean-log
or complete Water journey claim. Captain source was restored exactly; the
terminated driver experiment is not acceptance evidence. No terrain bake,
combat balance, new swimmer requirement or physical-gate fix is in this slice.


## Dock save boundary before the civilian departure

`ralph/dock-save-boundary`, based on PR151/21a064258, fixes a concrete save
ordering defect uncovered while preparing the ending's shared dock departure.
The earlier read-only suggestion that all dock ledger actions already saved
before publication was wrong. `world_ledger.gd::commit` evaluated the physical
action, then `ledger_rpc.gd::_commit_here` applied player costs/published it
without a mandatory world write. Only reward and satchel transactions had the
existing durable-save gate. Later autosave was not a transaction guarantee.

The production change adds `water_dock_action` to that existing gate. Authored
prerequisites, authenticated actor/realm/location, costs and duplicate refusal
remain unchanged. A successful candidate world change must save before the
player debit or public delta. Save refusal restores world state, sequence,
revision and ledger bookkeeping, publishes nothing and leaves materials intact.
The readable `journal_failed` result permits retry. Empty world IDs cannot
bypass persistence. No new schema, RPC, action row, art or departure flag.

**Remaining boundary:** paid repair debits still lack portable receipts and
reconciliation for a crash/disconnect between host world save and character
settlement. This is not full distributed atomicity. Zero-cost actions avoid
that debit gap. Derived dock completion flags can reconstruct from saved
physical-action facts. Generic world-flag writes are not silently made durable
by this change.

### Verification

Sol changed only `scripts/net/ledger_rpc.gd`; Luna extended existing
`tests/test_reward_delivery_rpc.gd`; root reviewed/tightened the failure-then-
retry test and extended existing `tests/smoke_water_dock_actions.gd`.
Focused run of `test_reward_delivery_rpc.gd,test_water_dock_rules.gd` passes
**11tests/138assertions**, exit0, no SCRIPT ERROR/ERROR. Log:
`tetherbound-dock-save-tests-final.log` in OS temp. It checks paid and zero-cost
save failure, no delta/material loss, world/sequence rollback, required save
for unnamed worlds, save-before-debit ordering, successful retry, duplicate
refusal and prerequisite/range refusal without a write. Existing reward
transaction tests remain included. Both affected runtime/test scripts parse.

The real Water dock smoke injects a refusing `save_world` wrapper over the
production saver, without replacing dock/ledger/barrier/current behavior.
Failure leaves the real Reedhaven barrier closed and all nine reed fiber/seven
driftwood available; retry spends the authored six/four and writes the repair
flag into the actual world file before any later manual save. The final run
passes **55checks/0failures**, exit0, no SCRIPT ERROR/ERROR. Log:
`tetherbound-dock-save-production-final.log` in OS temp. Fixtures still disclose
placed player poses and prerequisite victories; this proves neither earned
Water traversal nor a remote network session.

The first production run failed two old reload expectations: an earlier slot
snapshot pointed to the active world file, now correctly updated by the repair,
so loading it no longer closed the dock. The test now checks that durable open
state survives the original locator reload, while an explicitly separate
closed fixture still proves barrier/current reconstruction. No assertion was
removed to conceal an engine defect. First log: `tetherbound-dock-save-production.log`.
Required `tests/smoke_playground.gd` exits0 with `smoke: OK`, no SCRIPT ERROR.
Root compared `tetherbound-dock-save-playground.log` to the preceding
`tetherbound-regional-credits-playground.log`: the same eight distinct headless
material/RID/resource error categories, no new error. These baseline shutdown
errors remain disclosed rather than a clean-engine-log claim.

### Ending integration still needed

All18existing Water NPC rows have restored-current aftermath greetings;
`water_scene_npcs.gd` already selects them through the current world's state.
Mara's civilian supplies line, Rowan's repaired pier, Nalia's returning residents,
Orsen's supplies and Jessa's blankets are authored in `data/dialogue/water.json`.
Mara is on **First Shore**, not beside the Reedhaven action anchor; an eventual
speech-triggered action must not bind her to a distant4.2m dock check. The
physical exchange/departure and guided earned return remain unimplemented.
This prerequisite fix does not claim a new departure scene or chapter acceptance.


## Closed-gate tide races (flank repair)

Branch `ralph/water-closed-gate-seals`, PR226, based on main `49ef712f`. F12,
ACCEPTANCE §6.1 "no optional mount opens an uncleared gate", under WORLD §6.1.
This repairs the physical flank reproduced above. It does not accept the whole
route, co-op recovery or chapter T1.

**Cause.** A closed dock only strengthened its own departure strips (sheltered
18 m / direct 28 m wide) to 6 m/s. Open water on either side stayed calm, so a
swimmer could walk round the 10 m barrier and swim to the first shoal. Every
swim mount (6.3–10.0 m/s) could also outswim the 6 m/s strip itself. Fly had no
Water restriction at all: a 16 m/s glide that sinks 2 m/s covers roughly
900 m from the Cradle peak.

**Change.** `scripts/world/water_gate_seals.gd` walks the dock graph from the
realm arrival. Each island and rest shoal gets the ordered chain of mandatory
dock facts before it: 10 islands and all 17 shoals are sealed, while First
Shore and Lantern Cove stay open. A seal stays active until its landform's own
final fact, or any later fact on a chain through it, is present. Facts arrive
in chain order in an earned world, and a world holding a later fact has already
reached the land it opens.

While active, the shared current field (`water_current_field.gd::with_closed_gates`,
also used by `water_world.gd`) adds a radial outward race from the shoreline to
16 m offshore: 12 m/s, with a 4 m smooth outer blend. The race outranks route
currents, and where two races overlap the nearest shore owns the water.
`water_gate_seal_view.gd` draws the same ring as streaming white water. At most every 12 s it tells a
swimmer inside a race, heading in or out, which dock to clear. The same discs,
as disc-fitted z-strips, go through Fly's existing `register_restriction`
API. The tunables are in `water_swimming.json::docks.seal_race`. There is no
new flag, save field, RPC, mount rule or invisible wall. The dock barrier and
the closed strips are unchanged.

### Review corrections

**First independent review: no blocker, two majors.**

- **Worlds with a gap in their flags (fixed).** Only the landform's own final
  fact opened a seal. So a legacy or fixture world holding a later fact, but
  missing an earlier one, sealed islands the player had already passed.
  That broke every dock's authored `return_policy`. Now a seal opens with its
  own final fact or any later fact on a chain through it. Fly restrictions
  are re-synced from the same state on every flag revision, and the refusal
  names the dock to clear.
- **Visibility (only partly fixed; see the visual result below).**

Also added:
- tests for later-fact worlds, island reachability and simulated overlap seams;
- no push-back message during a combat pause;
- runtime checks that this trainer's Fly restrictions register while closed
  and release once open;
- a `push_error` when no dock reaches an island.

**Second independent review: FAIL.** It confirmed the gapped-world fix, the
Fly re-sync and the dock-smoke fixture as sound. It failed the PR because
the race was not readable from the departure beach in daylight, and because
this report had called the visibility major fixed. That wording is
withdrawn here.

**Third independent review: pass.** It found the change strictly better than
main, where the unvisualised 6 m/s strip is closer to an invisible wall and
can be bypassed on foot, by mount and by Fly. It breaks no hard rule or
settled spec while swimmer-height readability stays open under F13.

Its condition for merge (M1) is to write the mechanism back into WORLD §6.3
and §6.6 and into STATE row 91. Those are shared files: this was requested
from the coordinator on PR226 and is not done in this branch. Minor fixes
applied:
- trough and spray drawn at render priority 1, above the translucent sea;
- `visibility_range_end` of 700 m beyond each race on the ring, trough,
  crests and spray;
- spray, crest and emission tunables moved to `seal_race`;
- spray emission stops once a race opens.

No frame-time measurement exists. Measure on the Ally before any
performance claim.

### Visual result: failed at swimmer height, open under F13

`tools/capture_water_gate_seals.gd` writes the six-frame
`_sheet_gate_seals.png`. It runs under `xvfb-run`, `--rendering-driver
opengl3`, 1280x720, with HUD layers hidden. The top row shows the closed gate
from the beach at 3.2 m, from the swimmer's flank position at 0.9 m, and from
a 70 m overview. The bottom row shows night, then the beach and swimmer views
after the gate opens.

Presentation went through three approaches:
1. a flat foam annulus (alpha 0.62, then 0.9);
2. standing crest ribbons;
3. a dark trough, lit foam with low emission, and ring-emitted spray particles.

Two fresh code-blind judges saw only renamed frames and the references.

- **Round 1 (flat foam plus crests): no.** The race read as haze, fog, markers
  or ice, and was brighter at night than by day.
- **Round 2 (final): still no for surf.** "Is it at least clearly not an
  invisible wall? Yes, barely." The judge said the race "explains *that* there
  is a boundary, not *why*": a flat white rim with no height or curl, a
  bullseye from above, and pale glowing ice at night.

Its ranked fixes:
1. breaking height and spray along the whole ring;
2. an irregular reef outline;
3. scale that holds up at a distance;
4. darker churned water with flow streaks;
5. night lighting;
6. mounded sandbars.

The pushed-back swimmer also gets the explanation text. The stop rule ends
iteration here. Readable currents (seals and route currents alike, since
closed strips and ordinary currents on main have no visuals at all) belong to
F13's "currents … read pass T2's visual matrix" and are **not** claimed. The
gate is visible but not yet explained by readable surf.

### Production-camera motion capture (before and after)

`tools/capture_water_gate_seal_motion.gd` drives the production player,
swim controller, CameraRig and HUD with real input. It walks round the
closed barrier, swims the open-water flank and steers at the first shoal,
taking 16 frames over 40 s.

Disclosed fixtures: the four earlier Water facts are set directly, and the
trainer starts on the Cradle departure anchor.

- **`_sheet_gate_seal_motion_before.png`** (main 49ef712f, via worktree
  commit ec35fec2c, which adds tests only): the swimmer reaches the shoal
  centre (0.13 m) at 12.5 s and stands on it with the gate closed. This is
  the flank defect, shown on screen.
- **`_sheet_gate_seal_motion_after.png`** (this branch): the same input is
  held at 34.5 m from the shoal centre for the whole 40 s, in front of
  breaking-wave geometry with a wandering outline and height.

Blind judge round 3, on renamed sheets:
- **"Clearly not an invisible wall: yes."**
- Surf read: **weakly or no.** It reads as an ice shelf or snowbank. It is
  flat-topped and matte, with hard slab edges, sorting slivers under the
  front band, the islet ghosting through, a straight lower edge, no motion
  over 32 s, and health dropping (drowning after stamina runs out) with no
  on-screen cue.
- Bars A and B: no.

The remaining levers need an animated foam shader. That was requested on
PR226 as a shared-file request. **Readability stays failed and open.** #226
stays draft until a blind judge passes it.

### Verification

Stock Godot 4.7-stable in a Linux container, from a source checkout. There is
no exported package and no device run.

- **Unit tests.** `test_water_closed_gate_seals.gd` with
  `test_water_current_field.gd`: 20 tests / 51,123 assertions, 0 failed, on
  the final source. The broader `water`, `swim`, `flag_scopes` and
  `road_creature` selection passed 238 tests / 78,456 assertions, 0 failed,
  on 945ffa7d, before the corrections. Its printed FAIL lines are known
  negative controls.
- **`smoke_water_closed_gate_seal.gd`: 21 checks on 7569ae8c; 23 after the b8bb1e13 follow-ups.**
  - Disclosed fixtures: the four earlier facts are set directly, and one start
    position is placed at the Cradle departure. All later movement is real
    input.
  - Route: walk the beach round the barrier's south-west end, then swim the
    open-water flank 22 m outside both closed strips (current under 0.5 m/s).
  - Closed result: closest approach 34.50 m to the first shoal centre (shore at
    20 m) and 116.70 m to the second. The explanation names the Tidal Cradle
    dock. This trainer's Fly restrictions are registered.
  - Open result: after only `water_aquaryn_resolved` is set, the race and the
    Fly restrictions clear. The same swimmer lands dry on the shoal's safe
    landing.
- **Rerun on acedb91d, after the later-fact change:**
  - `smoke_water_dock_actions.gd`: 55 checks, 0 failed.
  - `smoke_water_mounted_swimming.gd`: 91 checks, all five mounts.
- **Passed on 945ffa7d or c3ae9bb9, before the later-fact change:**
  - `smoke_water_swimming.gd`: the lesson (60.142 m) and
    `--rest-route=sluice_isle_to_veilfall_sheltered` (84.147 m, 33.750 minimum
    stamina, 1.153 steering ratio, identical to the earlier receipt);
  - `smoke_net_water_swimming.gd`;
  - `smoke_net_water_mounted_swimming.gd`, which did not show the host-`MOUNTED`
    defect on this run;
  - `smoke_stormwood_water_gate_path.gd`;
  - `smoke_water_opening_continuous.gd`.
  The later-fact change only opens more land, and none of these fixtures holds
  a gapped flag set except the continuous one below.
- **Dock-smoke fixture (corrected after the coordinator's review).** The
  fresh world drove Shellwatch and Deep Watch equipment without the facts that
  open those islands.
  - The fixture now sets only the later facts `water_aquaryn_resolved` and
    `water_dock_salt_crown_landing_charted`. Through the later-fact rule they
    lift the races on every landform before them.
  - Every fact under test stays unset: lesson, Reedhaven repair, Brine Steps
    trial, Shellwatch and Deep Watch.
  - All original assertions are restored unchanged. That includes "Closed dock
    current pushes at configured 6m/s" and "Pre-reward reload restores the
    still-gated Shellwatch current" (6.0).
  - The only other change: `current_probe` tries more points along each segment
    and still requires full influence on the exact current.
  - An intermediate version (c3ae9bb9) had set the Brine Steps fact and
    weakened the Shellwatch reload assertion. The coordinator's review caught
    it, and b8bb1e13 reverted it.
  - Local runs on b8bb1e13: `smoke_water_dock_actions.gd` 55 checks, 0 failed;
    `smoke_water_closed_gate_seal.gd` 23 checks, 0 failed. The seal smoke adds
    a Fly re-sync after a changed local rig, and spray gated by distance: 6 of
    27 emitters live from the Cradle departure.
- **`smoke_water_continuous.gd` is unresolved and not claimed.**
  - Its gapped fixture holds only the Aquaryn fact. Under the old last-fact
    rule, and again with the race strength set to 0 (reverted, never
    committed), it timed out 72.5 m and then 70.9 m short of the Salt Crown
    arrival, with the mount at full stamina.
  - On acedb91d it landed Salt Crown and Sluice Isle, then hit the 900 s
    wall-clock limit while the renderer shared the CPU.
  - **Main baseline (49ef712f, uncontended, headless):** it also fails. It
    lands Salt Crown (+76.3 s), charts it and lands Sluice Isle (+304.2 s),
    then times out 2.8 m short of the Sluice→Veilfall waypoint
    (447.924, 3444.751), with mount stamina 0.696 and hp 195.3.
  - So the mounted late route is unstable on main and fails at a different
    leg on each run. It is not introduced by this PR. It needs its own work
    order. The smoke is not in CI.

**Remaining.** A runtime Fly glide into a seal, a network guest seeing the
race clear on a host delta, and a mounted runtime flank are all unexercised.
The mounted case is covered analytically (10 m/s against 12 m/s), and Fly
through the real controller's restriction test. The new smoke is not in CI; a
`.github` grant was requested on PR226.
