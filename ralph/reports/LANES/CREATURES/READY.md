# VIS-CREATURES lane: READY for tb/vis-batch1

## Summary (1 Nov 2026)

**Status.** Zero criteria closed. Nothing here is judged yet, and no CPU score is claimed. Every change is behind a flag that ships OFF, on `tb/vis-creatures`. `MANIFEST.json` (17 flags, 14 items) lists each item, its flag and its capture. Per the coordinator's update, there are no single-candidate READY lines.

**Game changes waiting on the batch GPU run:**
- **Coat grades.** Script: `tools/art_pipeline/grade_vis_creatures.py`. Each is a graded albedo `<stem>_vis1.png` behind `creature_coat_flags.json: creatures_vis_coat_<species>`:
  - fulgocobra: an earthy value lift ("dark brown on stage");
  - mirejaw: a gentle lift of the darkest hide;
  - cannonback: the brass and olive plating desaturated toward weathered horn ("machinery shell");
  - abyssal_guardian: the cyan dots muted, the blue deepened, and self-lit emission ×0.6 ("glossy vinyl, regular dots");
  - veridian: the bone-white bands lowered to warm ivory and the moss noise smoothed;
  - voltarach: the gold halo darkened to bronze, the arc cores kept, the black base lifted to dark bronze, the blue eyes brightened ("gold covers most of the body");
  - mudsnout: local value contrast on the face ("single tan value");
  - solmane: mild local contrast.
- **Height.** `creature_scale_flags.json: creatures_vis_taller_mirejaw` sets mirejaw ×1.35. It measures 2.80 → 3.78 m at runtime, and water_mirejaw grows too.
- **Grounded hits** (`creature_clip_flags.json`):
  - bramblebun: rotation ×1.35, position ×0.25 (its hit "looks airborne");
  - water_cannonback: rotation ×1.6, position ×0.5.
- **Pose role flags** (`f36_pose_candidates.json: candidate_role_flags`, checked by rendering in candidate mode):
  - `creatures_vis_galewisp_faint_away`: the faint is mirrored in yaw, so Galewisp falls onto its side away from the trainer instead of across him ("faint wing over the trainer").
  - `creatures_vis_mirejaw_tail_clear` (mirejaw and water_mirejaw, hit and faint): the tail curls clear of the trainer ruler. Without it, the ×1.35 height would hide him behind the tail fan. Pair it with `creatures_vis_taller_mirejaw`.
- **NPC bodies** (#25 wandering trainer, #27 young trainer, #28 trader, #29 innkeeper):
  - Script: `tools/art_pipeline/grade_vis_npcs.py`. Skin loses its chalk and blotches, eyes, brows and mouths gain local contrast, and the darkest cloth lifts a step. Atlas and identity are unchanged, and reserved-red texels go down.
  - Flags: `character_body_flags.json: npc_vis_body_<character>`, through the new `character_model.gd::with_body_flags` hook.

**Checks.**
- **New unit tests:** `tests/test_creature_coat_flags.gd` and `tests/test_character_body_flags.gd`. Both pass in a scratch project.
- **What failed in the scratch project, and why:**
  - `test_every_flag_resolves_when_enabled` fails only on the older flags' sources (duskhush, sparkit and others), which aren't in the scratch project. Every new flag passes.
  - `test_character_metallic` and `test_character_appearance_variants` fail identically with and without the hook, so those failures come from the missing assets.
  - The full suite was not run: the container can't import the whole project.
- **Runtime probes** (a real CreatureBody, or `character_model.build`, with the flags flipped on):
  - every graded albedo binds on its land and water form;
  - Abyssal Guardian's emission reads 0.60;
  - the NPC overrides bind.
- **CPU sanity capture** (`capture_f36_poses.gd --whole-body --context`, Low): `_sheet_vis1.png`.
  - Voltarach reads darker bronze with arcs, and mirejaw is clearly taller than the trainer.
  - Cannonback and Solmane barely change.
  - Fulgocobra's first grade went lemon yellow. It was re-graded softer (right half of its tile) before the push.

**CO-F36-7 (matte) finding.** The GPU verdict's "coats is a list" diagnosis is wrong: the flag is a dict on main and on the captured tree (e8da58fe1).
- A runtime probe on main shows the flag reaching the live materials. Skyrill goes from metallic 1.00 / roughness map to 0.00 / 0.85 / specular 0.35, and Voltarach's roughness goes to 0.80.
- These species' maps are already nearly matte. Voltarach's metallic is 0, and roughness map means are 0.50–0.67. So the chrome or statue look is painted into the albedo, and material values move little. That is why voltarach gets an albedo grade here instead.
- The coat hook now logs a misshapen flag instead of silently applying nothing.
- I don't have a confirmed cause for the GPU's identical frames.

**Not changed (parked, with reasons):**
- **Solmane's faint:** parked after two failed approaches (renders in `capture_f36_poses.gd --candidate`).
  - A side roll swings its rigid wings vertical, and the negative roll floats.
  - A sphinx collapse reads as sitting upright.
  - Its wings are skinned to the spine, with no wing bones, so the "wings up" crouch needs new rig work.
- **Riverdrake:** its faint end is a rolled plank, and a tail curl barely changes it. It is already 7.23 at High.
- **Galewisp's carrying frame:** it carries nothing, which is a staging issue.
- **Terrapup:** 7.35 at High, already over 7.
- **NPC faces:** the grade is subtle on CPU (warmer skin, crisper features). The judges' low-resolution baked eyes stay, so expect a small gain.

**Contact sheet.** `_sheet_vis1.png` (CPU, sanity only) shows three rows: the material arms, the pose flags, and the NPC faces off and on.
