# BEINGS-FLY-SHOULDER: Galecrest carries the trainer by the shoulders (F38#8)

**Status: CPU-ready, NOT queued.**

**Row:** F38#8 Fly carrier grip pose, GPU High 6.21 (pooled from two 12 Nov re-scores on main, 6.23 and 6.18).

**Defect, quoted (PRESENT 3/3 on both re-scores):** "trainer hangs rigidly under Galecrest". The last paired verdict (G-newapproach-fly-grip, the elbow bend that shipped at 7.14 in its own batch) says what remains: "the arms are still raised straight to the talons, so the bird still partly reads as perched on the hands. There is no lean or swing (3/3)." Judges a and b there ask for a grip at the shoulders.

## Cause, and how it was confirmed
`fly_controller.gd align_carrier_grip` puts the bird's two feet on the midpoint of the trainer's wrists every frame, and the hang pose aims the arms straight up at them. So whatever the arms do, the bird stands on the hands. CPU base frames on main (`phase2_capture_realm_flight.gd --biome=meadows`): both arms straight up, talons closed around the fists. The earlier shoulder-grip try (arm B, 268dc208d) failed the GPU pre-check and that commit is no longer reachable, so I could not read why; this is a new build.

## Change
Flag-off `data/config/fly_traversal.json hang_pose.shoulder_grip_1113`:
- `trainer_model.gd`: `fly_grip_world_points()` returns the shoulders (`LeftArm`/`RightArm` joints, lifted 0.06 m) when the flag is on, the wrists otherwise; with the flag on the arms bend up to hold the bird's legs (`upper` and `forearm` directions in the block).
- `fly_controller.gd align_carrier_grip` asks the model for its grip points, so the local carrier and a friend's carrier (`remote_trainer.gd`, same static function, same `set_fly_hang` pose) stay identical. A model without the method keeps the wrists.
Presentation only: carry offset, collider, camera, stamina and network packets are unchanged.

## CPU before and after
`_sheet_cpu_base_top_arm_bottom.jpg` (launch, glide; top base, bottom arm). Base: talons on the raised fists. Arm: the talons close on the upper arms beside the shoulders, the trainer's head sits between the bird's legs, the hands bend up to hold its ankles.

## By-eye line for the GPU lane
`01-launch`: the talons are at the trainer's shoulders, not on the hands above the head. If the talons still close on the fists, hold.

## Risks
- The hands are still up (holding the ankles), which some judges may read as "hands raised". If so, the next round lowers `forearm` so the hands hold the bird's shins at chest height.
- Talon geometry may touch the trainer's upper arms; on CPU it reads as a grip, not a clip. Check on GPU High.
- No lean or swing yet (the other half of the defect).

## Tests
`tests/test_beings_fly_shoulder_grip_flag.gd`, plus `test_uiposes_fly_hang_body.gd`, `test_human_swim_visual.gd`, `test_fly_traversal.gd`, `test_cloudreach_fly_loaner_end.gd`, `test_cloudreach_fly_build_shortcut.gd`: 43 tests, 0 failed.

## Landing notes
Flag ON with `_why_on`; turn `test_flag_is_off_and_presentation_only` into an ON pin. CI should run the fly smokes (`tests/smoke_*fly*`).
