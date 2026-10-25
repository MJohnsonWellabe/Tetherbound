# b13 (25 Oct 2026, CPU): F36#1 roster fixes, water-form recipes and the r13 topples

What was compared:
- Candidates:
  - Eight water forms previewing their base species' f36 recipe (`--candidate`).
  - The r13 topples, Mangrove Monitor -90 and Tuskroot +90, applied through the post-pass.
- Base: each subject's roster shipping tile (r1, r4, r6, r7; land head 2a5300916).

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1 (Grandpa face), f36_0_gap:C7, p2_094_r4. This is a confirming batch.
- Fit: linear, slope 1.430, intercept -2.264, RMSE 0.42, no warnings.

| Subject | Shipping | Candidate | Candidate poses (hit; faint; swim/ride) | Decision |
|---|---|---|---|---|
| tuskroot (topple) | 6.17 | **7.46** | F/F/Pa; F x3; ride Pa x3 | ON; passes F36#1 |
| water_riptusk | 5.74 | **7.46** | F x3; Pa/F/F; Pa/F/F | ON; passes |
| water_abyssal_guardian | 5.36 | **7.36** | Pa/F/F; F x3; F x3 | ON; passes |
| water_aquaryn | 5.46 | **7.13** | Pa x3; F x3; F/F/Pa | ON; passes |
| water_mangrove_monitor | 5.22 | **6.94** | Pa/Pa/F; Pa/F/F; F/F/Pa | ON; passes |
| water_sirenseal | 5.27 | **6.94** | Pa x3; F x3; F/Pa/F | ON; passes |
| water_tidecoil | 5.27 | **6.89** | Pa/Pa/F; F x3; Pa/Pr/Pa | ON; F36#1 still open on swim (coils float above the plane) |
| water_mirejaw | 4.31 | 5.89 | Pa/F/F; Pa/F/F; F/Pa/F | ON below bar (beats shipping, faint not PRESENT); fails score (camo bake, Meshy) |
| water_cannonback | 6.03 | 5.51 | Pr x3; Pr/Pa/Pa; F/Pr/Pr | OFF (belly-up faint) |
| mangrove_monitor (-90) | 7.03 | 5.84 | Pa/Pa/F; Pr x3 | OFF (rolls belly-up); its shipping +90 topple stays. On this tile the shipping faint reads as down, so Mangrove Monitor now passes F36#1 (hit Pa/Pa/F, faint F/Pa/F). |

Judges' recurring asks:
- The tail passes through the ruler (stage placement only).
- Faint-end darkening on dark coats.
- Swim limbs still stride under the plane.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
