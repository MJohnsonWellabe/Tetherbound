# F36#0 native creature candidates vs installed models: frames for the code-blind judge

Captured Sun 11 Oct 2026, about 12:35 PM CT, by the captures lane (`tb/ev-captures`). This lane captures; it does not judge. The coordinator's per-species PASS list decides which candidates get switched on.

- **Source:** `0d598b9b` (= origin/tb/ev-coordinator `94368e45` plus two capture-tool commits that touch no creature or render code).
- **Renderer:** local Linux container, Godot 4.7-stable, `gl_compatibility` / OpenGL on Mesa llvmpipe in xvfb, 1280x720.
- **Tool:** the existing `tools/art_pipeline/capture_f36_poses.gd --scale-only` (whole-body standing stage beside the 1.80 m trainer, yaw 0 and 180 degrees). It was run twice with the same command:
  1. **installed:** `species.json` exactly as committed;
  2. **candidate:** each species' `assets/creatures/tetherbound/<id>/candidate/source/species_candidate.json` placeholder merged into `data/creatures/species.json` in the working tree only (`enable_candidates_for_capture.py`), then restored with `git checkout`. **Nothing committed enables a candidate.** All 23 candidates still ship `enabled=false`.
- **Check that the switch took effect:** every species' candidate front frame differs from its installed frame (byte hash), and both variants report a model. The standing heights in the table are the stage's own render-bounds measurements.

## Sheets

`sheet-1.jpg`..`sheet-3.jpg` show one row per species: installed front, installed back, candidate front, candidate back. Every row uses ONE crop box shared by its four frames, so the two variants keep identical scale and camera (`cropgroup.py`: local-detail mask, union box, 16:9, 30% margin). Full uncropped frames and the tool's receipts are in `frames/`.

| Species | Sheet | Installed height (m) | Candidate height (m) | Candidate source and provenance |
|---|---|---|---|---|
| abyssal_guardian | sheet-1 | 7.20 | 7.20 | assets/creatures/tetherbound/abyssal_guardian/candidate/ |
| aeriex | sheet-1 | 4.00 | 4.00 | assets/creatures/tetherbound/aeriex/candidate/ |
| ashtusk | sheet-1 | 3.60 | 3.60 | assets/creatures/tetherbound/ashtusk/candidate/ |
| bramblebun | sheet-1 | 2.05 | 2.05 | assets/creatures/tetherbound/bramblebun/candidate/ |
| burrowback | sheet-1 | 2.95 | 2.95 | assets/creatures/tetherbound/burrowback/candidate/ |
| cannonback | sheet-1 | 3.70 | 3.70 | assets/creatures/tetherbound/cannonback/candidate/ |
| cloudfang | sheet-1 | 3.85 | 3.85 | assets/creatures/tetherbound/cloudfang/candidate/ |
| fulgocobra | sheet-1 | 5.20 | 5.20 | assets/creatures/tetherbound/fulgocobra/candidate/ |
| galecrest | sheet-2 | 3.50 | 3.50 | assets/creatures/tetherbound/galecrest/candidate/ |
| galewisp | sheet-2 | 3.25 | 3.25 | assets/creatures/tetherbound/galewisp/candidate/ |
| meadowhart | sheet-2 | 3.45 | 3.45 | assets/creatures/tetherbound/meadowhart/candidate/ |
| mirejaw | sheet-2 | 2.80 | 2.80 | assets/creatures/tetherbound/mirejaw/candidate/ |
| mudsnout | sheet-2 | 2.00 | 2.00 | assets/creatures/tetherbound/mudsnout/candidate/ |
| ripplet | sheet-2 | 3.60 | 3.60 | assets/creatures/tetherbound/ripplet/candidate/ |
| riverdrake | sheet-2 | 4.00 | 4.00 | assets/creatures/tetherbound/riverdrake/candidate/ |
| solmane | sheet-2 | 6.70 | 6.70 | assets/creatures/tetherbound/solmane/candidate/ |
| staticub | sheet-3 | 3.25 | 3.25 | assets/creatures/tetherbound/staticub/candidate/ |
| stormcapra | sheet-3 | 3.85 | 3.85 | assets/creatures/tetherbound/stormcapra/candidate/ |
| tanglevolt | sheet-3 | 3.40 | 3.40 | assets/creatures/tetherbound/tanglevolt/candidate/ |
| terrapup | sheet-3 | 3.85 | 3.85 | assets/creatures/tetherbound/terrapup/candidate/ |
| tuskroot | sheet-3 | 3.60 | 3.60 | assets/creatures/tetherbound/tuskroot/candidate/ |
| veridian | sheet-3 | 5.80 | 5.80 | assets/creatures/tetherbound/veridian/candidate/ |
| voltarach | sheet-3 | 4.25 | 4.25 | assets/creatures/tetherbound/voltarach/candidate/ |

## Limits and disclosures

- **Stage only.** These are standing presentation frames. They cover no animation, pose, earned fight or traversal, and no fight-scale claim.
- **Compatibility only.** A Medium/Forward+ view is not producible here: render.yml's Forward+ crashes on llvmpipe Vulkan, and this container has no GPU. Each candidate's `candidate/review/` already holds Codex's native GTX 1060 Low and Medium before/after sheets (provenance.json `native_validation`), which a judge can weigh alongside these.
- **Open gates in the candidates' own provenance** (`candidate/source/provenance.json` `gates`, read at capture time):
  - all 23 record `full_art_bar_pass: false`, with the independent judge OPEN and scale PASS;
  - 8 record a terminal-contact (faint/flank) **FAIL**: abyssal_guardian, aeriex, cannonback, fulgocobra, solmane, stormcapra, veridian and voltarach;
  - solmane also records topology **FAIL**;
  - the rest list rig/motion and terminal contact as OPEN.
  These standing frames do not show poses, so they cannot settle any of those gates.
- **Wiring note for enabling.** No code reads the `enabled` field. A candidate renders only when its `placeholder` block is merged into `species.json` (model, height, radius, animations, field_emission and the rest).
