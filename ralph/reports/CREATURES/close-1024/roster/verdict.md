# F36#1 whole-roster pose verdict (25 Oct 2026, CPU, land head 2a5300916 shipping state)

The roster has 70 subjects: every species and aspect variant, plus each water_* form that has its own recipe or swim role. They were judged in seven batches (r1-r7). Each batch used JUDGE_PROMPT.md verbatim, three fresh code-blind judges, at least 3 anchor pairs and calibrate.py mapping, and every batch was confirming. Each subject was shown as a shipping-state tile (A = B):
- First row: standing, hit and faint.
- Second row, where it applies: swim (water_* forms and swim mounts), fly-grip (carriers) and ride (rideable species).

Pass rule: no judge marks an applicable pose PRESENT, and the mapped mean is at least 6.7 (CPU-provisional). The b12 fixes (Bramblebun, Terrapup, Ripplet, Burrowback) replace those species' r1 rows.

**Result: F36#1 is not met. 31 of 70 pass.**

**Pass (31):** Stormursa, Trailpup, Mudsnout, Meadowhart, Bramblebun, Terrapup, Ripplet, Mosshell, Galecrest, Nightburrow, Veridian, Brooktail, Pipwing, Cindercub, Frostclaw, Shadelet, Staticub, Tidecoil, Sirenseal, Tanglevolt, Stormcapra, Craghorn, Thundertunnel, Stormraven, Glimmermoth, Cloudfang, Skyrill, Breezetail, Aeriex, Cliffspike, water_mosshell.

**Fail on a pose (clip work, this lane), 24 subjects:**
- Burrowback: lunge hit.
- Tuskroot: belly-up faint.
- Paddlenewt and Riftfrill.
- Aquaryn: swim rides above the water.
- Cannonback: shell roll.
- Torrentoad, Cragclaw and Fulgocobra: upright faints.
- Mangrove Monitor: flip.
- Pebbik: airborne hit.
- Riverdrake: land form.
- Solmane: crouch faint.
- water_cannonback and water_riptusk.
- water_torrentoad, water_cragclaw and water_riverdrake.
- water_aquaryn, water_tidecoil, water_sirenseal, water_mangrove_monitor, water_abyssal_guardian and water_mirejaw: base-rig fallback, with no swim clip except water_aquaryn.

**Fail on score only (materials/style, F36#0 remakes), 15 subjects:** Galewisp, Stormtrail, Duskhush, Reedwing, Ashtusk, Riptusk, Sparkit, Mirejaw, Voltwig, Abyssal Guardian, Mosshock, Stormbrush, Voltarach, Ribbonray, Tempestwing (stilt leg).

**Next:**
- b13: Mangrove Monitor -90 topple, Tuskroot topple (`--candidate-r13`).
- b14: enable the water_* recipes and author swim clips.
- Recoil hits on the remaining rear-up recipes.
- Meshy batch 4 for the material fails.

Batch verdicts: `roster/r1`-`r7/verdict.md`.

**After b13 (close-1024/b13):** Tuskroot, Mangrove Monitor (shipping faint reads as down on the b13 tile) and the water forms of Riptusk, Abyssal Guardian, Aquaryn, Mangrove Monitor and Sirenseal now pass: **38 of 70**.
