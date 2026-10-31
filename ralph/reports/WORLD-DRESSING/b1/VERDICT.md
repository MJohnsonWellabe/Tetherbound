# World dressing b1: CPU three-judge A/B (31 Oct 2026)

- Renderer: CPU llvmpipe, Compatibility, 1280x720. Control: tb/world-dressing with every new flag OFF (behaviour = main d4d5b262). Candidate: same tree with the round-1 flags ON (working-tree overlay, never committed).
- Captures: the job.json repro tools and arguments for each item (output to `.artifacts/`, not committed). Sheets 2x2 per side at 640x360 (`spec.json`).
- Yardstick: standard JUDGE_PROMPT.md, `anchor_tiles.py --pairs 3 --include craft --seed 31107`, three fresh code-blind judges, `calibrate.py`. Fit linear, slope 1.19, intercept -0.85, r 0.94, anchor RMSE 0.30, top anchor 7.35 (confirming batch). Warning: some candidates (both mains at 3.4-3.5) lie outside the anchors' measured range.

| Item | Flag | Main (mapped) | Candidate (mapped) | Gain | Defect (cand, j1/j2/j3) | Disposition |
|---|---|---|---|---|---|---|
| P2-041 Crown Arch | crown_arch_hero.json `enabled` | 3.52 | 5.27 | +1.75 | PARTIAL x3 | arm 1 |
| P2-070 Glass Sink | stormwood_glass_sink.json `meshy_rim` | 3.36 | 4.91 | +1.55 | PARTIAL x3 | arm 1 |
| P2-046 harvest resources | stormwood_harvests.json `material_cues.*.hero` | 4.47 | 5.87 | +1.40 | PARTIAL x3 | arm 1 |
| P2-045 candy tiers | pickup_grounding.json `enabled` | 5.07 | 5.98 | +0.91 | PARTIAL/FIXED/PARTIAL | arm 1 |
| P2-043 Glass Field spikes | stormwood_glass_field.json `meshy_spikes` | 4.83 | 5.39 | +0.56 | PARTIAL x3 | arm 1 |
| P2-033 ground pickups | pickup_grounding.json `enabled` | 6.02 | 6.58 | +0.56 | PARTIAL x3 | arm 1 |
| P2-035 camp props | trail_camp `camp_floor` | 5.47 | 5.87 | +0.40 | PARTIAL/PARTIAL/PRESENT | round 2 (ring 1.4x read as a pale blob) |
| P2-034 harvest rewards | pickup_grounding.json `enabled` | 5.98 | 6.26 | +0.28 | PARTIAL x3 | round 2 |
| P2-094 placed wall | build_wall_interior.json `meshy_wall.r8` | 6.10 | 5.98 | -0.12 | FIXED/FIXED/PARTIAL | round 2 (change too subtle) |

Raw per-judge scores: `batch.json`; mapped per judge: `mapped.json`. Judge notes that steer round 2: the Crown Arch slab still floats as a hard teal square; the Glass Sink void below the ridge is still a tiled plane (new_art: a basin bowl); glowmoss stays a pale flat patch; the camp fire is a flat cone and the ring a pale disc; the Stormwood carpet and flat sky cap every Stormwood score (chapter-wide, not this lane).
