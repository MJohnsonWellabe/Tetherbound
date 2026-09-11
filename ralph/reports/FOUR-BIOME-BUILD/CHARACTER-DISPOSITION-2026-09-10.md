# Character disposition — 2026-09-10

## Result

The production character roster is **31/31 visually passing** after inspecting
every distinct humanoid model bound by `data/config/art.json`. The audit also
rendered the generic Team Tether rank variants and all three named Meadows
captains through their real runtime configuration paths, for 38 front and 38
three-quarter frames total.

This is an asset-level disposition, not a claim that every NPC placement,
conversation camera, night scene or crowd composition is finished.

## Coverage

- All 31 distinct bodies load at their configured height and retain a complete
  silhouette in the common neutral-stage camera.
- `tools/check_character_clips.gd` now discovers every distinct production body
  rather than checking only trainer, Grandpa and Warden. All 31 pass; each of the
  five or six configured gameplay roles resolves to a real clip.
- Trainer, Grandpa, Warden, the two reusable villager bodies, the Team Tether
  archetype and seven individual rank bodies pass.
- The eight settlement bodies and seven trail/wilderness bodies pass.
- Lyra, Kael and Sera pass against owner boards 23–25.
- Rank palette variants remain dark by design but retain readable garment,
  face and badge separation on the calibrated stage.

## Replacement: wandering trainer

The neutral audit reproduced the known shared-body defect on
`wandering_trainer`: the face was a smeared low-resolution painted patch. This
body is used by both Gil and Old Bram, so one replacement fixes both characters.

Three agent-generated turnaround candidates were produced from the owner NPC
board under `assets/characters/wandering_trainer/reference/`. A code-blind judge
selected `generated_candidate_03.png` for its source fidelity, face readability,
turnaround consistency, silhouette and rig separation. The source board remains
authoritative; its shoulder companion is intentionally not fused into the
humanoid mesh and remains separate creature/attachment work.

Meshy preview task `01a08e70-e712-72c7-bcd3-404a49e82447` preserved the accepted
hat, coat, backpack and bedroll form with a modeled face and separated limbs. It
was cleaned from 55,805 to 27,998 triangles, then textured at 2k by task
`01a08e74-6e10-777e-b17c-c194fb7cb2d5`. Humanoid rig task
`01a08e76-ad47-71da-b396-148a687fd70f` produced the production skeleton; the local
animation pass installed idle, walk, sprint, jump, throw and chop at 1.78 m.

The replacement is installed at
`assets/characters/wandering_trainer/wandering_trainer_lod0.glb`. Its refreshed
dialogue plate is `assets/ui/portraits/wandering_trainer.png`.

## Validation

- Godot import completed for the replacement GLB and extracted texture.
- Neutral installed-body front and three-quarter frames preserve a complete
  silhouette and readable modeled face.
- The dedicated walk/sprint strip covers eight phases of each cycle plus a
  three-quarter pose. Hat, head, shoulders, coat, backpack, hips, knees and feet
  remain stable with no visible collapse.
- Dialogue portrait capture: 56% subject coverage, 0.6% blown pixels, clear edges,
  zero failures.
- `tools/check_character_clips.gd`: 31 distinct bodies, 0 failed.

## Remaining presentation work

No further character mesh replacement is justified by this audit. Remaining
character-related gaps are scene presentation: distant rear-only framing, night
separation, crowd staging and pairing characters visibly with creatures. Those
should be fixed in their biome/world lanes rather than by regenerating passing
humanoid assets.
