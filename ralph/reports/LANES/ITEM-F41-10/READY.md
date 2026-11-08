STATUS: parked
BRANCH: tb/item-f41-10  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, F41#10 P2-070 Glass Sink landmark (coordinator queue 8 Nov). **Nothing ships ON.**

## Diagnosis (main 972670fa, `qj/F41-10-base`)
- The sink floor fills the right half of every frame. It is a dark navy plane with only faint plates, nothing standing on it, and a straight cliff edge, so it reads as a void or lake.
- The ring and copper rim already exist.
- The cameras stand on the island about **140 m above the sink floor** (`terrain_stormwood.json` island_y 74, floor_y -65). Only floor beyond about 300 m is in frame.

## Arm (flag-off, on this branch)
- `stormwood_glass_sink.json meshy_rim.shards`: 11 installed glass-spike clusters (meshy-1031 glass_spikes, meshy-1024 stormwood_glass_scar_crystals) stand on the floor 300-530 m out, 25-49 m across, with the rim glow.
  - v1/v2 (16 clusters at the cliff foot) were out of view.
  - v1 also had a per-entry model-lookup bug, now fixed in `dress()`.
- `stormwood_glass_sink.json fused_glass` (coordinator addition): the terrain patch samples the installed stylised `rock_scree_Color` at about 60 m and 240 m tiles to mottle the glass body, and the brighter mottles keep a glossy sheen past the far fade. The uniforms default off.
- Visibility (`_sheet_visibility_v3.jpg`, `_sheet_visibility_v4.jpg`): v4 changes 11% / 2.4% / 11% of pixels. No shader errors.
- Tests: test_stormwood_glass_sink_obsidian, test_vis_stormwood_judged_on, test_storm_cams_candidates: 27 tests, 0 failed.

## Round (`qj/F41-10-v4/`, shards plus fused glass together, coordinator)
- Mapped **6.20 -> 6.24 (+0.04)**. Raw 4.9 / 5.3 / 5.5 -> 5.0 / 5.3 / 5.5; only 1 of 3 prefers it (+0.1, two ties).
- Defect PARTIAL on both sides.
- No split check: it did not win.

## Judges' reading (all three)
- "A and B are virtually identical" at sheet scale. The crystals register as "loose glass crystals on the slope" or "scattered decals", but the defect they score is the **form**:
  - a hard, unmarked cliff edge dropping onto a flat dark plane;
  - the ring "sits on a ledge" or "overhangs the edge", reading as a crystal planter rather than a sunken basin;
  - noisy saturated ground texture.
- All three put a **sculpted sinkhole/bowl** (terrain falling in a graded slope into a glass-lined basin) as new_art, their top Glass Sink change.

## Why parked
- Floor dressing and floor material are spent: they are too small or too subtle from 140 m up.
- The remaining defect is the island-to-floor cliff profile (terrain form).
- **Next idea:** a graded slope from the island lip down to the floor in the visible bearing. That is either a Blender bowl lip from installed rock and terrain textures over the existing cliff, or a heightfield slope change, which is a terrain bake with route and collision implications (owner or route check). Not config-scale.

## Files
- `scripts/world/stormwood_glass_sink.gd` (inert while the flags are off)
- `data/config/stormwood_glass_sink.json` (shards and fused_glass both OFF)
- `ralph/reports/LANES/ITEM-F41-10/**`
