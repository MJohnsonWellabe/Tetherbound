# Meadows closeout handoff — 2026-09-13

**Status: Meadows is not complete.** This is the current execution handoff for
`codex/all-branches-integration-0913`. It began as a deliberate owner-requested
session stop and is now the live consolidated desktop closeout record. It
supersedes older handoffs for current-state evidence, but it
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
| 2026-09-12 playtest ledger | **42/43** | Burrow Warrens visual quality |
| Named Meadows location visual ledger | **20/23** | The Rise; The Old Quarry; Old Mill Crossing |
| A1–A11 player-voice gates | **0/11 proven on the current revision** | Full continuous player/campaign evidence is still required |

Do not convert focused tests, a complete frame count, or implementation intent
into a pass. The four named locations remain red until their current-revision
production frames and independent verdicts pass. A1–A11 remain unproven until a
fresh continuous run demonstrates each behaviour.

## Desktop continuation — 2026-09-14 Terrapup promotion

This is the newest ledger-changing evidence and supersedes the older Terrapup
R38/R39 execution notes below. Playtest row T0#13 is now **PASS**; only Burrow
Warrens visual quality remains open in the 43-row playtest ledger.

- The shipped Terrapup GLB now contains a seventh, dedicated `rest` clip authored
  from the existing local rig. It preserves the six gameplay clips and uses a
  baked 90-degree flank pose with mirrored local-Z limb tucks. Runtime rest plays
  the terminal clip and holds its final frame; no whole-model roll, mesh scaling,
  runtime vertex deformation, or external generated-art service is involved.
- R40 exposed a false-positive in the evidence harness: CreatureBody's separate
  four-vertex `ContactShadow` helper supplied the recorded low point while the
  skinned creature visibly hovered. R41 excludes that helper from anatomical
  bounds and calibrates against the actual skinned minimum.
- Focused rest/capture contracts pass **16 tests / 201 assertions / 0 failed**.
- `final-terrapup-rest-17-r41/manifest.json` is a native-NVIDIA production
  Meadows/Stronghold proof with **4/4**, `complete:true`, no failures or warnings,
  final animation `rest`, 15,616 skinned vertices, no surface failures, height
  **2.270 m** (ratio **0.590**), ground offset **-0.100 m**, and anchor error
  **0.000 m**.
- A fresh independent blind review returned **PASS** across both day/night side
  and three-quarter pairs: clearly horizontal side-rest, credible weight-bearing
  bed contact, relaxed lowered head/forelimbs, and no crushing, tearing, clipping,
  or other obvious deformation.
- `final-companion-15-r40` is retained as rejected diagnostic evidence: its 8/8
  manifest was the ContactShadow false-positive and its rest pixels visibly
  hovered. `final-companion-16-r41` correctly remained incomplete when the
  unrelated moving formation frame projected at 43% against the unchanged 42%
  camera cap. The targeted R41 rest proof avoids weakening that accepted camera
  gate.

Current strict totals are therefore **42/43 playtest**, **20/23 named
locations**, and **0/11 current-revision continuous A-gates**. Burrow Warrens
now passes named-location identity at R38, while its production-quality playtest
row remains open. Terrapup is no
longer on the shortest ledger path; continue with direct production-subject
repairs for Rise, Quarry, Old Mill, with Warrens still owning the
last playtest row.

## Takeover update — later 2026-09-13

This section supersedes conflicting execution details below it. The strict
ledger totals above are unchanged.

- Focused handoff batch passed **52 tests / 1,414 assertions / 0 failed** after
  `8157f8d2f` fixed detached Terrapup geometry validation.
- Terrapup R38 was production-proven numerically, promoted in `6f2802dbe`, and
  captured normally in `final-companion-27` with 8/8 frames. A required blind
  visual review then **failed frames 05–08**: the result reads as an upright
  model rotated/collapsed onto the bed, with implausible limbs, an inverted head
  read and no supported spine/flank. Frames 01–04 formation passed. Therefore
  T0#13 remains open and the lower-shell/bone-offset strategy is exhausted; the
  next Terrapup attempt must be a genuinely authored rest animation/rig pose,
  not another deformation tweak. Do not treat the promoted R38 config as an
  accepted endpoint.
