# BELOW6-STRONGHOLD-STAND: F38#20 Team Tether stronghold (5.72), a closer approach stand. PROPOSAL for the coordinator's stand review

**Block:** `data/config/capture_stands.json approach_overrides.candidates_f38_20_1112` (OFF). Overlay: `overlay.json`.
**Tool change:** `phase2_capture_locations.gd approach_override_for` now reads any enabled `candidates_*` block (it read only `candidates_1112`, which ships ON). Test: `tests/test_capture_approach_overrides.gd` (4 tests pass).

**Why a stand, not art:** the row's recorded defect on approach is "reads as a small dark ruin behind dominant pylons". The Band 5 "Stronghold Approach" stand is the band's road entry at (0, 6968). The keep is about 590 m north of it, so in both approach frames (day and night) the row's subject is a speck on the horizon, and at night a black cut-out. This is the same case as the Stormheart stand (5.10 -> 6.81 once the stand showed its subject).

**Candidate:** the same road at (0, 7405), heading north, about 130 m from the gate. Screened on CPU with `--spot` at z 7330 (inside the trees), 7430 and (-30, 7480): at 7430 the keep, both flank towers, the gate ramp, the pylon line and the lit windows fill the frame, but the keep's top is cropped, so the block uses 7405. The sheet (`_sheet_cpu_old_stand_top_spot_7430_bottom.jpg`) shows the old stand above and the 7430 screen below, day and night. I have not captured 7405 itself.

**Not changed:** the game, and the row's third frame (`meadows__landmark__stronghold__day__approach`, the courtyard), where the judges' other complaint lives ("empty oversaturated stronghold interior").

**Ask:** approve the stand move, then queue base (overlay off) against arm (overlay on) for the two Band 5 approach frames with `phase2_capture_locations.gd --biome=meadows --subset=meadows__band5_stronghold_approach__09__stronghold_approach --times=day,night --views=approach --seed=2042`, High.

## Stand moved to (0, 7130) after the GPU pre-check (12 Nov)

The GPU lane held the first stand: at z 7405 the keep's top runs off the frame, day and night. Two more CPU screens (z 7385, 7365, (-18, 7350); then 7130, 7210, 7270) show why: the keep stands high on its hill and the production camera looks slightly down, so every stand from 7210 up crops the battlements or sits inside the tree line (one also had wild creatures filling the frame). At **(0, 7130)** the whole keep, its towers and banners stand against the sky at the end of the road, about a fifth of the frame tall (`_sheet_cpu_7130_7210_7270.jpg`, left). The block now uses (0, 7130), heading 0. The base stand at 6968 shows the keep at roughly half that size behind the first pylons.
