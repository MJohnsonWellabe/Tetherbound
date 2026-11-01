# Meadows visual lane (tb/vis-meadows), 1 Nov 2026

**Status (rolling batches, coordinator 13:49/13:54 UTC):** group 1 = six candidates, all flags OFF on this branch, in `MANIFEST.json` with `group: 1` and catalogue frame ids as stands (meadows/manifest.csv ids; F17-6 view ids for the Hall). No single-candidate READY lines.

| Item | Flag (set true) | Change |
|---|---|---|
| F17#6 | `crossing_hall.json:hall_2.enabled` | HALL-1 follow-ups: arch surround depth ×0.45 (piers stop reading as near-field posts), day ambient 0.65→0.52 + window daylight 2.6→2.0 + darker plaster (shrine blow-out), night ambient 0.22→0.12 with lantern pools 1.8→2.1, altar mask 1.6→0.85 / halo 1.5→0.9 / ShrineGlow 1.5→1.0 |
| P2-064 | `stronghold.json:site.conduits_stop_at_arena_wall` | the three centre-to-centre teal floor cables stop at the Warden arena wall instead of crossing the fight ring |
| P2-006 | `water.json:river.surface_candidate.enabled` | river only: finer stronger ripples, darker teal depth with a mid band, more sky fresnel, bank surf/foam; river reeds 90→130 and scrub 70→100 clumps |
| P2-012 | `burrow_warrens.json:bank.hill_shell.enabled` | close-1024 r2 hill shell (CPU 6.10 vs 4.94) with its interior blocker fixed: clip box moved to warrens space, covering only the real mouth chamber + passage |
| P2-005 | `grass_field.json:meadows_ground_candidate.enabled` | grass shader ground zones at Meadows scale (short clearings, shorter dry-olive patches, ~22 m), flower tiers in tighter, denser drifts; runtime only, no bake |
| P2-003 | `stronghold.json:p2_003_candidate.enabled` | lit keep 120→150 m wide with front face held (spire 45.7→57 m); courtyard wall-foot bricks 24/21→10, smaller, darker, pressed to the wall |

**Not verified on this lane:** no CPU capture was possible. The container has 3.3 GB free and the project has no `.godot` import (a full import would not fit), so Godot can't compile the project here and the new unit tests are unrun. Each change is config-gated and reviewed by hand; the batch build's GPU capture is the first render.

**Composition:** each flag lives in its own new key; shared files get appended blocks only (no reformatting). `hall_2` layers after `hall_1` (needs `hall_1` on, as on main).

**Scope items not built, and why:**
- P2-013 relay yard and P2-020 creature ground contact: their fixes are already ON on main (`tether_relay.json ground_pad.grass_clear`; every grass, flower and bush tier honours those discs. `creature_grass_clear.json`). They only need a GPU judge, which the batch run against main can't show (no diff).
- P2-014 (faceted planes at band2_stone_and_root_1): I couldn't identify the source from the 24 Oct sheet (horizon ranges or quarry/terrain cliff), and I had no capture to check. Parked until there's a frame.
- Hall grouped furnishing / villagers (HALL-1 path item 2): furniture pieces collide, so adding them blind risks the portal routes. Not built.
- P2-018, and the animation, UI and dialogue-camera rows: out of this lane's scene/material scope, or Cloudreach-only rows.

**Next round:** once the batch judging lands, I fix the regressions and the items still under 7 that it names.
