# b59: Mosshell on-back faint vs main (CPU, three judges)

This is a near-bar close-out (coordinator, 27 Oct). On GPU F36 main-1024, Mosshell scored 7.36 and water_mosshell 7.41. Three of three judges said the withdraw faint "barely differs from standing".
- Candidate 3899595e9 changes one thing: the faint rolls the turtle through a side lie, carapace toward the stage camera, onto its back. The legs go slack and the head lolls.
  - It is set by `FAINT_ON_BACK` and `FAINT_BACK_ROLL` -170 in `author_native_clips.py`.
  - The clip is re-authored into the shipped GLB, and only the faint clip changed.
  - water_mosshell uses the same model.
- A +170 roll was tried first. Mid-faint it showed the plastron and limbs to the camera, so it was dropped before judging.

Tiles: standing, faint 050 / 075 / 100. Sheet `_sheet_b59.jpg`: main | candidate, Mosshell. The water_mosshell frames are the same picture.

Anchors: f36_0_npc:C2, f36_0_gap:C3, p2_094_r4. Fit: slope 1.74, r 0.96, RMSE 0.35. **Not a confirming batch** (the top anchor reference is 7.07).

| species | main (mapped) | on-back faint (mapped) | gain | faint barely differs from standing (main / candidate) |
|---|---|---|---|---|
| Mosshell | 6.00 | **7.21** | **+1.21** | PRESENT x3 / FIXED, PARTIAL, FIXED |
| water_mosshell | 6.00 | **7.21** | **+1.21** | PRESENT x3 / FIXED, PARTIAL, FIXED |

Call: **GPU READY**. All six judge-set preferences favour the candidate.

Risk: GPU judges penalised Stormcapra's belly-up faint (CO8). For a shelled turtle, ending upside down is the canonical knockout, and all three CPU judges read it as knocked out. One judge called the end pose "comic rather than grounded".

Remaining reads, not from this change:
- The turtle stands low; the shell top is only about the ruler's head height.
- Olive-on-olive values give little rim separation.
- The face is small.

Checks: `run_tests --only=f36_pose,creature_pose,rest_pose,water,creature_body,mosshell`: 546 tests, 0 failed.
