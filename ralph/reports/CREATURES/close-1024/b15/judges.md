# b15 (24 Oct 2026, CPU): F36#1 r15 faint candidates, Riverdrake's land recipe, and a fresh-judge re-check of two b13 tiles

What was compared:
- Candidates, all previewed with `--candidate`:
  - Cragclaw and Torrentoad topple at -90 instead of prone.
  - Solmane topples.
  - Cannonback lies prone.
  - Their water forms.
  - Riverdrake's land form plays its f36 recipe.
- Base: the shipping state at land c6985d7a9 (captured fresh).
- Re-check: the coordinator flagged identical b13 scores, so the b13 Tuskroot and water-Riptusk tiles were re-judged by three new judges.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1 (Grandpa face), f36_0_gap:C6, f10_2_r3_capacitor. This is a confirming batch.
- Fit: linear, slope 0.897, intercept 1.240, RMSE 0.68.

| Subject | Shipping | Candidate | Candidate poses (hit; faint; swim/ride) | Decision |
|---|---|---|---|---|
| riverdrake (land recipe) | 6.20 | **6.80** | F x3; Pa x3 | ON (land only; the lane keeps its pilot bound); passes F36#1 |
| cannonback (prone) | 6.11 | 6.11 | Pr x3; Pa/Pr/Pr | OFF (no change) |
| cragclaw (-90) | 6.41 | 6.02 | Pr x3; Pr x3 | OFF (belly-up) |
| torrentoad (-90) | 6.62 | 6.23 | Pr/Pr/Pa; Pr x3 | OFF |
| water_cragclaw | 6.41 | 6.02 | Pr x3; Pr x3 | OFF |
| water_torrentoad | 6.65 | 6.23 | Pr/Pr/Pa; Pr x3 | OFF |
| water_cannonback | 6.56 | 5.79 | Pr x3; Pr x3 | OFF |
| solmane (topple) | 5.67 | 5.58 | Pa x3; Pa/Pr/Pa | OFF |
| water_riptusk (b13 pair, re-judged) | 5.94 | **7.13** | F/F/F; F/F/Pa; Pa/Pr/F | Confirms b13 (7.46): ON stays. One judge marks swim PRESENT, so F36#1 is not passed on this re-check. |
| tuskroot (b13 pair, re-judged) | 6.29 | 6.59 | Pa/Pr/Pa; Pa x3; ride Pa/Pr/Pr | Stays ON (beats shipping again). Below 6.7 with the ride marked PRESENT, so its b13 F36#1 pass is withdrawn. |

Judges' asks:
- Real per-rig hit recoils: most installed recipes are still an idle lean.
- No belly-up flips.
- Seat the Tuskroot rider into the back.
- Swims level and submerged.
- Re-surface Solmane's washed-out texture.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
