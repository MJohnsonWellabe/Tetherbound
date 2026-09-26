# Stormwood Surge audio: missing assets

Every cue in `data/config/stormwood_audio.json` whose intended asset does not exist. None was generated, synthesized or copied in. The observer plays each cue automatically once its file lands at this path.

| asset path | cue | bus | positional | fired in witness | AUDIO §4.3 row |
|---|---|---|---|---:|---|
| `res://assets/audio/stormwood/surge_calm_bed.wav` | `sw_surge_calm_bed` | Ambience | false | 1 | §4.3 Calm, 240 s baseline: rain/drip and low moss/forest life; distant thunder with long spacing |
| `res://assets/audio/stormwood/surge_building_bed.wav` | `sw_surge_building_bed` | Ambience | false | 1 | §4.3 Building, 90 s: copper-vine ticks, increasing canopy motion and rising electrical bed; birds/insects fall away; no strike yet |
| `res://assets/audio/stormwood/surge_break_bed.wav` | `sw_surge_break_bed` | Ambience | false | 1 | §4.3 Break, 120 s: the Break bed under the strike chain; rhythm follows the authored 4-8 s strike spacing |
| `res://assets/audio/stormwood/surge_fading_decay.wav` | `sw_surge_fading_decay` | Ambience | false | 1 | §4.3 Fading, 60 s: strike density stops; steam, glass and low rolling thunder decay; charged nodes/afterglow remain audible locally |
| `res://assets/audio/stormwood/release_forest_sky_bed.wav` | `sw_release_forest_sky_bed` | Ambience | false | 1 | §4.3 Stormheart release: removes the oppressive rod-line bed and opens ordinary forest/sky sound; it does not leave the same loop under brighter lighting |
| `res://assets/audio/stormwood/strike_warning.wav` | `sw_strike_warning` | SFX | true | 17 | §4.3 Break: each strike uses a spatial 1.2 s warning whose direction and ground location are readable |
| `res://assets/audio/stormwood/strike_crack.wav` | `sw_strike_crack` | SFX | true | 17 | §4.3 Break: followed by strike/body/decay layers (strike) |
| `res://assets/audio/stormwood/strike_body.wav` | `sw_strike_body` | SFX | true | 17 | §4.3 Break: followed by strike/body/decay layers (body) |
| `res://assets/audio/stormwood/strike_decay.wav` | `sw_strike_decay` | SFX | true | 17 | §4.3 Break: followed by strike/body/decay layers (decay) |
