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

### Route-strip investigation (not landed)

Phase 0.1 was reproduced and prototyped. A real party Terrapup was summoned,
the route frames showed trainer + companion, and a real CombatManager fight
was entered. The blind visual judge found the two traversal frames readable
and answered **yes** to the broad creature-adventure category, but rejected the
fight frame because the Bramblebun silhouette was too small and the trainer
was absent. A stricter three-subject capture then exposed two more details:

1. camera distance must be solved against all three projected bounds, not only
   the two creatures;
2. the scripted flee must wait beyond combat's 0.25 s input guard, and cleanup
   must run even when a capture assertion fails.

The prototype was reverted because its final bounded GPU smoke was red. There
is no half-finished route-strip implementation in this checkpoint.

### Exact resume point

1. Implement `docs/FINISH_THE_MEADOWS.md` Phase 0.1 in
   `tools/_capture_route_strip.gd`: real party/summon path, trainer + companion
   in every road frame, one real fight frame containing trainer + both creature
   silhouettes, projection-based rejection, and unconditional fight cleanup.
   Wait beyond CombatManager's 0.25 s input guard before scripted flee.
2. Run a Windows GPU smoke with `--bands=1 --max=2 --fast`; inspect all three
   PNGs and run the code-blind visual judge. Do not accept a frame merely
   because a projected AABB is technically on screen.
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
