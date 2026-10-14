# F17#6 Low blockers, round 2: CAPTURE-READY (not self-judged)

- **Source:** `tb/ev-coop-chapters` `555beaa81` (merged `tb/ev-coordinator` at `90bfa7849`); clean import; Low/Compatibility, llvmpipe; captured about 4:56 AM CT Mon 12 Oct.
- **Frames:** the round-1 matched 18 (`VISUAL-PROOF/F17-6`, `tb/ev-captures`), 1280x720 in `frames/`; all 18 on `sheet.jpg`.
- **How:** exterior 14 by `tests/capture_f17_visual_matrix.gd` at 1920x1080 (same real walk; only the mid-street stand moved, to x>47); interior 4 by `tests/capture_f17_hall_interior.gd` at 1280x720.

## Addressed (round-1 judge order)
1. **Red banners (hard rule):** now village teal `#426b69`. The `"*"` retint matched no material and the kit's oxblood vertex tint survived; `MI_Banner` is named and its vertex colour dropped. No other red in the village/Hall configs.
2. **Cyan beam:** it is the real objective beacon. It fades in over its lower 30% and out above 82%, additive, with a faint 2.6x halo; no bar over the companion. Canopy-proof depth kept (owner wayfinding test).
3. **Rain:** 1600 streaks (3 cm x 0.9 m, 20 m ring), cool mist (fog add 0.0055), grade saturation x0.86, terrain wetness 0.6 (darker, glossier).
4. **Placeholder planes:**
   - Sealed arches bricked with the kit's brick (dark but visible); locked arches hold the kit's `Door_8_Flat`.
   - The home membrane culls its back, so the entrance shows the lit Hall.