- Rise R13 production diagnostic `THE-RISE-IDENTITY-R13-DIAGNOSTIC-02` failed
  closed at waypoint 8. New telemetry in `41dd6ea6b` identified simultaneous
  contacts with `RiseTrailShelfTreadA_Collision` and production `Terrain`; the
  terrain contact normal was steeper than the tread. Direct baked-height samples
  proved the old uphill route contained consecutive **41.95°, 48.38°, 33.54°,
  34.35°, 33.99° and 49.80°** ground legs under boxes capped at 28°.
- Rise R14 source `657743c62` replaces that impossible line with a scoped,
  explicit 26.7° terrain bench and matching continuous tread route. The exact
  affected Terrain3D region `(0,-1)` was deterministically rebuilt and committed
  as `1f8b607ff`. Focused Rise + heightfield validation passes **27 tests / 548
  assertions / 0 failed**; Rise alone passes **12 / 450 / 0**.
- R14 has **no production verdict yet**. `THE-RISE-IDENTITY-R14` crashed at
  scene allocation immediately after the terrain bake; the two subsequent
  output directories are empty and make no claim. No Godot process remains.
  Repeated full Meadows boots also destabilized the Codex desktop session on
  this 7.64 GB machine. Do not attempt another production Meadows boot in this
  same Windows session. Restart Windows or use a higher-memory host, then run
  one fresh native-NVIDIA R14 capture directory.
- User-owned tracked changes in `project.godot` and
  `tests/smoke_net_movement_two_peers.gd` remain untouched. All generated report
  trees and untracked UIDs remain preserved.

Immediate safe continuation after a Windows restart/high-memory handoff:

1. Confirm no `Godot*` process and adequate available RAM.
2. Run `capture_the_rise_identity.gd` once under native NVIDIA/OpenGL into a new
   directory such as `THE-RISE-IDENTITY-R14-RETRY-03`.
3. If its real-player traversal and 8-frame manifest pass, obtain the required
   independent visual verdict before changing the 19/23 ledger.
4. Continue serialized Quarry R31, Old Mill R14 and Warrens R17 captures.
5. Replace the rejected Terrapup R38 rest with a dedicated authored animation,
   then repeat normal production capture and blind review.
6. Only after those rows pass, rebuild both ledgers and run regression/package
   plus the full continuous A1–A11 campaign.

## Desktop continuation — later 2026-09-13

The strict totals remain **41/43 playtest**, **19/23 named locations**, and
**0/11 current-revision continuous A-gates**. The higher-memory desktop completed
four full production boots without a RAM failure, so memory is no longer the
active blocker. None of the results below is a ledger promotion by itself.

- The focused six-item closeout batch passed **53 tests / 1,764 assertions / 0
  failed**. Subsequent focused checks passed Quarry **10 / 439 / 0**, Terrapup
  **16 / 311 / 0**, Warrens **8 / 115 / 0**, and Old Mill **7 / 219 / 0**.
- Old Mill R14 produced a clean **8/8**, `complete: true` manifest in
  `final-old-mill-14-desktop-01`, but independent visual review failed the
  obstructed arrival pair and the visually incoherent hydraulic chain. A bounded
  R15 legibility experiment also produced 8/8 clean frames and failed the same
  independent criteria; its rejected source changes were removed. R16 replaced
  the paired tailrace boulders with low continuous channel cheeks, lifted the
  non-emissive water value, and expanded the scoped south-arrival clearing.
  Focused tests pass **7 / 223 / 0**. The first production attempt correctly
  failed before pixels because its receipt still named the retired cascade stone;
  `final-old-mill-16-desktop-02` then produced a clean **8/8**, `complete: true`
  manifest. Independent review still failed it: the arrival bush remains a major
  obstruction, the segmented blue descent reads as stairs/blockout rather than
  flowing water, and source/headpond/contact causality remains unclear. Old Mill
  remains red; do not recapture unchanged R16.
