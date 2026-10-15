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

## Minimum correction result — 14 October 2026, 18:52 CT

Frozen pushed source cde643b0b6be5a624328a6c1a1fffe77462e5d69 adds frame-lantern-runtime only to the existing arm validation/frame selection, then sets the private copied hall_lantern_lighting.enabled=true. It does not enter the hard-coded frame-lantern-lit branch. The existing diagnostic now also refuses a production lantern flag that is already ON. Production config stays OFF. git diff --check PASS; no engine parse or image proof claimed.

Under the exclusive existing owner lock, reused transition_paths.read_file/write_file/batch_blobs/matches to preserve the11809 original Orsen bytes and restore exact11596-byte blob31d2aef18ac5be030f11d4f823728e28badd35aa. Existing binary binding now PASS with SHA256e7b4edd34d7c7a560934cdf15d5337c633e0d64bacd963aa84df075653777469. Original backup retained at D:/tetherbound/.artifacts/visual-takeover/restart-look-cde643b0b6/retarget_orsen_arms.py.original-crlf; portable exact base64 and verification in [restart-dependency-restoration.json](restart-dependency-restoration.json). No other stage file/index/HEAD changed. Current source was already committed/pushed before the immediate proof preflight.

First retained check exposed a historical packet mismatch for meadows_look.json: the stage file actually equals the requested current-source blob91e7e20d56f8e56fe35b0b9ac6bdaadc82851989, whereas the old c836 job binds1678a65697b49381bd4a4e850b415d89049c7109. This was NOT stage corruption and was NOT fixed by altering source. Exact observation retained in restart-current-source-gate.json. Completed the necessary authorized binding step in memory: resolved current tree, rebound65 stale dependency entries to current blobs/hashes with unchanged modes, asserted all3521 remaining bindings match current tree, and identified541 changed paths. Changed-source paths remain for the existing changed-blob materialization route; no transition/pack/stage mutation performed.

Immediately attempted the strict retained-dependency gate using those current-source bindings and unchanged preserved matches/read_file/resource helpers. After1312 successful checks it FAILED on assets/characters/npc_identity/water_otto/source/retarget_otto_arms.py. Current expected blob6898e34c47e606826cd63a66d96422c1dc7c89e5,11708bytes,SHA256acbac5ba4c94012b1d0ec98365144608ae9d7b60d005f6d17152f6dab5b6ec96; actual11922bytes,blob b3038f36b9610e7438b20631c963c96a95089c4b,SHA2568d9e73ee501dd441cdb0e8708501d67afb42422a1e23ac18eef563d55e4d62b7. Mode stays binary. Exact result: [restart-current-rebound-gate.json](restart-current-rebound-gate.json). No further normalization, hash waiver, checker edit, retry or chained tooling correction. Per root stop rule this proof route is PARKED. No executable current-source admission was produced because this prerequisite failed.

Parity proof remains UNRUN: zero Godot/parser/import/render children, zero PNGs, no capture logs/image hashes/natural-exit claims, no art score, zero closures. Preserved requested source and actual stage remain distinct: requestcde643b0b6; stageHEADb9d7edeb7f18d7ca2192f018016d4126f1910f91 with the one explicitly authorized byte restoration. Full source is NOT admitted. Root must decide a different supported proof route/game approach; this lane does not start a further tooling correction or skip F17#6.

Reservation released back to root after empty final Godot/Blender census and no owned children. Original owner bytes unchanged SHA256761caefb9af7a4601e729f1aa3a5a938e7aedc8b00855c75eec9ff2e94e06f1a; reserved=false,allow_native_launch=false,no PID/session/run. Existing owner lock disposed. No owner restoration write necessary. Balance this block: game0 / existing proof correction1 file plus exact requested one-file materialization; required preflight attempted and blocked.

## Direct-checkout Hall proof — 14 October 2026, 20:43–20:51 CT

