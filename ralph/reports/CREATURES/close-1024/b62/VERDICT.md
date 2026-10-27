# b62: second near-bar tier vs main (CPU, three judges)

The coordinator assigned this tier on 27 Oct. On GPU F36#1 main-1024 the four species scored Cliffspike 7.03, Thundertunnel 6.91 and Voltwig 6.89 (recipe hit read as "a pounce more than a flinch") and Nightburrow 7.01 (F36#0, 3/3 judges: "stray vertical line above its back in faint mid and end").

Candidates:
- **f402a1ed6, grounded flinch.** The held shove is regenerated at gain 0.75 for Cliffspike, Thundertunnel and Voltwig. This is the b58 change.
- **c3a333014, the aspect flame goes out on faint.**
  - The line was Nightburrow's own aspect VFX. Its motes climb a column sized to the standing body, and its eye glows sit at standing head height.
  - `play_faint` now suspends that VFX and `revive_animation` restores it; remote proxies go through both calls.
  - The F36 capture's faint row does the same, because it plays the clip directly.

Tiles:
- Flinch species: standing, then hit at 025, 050 and 075.
- Nightburrow: standing, then faint at 050, 075 and 100.

Anchors: p2_094_r4, f36_0_gap:C3, f36_0_npc:C1. Fit: slope 1.28, r 0.93, RMSE 0.50, **confirming**.

| species | main (mapped) | candidate (mapped) | gain | recorded defect (main / candidate) |
|---|---|---|---|---|
| Cliffspike | 6.21 | **7.27** | **+1.06** | pounce PRESENT x3 / FIXED, FIXED, PARTIAL |
| Voltwig | 6.17 | **6.89** | **+0.72** | pounce PRESENT x3 / PARTIAL x3 |
| Nightburrow | 5.79 | **6.30** | **+0.51** | stray line PRESENT x3 / FIXED x3 |
| Thundertunnel | 6.21 | 6.30 | +0.09 | its hit never reared; the flinch "barely reads" on both sides |

Call:
- **GPU READY** for Cliffspike, Voltwig and Nightburrow.
- **Thundertunnel is dropped** from this round, and its profile is restored to main's. All three judges named its real defect as near-black values: no visible eyes, and it merges with the backdrop.
- **Bramblebun gets no change.** Its GPU defect was the land-species swim row, which main's capture no longer stages (1d435bbe8), so a fresh GPU capture shows whether it clears.
- **Pebbik is out.** Its recipe is keyed to `creature_pebbik_lod0.glb`, but it now ships `candidate_b4`, so the recipe is not enabled.

Remaining reads, not from these changes:
- Nightburrow's muddy dark plating hides the face.
- Voltwig still rears its chest on the first hit frame, and its yellow streaks read as near-emissive.
- Cliffspike's face is small.

Checks: `run_tests --only=f36_pose,creature_pose,aspect,creature_body,dual_type,remote_creature,faint,revive`: 64 tests, 0 failed.
