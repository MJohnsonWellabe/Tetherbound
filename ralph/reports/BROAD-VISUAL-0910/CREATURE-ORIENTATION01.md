# Native Creature Orientation Diagnostic

## Receipt

The `creature-orientation-first` run started at `2026-09-10T10:50:04.0120671Z` and ended at `2026-09-10T10:50:16.6887967Z`. Its receipt reports exit code `0`, an empty error list, and `CREATURE_ORIENTATION_RESULT images=16 species=4`. The probe rendered four yaw angles (`0`, `90`, `180`, `270`) for Bramblebun, Skyrill, Torrentoad, and Mudsnout using the real `CreatureBody` and a conservative full-AABB camera.

Evidence:

- Console receipt: `.artifacts/broad-visual-0910/runs/creature-orientation-first/console.log`
- Run result: `.artifacts/broad-visual-0910/runs/creature-orientation-first/result.json`
- Probe: `.artifacts/broad-visual-0910/creature-orientation01/probe_creature_orientation.gd`
- Images: `.artifacts/broad-visual-0910/creature-orientation01/shots/`

The console records the expected body-forward sequence for every species: yaw 0 is `(0, 0, 1)`, yaw 90 is `(1, 0, -0)`, yaw 180 is `(-0, 0, -1)`, and yaw 270 is `(-1, 0, 0)`. No orientation probe errors or engine errors were recorded.

## Observations

Bramblebun's yaw 0 image is the front-facing view with its face visible, while yaw 180 is the rear view. This confirms the redesigned Bramblebun GLB is not simply backward. Mudsnout's yaw 0 image is also a clear front control with readable eyes and snout.

Skyrill and Torrentoad both have yaw 0 front-facing body orientation according to the receipt, but their front images do not present readable eyes. This is a front-facing readability/material or model presentation issue rather than evidence of a global 180-degree body rotation. The redesign path is visible in the Bramblebun receipt: `creature_bramblebun_redesign_lod0` receives `bramblebun_extracted_base_color_vivid.png`, the old vivid texture. Skyrill, Torrentoad, and Mudsnout similarly report their extracted vivid base-color textures.

## Limits and disposition

This is an isolated fixture with a conservative full-AABB camera. It tests body yaw, bounds, material assignment, and captured views; it does not test placement in a world, roster-wide presentation, animation-facing conventions, or player-camera framing. A clean receipt establishes that the diagnostic ran and that the body basis changes as expected. It does not establish visual acceptance.

The result does not justify a broad roster orientation fix and does not constitute a visual pass. The current investigation should focus on why the runtime redesigned GLB receives the old vivid texture and why Skyrill/Torrentoad front-facing presentation leaves eyes unreadable. No fix is claimed by this diagnostic.