Newest owner directive and [coordinator comment](https://github.com/MJohnsonWellabe/Tetherbound/issues/572#issuecomment-6180951023) superseded the stage route and F38 reassignment. F17#6 remains OPEN. Expected player result and complete required Village/Hall matrix remain as above. This turn tested whether the existing production lighting branch preserves the established lantern treatment on two fixed Hall views. No game or capture-script edits, stage access, admission preparation, owner/lease access or infrastructure changes this turn. All production candidates remain OFF.

Captured pushed source: **37137ce222328a2d2da778acca9494fddfdc8236**, branch tb/look, with runtime-arm implementation cde643b0b6be5a624328a6c1a1fffe77462e5d69 and game lighting implementation a20482cfc2c854625dd20e3097f0332876034b68. Existing capture_camera_set.gd used AS-IS. Godot reported 4.7 stable, Forward+, NVIDIA GeForce GTX 1060 3GB, Medium. Normal Git sparse materialization and generated import metadata were necessary in this checkout; generated .import/.uid changes remain local and are excluded from this evidence commit. These captures are not a claim that every generated working-tree file matched the commit.

### Actual commands and outcome

First command launched directly at **20:43:27 CT**, before inventory/preparation:

```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe' --path D:/tetherbound/restart-look --rendering-method forward_plus --resolution 1280x720 --script res://tools/visual_judge/capture_camera_set.gd -- --set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json --preset=Medium --views=nave-forward_day_clear,nave-forward_night_clear --hall-only-ground-y=0 --hall-arm=frame-lantern-lit --out=D:/tetherbound/restart-look/.artifacts/f17-direct/baseline
```

PID21124 produced zero frames: required scenes, textures, shaders and trainer resources were absent from the sparse checkout. [Original engine log](direct-look/first-attempt.log) is preserved. The GUI shell returned0 before the engine finished; that is not an engine exit-code claim. PID was later absent. Normal Git materialization added scenes, shaders, addons, scripts/autoload and required asset families to this checkout. An overlapping sparse-add command failed on Git's existing lock; it was repeated after the first command completed, without lock removal.

An isolated APPDATA at D:/tetherbound/restart-look/.artifacts/f17-direct/user held ordinary graphics_override.cfg settings: preset/base Medium, custom={}, overlay=false, rendering_method=forward_plus. Import and both following captures inherited that APPDATA. Normal import command:

```powershell
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe' --headless --editor --import --path D:/tetherbound/restart-look --log-file D:/tetherbound/restart-look/.artifacts/f17-direct/import.log
```

Import PID59032 exited naturally0. Its full log and generated cache remain local. The **one baseline retry** and candidate continuation used the following exact executable arguments (launched with Start-Process -WindowStyle Hidden -PassThru, waiting for the actual processes):

```powershell
$env:APPDATA='D:/tetherbound/restart-look/.artifacts/f17-direct/user'
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe' --path D:/tetherbound/restart-look --rendering-method forward_plus --resolution 1280x720 --log-file D:/tetherbound/restart-look/.artifacts/f17-direct/retry.log --script res://tools/visual_judge/capture_camera_set.gd -- --set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json --preset=Medium --views=nave-forward_day_clear,nave-forward_night_clear --hall-only-ground-y=0 --hall-arm=frame-lantern-lit --out=D:/tetherbound/restart-look/.artifacts/f17-direct/baseline-retry
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe' --path D:/tetherbound/restart-look --rendering-method forward_plus --resolution 1280x720 --log-file D:/tetherbound/restart-look/.artifacts/f17-direct/candidate.log --script res://tools/visual_judge/capture_camera_set.gd -- --set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json --preset=Medium --views=nave-forward_day_clear,nave-forward_night_clear --hall-only-ground-y=0 --hall-arm=frame-lantern-runtime --out=D:/tetherbound/restart-look/.artifacts/f17-direct/candidate
```

Baseline PID36704 and candidate PID8168 each exited naturally0 and saved two fresh1280x720 PNGs. [Baseline log](direct-look/retry.log) and [candidate log](direct-look/candidate.log) confirm Medium/forward_plus, the fixed contact-v2 fixture, trainer idle sample0.2s, selected arms and done2views. Candidate explicitly reports the production-build lighting branch with private flag only. Both logs also retain an actual error: missing res://assets/environment/nature/stump_round.glb at ironwood_grove_presentation.gd:17, followed by depended-script compilation failure in playground_world.gd loaded at capture_camera_set.gd:96. The isolated Hall still rendered. **Clean runtime proof FAILED; natural exit0 and four images do not waive this error.** No additional retry or correction followed.

GPU turn ended by **20:51:22 CT**, final Godot census empty, no owned children left and no forced termination. GPU yielded to Creatures at20:51CT; no subsequent native launch. High, complete Village/Hall matrix, weather/motion/fight and ordinary-world traversal remain unrun.

### Captured images and three independent blind verdicts

Original images remain under D:/tetherbound/restart-look/.artifacts/f17-direct/{baseline-retry,candidate}/. The local blind/sheet.png contains all four original-resolution images with neutral labels; separate blind/A-day.png,A-night.png,B-day.png,B-night.png were also provided. Mapping disclosed only after verdicts: **A=candidate runtime; B=baseline lantern-lit**. Three fresh agents received only neutral images and the existing art-direction/reference board, without source, logs, arm mapping, previous scores or intended change. Each judged both bars against8.5. No prior judge was reused for a new art iteration.

| Independent judge | Bar A, A / B | Bar B, A / B | Verdict |
|---|---|---|---|
| hall_blind_1 | 5.8 / 5.8 | 5.4 / 5.4 | Tie; both bars NO |
| hall_blind_2 | 5.5 / 5.5 | 5.5 / 5.5 | Tie; both bars NO |
| hall_blind_3 | 5.7 / 5.7 | 5.5 / 5.5 | Tie; both bars NO |
| Mean | **5.6667 / 5.6667** | **5.4667 / 5.4667** | Below8.5 |

Bar A range5.5–5.8, spread0.3; Bar B range5.4–5.5, spread0.1. Judge1 rated day5.4/night6.2; judge2 day5.0/night6.0; judge3 approximately day5.1/night6.1. All found no perceptible treatment difference. Shared defects: small generic table and blank banners fail to establish a memorable destination; repeated cobble surfaces and loud stretched timber compete with subjects; daylight lacks motivated window illumination, while the better warm/cool night still lights the foreground more than the destination. Suggested game-level improvements were a clearer focal hierarchy, calmer differentiated materials, purposeful furnishing clusters and focused destination lighting. These are criticism, not implemented or accepted changes.

The result supports **limited two-view visual parity**, not clean runtime acceptance, art improvement, full-matrix acceptance or F17#6 closure. It is a production-path comparison, not a fresh art iteration or new low-gain streak entry. **Zero criteria closed.** Production flags stay OFF. Next game/proof action is coordinator disposition of the preserved waymark comparison or a focal/material scene improvement, followed by an authorized direct-checkout capture and the complete required matrix; the missing stump resource must be resolved before any clean-world runtime claim. No further GPU turn or tooling work is claimed by this note.

### Preserved artifact SHA256

Paths below are relative to local .artifacts/f17-direct; the three log copies are also committed in direct-look/. PNGs/import cache remain local, not in Git.

| Artifact | SHA256 |
|---|---|
| baseline-retry/nave-forward_day_clear.png | 6e3b743b65d9675c0c395c862509483569de47cefb8c4f9bfe4e31d0b7fcb04a |
| baseline-retry/nave-forward_night_clear.png | 4f0c8dcb49f7ec506183e3bb53d40138b508b7288464016e6747c8595bfb60dd |
| candidate/nave-forward_day_clear.png | 7fcd49d701d1504b5373bb4627f08876e50ea0b60f77ccB81a114f69675e8bd1 |
| candidate/nave-forward_night_clear.png | f9039918b2b40e1ce0e8b557b95ba07a0dbf27373e9e474e56b9445c773705a1 |
| first-attempt.log | 8efd44bad7ca1517442cf53ff4e4c830517ad9acae9dd43ebf62e13243c9e37c |
| retry.log | 5f6cdbc730ad89ce54b13456a19b23db03d634e3a762af8bf8a7ab3ca46ea38d |
| candidate.log | 264dd9d01813ae566d80ebb731d80c3f15dfd30473154aa1d58e14b1cc47184e |

## Active F17#6 — Hall destination material candidate

Owner directed continued game improvement after the direct parity proof. Completion goal remains ACTIVE through acceptance and handoff for landing; the parity tie is not an improvement round. Creatures owns the GPU turn. No GPU/import, stage work or capture-script edit in this block.

Expected visible result, stated before edits: the existing Hall emblems should read against a quieter plaster backdrop; ordered stone flooring should separate from the cobbled side walls; darker rough timber should frame the destination instead of competing with it. This addresses the three judges' weak-identity/noisy-material findings with one coherent material hierarchy. Flat daylight remains unresolved and is not claimed fixed.

Game implementation extends the existing OFF hall_waymark candidate in crossing_hall.json/crossing_hall.gd. It reuses installed Quaternius T_Brick and T_Plaster albedo/normal textures on the nave floor and rear-wall panels, and retains the original wood texture with a darker tint and subdued normal response on HallTimberFrame. Rear-wall finish affects both faces of those modules; the complete exterior matrix must check that consequence. Material copies are local to the Hall and applied before its existing day/night copies. Geometry, UVs, collision, routes, portals, saves and network state are unchanged. No new assets, shader, harness or tool. Production furnishing/frame/waymark/lantern candidates all remain false.

Scoped checks: JSON parsed, replacement texture paths exist, four candidate flags OFF, git diff --check PASS, capture_camera_set.gd unchanged. Native parsing and appearance remain UNPROVEN; no score or closure. Next granted direct proof compares frame-lantern-lit against frame-waymark on the fixed contact-v2 day/night views, then three fresh code-blind judges. The unchanged capture arm now selects emblems plus the game material treatment; its historical console text describes only the emblems. Historical cloth-only pixel assumptions cannot certify this expanded candidate. Full fixed Village/Hall Medium/High matrix and 8.5 three-judge bar still govern acceptance. Keep the candidate OFF and the F17#6 goal active pending that proof; do not move to F38 or treat this pushed implementation as completion.

## GPU turn 5 — material round, 14 October 2026, 21:24–21:33 CT

Owner granted direct-checkout GPU turn5 after Routes yielded, about21:23CT. Actual captured source **01e8ce10032a348c1c3ed4cf3f3d867369a0438d**, already pushed on tb/look. First launch21:24:21; final natural exit21:33:02, empty Godot census21:33:18, then GPU explicitly yielded to Creatures. Eight serial children, all natural exit0, no failed capture and no retry. **52 fresh1280x720 PNGs**: baseline/candidate ×13 preserved Hall interior views ×Medium/High. No stage access, source-byte/preflight/lease/receipt machinery, import, capture-script edit or new harness. Source remained frozen throughout captures. The normal isolated graphics preference selected the actual preset; logs confirm Medium/High and Forward+ on GTX1060.

Actual executable for every row: C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe. Each was launched via Start-Process -WindowStyle Hidden -PassThru with the following argv, waited to actual exit. The table supplies the exact variable arguments. This records completed commands, not another runner:

```text
--path D:/tetherbound/restart-look --rendering-method forward_plus --resolution 1280x720
--log-file D:/tetherbound/restart-look/.artifacts/f17-material-turn5/<run>.log
--script res://tools/visual_judge/capture_camera_set.gd --
--set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json
--preset=<preset> --views=<views> --hall-only-ground-y=0 --hall-arm=<arm>
--out=D:/tetherbound/restart-look/.artifacts/f17-material-turn5/<run>
```

All children inherited APPDATA=D:/tetherbound/restart-look/.artifacts/f17-direct/user. Its user graphics_override.cfg kept custom={}, overlay=false and renderer/rendering_method="forward_plus"; preset/base were Medium for Medium rows and High for High rows. Production flags were never changed.

| Run | Preset | Arm | Views | PID | Start–exit CT |
|---|---|---|---|---|---|
| medium-baseline | Medium | frame-lantern-lit | forward pair | 21420 | 21:24:21–21:25:18 |
| medium-candidate | Medium | frame-waymark | forward pair | 12352 | 21:25:28–21:25:54 |
| high-baseline | High | frame-lantern-lit | forward pair | 28924 | 21:26:10–21:26:36 |
| high-candidate | High | frame-waymark | forward pair | 13932 | 21:26:46–21:27:11 |
| high-baseline-matrix | High | frame-lantern-lit | remaining11 | 15744 | 21:29:26–21:29:59 |
| high-candidate-matrix | High | frame-waymark | remaining11 | 65516 | 21:30:12–21:30:44 |
| medium-baseline-matrix | Medium | frame-lantern-lit | remaining11 | 39372 | 21:31:23–21:31:56 |
| medium-candidate-matrix | Medium | frame-waymark | remaining11 | 56420 | 21:32:31–21:33:02 |

Exact forward pair --views value:
```text
nave-forward_day_clear,nave-forward_night_clear
```
Exact remaining11 --views value:
```text
nave-forward_day_rain,nave-arches-left_day_clear,nave-arches-left_night_clear,nave-arches-right_day_clear,nave-arches-right_night_clear,nave-reverse_day_clear,nave-reverse_night_clear,shrine-pedestals_day_clear,shrine-pedestals_night_clear,shrine-pedestals-reverse_day_clear,shrine-pedestals-reverse_night_clear
```

Original images/logs remain at .artifacts/f17-material-turn5/. Portable log copies are committed as direct-look/turn5-<run>.log for the eight rows above. Every log reports done2 or done11 as appropriate. Every log also contains the disclosed missing assets/environment/nature/stump_round.glb error, its STUMP type-inference error, depended-script compilation failure and playground_world.gd load failure. Isolated Hall capture continued successfully. **Clean runtime proof FAILED; no warning/error waiver.** No unrelated outdoor repair was attempted. This is the full preserved isolated Hall interior set at the diagnostic raster, not the complete real Village/Hall acceptance matrix. Exterior approach, ordinary world path, shipping-resolution evidence, motion and relevant creature/gameplay proofs remain open.

### Three fresh code-blind verdicts

Neutral copies and unscaled labelled contact sheets: D:/tetherbound/restart-look/.artifacts/f17-pair05-blind/. medium-sheet.png/high-sheet.png contain the forward pair; medium-matrix-0..3.png/high-matrix-0..3.png contain the remaining views. A=baseline, B=material candidate; this mapping was withheld throughout both judging stages. hall_material_blind_1/2/3 were fresh agents with no conversation fork, source, logs, prior scores, intended changes or performance budgets. Each inspected actual images and the existing keyart/ART_DIRECTION/Palworld/Valheim references. They first scored the forward pair; its useful gain justified the broader capture. The same independent judges then inspected the expanded set while still blind. No score was fabricated or inferred from source.

| Judge | Forward Bar A A→B | Forward Bar B A→B | All13 Bar A A→B | All13 Bar B A→B |
|---|---|---|---|---|
| hall_material_blind_1 | 5.7→6.4 | 4.9→5.7 | 5.5→5.9 | 4.8→5.2 |
| hall_material_blind_2 | 6.0→6.5 | 5.5→6.0 | 5.7→5.9 | 5.3→5.5 |
| hall_material_blind_3 | 6.0→6.6 | 5.4→5.9 | 5.9→6.2 | 5.4→5.7 |
| Mean | **5.90→6.50** | **5.2667→5.8667** | **5.70→6.00** | **5.1667→5.4667** |

Each judge gave identical Medium and High scores; table values apply to each preset and their overall assessment. Forward Bar A ranges: A5.7–6.0 (spread0.3), B6.4–6.6 (0.2); Bar B A4.9–5.5 (0.6), B5.7–6.0 (0.3). Full-interior Bar A ranges: A5.5–5.9 (0.4), B5.9–6.2 (0.3); Bar B A4.8–5.4 (0.6), B5.2–5.7 (0.5). All three prefer B; all say NO to8.5 for both treatments/bars/presets.

All judges credit the floor/wall distinction, quieter rear backdrop and banner identity. The wider matrix reduces the gain to **+0.30 Bar A**: black timber dominates reverse/oblique night views; dark floor weakens trainer-leg contrast in gloomy day views; fine paving remains noisy at distance; the abrupt nave/shrine paving edge lacks a threshold. Shared remaining gaps: generic door/portal silhouettes and tiny signs, a small far table against a very large room, repeated lectern-like shrine displays, weak window direction and a brightly lit trainer disconnected from the night room. No judge established a need for new art; installed-family scene, lighting and material work remains justified. The shrine itself is essentially unchanged by this candidate.

This is **one material improvement round**, with one sub0.5 gain on the broader matched interior set. The earlier parity tie is not another improvement round; the forward and expanded scores here are not two rounds. Do not use the forward6.50 as the full-interior score. Neither full Village/Hall acceptance nor landing is earned. **Zero criteria closed; F17#6 goal ACTIVE; candidates OFF.**

### Next game revision after yielding the GPU

Pushed game source cae890f883bca130d56157cb96ba5253f093a356 restores timber midtones (#b7a58b instead of #796854) and routes the existing OFF waymark candidate's daytime recipe into the existing clock-driven window-light builder. Two lights inside west nave apertures aim across the aisle and at the far table; day ambient0.65, energy1.8, range13m, angle42deg, nightOFF. This is a different game composition from the old floor-only window diagnostic; no capture arm or tool changed. Expected result: directional daylight and readable structure while retaining the better material separation. It is **unrendered**, not covered by turn5 scores.

The completed broader verdict additionally prompted a shallow stone sill at the existing shrine doorway, using the existing presentation-only block helper and installed T_Brick texture. Its top is4mm above the authored floor, spans the clear opening, and adds no collider. Expected result: an intentional transition between nave paving and shrine cobbles. It stays under the same OFF candidate. Config parses, scoped diff checks pass, production flags remainOFF and capture script remains AS-IS; native appearance remains unproven. Next granted GPU turn must recapture frame-lantern-lit/frame-waymark on the revised pushed source, keep the fixed views and three independent judges, and re-evaluate the whole interior set against this round's retained best6.00. Do not relabel turn5 images as the new source or invent a new capture mechanism. Portal/shrine identity, fine floor repetition, trainer light/contact integration and the real Village matrix remain work; this source push does not finish the assignment.

## GPU turn 9 — directed-light revision, 14 October 2026, 22:17–22:21 CT

Root explicitly granted turn9 after Routes yielded. Effective permissions never/danger-full-access. Resumed the same F17#6 work; no criterion completion inferred. Captured pushed **44b75fe43a8847b1d902208f859699bc6df975f9** directly from D:/tetherbound/restart-look, existing capture_camera_set.gd AS-IS. Four serial captures each saved all13 views of F17-6-isolated-contact-v2.json: **52 fresh1280x720 PNGs**, matched Medium/High. No retry was needed. All exited naturally0. Final empty Godot census22:20:59; explicit **GPU TURN9 ENDED** and release to Creatures at22:21, before judging. No further engine calls this turn. No stage/shared checkout, cleanup, source-byte gates, preflights, leases or receipt machinery.

Executable: C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe. Actual command argv for each row follows; run/preset/arm values are the exact table entries. No --views filter was supplied, so the unchanged set's complete13-view list ran:

```text
--path D:/tetherbound/restart-look --rendering-method forward_plus --resolution 1280x720
--log-file D:/tetherbound/restart-look/.artifacts/f17-light-turn9/<run>.log
--script res://tools/visual_judge/capture_camera_set.gd --
--set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json
--preset=<preset> --hall-only-ground-y=0 --hall-arm=<arm>
--out=D:/tetherbound/restart-look/.artifacts/f17-light-turn9/<run>
```

| Run | Preset | Arm | PID | Start–exit CT |
|---|---|---|---|---|
| medium-baseline | Medium | frame-lantern-lit | 20124 | 22:17:55–22:18:54 |
| medium-candidate | Medium | frame-waymark | 57304 | 22:19:04–22:19:35 |
| high-baseline | High | frame-lantern-lit | 43936 | 22:19:46–22:20:19 |
| high-candidate | High | frame-waymark | 43716 | 22:20:27–22:20:58 |

Start-Process -WindowStyle Hidden -PassThru and actual-process WaitForExit were used. APPDATA remained D:/tetherbound/restart-look/.artifacts/f17-direct/user; ordinary graphics_override.cfg selected matching preset/base, custom={}, overlay=false, forward_plus. Logs confirm each actual preset and renderer. Source and production OFF gates remained unchanged throughout captures. Original PNGs/logs remain under .artifacts/f17-light-turn9/; committed copies are direct-look/turn9-<run>.log. All four logs report done13views, plus the same four outdoor dependency/compilation errors for missing nature/stump_round.glb and playground_world.gd. **No clean-runtime pass or error waiver.** No new game-code error is reported by these logs, but the isolated capture does not prove ordinary-world operation.

Neutral full-resolution pairs and contact sheets are in D:/tetherbound/restart-look/.artifacts/f17-pair09-blind/: medium-matrix-0..4.png and high-matrix-0..4.png, with all52 individual images. A=candidate, B=baseline; mapping withheld from three fresh no-history judges hall_light_blind_1/2/3. They received only the actual neutral images and existing ART_DIRECTION/keyart/Palworld/Valheim references, no source, prior scores or fix hints. This is one whole-interior lighting/material revision round, not a new forward-only subset round. The previous full-interior best6.00 remains the gain-rule reference; the full Village/Hall criterion also requires the unproven real-world/exterior scope.

### Final independent verdict and park disposition

All three judges inspected all ten sheets covering the complete13-view matched Medium/High set, plus individual original frames and the supplied references. Each preferred neutral A (candidate), modestly; every judge rejected the8.5 gate. Each scored Medium and High identically, so the following applies to each preset and overall; presets are not six independent judges.

| Judge | Baseline Bar A | Candidate Bar A | Baseline Bar B | Candidate Bar B |
|---|---:|---:|---:|---:|
| hall_light_blind_1 | 5.7 | 6.1 | 5.3 | 5.6 |
| hall_light_blind_2 | 6.2 | 6.5 | 5.8 | 5.8 |
| hall_light_blind_3 | 5.8 | 6.1 | 5.4 | 5.3 |
| Mean | **5.9000** | **6.2333** | **5.5000** | **5.5667** |
| Range / spread | 5.7–6.2 /0.5 | 6.1–6.5 /0.4 | 5.3–5.8 /0.5 | 5.3–5.8 /0.5 |

Shared actual findings: quieter nave paving/end wall and marked banners improve hierarchy, but daylight remains broadly uniform with little visible window direction. Night trainer clothing is detached from the surrounding exposure and foot contact remains weak. Large repeated floor/window/post fields dominate; the distant table, ordinary door-like portals and lectern-like shrine supports do not establish a distinctive Hall destination. Shrine views are effectively tied. Judge1 ranks destination identity first; judges2/3 rank spatial lighting first. Judge3's Bar B slightly prefers baseline, so improved finish is not unanimous. No judge found a meaningful High advantage or established that new art is necessary. Suggested game-level directions are purposeful floor zones, authored desk/portal/shrine groupings, motivated light and contact grounding; these are findings, not another authorized implementation round or acceptance claim. No motion, creature-scale, ordinary-world or performance verdict follows from these stills.

The new full-interior candidate mean gains **0.2333 over the retained6.00 best**, not the earlier forward-only6.50. Together with turn5's +0.30, this is **two consecutive improvement rounds below0.5**. Under root's explicit stop rule, **park this Hall approach at best source44b75fe43a8847b1d902208f859699bc6df975f9 / Bar A6.2333**. Preserve all original images, logs and prior failed evidence. F17#6 remains OPEN and unaccepted; all production candidates remain OFF. Do not keep tuning this approach or count the parity tie as an improvement round. The completion objective is not achieved or handed for landing. Its tool status was blocked during the previous repeated slot wait and the available goal API cannot resume it; root's resume directive governed this completed work block, not a false complete status.

**Zero criteria closed.** This block executed actual required visual proof; no game edits or infrastructure changes. GPU turn ended22:21CT before CPU judging, with all four owned children naturally exited and no retry. Next fixed criterion is F38#0, Meadows catalog recapture/rescore. Its existing OFF combined look candidate still lacks a matched visual verdict, so another speculative scene/material edit is not justified before its first direct proof. Existing F38 work note carries the next proof and idle disposition; no engine/import grant is inferred from this queue transition. Root retains board ownership.

## Reopened: one distinct shared-look-first round

Coordinator [11:30PM direction](https://github.com/MJohnsonWellabe/Tetherbound/issues/572#issuecomment-6184399278), reaffirmed [12:30AM](https://github.com/MJohnsonWellabe/Tetherbound/issues/572#issuecomment-6185104936), corrects the earlier immediate park: two flat rounds require one clearly different approach first. Root explicitly reopened F17#6, retained best6.2333, and granted turn18 after Routes17 ended. This supersedes the immediate-park disposition above, without rewriting the actual failed results. F17/F38 remain OPEN and the completion goal is unfinished.

Expected visible result before preview edits: the shared Meadows rim/toon/colour-grade/per-time light treatment should give the village and best Hall material a coherent palette, light hierarchy and surface response. Existing Hall furnishing, timber frame, waymark material/window treatment and lantern recipe are combined unchanged. No new camera, art generation, harness or capture-script edit. The14 preserved Meadows stands and existing15-view full F17 Hall approach/interior set remain the proof cameras. A separate13-view contact-v2 isolated set remains historical evidence; it is not silently substituted for the real-world round.

The completed448-frame F38 round independently exposed a candidate-only vegetation failure (all three prefer baseline; Bar A5.2333→3.7000). Its full rescoring/39-row limits are in ../../F38/look-pass/PROOF.md. The smallest supported game correction preserves Terrain3D's three direct rendering-server map bindings around the existing toon shader swap. Independent source reviewer shared_look_binding_review returned PASS: restore order is correct, material identity/terrain ownership stay intact, and no synchronous lifetime gap is introduced. Godot4.7's implementation confirms the cache-only getter/null-clearing setter cause. Native grounding is still unproven; source review is not a visual pass.

31 runtime files actually missing in turn13 were restored normally, then root-authorized own-checkout headless import PID34488 exited0 at15October01:51:41CT. Both next arms must be captured fresh from this same restored checkout; do not reuse the old missing-resource baseline. No imported metadata is committed. No scene changes were invented for absent checkout assets.

**PREVIEW ONLY, NOT FOR LANDING:** this pushed preview sets the existing four Hall flags true solely for the granted proof. Meadows look_candidate remains false in this first preview; the existing F38 adapter's --meadows-candidate selects it in memory for candidate runs, while baseline omits it. Thus both world arms contain the same best Hall and restored assets. Full F17 baseline uses this preview; its candidate requires a subsequent pushed one-boolean Meadows=true preview because that existing full-world camera adapter has no Meadows CLI arm. Restore all five flags false and push before yielding after an unaccepted run. This explicit owner preview exception is not production activation or permission to merge enabled candidates.

Ready direct batch, unchanged executable C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe, own path, isolated existing APPDATA, fresh outputs and actual pushed SHA recorded at launch:

```text
--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080
--log-file D:/tetherbound/restart-look/.artifacts/f17-shared-turn18-RUN.log
--script res://tools/capture_meadows_look.gd -- --biome=meadows --preset=PRESET --source-commit=ACTUAL_PUSHED_SHA
[--meadows-candidate for candidate only]
--output=D:/tetherbound/restart-look/.artifacts/f17-shared-turn18-RUN

--path D:/tetherbound/restart-look --rendering-method forward_plus --resolution 1920x1080
--log-file D:/tetherbound/restart-look/.artifacts/f17-shared-turn18-HALL_RUN.log
--script res://tools/visual_judge/capture_camera_set.gd -- --preset=PRESET
--set=res://tools/visual_judge/camera_sets/F17-6.json
--out=D:/tetherbound/restart-look/.artifacts/f17-shared-turn18-HALL_RUN
```

World target112frames×2arms×2presets=448; Hall target15×2×2=60 additional frames. No subsets/easier stands, no Hall-only arm on the full-world set. Attempt Medium pairs first, then High within about30minutes;600s child maximum, one actual-failure retry total, explicit GPU release before three fresh blind judges. Retain any incomplete coverage for the next granted turn rather than overrun/claim full proof. Candidates stay unaccepted until required8.5/matrix/review/landing; if this distinct approach remains below8.5, apply the coordinator's park-at-best direction. No Meshy task is justified by the current scene/terrain findings.

### Turn18 actual direct proof and release

15 October CT: first child started02:04:26; last child naturally exited02:25:32. All six children exited0; no retry. Root reiterated the grant-window bound and Hall priority during capture. The outdoor High pair was therefore **UNRUN**. Actual output is284 fresh1920×1080 PNGs:224 outdoor Medium (all14stands×4times×2weather×2arms), plus60 real-world Hall (all15views×2presets×2arms). Frame counts are not proof that each frame is usable. Both outdoor adapter manifests report complete=true, planned_frame_count=112, captured_frame_count=112, failures=[]; every Hall log reports done15views. Both capture scripts remained AS-IS.

Executable and APPDATA are the exact paths above. Every row used the corresponding command template above, replacing RUN/PRESET/SHA as follows; the outdoor candidate alone appended --meadows-candidate. All runs used --path D:/tetherbound/restart-look and Forward+/Vulkan. Full Hall used F17-6.json with no isolated-ground or Hall-arm arguments. The ordinary graphics_override.cfg selected matching Medium/High preset/base, custom={}, overlay=false. No stage, lease, admission or preflight machinery was used.

| Run | Preset | Pushed SHA | PID | Start–natural exit CT |
|---|---|---|---:|---|
| medium-baseline | Medium | 9bdff801d51c6209cfa96ac9bb492da41a58bbb1 | 16372 | 02:04:26–02:09:48 |
| medium-candidate | Medium | 9bdff801d51c6209cfa96ac9bb492da41a58bbb1 | 62580 | 02:10:03–02:15:26 |
| hall-medium-baseline | Medium | 9bdff801d51c6209cfa96ac9bb492da41a58bbb1 | 54020 | 02:15:57–02:17:49 |
| hall-high-baseline | High | 9bdff801d51c6209cfa96ac9bb492da41a58bbb1 | 45888 | 02:18:08–02:19:44 |
| hall-high-candidate | High | e2f55765d8d4479f4f285151a56c2a72d51d1320 | 49784 | 02:21:39–02:23:17 |
| hall-medium-candidate | Medium | e2f55765d8d4479f4f285151a56c2a72d51d1320 | 27788 | 02:23:56–02:25:32 |

The two preview SHAs differ only in meadows_look.json::look_candidate.enabled. Both contain the same best Hall treatment and terrain-map binding fix. After the last exit, all four Hall flags and the Meadows flag were restored false, verified in parsed config and pushed as **cb77e6081f3b44ab511fe744813623e7cb9adfbe**. The02:26:41 process query returned no Godot processes. **GPU TURN18 ENDED**, explicitly yielded to Fights19 before CPU judging. No native/import/render calls after release.

Original logs/images/manifests remain at .artifacts/f17-shared-turn18-<run>[.log]. [turn18-runtime.zip](direct-look/turn18-runtime.zip) preserves the six unmodified logs, both original outdoor manifests and SHA256 entries for all284 original PNGs. [turn18_sheet.png](direct-look/turn18_sheet.png) is one neutral Hall contact sheet; all36 neutral sheets and284 original-resolution hardlinks remain under .artifacts/f17-pair18-blind/. A=candidate, B=baseline; this mapping is withheld from the three fresh no-history judges hall_shared18_blind_1/2/3. They receive only those images and the existing keyart/ART_DIRECTION/5Palworld/2Valheim references. They score whole15-view Hall,13-view interior,14-stand outdoor Medium and observed combined presentation separately; High outdoors is absent.

**No clean runtime pass:** all six logs contain errors. Retained categories include invalid stable-harvest generation, missing craftsperson cloth texture, absent NPC/trainer models/art keys (Relay/Bridge sentries, practice trainer and multiple named trainers), missing cindercub/frostclaw model paths in Hall startup, and growl_idle.wav. No waiver, unrelated repair or claimed gameplay/creature/performance proof follows. Error-line counts in table order:54,53,56,53,53,56.

Independent initial image inspection also reproduced unusable outdoor baseline coverage: Grandpa's Village frames are almost entirely occluded by flat surfaces; some rain views contain black/white/neon artifacts. The original grandpa-s-village__day__clear.png confirms the occlusion. Cause is not established, and complete=true does not erase it. Hall frames are independently reported judgeable. Preserve these failures; no automatic new run or capture-tool change is authorized by this finding. Final scores/disposition follow the completed blind reviews, not the successful file counts.

### Turn18 final three-judge verdict: distinct approach failed, park OPEN/OFF

All three independent judges inspected all36 sheets representing284 images, all8 reference images and ART_DIRECTION; judges1/2/3 additionally inspected4/4/8 original-resolution frames. Each preferred **baseline B for Hall**, and each rejected both bars for every judged scope. Their initial tables were holistic scores; the final explicit two-bar clarifications below are authoritative. Values list judges1/2/3, followed by mean and spread (max−min). Presets are not additional independent judges.

| Exact observed scope | Baseline Bar A: scores → mean / spread | Candidate Bar A: scores → mean / spread | Baseline Bar B: scores → mean / spread | Candidate Bar B: scores → mean / spread |
|---|---|---|---|---|
| Full15 Hall, Medium | 6.3,6.1,6.1 → **6.1667 /0.2** | 6.2,5.8,5.9 → **5.9667 /0.4** | 6.2,6.2,5.7 → **6.0333 /0.5** | 5.8,5.5,5.3 → **5.5333 /0.5** |
| Full15 Hall, High | 6.4,6.2,6.1 → **6.2333 /0.3** | 6.3,5.9,5.9 → **6.0333 /0.4** | 6.3,6.3,5.7 → **6.1000 /0.6** | 5.9,5.6,5.3 → **5.6000 /0.6** |
| Interior13, Medium | 6.1,5.9,5.9 → **5.9667 /0.2** | 6.0,5.6,5.7 → **5.7667 /0.4** | 6.0,6.1,5.6 → **5.9000 /0.5** | 5.6,5.4,5.2 → **5.4000 /0.4** |
| Interior13, High | 6.2,6.0,5.9 → **6.0333 /0.3** | 6.1,5.7,5.7 → **5.8333 /0.4** | 6.1,6.2,5.6 → **5.9667 /0.6** | 5.7,5.5,5.2 → **5.4667 /0.5** |
| Outdoor14 stands, Medium | **Unjudgeable intended scene** | 5.2,4.5,4.8 → **4.8333 /0.7** | **Unjudgeable intended scene** | 4.8,4.4,4.0 → **4.4000 /0.8** |
| Observed combined Village/Hall | **Unjudgeable intended scene** | 6.0,5.5,5.7 → **5.7333 /0.5** | **Unjudgeable intended scene** | 5.5,5.2,5.0 → **5.2333 /0.5** |

Judge1 withheld baseline outdoor/combined art scores. Judges2/3 supplied delivered-failure scores only (outdoor Bar A1.5/1.8, Bar B1.0/1.2; combined Bar A3.0/3.4, Bar B2.5/3.0), explicitly excluding any valid intended-scene comparison. These are preserved here but **not averaged or used as an art gain**. No numeric outdoor before/after improvement is established. All judges found all Hall images and candidate outdoor images usable for static criticism. Baseline eight-condition sets at Grandpa's Village, Old Mill, Stronghold Approach, Warrens, Ironwood, Quarry, Ridgeline and South Bridge were unusable; additional rain frames failed. Both village-reverse arms show a close Home arch, not an outdoor reverse composition.

The valid same-round Hall comparison is **−0.20 Bar A** at each preset, full15 and interior13. Baseline better separates the trainer at night and gives stronger warm/cool local contrast. Both retain generic domestic-door portals, repeated empty lectern-like shrines, dark signs, broad repetitive paving/posts/windows and weak inhabited focal hierarchy. Examples: nave-reverse_night_clear, nave-arches-left_day_clear, nave-arches-right_day_clear and shrine-pedestals_day_clear. Candidate outdoor criticisms name grass carpets/weak middle distance at stronghold-approach and ridgeline, slab-like Warrens terrain, abrupt road/vegetation transitions and lost route/trainer-leg readability at ironwood-grove__night__rain. None establishes that a new Meshy hero is necessary; scene/material/light work remains the supported category.

**Disposition:** the coordinator acknowledged this third, clearly different approach and authorized park after the actual failed judges. F17#6 is **PARKED, OPEN, unaccepted, all flags OFF**. Retain historical best source44b75fe43a8847b1d902208f859699bc6df975f9, historical13-view isolated mean6.2333; that is an older panel and scope, not this round's matched baseline or a cross-panel gain calculation. Do not retune Hall again under this disposition. Full Village/Hall acceptance, High outdoor coverage, gameplay/state proof and landing remain unearned. No production activation or READY handoff.

**Zero criteria closed.** Game work exercised was the shared-look terrain-map binding correction plus existing best Hall/shared look. Six direct captures and three independent image reviews are actual proof attempts; failed/unrun coverage and original runtime errors remain above. No infrastructure was added. Advance the fixed queue to **F38#0 only**, with one bounded OFF night-readability config change supported by these actual frames; its implementation and next proof are recorded in the existing F38 look-pass/PROOF.md. The F17 completion objective has not been falsely marked achieved.

## Owner Meshy-first restart: F17#6 active again (15 October,05:41CT relay)

Newest owner directions [6190123384](https://github.com/MJohnsonWellabe/Tetherbound/issues/572#issuecomment-6190123384) and [6190144559](https://github.com/MJohnsonWellabe/Tetherbound/issues/572#issuecomment-6190144559) were fetched directly and applied immediately. They supersede the earlier park/queue direction and Meshy-fallback/nightly-cap restrictions. Look returns to Hall/Village first; Tidewake work stops with its actual evidence preserved at e2fd01db17. **New acceptance bar: three fresh blind judges mean Bar A>=7.5 on the required fixed set, Bar B reported; other preset recheck and required proof/landing still apply.** Old scores remain their actual historical results, not retroactive closures. Two successive paired gains<0.5 still stop an unchanged approach. No stage access or new capture/harness; no native authority follows from generation.

Expected visible change stated before generation: replace domestic-door portal identity and lectern-like shrines with purposeful carved civic thresholds and empty relic cradles, then quiet the repeated stone/timber/plaster wall fields. The existing `ralph/reports/HUB/f17/meshy-handoff/README.md` supplies the two named hero subjects,1.80m trainer ruler, portal bay dimensions and pedestal target. Prior best/reference evaluation and turn18 criticism supply the material hierarchy gap. This is a different asset approach, not another grading iteration.

The available skill catalog/local/global roots exposed no Meshy SKILL.md; existing `tools/art_pipeline/meshy.py` REST client and its already-used image-to-3D settings were reused, unchanged. Built-in imagegen drafted one original reference per asset; each full image was inspected before submission. Existing environment credential was used without printing/persisting it. No new client, generation harness, script edit, purchase or native import. References, exact image prompts, API settings, source/task provenance and raw models are under `assets/props/crossing_hall_hero/<asset>/`; references and raw source folders contain .gdignore. Source GLBs remain untransformed and are not runtime-loaded.

| Named asset | Meshy task | Actual status | Target size only, not measured |
|---|---|---|---|
| portal |01a13f2a-f7fa-7318-8c5d-08fe8af8a57f|SUCCEEDED; original GLB and preview downloaded|3.2m wide ×4.3m high ×0.5m deep; opening target>=2.4×3.6m|
| pedestal |01a13f2c-400b-70cc-8fcc-7bf1874fe6c3|SUCCEEDED; original GLB and preview downloaded|0.8m square base ×1.1m high|
| wall_bay |01a13f2e-f35a-7557-bb79-0bc4cbd43cd4|SUCCEEDED; original GLB and preview downloaded|2m wide ×3.12m high ×0.22m deep|

Returned previews inspected: portal has the intended empty aperture, stone piers and timber/bronze upper structure; pedestal retains a shallow empty cradle and three supports; wall keeps a broad quiet plaster field with timber borders and two low stone courses. These are service previews, **not Godot frames or art acceptance**. The portal's actual opening and overall size may conflict; must measure rather than assume the prompt dimensions were obeyed. Pedestal base footprint and relic placement, wall rear surface/module seams, texture behaviour and camera readability remain pending. No model has been imported, scale-checked, wired into runtime or activated. Account balance before submissions15300, after first two15180, after third15150; shared-account changes are observations, not unsupported per-task cost attribution. Credits available; no exhaustion or purchase.

**Next concrete work:** under the next root native grant, reuse existing model inspection/import/asset preparation, measure all three, then integrate behind an OFF Hall asset candidate. Keep portal action/state/sign semantics, Shrine interactions/approach positions and existing route clearance intact; measured geometry must fit existing bays and remain coherent with membrane/locked/sealed treatments. Use unchanged fixed Hall cameras for real paired scene images and three fresh code-blind judgments; full selected criterion required, no subset closure. Native ended at turn30 release05:34:48; none since. **Zero criteria closed.** Active F17 objective remains unfinished; generated task success is asset progress only.

The previously scoped1.4×1.8×0.12m civic identity relief is also now generated, from the established `assets/ui/hall_waymark.svg` motif: one home doorway/threshold and exactly seven route studs, no new biome identity. Meshy task **01a13f34-9ad6-772b-9760-45244a433dc2 SUCCEEDED**; original reference, exact imagegen prompt, source GLB/preview and API provenance are under `assets/props/crossing_hall_hero/waymark_relief/`. Both full reference and service preview were inspected; seven studs and the solid-backed doorway relief are visible. The old evaluation's Meshy-fallback disposition is superseded by the explicit first-line owner direction.

**OFF game integration:** `crossing_hall.json::hall_hero_assets.enabled=false` guards one rear-wall relief at local[0,3.4,14.84], yaw180. `crossing_hall.gd` dynamically loads it only under that gate, fits only the instance with the existing render-bounds helper, centres X/Z and anchors its base, after the old material retint pass. Model geometry/materials remain unchanged; ordinary Hall ambient treatment still applies. The raw generated GLB was copied unchanged into its runtime models folder, without import. No collider, input, portal state, interaction, durable state or network mutation. Config remains OFF alongside all four prior Hall gates; capture script unchanged. Portal/pedestal/wall-bay replacement bindings remain pending measured fit rather than guessed aperture/physics.

Independent changed-source review returned bounded PASS: defaultOFF prevents resource loads, transform algebra is correct for identity root rotation, no gameplay writes, retint ordering correct; imported root/material/collision facts were unavailable at review time and stay unproved. JSON and scoped diff check pass. No Godot/parser/Blender/import/render/scale measurement sinceEND30. Native grant request stays here: inspect/import/measure the four generated assets with preserved tools, correct asset placement/scale under that grant, finish OFF scene binding, then actual unchanged fixed-camera Hall proof and fresh three-judge7.5bar. Generation/service thumbnails and CPU review close zero criteria.


## Turn34 � generated Hall asset native fit and direct proof (15 Oct 06:31�06:43 CT)

Root granted the sole native turn34 on pushed907e39b9ac584e5fdc88786c21c784ef86d8ccce. Expected visible result: the generated civic relief gives the rear nave a recognizable destination focal point. Existing capture script unchanged. No stage, lease, admission or byte gates. Owner comments6190123384/6190144559 govern Meshy-first and **7.5 three-judge Bar A**; previous8.5 references remain historical.

Existing Blender4.2.9 `tools/art_pipeline/blender/inspect_glb.py -- assets/props/crossing_hall_hero/<asset>/source/model.glb --out .artifacts/look34-<asset>-inspect.json` opened all four models, each naturalexit0. Static meshes have one material and no armature/animation. Retained topology diagnostics are not rejection reasons. Original GLBs remain unchanged. Actual portal cross-sections at target3.2m outerwidth/4.3mheight show central clear-span upper estimates1.701m at0.1mheight,1.863m at1.8m,1.713m at3m,0.888m at3.6m: insufficient for2.4x3.6 opening. Portal stays uninstalled pending a geometric revision. Pedestal raw1.90345x1.56429x1.78321m needs target0.8x1.1x0.8 fitting and matching interaction/collider review; not installed. Wall bay raw1.40404x1.903x0.15127m has not yet received scene fit. Relief identity-root raw1.366712x1.903037x0.101216m was fitted by the existing game binding to1.4x1.8x0.12m; actual images show correct orientation/material, but the existing central lantern crosses its emblem.

Godot4.7 executable `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe`, APPDATA=`D:/tetherbound/restart-look/.artifacts/f17-direct/user`. Changedscript check `--headless --path D:/tetherbound/restart-look --check-only --script res://scripts/world/crossing_hall.gd --log-file D:/tetherbound/restart-look/.artifacts/look34-hall-parser.log`: PID45740,06:31:45�06:31:47,naturalexit0. Existing import `--headless --editor --import --path D:/tetherbound/restart-look --log-file D:/tetherbound/restart-look/.artifacts/look34-required-import.log`: PID31208,06:35:41�06:36:07,naturalexit0,existing180s bound. Relief imported successfully; the other three raw source directories remain ignored by Godot.

Every capture used actual executable above and:
```
--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan
--resolution 1920x1080 --fullscreen
--log-file D:/tetherbound/restart-look/.artifacts/look34-<RUN>.log
--script res://tools/visual_judge/capture_camera_set.gd -- --preset=<PRESET>
--set=res://tools/visual_judge/camera_sets/<SET>.json
--out=D:/tetherbound/restart-look/.artifacts/look34-<RUN>
```
Isolated rows additionally used `--hall-only-ground-y=0 --hall-arm=frame-waymark`. Actual local graphics preference matched each preset, base same,custom={},overlay=false,Forward+. All children naturalexit0, allPNG1920x1080. No ERROR/WARNING lines in retained parser/import/capture logs; clean process logs do not cure the failed full-world subject coverage.

| RUN | PRESET / SET | actual pushed source | PID / CT start�exit | Result |
|---|---|---|---|---|
| medium-base | Medium / F17-6 | 9830fa0fec866520a0afc3bb8841aaa4b5291464 |44296 /06:37:42�06:38:57|15 images INVALID Hall evidence: terrain captured before world finished scatter and built Hall |
| medium-base-isolated | Medium / F17-6-isolated-contact-v2 | a33833e068d0fcfc0cefe02f2fc2875ba2c38a7a |62868 /06:39:31�06:40:10|13 actual Hall views |
| high-base-isolated | High / F17-6-isolated-contact-v2 | a33833e068d0fcfc0cefe02f2fc2875ba2c38a7a |62836 /06:40:32�06:41:10|13 actual Hall views |
| medium-hero-isolated | Medium / F17-6-isolated-contact-v2 | b01f0e402834f05b759c1252893645410090e2d3 |11224 /06:41:49�06:42:27|13 actual Hall views, relief loaded |
| high-hero-isolated | High / F17-6-isolated-contact-v2 | b01f0e402834f05b759c1252893645410090e2d3 |54344 /06:42:50�06:43:28|13 actual Hall views, relief loaded |

Full-world attempt used existing600s bound; isolated route used existing120s bound. One failed proof route followed by its single supported fallback batch; no further retry. Full-world returned0 but screenshots and shell_build log prove capture outran construction. No empty-world art score. No capture-script repair. Full ordinary Village/Hall matrix remains unproven. The isolated script's historical console text says productionflagsOFF; specifically its four checked flags wereOFF and the new hero flag was temporarilyON only on b01f0e4028. Baseline and candidate shared the identical frame-waymark private config.

**GPU TURN34 END06:43:51CT**, actual Godot/Blender census empty; all five Hall candidates restoredOFF and pushed **e60e58dd613b5a7500e3b91ca6cf0613da7d30b5** before explicit yield to Fights35. CPU-only judges follow release. Zero criteria closed; no activation, full-matrix acceptance or landing.

Original PNGs and logs preserved in `direct-look/turn34-<RUN>.zip`, each contains individual SHA256SUMS.txt. Archive SHA256, in table order: `73ef7686a90d28612fce9f7487f41095e6f9766eff8624abef627b58f706d610`, `d6a99559a72ee2762364ac44979323df2955ac7e938727cec7252ef3aad66eb5`, `4e3c947e70987ca02ca987c3d12485593f3ba4789816720d0f9c693a80451f6d`, `266189cc25c65f04bdaab8779eb888ff187df7a1c22f7ebed0833bf99e2be891`, `69e58f7e837b5dd1bb4cab3ec5719176afa5a9ea5061a6842327a8e3b489b7e0`. `direct-look/turn34-native-inspection.zip` preserves native measurements/parser/import logs. Neutral paired contact sheets use A=reliefcandidate,B=baseline, withheld from judges; all13 views/preset included.


Turn34 fresh independent code-blind verdicts (all8 neutral sheets,52frames; each judge also inspected full-resolution pairs and preserved keyart/Palworld/Valheim references):

| Judge | Medium A/B BarA | High A/B BarA | Medium A/B BarB atmosphere | High A/B BarB atmosphere |
|---|---|---|---|---|
| meadows22_blind_1 |6.0/5.9|6.0/5.9|5.8/5.8|5.8/5.8|
| meadows22_blind_2 |6.0/5.9|6.0/5.9|5.5/5.5|5.5/5.5|
| hall34_blind3 |6.1/6.0|6.1/6.0|5.2/5.2|5.2/5.2|

Both presets: candidate BarA **6.0333**,baseline **5.9333**,spread**0.1** each,gain**0.10**; BarB**5.5000**,spread**0.6**,tie. Allthree narrowly preferA; allfail7.5. Their shared findings: the small emblem helps onlyforwardnave identity, existing lantern obscures it; broad empty floor and distant small furniture lackcivicpurpose; repeatedwindows,stripedtimber,outlinedstone and emptylecterns compete; brightwindowslackdirectionaldaylight,shrineatnightgetsabroadwallwash. Judges recommendintegratedciviccomposition,calmermaterialhierarchy,source-alignedlight; no mandatorynewasset inferredfromthisround. No creatures,motion,functionalportal/relicstates or ordinaryVillage proof. One new Meshy relief improvementround gainedunder0.5; old runtimeparitytie isnotanart improvementround. Neutral sheets retained in `direct-look/turn34-neutral-sheets.zip`.

### CPU game follow-through after END34

Expected result stated before edits: one coherent rear-wall civic composition, larger relief, quiet generated plaster/timber backing, existing lantern clearofemblem. Implemented behindOFF`hall_hero_assets`: wallbayboundsX[-1.7,1.7],Y[.06,6.06],Z[14.39,14.61];reliefX[-1.05,1.05],Y[3.2,5.9],Z[14.29,14.41]. Reliefback overlapsbackingbounds2cm; actualsurfacecontact needsnativeinspection. This liesontheclosedrearwall,betweenexistingbanners,below6.2mceiling,notacrossportal/shrineopening. Preservedraw wallGLBcopiedtoruntimepath; measuredidentityrootstaticmesh, materialuntouched. One stable`nave_focal`lightIDselectsitscandidateposition[3.6,3.4,14.4] intheclearrearbay; fixture/flame/lightmovetogether,yaw/energyunchanged. Movingrightwaschosenoverloweringbehindthetable. No additional light, physics, interaction, save/network change. No creature rescaling. DefaultOFFpathskeepoldplacement anddonotloadnewmodels.

Independent CPUsource reviewer tidewake30_blind1: boundedPASS; gates/fallback,identityroots,boundsfitting,scopechecked; JSON+scopeddiffchecksPASS. No native parser/import/render afterEND34. Appearance,wallcontactandclearance remainunproven. Next grantedturn mustparsechangedGD,importwallbay,thenmatchedfixedHallM/Hproofwithfresh3judges; fullordinaryVillage/Hallmatrixstillrequiredandcurrentlyblockedbyactualworld-loading/capturetiming. No script/harness change here.

Remaininggeneratedassetdecisions: portalv1 isNOTinstalledduemeasuredaperturefailure; pedestalv1 targetheight1.1m withuniformscalewouldneedabout1.34x1.25mfootprint,exceeding0.8mbrief (fitting0.8widthwouldleaveheight~0.66m). Do not distort/forceeitherintoexistingportalactionsorcollision. Correctedreferencespreserveidentity: pedestalv2 taller/narrowerwithsmallfoot; portalrefv2 rejectedbeforeMeshy, finalfrontv3 muchwiderhole/slenderpiers. Both finalreferencespersonallyinspectedbeforeMeshysubmission. Newpedestaltask**01a13f6a-14f6-706a-ba89-45695b7a3255**,newportaltask**01a13f6b-5abe-7592-8cf7-b439ee1cfd8a**; provenance-v2.json retainssettings/referencehash/taskID/status. No new purchase,no localnativejob. Native measurementsandactualsceneproofremainrequired;generationisnotacceptance. Alloriginalsv1preserved.


Post-END34 source/proof commit **d1adf2ab2efe6514035c999321fc78b8447e4f76** pushed to tb/look. Both corrected Meshy tasks reachedSUCCEEDED100percent at07:00CT. Downloads are intentionallypendingresourceheadroom; taskIDs andrefs retainedinprovenance-v2.json. No laternativeprocesswaslaunched.

At06:58CT Git's evidence-object write reproduced `No space left on device`, D:free0. To preserve everything withoutdeletion, six task-owned generated directories (`look34-neutral`, `look34-medium-base`, `look34-medium-base-isolated`, `look34-high-base-isolated`, `look34-medium-hero-isolated`, `look34-high-hero-isolated`) movedfrom `.artifacts/` to `C:/Users/mattj/.codex/visualizations/2026/10/14/01a13c92-b230-70b3-bb39-3ebb88cd3489/look34-retained/`. Resolvedcontainmentandno-link/file-onlychecks passedbeforemove. 361,285,106logicalbytes preservedthere; originalcommandpathsabovearehistoricalcapturelocations. Logs remainin.artifacts; fulloriginalframes/logs alsoin pushedZIPs with individualhashes. No authoredasset,importcache,otherlane,stageorsave touched. C:~7.15GB,D:~148MB afterGitobjectwrite; existingresourcefloorsremainunchanged. No furtherrender/import orMeshydownloaduntilrootrestoresheadroom. This is a disk constraint, not stage admission.

Next minimum actions: recover diskheadroom, fetch the two alreadySUCCEEDEDMeshy tasks using existing `meshy.py` fetch route, then undernextnativegrant measure revised aperture/pedestal footprint and parse/import the OFF wall composition. Corrected portal/pedestal integration still must preserve portal states/actions and match physics/labels/clearance. Existing capture script remainsAS-IS; ordinaryworldcapturetimingfailure requires an already-supported fullybuilt-world proof route before fullF17closure. No fullcriterionacceptance from isolatedscore6.0333. GoalF17#6unfinished; noF38advance or READYhandoff.


### Corrected portal/pedestal preparation after capacity recovery (CPU only)

Root verified this session's actual approval_policy=never and sandbox_mode=danger-full-access, then authorized fetching the two completed jobs on D while Creatures36/Routes37 own native. Both fetched using existing meshy.py request/fetch functions without tool changes. Preserved raw models, thumbnails and service provenance are in portal/source-v2 and pedestal/source-v2; both directories have .gdignore. Original v1 files and all references remain intact. Runtime copies under models are unchanged copies of these corrected models. Both thumbnails were personally inspected: same limestone/bronze/timber identity and visibly corrected aperture/pedestal proportions. No Godot, Blender, import, render, stage or cleanup operations occurred.

CPU embedded GLB measurements: both models have an identity root and one static mesh. Portal raw bounds size is 1.379358 x 1.902831 x 0.216121 m. At authored outer size 3.2 x 4.3 x 0.5 m, central clear spans are approximately 2.6526 m at height 0.1, 2.7449 m at 1.8, 2.7444 m at 2.6, 2.7450 m at 3.0, and 2.2771 m at 3.6; the central crown closes near 3.95 m. These support preparing the larger presentation, not a whole-Hall clearance pass. Pedestal raw size is 1.030990 x 1.902666 x 0.956217 m. Uniform scale 0.578136 yields height 1.1 m and footprint 0.596052 x 0.552824 m, inside the 0.8 m maximum without distortion. Its measured front surface at label height 0.65 m is Z=0.22088; the label is placed at Z=0.229.

Expected visible result stated before editing: stone shrine displays replacing household lecterns, and larger civic portal surrounds with coherently fitted existing doors, state surfaces and signs. Behind OFF hall_hero_assets, the pedestal uses uniform fitting and a collider matching the measured mesh bounds. Slot positions, Stand/PedestalBody names, approach markers, prompts and relic transaction identity remain unchanged. The wider legacy 0.9 m companion keep-clear footprint is retained. Portals retain entry positions/yaws, actions, approaches, IDs, home culling and existing open/locked/sealed/stirred state ownership. Their existing door is fitted from measured native bounds; signs sit on the new header. The candidate state fan follows the measured inner opening with slight overlap under the frame, preserving winding and material state selection. No durable-state or network writes were added. Missing or invalid hero models report an error and fall back to legacy presentation; this is not a proof pass.

Independent CPU source review found one actual P2: the enabled legacy crossing_hall_claude sealed reveal would scale the new fan with the old reveal transform, producing an oversized roughly 3.183 x 4.498 m fan. Corrected the game integration only: a marker is set after successful hero surround fitting, and legacy reveal/signage creation skips marked slots. No claude_infill/sign metadata can then resize those hero surfaces. Existing pools, ambient handling and default/fallback arches retain their prior treatment. Reviewer tidewake30_blind1 rechecked the correction: P2 resolved, bounded source PASS, no remaining actionable source findings. Pedestal fitting/collider/keep-clear, prompts, approaches and portal state/winding were also reviewed. JSON and scoped whitespace checks pass.

All five Hall candidates remain OFF. Native parser/import, door/sealed/home-state fit, pedestal collision/label clearance and actual scene appearance remain UNPROVEN. The existing wall backing, enlarged relief and lantern correction remain part of this same candidate. Next explicit native grant must first parse both changed GD files, then use existing inspection/import and matched fixed Hall Medium/High cameras with three fresh blind judges against the owner's 7.5 Bar A and reported Bar B. Required ordinary Village/Hall/state/clearance proof still governs acceptance and landing. No new capture scripts, tools or validators. D had 24.82 GiB free before the asset commit; preparation stays within the authorized 1 GiB estimate, with no new C payloads.

Game/asset commit f0e9a19ceb88ed6924a2b6f7bcddda22f1e240eb was pushed. Its evidence-note write failed on a Windows cp1252 Unicode encoding error and unintentionally emptied this README. This successor restores the exact README bytes from 6c44ded140, then appends this preparation result in explicit UTF-8. Earlier evidence and files remain preserved in Git and the committed proof archives. F17#6 remains OPEN; no closure, activation or READY handoff.


### Look 16-hour checkpoint — recorded 15 Oct 09:34 CT, due 09:41:42 CT

**Zero whole criteria closed.** The central cause is that the game has not earned the visual bar: the newest complete isolated Hall interior comparison scored candidate Bar A 6.0333 versus baseline 5.9333 (gain 0.10), below the owner's current 7.5 threshold; Bar B remained 5.50. Judges still find weak civic composition, repeated noisy materials and flat daylight. Earlier retained-stage/source-admission work consumed time without frames before the owner ended that route. Later direct captures produced useful diagnostics but did not prove the ordinary Village/Hall experience. Turn34's full-world attempt captured terrain before Hall construction completed; its 15 frames are invalid Hall evidence despite exit0. The four successful isolated runs cannot replace that missing matrix or portal/relic-state, creature-clearance and motion evidence. Shared native scheduling and the subsequently recovered disk-full incident delayed the next proof; neither explains away the below-bar art.

**Unaccepted game work:** the OFF candidate now combines a quiet generated civic wall bay, larger relief and lantern moved clear of it, corrected wider portal surrounds with fitted existing door/state surface/signs, and uniformly scaled stone shrine pedestals with matching local colliders and retained companion keep-clear envelope. Corrected portal/pedestal sources and references are preserved. Independent source review passes after fixing a legacy sealed-reveal transform conflict. This is implementation, not visual acceptance.

**Failed/unrun proof:** full-world turn34 coverage failed as above; the current four-asset composition has not yet been parsed/imported/rendered. Native state/door/contact/collision checks and three fresh blind judges remain unrun. No candidate activation or landing is authorized by the old 6.0333 score. All candidates remain OFF; capture scripts unchanged.

**Next bounded acceptance attempt:** explicit Look38 after Routes37 END/census. First existing Godot check-only on changed Hall script (and its changed preloaded Hall-interiors dependency), existing native model inspection/import, then matched existing fixed Hall Medium/High captures using a frozen pushed source and fresh outputs on D. Honor the existing isolated120s child bound, one actual-failure retry, roughly30min turn, unchanged reserves and at most1GiB incremental D allocation; no deliberate C payload. Inspect the actual scene/state/clearance result, restore OFF and drain native children before yielding Fights39, then three fresh code-blind judges. Full ordinary Village/Hall proof still must be obtained through a supported existing route; no new capture/harness or easier subset can close F17. If only isolated evidence succeeds, retain its limited verdict and continue/park by the actual art outcome rather than claiming whole closure.

Historical README restoration independently verified: current committed note begins with all **77,764 exact bytes** from 6c44ded140; only the intentional corrected-asset preparation result was appended. All historical assets/evidence retained. Source for root review before this checkpoint append: **f8ad3014bf23594b13e78ef1ba0ca766b6641a9b**; compare against6c44ded140 for the scoped portal/pedestal game changes. No additional review packet created.


### Look turn38 - native proof 15 Oct 09:47-10:02 CT

F17#6 remains OPEN; zero criteria closed. Root granted corrected portal/pedestal plus wall/relief/lantern candidate proof, then Fights39. Production source began at d7419a95e874fb59e8524cc72ef1c0ee31318b8b. Native parser checks for crossing_hall.gd and crossing_hall_claude.gd both exited0 (09:47:35-09:47:39). Ordinary import ran09:51:20-09:52:56, exit0. Existing Blender inspect_glb.py inspected preserved portal/source-v2/model.glb, pedestal/source-v2/model.glb and wall_bay/source/model.glb at09:55:24-09:55:29; all exit0. Blender reports Z-up dimensions consistent with the CPU glTF Y-up measurements; this is model inspection, not passage clearance.

Actual Godot executable: C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe. APPDATA=D:/tetherbound/restart-look/.artifacts/f17-direct/user. Check commands: `--headless --path D:/tetherbound/restart-look --check-only --script res://scripts/world/crossing_hall.gd --log-file D:/tetherbound/restart-look/.artifacts/look38-crossing_hall-parser.log`, then identical args for crossing_hall_claude.gd/look38-crossing_hall_claude-parser.log. Import command: `--headless --editor --import --path D:/tetherbound/restart-look --log-file D:/tetherbound/restart-look/.artifacts/look38-required-import.log` (180s outer bound, natural exit).

The unchanged capture_camera_set.gd ran four times, each with actual common argv `--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --fullscreen --log-file D:/tetherbound/restart-look/.artifacts/look38-RUN.log --script res://tools/visual_judge/capture_camera_set.gd -- --preset=PRESET --set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json --hall-only-ground-y=0 --hall-arm=frame-waymark --out=D:/tetherbound/restart-look/.artifacts/look38-RUN`. RUN/PRESET and source below are the literal substitutions used. Ordinary graphics_override.cfg matched each requested preset. Actual renderer logs confirm Forward+ Vulkan on GTX1060 3GB. All four children ended naturally within the unchanged120s bound; no retry.

| RUN | PRESET | source | CT interval | PID | result |
|---|---|---|---|---|---|
| medium-base | Medium | d7419a95e874fb59e8524cc72ef1c0ee31318b8b |09:53:22-09:54:11|64528|exit0,13PNGs|
| high-base | High | same d7419a95e8 |09:54:31-09:55:09|12244|exit0,13PNGs|
| medium-hero | Medium |5a70047a3382ac8e94051f6f9124b1f57cb42010|09:56:09-09:56:48|45160|exit0,13PNGs|
| high-hero | High |same5a70047a33|09:57:06-09:57:45|4224|exit0,13PNGs|

All52 native PNGs verified1920x1080. Candidate preview source changes only hall_hero_assets.enabled=true from the baseline; the existing arm privately selects furnishing/frame/waymark/lantern in both sides. The script's historical console text says production flags OFF because it checks those four gates; hero assets were explicitly diagnosticON at the pushed source above. No script changes. The new wall/relief, moved lantern, corrected portal/door/surface geometry and stone pedestals visibly render. This establishes their isolated presentation, not accepted quality, earned-state coverage, collision clearance, creature motion or ordinary Village/Hall proof. Parser/import/four capture logs contain no ERROR/WARNING/SCRIPT ERROR lines.

Ordinary-world attempt used pushed diagnostic92d449ae26e45d79e8ea218ce1bc487425c0b52b (all five presentation candidatesON for this run only): `--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --fullscreen --log-file D:/tetherbound/restart-look/.artifacts/look38-world-circuit.log --script res://tools/capture_f17_visual.gd -- --preset=Medium --paired-high --source-commit=92d449ae26e45d79e8ea218ce1bc487425c0b52b --output=D:/tetherbound/restart-look/.artifacts/look38-world-circuit`. PID53752 started09:58:37 with600s outer turn allocation, existing proof unchanged. It progressed through actual world construction, then reported missing outdoor NPC/trainer art keys and Vulkan allocation failures: `ERROR: Can't create buffer of size: 256 (VkResult error -2).` Subsequent invalid-buffer/vertex errors flooded the log. Stopped the owned failed child at10:01:46; exit-1 is forced, NOT natural or clean. ZERO output files/valid world frames. No fullworld retry, profiling, unrelated fixes or relaxed guard. The preserved log contains83,665 error/warning lines. All originals retained.

All five candidates restoredOFF and pushed at ff20e2c5483f220bff07bbc4b09f58c36bac340c. Turn38 explicitlyEND at10:02:26 after actual Win32_Process census returned no Godot/Blender. GPU yielded to Fights39. No native processes afterEND. Root observed Cfree2.43GB during failure and6.91GB after child end, a transient resource-pressure observation with cause unproven; no deliberate C payload writes or deletions. Dfree was24.32GiB after run, above20GiB floor. New local look38 artifacts355,010,531bytes before archives, within2GiB turn allowance. No stage, lease, admission machinery or capture tooling accessed/changed.

Preserved evidence: direct-look/turn38-{medium-base,high-base,medium-hero,high-hero}.zip each contains13 original PNGs and original capture log; turn38-neutral-sheets.zip contains eight neutral paired sheets from existing tools/sheet.py; turn38-native-inspection.zip retains parser/import/Blender reports and failed world log. Every archive contains SHA256SUMS.txt; all77 archived entries verified after packaging. Native originals and neutral full-size copies remain .artifacts/look38-* on D. Blind mapping withheld until verdict: A=baseline, B=candidate, same for Medium/High. Three fresh independent judges now inspect the same panel; verdict pending. No acceptance or activation inferred from successful capture.


### Turn38 blind result and next game correction - CPU only after native END

All three fresh judges inspected all eight neutral sheets (52 native frames) and selected full-resolution originals, with the same reference/rubric, no source/mapping/other verdicts and no native calls. Each gave identical Medium and High scores because the images did not support a meaningful preset difference. Owner's current7.5 Bar A applies; Bar B is the written atmosphere/lighting target, not a second general-finish score.

| Independent judge | A baseline Bar A | B candidate Bar A | A/B Bar B | preference |
|---|---:|---:|---:|---|
| meadows22_blind_1 |5.9|6.6|5.8/5.8|B|
| meadows22_blind_2 |5.9|6.4|5.5/5.5|B|
| hall34_blind3 |6.0|6.6|5.2/5.2|B|

For BOTH Medium and High: baseline Bar A mean5.933333, spread0.10; candidate mean6.533333, spread0.20; matched-panel gain0.60. Bar B mean5.50, spread0.60, unchanged. Candidate gain over prior best turn34 mean6.033333 is exactly0.50 using unrounded scores; this is not a second consecutive under0.5 round. No7.5 pass and no whole-feature closure.

All three independently prefer the new portal rhythm, civic emblem/backing and shrine pedestal silhouettes. All still reject acceptance: accents look attached rather than integrated; nearly white stone contrasts abruptly with dark masonry/warm shell; tiny dark portal labels compete with bright frames; pedestal names wrap directly across curved stone. From the shrine, a dark adjacent panel visibly intrudes into the opening composition, though frames do not establish collision obstruction. Home opening has nested contrasting silhouettes. Repeated outlined paving/window grids/striped posts dominate a sparse room. Daytime windows do not create convincing light across beams/floor, rain flattens the scene, and night shrine wall wash competes with the focal emblem. Ranked next work is existing scene/material/signage integration and source-aligned lighting; none of the judges establishes a need for another hero asset. These are isolated still verdicts only: no Village/exterior/route/portal functionality/earned relic/creature/motion acceptance.

Next expected player-visible result was stated BEFORE editing: retain the stronger civic silhouettes, warm the new pale stone into the Hall palette, and mount shrine names on deliberate plaques instead of printing them across curved columns. Implemented one coherent material/signage revision in owned game source, CPU only: reuse existing _retint with per-asset Material_0 colour config (the name exists in each preserved raw GLB); duplicate local materials via existing helper while preserving textures/raw models; existing portal boards receive cream shaded lettering only on successful hero construction; each hero pedestal receives a0.46x0.26x0.025m wood plaque at[0,.65,.227], inset against its measured front, with cream shaded smaller lettering0.0024pixel size and0.40mwrap width. Plaques add no colliders; slot positions, approach markers, portal state/actions, prompts, keep-clear envelopes and production behavior stay unchanged. Original fallback label behavior retained. All five candidatesOFF.

JSON and scoped whitespace checks pass. New material/signage source has NOT been parsed/imported/rendered after Turn38; no GPU authority afterEND. Independent bounded CPU source review requested. The6.533333 verdict belongs ONLY to5a70047a33, not this successor. The new palette/labels, physical plaque contact and readability need the next direct fixed-camera proof. Remaining portal/opening joins and daylight still require game work informed by that proof; no claim they were solved. Full-world attempt remains failed, zero frames, no retry or resource/profile tooling. F17#6 stays the active unfinished criterion; no F38 advancement or visual activation.

Independent source reviewer tidewake30_blind1: bounded PASS, no confirmed actionable defect. Verified local material duplication, four GLB Material_0 declarations, candidate/fallback isolation, 0.2395m plaque front and0.2455m text plane (6mm separation), and text width within plaque. Native imported material matching/root hierarchy, actual plaque contact and readable lettering remain unverified. No native operations afterTurn38END.


### Look turn42 - fresh warm stone/plaque comparison, 15 Oct 10:48-10:54 CT

Root granted existing reviewed4a1667b375 candidate proof only, with no fullworld allocation retry. F17#6 OPEN; zero closures. Actual parser command on4a1667b375cb7c71ac2217eb401400d954f73593: `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe --headless --path D:/tetherbound/restart-look --check-only --script res://scripts/world/crossing_hall.gd --log-file D:/tetherbound/restart-look/.artifacts/look42-parser.log`. PID61400,10:48:23-10:48:26CT, naturalexit0. No import/newmodel work needed.

To isolate this material/signage revision, BOTH arms retain the previously judged hero assets/composition. Fresh baseline7bdb283d1bb3e4a52ee22fd7e8d8e4ea55b8ecaa uses the prior5a70047a33 hero config (diagnosticON, no new retints/plaques) with the current unchanged reviewed game script. Empty optional retint/plaque settings preserve the previous presentation. Fresh candidate d38fa73103618fbaf1b5cfc2c8907595908e7775 restores4a1667b375 config with only heroenabled diagnosticON. The other four gates remainOFF; unchanged frame-waymark arm selects them process-locally in both sides. Thus this panel measures warm stone/plaques versus prior hero treatment, not the larger earlier hero-versus-legacy change. No historical cross-panel gain inference.

Actual common capture argv, same executable above and APPDATA=D:/tetherbound/restart-look/.artifacts/f17-direct/user: `--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --fullscreen --log-file D:/tetherbound/restart-look/.artifacts/look42-RUN.log --script res://tools/visual_judge/capture_camera_set.gd -- --preset=PRESET --set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json --hall-only-ground-y=0 --hall-arm=frame-waymark --out=D:/tetherbound/restart-look/.artifacts/look42-RUN`. RUN/PRESET literal substitutions follow. Ordinary graphics preference matched each preset. Actual log renderer: Forward+ Vulkan GTX1060 3GB. Existing120s child bounds unchanged.

| RUN | PRESET | source | CT interval | PID | actual result |
|---|---|---|---|---|---|
|medium-base|Medium|7bdb283d1b|10:49:19-10:50:19|37872|naturalexit0,13PNGs|
|high-base|High|7bdb283d1b|10:50:43-10:51:23|49344|naturalexit0,13PNGs|
|medium-warm|Medium|d38fa73103|10:52:10-10:52:49|33424|naturalexit0,13PNGs|
|high-warm|High|d38fa73103|10:53:26-10:54:06|59868|naturalexit0,13PNGs|

All52 native PNGs verified1920x1080; parser/four capture logs contain no ERROR/WARNING/SCRIPT ERROR lines. Actual shrine images show changed material tint and mounted plaques; acceptance belongs to the blind verdict, not this observation. No capture script edits, new harnesses, stage/source gates, profiling or fullworld retry. No state/clearance test could establish ordinary-world coverage without the failed fullworld route; none claimed. Previous fullworld allocation failure remains preserved, not relabelled as a clean run.

Restored exact all-five-OFF4a1667b375 config, committed/pushed7412b805451bcc650135653ea69b20b40d9c12ec. Actual Win32_Process census at10:54:48CT returned no Godot/Blender. ExplicitTurn42END and yieldFights43 occurred BEFORE CPU judges. No further native calls. Dfree23.73GiB before captures; outputs/archives stay below2GiB incremental, no deliberate C payloads/deletions.

Preserved original frames/logs in direct-look/turn42-{medium-base,high-base,medium-warm,high-warm}.zip; eight paired sheets plus parser log in turn42-neutral-sheets.zip. Existing tools/sheet.py used, no new tool. All65 archive entries verified against their included SHA256SUMS.txt. Full native files and neutral copies remain .artifacts/look42-* on D. Mapping withheld from judges: A=warm candidate, B=prior hero baseline, consistent across presets. Three fresh independent code-blind same-panel verdicts pending.


### Turn42 final blind verdict and next OFF daylight revision

All three independent code-blind judges inspected all eight neutral sheets (all52 frames), selected full-size originals, and the same references/written target. No source, side mapping or other verdicts supplied. Each assigned identical Medium/High scores because the actual pairs did not support a meaningful preset distinction.

| Judge | A warm candidate Bar A | B prior hero Bar A | A/B Bar B | Preference |
|---|---:|---:|---:|---|
|meadows22_blind_1|6.9|6.6|5.8/5.8|A|
|meadows22_blind_2|6.7|6.4|5.5/5.5|A|
|hall34_blind3|6.9|6.6|5.2/5.2|A|

BOTH presets: candidate Bar A mean6.833333/spread0.20; baseline mean6.533333/spread0.20; same-fresh-panel gain0.30. Bar B5.50/spread0.60 on both sides. No7.5 pass. This is one under0.5 round after turn38's same-panel+0.60; no historical cross-panel subtraction used. No criteria closed, activation or landing. Scores apply to d38fa73103 only, not subsequent unrendered game edits.

All prefer warmer stone coherence and more readable mounted plaques/portal lettering. Tradeoff: prior pale pedestals and end-wall inset separated more strongly, especially at night. Unanimous top defect is flat daylight: many opaque-looking pale windows have little visible relationship to floor/beam lighting; rain remains a grey veil, night peripheral/shrine wall wash competes with the emblem. Repeated outlined stone/grain/window grids and a small distant civic table still dominate composition. Duplicate Sealed signs, dense distant text and a Cloudreach word break remain; the home arch has nested opening shapes, and the adjacent sealed masonry panel still presents an unresolved join from the shrine. Still images do not establish collision obstruction. Judges recommend existing lighting/scene/material/signage work, not another hero asset. Creature, motion, ordinary Village/world/state/clearance coverage remains UNPROVEN.

Expected next player-visible result stated BEFORE edit: the two existing west window lights create more directed illumination across the aisle and civic table, revealing floor and beam depth without lifting whole-room ambient or changing night. Implemented CPU-only config revision under existing OFF hall_waymark: energy1.8->3.6; half-angle42->24degrees; originsX-6.75->-6.48 withY4.85/Z0,12 unchanged. Targets, range13m, two-light count, existing shadows, ambient0.65 and clock-driven nightOFF stay unchanged. No script, harness, shader, asset or native changes.

Source geometry supports aperture placement: installed Window_Wide_Flat1 trim localZmax0.416857 at wallX-7/yaw90 gives room-side boundX-6.583143; new sourceX-6.48 is0.103143m inside that bound. GlassY interval3.12+[1.097139,2.355356] has midpoint4.846248m, matchingY4.85. These are CPU source measurements, not native occlusion proof. A direct source-triangle centre-ray check did NOT find a blocked old ray, so no shadow-blockage diagnosis is claimed. The revision is a judged lighting-response hypothesis, not a proven fix. JSON and scoped whitespace checks pass; allfive candidate flags remainOFF, ambient/night config and light count verified unchanged. Native appearance, window material relationship, rain/readability and any improvement require next granted Look46 comparison. No GPU activity afterTurn42END.

Independent CPU review tidewake30_blind1: bounded PASS, no actionable config defect. Verified defaultOFF creates neither window spot; enabled builder consumes new values, both targets within13m range, clock hides/zeros lights at night. Light count/shadows/targets/ambient/night logic unchanged. Native unobstructed lighting/depth/improvement remains unverified. Dfree23.10GiB after evidence packaging, above20GiB floor.


### Look turn46 - focused daylight proof, 15 Oct 12:03-12:08 CT

Root granted existing reviewed daylightc850435f0b proof with prior warm treatment as control and the explicit two-flat-round stop. F17#6OPEN, zero closures. Fresh baseline403e9117bd73cf670f4e503224c959ae169d8bdb restores the warm stone/plaque config from7412b80545 with diagnostic heroON. Fresh candidatec9a458e7834324fa68b965777339147bb238b914 usesc850435f0b daylight config with diagnostic heroON. Other four production flagsOFF in both, selected process-locally by unchanged frame-waymark. Same current game script and assets. Only daylight recipe differs: existing two spots energy1.8->3.6, angle42->24, X-6.75->-6.48; targets/range/count/ambient/night unchanged. No parser rerun needed for a config-only change; no new assets/imports.

Actual executable `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe`, APPDATA=D:/tetherbound/restart-look/.artifacts/f17-direct/user. Actual common argv: `--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --fullscreen --log-file D:/tetherbound/restart-look/.artifacts/look46-RUN.log --script res://tools/visual_judge/capture_camera_set.gd -- --preset=PRESET --set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json --hall-only-ground-y=0 --hall-arm=frame-waymark --out=D:/tetherbound/restart-look/.artifacts/look46-RUN`. RUN/PRESET literal substitutions follow. Ordinary graphics preference matched each preset. Logs confirm Forward+ Vulkan GTX1060 3GB; unchanged120s bounds.

| RUN | PRESET | source | CT interval | PID | actual result |
|---|---|---|---|---|---|
|medium-base|Medium|403e9117bd|12:03:18-12:04:17|15144|naturalexit0,13PNGs|
|high-base|High|403e9117bd|12:04:35-12:05:15|65312|naturalexit0,13PNGs|
|medium-daylight|Medium|c9a458e783|12:06:25-12:07:04|53928|naturalexit0,13PNGs|
|high-daylight|High|c9a458e783|12:07:35-12:08:15|48976|naturalexit0,13PNGs|

All52 native PNGs verified1920x1080. All four logs contain noERROR/WARNING/SCRIPT ERROR lines. No retries. Captures are valid isolated presentation comparisons, not whole-world/earned-state/clearance/motion acceptance. No fullworld allocation rerun, profiling, new tools, capture edits, staging or source gates. The preserved frame-waymark arm selects the current game daylight configuration; no fixed frame-window-lit override was used.

Restored exact all-five-OFFc850435f0b config, committed/pushed330f76cd179f3052a8e550c2c953eae0396d3d0a. Actual Win32_Process census returned no Godot/Blender at12:08:47CT. ExplicitTurn46END and yieldFights47 occurred BEFORECPU judging. No native calls afterEND.

Original frame/log archives: direct-look/turn46-{medium-base,high-base,medium-daylight,high-daylight}.zip. Eight neutral sheets from existing tools/sheet.py: turn46-neutral-sheets.zip. All64 archive entries verified against includedSHA256SUMS.txt. Native originals and neutral copies remain .artifacts/look46-* onD. Example original Medium nave-forward_day_clear SHA256: baselinecb844404e84136dc58a9e92ba1d26de78c99cb13ffb822d21409e5e01674263c; candidate14d2728483e3107b0271c31733f06cea34600214dea81245bd65203b371eb889. Dfree22.39GiB after packaging, above20GiBfloor and within2GiBincrement including pendingGit copies; no deliberateCpayload writes/deletions. Blind mapping withheld: A=priorwarmcontrol,B=focuseddaylightcandidate, bothpresets. Three same-panel independent verdicts pending. No historical cross-panel gain inference.


### Turn46 final verdict - approach PARKED, F17#6 OPEN

All three independent code-blind judges inspected all eight sheets covering52 native frames and selected full-resolution originals, with the same references/written target and without source, mapping or other verdicts. Each returned a tie on both presets: no meaningful visible benefit from the daylight revision.

| Judge | A warm control Bar A | B daylight candidate Bar A | A/B Bar B | Preference |
|---|---:|---:|---:|---|
|meadows22_blind_1|6.9|6.9|5.8/5.8|tie|
|meadows22_blind_2|6.7|6.7|5.5/5.5|tie|
|hall34_blind3|6.9|6.9|5.2/5.2|tie|

For BOTH Medium and High: Amean6.833333/spread0.20; Bmean6.833333/spread0.20; within-panelgain0.00. Bar Bmean5.50/spread0.60, tied. No7.5 pass. This is the second consecutive under0.5 same-panel gain afterturn42+0.30. Under explicitTurn46direction, STOP the unchanged small material/lighting approach. No further energy/cone/colour tweak loop. No historical cross-panel score subtraction.

Disposition: park F17#6's current approach OPEN and unaccepted at the prior warm stone/mounted-plaque treatment. Restored its exact all-five-OFF config from7412b80545; the unhelpful focused-daylight hypothesis remains preserved atc850435f0b/c9a458e783 and in allturn46 evidence, but is no longer the prepared defaultOFF candidate. This is a real art-round park, not completion, activation, landing or a lowered bar. Zero whole criteria closed. No GPU activity since12:08:47END.

Actual unresolved gaps, shared across judges: (1) pale windows do not produce convincing daylight direction or beam/floor depth; broad night shrine/side-wall washes compete with the civic focal area; (2) outlined stone paving/walls, striped posts and repeated window grids dominate sparse furnishings, and the small table under the emblem is a weak destination; (3) shrine stations lack a composed ceremonial floor/grouping, Cloudreach can split within the word, Sealed appears twice, and the shrine-side masonry join plus nested home opening remain visibly awkward. Still images establish visual defects, not collision obstruction. Judges see no demonstrated need for another hero asset. A future F17 art return must be a clearly different scene-composition/architectural integration approach using these findings, not more small light/material tweaks; its proof must again use fresh matched cameras and independent judges.

Required acceptance still missing: complete ordinary Village/Hall Medium/High/Low coverage and representative motion, creature accommodation, actual state/door/relic and physical clearance evidence. The preserved whole-world attempt failed on allocation errors with zeroframes; repeating it or building profiling/capture infrastructure was explicitly prohibited and was not attempted. Full criterion acceptance requires a supported ordinary-world proof that actually completes, independent visual acceptance at7.5 and landing. Isolated6.833333 cannot substitute. Fixed remaining Lookqueue is unchanged; no F38 closure/implementation claimed in this turn. Root receives this explicit park and actual gaps for next scope/disposition.


### Post-turn46 CPU scope - different architectural integration approach (before edit)

Root accepted the two-flat small-material/lighting park and explicitly directed ONE different composition/architectural approach using preserved assets, CPU only untilLook50. Selected F17#6 defect: the dark sealed panel/surround visually projects across the shrine entrance in every recent blind panel. Expected visible change: a clearly open nave-to-shrine threshold, with adjacent sealed portals belonging to solid wall bays rather than overlapping the room entrance. This changes authored placement, not light energy, colour, materials or new hero assets.

Source evidence: shrine wall opening atX7 spansZ[-3,+3]; current3.2m-wide surrounds centeredZ-3/+3 extend to-1.4/+1.4 inside that sightline. Candidate moves ONLY sealed biome7 slot from[5.9,.15,-3] to[5.9,.15,-4.8], and sealed biome8 from[5.9,.15,3] to[5.9,.15,9]. First surround then endsZ-3.2,0.2m outside opening; second beginsZ7.4. Existing biome6 atZ-9 remains. Move existing WallBenchR1 fromZ-6 to-12.7 and WallBenchR2 fromZ6.5 to5.3, bothX6.5/Y.06. Installed Bench.gltf half-length1.388341m gives spans[-14.088341,-11.311659] and[3.911659,6.688341], leaving about0.71m to the neighboring portal frames and0.91m to the front wall/shrine edge. No bench scaling, removal or new collider type; existing collider/keep-clear construction follows the moved holders. These are CPU bounds, not native clearance proof.

Contract WORLD2.6 declares Hall layout world-scope. Candidate scope must therefore explicitly include these authored slot/bench moves and require identical host/guest configuration, not claim purely device-local presentation. IDs/order, home/live-capable/fifth-stirred slots, state records, save schema, actions and transactions remain unchanged. Move each entire sealed slot so Surround/Plaque/BiomeSign/StateSign/PortalSurface/LockedDoor/Approach/PortalAction remain together. Existing session.gd and foundation_travel_lifecycle.gd derive authoritative arch positions from hall.arch(id).global_position; policy uses those positions. No net code change needed, but host/guest layout proof is required. Feature remainsOFF and cannot close on source review.

Existing proof path: next authorizedLook50 uses changed Hall Godotcheck-only, then unchanged capture_camera_set.gd/frame-waymark and contact-v2 fresh matched Medium/High13-view pairs with hero candidate selected only at pushed preview source, followed by three blind judges. Inspect nave-arches-right and shrine forward/reverse for actual doorway presentation. Existing smoke_crossing_hall_circuit.gd and smoke_net_crossing_hall_agreement.gd remain the relevant physical/layout-agreement proofs, pending a supported bounded ordinary-world route; do not repeat the allocation-failed fullworld run or build new tools. Full Village/world/state/clearance/motion coverage remains unproved. All production flagsOFF throughout CPU work.


Implementation result: added the bounded shrine_portal_layout config under the existing OFF hero candidate and consumed it in the game slot/furnishing builders. Whole sealed slots and bench holders move; missing overrides retain existing positions. Existing layout validation accepts only biome7/biome8 and WallBenchR1/WallBenchR2 with valid finite positions. No capture script, material, light, asset, save or network code changes. All five production candidate flags remainOFF.

Independent CPU review tidewake30_blind1: bounded source PASS, no actionable defect. Checked whole-slot input alignment, shared bench mesh/collider/keep-clear transforms, hero/furnishing gating, fallback positions and actual-position session policy. JSON parse, exact override scope and scoped git diff --check pass. This is not an engine parse or native proof: Godot was not launched during this CPU block. Actual visual composition, physical access and host/guest matching remain unverified. Next action is the preserved matched comparison on the next explicit native grant; no further material-lighting tuning and no allocation-failed fullworld retry. Zero criteria closed; F17#6 remains OPEN, candidateOFF, completion objective retained.


### Look turn50 - shrine threshold architectural proof, 15 Oct 12:52-12:57 CT

Root granted the distinct architectural approach at21928db70c, no further lighting tuning or failed fullworld retry. Existing Godot check-only for res://scripts/world/crossing_hall.gd passed at PID31180, naturalexit0, log .artifacts/look50-check.log containing only engine header. Actual command: Godot executable below with --path D:/tetherbound/restart-look --headless --check-only --script res://scripts/world/crossing_hall.gd --log-file D:/tetherbound/restart-look/.artifacts/look50-check.log. No new parser/tool.

Control93bd22daef7848355e6f4d516c55f8b519ddfb90 selects priorwarm ba015276ae Hall config with heroON. Candidateb33bc89b996182e47a5d2dc87b469455f9c833de selects21928db70c architectural config with heroON. Same current script/assets and unchanged capture script; other four production flagsOFF in both, selected process-locally by frame-waymark. JSON serialization expanded formatting in temporary preview commits; restored exact21928 config afterward. No actual material/light values changed between the two arms.

Executable C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64.exe; APPDATA=D:/tetherbound/restart-look/.artifacts/f17-direct/user. Actual common argv: `--path D:/tetherbound/restart-look --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --fullscreen --log-file D:/tetherbound/restart-look/.artifacts/look50-RUN.log --script res://tools/visual_judge/capture_camera_set.gd -- --preset=PRESET --set=res://tools/visual_judge/camera_sets/F17-6-isolated-contact-v2.json --hall-only-ground-y=0 --hall-arm=frame-waymark --out=D:/tetherbound/restart-look/.artifacts/look50-RUN`. Ordinary graphics preference matched PRESET. Exact substitutions and actual times:

| RUN | PRESET | source | CT interval | PID | result |
|---|---|---|---|---|---|
|medium-base|Medium|93bd22daef|12:52:51-12:53:46|43620|naturalexit0,13PNGs|
|high-base|High|93bd22daef|12:54:00-12:54:40|51492|naturalexit0,13PNGs|
|medium-layout|Medium|b33bc89b99|12:55:31-12:56:10|26340|naturalexit0,13PNGs|
|high-layout|High|b33bc89b99|12:56:35-12:57:14|55672|naturalexit0,13PNGs|

All52 originals valid1920x1080, all four logs without ERROR/WARNING/SCRIPT ERROR. Each child stayed inside unchanged120s bound; zero retries. Restored exact all-five-OFF21928db70c config at pushed1e45feb5e3e890c6680270c273fac246a137cdfc. Actual Win32_Process census EMPTY forGodot/Blender at12:57:49CT. ExplicitTurn50END/yieldFights51 BEFORE CPU judges. No native work afterEND. Dfree21.73GiB then, starting22.05; later archives about0.17GiB plus Git copies remain within2GiBincrement/20GiBfloor. No deliberate largeCwrites.

All nativeimages/logs preserved .artifacts/look50-{medium,high}-{base,layout}; four matching direct-look/turn50-*.zip archives plus turn50-neutral-sheets.zip preserve64 verified payload entries and SHA256SUMS.txt. Eight neutral sheets use existing tools/sheet.py; fullresolution neutralcopies in .artifacts/look50-neutral. Mapping withheld from judges: A=architecturalcandidate,B=priorwarmcontrol, bothpresets. Materialized six exact tracked docs/reference keyart/Palworld images by normal Git restore for actual reference review. No new capture tools or stage access.

Medium nave-arches-right_day_clear SHA256: control3ef1b8b2383cb483503735035a738502d51922101dfc38e9eb60239fca22d901; candidateeff72425d8ceed42b412443e9e1ee407c213416401359f4369aff70a252587b9. Medium logs bothfe0369ee2f2bc9c602a109f400fa98004292c7bb0e3a10692e49ecdb36ab52cf; High logs botha2abbaf5a995cf5015a1bdcbd0c0ff209c3eae5a34bab24fd3c05af47454e2db. Identical text logs are expected; images differ.

Physical smoke_crossing_hall_circuit inherits real-world instantiation and shell wait from smoke_village_hall_redesign; smoke_net_crossing_hall_agreement starts two actual production worlds and reload. Neither supplies a supported isolated bounded alternative to the allocation-failed fullworld route. Both remain UNRUN under explicit no-repeat direction. No actual clearance/hostguest/world/state/motion acceptance inferred from pictures. Fresh three-judge verdict pending; F17#6OPEN, zero criteria closed, candidateOFF.


### Turn50 three-judge result and next game correction

All three fresh code-blind verdicts inspected all eight sheets/52 images, selected fullresolution originals, actual tracked Meadows keyart and all five Palworld references. A=architecturalcandidate; B=priorwarmcontrol. All three preferA modestly; all fail7.5. BothMedium/High Bar A: hall34_blind3 A7.1/B6.9; meadows22_blind_2 A6.9/B6.7; hall50_blind3 A6.2/B5.9. Amean6.733333/spread0.90; Bmean6.500000/spread1.00; same-panelgain0.233333. No historical cross-panel subtraction. Medium Bar B A/Bmean5.50/spread0.60; High A/Bmean5.533333/spread0.70 (judge3High5.9 vsMedium5.8; otherjudges5.5/5.2). No lighting advantage. This is the first under0.5 round of the distinct architectural approach; prior material/energy approach stays parked.

Actual improvement: all judges identify a cleaner shrine opening and clearer nave/shrine relationship. This is visual composition only, not physical clearance. Retain architectural candidateOFF. Shared remaining gaps: weak window-directed daylight, sparse civic grouping and busy shrine stone pattern, duplicate Sealed signs; two judges again identify the mid-word Cloudreach break. No new hero asset requested. F17#6 remainsOPEN; zero closures; no activation/landing, access/net/fullmatrix/motion still unrun.

CPU follow-up scope BEFORE edit: one coherent plaque-legibility correction under existingOFF hero candidate. Expected visible result: sealed arches display one centered Sealed line instead of duplicate headings; shrine names remain whole on their mounted plaques rather than splitting Cloudreach. Preserve actual biome/state label nodes and exact name/state strings, live arch advice, interactions and every slot/collider position. Consolidate only identical sealed hero labels by suppressing the duplicate BiomeSign while keeping StateSign visible/centered; fit hero pedestal name font to its existing configured width using the actual font measurement, without expanding plaques or clipping text. No light/material/worldlayout/capture changes. Next direct proof on explicitLook54: changedgameparse then existing fixed pairedM/H images and three judges; existing physical/netproof requirements remain outstanding. This edit is unrendered and cannot inheritturn50scores.


Source-review correction: tidewake30_blind1 found the proposed duplicate-label suppression conflicts with the existing agreement witness, which records BiomeSign visibility in tests/helpers/hall_agreement_net_peer.gd:181 and requires it in smoke_net_crossing_hall_agreement.gd:119. Removed that entire suppression and its option before commit. Neither witness nor any test was changed; all existing portal labels remain exactly as before. Duplicate Sealed stays an open visual defect. Resolving it requires a semantically correct combined-sign design with the corresponding actual existing agreement proof, not hiding a required label or weakening its assertion.

FINAL CPU implementation is ONLY hero pedestal whole-name fitting: one config option and six game lines, no portal/state/layout/material/light/capture changes beyond the already preserved architectural candidate. Independent review passed this font-measure/fit path; the offending portal branch is absent. JSON/whitespace checks pass, all five flagsOFF. No native parse or rendering of this follow-up becauseTurn50 alreadyENDED; exact font fit/readability unverified until explicit next grant. Dfree21.41GiB after required capture archives/Git, totalturnincrement about0.64GiB. Completion objective retained, F17#6OPEN, zero closures. Next proof compares this final signage candidate with the turn50 architectural source, then required complete proofs before any activation or landing.
