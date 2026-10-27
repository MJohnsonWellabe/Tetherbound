# b48: Stormtrail off-body lightning arcs vs main and vs the painted bolts (CPU, three judges)

Candidate: f1fa3f8e, built on 2ee02bfa's bolts. `aspect_vfx.gd` draws three jagged, camera-facing lightning ribbons between nearby points of the current pose, bowed 0.38 m off the camera-facing flank and redrawn every 0.16 s. Sheet `_sheet_b48.jpg`: main | bolts (2ee02bfa) | bolts + arcs.

Anchors: f36_0_gap:C1, f36_0_gap:C6, f36_0_npc:C1. Fit: slope 0.98, r 0.78, RMSE 0.49, confirming.

| set | side | mapped (j1, j2, j3) | mean | seams on fur / lines not arcing off |
|---|---|---|---|---|
| arcs vs main | main | 6.66, 6.85, 6.85 | **6.79** | PARTIAL, PARTIAL, PRESENT (both) |
| | bolts + arcs | 6.56, 6.56, 6.26 | 6.46 | PRESENT x3 (both) |
| arcs vs bolts | bolts | 6.56, 6.56, 6.26 | **6.46** | PRESENT x3 (both) |
| | bolts + arcs | 6.36, 6.36, 6.07 | 6.26 | PRESENT x3 (both) |

Call: arcs lose to both (-0.33 vs main, -0.20 vs bolts). Reverted. On the CPU stage the unshaded arcs read as "brighter, thicker white seam lines" (3/3), not as discharge.

This batch also scores main above the bolts, against b47's +0.32 the other way. Stormtrail lightning is therefore at two rounds under 0.5 (b47 +0.32, b48 -0.33). **Parked** per the rule.
- The 2ee02bfa bolts stay on tb/creatures-land. They are an owner-rule question, not a score win: they remove the lit-seam glow the owner ruled out.
- The GPU decides whether they carry. Their emission and bloom are GPU-only, and the CPU stage shows only the albedo core.

Judges' consistent read (b45, b47, b48): Stormtrail is "a plain grey wolf whose identity rests on the glow". All three suggest moving the coat toward Tanglevolt's blue-violet. That would change its identity colour (storm grey, owner 24 Oct), so it is the owner's call, not this lane's.
