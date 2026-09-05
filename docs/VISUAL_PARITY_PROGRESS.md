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
