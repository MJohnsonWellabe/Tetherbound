# b23 (24 Oct 2026, CPU candidate pick): Aquaryn and Tidecoil Meshy b5 naturalistic remakes

What was compared:
- Candidates: coordinator Meshy b5 (navy back, ivory belly, matte scales).
  - Each is rigged as `candidate_b5` with the measured quadruped rig at its installed height (Aquaryn 3.4 m, Tidecoil 5.5 m).
  - Clips from the Ripplet nat1024b script: recoil hit, -90 faint, sunk swim.
  - No footprint shrink.
- Base: shipping (the installed models playing their b13 recipes).

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1, f36_0_gap:C5, p2_094_r4. This is a confirming batch.
- Fit: slope 1.363, intercept -1.651, RMSE 0.54.

| Species | Shipping | Remake | Remake poses (hit; faint) | Next |
|---|---|---|---|---|
| tidecoil | 6.39 | **7.26** | Pr x3; Pa/F/Pa | GPU READY. The hit reads as idle on the serpent (the recoil barely moves the coil), and one coil arches up in the faint. A serpent-specific hit is the next candidate. |
| aquaryn | 7.30 | 7.30 | Pr/Pa/Pa; F x3 | Tie. Judges split between navy (more naturalistic) and cyan (better value separation). Goes to GPU for the owner-directed look. |

Tidecoil's blue lines read as water and scale sheen, not storm, so they are left as they are.

The water forms share the land mesh, so `water_roster.json` moves water_aquaryn and water_tidecoil onto the remakes too (model and replacement_model). All four ids leave enabled_species.

Checks:
- With the lane's assets present: creature_rest_pose, water_species_catalog, four_biome, rideable and riding give 87 tests, 0 failed.
- Earlier focused set: water, species, f36_pose, dual_type, aspect, swim, texture_for and scale_ladder.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
