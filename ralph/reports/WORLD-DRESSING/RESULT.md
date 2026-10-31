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

## Arms (GPU verdict is the score of record)
- **WD1** `tb/world-1-on` 0d7458fe: P2-041, P2-070, P2-046, P2-045, P2-043, P2-033 at round-1 values. CPU b1 gains +1.75, +1.55, +1.40, +0.91, +0.56, +0.56 (`b1/VERDICT.md`).
- **WD2** `tb/world-2-on` 1bfc5d09 (supersedes WD1): WD1 at round-2 values plus P2-035 camp floor, P2-115/P2-116 Meshy camp bed and workbench, P2-054 grounding. CPU b2 gains: P2-046 +2.45, P2-041 +2.18, P2-070 +2.18, P2-115 +1.30, P2-043 +1.25, P2-116 +0.82, P2-035 +0.76, P2-054 +0.65 (`b2/VERDICT.md`).
- Both arm requests are appended to `ralph/reports/GPU-PASS/NOTE.md` on this branch, each listing its JSON flags so the GPU can judge on one imported tree.
- No CPU candidate reaches 7.5 mapped; the best is P2-035 at 6.96. CPU runs about 0.8 below GPU, so the GPU pass decides.

## Parked (stop rule or no >0.5 path with installed assets)
- P2-034 harvest rewards: r1 +0.28, r2 +0.44. The attack tonic node is a tiny glint; needs a hero mesh (new art).
- P2-094 placed wall: r1 -0.12, r2 +0.27. Judges now call it a framed, capped, footed wall; what remains is the lone thin panel and flat infill (new art or a multi-segment build in the capture).
- P2-038 Stormwood destinations: two rounds with no gain. Judges ask for a hero subject per destination (glowing black pools with lanterns at Lantern Pools, a dominant Fallen Giant trunk): new art.
- P2-024 Cloudreach landmarks: r1 0.00. Stone spire clusters read as background; judges ask for landmark-specific hero detail (observatory dome, beacon detail): new art.
- P2-102 rim mushroom: night grade and griffin pose belong to other lanes (see scope changes).

## Meshy candidates noted (no Meshy access here)
- A sunken Glass Sink basin bowl with dark glass walls and black pool water, visible from the rim (all six b1/b2 judges named it).
- A ground-blended Crown Arch footing (root and rubble apron) to replace the 9x9 m square slab look; the footing collider stays.
- A hero attack-tonic pickup and a Fallen Giant hero trunk.

## Scope changes
- 31 Oct, coordinator (owner feedback): P2-011 Tidewake named destinations moved to a new Tidewake lane (declutter plus a Meshy beach focal piece). Dropped here: `tidewake_destination_read.json` stays OFF and is not for landing; no further Tidewake location dressing from this lane. CPU r1 notes for that lane: the 8.5 m drift arch read much stronger; the shallow-water terrace walls showed a blank back face. The Tidewake camp bed and workbench (P2-115/P2-116) stay here.
- P2-102 parked without an arm: the night frame's crushed tower is the Cloudreach night grade (chapter lighting) and the griffin wing in the tower is a creature pose (other lanes); installed-asset dressing reaches neither for a >0.5 gain.
