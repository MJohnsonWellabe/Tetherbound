# SCENE-ROLEPOSES: authored readable villager poses (F38#35)

**STATUS AT WRAP-UP (14 Nov): pose-bench only; NOT in-world verified; not queued.**
- Overlap found: `data/config/npc_post_stances.json` (P2-050, `scripts/characters/post_stance.gd`, a SkeletonModifier3D from `village_npcs.gd`) is a separate, OFF stance system for the same three villagers (Oskar arms_folded, Halda hands_clasped, Lark strap_hold). G-occlusion-fade-off-wide recorded F38#35 level, 6.24 to 6.24 (0/3, three ties); I did not confirm whether that run had post stances on.
- Next step: capture with `tools/phase2_capture_characters.gd` (the plan is `tools/phase2_character_plan.json`; the world-inventory tool exited 1 because it has no character rows). Keep `npc_post_stances.json enabled` false so the two systems do not stack. If the poses read in world, queue this arm; the folded-arms and hands-on-hips silhouettes are larger than P2-050's angles.

Row: F38#35 Meadows human post poses. GPU High 6.33 (5.7, 5.3, 5.2), PRESENT 3/3: "every NPC holds the same arms-down idle". The 1.8x gain on the old angles is parked (it did not register).

## Cause

`npc_postures.json` P2-050 profiles add 4 to 38 degrees per bone over the breathing idle (marshal: elbows 28 degrees; keeper: one forearm 38 degrees). The silhouette still reads as arms down at sheet size. This is a pose problem, not a scale problem: on the GPU frame Oskar is about 180 px tall and still reads neutral.

## Arm

Overlay: `npc_postures.json role_poses_1114.enabled` true. Flag-off code on `tb/scene`: `npc_posture.gd install()` merges the flag's `by_name` over the shipped map. It uses the same bone-local offsets over each villager's installed idle, so breathing continues, and hips, legs and feet are untouched.

| Villager | Pose | Why this one |
|---|---|---|
| Halda (`villager_ranger`) | Folded arms: upper arms forward and twisted in, forearms crossed at the chest | Her shirt is skinned to the arms, so any raised-elbow pose (hands on hips) flares it into a skirt. Folded arms keeps the elbows down. |
| Oskar (`villager_keeper`) | Hands on hips, elbows out, slight lean back | The vest deforms cleanly. This is the widest silhouette change. |
| Lark (`courier`) | Right hand on hip, left hand up at his satchel strap | Reads as a cocky courier waiting for the next run. |

The axes were found on an xvfb pose bench that builds each villager from its real art key. Arm Z sets abduction, arm Y twists, and forearm X flexes. Twist plus flex brings the hand across the body. Each pose was checked downscaled to about 40 px tall against the shipped poses: folded arms and hands on hips both read as a different silhouette at that size.

Test: `tests/test_npc_role_poses_flag.gd`. It checks that the flag ships off and the shipped roles stay. With the flag on, each villager gets its posed clip on its real rig; a missing bone would fall back to the neutral idle.

## By-eye line for the GPU lane

On `meadows__inventory__character__oskar` at High, Oskar stands with hands on hips, elbows out. Halda's arms are folded across her chest. Lark has one hand on his hip. If any of them still stands arms down, the overlay did not apply: hold it.

## Risks and no-loss frames

- Folded arms bring the hands together. The P2-050 note asks for hands apart, but the coordinator named folded arms. The hands stay below the face, as a social pose rather than a guard.
- Close-ups may show the hands clipping the forearms on folded arms.
- No other NPC changes, since only these three names are mapped. Any other Meadows character frame must be identical.
