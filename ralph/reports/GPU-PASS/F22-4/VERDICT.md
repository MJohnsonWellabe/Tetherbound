# F22#4 Riverwatch r13: GPU confirmation, Low and Medium (22 Oct 2026, afternoon)

**Verdict: REOPENED on both presets.**
- **Low (Compatibility):** r13 maps **6.71** against control 5.11, a +1.60 gain.
- **Medium (Forward+):** r13 maps **5.85** against control 4.83, a +1.02 gain.
- Both are below 7.5.
- Compatibility comes close to the CPU result (7.03; the CPU renderer is Compatibility too).
- **Medium has a Forward+-only defect:** the captain's Brooktail renders washed-out, grey and semi-transparent, a "ghost" or "hologram" in all three judges' words. On Low the same frames show a solid brown otter with a readable face.

## What was run

- **Source:** tb/fights `765bf9d92` (the r13 overlay receipt), in a local detached worktree. Nothing was committed from it.
- **Control:** the tree as committed, with every candidate OFF.
- **r13:** `ralph/reports/FIGHTS/close-1022/cand_rw13.py.txt`, which chains r10 → r11 → r12 and then sets the tilt back to 0.
  - It changes 5 data files: the river-lock trainers, camera, combat, foliage_camera_visibility and trainer_aftermath. The applied diff is in `r13_overlay_applied.diff.txt`.
  - It was applied from Git Bash with an LF copy of `rw_r9.patch.txt`. This machine's `core.autocrlf=true` checks that `.txt` out with CRLF line endings, and `git apply` then refuses it.
- **Two discarded first attempts:** my first r13 attempt captured the control twice, once because the overlay folder was outside the sparse checkout and once because of the CRLF problem. Both were discarded; only the overlay-verified captures are judged.
- **Capture:** `tools/art_pipeline/capture_named_fight.gd --trainer=captain_riverwatch --live-member=captain_riverwatch:4 --ally=ripplet --frames=12 --interval=0.5 --tell-frames --keep-alive`, at 1280x720.
  - Low: Compatibility on OpenGL3. Medium: Forward+ on Vulkan. GTX 1060.
  - Each preset reads its own isolated `graphics_override.cfg`.
  - Exact commands are in `commands.txt`.
- **Frames per arm (23):** before, i01–i12, after, and three telegraphed attacks (start, mid, strike).

## Yardstick

**Batch:**
- `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`.
- Anchors: f36_0_npc C1, p2_094_r4, f04_6_r22 and f36_0_gap C5.
- Candidate pairs: r13 | control at Low, and r13 | control at Medium, with sides shuffled.
- Three fresh code-blind judges, each given `JUDGE_PROMPT.md` verbatim. The key was withheld until all three verdicts were in.
- Recorded defects (the Fights lane's three): boss size, flat magenta telegraphs, and no visible impact.

**Calibration:** 8 anchor points, linear fit, slope 0.854, intercept 2.040, r 0.85, anchor RMSE 0.64, no warnings, confirming batch (top anchor 7.53).

| Arm | Raw (j1/j2/j3) | Mapped per judge | **Mapped mean** |
|---|---|---|---|
| Low control | 3.6 / 3.4 / 3.8 | 5.11 / 4.94 / 5.28 | **5.11** |
| **Low r13** | 5.4 / 5.4 / 5.6 | 6.65 / 6.65 / 6.82 | **6.71** |
| Medium control | 3.2 / 3.2 / 3.4 | 4.77 / 4.77 / 4.94 | **4.83** |
| **Medium r13** | 4.4 / 4.6 / 4.4 | 5.80 / 5.97 / 5.80 | **5.85** |

**Recorded defects on r13, both presets:** boss size FIXED 3/3, magenta FIXED 3/3, impact FIXED 3/3. On control they are PRESENT or PARTIAL.

## What the judges saw

**r13 at both presets:**
- The otter reads as a boss over the small player creature.
- Telegraphs are cyan.
- Water splashes land on the strikes.

**Remaining asks on r13:**
- The telegraphs are still flat translucent wedges and discs, not a water object.
- The camera is too close: the otter is cropped at the frame edge, and i08 is occluded by the boss's body.
- The HUD covers the lower third.
- The grade is a one-note yellow-green (Low) or murky dark (Medium).

**Medium only:** Brooktail renders grey and semi-transparent through almost every frame, with the forest visible through its body. All three judges named it the biggest loss.

## Forward+ ghost boss: what was checked

- **Visible on screen:** `_sheet_f22_4_r13.png` puts Low and Medium side by side for control and r13.
- **Not the line-of-sight fade:** r13's overlay enables `foliage_camera_visibility.line_of_sight_fade` for `playground`. I captured Medium r13 again with that one change reverted, and Brooktail is just as ghostly (`Medium-r13-nolosfade`, kept locally).
- **Still open, for the Fights lane:**
  - the rigged Meshy captain's material on Forward+, its transparency or depth-draw path and the "hero material correction";
  - an effect surface drawn in front of the boss on Forward+, such as the water wall or fan sheets at reduced opacity;
  - the Forward+ grade (`forward-plus-grade/`) on top of either of those.
- **Suggested check:** a Medium capture with the water wall/fan cues disabled, plus a single-material swap on the captain.

## Files

- `_sheet_f22_4_r13.png`: control and r13 at Low and Medium, frames i04, i06, tell2 mid and tell3 strike.
- `commands.txt`: exact capture command lines.
- `r13_overlay_applied.diff.txt`: the data changes the overlay made.
- `yardstick/`:
  - `key.json`, `candidates.json`, `sets.md`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1.json`–`j3.json`: the judges' final JSON blocks;
  - `batch.json`, `mapped.json`: calibrate output.
- Per-frame captures stay local and are not committed.
