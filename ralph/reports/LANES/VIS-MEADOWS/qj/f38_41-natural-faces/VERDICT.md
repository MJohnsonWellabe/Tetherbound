# F38#41 old quarry: natural rock worked faces, grey stone, sunk floor tiles (SHIPPED ON)

- Arm: `old_quarry.json worked_cut.natural_faces: true` (new optional hook in `old_quarry.gd`, default off; routes the four WorkedFace pieces to the installed `stylized_nature/Rock_Medium_*` meshes instead of the generated cliff panel), every extraction_face / tool_course / working_bench colour moved from tan to grey (#8a867d-#a09a8f), and `building_prefabs.json quarry_foundation` Floor_UnevenBrick y 0.03 -> -0.4. No new meshes.
- Frames: `catalogue_survey.gd --biome=meadows --times=day --subset=quarry` (stand `meadows__band2_stone_and_root__03__the_old_quarry__day`), CPU llvmpipe Compatibility, 1280x720. Packet: `anchor_tiles.py` (3 anchor pairs incl. craft, seed 4141), three fresh code-blind judges, JUDGE_PROMPT verbatim. Candidate set Gz, side B = candidate.
- Raw Bar A, base / cand: j1 5.9 / 6.5, j2 6.0 / 6.5, j3 5.5 / 6.3. Mean 5.80 -> 6.43 (+0.63). All three prefer the candidate and move the recorded defect PRESENT -> PARTIAL.
- Anchors ran the known direction (craft after > before on all three; wall after > before on all three).
- Judges on the candidate: the flat stretched brown slab is replaced by "chunky stratified rock faces" that read as a quarry face. Remaining: smooth low-detail boulders, foreground planks clipping the camera near plane, a floating teal tether line at left, a flat tree wall behind.
- An earlier sub-arm (grey colours + sunk tiles without natural faces, q41b) barely changed the frame and was not judged.