- Quarry R32 moved the work wagon 5 m east, eliminating its exact overlap with
  the haul-apron endpoint. `OLD-QUARRY-TERRACE-R32-DESKTOP-02` then advanced from
  2/8 to **6/8** accepted frames: worked-floor, conduit-head, and cut-face pairs
  all passed. Only arrival remained red because the evidence rays counted the
  ordinary third-person Player capsule as apron occlusion. The harness now
  excludes that player RID from quarry-art visibility rays and removes the
  abandoned exhaustive camera sweep; focused tests pass, but one fresh
  production capture and independent verdict are still required.
  That fresh `DESKTOP-03` run remained 6/8 because the second apron half was
  still outside both viable arrival lenses. Independent review of the six valid
  frames also failed: 02/03 were visually redundant, the conduit was not a
  distinct focal feature, the cut face read as smooth repetitive blockout, and
  night detail collapsed. Do not weaken the arrival gate or recapture unchanged
  R32 art. R33 now adds three shallow visual-only chisel scars to each extraction
  face plus one second bounded modeled lantern at the otherwise unlit west cut.
  The R33 evidence contract is also split by subject: worked-floor centers and
  proves the wagon handoff, conduit centers and proves the real `Pylon_0` plus
  its apron, and cut-face alone proves the scarred strata. Quarry focused tests
  pass **10 / 441 / 0**. `OLD-QUARRY-TERRACE-R33-DESKTOP-01` then produced a
  clean **8/8**, `complete: true` manifest with no failures. Independent review
  still failed it: all four night frames were too dark, the wagon and conduit
  subjects remained ambiguous, and the cut still read as tiled stepped slabs.
  R34 then replaced the cut material with the existing `Rock030` quarry rock,
  made the strata shallower, enlarged the authored tool scars, and strengthened
  the two bounded work practicals. Its eight frames were diagnostic only because
  the manifest caught one rotated ledge below the production depth threshold.
  R35 corrected that ledge and passed focused tests at **10 / 442 / 0**, then
  produced a clean **8/8**, `complete: true` manifest in
  `OLD-QUARRY-TERRACE-R35-DESKTOP-01`. Independent review still failed it: the
  face reads as repetitive rectilinear slabs rather than geological extraction,
  wagon/floor and conduit/apron relationships remain ambiguous, and all night
  proof loses the required landmark detail. Therefore The Old Quarry remains
  red; unchanged R33/R35 must not be recaptured.
- Terrapup R38 produced a numerically clean 2/2 rest pair, but independent review
  rejected it as an upright compressed crouch rather than a supported laying
  pose. A bounded R39 ±45-degree comparison proved the imported axis unsuitable:
  both variants tipped vertically and floated. R39 was removed; the next attempt
  must be a genuinely authored rest pose/animation, not another whole-model roll.
- Warrens R17 wrote 9/9 frames but failed its manifest on arrival grounding and
  threshold drift. The capture now seats the production player before collision
  warmup and reseats residents before shutter. Independent review also rejected
  the approach's faceted/overexposed mound and the threshold composition, so
  seating alone is not enough for promotion. R18 darkened only the sun-exposed
  mouth/hall shell and updated the stale capture to give the already-fixed
  production companion formation 36 physics frames after teleport. Focused tests
  pass **8 / 117 / 0**, and `final-warrens-18-desktop-01` produced a clean **9/9**,
  `complete: true` manifest. Independent review still failed both the named-
  location and playtest visual rows: the exterior remains a faceted generic dark
  mound with blown terrain shelves, the large threshold blocker persists, the
  close sequence is creature/player crowded, and the guardian mass obscures the
  den. The blocker is therefore not merely the previously fixed ordinary
  companion-follow station. Warrens remains red; do not recapture unchanged R18.
- Rise R16 still stalls the production controller at the same terrain location
  near `(76.61, -61.02)` despite the focused and lightweight route probes passing.
  Do not spend another full boot on the unchanged route.

Next shortest ledger path: stop capture iteration and fix a production subject
directly. Quarry still needs genuinely geological extraction massing plus usable
night exposure; Old Mill needs a coherent modeled water path; Warrens needs
facade/composition repair; Terrapup needs an authored rest pose. Do not return to
camera sweeps or recapture unchanged R32/R33/R35 art.

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

#### Warrens R51 update — 2026-09-15

`final-warrens-51-desktop-01` is a complete 9/9 native production set and the
focused contract passes **8/132/0**. R51 removes all failed applied roof geometry
and is the stable open-cut entrance checkpoint. Independent review still fails
the playtest and full-journey identity bars because the façade masses intersect
visibly, the gallery is a nearly black uniform tube, and the sparse den does not
repeat the exterior identity strongly enough. Ledgers remain **42/43** and
**20/23**. Do not restore R41-R50 canopy/sheet/blob experiments; address the
passage and den as authored world spaces.

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
