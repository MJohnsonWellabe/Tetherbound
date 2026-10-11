# P2-039 capture key (not for the judge)

Renderer: gl_compatibility, `--preset=Low --low-resolution=1920x1080` (Low/Compatibility). Forward+ High/Medium crashes on render.yml (llvmpipe Vulkan, signal 11 after world attach; runs 38153416759, 38153419748, 38153812819), so no Forward+ sheet exists here.

Command (only checkout_ref and --source-commit/--output differ):
`tools/phase2_capture_locations.gd -- --biome=stormwood --seed=2042 --subset=glowmoss_hollows --subset=crown_heartstone --times=day,night --views=approach,close --preset=Low --low-resolution=1920x1080`

Each run captured 16 frames (16/16 OK); the 4 `stormwood__landmark__crown_heartstone__*` frames duplicate place 08 and are left off the sheets.

| Sheet | A (left) = BEFORE | B (right) = AFTER |
|---|---|---|
| sheet-1-low-compat.jpg | 408d028fdb2c2b4a813761797369ec1fb847cc0e (failed attempt), run 38154410700 | de7e24d93df54c6fb3ae3915a10699c875170bbb (candidate), run 38153815266 |
| sheet-2-low-compat.jpg | 9e39d0086ee88998b8295747fc19f6603fe714f7 (main), run 38155917837 | de7e24d93df54c6fb3ae3915a10699c875170bbb (candidate), run 38153815266 |

Ground band mean luminance: Rec.709 luma (0–255, sRGB values) of the bottom 30% of each full 1920x1080 frame.

Sheet 1: mean A 8.6, mean B 16.8

| Pair | Frame | A | B |
|---|---|---|---|
| 1 | stormwood__glowmoss_hollows__03__the_lantern_pools__day__approach | 1.9 | 7.6 |
| 2 | stormwood__glowmoss_hollows__03__the_lantern_pools__day__close | 5.7 | 9.5 |
| 3 | stormwood__glowmoss_hollows__03__the_lantern_pools__night__approach | 2.1 | 7.9 |
| 4 | stormwood__glowmoss_hollows__03__the_lantern_pools__night__close | 5.8 | 9.8 |
| 5 | stormwood__glowmoss_hollows__04__crown_overlook__day__approach | 0.7 | 14.8 |
| 6 | stormwood__glowmoss_hollows__04__crown_overlook__day__close | 0.3 | 5.9 |
| 7 | stormwood__glowmoss_hollows__04__crown_overlook__night__approach | 0.6 | 14.7 |
| 8 | stormwood__glowmoss_hollows__04__crown_overlook__night__close | 0.4 | 5.9 |
| 9 | stormwood__hollow_crown__08__the_crown_heartstone__day__approach | 0.8 | 18.0 |
| 10 | stormwood__hollow_crown__08__the_crown_heartstone__day__close | 42.8 | 47.8 |
| 11 | stormwood__hollow_crown__08__the_crown_heartstone__night__approach | 0.5 | 17.8 |
| 12 | stormwood__hollow_crown__08__the_crown_heartstone__night__close | 42.1 | 41.6 |

Sheet 2: mean A 21.0, mean B 16.8

| Pair | Frame | A | B |
|---|---|---|---|
| 1 | stormwood__glowmoss_hollows__03__the_lantern_pools__day__approach | 18.0 | 7.6 |
| 2 | stormwood__glowmoss_hollows__03__the_lantern_pools__day__close | 13.2 | 9.5 |
| 3 | stormwood__glowmoss_hollows__03__the_lantern_pools__night__approach | 18.3 | 7.9 |
| 4 | stormwood__glowmoss_hollows__03__the_lantern_pools__night__close | 13.7 | 9.8 |
| 5 | stormwood__glowmoss_hollows__04__crown_overlook__day__approach | 23.0 | 14.8 |
| 6 | stormwood__glowmoss_hollows__04__crown_overlook__day__close | 9.5 | 5.9 |
| 7 | stormwood__glowmoss_hollows__04__crown_overlook__night__approach | 22.7 | 14.7 |
| 8 | stormwood__glowmoss_hollows__04__crown_overlook__night__close | 9.5 | 5.9 |
| 9 | stormwood__hollow_crown__08__the_crown_heartstone__day__approach | 26.7 | 18.0 |
| 10 | stormwood__hollow_crown__08__the_crown_heartstone__day__close | 38.6 | 47.8 |
| 11 | stormwood__hollow_crown__08__the_crown_heartstone__night__approach | 26.4 | 17.8 |
| 12 | stormwood__hollow_crown__08__the_crown_heartstone__night__close | 32.9 | 41.6 |

Manifest clock: day frames 08:00, night frames 23:00 (requested times reached); all frames weather phase `calm`.

## Follow-up (coordinator review, 12:16 PM CT)

| Sheet | A (left) = BEFORE | B (right) = AFTER |
|---|---|---|
| sheet-3-candidate-heartstone-lamp-low-compat.jpg | none (candidate only) | de7e24d93df54c6fb3ae3915a10699c875170bbb, run 38153815266 |
| sheet-4-heartstone-landmark-low-compat.jpg | 9e39d0086ee88998b8295747fc19f6603fe714f7 (main), run 38155917837 | de7e24d93df54c6fb3ae3915a10699c875170bbb, run 38153815266 |

No new render: sheets 3 and 4 use the `stormwood__landmark__crown_heartstone__*` frames that every run already captured (left off sheets 1–2). Same command and seed, so a re-run would reproduce the same views.

Sheet 4 ground band (bottom 30%) mean luma: A 28.1, B 18.6. Pairs: day approach 26.7/17.6, night approach 26.7/17.6, day close 29.6/19.6, night close 29.6/19.6.

1. Night: `--times=night` takes effect in the capture tool. Manifest clock is 23:00 for every night frame, and the same tool in Meadows (P2-006 candidate run 38156433591, also Low/Compatibility) darkens frame mean luma from about 101–114 (day) to about 22–26 (night). In Stormwood the day and night frames differ by ≤0.1 mean luma at every stand on all three SHAs, so Stormwood's scene lighting does not respond to the clock in this capture path. It is not a tool failure. The coordinator confirms this is intended: ART_DIRECTION holds Stormwood at a fixed purple storm with no day/night, so this is not a defect.
2. Heartstone lamp: no option of `phase2_capture_locations.gd` (subset/times/views/character/seed) frames the heartstone itself. Neither the catalogue stand (place 08, 50 m west, heading 76.5°) nor the landmark stand shows a heartstone body. The landmark close stand does frame two lamps with the ground around them (sheet 3 crops). Their ground-patch luma is identical day and night: about 32 under the lectern lamp and 31 under the left lamp post.
3. Place 08 `close` (sheet 1/2 pairs 10 and 12) puts the camera inside a wild bear body on every SHA. The landmark stand (sheets 3–4) has no bear occlusion.
