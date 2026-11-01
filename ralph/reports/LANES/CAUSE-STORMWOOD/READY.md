# CAUSE-STORMWOOD: ready for the GPU (group 1)

The cause is Stormwood (F41) storm light and ground. There are four flag-off candidates, each with its own switch; all of them compose with each other and with the queued `stormwood_look.json:light_pass_1101` (group 5) and `stormwood_ground_finish.json:value_lift_candidate` (group 6). The suggested GPU arm is all four ON on top of those two.

| Flag | What it changes |
|---|---|
| `stormwood_surge.json:presentation.storm_sky_1101.enabled` | Storm sky and light. The ceiling gains cloud form (contrast, definition, lit rims, thin-spot glow) and faint white-violet sheet glow in Calm. The sun and ambient cuts ease in every phase, so values lift. The parked skyline (r22) and depth fog (r34) switch on. Cheap additive light shafts (`stormwood_storm_shafts.gd`, one MultiMesh) fall on a world grid. |
| `stormwood_surge.json:presentation.soft_rain_1101.enabled` | Rain streaks are soft-edged (view-facing fade across their width), longer, denser and lilac-grey instead of white. |
| `stormwood_ground_finish.json:moss_variation_1101.enabled` | Cover-tier shader: a world-space olive/sage/copper moss field, lifted value, sparse clearings to the loam and pools, and rare copper and stormglass flecks. |
| `stormheart_presentation.json:deck_light_1101.enabled` | Hollow and Captain Marrow deck: warm lantern pools (3 on the OuterWorks lip, 4 on the DynamoCore deck), a cool crown spot light into the hollow, and more board-to-board plank tone. |

**Checks run here:**
- `tests/test_cause_stormwood_candidates.gd`: 8 of 9 pass in this container. The deck test needs an imported tree, because `stormheart_tree.gd` preloads glTF files.
- Parse checks pass, with stubbed preloads for the files that need them.
- All three shaders compile on Compatibility (opengl3, llvmpipe).

**Not run:**
- No CPU capture. The container has 0.9 GB free with a 20 GB `.git`, and a full import does not fit (trimming the pack was refused).
- No Forward+ compile check.

Nothing here touches a scatter or terrain bake input.
