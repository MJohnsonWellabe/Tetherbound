# THINGS-RULER: tail through the trainer on the pose stage (six F36 (1) rows)

**Shared cause.** `G-things-t4-rescore.md`: "Tail at or through the trainer: mirejaw (every frame, 3/3), brooktail, shadelet, riftfrill, sparkit, ashtusk". Those frames were captured without `--clear-ruler`, so the trainer ruler stood at the rest-mesh bounds and the posed tail ran through it.

**Change.** None to the game. The stage already has `--clear-ruler` (on main since the faint landing): it stands the ruler clear of the skinned mesh as posed. This is a re-capture and re-score with the flag on.

**CPU check** (`_sheet_ruler_off_vs_on_cpu.jpg`: columns are hit 000 off, on, hit 050 off, on; rows mirejaw, brooktail, shadelet, riftfrill, sparkit, ashtusk). With the flag the ruler stands clear of the tail in all six; creature size, camera and pose are unchanged.

**Expected.** Mirejaw 5.28 was marked down 3/3 for this in every frame; the other five 2/3 or 3/3. Roughly +0.3 to +0.8 per row across six rows.

**Ask.** Capture `capture_f36_poses.gd --whole-body --context --clear-ruler --roles=hit,faint` for the six species on main, High, and score against the t4 re-score frames. If it holds, `--clear-ruler` should be the fixed setting for every F36 (1) row.
