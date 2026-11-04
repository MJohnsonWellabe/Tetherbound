# F38#41 old quarry: conduit core and sunk floor tiles (parked, flat)

- Arm (OFF): `old_quarry.json conduit_head.core` {albedo #2e8a94, emission #2fb8c8, energy 0.9} (hook `old_quarry.gd`, 5fdd86d25) plus `building_prefabs.json quarry_foundation` Floor_UnevenBrick y 0.03 -> -0.4.
- Frames: `catalogue_survey.gd --biome=meadows --times=day --subset=quarry` (one stand, `meadows__band2_stone_and_root__03__the_old_quarry__day`), CPU llvmpipe Compatibility. The GPU-only look-dev rigs (`capture_meadows_look.gd`) refuse CPU, and quick_judge has no F38#41 entry, so this round used `anchor_tiles.py` (3 anchor pairs incl. craft) and three fresh code-blind judges with JUDGE_PROMPT verbatim.
- Raw Bar A, base / cand: j1 5.4 / 5.4, j2 5.5 / 5.6, j3 5.5 / 5.5. Gain +0.03 raw: flat. No calibration needed; stays OFF.
- The core change reads (a teal cylinder, not a white blow-out), but the judges score the frame on other things. The floor slab is not visible from this stand.
- All three judges name the same blockers: the flat brown cliff block at frame right ("untextured block, stretched texture, hard box edges"), the smooth faceted boulders, and the foreground plank fence cut by the camera near plane. That is a material swap or new rock art, not a tint.
