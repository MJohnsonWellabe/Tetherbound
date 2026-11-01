# VIS-CREATURES lane: READY (rolling groups)

**Manifest format (coordinator, 1 Nov):** creatures use camera_set "F36" (capture_f36_poses --whole-body --context), species names as stands, with each stand's mode (`--candidate` for enabled_species, otherwise plain). NPCs use the character-cast frame ids (`tools/_capture_character_cast.gd`). Group 1 is the material, height and hit batch plus the NPC bodies; group 2 is the pose flags (Galewisp, Mirejaw tail).

## Summary (1 Nov 2026)

## Group 4 (1 Nov, pushed): glowing eyes and elemental vein markings

This follows the owner's settled creature rule, via the coordinator: a believable adult animal plus ONE elemental trait, glowing eyes plus glowing lines, veins or markings in its element.
- **Flags:** `creatures_vis_glow_<species>` in `creature_coat_flags.json`, all OFF. Each flag's albedo is the group-3 trait (or the group-1 grade), so it supersedes both when on.
- **Script:** `tools/art_pipeline/grade_vis_glow.py`.
  - Eyes are the few most locally-dark pinpoints in a per-species head zone, grown into a thin iris ring.
  - Veins are a ridged model-space noise network, continuous across UV seams, kept to the back and shoulders.

**Per species:**
- mudsnout: amber (ground) eyes and veins;
- mirejaw and cannonback: cyan (water) eyes, markings and veins;
- fulgocobra: gold eyes, keeping its group-3 lightning rims;
- riverdrake: cyan eyes, keeping its crest rims;
- solmane: pale-sky eyes and wing veins (barely visible on CPU);
- voltarach: its board's blue eyes lit.

**CPU check.** Mudsnout's amber eye and Riverdrake's cyan eye read clearly. On Mirejaw and Cannonback the glow lands as small cyan head markings. The first eye pass flooded whole heads with glow, so it was replaced by a fixed small texel budget before the push.

**Conflict to rule on.** CLAUDE.md (owner, 25 Oct, delegated) says glow appears only where natural to the element and never as glowing seams on fur or hide. The newer owner rule, relayed by the coordinator, asks for glowing veins and markings. Both groups stay OFF until judged; the judging decides.

**Removed from the manifest:** the Bramblebun and Trailpup flags (`creatures_vis_coat_bramblebun` does not exist; `creatures_vis_grounded_hit_bramblebun` and `creatures_vis_trait_bramblebun/trailpup` were removed). Both get Meshy remakes from the coordinator. The flags stay in the files, OFF.

## Group 3 (1 Nov, pushed): one natural-magic trait per plain species

The owner's style direction (via the coordinator): a believable animal plus ONE bold natural-magic trait grown into the body. Flags `creatures_vis_trait_<species>` in `creature_coat_flags.json`, all OFF. Each is built over the group-1 grade, so it supersedes `creatures_vis_coat_<species>` when both are on. Script: `tools/art_pipeline/grade_vis_traits.py`. It places every trait by anatomy with the existing `creature_anatomy_maps` / `creature_overlays` tools, using the LIVE GLB's own UVs.
- **Bramblebun:** denser bramble and leaf growth over the back, with the face kept clear.
- **Trailpup:** an earth-ochre spine stripe with a warm glow at energy 1.2. Earth is not a glowing element; if the judges call it unnatural, this is the first thing to drop.
- **Mudsnout:** a moss carpet over the shoulders and back.
- **Mirejaw:** swamp moss along the back.
- **Cannonback:** water-weed over the shell top.
- **Fulgocobra:** gold lightning lit as a thin rim along its pattern edges, never across the hide.
- **Riverdrake:** bioluminescent cyan on the crest and frill rims.
- **Solmane:** sky-blue tips on the upper wing feathers (tint only).

**Code.** The coat hook gains an `emission` glow-map key (multiply operator, as the aspect variants' glow), with a unit test.

**CPU check (candidate mode where the GPU uses it):**
- reads clearly: Mudsnout, Solmane, Cannonback, Bramblebun;
- subtle but visible: Trailpup, Mirejaw, the Fulgocobra and Riverdrake glow rims.
- First-pass fixes: Bramblebun's leaf-ear overlay was dropped because it read as a decal, and the growth was kept off its face. Trailpup, Mirejaw and the glow rims were strengthened after the first pass read invisible.

**Not done:** Terrapup (left out; the coordinator is remaking it in Meshy). Pipwing and Brooktail ("cute rounded") are outside this lane's F36 (0) scope.

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
