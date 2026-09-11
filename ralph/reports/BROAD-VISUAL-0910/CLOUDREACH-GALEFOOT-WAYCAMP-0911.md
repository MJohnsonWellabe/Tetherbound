# Galefoot Waycamp — named-location pass (2026-09-11)

## Disposition

Implementation-lane grade: **KEEP / POLISH**. The production frame is materially cleaner and more legible than the current-head baseline, but this is not represented as an independent commercial-pass receipt. The primary approach is a strong keep; the secondary commons view still needs a future authored landmark/signature pass to become character-quality rather than a clean generic settlement.

## What changed

- Moved the two authored two-creature roadside pairs out of Galefoot's 28 m safe commons, while preserving their table, count, scatter radius, and visibility on the incoming and outgoing roads.
- Added a visual-only communal hearth group, two human-scale seats, warm night light, supplies, and a sagged seven-bulb line to the production settlement.
- Corrected the lantern cable construction after the first render exposed disconnected-looking segments.
- Moved the named-location catalogue arrival from the crowded camp centre to a verified, unobstructed grass approach with an authored heading.
- No new collision, navigation blocker, gameplay radius, FOV override, or progression bypass was introduced.

## Production evidence

Accepted technical receipt: `shots/locations/cloudreach-galefoot-waycamp-0911-r3/`

- `galefoot-waycamp-overview-day.png`
- `galefoot-waycamp-overview-night.png`
- `galefoot-waycamp-hearth-day.png`
- `galefoot-waycamp-hearth-night.png`
- `manifest.json`: complete `4/4`, failures `[]`, 1280x800, production scene/player/HUD/CameraRig/WorldLook, 70 degree FOV, `camp_wildlife_within_31m: 0` in every retained frame.

The r1/r2 directories are explicitly rejected iteration evidence: r1 had an invalid outer stand; r2 exposed an eave-clipped overview and avatar-hidden hearth. They are not the receipt.

## Visual read

- Primary/overview: **KEEP / POLISH**. The former pair of oversized creatures no longer owns the frame or collides with the HUD. The cottage lane, trainer silhouette, path, and inhabited props read cleanly day and night.
- Secondary/hearth: **POLISH**. It verifies the clean commons and warm overhead dressing, but the player-centred third-person composition still under-sells the hearth itself. This is usable production evidence, not a claim that Galefoot has a singular hero landmark yet.
- Incidental defect fixed: the previous debug arrival was inside the settlement/creature crowding. The retained arrival is on known production ground and no longer clips the cottage or vegetation.

## Verification

- `test_cloudreach_galefoot_waycamp.gd`: 4 tests, 30 assertions, 0 failed.
- `test_cloudreach_encounters.gd`: 3 tests, 3159 assertions, 0 failed.
- `test_four_biome_debug_teleport.gd`: 8 tests, 1047 assertions, 0 failed.
- Production capture booted the full Cloudreach world and completed 4/4. The pre-existing `cr_candy_broken_route_good_07` missing-surface warning remained unchanged and is outside this location.

