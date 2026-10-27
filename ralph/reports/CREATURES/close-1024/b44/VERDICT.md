# b44: CLOSE-OUT per-species faint recipes (CPU, three judges)

Candidate 562c38f5 (`f36_pose_postpass.py --close-out-faint`; only the faint role spliced into the live recipes). Torrentoad moved from the belly-down prone faint to the +90 side topple; Brooktail and Tanglevolt joined the +90 topple. Riverdrake's prone was dropped before judging (CPU frames: head up, a low crouch). Sheet `_sheet_b44.jpg`: base | candidate, rows Torrentoad, Brooktail, Tanglevolt.

Anchors: p2_094_r4, f04_6_r22, f36_0_gap:C6. Fit: slope 1.15, r 0.79, RMSE 0.72. Not a confirming batch.

| species | base (mapped) | candidate (mapped) | faint end does not read as down |
|---|---|---|---|
| Torrentoad | 6.20 | 6.28 | base PRESENT x3 (upright crouch); candidate PRESENT x3 (read as a belly-up flip, limbs up) |
| Tanglevolt | **7.84** | 7.58 | FIXED/PARTIAL on both; base slightly preferred |
| Brooktail | 6.89 | 6.97 | base FIXED, PARTIAL, PARTIAL; candidate PARTIAL, FIXED, FIXED |

Call: no change gains 0.5; reverted (the next commit restores the live recipes and postpass). The side topple on Torrentoad's wide splayed body ends with the limbs in the air, and judges read that as the belly-up flip; its prone squat reads as standing. Neither stock faint style works for this body, so it needs a hand-shaped collapse (chest down, legs splayed flat, chin on the ground), not a style switch. Tanglevolt's faint already reads as down on CPU (7.84); its GPU "belly-up pale slab" read is a GPU lighting matter. Brooktail is a tie.

Burrowback and Mosshell faints are authored clips in their naturalistic remakes. Mosshell's was already redesigned after GPU H as a withdraw-into-shell, and Burrowback's as a back-to-camera roll. Re-authoring them needs a Blender re-export of the shipped GLB with no clear better pose, so they are not attempted (no expected gain over 0.5).
