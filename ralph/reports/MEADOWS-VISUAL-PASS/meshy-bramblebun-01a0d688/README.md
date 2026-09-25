# Bramblebun Meshy retexture candidate: handover to the creature/hero art lane (X04)

- **State:** candidate only. Nothing is integrated, and nothing has been rendered in Godot.
- **Task:** Meshy `01a0d688-9a9b-718d-83c8-d5e4c0ce9abf`, texture-only retexture of the shipped rigged `assets/creatures/tetherbound/bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb`. Original UVs kept, 2k PBR, 10 credits. The Meadows core lane submitted it on 2026-09-25T03:07Z.
- **Why Bramblebun:** the R9 blind judge (see REPORT.md, round 5 R9) ranked creature art the top gap. Bramblebun has read as a brown lump in the grass in three judge rounds.
- **Contents:**
  - `identity_sheet.md`: what must be preserved.
  - `provenance.md`: the full task record and how the reference was drafted.
  - `ref/`: the agent-drafted style image.
  - `candidate/`: the Meshy outputs (glb plus four texture maps; fbx/obj omitted).
  - `comparison_current_vs_candidate.png`: flat-lit Pillow previews, not engine renders.
  - `scripts/`: the submission and preview scripts. They read the key from the environment only; no key is stored anywhere here.
- **Validation so far:** the index buffer and per-corner UVs match the shipped mesh exactly, so integration would swap only the texture maps onto the existing rig. Identity is preserved. The colour is flat blocks with no speckle or creases, with clear value steps, and it reads against grass at 40%.
  - Minor defects: pink spill on the backs of the ears, and olive smears on the back spikes.
- **Open risks for the in-engine trial:**
  - The albedo is much brighter than the shipped one (median value 0.67 vs 0.38), and this model's albedo also feeds emission; check for glow and blown-out cream.
  - The coat is still orange-toned, and the judge's "every creature is orange-tan" point may still apply roster-wide.
- **Earlier related branch:** `ralph/meshy-terrapup` (bd4fc0acd), the rejected Terrapup retexture pilot `01a0cfcd` (identity loss; see REPORT.md).
- **Ownership:** the Meadows core lane submits no further Meshy tasks, and its key file was deleted. The art lane owns any next step.
