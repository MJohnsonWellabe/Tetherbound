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

## Delegated sole-native attempt — 14 October 2026, 17:49 CT

Root granted only F17#6 source d0293b75e570a0bcbe1e95b429627771ac9ef135 (game a20482cfc2c854625dd20e3097f0332876034b68), preserved reconciliation followed by conditional two-run parity, no retries. Read root STATE confirming Look's sole reservation. Result: BLOCKED before native launch; zero frames, zero criteria closed. Actual read-only receipt: [restart-native-preflight.json](restart-native-preflight.json). No new staging/runner/validator, imports, source transition or stage writes.

Held the existing C:/CodexTemp/tetherbound-native-owner.lock exclusively while inspecting the stage and running the existing checker. Actual HEAD b9d7edeb7f18d7ca2192f018016d4126f1910f91; complete index matches its 49,341-path tree. This is index identity, not a full materialized-source pass. Engine SHA256 b2ca888d5115a6cedee564764a2ee494a625f2ec2edbabd010fe33c9a88a6bf8 and Terrain DLL SHA256 5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306 match retained pins. 12,874/12,911 historical Hall-required paths are physically present; that historical set is not certification for the requested source. Resource sample: C14,417,203,200 bytes, D22,735,577,088 bytes, physical5,421,498,368 bytes, commit5,699,702,784 bytes; existing admission floors pass at that instant, but transition peak reserve is not certified.

Reproduced the precise retained failure by calling the unchanged transition_paths.matches against the actual dependency and old job binding: FALSE / Retained dependency differs for assets/characters/npc_identity/water_orsen/source/retarget_orsen_arms.py. Stage has11,809 CRLF bytes; the pinned Git blob has11,596 LF bytes. CRLF-to-LF yields the exact committed content/blob31d2aef18ac5be030f11d4f823728e28badd35aa. The old job marks it kind=binary/hash_mode=binary, so the existing strict comparison fails correctly for those different bytes. No substantive source difference demonstrated; no blanket normalization or check weakening applied. Originals and old failed transcript remain intact. If a later authorized source transition needs this exact dependency, the minimum materialization action is preserve its original bytes and restore the exact pinned LF blob, keeping the strict check unchanged; that alone does not certify the stage.

Ran the unchanged source_preflight.py once with its preserved Hall job/contract against the actual stage: exit1, stderr {"status":"FAILED","error":"HEAD mismatch"}. Expected historical565, observedb9. No retry and no misleading re-admission. Runner/helper/contract hashes match their ready manifest. Current historical job/admission are ROOT_ADMITTED and differ from PREPARED ready hashes, but both .before-root originals match exactly; these are retained historical admission changes, not permission for d029 or this root session.

The decisive parity blocker is unsupported overlay handling. run_hall_window.ps1 Run-Step calls Assert-Source before every child and only provisions an isolated user://graphics_override.cfg, not a Hall game-config overlay. source_preflight.py lines69–71 require tracked bytes to match the commit (with only approved CRLF normalization). Changing hall_lantern_lighting.enabled would therefore fail the existing full-source check. capture_camera_set.gd's current arms do not select the new runtime flag. The earlier README's presumed existing game-config overlay route is corrected: preserved old overlay files are not a supported route in this runner. No candidate flag was edited in the stage, and no guard was changed to allow it.

Existing alternatives checked: the direct frame-lantern-lit arm bypasses the new enabled runtime branch, so cannot prove parity; the preserved R3 runner permits graphics preferences only; the old transition is pinned b9-to-c836 and cannot certify the requested Look source unchanged. Per root's explicit unsupported-overlay instruction, parity remains UNRUN. The smallest future proof action would be one process-local selection of hall_lantern_lighting.enabled in the existing capture arm, then a deliberate current-source binding through the preserved runner; do not add overlay infrastructure. Not implemented or authorized by this blocked attempt. Root must choose that bounded correction or another supported proof route before a new launch grant.

Reservation is idle for root. No native children were created; final global Godot/Blender census empty. Owner bytes remain exactly SHA256761caefb9af7a4601e729f1aa3a5a938e7aedc8b00855c75eec9ff2e94e06f1a (historical thread01a13307-fea3-7ae0-a0cf-ecd8f0e0d502, sourceb9, reserved=false, allow_native_launch=false, no active PID/session/run). The exclusive inspection lock was disposed. No owner restoration write was needed. Root may release/reassign its reservation; this lane retains no launch authority beyond the completed blocked attempt. All look candidates OFF, no waymark/full-matrix launch or visual score. Game changes this block0; required proof preflight attempted once; next action is root disposition of the concrete unsupported route.

## Root-authorized minimum blocker correction — 14 October 2026, 18:47 CT

Criterion F17#6. Reproduced blockers and alternatives are in restart-native-preflight.json: exact Orsen CRLF bytes fail the retained binary binding; an on-disk Hall boolean overlay is unsupported by the strict full-source runner, and the existing lantern arm bypasses the production enabled branch. Root renewed sole reservation and authorized two narrow corrections only. Before edits: preserve the exact11809-byte dependency, restore the exact11596-byte Git blob31d2aef18ac5be030f11d4f823728e28badd35aa through the preserved binary write/readback helper under the existing owner lock; retain strict comparison. Add one frame-lantern-runtime process-local arm to capture_camera_set.gd, using the existing deep-copy and frame geometry, setting only hall_lantern_lighting.enabled=true. Production remains OFF; no file overlay, new runner or relaxed guard.

Exact next proof after commit/push: current-source rebind through preserved machinery, then two serial Medium Forward+1280x720 captures using frame-lantern-lit and frame-lantern-runtime, contact-v2 nave-forward_day_clear,nave-forward_night_clear, ground0,120s each,max330child seconds,four fresh PNGs. All full-source/engine/DLL/ownership/resource guards unchanged. On another failed gate preserve failure and park this route without another tooling correction. No art score/closure follows parity. Restore original owner bytes and release lock after owned children are absent.