5. **Interiors:**
   - 79 window modules get the matching `Window_Wide_Flat1` glass (cool panes, dim glow); the hard white sun rectangles are gone.
   - Nave end wall: two teal banners and a lantern.
   - Lecterns 1.3x on 0.9 x 0.3 x 0.9 m stone plinths (the kit's platform).
   - Hall night ambient 0.25 -> 0.12.
6. **Bench:** the stand moved to x>47, midway between the bench pairs at x 40.3 and 58.3.

## Not addressed
- **Cobble scale:** the floor shares `MI_UnevenBrick` with the walls.
- **Nave top-right gap:** not visible after glazing; needs the judge's call.
- **Shrine Room at night:** still close to day.
- **Full-bar (later, Medium/High with Codex):** fog and aerial perspective, mountain card, lamp pools and window spill, street wear, ground cover, tree groups, NPC idles, clutter, UI collisions (clock, quest panel, keyboard glyphs).
- **Checks:** affected unit tests 52 + 32 + 16, all passing; `crossing_hall.gd` parse check clean.

## Isolated native baseline feasibility — 13 Oct 2026, 5:58–5:59 PM CT
Source4ae7c09b0599d98ad5549ee7a77338a8e7777158, Godot4.7 Forward+ on GTX1060 3GB. This lane viewed both PNGs and read both stdout/stderr and terminal receipts. Correct trainer idle arms and fixed nave composition are visible; no falling-velocity warning. Both stderr files are0bytes and both natural exits0. This verifies diagnostic setup only; no Bar A/B score, traversal, full-world or F17#6 acceptance claim.

- Medium:25.822s; minimum physical free3225698304bytes;1280x720; image SHA2568783ef7e252c3e7447ef39942b40bc9031253d16f6ef7f7bdcc141e1b52621bc.
- High:25.938s; minimum physical free3108315136bytes;1280x720; image SHA256538052943072324b9998aae948322629a7a3cdb49c9d3e5b59085b0c5428eec9.
- Receipts/logs/images retained at D:/tetherbound/.artifacts/visual-takeover/hall-idle-delta-4ae7c09b05/capture-runs/run-hall-idle-medium-4ae7c09b05-r1/ and run-hall-idle-high-4ae7c09b05-r1/.
- Both logs identify production idle=idle sampled0.2s, trainer stand(113.25,0.91,14.3), isolated ground_y0 and named presets. The first8da633 run's fall/T-pose issue is not accepted; these corrected runs supersede its setup result.


## Hall I independent GPU comparison — 2026-10-13 18:37 CT

All 52 images validated across the preserved first-run recovery and 15-step successful continuation. Three fresh blind judges completed all 26 Medium/High interior pairs. Baseline Bar A 3.049 (spread 0.315), furnishing 3.728 (spread 0.500), gain +0.679; Bar B 2.458 → 2.905. Neither passes 8.5; both candidates stay OFF. Major gaps: beige night haze/trainer lighting, repetitive architecture and weak structural hierarchy, generic shrine/portal identity. Full per-view means/spreads, original verdicts and provenance are in [Hall I judge report](hall-i-2026-10-13/JUDGE.md). Isolated interior only, no F17 closure. Root owns the next native frame-arm comparison; no engine launched by this lane.

## Four-lane restart — F17#6, 14 October 2026, 17:46 CT

Permissions verified from effective session context: approval_policy=never, sandbox_mode=danger-full-access. Assigned checkout D:/tetherbound/restart-look, branch tb/look, restart baseline 6b13cc0851017cd90ead79c9dc143d62a21576c8. Native slot UNASSIGNED; no engine, import, capture, export or stage access performed.

Selected criterion: F17#6, board status in_progress. Expected player result: an inviting, readable Village/Hall with material depth, grounded light and a recognizable destination. Existing required proof remains the fixed Village/Hall Medium/High matrix, three independent code-blind judges, Bar A mean/spread with 8.5 gate and Bar B alongside; relevant weather/day/night and motion remain required. Pair02's +1.5333 is a two-view diagnostic gain, not closure. Window rejection remains one low-gain round in that matched subset; old structural rounds remain separately parked.

Game change: source a20482cfc2c854625dd20e3097f0332876034b68 adds hall_lantern_lighting.enabled=false in data/config/crossing_hall.json and applies its eight exact Pair02 night values to the Hall instance's deep-copied config before construction in scripts/world/crossing_hall.gd. The better treatment previously existed only inside the capture script. It can now reach an ordinary Hall build after acceptance without leaving the accepted look in test code. No new visual tuning, geometry, asset generation or tool changes; furnishing/frame/waymark remain independently OFF. No shared STATE/dashboard edits.

Actual checks: PowerShell ConvertFrom-Json compared the complete config after removing the new block to git show HEAD:data/config/crossing_hall.json before commit: identical. All eight override assignments matched the existing frame-lantern-lit capture source; all four candidate flags false. git diff --check PASS. Independent read-only source review found no actionable issue: copy isolation, default behavior, construction ordering and exact values checked. No Godot parse/runtime/visual proof claimed. Initial python command failed because the Windows alias has no Python interpreter; it made no changes. Existing PowerShell performed the checks; no installation or new validator.

### Native request for root — NOT ADMITTED

Frozen game source: a20482cfc2c854625dd20e3097f0332876034b68. Reuse tools/visual_judge/capture_camera_set.gd, tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json and the preserved run_hall_window.ps1/source_preflight.py/bounded-source-functions.ps1 runner family. Historical executable packet: D:/tetherbound/.artifacts/visual-takeover/hall-window-capture-5650c507e6-r3/. Preserve its old receipts; it is not an admission for this source.

First bounded proof is runtime treatment parity, not another art round: two serial Medium Forward+ processes, 1280x720, fixed nave-forward_day_clear,nave-forward_night_clear, --hall-only-ground-y=0. First uses --hall-arm=frame-lantern-lit with source defaults. Second uses --hall-arm=frame and the existing isolated-config overlay mechanism with only hall_lantern_lighting.enabled=true. This second arm must exercise the new build branch; repeating frame-lantern-lit twice does not prove it. Do not enable furnishing/frame/waymark in the file: the existing frame arm selects geometry privately. Root must explicitly bind and restore the one-boolean diagnostic overlay under the existing source/admission protocol; if that supported overlay route cannot be admitted, leave parity unrun rather than invent machinery. Use fresh output directories under D:/tetherbound/.artifacts/visual-takeover/restart-look-a20482cfc2/, never overwrite historical images.

Request retains 120 seconds per render child, three existing parser requests at most 30 seconds each where necessary, maximum 330 child-process seconds, four PNGs, no automatic retry. Retain historical resource bounds: physical and commit free >=2 GiB; C stop >=10 GiB, D stop >=20 GiB; admission C >=11274289152 bytes, D >=22548578304 bytes; output/isolated homes <=167772160 bytes. Engine/DLL pins and full-source check must pass under root's sole lease. No source score or image count substitutes for natural exits, clean logs and actual images.

Stage reconciliation remains root-owned: the b9-to-c836 retained dependency failure at assets/characters/npc_identity/water_orsen/source/retarget_orsen_arms.py is unresolved by an idle record. Select the actual base, preserve/verify retained work, reconcile that failure, then rebind the existing bounded full-index/materialization contract to the chosen source and declared overlay. No request to rebuild the stage or relabel historical admission. This checkout is intentionally text-sparse; absent assets/ui/hall_waymark.gdshader is sparse absence, not an established missing Git asset or game defect.

After parity, the preserved waymark pixel request remains the next distinct art comparison: frame-lantern-lit versus frame-waymark on those same two contact-v2 views, with production flags OFF and a separately granted bounded run. Its existing pixel-contract.json defines banner/depth/normal-response checks; it is pinned to historical 74b6 and cannot be silently relabelled. A passing pixel diagnostic permits the three-judge comparison and later complete matrix, not activation or closure. No additional unjudged art is stacked while native proof is unavailable.

Result: zero criteria closed; one OFF game treatment delivered, independent source review complete, native parity/waymark/full-matrix proofs UNRUN. Balance: game 2 files / tests-tools 0. Next action waits on root's serialized native grant; no native launch is authorized by this note.
