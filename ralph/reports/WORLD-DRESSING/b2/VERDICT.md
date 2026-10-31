# World dressing b2: CPU three-judge A/B (31 Oct 2026)

- Renderer and method as b1 (CPU llvmpipe Compatibility 1280x720; control = all new flags OFF; candidate = flags ON via working-tree overlay; 2x2 sheets; standard prompt; `anchor_tiles.py --pairs 3 --include craft --seed 31208`; three fresh judges; `calibrate.py`).
- Fit: linear, slope 1.63, intercept -3.83, r 0.99, anchor RMSE 0.24, top anchor 7.53 (confirming batch). Warning: some mains (Glass Sink, Crown Arch) lie outside the anchors' measured range.
- Round-2 values (lane commit 97c8b3ab and follow-ups) for the WD1 items; first or second rounds for the rest. Round 1 and round 2 sit on different batch fits, so compare gains within a batch.

| Item | Flag | Main | Candidate | Gain | Round | Disposition |
|---|---|---|---|---|---|---|
| P2-046 harvest resources | stormwood_harvests.json `material_cues.*.hero` | 3.86 | 6.31 | +2.45 | r2 | WD2 (glowmoss fungi now read) |
| P2-041 Crown Arch | crown_arch_hero.json | 3.15 | 5.33 | +2.18 | r2 | WD2 (slab still a hard square: judges ask for new_art footing) |
| P2-070 Glass Sink | stormwood_glass_sink.json `meshy_rim` | 2.71 | 4.89 | +2.18 | r2 | WD2 (void below still tiled: needs a basin mesh) |
| P2-115 camp creature bed | meshy_camp_props.json `bed` | 4.95 | 6.25 | +1.30 | r1 | WD2 |
| P2-043 Glass Field spikes | stormwood_glass_field.json `meshy_spikes` | 4.95 | 6.20 | +1.25 | r2 | WD2 (defect FIXED 2/3) |
| P2-116 camp workbench | meshy_camp_props.json `workbench` | 5.22 | 6.04 | +0.82 | r2 | WD2 |
| P2-035 camp props | band1 props.json trail_camp `camp_floor` | 6.20 | 6.96 | +0.76 | r2 | WD2 |
| P2-054 mushrooms | pickup_grounding.json | 5.71 | 6.36 | +0.65 | r1 | WD2 (FIXED 1/3) |
| P2-034 harvest rewards | pickup_grounding.json | 6.14 | 6.58 | +0.44 | r2 | parked (r1 +0.28, r2 +0.44; tonic node needs a hero mesh) |
| P2-094 placed wall | meshy_wall.r8 | 6.58 | 6.85 | +0.27 | r2 | parked (r1 -0.12, r2 +0.27) |
| P2-038 named destinations | lantern_pools `arrival_pools` | 5.05 | 5.05 | 0.00 | r2 | parked (two rounds with no gain; judges ask for hero subjects per destination: new_art) |
| P2-024 landmark read | cloudreach_f40_items last candidate | 6.09 | 6.09 | 0.00 | r1 | no gain; plinths not in view, strata clusters read as background |

Raw per-judge scores in `batch.json`, mapped per judge in `mapped.json`.
