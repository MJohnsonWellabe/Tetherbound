# Code-blind judge — Tidewake current change (F14#2), round 2

Inputs: 4 frames (S1, X/Y, t0 and t0+0.5 s), LABELS.txt. No source read.

## 1. Is a current visible?
- **Y: yes, clearly.** A broad band of white streaks and foam flecks runs from the far-left shore, past the central creatures, to the lower right, with a thinner arm reaching the right-hand sandbar. Streaks and foam flecks shift between t0 and t0+0.5 s (pixel difference inside the band is about 2x the X band, ~1,200 pixels changing strongly vs 0 in X), so it reads as flowing water.
- **X: barely.** About 6–8 thin, sparse white lines follow the same diagonal path, with no foam. Between t0 and t0+0.5 s they appear static (band difference is lower than ordinary ripple noise in open water). A player would read them as faint glints or wake lines, not as a current.

## 2. Do X and Y differ?
Yes, obviously, at normal viewing distance. **X is the calmer state.** Same direction and path, far fewer and fainter streaks, no foam, no visible motion. Confidence: high.

## 3. Non-water differences
- Cloud layout differs slightly between states (the sky moves over time; not a problem).
- Central creatures' pose/position shift slightly. No UI or lighting difference.

## Overall
A player who saw both states would notice the current changed. **PASS** (calmer = X, high confidence).

## Remaining fixes (minor)
- In X the leftover lines are frozen and look like rendering artefacts. Either give them a slow drift so the sea reads as "calmed current", or fade them out completely.
- In Y the band has hard straight edges and uniform ruler-straight streaks. Break up the edge with foam density falloff and slight curvature around the islands so it reads as water, not a painted stripe.
- Y's streaks overlap the creatures without any interaction (no foam at their bodies). Optional polish.

---
Provenance (VIS, added after the judge returned). The frames are Tidewake-B's `ralph/reports/TIDEWAKE/b/f14_2_visible_current/S1_{live,restored}_t{0,1}.jpg` at `tb/tidewake-b` `b0ce38fc`, relabelled. The hidden mapping is **X = restored (after), Y = live (before)**, and the judge's call (X calmer, high confidence) is correct.

This is the second, independent code-blind judgement; Tidewake-B's own was the first.

Disclosed shortcuts and limits:
- one stand at 1280×720;
- t1 is +0.5 s (vis_time 100.50);
- the flag is set directly;
- the shader clock is pinned;
- the CameraRig is disabled and the Camera3D placed at the pose (a deviation from V-TW-1's "production CameraRig");
- the trainer and HUD are hidden;
- software GL.
