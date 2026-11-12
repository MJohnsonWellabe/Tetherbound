# BELOW6-STRONGHOLD-STAND: F38#20 Team Tether stronghold (5.72), a closer approach stand. PROPOSAL for the coordinator's stand review

**Block:** `data/config/capture_stands.json approach_overrides.candidates_f38_20_1112` (OFF). Overlay: `overlay.json`.
**Tool change:** `phase2_capture_locations.gd approach_override_for` now reads any enabled `candidates_*` block (it read only `candidates_1112`, which ships ON). Test: `tests/test_capture_approach_overrides.gd` (4 tests pass).

**Why a stand, not art:** the row's recorded defect on approach is "reads as a small dark ruin behind dominant pylons". The Band 5 "Stronghold Approach" stand is the band's road entry at (0, 6968). The keep is about 590 m north of it, so in both approach frames (day and night) the row's subject is a speck on the horizon, and at night a black cut-out. This is the same case as the Stormheart stand (5.10 -> 6.81 once the stand showed its subject).

**Candidate:** the same road at (0, 7405), heading north, about 130 m from the gate. Screened on CPU with `--spot` at z 7330 (inside the trees), 7430 and (-30, 7480): at 7430 the keep, both flank towers, the gate ramp, the pylon line and the lit windows fill the frame, but the keep's top is cropped, so the block uses 7405. The sheet (`_sheet_cpu_old_stand_top_spot_7430_bottom.jpg`) shows the old stand above and the 7430 screen below, day and night. I have not captured 7405 itself.

**Not changed:** the game, and the row's third frame (`meadows__landmark__stronghold__day__approach`, the courtyard), where the judges' other complaint lives ("empty oversaturated stronghold interior").

**Ask:** approve the stand move, then queue base (overlay off) against arm (overlay on) for the two Band 5 approach frames with `phase2_capture_locations.gd --biome=meadows --subset=meadows__band5_stronghold_approach__09__stronghold_approach --times=day,night --views=approach --seed=2042`, High.
