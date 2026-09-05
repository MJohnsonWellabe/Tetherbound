# Cloudreach production-world integration — 2026-09-05

Implementation checkpoint, **not continuous chapter acceptance or visual acceptance**.
The independent round-2 visual verdict remains No/No. The world, ground-cover,
destination-context, bridge construction and apparatus hierarchy corrective pass
is still required. Existing creatures appear only as installed capability fixtures
for the actual combat/Fly contracts; no new roster or generated art is introduced.

## Production assembly

`cloudreach_world.gd` now mounts one `CloudreachRuntime` composer. It binds the
canonical `Game.bind_realm_map("cloudreach", ...)` instance and the actual terrain
atlas; mounts the existing chapter/physical runtime, realm-safe BuildPlacer and
PlayerDeath, Cloudreach combat manager/director and shared CombatHUD, finale and
atmosphere; and reuses PlaygroundHUD's one shared progression presenter. Surface
queries have a conservative spatial broad phase, retaining exact shape/stack
tests and invalidating when runtime surfaces are appended.

The scene-specific encounter adapter fixes three assembly conflicts without
forking combat rules: canonical `bridgekeeper_orrin` alias; the newer physical
encounter prerequisites (old Maela/Voss prerequisites made circular gates); and
separate Challenge offers rather than overwriting NPC Talk. Challenges follow
the same canonical people when PhysicalRuntime rebuilds them after relocation
or live reload. Captain Veyra's same body is seated at the explicit finale arena
instead of the older gatehouse coordinate 100m south.

The summit has a radius-36m collision deck at y1160.15, a connected approach,
three real lee windbreaks, installed relay apparatus and exposed core cues,
and rotating telegraphs sampled from the same timing/shape config as hazards.
Installed Hall UnevenBrick materials replace the first procedural paving.
Regional grass/tree scatter is excluded from the fight floor. The composer
registers velocity-only hazard modifiers on the actual player and deployed body,
and hands real creature movement/camera/arbiter control into the relay phase.
Relay sight checks exclude only that piloted creature's collider; walls still
occlude. Recovery uses the existing realm-safe recovery/respawn path and unwinds
active combat as retreat first. Teardown unregisters the owned modifier.

Atmosphere binds real lights, route indicators, installed relay lights, canonical
returning people, and a distant non-colliding Waterward reveal. Its scene wrapper
prunes freed traveler references before the shared typed binding loop on reload.
Waterward has no entry portal or gameplay collider. The composer exposes the
actual finale lifecycle as `combat`/`relays`/`exploration` and calls the two HUDs'
capability-checked `set_world_presentation_mode` API. Shared HUD corrections are
owned by the separate HUD lane, not this environment pass.

## Verified evidence

- Focused world/environment/integration unit suite: **18 tests, 423 assertions,
  zero failures**.
- `smoke_cloudreach_foundation.gd`: PASS.
- `smoke_cloudreach_arrival_walk.gd`: PASS, continuous production walking to Aila.
- `smoke_cloudreach_environment.gd`: PASS, exactly ten gatherables with actual
  supporting raycast floors, courtyard clearance and distant ranges.
- `smoke_cloudreach_camp_exit.gd`: PASS after relocating the obstructing lower
  cottage; actual controller movement from the declared camp fixture station to
  (-120.382, 205.001, 699.571), with no intermediate position writes.
- `smoke_cloudreach_production_integration.gd`: PASS in headless and actual
  Compatibility rendering. Checks exactly-once mounts/feed/map, all seven
  supported trainers, canonical NPC reuse, actual arena collision, real party
  deployment, actual three-round captain lifecycle, real post-battle stick input,
  real Interact presses for every relay, actual overlook proximity, canonical
  reward-dialogue effect, isolated disk save/load, no repeat trainer reward and
  canonical NPC/map identity after reload. Only lethal battle resolution is
  accelerated test code. The starting chapter flags are an explicitly declared
  checkpoint fixture; station warps are not continuous-travel evidence.
- `shots/` and `performance.json`: ten real production route/camera frames from
  initial assembly. These precede the live arena/HUD/paving cleanup and must not
  be presented as the final cleaned-up rendering.
- `live/`: four latest actual production combat/relay frames with HUD and input,
  plus actual frame timing/draw/primitive measurements at 1280x800 on GTX1060.
  These are not ROG Ally acceptance measurements. Parallel headless regression
  work may affect the absolute timing; the hardware/context is disclosed.
  Latest live samples: 1503–1704 draw calls, 8.42–9.19M primitives and
  26.21–30.06ms frame intervals. Relay frames show the actual mapped blue X
  glyph after a real above-deadzone joypad motion event. The production GPU
  integration completed PASS after capturing all four frames.
- `route-repair/`: seven current production-camera frames of all three yards,
  the relocated lower-road resource and both causeway joins. Actual captures
  and per-view rendering/performance data; not concept art or chapter acceptance.
  The 24-frame samples measured 835–2375 draw calls, 2.10–7.71M primitives and
  4.81–10.60ms frame intervals. These short samples do not establish sustained
  frame pacing, and other agents' continuous/headless runs were active.

## Newly addressed arrival cadence

