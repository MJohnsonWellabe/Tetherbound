# Code-blind judge — Tidewake current change (F14#2)

Inputs judged: 16 native frames, 4 contact sheets, LABELS.txt. Also 1000x400 full-res crops of the streak zone (x 900-1900, y 420-820) and a simple pixel check: streak coverage (pixels >20 luma above a 41-px row median) and t0->t1 correlation of high-passed water.

## Per stand

| Stand | Current visible in X? | Current visible in Y? | Moves t0->t1? | Calmer state | Obvious? |
|---|---|---|---|---|---|
| S1 | Yes: white diagonal streaks + foam blobs, upper-left to lower-right | Yes, same | Both: streak segments lengthen/fade in place; no rigid drift | **Can't call.** Coverage 0.75% vs 0.75%. X is denser far away (1.7% vs 1.2%) and Y denser near (0.56% vs 0.32%). Y changes a bit more in 1 s (corr 0.46 vs 0.62). | No |
| S2 | Yes | Yes | Both, slightly | **Can't call.** 0.56% vs 0.60%, corr 0.70 vs 0.67 | No |
| S3 | Yes | Yes | Both, slightly | **Can't call.** 0.55% vs 0.54%, corr 0.46 vs 0.49 | No |
| S4 (golden) | Yes | Yes | Both | **Can't call.** Y marginally busier (1.21% vs 1.03%, corr 0.32 vs 0.39), so X is weakly calmer | No, only on measurement |

X and Y differ in the water only in *where* the streaks sit, as if the same pattern were sampled at another phase or offset. Streak count, length, brightness (99.5th-pct high-pass amplitude 31-39 in both), foam amount and apparent speed are the same by eye at every stand. The measured leans point different ways at different stands (S1 and S4 lean X calmer; S2 and S3 are ties), so they are noise, not a state difference.

## Non-water differences (not the current change)
- S1: the rocky or shelled creature's pose/position shifts slightly between frames.
- S3: the dark long-bodied swimmer and the small blue creature beside it change pose and position (Y's pair sits left and lower).
- S4: the shelled creature's pose shifts.
- Cloud layer drifts slightly between t0 and t1 in all stands. Sun glint column in S4 is unchanged.
- Base wave normal ripple animates in both states (fine chop), which is equal.

## Overall
- Would a player notice the currents changed? **No.** Both states read as the same strong streaked current.
- Can I say which is calmer at every stand? **No.**
- **Verdict: FAIL.**

## Fixes that would make the change read
1. Make the calm state visibly calm. Cut streak opacity/coverage by at least ~60% (or remove the long streaks and keep only sparse, faint foam flecks), not just shift the streak phase.
2. Change scroll speed by a large ratio (for example 3x or more) between states, so the t0->t1 displacement differs visibly. At present neither state shows measurable rigid drift over 1 s, and streaks evolve in place.
3. Add a second cue that survives stills: the strong state gets foam piling at island edges and behind the swimmers, and the calm state gets glassier water (lower normal strength, a clearer sky reflection).
4. For judging motion, capture 3-4 frames 0.25 s apart, or a short clip. Streak drift is hard to see at a 1 s interval, because the pattern tiles and fades.

---
Provenance (VIS, added after the judge returned). Frames are from render.yml run 36312890159 at `tb/vis` `a54d2b29` (main `4316362e` plus `tools/vis_capture_current_restore.gd`). The X/Y mapping, hidden from the judge, is in `CAPTURE.md`: S1 X = before; S2, S3 and S4 X = after.

The judge could not identify the calmer state at any stand. On its numeric leans, S1 "X slightly calmer" is wrong (S1 X is before), while S4 "X slightly calmer" is right (S4 X is after). That confirms the change does not read.

Disclosed shortcuts:
- the flag is set and cleared at the same pose;
- the Salt Crown and Sluice Isle dock flags are set;
- the water shaders' clock is pinned (t0 = 100 s, t1 = 101 s);
- the rig is disabled and the camera placed at the stand eye;
- the trainer and HUD are hidden;
- frames are software GL (llvmpipe).

Tool finding for @Tidewake-B: a paused CameraRig (SpringArm3D) still pulls its Camera3D back to the arm end. So the `smoke_tidewake_b_current_restore.gd` `_capture` frames were probably not over the current.
