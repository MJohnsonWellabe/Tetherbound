# Visual Parity Progress

Final visual acceptance belongs to external ChatGPT review. This file records
only implementation, test, capture, and handoff state.

## Exit checkpoint — 2026-09-04

- Working branch: `codex/meadows-visual-parity`
- Working copy: `D:\Tetherbound-source`
- Base first updated for PR #37 at `b83123738`, then merged through the final
  upstream `origin/main` at `90efc0d5b`; no in-progress work was reset.
- Godot: `4.7.stable.official.5b4e0cb0f`
- Renderer used: Windows Compatibility / OpenGL 3.3 on an NVIDIA GTX 1060 3GB.
- VP0 is **not complete**. No visual-parity pass is claimed or accepted.

### Landed in this checkpoint

- `tools/capture_check.gd` now recognises the shipped tiled GrassField through
  `_ring_instances`, while retaining the legacy parent-MultiMesh fallback.
  The former check falsely rejected real grass because the tiled field leaves
  its parent MultiMesh empty by design.
- `tests/test_capture_check.gd` exercises tiled live grass, the legacy shape,
  and a genuinely empty field.
- `tools/vp_capture_windows.ps1` now retains child capture/performance exit
  codes and fails the top-level run if any stage fails. Previously it could
  print `DONE` and exit zero after a failed ground or combat child process.
- Current-main scatter and terrain manifests were regenerated from the merged
  configs. Freshness and scatter-budget tests pass.

### Verification

Targeted headless suite:

`capture_check,kickoff_script_syntax,scatter_perf_budget,terrain_bake_freshness`

Result: **10 tests, 19 assertions, 0 failed**.

PowerShell parser check for `tools/vp_capture_windows.ps1`: **PASS**.

Earlier pre-PR-37 baseline capture measured the desktop structural proxies at
1280×720 as follows. These are not ROG Ally frame-rate claims:

| View | Draw calls | Primitives | Objects |
|---|---:|---:|---:|
| Village high | 4,787 | 8,189,284 | 4,624 |
| Band 1 open | 6,901 | 10,651,618 | 5,920 |
| Hall approach | 3,865 | 3,383,053 | 4,226 |

The incomplete/mixed VP0 evidence payload was intentionally removed before
commit. It must not be treated as a completed baseline.

### Prompt 75 intake completed

- Read `docs/prompts/75-CODEX-pull-in-pickup-assets-and-finish-the-meadows.md`,
  prompt 73, prompt 74 (including procedural-first signpost/bridge §7),
  `docs/FINISH_THE_MEADOWS.md`, its 2026-09-04 addendum, and the pickup/blind-
  review entries in `docs/specs/ASSET_LEDGER.md`.
- The four shipped GLBs were not edited. Preserve the owner-approved open
  candy wrapper/topology and potion-plant stray-bud items.
- No pickup wiring, candy mechanics, progression feed, signpost, bridge, or
  Meshy work was started in this checkpoint.

### Route-strip investigation (landed 2026-09-05, lane W01-ROUTE-STRIP-0904)

Phase 0.1 was reproduced and prototyped by Codex. A real party Terrapup was
summoned, the route frames showed trainer + companion, and a real
CombatManager fight was entered. The blind visual judge found the two
traversal frames readable and answered **yes** to the broad creature-adventure
category, but rejected the fight frame because the Bramblebun silhouette was
too small and the trainer was absent. A stricter three-subject capture then
exposed two more details:

1. camera distance must be solved against all three projected bounds, not only
   the two creatures;
2. the scripted flee must wait beyond combat's 0.25 s input guard, and cleanup
   must run even when a capture assertion fails.

That prototype was reverted. Lane W01-ROUTE-STRIP-0904 then implemented it
from those findings on branch `ralph/W01-ROUTE-STRIP-0904`:

- `tools/capture_check.gd`: `readable_problems()` (pure projection, so the
  headless unit suite can see it fail) refuses an empty subject list, a
  subject behind the camera, under 12 % of frame height, more than a quarter
  cropped, occluded by geometry, overlapped on screen by another subject by
  more than half, or (opt-in) filling more than a cap of the frame;
  `fit_distance()` solves the smallest camera distance at which every subject
  fits the safe area, optionally stepping out until none exceeds the cap.
- `tools/_capture_route_strip.gd`: summons the party's active creature through
  the production path, stands the pair side by side on every road stand
  (canvas layers hidden), enters one real fight per band through the interact
  press (director fallbacks recorded in the manifest), solves the fight camera
  from a 3.2 m eye over seven bearings (front quarters first), refuses and
  lists any frame the check faults, flees only after the 0.25 s guard, and
  asserts the world is back in the `world` input context via
  `gate_f_probe.input_context()` after a process frame has run.
- Three in-container findings, all in the tool: WorldWeather is thawed by the
  world's boot coroutine (re-pinned before every shutter); a `--max` that
  counted saved frames walked the whole band when every frame was refused
  (now counts attempted stands); the context read `locked` on the physics
  tick a fight ended (read after a process frame).