The continuous harness reported 191 simulated seconds of empty arrival travel.
The road geometry is unchanged. An optional, reward-free installed ruin inspect
beat is at approximately 30 seconds; two existing day-regrowing nodes retain
their stable save identities but now appear on the pre-camp road:

- `cr_node_cloudberry_waycamp`: (-175, 136.4714, 109), approximately 85 seconds.
- `cr_node_gale_fiber_gate`: (-292, 159.4031, 320), approximately 140 seconds.

These are ordinary harvest/inspect offers, not fabricated objective completions.
Continuous retry 3 measured actual offers at 32.5/89.5/147/187.5 seconds,
with a maximum pre-camp gap of 57.5 seconds. It passed the corrected camp exit.

## Continuous retry-3 route corrective checkpoint

The genuine causeway fall exposed three coupled defects: the old west route
vertex was 40m away from the installed bridge endpoint; a 145m endpoint proximity
heuristic plus an 8m cut margin removed adjacent approach ground; and the
Three Bells crag penetrated the straight rope deck. The route now meets the
actual (-540,330,1280) abutment. Only collinear XZ bridge overlap removes ground,
so the bridge still crosses a real gap without deleting its approach. Its
authored deck profile rises over the existing crag, and interior profile bends
do not create blocking landing mesas. Endpoint ramps reach the actual landing
cap edge at matching height. The second stone span now meets the actual y390
regional crown instead of the old buried y375 abutment. Root relocated the
same `lower_west` interaction to (-544,330,1280); its ID and flag are unchanged.

- `smoke_cloudreach_causeway_crossing.gd`: PASS. One declared starting fixture,
  then real movement from (-320,300,1040) across both spans to (120,420,1830),
  without jump or intermediate position writes. Every reached waypoint must
  also be within 0.7m of its authored floor height.
- Dedicated Ila, Senn and Voss yards are 25m outside their road entries, with
  radius-16.5m collision floors and clear radius-14m battle space. Existing
  crate/barrel dressing stays outside that diameter. Trainer IDs, teams,
  prerequisites and rewards are unchanged. Voss reuses his canonical NPC.
- `smoke_cloudreach_battle_yards.gd`: PASS for all three. Each declared local
  entry fixture walks into the yard, around the clear floor and back out using
  actual production input. Integration also probes four floor points per yard.
- The existing `cr_node_gale_fiber_bridge` moved to (-284,260.7141,890), between
  lower-road potion and revive, to address their measured 97s actionable gap.
  Same identity and regrowth rewards; exactly ten resource nodes remain. Its
  physical floor passes. Continuous retry 4 measured its offer at 317.5 seconds,
  splitting the earlier gap into 60.5 and 37 seconds. It also passed the actual
  west-anchor inspection and the complete corrected first rope span, reaching
  (-260.16,390.03,1559.83) at 517.25 seconds.
- Current foundation, arrival, camp exit, environment/resource and complete
  production integration smokes all PASS. The latter retains real captain
  callbacks, piloted relay interaction, canonical reward and disk save/reload.

Exact code/config/test changes for this checkpoint:
`cloudreach_world.gd`, `cloudreach_world_runtime.gd`,
`cloudreach_scene_encounters.gd`, new `cloudreach_battle_yards.gd`,
`cloudreach_world.json`, `cloudreach_visual.json`, new
`cloudreach_scene_runtime.json`, `test_cloudreach_production_integration.gd`,
`smoke_cloudreach_production_integration.gd`, new
`smoke_cloudreach_causeway_crossing.gd`, new `smoke_cloudreach_battle_yards.gd`,
and `capture_cloudreach_production_integration.gd`. Logs reside beside this
report. No shared HUD, chapter, creature, player or reward rules were edited by
this corrective checkpoint.

## Exact remaining gaps

1. Continuous Act I → authored Fly trial → upper encounters → summit path has
   not passed. A separate continuous harness owns that evidence.
2. Continuous retry 4 must verify the repaired causeway from true arrival, the
   next route segments and the relocated resource's actual offered cadence.
3. Dedicated yard traversal/floor checks pass, but the bare circular clearing,
   rectangular entry apron and minimal dressing still need visual round 3.
   Voss's yard also has a large noncolliding geological mass visually intruding
   behind the trainer: floor checks are not visual-clearance acceptance.
   These local walking fixtures do not establish full trainer battle balance.
4. Recovery integration exists, but no full live deep-fall/retry acceptance run
   has yet established loss/retry clarity through every finale stage.
5. The surrounding giant smooth brown cliffs and sparse destination contexts
   remain visibly below the governing references. The arena cleanup is not a
   substitute for the next environment corrective round. Repair frames still
   expose dirt-material bridge planks, coarse rim geometry and bare yard forms.
   Summit apparatus housing currently has no local blocking collision; the
   bounded relay capture fixture now approaches from the arena interior rather
   than placing the crown actor inside its outward machine. This is an explicit
   fixture correction, not proof that machine penetration is production-fixed.
6. External ChatGPT visual acceptance remains external. Nothing in this report
   supersedes the failed blind verdict or claims the complete goal is finished.

No commits or pushes were made by the environment sub-agent; root owns shipping.
