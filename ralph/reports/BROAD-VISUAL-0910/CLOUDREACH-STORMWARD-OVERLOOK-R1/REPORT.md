# Cloudreach Stormward Overlook R1 — 2026-09-11

## Verdict

**POLISH — RETAIN.** This clears the previous invalid/FAIL receipt: both production frames place the trainer on valid authored ground and present an identifiable overlook threshold. It does not yet earn PASS.

## Production evidence

- Receipt: `shots/catalogue/cloudreach/cloudreach-stormward-r1-0911`
- Complete: 2/2 requested frames, day 08:00 and night 23:00, 1280x800.
- Production `CameraRig/Camera3D`, NVIDIA GeForce RTX 3050, ordinary gameplay HUD.
- Both frames report `debug_travel: true`, `terrain_ground_y: 1110.0`, `resolved_ground_y: 1110.0`, and 5.82 m camera/player distance.
- Generated HUD texture cache was repaired locally before capture; the successful engine log has no keyboard-icon cache failures.

## Pixel judgment

The day and night frames now visibly contain the trainer, a route apron, paired ruined masonry piers, banners, beacons, and the central compass treatment. The open threshold reads as a deliberate named place rather than the former low-angle floor/pillar failure.

Remaining POLISH defects:

- The centre tree blocks the compass/needle and visually divides the threshold.
- The bright, mostly blank cloud horizon does not supply a legible Stormwood/storm destination.
- Night masonry loses most surface definition against the pale sky.
- The bright compass slash can read as a UI/world-marker primitive rather than embedded directional craft.

## Arrival correction

The retained catalogue arrival is `[-418.0, 5634.0]`, heading `-6.0`. The first lateral candidate at z=5630 was collision-covered but outside `ground_height_at`'s 17 m landmark footprint, so production debug travel correctly refused it. The retained point lies inside both the production height footprint and the authored sloped crown.

## Next iteration for PASS

Reframe or move the centre tree so the compass and needle read uninterrupted, add a visible stormward destination cue beyond the threshold, lift night masonry separation, and integrate the white directional mark more clearly into the ground construction.
