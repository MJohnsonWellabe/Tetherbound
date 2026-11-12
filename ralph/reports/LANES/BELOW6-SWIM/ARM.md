# BELOW6-SWIM: the swimmer shows a body and a stroke (F39#5, 5.64)

**Flag:** `data/config/human_swim_visual.json surface_crawl_1112` (OFF; overlay turns it on).
**Code:** `scripts/player/trainer_model.gd`: `load_human_swim_visual` merges the flag's `swim_pose` last; `_apply_human_swim_pose` gains `arm_recover_lift` (0 keeps the old stroke). Test: `tests/test_surface_crawl_flag.gd`.

**Cause:** the two stroke candidates that are active on main (`uiposes_stroke_candidates`) set `chest_above_surface_m -0.14`, pitch 84 and `arm_depth 0.3`. The chest is under the surface and the arms reach below the body, so from the swim camera only the hair and the pack break the water: "a floating head with no stroke" (3/3).

**What the arm does (pose keys only):** chest 0.03 m above the surface, pitch 80, arms wider (0.6), arms just under the body plane, and on the recovery half of each cycle the arm arcs up out of the water (`arm_recover_lift 0.75`). Capsule, camera, speed, stamina and the network packet are unchanged; a remote trainer runs the same pose code from the packet it already gets.

**CPU look** (`_sheet_cpu_base_top_arm_bottom.jpg`: entry, surface west, surface mid; base top, arm bottom): shoulders, upper back and pack are above the water, one arm reaches forward out of the water and the other lies out at the surface. Round 1 (chest 0.16, lift 1.0) floated the whole body on top with both arms up; this is round 2. 0 script errors. No CPU judge batch.

**Risks:** in a still the raised arm can read as a wave. Water is opaque on CPU; on GPU more of the body may show through.

## r3 (12 Nov, after the GPU pre-check hold)

The GPU lane held r2 before judging: on the GPU's transparent water the whole trainer lay on top of the surface, torso and legs visible, with one or both arms raised high and wide, which reads as a wave or "hands up".

r3 (same flag, pose keys only): chest 0.07 m under the surface (main is -0.14, r2 was +0.03), pitch 83, `arm_lateral` 0.42, `arm_recover_lift` 0.42 and `forearm_recover_scale` 0.6, so the recovering arm stays low and forward.

CPU (`_sheet_cpu_base_top_arm_bottom.jpg`, r3 below base): head, shoulders and the top of the pack sit at the waterline; one forearm and hand reach forward just above the water and the other arm lies at the surface. The CPU water is opaque, so how much of the body shows through on the GPU is still unverified.

## r4 (12 Nov, after the second GPU pre-check hold): not CPU-captured

The GPU lane held r3 as well: on its frames the recovering arm stands high above the head with an open hand, and the torso, pack and a boot clear the water. My CPU frames of r3 showed a low arm; the stills land on a different stroke phase there and the opaque CPU water hides the body, so CPU is not a reliable check for this arm.

r4 drops the arc instead of tuning it: `arm_recover_lift` 0.1 (the arms skim the surface plane), `arm_depth` 0.0, `arm_lateral` 0.34, chest 0.10 m under the surface, pitch 86. The stroke should show as arms reaching forward at the waterline, with the body under it. I have not captured r4 on CPU; the GPU pre-check (about 3 minutes) is the test. If r4 is held too, I park the pose approach: the next step would be a pinned stroke phase in the capture or an authored swim clip.

## r4 checked numerically and with the water hidden (12 Nov, coordinator's request)

Probe: the swim capture, overlay on, at `surface_mid`; the pose was stepped through twelve phases of one stroke cycle with `_apply_human_swim_pose`, and each bone's height above the water plane printed (metres; the loaded pose dictionary was printed too, so the keys do reach the pose).

| Bone | Whole cycle |
|---|---|
| Spine02 (chest) | -0.10 at every phase |
| Hips | -0.12 at every phase |
| Head (bone at the skull base) | -0.02 at every phase |
| Upper arm (shoulder end) | -0.03 at every phase |
| Forearm (elbow end) | -0.05 to +0.04 |
| Hand | -0.00 to +0.13 (the peak is one phase per side) |
| Foot | -0.10 to +0.06 |

So in r4 the chest and hips stay under the plane for the whole cycle and the hand's apex is 0.13 m above it, about 0.16 m above the shoulder, never near head height. `_sheet_cpu_r4_water_hidden_two_phases.jpg` shows the two apex phases with the sea mesh hidden: the body lies flat and prone with the arms close to the head, one reaching slightly forward, and no raised arm.

For comparison r3's keys were `arm_recover_lift 0.42` with `arm_depth 0.12` and chest -0.07; I did not probe r3, so I cannot say from numbers why its GPU frames showed the arm above the head.
