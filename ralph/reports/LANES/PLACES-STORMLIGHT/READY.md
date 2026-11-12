STATUS: land

# READY: storm_phase_1111 + distinct_bodies_1111 ON (LANE-PLACES, 12 Nov 2026)

Branch `tb/places-stormlight-land`, cut from main 4e35bfbd.

## Verdict
GPU High, `G-places-stormlight.md` (tb/item-scout-1108 6ece0b6f), three code-blind judges, confirming batch: **SHIP**.
- F41#2 Surge phases 5.17 → 5.97 (+0.80, 3/3).
- F41#8 named silhouettes 5.22 → 5.80 (+0.58, 3/3), with distinct bodies.
- F41#13 +0.23 (3/3), riding.
- F41#6, #12, #19 identical; F41#4 and #5 within 0.05. No row drops; no Glass Field glare.
- The batch reads about 0.9 below board values; the gains are within-batch. Closes no row.

## What lands
- `data/config/stormwood_surge.json`: `presentation.storm_phase_1111` ON with `_why_on`.
- `data/config/stormwood_npcs.json`: `distinct_bodies_1111` ON with `_why_on`; `character_appearance_variants.json` gains `meshy_f41_8_bryn_teal`.
- Code: `stormwood_surge.gd` (layered ceiling, bolt halo, bolt key light, far bolts), `stormwood_surge_rules.gd`, new `stormwood_fog_layers.gd`, `stormwood_storm_shafts.gd` (`follow_camera`), `stormwood_chapter.gd` (`distinct_bodies`).
- Art: Bryn's teal albedo and portrait with their import sidecars (LANE-MESHY, `MESHY-F41-8-BODIES/`).
- Flag-OFF and inert: the Cloudreach `rain_time_grade` (`cloudreach_weather.gd`, `cloudreach_visual.json`); its arm is on the GPU queue (`PLACES-RAINTIME/`).
- No scatter bake input changed. No save, strike, phase timing or shelter change.

## One older rule changed: please accept or tell me to strip it
`tests/test_stormwood_surge_presentation.gd::test_only_break_shows_sky_lightning` (F10#3) pinned that no phase but Break shows any sky lightning. The judged arm gives Building slow, faint far-horizon bolts (`far_bolts`). The test now allows exactly that: in Building, far bolts only, never at Break's full level, never in the aftermath; Calm, Fading and the aftermath still show none. Far bolts are held during a ground warning and count in the flash budget. To strip instead, set `phases.building.far_bolts` to 0 in the overlay (that differs from the judged frames).

## Tests
`--only=stormwood,surge,appearance,places_storm,cloudreach_rain,portrait,npc`: 628 tests, 0 failed, with the flags ON.
Pins: `tests/test_places_storm_phase_rain_grade.gd` (ships ON with its verdict; phase order; far bolts; halo; mist cap; rain grade OFF) and `tests/test_stormwood_distinct_bodies.gd`.

## Still holding the rows back (judges, for the next swing)
Stormwood ground and road value (near-black mud with hard cut-out edges, flat carpet with blotches, one flat treeline band); Fading too close to Building; the F41#19 stand (a trunk fills half the frame); Stormraven needs new art; a beige patch under Voltarach; salmon bears.
