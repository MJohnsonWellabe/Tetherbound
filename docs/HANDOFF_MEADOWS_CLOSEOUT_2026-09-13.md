# Meadows closeout handoff — 2026-09-13

**Status: Meadows is not complete.** This is the current execution handoff for
`codex/full-game-0912` at `5732d1239`. It records a deliberate owner-requested
session stop. It supersedes older handoffs for current-state evidence, but it
does not supersede the 2026-09-12 owner directive, raw playtest, `CLAUDE.md`, or
the Meadows exit criterion.

Read first, in order:

1. `CLAUDE.md`
2. `docs/00_START_HERE.md`
3. `docs/owner/OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md`
4. the newest raw 2026-09-12 owner playtest located through `docs/owner/README.md`
5. this handoff
6. `docs/acceptance/MEADOWS_EXIT_CRITERION.md`

## Strict state at the stop

| Requirement | Proven now | Still open |
|---|---:|---|
| 2026-09-12 playtest ledger | **41/43** | Terrapup rest; Burrow Warrens visual quality |
| Named Meadows location visual ledger | **19/23** | The Rise; The Old Quarry; Old Mill Crossing; Burrow Warrens |
| A1–A11 player-voice gates | **0/11 proven on the current revision** | Full continuous player/campaign evidence is still required |

Do not convert focused tests, a complete frame count, or implementation intent
into a pass. The four named locations remain red until their current-revision
production frames and independent verdicts pass. A1–A11 remain unproven until a
fresh continuous run demonstrates each behaviour.

## Current source checkpoints

- **The Rise R13** — `340168da4`, test-order correction `e1c79ddb0`.
  All 12 uphill terrace entries start on the carried shared top edge. Focused:
  **11 tests / 423 assertions / 0 failed**.
- **The Old Quarry R31** — `fb1ae0b1b`. Aprons are dense terrain-conforming
  local grids; evidence rays target their actual upward faces without excluding
  Terrain or the wagon; live AABB continuity replaces the broken origin check;
  arrival lens is pulled back. Focused as part of the combined run below.
- **Old Mill Crossing R14** — `c7eb5ff47`, hydraulic seam correction
  `21230530d`. Focused: **7 / 217 / 0**.
- **Burrow Warrens R17** — `5732d1239`. This is a new visual rebuild after an
  independent R15 failure: separated visible/collision bank surfaces, broader
  low threshold cut, convergent wear, longer passage/chamber overlaps, removed
  false ceiling haze cards, clearer guardian evidence camera. **Static checks
  only; no Godot parse, production capture, or independent R17 verdict yet.**
- **Terrapup rest R38** — `b65298ef2`. This abandons the failed R36/R37 bone
  scaling experiments. It keeps the recognizable, height-passing R35-B pose and
  creates a private reversible rest-only ArrayMesh whose lower torso shell maps
  into a 0.14 m contact span. Head, limbs, tail, upper shell, gameplay body and
  collision are untouched; original meshes restore on wake. **Static checks
  only; no focused Godot run or production R38 capture yet. `species.json` is
  deliberately unpromoted.**
- **Warrens R16 + Quarry R31 focused batch** — **18 tests / 538 assertions /
  0 failed** before R17 replaced the Warrens implementation. R17 therefore
  needs its own focused rerun.
- Existing accepted receipts remain: Long Water R5 `12c4971440`, Stronghold R6
  `456310a6e`, Meadows scatter rebake `ae313b3ce`, multiplayer identity acceptance
  `7fce90d4e` (74 assertions).

## Production evidence from this stop

Preserve every directory; failed captures are diagnostic evidence.

- `ralph/reports/MEADOWS-0912/THE-RISE-IDENTITY-R12/manifest.json` — **FAIL**.
  Real player reached 8 waypoints, then stopped 0.383 m past the joint at the
  exposed ShelfTreadA leading face. R13 is the source fix.
- `ralph/reports/MEADOWS-0912/THE-RISE-IDENTITY-R13/` — final session attempt
  fell back to ANGLE, became non-responsive while holding about 3.9 GB private
  RAM, and was terminated after repeated live-handle waits. No pass or frames
  are claimed. Use a fresh retry directory.
- `ralph/reports/MEADOWS-0912/OLD-QUARRY-TERRACE-R30/manifest.json` — **FAIL**.
  Only the two cut-face frames were accepted. Terrain blocked apron rays because
  the sampler preferred buried skirts; world-space vertices with origin nodes
  also broke continuity; the close arrival lens cropped the enlarged handoff.
  R31 addresses those specific causes.
- Old Mill R14 production attempt — **no evidence accepted**. Godot exhausted
  system RAM during scatter construction and was terminated after it stopped
  progressing. Focused source remains green.
- `ralph/reports/MEADOWS-0912/final-warrens-15/manifest.json` — all 9 frames
  exist but `complete:false`. First day arrival grounded 0.89 m below the sampled
  surface; R16 added a longer collision warmup. More importantly, independent
  review was a **visual FAIL**: bunker/panel exterior, tube/fins at threshold,
  unclear wear-to-opening hierarchy, ceiling artifacts, and obscured guardian.
  R17 is the unrendered response.
