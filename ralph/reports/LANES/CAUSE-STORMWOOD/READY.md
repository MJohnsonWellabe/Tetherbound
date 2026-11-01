# CAUSE-STORMWOOD: summary (lane stop, 1 Nov ~22:00 UTC)

**State:**
- All four parts of the cause are built as flag-off candidates and listed in `MANIFEST.json`, group 1, 65 entries. Every Stormwood catalogue item a flag visibly changes has an entry.
- Pushed on `tb/cause-stormwood`, branched from `tb/land-vis-2`. PR #792 is still open, so `origin/main` has not been merged in yet. Merge it once #792 lands.

**Suggested GPU arm:**
- Turn all four flags ON, plus `stormwood_look.json:light_pass_1101` and `stormwood_ground_finish.json:value_lift_candidate`.
- Then split the arms if the gain is mixed.

**Checks:**
- `tests/test_cause_stormwood_candidates.gd`: 10 of 10 pass headless in this container.
- All shaders compile on Compatibility (opengl3, llvmpipe). The check was validated with a deliberately broken shader, which failed as expected.
- Tuning is from scratch-scene renders, not the game (`_sheet_scratch_ab.jpg`):
  - The first sky values washed out and were darkened.
  - The rain needed wider, fainter streaks before the soft edge showed.

**Blocked:**
- No in-game CPU capture. The container has 0.9 GB free with a 20 GB `.git`, so a full import does not fit, and trimming the pack was refused.
- No Forward+ compile check.

**Open ideas, not built:**
- A held distant-bolt glow in Calm. I held it back because P2-042 needs Calm and Break to stay distinct.
- A rim on dark uniformed NPCs (P2-056). That belongs to `stormwood_character_rim.json`, another lane's candidate.

**Runbook additions:**
- Without an import, `godot --headless --path . --script tests/run_tests.gd -- --only=<file>` still runs tests whose preloads are scripts or JSON only. Move pure helpers out of asset-preloading scripts (for example `stormheart_deck_light.gd`) so their tests run anywhere.
- To compile-check a shader, set it on a material under xvfb with opengl3 and grep for `SHADER ERROR`. The "shader type not supported" lines are noise.
- The headless dummy renderer keeps no MultiMesh instance buffer, so tests cannot read instance transforms back.

## Group 1 detail

The cause is Stormwood (F41) storm light and ground. There are four flag-off candidates, each with its own switch; all of them compose with each other and with the queued `stormwood_look.json:light_pass_1101` (group 5) and `stormwood_ground_finish.json:value_lift_candidate` (group 6). The suggested GPU arm is all four ON on top of those two.

| Flag | What it changes |
|---|---|
| `stormwood_surge.json:presentation.storm_sky_1101.enabled` | Storm sky and light. The ceiling gains cloud form (contrast, definition, lit rims, thin-spot glow) and faint white-violet sheet glow in Calm. The sun and ambient cuts ease in every phase, so values lift. The parked skyline (r22) and depth fog (r34) switch on. Cheap additive light shafts (`stormwood_storm_shafts.gd`, one MultiMesh) fall on a world grid. |
| `stormwood_surge.json:presentation.soft_rain_1101.enabled` | Rain streaks are soft-edged (view-facing fade across their width), longer, denser and lilac-grey instead of white. |
| `stormwood_ground_finish.json:moss_variation_1101.enabled` | Cover-tier shader: a world-space olive/sage/copper moss field, lifted value, sparse clearings to the loam and pools, and rare copper and stormglass flecks. |
| `stormheart_presentation.json:deck_light_1101.enabled` | Hollow and Captain Marrow deck: warm lantern pools (3 on the OuterWorks lip, 4 on the DynamoCore deck), a cool crown spot light, two fixed light-shaft columns under the crown opening, and more board-to-board plank tone. |

**Checks run here:**
- `tests/test_cause_stormwood_candidates.gd`: 10 of 10 pass in this container.
- Parse checks pass, with stubbed preloads for the files that need them.
- All three shaders compile on Compatibility (opengl3, llvmpipe).

**Not run:**
- No CPU capture. The container has 0.9 GB free with a 20 GB `.git`, and a full import does not fit (trimming the pack was refused).
- No Forward+ compile check.

Nothing here touches a scatter or terrain bake input.
