# Local light shadow fade: before/after evidence

Change: `scripts/world/local_light_shadow_fade.gd`, configured by `performance.json` `local_light_shadow_fade` and hooked from `world_look.gd::_ready` for every realm. It applies only to shadow-casting omni/spot lights with no authored distance fade:
- An exterior light loses only its shadow past 18 m; the light itself stays out to 160 m.
- An enclosed light (an ancestor named `Interior` or `GrandpaHouse`) is unchanged out to 72 m. It then fades out whole by 80 m, before its shadow is allowed to drop.

## Structural numbers (Meadows F26 stands, Compatibility under xvfb, batching on in both)

| Stand | Draws before | Draws after |
|---|---:|---:|
| stand_0 | 5,396 | 5,397 |
| stand_1 | 2,525 | 2,525 |
| stand_2 | 963 | 963 |
| stand_3 (Hall nave) | 8,971 | 6,646 |

The probe JSON is `../probe/meadows_fade.json`. Before the fade, 11–13 shadowed interior room lights were in the frustum at stand_0 and stand_3. At the nave, GrandpaHouse alone cost 2,446 draws from 236 surfaces, about 110 m away.

## Judge rounds (code-blind, randomised X/Y; keys in this folder)

1. **judge2: shadow-first fade at 18 m for every light. Rejected.** The judge preferred the fade build at night, because unblinding showed warm pools around the cottages. In fact room light was leaking through walls once its shadow was gone.
2. **judge3: enclosed lights fade whole from 18 m. Rejected.** On Compatibility the shadow cut off before the light's fade finished, so there was still a leak on cottage exteriors, and distant lattice windows went dark.
3. **judge4: enclosed lights untouched to 72 m, fading light-first. Accepted, EQUIVALENT on all 8 pairs.** Lighting, light pools, window glow and interiors seen through openings were identical. The only differences were clouds, grass, pulse phase and idle pose.

A pre-existing defect noted in both builds: at 23:00 the open Hall doorway on route_02 shows a flat, bright beige interior.
