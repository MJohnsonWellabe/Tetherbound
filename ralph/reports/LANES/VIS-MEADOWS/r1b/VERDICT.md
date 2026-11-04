# VIS-MEADOWS r1b: Meadows catch, fight, inventory and flight items (CPU, 4 Nov 2026)

Same yardstick as r1a: CPU llvmpipe Compatibility 1280x720, base = 98879e2e (main at the time), candidate = the same tree with r1's 25 existing OFF arms on. Same stands. Base catch/fights/flight were re-captured after the candidate on the same clean tree, because their first base launches failed on the evidence-dir rule. tools/visual_judge: JUDGE_PROMPT verbatim, anchor_tiles `--pairs 3 --seed 11042`, three fresh code-blind judges in parallel, calibrate.py: linear slope 1.16, r 0.90, anchor RMSE 0.53.

| Item | Subject | CPU base | CPU cand | Verdict |
|---|---|---|---|---|
| F38#13 P2-059 | catch sequence camera framing | 6.22 | **7.19** | gain +0.97: camera jump FIXED 3/3 on the candidate, PRESENT 3/3 on base. Ship ON |
| F38#33 P2-061 | catch result hierarchy | 6.02 | **6.88** | gain +0.86: a clean "Caught Bramblebun!" card and cards stepping back. Ship ON |
| F38#15 P2-069 | flight and landing pose | 5.99 | **6.33** | gain +0.34: folded-wing perch on landing (FIXED 1, PARTIAL 2). Ship ON |
| F38#7 P2-058 | catch aim readability | 7.15 | 6.99 | -0.16 (noise; aim frames are not reached by the catch arms); above 6 as shipped |
| F38#6 P2-033 | ground pickup identity | 6.64 | 6.68 | flat; above 6 as shipped; item identity/potion arms stay OFF |
| F38#32 P2-035 | camp and workshop props | 6.37 | 6.45 | flat (+0.08); above 6 as shipped; flame stays OFF |
| F38#29 P2-065 | trainer defeated presentation | 6.18 | 6.18 | flat: the grunt slump and beaten stance never show (the frames show the grunt far off and upright); arms stay OFF |

Arms shipped ON:
- F38#13 + F38#33: `catching.json framed_camera.r2`, `camfx.json catch_orb`, `hud.json catch_card`.
- F38#15: `fly_traversal.json landing_presentation.wing_fold_enabled`.

Judges' remaining asks: the flight glide shows the bird hovering over the trainer's head rather than ridden. Pickups read oversized against the trainer, about half his height. Camp props crowd into one brown band, overlapping creatures and the trainer. The defeated grunt is a distant upright speck: the after-victory frame needs the grunt in view and slumped. The anchor Stormwood fight (an anchor, not scored here) was flagged for magenta telegraph rings.
