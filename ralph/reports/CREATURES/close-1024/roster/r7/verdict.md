# r7 (25 Oct 2026, CPU): F36#1 whole-roster pose verdict, batch 7 of 7 (water forms, land head, shipping state)

Same method as r4-r6. Anchors: Grandpa face (f36_0_npc:C1), craft and the Mudsnout gap pair. This is a confirming batch. Fit: linear, slope 1.363, intercept -1.950, RMSE 0.16. Warning: some candidates sit more than 0.5 outside the anchors' measured range (low end, extrapolated). The verdict holds regardless, because every low row also fails on a PRESENT pose.

Pass rule: no judge marks an applicable pose PRESENT, and the mapped mean is at least 6.7 (CPU-provisional). A water form with no swim clip fails swim. The builder printed MISSING ROLE CLIPS for water_tidecoil, water_mirejaw, water_sirenseal, water_mangrove_monitor and water_abyssal_guardian.

| Species | Mapped | Hit | Faint | Swim | Verdict |
|---|---|---|---|---|---|
| water_mosshell | 7.32 | Pa x3 | Pa x3 | F/F/Pa | pass |
| water_torrentoad | 6.28 | Pa x3 | Pr x3 | F/Pr/Pa | FAIL: hind leg kicks up in the faint, through the ruler |
| water_cragclaw | 6.23 | Pa/Pa/Pr | Pr/Pa/Pa | Pa/Pa/Pr | FAIL: faint stays on its legs, swim wades |
| water_aquaryn | 5.87 | Pr x3 | Pr x3 | | FAIL: base-rig fallback (hit = idle, upright faint) |
| water_riverdrake | 5.78 | Pa x3 | Pr x3 | F/Pa/Pa | FAIL: belly-up floating faint |
| water_tidecoil | 5.69 | Pr x3 | Pr x3 | no clip | FAIL: fallback; faint rears like a roar |
| water_sirenseal | 5.59 | Pr x3 | Pr x3 | no clip | FAIL: fallback; sit-up faint |
| water_mangrove_monitor | 5.55 | Pr x3 | Pr x3 | no clip | FAIL: fallback; sit-up faint |
| water_abyssal_guardian | 5.14 | Pr x3 | Pr x3 | no clip | FAIL: fallback; sit-up faint, hovering flipper |
| water_mirejaw | 4.05 | Pr x3 | Pr x3 | no clip | FAIL: fallback; floating belly-up faint, blotchy camo, near-oxblood gills |

Every water form except Mosshell and Torrentoad plays the installed base-rig fallback, because its f36 recipe is not in enabled_species. Next: b14 enables the water_* recipes and adds swim clips, capturing the candidate against this shipping state.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
