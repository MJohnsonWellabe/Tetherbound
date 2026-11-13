# THINGS-BANNERLENS-LAND: the Warden fight camera no longer rests against the war banner

STATUS: land

- **Branch:** `tb/things-bannerlens-land`, cut from `origin/main` 01356b08.
- **Kind:** correctness fix, no GPU verdict (coordinator's message, 13 Nov). A no-loss look at the Warden fight frames on the GPU is still worth having.
- **Fault:** `G-things-wardenring-f41-13-closeout.md`, 3/3 on both sides: Warden fight frame r10 is near-black, the camera inside or behind geometry.
- **Cause (CPU, the tool's own `--lens-probe`):** when the Warden sends out his next creature the fight camera swings to the east wall. Its arm stops against the camera-only occluder box on the Team Tether war banner there. That box ended at the banner model's own cloth front, so the lens could rest touching the cloth: lens x 18.91 to 19.00 across two runs, inside the banner's bounds on one of them.
- **This is different from what I first wrote in the NOTE.** It is not a one-frame lag after the camera jumps, and nothing in `camera_rig.gd` changes. The lens settles there; the next sample only looked fine because the creatures had moved.
- **Fix:** `scripts/world/stronghold.gd _hang_banner` / `_add_banner_occluder`: the banner model's occluder box extends outward by `stronghold.json banner_model_candidate.occluder_standoff_m` (0.8 m, new key; 0 or absent = the old box). Depth only; the wall side of the box stays where it was. Camera occlusion layer only: no collision with anything else, no gameplay.
- **Shown (CPU):** with the stand-off the same sample puts the lens at x 18.11, 0.8 m in front of the cloth, inside nothing (`lens r09 ... inside 0`). `_sheet_warden_swap_cpu.jpg`: main (top) and this branch (bottom) at r09 and r10; the frames read the same on CPU, a little closer. CPU never drew the black frame, so the sheet only shows nothing got worse.
- **Tests:** new `tests/test_stronghold_banner_lens_standoff.gd` (2 tests).
- **Tests run on this branch:** all `test_stronghold*`, `test_fight_camera*`, `test_combat_camera*`, `test_conversation_camera*`, `test_conversation_clearance*`, `test_camera_rig*` (20 files): 122 tests, 1238 assertions, 0 failed.
- **Scope:** every war banner in the stronghold built from the model gets the deeper box, so a camera near any of them stops 0.8 m further out.
- No `.uid` files are included.
