# Stormwood nine: installed-source audio assets

Owner decision 2026-10-05 (STATE open-decision 5): author the nine missing
`assets/audio/stormwood/*.wav` from sound sources already installed in the
repository (AUDIO §10). No purchase, no new third-party download, no
text-to-audio service. Acceptance is spectral and loop checks; no owner listen.

## The nine files (all referenced by `data/config/stormwood_audio.json`, read by `scripts/world/stormwood_surge_audio.gd`)

| file | cue id | bus / mode | AUDIO §4.3 role | built from (installed) |
|---|---|---|---|---|
| surge_calm_bed.wav | sw_surge_calm_bed | Ambience, loop, 22050 Hz mono, 24 s | Calm: rain/drip, low moss/forest life, distant thunder with long spacing | river_water, ironwood_canopy, night_insects + synth drips/thunder |
| surge_building_bed.wav | sw_surge_building_bed | Ambience, loop | Building: copper-vine ticks, canopy motion, rising electrical bed; no birds, no strike | ironwood_canopy, wind_high, tether_drone + synth ticks/hum/crackle |
| surge_break_bed.wav | sw_surge_break_bed | Ambience, loop | Break bed under the strike chain | river_water, wind_low, wind_high, tether_drone + synth rain/crackle/thunder |
| surge_fading_decay.wav | sw_surge_fading_decay | Ambience, loop | Fading: steam, glass, low rolling thunder decay, afterglow | wind_high, tether_drone + synth glass/thunder/drips |
| release_forest_sky_bed.wav | sw_release_forest_sky_bed | Ambience, loop | Stormheart release: ordinary forest/sky, no rod-line bed | meadow_birds, ironwood_canopy, wind_high + synth drips |
| strike_warning.wav | sw_strike_warning | SFX, positional one-shot, 44100 Hz mono, 1.20 s | spatial 1.2 s warning (= `strike.telegraph_seconds`) | tether_drone (varispeed) + synth whine/crackle/sizzle |
| strike_crack.wav | sw_strike_crack | SFX, positional one-shot, 0.70 s | strike layer | impact_super_1, mine_stone_2 + synth crack |
| strike_body.wav | sw_strike_body | SFX, positional one-shot, 1.80 s | body layer | build_place_thud_1, impact_super_2 + synth boom/sub |
| strike_decay.wav | sw_strike_decay | SFX, positional one-shot, 5.00 s | decay layer | wind_low + synth rolling thunder |

Every installed source is itself original synthesis by `tools/audio/` (archive
ASSET_LEDGER, Meadows soundscape row), so no third-party licence attaches.
Per-asset sources with SHA-256, every processing step, seed and output hash:
`MANIFEST.json` (copy of `assets/audio/stormwood/MANIFEST.json`).

Format follows the installed set: 16-bit mono PCM; beds at the ambience rate
22050 Hz with a `smpl` whole-clip forward loop (Godot imports LOOP_FORWARD),
strike layers at the sfx rate 44100 Hz, mono because positional.

## Results

- `checks.md` / `checks.json` / `check_stormwood.txt`: **94/94 pass**. No
  clipping (peak <= -0.5 dBFS, zero full-scale samples), DC, format, loop chunk;
  seam (wrap step under interior p99.9 step, RMS across wrap within 3 dB,
  spectral flux at wrap under interior p99); bed loudness within ±6 LU of the
  installed ambience layers (no Tidewake/Cloudreach beds exist in
  `assets/audio/`, so the eight installed ambience layers plus five music loops
  are the comparison set); strike loudness within ±8 LU of `impact_super_*`;
  Surge phases pairwise distinct by centroid (>= 150 Hz) and energy (>= 1.5 dB),
  energy Calm < Building < Break > Fading; Building has copper-tick onsets
  (5.2/s vs 0 in Calm) and a 90-210 Hz electrical share 13x Calm; Release has
  < half Break's 80-220 Hz share; crack attack 2.8 ms, centroid ~11.7 kHz;
  body/decay >= 0.9 energy below 250 Hz; chain = transient + low tail; warning
  rises 11.7 dB and lasts the telegraph; every asset >= 2 dB mean third-octave
  shape gap from the other eight and from every installed bed/music loop.
- `test_stormwood_audio_assets.txt`: headless Godot 4.7, all nine contract paths
  load as mono AudioStreamWAV; beds LOOP_FORWARD, strikes LOOP_DISABLED; warning
  length = telegraph. 2 tests, 48 assertions, 0 failed.
- `smoke_stormwood_surge_audio.txt`, `cue_timeline.md`, `MISSING_ASSETS.md`:
  production Stormwood world, real Surge clock and host lightning. 20 passed,
  0 failed; 85 of 85 fired cues found their asset and started a player;
  MISSING ASSETS (0). Headless uses the dummy audio driver: this proves load
  and playback start, not what was heard.

Not proven here: in-game mix against music/other buses, Ally speakers, blinded
listener identification (AUDIO §12 #3). The rod-area pressure layer, arches and
Dynamo cues remain unwired (`not_in_this_witness` in the contract).

## Commands

```
pip install numpy pyloudnorm                     # tool-time only
python3 tools/audio/gen_stormwood.py             # deterministic: re-run is byte-identical
python3 tools/audio/check_stormwood.py --out ralph/reports/AUDIO/stormwood-nine
godot --headless --path . --import
godot --headless --path . --script tests/run_tests.gd -- --only=stormwood_audio_assets
godot --headless --path . --script tests/smoke_stormwood_surge_audio.gd
```
