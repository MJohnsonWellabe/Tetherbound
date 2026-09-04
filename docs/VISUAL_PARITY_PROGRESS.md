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