Evidence, sheet and the code-blind verdict:
`ralph/reports/W01-ROUTE-STRIP-0904/REPORT.md`.

### Exact resume point

1. **Run the GPU route strip on the owner's Windows machine** with the landed
   tool (`--bands=1 --max=3 --fast` first, then the full strip via the kickoff)
   and put the sheet to the code-blind judge. The in-container frames are
   llvmpipe: trust composition, silhouette and scale, not lighting.
2. If the judge still faults fight readability, the levers are
   `FIGHT_EYE_H`, `FIGHT_MAX_HEIGHT_FRAC` and the bearing order in
   `_capture_route_strip.gd`, and `READABLE_MIN_HEIGHT_FRAC` in
   `capture_check.gd` — never the check's refusal.
3. Continue Phase 0.2 (`input_context`) and Phase 0.3 (S08-22 freeze).
4. Build prompt 73's progression feed before candy, record the bond-ladder
   decision, then wire prompt 75's four props through
   `scripts/world/item_cache_pickup.gd` in regional batches. Candy must consume
   the shared progression feed. Signpost and bridge remain procedural-first.

## Standing constraints

- No new creature meshes or Meadows Meshy generations.
- Five owned creatures total; no storage or hidden sixth slot.
- Do not alter the shipped candy/potion geometry open items unless the owner
  explicitly reopens them.
- ROG Ally performance remains unmeasured in this checkpoint.

## Cloudreach environment corrective pass — 2026-09-04

This is a Cloudreach visual-foundation checkpoint, not a completed VP pass and not final visual
acceptance. Creatures were deliberately deferred so the environment could be judged on its own.

- Ported the Meadows surface family to Cloudreach procedural geometry: meadow grass, verge, dirt
  path, and rock scree with world-space triplanar mapping.
- Added deterministic, chunked, culled MultiMesh grass, flowers, and bushes using the production
  Meadows procedural meshes across Cloudreach's stacked elevations.
- Replaced repeated route-support cylinders with continuous irregular cliff ribbons and grounded
  route landings; added clustered production trees and rocks.
- Captured six real production-scene gameplay views and measured 139–906 draws and 2.31–4.50 ms
  frame time on the local GTX 1060 at 1280x720. This is not ROG Ally evidence.
- Passed the Cloudreach world-data and grass-field selections plus both foundation and full
  Meadows → Cloudreach → Meadows smoke paths.
- Code-blind review still returned **No / No**. The next pass must solve the gray slab geology,
  runway-like routes, weak exposed-crossing/destination compositions, flat palette and lighting,
  and mechanically uniform vegetation. Creature absence was not counted against the result.

Evidence and the full critique are in `ralph/reports/CLOUDREACH-PHASE2-0904/`. Exact resume:
reshape the terrain and route composition first, then refine materials/lighting/vegetation and
recapture the same six views for another external review.

## Cloudreach environment corrective pass 2 — 2026-09-04

This additional checkpoint keeps creatures deferred and is still **not accepted**. Cloudreach now
uses the Meadows cloud-sky/day look, denser seven-blade procedural grass plus flowers and bushes,
olive-palette production tree assets, warmer three-band cliff ribbons, narrower paths, and true
terrain/collision gaps beneath authored bridge spans. The summit stronghold is now an open,
articulated gate complex rather than a solid block.

Final six-view Windows/OpenGL3 evidence measured **215–756 draws** and **3.05–8.49 ms** per sampled
frame on the local GTX 1060 at 1280×720. World-data and grass-field unit selections passed, as did
the foundation smoke, complete Meadows → Cloudreach → Meadows transition smoke, GPU capture, and
contact-sheet assembly.

The code-blind judge again returned **No / No**. The environment has a clearer suspended-highland
identity, but still reads as a traversal prototype because it lacks authored lived-in density,
finished geological/architectural vocabulary, and layered lighting/material/atmospheric depth.
Exact resume: retain the current grass/trees/sky/real-chasm foundation; replace the remaining
primitive landforms and landmarks with irregular strata, terraces, built edges/supports,
human-scale detail clusters, and multiple distance layers; repair the visible seams and summit
grass/trench intersection; then recapture the same six views for external ChatGPT acceptance.

## Cloudreach irregular-strata corrective pass — 2026-09-04

The procedural cliff body's high and low rings now rise and fall independently around every
region and satellite crag instead of forming ruler-flat horizontal bands. Walkable crowns remain
level, preserving traversal and collision. Foundation smoke and the six-view GPU capture passed;
the final local GTX 1060 samples measured **215–756 draws** and **2.86–8.44 ms** at 1280×720.
Creatures remain deferred. The new code-blind result is **Meadows art direction: No / Palworld
game category: Yes**. The category bar is a genuine improvement; the art-direction failure means
this remains an evidence-backed visual correction, not Phase 2 acceptance.

## Cloudreach authored-roadside pass — 2026-09-04

Astra added eight distinct route-side places using 59 installed, bounds-normalized production
rocks, shrubs, flowers, paving remnants, fences, wagons, crates, and barrels. Meadows modular
cottages now replace the primitive settlement house boxes. All details are deliberately off the
controller route centre, reject unsupported/stacked surfaces, and use distance culling. Creatures
remain deferred.

