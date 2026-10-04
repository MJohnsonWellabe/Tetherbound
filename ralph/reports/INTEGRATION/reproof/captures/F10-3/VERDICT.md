# F10#3 — Readable lightning (1.2 s / 3 m) and phase cues without HUD

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1280x720
- Commands:
  - Phases: `xvfb-run ... --resolution 1280x720 --script tools/capture_stormwood_surge_phases.gd -- --out=<dir> --label=reproof --only=quick,night` → `DONE 8 frames, 0 failures` (phases/, phases_lines.txt)
  - Strike, normal: `... --script tools/vis_capture_strike_motion.gd -- --motion=normal --hours=12 --out=<dir> --label=seqN --only=quick` (relaunches itself as a `--fixed-fps 60` child; strike_child_cmds.txt) → `DONE 19 frames, 0 failures`
  - Strike, reduced: same with `--motion=reduced --label=seqR` → `DONE 19 frames, 0 failures`
  - Note: the strike tool wrote its PNGs to `res://shots/vis_f10_3_motion/<label>/` despite the absolute `--out` (only the JSON landed in `--out`); frames moved into strike_seqN/ and strike_seqR/ (JPG q90) and frames_<label>.json copied alongside.
- Tool data (frames_*.json): impact_sent true from t120; presentation.bolt_level 0.0 in every frame, flash_level 0.13 at seqN t120, 0.0 in all seqR frames.
- Replaces: ralph/reports/STORMWOOD/f10_3/r6/

## Code-blind judge (fresh agent; 8 phase stills + 2×19 strike frames, criterion, Stormwood bar, accessibility rules): FAIL

1. Telegraph: PASS. "a magenta ground ring is already up at t000. Crack lines grow inward from the rim from t010 to t090 ... bolt lands at t120 ... So the warning lasts 1.2 s, as required." Ring ≈ 750 px wide at the 170 px-tall trainer's depth → plausibly ~3 m radius. "a large forked white-violet bolt ... lights only the trainer and the ring." Defect: strike lands at the trainer's feet near the back edge of the ring, not its centre. No strike steam in t130–t170.
2. Phases without HUD: FAIL. "phase identity rests on rain density and small grade shifts." Building and Break close to indistinguishable; Calm vs Fading only side by side. quick_break/night_break lack white-violet contrast and sky lightning; quick_building/night_building lack copper/blue build-up; a bright white spot on a gold ground vein appears in Break but also in night_calm (strongest) and night_building, so it is not a phase cue; the night_* set reads the same as the quick_* set.
3. Reduced motion: warning fully readable, but "seqR looks the same as seqN; the bolt is not softened" — only rain-streak positions differ.
4. Photosensitivity: no whole-frame flash; largest bright area the ring at t110–t120 (~25–30% of frame); single dark→white bolt jump at t120 decaying by t140. Low hazard for a single strike; repeated strikes not shown.

## Verdict: FAIL
Top defects: Surge phases not distinguishable without HUD (no copper/blue Building, no white-violet Break); reduced-motion strike identical to normal (no softening).
