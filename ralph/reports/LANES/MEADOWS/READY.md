# Meadows visual lane (tb/vis-meadows), 1 Nov 2026

**16:50 UTC, group 3 (from the batch-1 verdicts):** five entries in MANIFEST.json, `group: 3`. Entries marked `also_on` need those flags on too (landed or companion flags).
- **Meadows light** (`meadows_look.json:light_candidate.enabled`): the judges' common ask. A warmer, lower key sun, a character rim and about double the aerial fog with sky haze; at night, more ambient fill and exposure, a brighter moon, softer shadows and a tighter moon glow (the banded halo).
- **P2-003 r2:** keep 150 → 170 m (front face still fixed), darker stone, hotter fire-orange windows (`stronghold_hero_gatehouse.gd emission_colour`); judge with the existing `approach_pylons.p2_003_unlit_candidate_enabled` so the pylon lamps stop carrying the eye.
- **P2-006 r2:** bank rocks at the waterline (`bank_rocks` in the river candidate); judge on the close and landmark stands, not the canopy-blocked approach views.
- **P2-012 r2** (`bank.hill_shell.r2.enabled`): triplanar grass grain on the shell, the floating `MoundGrowth` hidden with the bank, and the interior clip moved behind the door beam (z 1.4 → 3.2) for the night dark band.
- **P2-064 r2:** the six Warden-arena wall torches pool at the wall (energy 12 → 7.5, attenuation 1 → 1.8, softer flame colour) for the over-lit orange Terrapup; the Warden-only boundary ring is softer (`combat.json arena.boundary_per_trainer_candidate`, alpha 0.3 → 0.12, height 0.8 → 0.45).

Checks: every touched script parses (`--check-only`, method in TECHNICAL §8.1); the shell shader compiles in a one-file Compatibility project. Unit tests are added but unrun here.

**15:25 UTC, compile fix:** 36c838031 renames `crossing_hall.gd apply_hall_layer`'s parameter `key` to `layer` (it was shadowed by the function's own `for key` loops, a parse error that broke every Meadows capture). This is the same fix as on the batch branch. Every script this branch touches now passes a Godot `--check-only` parse (method in TECHNICAL §8.1, since there is no import here):
- clean outright: `crossing_hall.gd`, `crossing_hall_arch_facades.gd`, `grass_field.gd`;
- clean with its one texture preload stubbed: `water.gd`;
- new functions checked in isolation with stubs, because dependency scripts' asset preloads block a whole-file check: `stronghold.gd`, `harvest_node.gd`.
`run_tests.gd` itself still can't run here (autoloads need imported assets), so the new unit tests remain unrun.

**Status (rolling batches, coordinator 13:49/13:54 UTC):** group 1 = six candidates, all flags OFF on this branch, in `MANIFEST.json` with `group: 1` and catalogue frame ids as stands (meadows/manifest.csv ids; F17-6 view ids for the Hall). No single-candidate READY lines.

| Item | Flag (set true) | Change |
|---|---|---|
| F17#6 | `crossing_hall.json:hall_2.enabled` | HALL-1 follow-ups: arch surround depth ×0.45 (piers stop reading as near-field posts), day ambient 0.65→0.52 + window daylight 2.6→2.0 + darker plaster (shrine blow-out), night ambient 0.22→0.12 with lantern pools 1.8→2.1, altar mask 1.6→0.85 / halo 1.5→0.9 / ShrineGlow 1.5→1.0 |
| P2-064 | `stronghold.json:site.conduits_stop_at_arena_wall` | the three centre-to-centre teal floor cables stop at the Warden arena wall instead of crossing the fight ring |
| P2-006 | `water.json:river.surface_candidate.enabled` | river only: finer stronger ripples, darker teal depth with a mid band, more sky fresnel, bank surf/foam; river reeds 90→130 and scrub 70→100 clumps |
| P2-012 | `burrow_warrens.json:bank.hill_shell.enabled` | close-1024 r2 hill shell (CPU 6.10 vs 4.94) with its interior blocker fixed: clip box moved to warrens space, covering only the real mouth chamber + passage |
| P2-005 | `grass_field.json:meadows_ground_candidate.enabled` | grass shader ground zones at Meadows scale (short clearings, shorter dry-olive patches, ~22 m), flower tiers in tighter, denser drifts; runtime only, no bake |
| P2-003 | `stronghold.json:p2_003_candidate.enabled` | lit keep 120→150 m wide with front face held (spire 45.7→57 m); courtyard wall-foot bricks 24/21→10, smaller, darker, pressed to the wall |

**Group 2 (15:20 UTC):**

| Item | Flag (set true) | Change |
|---|---|---|
| P2-087 | `stronghold.json:p2_087_grade_candidate.enabled` | DLG-2's one ask (6.94): break the single orange-brown stronghold grade. The courtyard's broad daylight fill becomes a cool sky bounce (#d6e2f2); the two courtyard-joint fires are a little less orange; the night moonlight is unchanged |
| P2-034 | `meadows_orb_reward_presentation.json:enabled` | the Basic Orb harvest node (the only one, order 1029) skips the Meshy orb-cache basket (judged as "eggs") and shows the lone mounted capture orb with navy seams, 0.5 m |

Checked and parked in group 2: P2-059/P2-113 (the trainer-share catch camera was judged worse in CPU r2, so it stays parked at r1); P2-094 (parked by the gain rule after r5–r8); P2-035 (the trail-camp props carry the rest, craft and creature-bed radii, so they can't be moved blind); P2-019 (alpha aura and presence already exist; no named, fixable defect); P2-078/P2-079/P2-086 (only ever judged on the old direct-start dialogue fixture; they need a capture with the DLG-2 fixture before any fix).

**Not verified on this lane:** no CPU capture was possible. The container has 3.3 GB free and the project has no `.godot` import (a full import would not fit), so Godot can't compile the project here and the new unit tests are unrun. Each change is config-gated and reviewed by hand; the batch build's GPU capture is the first render.

**Composition:** each flag lives in its own new key; shared files get appended blocks only (no reformatting). `hall_2` layers after `hall_1` (needs `hall_1` on, as on main).

**Scope items not built, and why:**
- P2-013 relay yard and P2-020 creature ground contact: their fixes are already ON on main (`tether_relay.json ground_pad.grass_clear`; every grass, flower and bush tier honours those discs. `creature_grass_clear.json`). They only need a GPU judge, which the batch run against main can't show (no diff).
- P2-014 (faceted planes at band2_stone_and_root_1): I couldn't identify the source from the 24 Oct sheet (horizon ranges or quarry/terrain cliff), and I had no capture to check. Parked until there's a frame.
- Hall grouped furnishing / villagers (HALL-1 path item 2): furniture pieces collide, so adding them blind risks the portal routes. Not built.
- P2-018, and the animation, UI and dialogue-camera rows: out of this lane's scene/material scope, or Cloudreach-only rows.

**Next round:** once the batch judging lands, I fix the regressions and the items still under 7 that it names.
