# CAUSE-CAMFX lane (tb/cause-camfx): cameras and effects

## Status (1 Nov, group 1)
- **Criteria closed: zero.** Nothing here is judged. Every candidate is flag-OFF in `data/config/camfx.json` (one block per sub-cause, so it composes with every other lane's flags; no shared config file edited).
- **No CPU capture was possible in this container.** The writable disk allowance left ~0.9 GB beside a 21 GB pack, and a Godot import needs several GB. So the candidates are unverified on screen. Each was parse-checked and unit-tested with stubbed asset preloads (TECHNICAL §8.1 disk-tight route). The GPU arm is the first render; please capture before judging.
- `MANIFEST.json`: 69 rows (item × flag × camera set), group 1. Camera sets are the job.json repro commands without `--out`.

## Candidates (all OFF)
| Sub-cause | Flag | What it changes | Items |
|---|---|---|---|
| (4) Catch orb | `camfx.json:catch_orb.enabled` | The authored Meshy capture orb (teal/cream shell, brass band; already in repo, `assets/props/meshy-1020/capture_orb`) replaces the flat gold sphere. The halo shows in flight only, at 2.6x instead of 5.5x. There is **no disc at hang, rest or seal**. A soft contact shadow sits under the resting orb. Landing and each shake kick small dust and grit (the fights' `contact_burst`) instead of the flat gold flash disc. Each shake squashes and hops the shell. Verdict flashes are scaled to 0.55. | P2-059, P2-060, P2-061, P2-113, P2-117, P2-118 |
| (2) Camp fire flame | `camfx.json:flame.enabled` | `ignite()` hides the Bonfire's flat Fire cone and stands a procedural flame in the cone's own footprint: two Y-locked cards with a feathered, noise-licked teardrop that sways and flickers (`shaders/camfx_flame.gdshader`). Orange to pale gold, no red. There are no textures or particles, so it should read the same on Compatibility and Forward+. The halo card is dropped for replaced cones; light, embers and smoke are unchanged. | P2-035 (bonfire_fire, camp frames), P2-006 (trail camp close) |
| (1)+(3) Fight and dialogue occlusion | `camfx.json:fight_fade.enabled` | Turns on the shipped occlusion fade (tb/vis-storm-cams) for fight and conversation cameras even with `camera.json occlusion_fade` off. It also fades along the opponent's (fight) and speaker's (conversation) chest-to-lens line, not only the followed body's. It also fades shadowless foliage cards at least 2.5 m tall (canopy leaf cards the base fade skips). Aimed at the Stormwood canopy blackouts (i11/i13/i15), Fenn's black frame (P2-084) and rock or overhang between lens and speaker. | every fight item (P2-062/063/064/065/088/089/090/091/092/093/101/103/110/111/112) and every dialogue item (P2-073–079, 081–084, 086, 087) |

## Checks (stubbed preloads, no import)
- `test_camfx_candidates.gd` (new): 6 tests, 39 assertions, 0 failed. It covers: every block OFF and inert; flame OFF keeps the lit cone; flame ON hides the cone and builds two cards on its base; the catch-orb block names an installed model; OFF paths unchanged.
- These passed, 0 failed: test_camera_rig_out_of_tree, test_camera_rig_vertical_sweep, test_combat_camera_clear_orbit, test_conversation_camera (135 assertions), test_fight_camera, test_orb_passes_your_own_creature, test_storm_cams_candidates, test_capture_readout_side, test_combat_vfx, test_catch_math, test_combat_camera_shoulder.
- **Not passing locally because of the environment:** test_vegetation_camera_canopy needs imported tree GLBs. test_trail_camp_arrival_identity needs props.gd to compile, and the asset stubs break its dependency chain. Both need a real import (CI).

## Not done / notes
- **Telegraph rings:** on this base, generic fights already run `telegraph.soft_style.outline_off` (dust tells) and `impact.ground_burst` (dust and stone chips). The GPU sheets show no magenta slab in the Meadows/Stormwood fight frames, and P2-093 and P2-063 are judged FIXED. I did not rebuild them. Any remaining magenta is in per-pattern `cue_*` rows (fights lane data) that I could not see without a render.
- **Kell (P2-078):** he is placed only after `legendary_freed` (STORMCAMS note), so the frame needs a post-game save, not a camera change.
- **"Speakers lack capture stands" (P2-073/074/075/086/087):** every one of these is in `tools/phase2_character_plan.json`, and STORMCAMS group 1 lists its `__dialogue` stands, so I found nothing missing to add. Coordinator: if you meant something else, note it here.
- **Catch outcome card with the HUD collapsed:** `hud.json catch_card` (UIPOSES, OFF) already does this. It is not duplicated here; judge it together with `catch_orb`.
