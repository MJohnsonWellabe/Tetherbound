# CREATURES-RALPH r5: variant-base remakes (Task 2) against their installed models (CPU, three blind judges)

Same harness as r1. Arm A is the installed models, as shipped: `remake_owner1101_burrowback`, `_trailpup` and `_paddlenewt` are OFF. Arm B turns those three flags ON. Their variants follow onto the base meshes with the aspect textures CAUSE-REMAKES already repainted for the remakes, and the B GLBs had their weights relaxed. Anchors: craft, f36_0_npc:C4 and f36_0_gap:C5 (seed 110205). Fit: slope 0.94, intercept 0.48, r 0.68, RMSE 0.62, no warnings.

| Creature | Installed → remake (mapped) | Verdict |
|---|---|---|
| Burrowback | 6.80 → 6.71 | stays HELD (−0.09) |
| Nightburrow | 5.73 → 5.64 | stays HELD (−0.09) |
| Trailpup | 6.93 → 6.11 | stays HELD (−0.82) |
| Stormtrail | 6.93 → 6.61 | stays HELD (−0.32) |
| Paddlenewt | 6.58 → 5.80 | stays HELD (−0.78) |
| Riftfrill | 6.49 → 5.70 | stays HELD (−0.79) |

The variant textures resolve correctly on every remake, so the contract in the HELD text is met. But no remake reaches its installed model's score. Turning them ON would regress the game, so the three flags stay OFF, and the weight relax I tried on them is not kept. The HELD reasons should now read "the remake scores below the installed model (r5)". The coordinator owns that test text.

## What the judges name (agreed ×3)

- **Paddlenewt / Riftfrill remake:** a hunched, near-bipedal "kaiju" stance with a shark-like head, where the installed form is a long, low newt. The hit react lifts it off the ground, and the faint frames are a studded "bubble-wrap" blob. This is the mesh and rig, so it needs new art. Riftfrill's purple speckle reads as "galaxy noise".
- **Trailpup remake:** a darker brown wolf where the installed form is a near-real coyote. It has a twisted hit react, and in the faint frames a cobbled, scaly back texture.
- **Burrowback remake:** close to the installed model. It wins on spine plates that sit naturally, and loses on turtle-shell tiling in the faint frames.
- **Nightburrow (both arms):** near-black. The remake's yellow-violet plate patchwork reads noisy.
- **Stormtrail remake:** blotchy blue glow decals rather than lines, and a split verdict (5.7 / 6.8 / 7.0).

## Next for these

- **Burrowback and Nightburrow:** a plate grade that breaks the regular tiling and calms Nightburrow's patchwork, using `grade_regions.py` with a plate mask. The gap is small (−0.09).
- **Trailpup / Stormtrail:** a coyote-toned regrade toward the installed palette. The hit-react twist is in the recipe clip, so it needs `amplify_clip` with a factor below 1 on the twisting bone.
- **Paddlenewt / Riftfrill:** a new mesh via Meshy, which goes to the coordinator because the key is absent here.
