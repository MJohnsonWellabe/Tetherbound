# b1 (23 Oct 2026, CPU llvmpipe Compatibility/Low): naturalistic pilots vs live

Stage: `capture_f36_poses.gd --whole-body --context` (live = shipping state: Terrapup on its enabled recipe; Bramblebun and Riverdrake on installed clips; pilot = candidate_nat1022 bound, own clips). Sides: standing, hit react, hit recover, faint mid, faint end.
Standard prompt verbatim, three fresh code-blind judges, anchors f36_0_gap:C3, p2_094_r4, f36_0_npc:C1 (3 pairs, confirming batch).
Fit: linear, slope 1.421, intercept -2.183, r 0.938, anchor RMSE 0.478. Warning: Terrapup and Bramblebun pass only above the top anchor (7.53); this batch's anchors reach 7.35+, so it is the confirming batch.

| Set | Live raw (j1/j2/j3) | Pilot raw | Live mapped | **Pilot mapped** |
|---|---|---|---|---|
| Terrapup (Ee) | 5.4/5.4/5.0 | 6.9/6.9/6.9 | 5.30 | **7.62** (above top anchor, confirming) |
| Bramblebun (Eh) | 5.0/4.8/4.5 | 6.8/7.0/6.8 | 4.59 | **7.57** (above top anchor, confirming) |
| Riverdrake (Sk) | 5.2/4.9/4.6 | 6.6/6.9/6.5 | 4.78 | **7.29** |

Defects on the pilots: style FIXED x3 on all three. Hit: Terrapup PARTIAL/FIXED/FIXED, Bramblebun PARTIAL/FIXED/FIXED, Riverdrake PARTIAL/FIXED/FIXED. Faint: Terrapup FIXED/PARTIAL/FIXED, Bramblebun PARTIAL/FIXED/FIXED, Riverdrake PARTIAL/FIXED/PARTIAL (pale underside shows; reads close to belly-up).
Live sides: style, hit and faint PRESENT x3 on Bramblebun and Riverdrake (toy-like; faint sits up facing the camera); Terrapup style PRESENT x3.
Remaining asks: Terrapup's dark fur loses its face against the floor in the faint (rim light); Bramblebun's hit reads as a hop; Riverdrake's faint should hide the pale belly; the remaining cartoon roster to the naturalistic bar (new art).
