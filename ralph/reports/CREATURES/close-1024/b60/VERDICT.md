# b60: Ripplet matte coat r1 vs main (CPU, three judges)

This is a near-bar close-out. On GPU F36 main-1024, Ripplet scored 7.26, and the judges called its coat a "flat, plastic-smooth cyan material".

r1, built with `ripplet/candidate_nat1024b/retex/grade_matte.py` without countershading, changed three things on main's own maps:
- roughness from 0.68 to 0.88;
- coat saturation x0.72;
- doubled the painted strand contrast.

Tiles: standing, hit 050, faint 050, faint 100. Anchors: f36_0_gap:C4, craft, f36_0_npc:C3. Fit: slope 1.98, r 0.97, RMSE 0.31, **confirming**.

| | main | r1 | gain |
|---|---|---|---|
| Ripplet (mapped) | 5.62 | 5.89 | +0.27 |

The defect read PRESENT, PARTIAL, PRESENT on r1. All three judges asked for the same next change: "one flat cyan value", meaning a darker back, a lighter belly, rim light and a fin accent.

Call: under 0.5 on its own. r2 adds countershading (b61).
