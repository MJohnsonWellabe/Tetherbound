# CURRENT_STATE history — moved 2026-09-07

Moved verbatim from `docs/CURRENT_STATE.md` when that file was slimmed to the live
status. History only; nothing here routes current work. See `docs/CURRENT_STATE.md`.

## 2026-09-04 — Cloudreach checkpoint / agent exit

Branch: `codex/cloudreach-cliffs`, based on `origin/main` `763ecac1a` (PR #40).

This is a deliberately narrow, buildable foundation checkpoint, not a completed Cloudreach
pass and not visual acceptance. It adds the persistent second-realm seam: the Meadows Warden
now grants durable `realm_key_cloudreach` and `realm_heart_meadows_earned` progression facts
exactly once through the existing trainer-defeat path; a short automatic victory conversation
names both rewards and Cloudreach; data-driven `RealmHeartState` owns placement and the single
active Heart choice; Meadowstride doubles maximum stamina without stacking; save format v17
persists the current realm and active Heart while migrating older saves to the Meadows; and
Continue selects the saved realm scene. A saved player pose is realm-tagged so Meadows
coordinates cannot be applied in another world.

Verification on Godot 4.7 stable (`D:\Tetherbound-tools\godot\Godot_v4.7-stable_win64_console.exe`):
the focused handoff/Heart/vitals/dialogue/trainer/band suite passed **161 tests / 3,640
assertions / 0 failures**. The dialogue runner intentionally emits one expected error while
testing rejection of a nonexistent conversation; there were no parse errors or unexpected
script errors in this run. A whole-project editor scan reached script-class registration cleanly,
then began a first-time import of the entire asset library; it was stopped at 18% to keep this
handoff bounded, and all generated import metadata was removed before commit.

Exact resume point: build the physical Heart shrine in the Meadows, then the locked Storm Road
realm gate and `scenes/world/cloudreach_cliffs.tscn`; only after that should a smoke test call
`Game.enter_realm("cloudreach")`. The realm registry already names that scene, but
`Game.enter_realm` checks `ResourceLoader.exists` before mutating or saving state, so this
checkpoint refuses the unfinished crossing safely. Then prove Warden victory -> reward dialogue
-> shrine place/equip -> doubled stamina -> locked/unlocked gate -> Cloudreach -> return ->
save/reload as one continuous real-game path before starting Phase 2 terrain. No visual-judge
pass or performance measurement has been claimed for this systems-only checkpoint.

Known external input gap: PR #40 did not include the referenced Cloudreach concept board and no
local copy was found on C: or D:. Follow the directive's written visual language until the owner
provides the board; do not invent a competing style reference. Do not implement the intentionally
deferred final Cloudreach creature roster, final Fly bird models, unique animations, legendary
final art, or the Water biome while completing the functional chapter.

## 2026-09-04 — Cloudreach checkpoint 2 / agent exit

Branch: `codex/cloudreach-cliffs`, continuing from checkpoint `04d844d07`. This checkpoint is
buildable and safe for another agent to continue; it is **not** a completed Cloudreach biome,
visual acceptance, or a substitute for the remaining phases in
`docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md`.

The Meadows-to-Cloudreach seam is now physical and bidirectional. The Meadows builds an
interactive Realm Heart shrine and a locked Storm Road gate from
`data/config/realm_transitions.json`. The gate recognizes the Warden's durable Realm Key,
persists its own unlock, and routes through `Game.enter_realm()` without consuming the key.
Destination entry ids now survive the transition autosave and are cleared only after the new
world places the player and records the destination pose. Returning from Cloudreach uses the
authored far-north Meadows anchor; the player is held out of gravity for the first four terrain
collision-streaming physics beats, then re-grounded before the arrival autosave, preventing the
remote Storm Road spawn from falling through while Terrain3D catches up.

Cloudreach now has its first production scene and authored world-data foundation. The scene
builds the directive's exact six ordered regions across a 3.2 km × 6.5 km × 1.7 km volume, an
authored route graph with loops, twelve recognizable landmark masses, five suspended/broken
bridge spans, a cloud sea, wind-bent vegetation, a visible sheer High Roost, an upper-route
counterweight barrier, initial settlement/shrine/stronghold silhouettes, solid walkable
surfaces, a physical return gate, the normal player/camera/HUD/interaction shell, and explicit
arrival/return anchors. High Roost has only a Fly edge in the data graph; the grounded graph
stops at Windscar until `cloudreach_upper_route_unlocked`, then reaches Upper Cloudreach and the
Summit through one authored ground crossing. This is traversal/composition massing, not final
art or content.

Verification on Godot 4.7 stable:

- Focused Heart/handoff/world-data/vitals/save/component suite: **113 tests / 782 assertions /
  0 runner failures**. Five older tournament-save methods still emit the known false-green
  `SaveGame.save_game()` script errors in this runner; they predate and do not exercise this
  checkpoint, so the output must not be described as a globally clean save suite.
- `tests/smoke_cloudreach_foundation.gd`: **PASS** — six regions, twelve landmarks, five
  bridges, authored route/collision volume, and player grounded at the Meadows arrival.
- `tests/smoke_cloudreach_transition.gd`: **PASS** — real physical gate, Meadows → Cloudreach
  authored arrival, durable unlock, physical return gate, Cloudreach → full production Meadows
  Storm Road arrival, stable Terrain3D grounding, pending-entry settlement, and isolated
  autosave cleanup.
- Direct `--check-only` parsing passed for the new/changed world and transition scripts.
- The full unit suite, a real rendered capture/contact sheet, blind `visual-judge` review, and a
  representative performance capture were **not** run for this checkpoint and are not claimed.
  Full Meadows boot still prints existing no-mipmap warnings and, in this unimported D: checkout,
  warnings for the four pickup GLBs while the transition smoke builds the source world.

Exact resume point: first render the current Cloudreach scene from the real gameplay camera at
arrival, Broken Causeways, Windscar, High Roost, Cliffhold, and the Summit; measure representative
performance; and run the required code-blind visual-judge pass. Treat that evidence as a massing
critique and correct the world foundation before layering content. Then implement Phase 3 in
order: Cloudreach act/progression data, local NPCs/dialogue/tasks, encounters/trainers/resources/
pickups/camps, the functional Windscar Fly unlock and controller-safe flight loop, the interactive
Sky Shrine that grants the separate upper-route unlock, and save/load coverage for both. After
that continue the stronghold, boss/reward/aftermath/Water setup and final full-route acceptance
phases. The referenced Cloudreach concept board remains absent; use the directive's written
visual language and document the missing reference rather than inventing a replacement.

## 2026-09-04 — Cloudreach checkpoint 3 / visual-foundation exit

Branch: `codex/cloudreach-cliffs`, continuing from checkpoint `3f9e1a141`. This checkpoint is a
tested **prototype/massing handoff only**. It is not a finished Cloudreach environment, not a
completed Phase 2, and not visual acceptance.

The Cloudreach builder now replaces the first pass's region boxes with tapered low-poly mesa
masses, distinct upland caps, irregular route-support shelves, satellite crags, a cooler cloud
horizon, clustered cloud-bank silhouettes, approved Quaternius nature-family trees/rocks, batched
bridge deck planks, differentiated bridge materials, and larger first-pass settlement, Sky Shrine,
wayfinder, and summit silhouettes. A production-scene capture harness records six third-person
chapter views and representative renderer counters. Evidence lives in
`ralph/reports/CLOUDREACH-PHASE2-0904/`.

The capture on Windows/OpenGL3 at 1280x720 using an NVIDIA GTX 1060 3GB recorded **197–1,684 draw
calls**, **65,265–334,480 primitives**, and **1.93–5.44 ms measured frame time** across the six
views (24 frames/view). The highest draw count remains below the Hall reference ceiling of 4,000.
`tests/smoke_cloudreach_foundation.gd`, direct parsing of `cloudreach_world.gd`, and the complete
physical Meadows -> Cloudreach -> Meadows transition smoke all pass. The transition still prints
the pre-existing Meadows Terrain3D no-mipmap/deprecation warnings. After merging current `main`,
the combined Cloudreach chapter/world/handoff/realm/Heart/vitals/save unit selection passed
**129 tests / 1,511 assertions / 0 runner failures**. Five pre-existing tournament save methods
still emit the known false-green `SaveGame.save_game()` errors while the runner marks them `ok`;
this checkpoint does not claim those methods are clean.

The mandatory code-blind visual judge rejected the result on both bars:

- belongs to the world of the Tetherbound Meadows key art: **No**;
- looks like the same kind of game as the Palworld references: **No**.

That failure is correct and must not be softened. Cloudreach is currently procedural world
massing made from cliff cylinders, route/slab geometry, cloud meshes, and sparse instanced nature
props. It does **not** yet use or reproduce the Meadows presentation stack: Terrain3D-painted
surfaces, the dense procedural grass/flower/ground-cover layers, regional scatter density,
habitat prop clusters, creature/NPC activity, or content-aware HUD/world systems. The reviewer
described the result as a sparse floating-platform prototype, with repeated construction geometry,
flat materials/lighting, weak landmark identity, no creature-led life, broken Cloudreach context
in the Meadows HUD copy, and insufficient depth/scale cues. The full critique is preserved in
`ralph/reports/CLOUDREACH-PHASE2-0904/JUDGE.md`; final visual acceptance remains external.

Owner follow-up after seeing the sheet: creature presence is deliberately deferred and is **not**
a blocker for this environment pass. Exact resume point: do not advance the biome as though Phase
2 passed. First port the Meadows procedural grass, flowers, and ground-cover approach to
Cloudreach; give the procedural cliffs the same terrain/material language as the Meadows; densely
place the approved existing tree/rock assets; and iterate lighting, composition, depth, and
landmark silhouettes against the reference art. Preserve the suspended/vertical route design and
budget the surface dressing with MultiMesh/streaming where appropriate. Remove Meadows-only
objective/tutorial leakage from the evidence presentation, but do not divert this pass into
creature implementation. Recompose the six named reveals around unmistakable arrival, causeway,
Windscar, High Roost, Cliffhold, and summit silhouettes, then recapture the same six views,
remeasure, and repeat the code-blind visual review. Only continue to Phase 3 content after the
environment review materially closes the reported gaps. The named Cloudreach concept board is
still absent from the repo/local workspaces and remains a disclosed input gap.

The wrap also includes a **data-only Phase 3 contract**,
`data/config/cloudreach_chapter.json`, with focused coverage in
`tests/test_cloudreach_chapter_data.gd`: **16 tests / 729 assertions / 0 failures**. It authors the
three-act Storm Anchor story spine, Fly/Sky Shrine/counterweight progression, installed-body NPC
roles, replaceable encounter/trainer contracts, persistent pickups/resources/camps, map/audio
requirements, Captain Veyra finale, Cloudreach Heart + Water Realm Key rewards, Waterward reveal,
and durable aftermath. Nothing consumes this file at runtime yet. Do not interpret data presence
as implemented content. A separate read-only systems audit is preserved at
`ralph/reports/CLOUDREACH-PHASE3-AUDIT-0904/REPORT.md`; it routes the next agent through the
required realm-aware persistence, vertical 3D placement, dialogue-effect, catalogue injection,
map isolation, and gameplay-scene wiring seams before live content is spawned.

## 2026-09-04 — Cloudreach checkpoint 4 / Meadows-surface corrective pass

Branch: `codex/cloudreach-cliffs`. This is a coherent, tested visual-foundation checkpoint, not
final Cloudreach acceptance and not completion of Phase 2.

Cloudreach now uses the Meadows meadow-grass, verge, dirt-path, and rock-scree texture family on
its procedural geometry. Repeated hanging-cylinder route supports were replaced by continuous
irregular cliff ribbons and grounded landings. A new deterministic, chunked, distance-culled
MultiMesh layer places the production Meadows procedural grass, flowers, and bushes across
overlapping Cloudreach elevations, where the single-height Terrain3D grass sampler could not be
used safely. Approved production trees and rocks are clustered on region caps, route edges, and
landings. The capture harness now excludes Meadows-only HUD copy. No creatures were added.

Real Windows/OpenGL3 evidence from six production-scene gameplay viewpoints is stored in
`ralph/reports/CLOUDREACH-PHASE2-0904/`. On the local GTX 1060 at 1280x720, 24-frame samples
recorded 139–906 draw calls, 494,717–2,462,935 primitives, 139–906 objects, and 2.31–4.50 ms
measured frame time. These are local structural measurements, not ROG Ally claims.

Verification after the final geometry changes:

- Cloudreach world-data selection: **13 tests / 391 assertions / 0 failures**.
- Grass-field selection: **18 tests / 87,806 assertions / 0 failures**.
- `tests/smoke_cloudreach_foundation.gd`: **PASS** — six regions, twelve landmarks, five bridges,
  cover thresholds, and grounded player arrival.
- `tests/smoke_cloudreach_transition.gd`: **PASS** — production Meadows → Cloudreach → Meadows.
- Six-view GPU capture/performance run: **PASS**.

The mandatory code-blind visual judge still rejected both comparison bars. The corrective pass
improved surface continuity and scene population, but the distant geology remains too slab-like,
routes too straight and broad, landmark/crossing compositions too weak, and the palette/lighting/
vegetation pattern too flat and mechanical. Creature absence was explicitly excluded from the
verdict.

Exact resume point: keep creatures deferred. Replace broad route ribbons and blank slabs with
layered, irregular warm cliff forms, narrow embedded paths, terraces, recesses, and legible drops;
compose each of the six named views around one dangerous crossing and one distinct destination;
then improve wind-shaped vegetation clusters, warm/cool light separation, cloud layers, and
distant silhouettes. Recapture the same six views and repeat external visual review. The named
Cloudreach concept board is still absent from the repository/local workspaces.

## 2026-09-04 — Cloudreach checkpoint 5 / exposed-crossing and sky corrective pass

Branch: `codex/cloudreach-cliffs`. This is the pushed-safe continuation of checkpoint 4, not
completion of Cloudreach Phase 2 and not final visual acceptance. Creatures remain deliberately
deferred.

Cloudreach now loads the production Meadows cloud-sky/day look and keeps the Meadows-derived
surface family across its procedural highland geometry. Grass uses denser seven-blade procedural
tufts with flowers and bushes; approved production CommonTree and TwistedTree assets are placed
in clustered groves with an olive Meadows-derived leaf palette. Route shoulders and visible paths
are narrower. Authored bridge intervals now remove terrain, path, vegetation, and collision so
the rope and stone spans cross real chasms. Cliff ribbons use warmer high/mid/deep geological
bands, route-ridge walls have three irregular layers, and the summit destination is an open gate
with wings, buttresses, threshold, crenellations, towers, banners, and a spire instead of a solid
wall cuboid. The region surface query was tightened from an enclosing rectangle to a conservative
rotated ellipse so gameplay height checks do not report false ground beyond the rendered cap.

Final Windows/OpenGL3 capture evidence at 1280×720 is in
`ralph/reports/CLOUDREACH-PHASE2-0904/`. On the local GTX 1060, the six 24-frame samples recorded
**215–756 draw calls**, **347,926–6,479,973 primitives**, **215–756 objects**, and **3.05–8.49 ms
measured frame time**. These are local structural measurements, not ROG Ally claims.

Verification for the final source state:

- Cloudreach world-data selection: **13 tests / 391 assertions / 0 failures**.
- Grass-field selection: **18 tests / 87,806 assertions / 0 failures**.
- `tests/smoke_cloudreach_foundation.gd`: **PASS**, including a zero-ground-section assertion over
  the complete west ropeway interval.
- `tests/smoke_cloudreach_transition.gd`: **PASS**, Meadows → Cloudreach → Meadows.
- Six-view Windows GPU capture and contact-sheet assembly: **PASS**.

The required code-blind visual review still returned **No / No**. It recognized the bright sky,
suspended-land identity, long crossings, coherent palette, and danger-only oxblood, but found the
world still reads as an early platform/traversal prototype. The three ranked gaps are authored
lived-in density, finished landform/landmark vocabulary, and lighting/material/atmospheric depth.
That verdict is preserved in the evidence report and must not be softened.

Exact resume point: keep creatures deferred. Preserve the real chasms, sky, surface family, and
performance structure. Replace the remaining procedural-primitives look with authored irregular
cliff strata, terraces, recesses, constructed causeway edges/supports, landmark-specific parts,
route-side stories, and secondary-scale habitation clusters. Fix the visible seams and summit
grass/trench intersection, widen the destination reveals, and build several overlapping distance
layers before recapturing the same six views for external ChatGPT review. Do not advance to Phase
3 content or call Phase 2 complete until that environment review passes.

## 2026-09-04 — Cloudreach checkpoint 6 / irregular cliff-strata profile

Branch: `codex/cloudreach-cliffs`, continuing from checkpoint `61e24cedb`. The shared procedural
mesa builder no longer holds its high and low geological rings at perfectly constant elevations.
Each generated region mass and satellite crag now receives deterministic, independently phased
vertical strata variation while its walkable crown remains level. This directly reduces the
clean horizontal cutaway signature without changing routes, top-surface collision, or the
creature-deferred scope.

`tests/smoke_cloudreach_foundation.gd` passes after the change. A fresh six-view Windows/OpenGL3
capture and contact sheet also pass. The local GTX 1060 samples remain **215–756 draws** and
**2.86–8.44 ms** measured frame time at 1280×720. External visual acceptance remains required;
this bounded corrective pass does not complete Phase 2 or the biome. The new code-blind verdict
is **Meadows art direction: No / Palworld game category: Yes**. The latter is real progress, but
the former remains the controlling visual failure: authored density, natural terrain/depth, and
landmark-context richness are still below the reference.

## 2026-09-05 — Cloudreach integrated checkpoint, acceptance still open

Branch `codex/cloudreach-cliffs` contains the integrated chapter runtime and
round 3 environment work. The exact evidence and remaining work are recorded in
`archive/docs/VISUAL_PARITY_PROGRESS_cloudreach.md` and `docs/biomes/cloudreach/`. Fresh visual
judgment remains No/No; continuous play has reached Maela but has not completed
Fly, the upper chapter or finale. The full unit run found missing portrait
bindings for new payoff travelers and historical Gate F instrumentation failures;
these are not a clean-suite claim. New main 2cd711eb1 now needs integration,
especially its shared progression feed, HUD, combat and creature hooks. Preserve
both implementations' behavior when resolving those overlaps. No merge to main
or final acceptance is claimed.

## 2026-09-04 — Cloudreach checkpoint 7 / authored roadside-place pass

Branch: `codex/cloudreach-cliffs`, after merging current `origin/main` at `c5a16dfb9` without
discarding branch work. Astra implemented eight individually authored roadside pockets containing
59 installed production props across the six evidence routes: boulders, low rocks, bushes,
flowers, paving remnants, broken fence runs, wagons, crates, and barrels. Placement is scaled from
real imported bounds, kept clear of controller route centre lines, grounded only on the matching
stacked surface, and culled at 320 m. Meadows modular cottage prefabs now replace five primitive
house boxes in each generated settlement; their authored doorway/wall collision is retained.
Creatures remain deferred.

Fresh Windows/OpenGL3 capture evidence at 1280×720 is in
`ralph/reports/CLOUDREACH-PHASE2-0904/`. On the local GTX 1060, six 24-frame samples recorded
**252–915 draw calls**, **368,618–6,494,861 primitives**, **252–927 objects**, and **3.14–8.51 ms
measured frame time**. These are local structural measurements, not ROG Ally claims.

Verification for this source state:

- Cloudreach world-data selection: **13 tests / 391 assertions / 0 failures**.
- `tests/smoke_cloudreach_foundation.gd`: **PASS**, including all 59 authored props on supported
  ground and rejection of an unrelated stacked bridge surface.
- `tests/smoke_cloudreach_transition.gd`: **PASS**, production Meadows → Cloudreach → Meadows.
- Six-view Windows GPU capture and contact-sheet assembly: **PASS**.
- Code-blind visual review: **Meadows art direction No / Palworld game category Yes**.

The route now has more readable human-scale places, but the review still rejects the environment
on authored richness. The next visual pass must work at middle-distance composition scale: larger
irregular groves and clearings, terrain terraces/recesses, route-edge construction, and layered
atmospheric silhouettes. Do not answer this with more uniform micro-scatter. Remove the stray sky
marks and repair the harsh summit foreground shadow/grass intersection while doing that work.
- **Gate 3 / 4:** not started as a chain. Gate F S03 reached 6 failures outside its lane's
  scope; S04–S10 unverified as a chain.

  **CL-H1 / CL-H2 / CL-H7 are closed at the script level and half-proven in play
  (W21-HARNESS-FIGHTS-0904, `ralph/reports/W21-HARNESS-FIGHTS-0904/REPORT.md`).** Every fight
  in `S06`–`S09` and their capture twins was `press combat_quick, times: N`, the failure mode
  `SEGMENT_SCHEMA.md` names by name; all 21 blocks are now `fight_until_resolved` (or
  `chip_to_floor` for S08's two catch chips, which must NOT resolve), all 21 challenge
  conversations are `advance_dialogue_until_closed`, and every fight carries a
  revive-by-item-identity + switch ladder ending in the `active_creature_alive` gate.
  `tests/test_gate_f_segments.gd` (7 tests) pins all of it, seen red on the old files for the
  right reason at every one. **Played evidence, four logic-lane runs from the synthetic
  entries:** nine trainer fights resolved by predicate, every one ending on its own defeat
  flag with a live party — including **S06-22 against Dorn (41 presses, `defeated_quarry_dorn`
  set, lead at 94/170, bench untouched), the fight G3-BAND2 watched wipe a party of four
  inside its 34-press block**. S07 ran 154/3 through the whole relay ladder with zero faints;
  S09's ladder was observed handing the pilot from a fainted Tup to Ripple and winning a fight
  `can_challenge()` would otherwise have refused. **Still unplayed:** S06's Warrens fights
  (blocked by the S06-50 pin below), S08's captains (derailed at S08-79) and S09's checkpoint
  (derailed at S09-35), each behind a defect another lane owns.

- **A second `stick_navigator.gd` pin, same class as the Pond stall above and CL-H14, with the
  detail that changes the diagnosis (open, W21-HARNESS-FIGHTS-0904).** `S06-50`'s walk out of
  the Old Quarry pinned inside a **2.7 m × 2.5 m box at (336.2, 1.3, 1820.6) for its entire
  44,100-frame budget — 711 play seconds, `input_context` `world` throughout, "0 held"** — and
  took eleven Warrens steps down with it. Unlike the Pond stall it is **not frozen**:
  `dead_travel_m` climbed to 1,258 m while the body jittered inside that box, so the walker
  was pushing and moving. And the **next** `move_to` (`S06-55`) started from the same position
  and walked away cleanly at ~3.9 m/s, 470 m in 7,200 frames. A fresh walk call escapes ground
  the previous call cannot leave — navigator state, not terrain — one step after `S06-38`
  placed a workbench at the player's feet. Meanwhile **CL-H14's `S08-22` freeze did not
  reproduce** on that branch: `walked 839.5 m to (-345, 5060) in 10912 walking frames (0 held)`,
  region confirmed `the_ironwood_grove`. One clean crossing from a synthetic entry, not a
  refutation.

| Combat and reward VFX (CL-A2, W09-VFX 2026-09-04) | **Landed on `ralph/W09-VFX-0904`, judged twice** | Hit spark tinted by element and sized by damage, per-instance body flash, KO puff, catch sparkle, 1.5 s level-up flourish (beam, rising rings, motes, rim) — `scripts/vfx/`, `data/config/vfx.json`, hooks in `combat_manager.gd::_flash_at`/`_finish_catch`. `test_combat_vfx.gd` 8/8 (seen red with the hook removed); `smoke_combat`, `smoke_boss`, `smoke_trainer_battle`, `smoke_catching`, `smoke_combat_camera` green, benign `ERROR:` set unchanged. Round-1 blind judge: effects invisible at thumbnail, no hot colour, ring read as a stun — retuned (saturated tint, white-hot birth, contrast halos, wide gold rings, real beam). Round-2 verdict, frames and the band1_open draw-call delta: `ralph/reports/W09-VFX-0904/REPORT.md`. Level-ups are found by polling `Game.party` until the progression feed lands (seam in place); bench level-ups have no world flourish (D80). |
| Burrow Warrens | Working | `smoke_warrens` passes (379 s) |
| Stronghold and Gate E finale (Warden, legendary, ceremony) | Working (scripted) | `smoke_stronghold` (404 s) and `smoke_gate_e_finale` (486 s) pass; never played as a continuous chapter (Gate F S04–S10 unverified) |
| P2 | Legendary Chamber: cyan light-bars read as debug draws; no contact shadow under the machine or the creature; single-key lighting crushes blacks; wall slabs overlap with a black gap; at distance "you cannot tell there is a creature there at all" (three independent blind judges, W06-FINALE-0904 rounds 1–3) | `scripts/world/stronghold.gd`, `data/config/stronghold.json` | **partly fixed 2026-09-05, N05-WORLD-DRESSING-0905, one blind round (`ralph/reports/N05-WORLD-DRESSING-0905/JUDGE_CHAMBER.md`): the two ceiling light-bars and the corner void are called convincingly fixed; the floor conduits are recoloured not mounted, no contact shadow registers, the fill reaches floor/machine/creature but not the walls, and the oxblood trim pillars still render as black slabs.** The bars were the two `lit` trim girders at 15 m (0.6×0.5 m boxes of the 1.4-energy live teal, the full room width) plus the two floor conduits; a lit girder is now an oxblood girder carrying a slim line at `site.interior_conduit_energy` 0.9 (W06 measured the teal clipping to white at 2.2, holding hue at 1.15), and roofed floor conduits take the same. The "overlapping slabs with a black gap" were the exterior HallMassing towers reaching up to 4.75 m into all four interior corners (`tools/_probe_legendary_chamber.gd`); they are enclosed in masonry piers of the wall's own stone (5.05/4.05/4.05/3.55 m, non-solid, floor to ceiling). Lights: a warm fill inside the doorway wall, a shadow-casting spot over the bound creature's stand (rim + contact shadow toward the reveal stand) and a second over the machine's base — the first shadowed lights in the building (`type: spot`, `shadow: true` in `lights`). `smoke_stronghold` passes on the changed room. |
| TREE-SILHOUETTE (ROADMAP 2.3, `ralph/TREE-SILHOUETTE-0903`) | Real canopy-height variation at seven copses the composition plan names (the mound's south-west foot, both Gate Meadow flanks, both first-bend copses, both Long Field groves), each split into three co-located anchors at the same centre/radius — one tree at 1.4-1.6 scale, two at 0.5-0.7, the rest at 0.8-1.3 (`BAND1_COMPOSITION_PLAN.md` §3's copse recipe) — plus new silhouette anchors: the crest hero grown 1.1-1.15 → 1.3, a `CommonTree_1` pair crowning the crest right of the road, the Gate Meadow knoll's one `CherryBlossom_3` crown, the village-approach frame trunk, the comp4 near-tree pin, a basin far-side grove and one dead tree behind the mill, and a far-rim treeline and dead tree behind the South Bridge — 6 new trees/deadfall anchors, 36 requested instances net. **Fixed the directed defect**: `place3-pond-pocket` was occluded by the Pond's own unthinned grove after MID-LAYER's re-site (JUDGE-after.md: "darkest, most cluttered frame... fails the 30%-size test outright"); added one `clearings` window (order 1909, (-397,586) r16) centred on the fisher's camp rather than thinning the pocket, clearing the near-field trunks between the eye and the water while leaving the far 50m of grove to the mill's own clearing untouched, so "the Pond's density does not change" still holds. **Scale-lever decision**: built no band-scoped per-model size mechanism. `scatter_rules.gd` already has exactly two levers — a corridor-wide `model_scale` (touches every band) and per-anchor `scale_min`/`scale_max` overrides (already RNG-isolated, `test_an_anchor_override_does_not_leak_into_the_rest_of_the_layer`) — and splitting one copse into co-located sub-anchors with different scale ranges (the same technique MID-LAYER's own rock line + pebble skirt already used) gets deterministic peak/shoulder/body variation with no new code; per-instance yaw is already fully randomised in `_consider` regardless. Three siting bugs the plan's own guessed coordinates carried were caught before shipping, none by trusting a render at face value: probing real ground (`tools/_probe_tree_silhouette_0903.gd`, `tools/_probe_farbank_0903.gd`, headless heightfield arithmetic) found the plan's far-side-grove centre (-420,560) 3.2m *under* the -17.0 waterline (open pond, not the far bank) — re-sited to real dry ground at (-448,590), still on the crest-eye→mill sightline extended; and a live bake caught the comp4 near-tree pin's first re-site placing 0 of 1 because it sat inside MID-LAYER's own crest-window clearing. The third was caught only by computing each near-field anchor's bearing against its own capture stand's real eye/target/FOV (a systematic post-hoc audit run after the first render, prompted by a rendered comp1 frame that still showed the pre-existing rock line, not a new tree trunk, as the near element) rather than trusting the rendered thumbnail: the comp1 frame-trunk anchor at the plan's own (-58,199) was **146.7 degrees off the camera's forward axis — behind the eye, not in front of it** — it placed in every bake and never once could have appeared in the frame; the comp4 near-tree pin, even after its clearing re-site, sat at 62 degrees off-axis, outside the capture tools' 70-degree FOV. Both re-sited using the stands' own forward/right axes (comp1's trunk to (-53.1,187.4), 27 degrees off-axis; comp4's pin to (-234.4,326.6), 23 degrees off-axis) and confirmed both by eye in the re-rendered frames and by a second independent blind judge pass. | Godot 4.7-stable installed fresh in-container (none was present) and used for every check below — no self-report, including a full bake→test→render→judge cycle repeated a second time after the camera-geometry fix. `test_scatter_rules.gd`, `test_veg_corridor.gd`, `test_scatter_perf_budget.gd` (incl. `test_playground_bake_is_committed_and_fresh`) and `test_band_vegetation.gd` green on the final bake: 55 tests / 2,557,512 assertions, 0 failed; zero placement-failure warnings for any anchor this lane added or moved (the same four pre-existing under-placement warnings at coordinates this lane never touched persist unchanged from MID-LAYER's own report). Scatter re-baked and committed in the same commit as the config (`data/scatter/playground`, 256/256 regions, 825,979 placements). Perf proxy at `band1_open`, measured with `tools/perf_render_stats.gd` on the final bake: **6,940 draws / 11,747,201 primitives**, comfortably under the plan's 7,500/12.0M ceiling (and still under MID-LAYER's own 6,932/11,776,254 baseline on draws; primitives are within noise of it). All eighteen `BAND1_COMPOSITION_PLAN.md` stands (5 survey, 5 places, 8 composition) re-rendered from the final bake; two independent code-blind judges ran on two successive render passes (`ralph/reports/TREE-SILHOUETTE-0903/JUDGE-after.md` on the first pass, before the camera-geometry bugs were found; `JUDGE-after-fix.md` on the corrected final pass), each asked the plan's own two extra questions per frame plus required callouts on `place3-pond-pocket`, `comp1-village-approach` and `comp4-rise-look-back`. **place3, final pass: water and campfire land clearly** (water "the strongest water read in the set"; campfire "present and unoccluded"); **the bench is not legible** (not reported as occluded by anything — a props-scale question, `pond_fisher_camp`/`props.json` is 2.6's/WORLD-CONTENT's file, not vegetation's) and **the far-shore building reads as a generic cottage, not a windmill** (no sails/blades visible, and no occluder named — same finding both passes, so likely no windmill-specific geometry exists on that building at all, a props/asset question outside this lane's scope). **comp4, final pass: two distinct trunks, confirmed reading as a frame/proscenium** around the village view between them — the near-tree-pin fix visibly landed. **comp1, final pass: a real tree trunk is now visible near-left and in frame** (fixed from being completely absent — the plan's own coordinate was literally behind the camera) but the pre-existing rock-line boulder on the right (MID-LAYER's own scale-1.6 stone, an intentional element, not a defect) still reads darker and larger than the new trunk, so the Proof line's literal "darkest 5% must be a tree trunk, not a boulder" is not fully met — a colour-value/prominence tuning question now, not a placement bug, and honestly short of full compliance rather than claimed fixed. No stand in either pass reports a defect outside what `JUDGE-before.md`/MID-LAYER's own `JUDGE-after.md` already named (the plan's §8 fail condition), so nothing here is a regression. Both judges' top-ranked residual gap, unchanged across passes: several tree-lines this lane did not reshape by anchor (`place2-the-rise`, `place5-bridge-approach`, `comp7-pond-reveal`, `comp8-bridge-rim`) still read as "one lollipop, repeated" — these frames are dominated by `corridor_fill`'s own independent per-instance scale draw (already 0.5-1.45x, untouched by this lane) rather than by any named copse anchor, so the seven copses this lane DID reshape (verified in the committed config) carry real height variety a camera angle can still fail to foreground among a dozen unrelated corridor-fill trees. Reaching those tree-lines would mean turning more of the route's corridor-fill-dominated stretches into named copses (materially larger) or widening the `trees` layer's own corridor-wide `scale_min`/`scale_max` (re-rolls the whole 12km corridor's RNG stream per this file's own `_comment_seed_offset_of12r`/`BAND2-FLOOR` precedent, out of this task's band-scoped remit); neither attempted. **Correction, 2026-09-04 (G3-LAND): the parenthesis is wrong, and it has since been repeated in `docs/decisions/D73…` §5 and from there into the closure plan, where it was briefly treated as a hard bake-ordering constraint.** Widening a scale range does not re-roll anything. `scatter_rules.gd::_place_one()` draws one `rng.randf_range(low, high)` for scale, then one `randi_range` for the model and one `randf_range` for the yaw, unconditionally and in that order, with every rejection test resolved before them and none reading the scale — so a wider range consumes the same draws and yields identical placements, models and yaws, with only the sizes changed. The cited precedent does not support the claim either: `seed_offset` re-rolls because the seed is literally `base_seed + offset * 7919 + layer.seed_offset`, which a scale range never touches. `vegetation.json`'s own Band 2 anchor note had it right all along (*"RNG-safe: a wider `scale_min`/`scale_max` range draws the same one `randf_range()` call per placed instance regardless of its bounds"*). What genuinely re-rolls corridor-wide: an anchor's `count` (it moves the attempt budget in the shared stream) and a per-layer `band_scale` (`_place_verge`). So this residual gap is reachable by an ordinary tuning change in any bake window, not gated behind a corridor-wide re-roll. `smoke_playground.gd` fails on this branch ("the gather resolved 0.83-0.84 through the swing, well past the 0.60 impact pose") — confirmed **pre-existing, not caused by this lane**: reproduced identically on the unmodified pre-edit tree via `git stash`/re-run/`git stash pop` in this same container, an environment-dependent swing-timing issue unrelated to vegetation. |
- **Gate 2's Pond stall — the walker, not the world (open, scoped as 2.9).** Walking straight at
  the Old Bram detour from the Pond shore, `stick_navigator.gd` freezes a real player body at
  **(−328.7, −14.2, 505.3)** — to a centimetre, on three independent runs — for **543 play
  seconds** with locomotion enabled throughout ("0 held"); on the first run it never recovered
  and the leg reported "stopped 658.8 m short". This is **not** a world hole:
  `tools/gate_f/probe_pond_stranding.gd` stands the real body at that exact coordinate and at
  eight points on a 6 m ring, injects a real full-deflection stick, and finds **0 of 10 stands
  wedged** — every stand walks 12–17 m in five or more of eight bearings, resting on the
  authored heightfield (worst delta 0.09 m), `on_floor`, touching nothing but `Terrain3D`. The
  Pond is a real 14 m basin (water surface authored at −17.0 m) and the evidence run now authors
  the climb out of its north-east shoulder (`S05-32x`, the RIG-F6 precedent — legs checked
  against a route that was actually walked, never a teleport past geometry): 23 s instead of 543.
