# Provenance: Bramblebun Meshy retexture candidate (not integrated)

| Field | Value |
|---|---|
| Service / mode | Meshy REST `/openapi/v1/retexture` (texture-only retexture of an existing model) |
| Task ID | `01a0d688-9a9b-718d-83c8-d5e4c0ce9abf` |
| Submitted (UTC) | 2026-09-25T03:07:50Z |
| Created / started / finished (Meshy) | 03:07:53.604Z / 03:07:53.615Z / 03:08:32.485Z |
| Credits | 10 (balance went from 13795 to 13785). This is the second measured retexture at 10; `meshy.py` COSTS still says 30. |
| Input model | `assets/creatures/tetherbound/bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb` (the shipped rigged mesh, read-only) |
| Style image | `ref/bramblebun_style_ref_final.png`, drafted by the agent (see below) |
| text_style_prompt | Sent, but Meshy echoed it back empty: the image took precedence. The text is in `submission.json`. |
| Settings | enable_original_uv=true, enable_pbr=true, texture_resolution=2k, ai_model=latest. Meshy reports art_style "realistic". |
| Tooling | `submit_retexture.py`, which imports `tools/art_pipeline/meshy.py` request/data_uri. `meshy.py fetch --stage texture` did the poll and download. The key came from the environment only and was never stored. |
| Outputs | `candidate/model.glb` (plus fbx/obj), `candidate/tex0_{base_color,metallic,roughness,normal}.png`, `candidate/thumbnail.png`, `candidate/provenance.json`, `candidate/task_meta.json` |

## Reference drafting
`draft_ref.py` builds the style image from the species' own saved canon front view (`bramblebun_redesign/reference/front.png`, owner sheet 06).

**How it is built:**
- The canon view supplies the layout: shape and feature positions.
- Every surface is replaced by flat palette blocks, plus soft form shading taken from a heavily blurred luminance:
  - coat HSV(18°, 0.64, 0.66), russet;
  - cream (38°, 0.12, 0.95);
  - inner ear (355°, 0.35, 0.90);
  - antler bark (30°, 0.58, 0.42);
  - moss (98°, 0.52, 0.52);
  - eyes near-black, with a highlight.
- Hand-placed blocks cover what the watercolour does not carry cleanly: the muzzle, nose, chest core, toe caps and moss leaves on the shoulders and crown.
- Mode filtering removes the speckle and scribble line-work.

**Checked against the identity sheet before submission:** every signature feature is present in its canon position, and there is no red. Drafts v1 to v3 were rejected along the way:
- v1 read the mouth line-art as a dark grin, left specks on the chest and had no moss;
- v2 had a split muzzle, no nose and a paw band.

**It is a style input only.** No reference pixels ship.

## Why this avoids the Terrapup pilot's failure (task 01a0cfcd)
- **Matching style image.** The Terrapup pilot used a different drawing, a board panel whose features did not register with the mesh, so Meshy dropped the badger mask and shell design. This style image is drawn from the mesh's own canon view, so every feature sits where the mesh has it.
- **No noise to copy.** The board's watercolour noise came back as dotted orange noise. This image is flat blocks with no texture noise.
- **Moderate values.** The Terrapup output's face washed to yellow-white and blew out. Here the only near-white areas are the cream regions, and the coat is a mid-value russet.

## Validation (flat-lit software preview, NOT an engine render)
- **Mesh check:** the candidate GLB's index buffer and per-corner UVs match the shipped mesh exactly (maximum difference 0.0). The only change is a Y recentre, which does not matter because only the textures would be used. The candidate GLB has no skin or animations, so integration is a swap of the albedo, normal and roughness maps onto the shipped rigged mesh.
- **Sheet:** `comparison_current_vs_candidate.png` shows:
  - the shipped mesh with the current vivid albedo against the same mesh with the candidate albedo;
  - five yaws;
  - a 40%-scale paste onto a real in-game meadow crop;
  - the inputs and the Meshy thumbnail.

## Verdict: acceptable for an in-engine trial, with conditions
**Identity preserved:**
- dark eyes with a highlight, a cream muzzle and nose;
- the cream bib, toes and tail;
- pink inner ears;
- dark bark twig antlers;
- a green moss collar, and a bramble mantle down the spine.

**Defects fixed:**
- The colour blocks are flat, with no speckle or scribbled creases.
- The value steps are clear: cream at about 0.95, coat at about 0.67, bark/bramble dark.
- The russet coat separates strongly in hue from the meadow at 40% scale.
- The green is now a small, darker accent rather than grass-coloured patches.
- The non-canon green ear tips are gone.

**Minor defects:**
- There is a thin pink spill on the backs of the ears.
- Some olive-brown smears sit on the bramble spikes along the back. They read as bramble, but check them in engine.
- Metallic is about 0 and roughness has a mean of about 0.72, which is fine.

**Risk for the lead:**
- **Brightness:** the candidate's median albedo value is 0.67, against 0.38 for the shipped vivid texture. The redesign's albedo also feeds emission (see the round-2 regrade note: x1.4/x1.05 rendered fire-orange). The in-engine trial must check for glow and blown cream. The fix, if needed, is a value scale around 0.8 in the colourway, not a new task.
- **The engine's own treatment** (`field_degreen` / `field_emission`) also acts on the albedo at render time.
- **Not approved:** this preview is not an approval render. Integration waits for the lead's Godot turntable and in-world capture.
