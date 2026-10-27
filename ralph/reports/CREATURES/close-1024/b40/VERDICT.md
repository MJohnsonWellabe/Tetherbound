# b40: Meshy retexture grades, dog3 Terrapup and Mirejaw (CPU, three judges)

Renderer: Godot 4.7 Compatibility, Mesa llvmpipe under xvfb (CPU; ranking only). Stage: `capture_f36_poses.gd --whole-body --context` (Mirejaw `--candidate`). Tiles per side: standing (hit-000), hit-050, faint-100, then ride-050 (Terrapup) or faint-050 (Mirejaw). Base = main's shipping model on the same stage (Terrapup: the nat1022 badger; Mirejaw: the native candidate with main's albedo). Sheet: `_sheet_b40.jpg` (top: Terrapup base | candidate; bottom: Mirejaw base | candidate).

Anchors: p2_094_r4, f36_0_gap:C6, f36_0_npc:C1. Fit: slope 1.22, r 0.87, RMSE 0.67 (under 0.75), confirming.

| subject | base (mapped) | candidate (mapped) | gain | judges' defects (candidate) |
|---|---|---|---|---|
| Mirejaw, r2 graded (olive-umber back, amber frills, mouth out of red) | 5.69 | **6.35** | **+0.66** | near-black back: PARTIAL x3 (base PARTIAL, PARTIAL, PRESENT) |
| Terrapup dog3, r1 graded (chestnut coat, earth-grey plates with fur rim, contact shadow, moss) + seat 2.36, rim 0.3 | 6.18 | **6.63** | +0.45 | plates strapped on: PRESENT x3; coat orange-red: PARTIAL, PRESENT, PARTIAL |

Judges' notes:
- Mirejaw: all three prefer the olive body to the black-and-gold net ("busy", "generated-looking print"); the olive back "holds some form". Still flagged on both sides: the tail frill overlaps the 1.80 m ruler (stage staging), the hit reads as a rear-up, the faint as a weak top-down sprawl.
- Terrapup: all three read the dog as "appealing", "on-style", "taller than the ruler" with the best poses in the batch (hit flinch, side-lying faint, seated rider). One judge called the badger "off-board identity". All three read the grey plate mass as a saddle or pack with a hard edge at the shoulders and haunches. Two flag the coat as orange-red on this stage; the CPU stage self-lights the whole albedo, so the GPU decides the coat. One judge saw a thin white streak off the tail in the hit frame (a dog3 clip artefact, not the texture).

Calls:
- Mirejaw: gain above 0.5. GPU READY.
- Terrapup: +0.45, under the 0.5 rule on CPU alone. It carries the owner's identity order ("Terrapup should be a dog"), so it goes to the GPU queue anyway, and the plates still read as a backpack after grading, so a stronger plate retexture is requested (MESHY).

Checks: `run_tests --only=f36_pose,rideable,riding,scale_ladder,species,colourway,texture_for,creature_body,rest_pose,water,starter,companion`: 694 tests, 1 failed, `test_companion_presence :: test_low_hp_slows_the_gait_lowers_the_head_and_flinches` (gait_scale 0 on a healthy creature). It fails the same way with the land head's species.json (badger), so it is pre-existing and not this candidate's. Texture import policy PASS (934). Reserved red band after grading: Terrapup 0.13% of texels (jpeg edges), Mirejaw 0.000%.
