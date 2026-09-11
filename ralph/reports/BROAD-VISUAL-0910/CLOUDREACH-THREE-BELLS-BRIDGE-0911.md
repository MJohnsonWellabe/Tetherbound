# Three Bells Bridge — named-location pass (2026-09-11)

## Disposition

Implementation-lane grade: **KEEP / POLISH**. The giant plain-pillar failure is removed, the bridge now terminates in a readable three-bell signal portal, and the retained east approach shows all three bells cleanly at player scale. This is not represented as an independent commercial-pass receipt.

## What changed

- Replaced the two 16 m undecorated piers with a bridge-aligned, human-scale signal portal: capped stone supports, timber crown and knee braces, five visible metal bindings, three unequal flared bronze bells with yokes/clappers, route pennants, teal signals, and warm bell lighting.
- Rotated the complete assembly onto the rope-span axis rather than presenting it as an unrelated crosswise prop.
- Preserved the existing production bridge deck, rope rails, landmark ledge, physical interaction marker, and all traversal collision. The new presentation is visual-only.
- Moved the two two-creature encounter pairs that were exactly 6 m from the west/east bridge landings roughly 50 m down their respective causeway legs. Their table, count, scatter radius, and road cadence remain intact.
- Moved the catalogue arrival from inside the former pier to the authored west approach, then offset the heading slightly so the avatar does not hide the full signal silhouette.

## Production evidence

Final receipt: `shots/locations/cloudreach-three-bells-bridge-0911-r3/`

- `three-bells-west-approach-day.png`
- `three-bells-west-approach-night.png`
- `three-bells-east-landing-day.png`
- `three-bells-east-landing-night.png`
- `manifest.json`: complete `4/4`, failures `[]`, production Cloudreach world/player/HUD/CameraRig/bridge/terrain/WorldLook, 1280x800, 70 degree FOV. Every retained frame analytically retains all three bell centres.

R1 is rejected because both landing encounters crowded the composition and the east creature covered the portal. R2 verifies the encounter fix but aimed directly through the avatar. R3 is the retained composition receipt.

## Visual read

- Primary/east landing: **KEEP / POLISH**. Three separate bronze bells, their supporting portal, and the bridge route read immediately day and night. No creature or HUD overlap obscures the destination.
- Secondary/west approach: **POLISH**. It sells the bridge span, cloud depth, and distant summit strongly; the signal is deliberately smaller at this longer arrival distance, and the player still overlaps part of the left bell in the default third-person composition.
- Night readability is improved by restrained warm light on the bell group, while the broader Cloudreach bright-sky/dark-ground night imbalance remains a shared biome issue rather than a bridge-local defect.

## Verification

- `test_cloudreach_three_bells_bridge.gd`: 4 tests, 28 assertions, 0 failed.
- `test_cloudreach_encounters.gd`: 3 tests, 3159 assertions, 0 failed.
- `test_four_biome_debug_teleport.gd`: 8 tests, 1047 assertions, 0 failed.
- `test_cloudreach_world_data.gd`: 13 tests, 407 assertions, 0 failed.
- Production receipt: 4/4, exit 0. The pre-existing `cr_candy_broken_route_good_07` missing-surface warning remains unchanged and is outside this location.

