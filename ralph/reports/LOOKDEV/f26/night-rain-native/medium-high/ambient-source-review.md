# Night-rain ambient source review

**Assessment: applying the existing rain/night-weight color blend to `ambient_colour` is a justified narrow follow-up.** This approves the source rationale only; no source patch or runtime validation occurred in this review.

## Evidence and residual behavior

The supplied [travel observation](D:/tetherbound/redesign-lookdev/ralph/reports/LOOKDEV/f26/night-rain-native/medium-high/travel-plaster-observation.md) and [pixel record](D:/tetherbound/redesign-lookdev/ralph/reports/LOOKDEV/f26/night-rain-native/medium-high/travel-plaster-observation.json) describe the first matched travel block at 23:00: the same upper-plaster ROI has weighted sRGB luma 138.183 clear versus 159.525 rain on Medium (+15.44%), and 137.587 versus 158.341 on High (+15.08%). The internally matched poses are supplied review evidence, not a fresh image judgment here. These statistics describe rendered pixels, not physical luminance or an isolated ambient contribution. The native run failed before the doorway block.

The existing [sky weather branch](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:584) preserves the time-derived night palette for three sky colors, but [the ambient override](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:599) still replaces the time-derived ambient color unconditionally. [weather.json](D:/tetherbound/redesign-lookdev/data/config/weather.json:73) supplies rain's `ambient_energy_mult=0.85` and `ambient_colour=#7e8fa0`. [art.json](D:/tetherbound/redesign-lookdev/data/config/art.json:393) authors night ambient as `#3d50a3`; its night ambient energy is 1.5. Thus the current rain result uses energy 1.275 with the rain color instead of retaining the authored night color. This is a concrete residual palette replacement; the pixel evidence alone does not prove it caused all of the observed brightness difference.

## Narrow proposed semantics

For an existing ambient-color override, reuse the sky branch's condition: rain is true and `night_weight > 0`. Let `R` be the rain color, `T` the already time-derived ambient color, and `w` the clamped night weight. Assign `R.lerp(T, w)`; otherwise retain the exact existing override assignment. This gives the prior daytime rain value and type at weight zero, the authored time color at weight one, and a continuous transition between them. Keep ambient energy, fog, sun, sky, exposure, and all other assignments unchanged. Non-rain weather and empty weather keep their existing behavior.

The existing color conversion supports both hex strings and `Color` values ([world_look.gd](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:877)); the environment consumer uses that conversion at [line 1180](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:1180). No new color representation or clock control is needed.

## Clock and reapplication checks

- [Named application](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:525) derives fresh time dictionaries and passes the named weight. `night` and the current direct `same_as: night` alias `night_end` both yield one; named day/golden/dawn yield zero. Unknown names retain the existing fallback behavior.
- [Clock application](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:797) passes the same from/to/t bracket that produced the palette. Golden-to-night weight rises with t, night-to-night_end stays one, and night_end-to-dawn falls with t. Ambient is already a blended color key at line 824. The additional rain blend is continuous but is not necessarily linear in clock t, because its target is itself time-blended; this matches the existing sky approach.
- [Weather changes](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:553) and [look reapplication](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:432) use the live clock blend when a cycle exists. They do not snap to a named hour. The no-cycle path retains the existing named application behavior.
- [Fresh merging](D:/tetherbound/redesign-lookdev/scripts/world/world_look.gd:650) duplicates base configuration, and the clock path constructs fresh blended dictionaries at line 723. Repeating these public application paths at the same hour/weather therefore recomputes the same result without accumulating color or energy changes. `_layer_weather` itself is not idempotent if called repeatedly on an already-layered dictionary; the follow-up must retain the existing one-layer-per-fresh-result call pattern.

## Limits

Bounded source and supplied evidence reads only: no engine, Blender, tests, new tooling, source patch, or Git mutation. Local lights, sky contribution, renderer response, exposure, and tonemapping are not isolated. A follow-up must still be checked in matched native views. Full sky, facade, doorway, interior lighting balance, performance, and full art acceptance remain **OPEN**.
