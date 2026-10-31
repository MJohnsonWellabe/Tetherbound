# World dressing lane: running result

Lane: tb/world-dressing (coordinator start, 31 Oct 2026). Scene dressing from installed asset families and the coordinator's Meshy batch (tb/props-r2 31592e46, a2f81b50), every change behind a flag-off key.

## Setup
- Container: 19 GB free. Godot 4.7-stable installed from the CI URL; first `--import` about 2 h on this container.
- Captures: CPU llvmpipe, Compatibility, 1280x720, the job.json repro tools with their own arguments (one boot per biome per tool, several `--subset`s). Baselines run on this branch with every new flag OFF (same behaviour as main d4d5b262).
- Harness notes (added to the runbook list on landing): `phase2_capture_tidewake_camps.gd` and `phase2_capture_cloudreach_high_perch.gd` refuse output outside `ralph/reports/VISUAL/phase2/<biome>/`; stage there and move to `.artifacts/`. `pkill -f <pattern>` from a shell containing the pattern kills the shell (exit 144), as TECHNICAL 8.1 warns.

## Items and candidates (GPU mapped score of record; all keys OFF on this branch)
| Item | Biome | GPU | Candidate key | What it does |
|---|---|---|---|---|
| P2-070 Glass Sink | Stormwood | 3.19 | stormwood_glass_sink.json `meshy_rim` | Meshy rim markers on the Hollow Crown lip in the reachable view, two scaled rings on the sink floor |
| P2-041 Crown Arch | Stormwood | 4.23 | crown_arch_hero.json | Meshy hero arch 5.5 m; old piece and slab mesh hidden; passage, trigger, axis, placement unchanged |
| P2-038 named destinations | Stormwood | 4.54 | stormwood_lantern_pools.json `arrival_pools` | two pools in the Lantern Pools arrival view, Meshy lantern posts |
| P2-115 camp creature bed | Tidewake | 4.59 | meshy_camp_props.json `bed` | Meshy log-ringed straw nest at forward camps and authored camp beds |
| P2-116 camp workbench | Tidewake | 4.71 | meshy_camp_props.json `workbench` | Meshy workbench with lantern post, 2.3 m |
| P2-011 named destinations | Tidewake | 4.85 | tidewake_destination_read.json | drift arch 8.5 m; signal lantern on the Gull Rest platform with researcher props; drowned terrace walls in the shallows |
| P2-046 harvest resources | Stormwood | 4.99 | stormwood_harvests.json `material_cues.*.hero` | Meshy glass-scar crystals for stormglass/crown; glowing storm fungi and teal moss for glowmoss |
| P2-043 Glass Field spikes | Stormwood | 5.15 | stormwood_glass_field.json `meshy_spikes` | Meshy spike clusters per scar, varied scale and yaw |
| P2-034 harvest rewards | Meadows | 5.47 | pickup_grounding.json | find-stone, contact shadow, pebbles, size step |
| P2-033 ground pickups | Meadows | 5.52 | pickup_grounding.json | same |
| P2-045 candy tiers | Stormwood | 5.63 | pickup_grounding.json | size 2.5, find-stone, shadow |
| P2-035 camp props | Meadows | 5.85 | band1 props.json trail_camp `camp_floor` | trodden-earth floor, grass cleared, larger fire and ring |
| P2-102 rim mushroom | Cloudreach | 5.90 | (pending perch baseline) | |
| P2-024 landmark read | Cloudreach | 6.14 | cloudreach_f40_items.json last candidate | Meshy eagle plinths flank the arch, strata spire clusters frame the approach |
| P2-054 mushrooms | Cloudreach | 6.48 | pickup_grounding.json | size 1.45, shadow, pebbles |
| P2-094 placed wall | Meadows | 6.65 | build_wall_interior.json `meshy_wall.r8` | half-sunk fieldstone plinth, grime band, base tufts |

## Arms
None pushed yet: candidate captures queued, then three-judge CPU batches.