- `ralph/reports/MEADOWS-0912/terrapup-rest-r37/manifest.json` — zero-frame
  allocator crash. `terrapup-rest-r37-retry-01/manifest.json` — completed
  **FAIL**, height ratio 1.191 and torso lower-quartile 1.040 m. Its images show
  the body still upright/distorted. Do not revive R36/R37 bone scaling.

## Laptop/Godot operating constraint

This machine has **7.64 GB visible system RAM**. A single production Meadows
boot constructs roughly 387,184 scatter props plus 62,140 grass instances and
can hold 2–4 GB private memory. One run can therefore fail even without a second
Godot process.

- Exactly one Godot process at a time. Source-only agents may run in parallel;
  they must not start Godot.
- Before a production boot, confirm no `Godot*` process remains and allow memory
  to recover. About 3 GB free was enough for several boots but not a guarantee.
- Production evidence command uses non-headless `--rendering-driver opengl3`.
  Require the native line `OpenGL API 3.3.0 NVIDIA ... Compatibility`. The final
  Rise attempt fell back to `ANGLE ... Direct3D11` and hung; do not count or
  repeat an ANGLE result. A Windows restart may be the cheapest clean reset.
- If a failed Godot process is non-responsive and retaining gigabytes after its
  own timeout, terminate that exact process/session. Never overlap a retry.

At handoff time there is no intentional Godot process left running.

## Exact next-session order

### 1. Parse and focused-gate the two new checkpoints

Run one headless batch before any production boot:

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd -- --only=burrow_warrens_visual_identity,creature_rest_pose,companion_terrapup_capture_0912,rise_visual_identity,old_quarry_visual_identity,old_mill_crossing_visual_identity
```

If R17 or R38 fails, fix the implementation; do not weaken its gate.

### 2. Prove and promote Terrapup R38

Use a native production boot and fresh output:

```powershell
& 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe' --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/capture_companion_terrapup_0912.gd -- --candidate-sheet --output=res://ralph/reports/MEADOWS-0912/terrapup-rest-r38
```

Required numeric gates remain height ratio `<=0.82`, torso lower-quartile
`<=0.20 m`, valid grounding/replay, and recognizable visual anatomy. If and only
if all pass, copy the winning recipe and measured production grounding offset to
Terrapup's `rest_pose` in `data/creatures/species.json`, run the normal full
companion/formation/rest capture, and obtain an independent verdict. That closes
playtest row T0#13 only after the production recipe passes.

### 3. Capture the four red locations, strictly serialized

Use fresh directories after any failed attempt:

1. Rise R13: `tools/capture_the_rise_identity.gd`, output
   `THE-RISE-IDENTITY-R13-RETRY-01`.
2. Quarry R31: `tools/capture_old_quarry_visual_identity.gd` (current hard-coded
   output is `OLD-QUARRY-TERRACE-R31`).
3. Old Mill R14: `tools/capture_old_mill_crossing_identity.gd`, output
   `final-old-mill-14-retry-01`.
4. Warrens R17: `tools/capture_burrow_warrens_visual_identity.gd`, output
   `final-warrens-17`.

Each needs its fail-closed manifest plus an independent, non-author visual review.
Warrens must pass both its named-location bar and playtest visual row T2#5.

### 4. Close ledgers, then run chapter acceptance

Only after Terrapup and all four locations pass:

1. Update/rebuild the strict 43-row audit from current evidence. The old
   `STRICT-43-ROW-AUDIT-2026-09-12.md` is stale and must not be reused as proof.
2. Update the 23-location ledger from the four independent verdicts.
3. Run proportionate full regressions and build/package verification.
4. Run the full, non-Quick Gate F/KICKOFF campaign using
   `docs/prompts/70-MEADOWS-full-chapter-integration-playthrough.md` and
   `docs/acceptance/KICKOFF_RUN.md`.
5. Judge A1–A11 from that continuous run. Current strict assessment is still
   **0/11 proven**. A4 and A5 have partial implementation/visual evidence; the
   latest owner playtest contradicts A1, A3, A6 and A7; A2 and A8–A11 lack a
   current continuous proof chain (A11 has focused post-Warden frames only).

Do not declare Meadows complete at 43/43 or 23/23 alone. Completion requires both
ledgers, current regression/package evidence, and all A1–A11 evidenced through the
continuous chapter.

## Workspace hygiene

- Preserve user-owned tracked modifications in `project.godot` and
  `tests/smoke_net_movement_two_peers.gd`.
- Preserve untracked capture reports, `.uid` files, `0.001`, and the transient
  Terrain3D debug DLL unless the owner explicitly asks to remove them.
- Exact-stage only. Never blanket-add, clean, reset, or delete report trees.
- The last scoped commits are:
  - `5732d1239` Warrens R17
  - `b65298ef2` Terrapup R38
  - `a802e9656` Terrapup R37 cache/test (failed production; historical evidence)
  - `d21fa1229` Warrens R16 warmup
  - `fb1ae0b1b` Quarry R31
  - `e1c79ddb0` / `340168da4` Rise R13
  - `21230530d` Old Mill R14 seams

Cloudreach, Stormwood and Tidewake work was intentionally not re-audited by this
Meadows-first lane. Do not infer their completion from old lane messages. After
Meadows meets its full exit criterion, resume them from the newest owner records
and current worktree evidence, not from the September 7 allocation text.
