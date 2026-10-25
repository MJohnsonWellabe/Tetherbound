# b14 (25 Oct 2026, CPU): Meshy batch 4 remakes, Pebbik and Riptusk (F36#0 / F36#1)

What was compared:
- Candidates: naturalistic remakes from Meshy batch 4 (coordinator-generated at `tb/meshy-1024` 23267cffd).
  - Rigged with the Cindercub (Pebbik) and Ripplet (Riptusk) native-clip scripts, which give a recoil hit, a -90 roll faint and a sunk swim.
  - Bound locally for the capture only.
- Base: the roster shipping tiles (r5 Pebbik, r3 Riptusk).
- Capture logs: no footprint-allowance shrink.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1 (Grandpa face), f36_0_gap:C2, f10_2_r3_capacitor.
- Fit: linear, slope 0.934, intercept 1.118, RMSE 0.70.
- Warning: Riptusk meets 7.5 only above the top anchor (7.53). This batch's anchors reach 7.35 or more, so it is the confirming batch.

| Species | Shipping | Remake | Remake poses (hit; faint) | Decision |
|---|---|---|---|---|
| riptusk | 6.88 | **7.81** | F/Pa/Pa; F x3 | ON; F36#0 at the 7.5 bar (CPU); passes F36#1 |
| pebbik | 5.69 | **7.16** | Pa x3; F/F/Pa | ON; CPU-provisional F36#0 (>= 6.7); passes F36#1 |

Judges' notes:
- Riptusk's faint is a little pancaked, with the legs swallowed.
- Pebbik's hit rears like a hop. Its faint head squashes, a deformation at the end pose.
- Both read as naturalistic and on the owner's style bar.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
