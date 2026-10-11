# F10#5 Stormwood Surge audio: in-scene playback witness

Run Sun 11 Oct 2026, about 4:46 PM CT, by the captures lane. Source tb/ev-captures `d605da7b3b` (tb/ev-coordinator merged). Local Linux, Godot 4.7-stable, headless, `--audio-driver Dummy`.

- **Command:** `godot --headless --path . --script res://tests/smoke_stormwood_surge_audio.gd` (the existing smoke: production Stormwood world, real Surge clock and host lightning, the realm's StormwoodSurgeAudio node). No audio was authored or changed; the nine cues are the existing `assets/audio/stormwood/*.wav` (#540).
- **Result:** `STORMWOOD SURGE AUDIO WITNESS OK: 20 passed, 0 failed`; MISSING ASSETS (0); **89 of 89 fired cues started a player.**
- **Per cue** (`played=true` on every firing; from `cue_log.json`, timeline in `cue_timeline.md`):
  - sw_surge_calm_bed: fired 1, played true (calm)
  - sw_surge_building_bed: fired 1, played true (building, Surge clock 240.0 s)
  - sw_surge_break_bed: fired 1, played true (break, 330.0 s)
  - sw_strike_warning: fired 21, played true (break; 1.20 s before each strike, at the strike's ground position)
  - sw_strike_crack: fired 21, played true (break)
  - sw_strike_body: fired 21, played true (break)
  - sw_strike_decay: fired 21, played true (break)
  - sw_surge_fading_decay: fired 1, played true (fading, 450.0 s)
  - sw_release_forest_sky_bed: fired 1, played true (release)
- **Scope:** wiring, timing and playback start only. What the cues sound like is checked offline (`tools/audio/check_stormwood.py`, ralph/reports/AUDIO/stormwood-nine/). Under the Dummy driver nothing is heard; `played` means the asset loaded and a pool player started it.
- **Disclosed fixtures (the smoke's own):** the trainer is pinned on exposed ground with health refilled; the Surge clock is set a few seconds before each phase boundary; the Long Storm's end is committed through the ledger.
