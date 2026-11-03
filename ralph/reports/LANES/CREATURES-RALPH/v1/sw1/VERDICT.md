# Visual lane v1/sw1: Stormwood items, CPU A/B (3 Nov 2026, ~04:40 UTC)

**Yardstick:** CPU llvmpipe, Compatibility, 1920x1080 frames from each item's `VISUAL/item-scores/job.json` repro launch. Base = this branch (`f96f62a0`), candidate = the same launches with the Stormwood OFF arms temporarily ON (`stormwood_character_rim`, `npc_role_accessories`, `camfx.fight_fade`, `camfx.dialogue_open`, `hero_landmarks_1101.crown_arch`/`glass_sink`, `stormwood_glass_sink.dark_pool_candidate`, `stormwood_road_current.puddle_candidate`, `stormwood_harvest_hero2`, `pickup_grounding.tier_candidate`, `stormheart_presentation.hollow_floor`/`deck_light_1101`, `stormwood_lantern_pools.arrival_pools`). Standard JUDGE_PROMPT verbatim, 3 anchor pairs (craft, f36_0_gap:C7, f36_0_npc:C8; top anchor 7.35, confirming batch), three fresh code-blind judges, `calibrate.py`: linear, slope 1.38, intercept -2.02, r 0.87, anchor RMSE 0.42, no warnings.

| Board row | Item | CPU base -> arms ON (mapped) | Raw base / ON | Defect call | Decision |
|---|---|---|---|---|---|
| F41#4 | P2-038 named destinations | **5.25** -> 5.21 | 5.0 5.1 5.6 / 5.2 5.3 5.3 | PRESENT/PARTIAL | arms OFF |
| F41#2 | P2-042 Surge phases | **5.02** -> 4.93 | 5.0 5.1 5.2 / 4.9 5.0 5.2 | PRESENT 2, PARTIAL 1 | arms OFF |
| F41#5 | P2-039 forest ground and distance | **4.75** -> 4.70 | 4.9 5.0 4.8 / 4.8 4.9 4.9 | PRESENT 3 | arms OFF |
| F41#17 | P2-041 Crown Arch | **4.70** -> 4.56 | 4.8 4.4 5.4 / 4.5 4.6 5.2 | PARTIAL 3 | `crown_arch` OFF (judges prefer the shipped blue pillar) |
| F41#1 | P2-037 Stormheart finale | **4.52** -> 4.33 | 4.4 4.4 5.0 / 4.4 4.6 5.0 | PRESENT 3 | arms OFF |

These are the first CPU scores of the current branch for these rows; all five stay under 6.0.

**What the judges said (all three agree):**
- `stormwood_road_current.puddle_candidate` draws "flat lavender puddle discs that read as decals" on the path in every candidate frame. It costs every row a little. Keep OFF.
- **Crown Arch:** both sides are "a lone pillar on an exposed square slab, not an arch". Needs new art: a real two-pillar arch with a spanning crown, seated into the moss with no slab.
- **Stormheart:** both stands are inside the walled outer ring under the plank ceiling ("a roofed arena"); no trunk, crown or core reads. Needs new art and a stand outside the ring; the catalogue stands are fixed, so the tree has to read from where they stand.
- **Surge phases:** Calm, Building and Fading frames are "practically identical"; only Break's lightning differs. A scene fix (per-phase grade, fog and cloud).
- **Forest ground:** "uniform teal carpet, evenly spaced single trees, flat lavender haze"; asks for groves, clearings, black pools and layered distant silhouettes (scene).

Per-judge JSON, key, spec, batch and mapping are beside this file.
