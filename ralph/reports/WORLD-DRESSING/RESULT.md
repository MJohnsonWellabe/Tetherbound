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
- **WD1** `tb/world-1-on` 0d7458fe (main a41e1b30 + lane 43c73100 + flags): P2-041, P2-070, P2-046, P2-045, P2-043, P2-033. CPU b1 mapped gains +1.75, +1.55, +1.40, +0.91, +0.56, +0.56 (`b1/VERDICT.md`). Arm request appended to `ralph/reports/GPU-PASS/NOTE.md` on this branch. Waiting on the GPU verdict.

## Round 2 (r2 tweaks committed, flags OFF; captures queued)
- P2-035 (+0.40 r1): ring 1.4x read as a pale blob; ring 1.15x, fire 0.6.
- P2-034 (+0.28 r1): unchanged code; re-judge with the r2 Meadows set.
- P2-094 (-0.12 r1): r8 plinth 0.6 m darker, grime 1.05 m at 0.92, taller tufts.
- P2-038 r1 showed no new pools (flatness limit): per-pool relief 1.2 m.
- P2-115/P2-116: bed reads; bench hidden behind the trainer, turned -39 deg and 2.6 m.
- Arm-1 items get r2 follow-ups judged separately: glowmoss larger fungi; six spikes per scar; Glass Sink approach marker; darker crown slab moss.

## Scope changes
- 31 Oct, coordinator (owner feedback): P2-011 Tidewake named destinations moved to a new Tidewake lane (declutter plus a Meshy beach focal piece). Dropped here: `tidewake_destination_read.json` stays OFF and is not for landing; no further Tidewake location dressing from this lane. CPU r1 notes for that lane: the 8.5 m drift arch read much stronger; the shallow-water terrace walls showed a blank back face. The Tidewake camp bed and workbench (P2-115/P2-116) stay here.
- P2-102 parked without an arm: the night frame's crushed tower is the Cloudreach night grade (chapter lighting) and the griffin wing in the tower is a creature pose (other lanes); installed-asset dressing reaches neither for a >0.5 gain.
