STATUS: parked
BRANCH: tb/item-hitreact  HEAD: the commit that adds this file (origin/main merged in just before)

- Row: Shadelet, Paddlenewt, Glimmermoth and Tempestwing, faint clipping and floating hit-react (CREATURES-RALPH open items; Shadelet 6.26, Paddlenewt 6.70, Glimmermoth 5.57, Tempestwing 5.87). One cause tried: root keys not grounded per frame.
- Arm `data/config/creature_model_flags.json:flags.lanekit_hitreact_grounded_1107` (OFF; in HELD in tests/test_creature_model_flags.gd). Copies of each live remake GLB with the existing `tools/art_pipeline/ground_clip.py` applied (`make.sh`): `hit --settle` on all four (8, 6, 11 and 10 of 13 hit root keys moved). No new mesh, no size change.
- First cut (not judged, recorded): also grounded the winged species' `faint` on the lowest vertex. The downward wing tip then held Glimmermoth and Tempestwing about 1.5 m in the air, worse than the clip, so faint was left unchanged.
- Round `ralph/reports/LANES/LANE-KIT/qj/HITREACT-33acc782d931-11072245/`: neutral `capture_f36_poses.gd` stage, `--whole-body`, hit-react mid for all four. **Flat 6.14 -> 6.14**: every judge scored the sides identically.
- Why flat: the lowest vertex already sits on the floor in these clips. What the judges call "floating" is the lunge pose itself (daylight under the chest) plus the stage sun's angled shadow, which lands behind and below the torso. More root grounding cannot change that.
- Flags turned ON: none. Tests: HELD entry added (OFF arm). run_tests --only=test_creature_model_flags: 3 tests, 1129 assertions, 0 failed.
- Judges' remaining asks: seat the hit pose on its contact points (lower chest/pelvis) and rim light so the dark bodies separate. Shadelet's face disappears into black. Glimmermoth's big blue wing reads as a glossy plastic slab (new art). The hit reads as a crouch, not a recoil.
- Next idea:
  - A per-bone pose edit on the hit clip: pelvis and spine down a few cm at mid, legs folded (`lateral_recoil.py`-style rotation), so the chest meets its shadow.
  - Separately, a wing-fold rotation in the winged faint clips so the wings stay above y=0 without lifting the body.
  - The landed `creature_rim` / per-species coat rim covers the rim ask.
- Also unblocks F38#26's re-judge only partly: Mosshell's faint float is a different species and clip.