Foundation smoke, world-data tests, the full Meadows → Cloudreach → Meadows transition smoke,
Windows GPU capture, and contact-sheet assembly pass. The local GTX 1060 evidence measured
**252–915 draws** and **3.14–8.51 ms** at 1280×720. Blind review
remains **Meadows art direction No / Palworld game category Yes**: the authored pockets improve
human-scale grounding, but broad empty platforms, simple cliff faces, pale voids, and repeated
straight corridors still dominate. Next: larger middle-distance clusters, terraces/recesses,
constructed route edges, atmospheric layers, and visible artifact repair—not more uniform scatter.

## Cloudreach integrated chapter / round 3 checkpoint — 2026-09-05

The chapter runtime now mounts the main story, cast, trainers, resources, camps,
Fly trial and temporary non-owned carrier, realm saves/building/recovery, finale,
and persistent side-world payoffs. This is an implementation checkpoint, not
chapter acceptance. Full continuous evidence currently reaches Maela; the moving
challenge prompt is under investigation. Fly, upper routes and the finale remain
unproven as one uninterrupted path. Separate production payoff checks pass 57/57;
the production finale regression passes 62/62. Trainer-only powers 24/28/32/36
produced 28/28 real-input wins plus a real wipe/recovery/retry; finale hazards were
not included in that balance probe.

Round 3 real production captures are in
`ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round3/`. Fresh Astra judgment is
**Meadows reference No / Palworld reference No** (`JUDGE-ASTRA.md`): repetitive pale
cliffs, rigid path borders, bare ground and sparse landmark settings remain.
The causeway frame is obstructed; the airborne and payoff capture harness fixes
are prepared but have not yet produced acceptable replacement evidence.

Ten views at 1280×800 on Windows/GTX 1060 measured a maximum 4,293 draws and
7.60M primitives. Three ten-second static samples measured means 8.59–11.26 ms
and p95 8.74–11.47 ms. These are local static-view results, not Ally or continuous
frame-pacing acceptance. Creatures remain deferred; final visual acceptance is
external ChatGPT review.

Resume: preserve this checkpoint, merge `origin/main` 2cd711eb1 (new Meadows
progression/UI/combat/companion/VFX/portrait/route work), reconcile shared APIs,
run regression checks, finish the continuous chapter and corrected real Fly/
payoff evidence, then implement the next geometry/material/composition pass.

## Cloudreach round 4 — 2026-09-05

Main `2cd711eb1` is integrated in pushed checkpoint `1f1f23652`. Round 4 joins
the turf/material family, warms the cliff stone, replaces distant tabletop
masses with installed irregular rock geometry, and develops settlement,
shrine and summit edges. Real twelve-frame evidence and the original blind
verdict are in `ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round4/`.

Fresh Astra verdict: **art direction Yes / Palworld presentation No**. Final
external ChatGPT acceptance remains open; creatures remain deferred. Terrain
joins, uniform ground bands and unfinished apparatus still need correction.
The upper watch's new position also obscures the east arrival and must move.

Production foundation passes; five related unit files pass 37 tests / 1,195
assertions. Real-input airborne Fly capture passes. Five rendered side-payoff
views pass 63/63 checks, and live captain/relay/save checks pass 64/64. A separate
five-member near-level reward fixture passes its 65 functional checks but
reveals a genuine banner/party-rail overlap; layout correction is in progress.

Local Windows / GTX 1060 / Compatibility / 1280×800 sustained static samples
measure mean 8.20–11.70 ms, p95 8.34–15.18 ms, maximum 15.81 ms. Maximum geometry
across twelve views is 4,416 draws / 7.486M primitives. The arrival tail regresses
against round 3; these are neither Ally nor continuous-play acceptance figures.
Failed first launches and concurrent-load measurements remain disclosed in
`round4/IMPLEMENTATION.md` rather than being replaced by successful retries.

Resume: finish the live five-member HUD regression and continuous flight-perch
approach/trial, then address the blind judge's terrain contacts, asymmetric
route vegetation, bell/veil construction, watch alignment and arena surface
grouping. Preserve the passing palette and real collision/progression gates.

### Full-team HUD follow-up

The simultaneous five-level-up receipt no longer covers the party rail or
controlled creature. The same production presenter retains all five actual
stat/XP results, exact payout and relay instruction in a tunable upper-right
card. Actual 1280×800 captain/relay/save capture passes 74/74; the expanded
HUD lifecycle passes 70/70 and related units pass 43 tests / 159 assertions.
Fresh code-blind review finds no blocking visible HUD defect, with receipt
density, relay-object occlusion and faint Energy track recorded for refinement.

`ralph/reports/CLOUDREACH-HUD-0905/` holds the verdict and one contact sheet.
Its four arena frames return A No / B Yes; this narrower sample does not
replace the twelve-view round-4 result or accept the arena. Short live means
24.12–28.34 ms share the host with continuous diagnosis and are not a sustained
performance baseline. Round 4 itself is pushed as `ca7d87113`; round 5 is active.
