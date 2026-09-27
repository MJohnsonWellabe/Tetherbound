# X04 / V4 — Meadowhart complete bare skin

Base: `0e2a3b60c9263d4d96d447869d6e34d57efa2506` (`origin/main`, re-fetched 2026-09-26).
Branch: `tb/x04-meadowhart-anatomy`. Claude owns integration/merge.
Anchor: ACCEPTANCE §4 and ART_DIRECTION §§7–9; VIS A-C1 / coordinator V4.

## Result and boundary

The final code-blind judge accepts the **creature body/anatomy as a bounded result**, with no blocking anatomical discontinuity in the supplied front, rear, attack or mounted views. It accepts the saddle/back interface without an obvious floating daylight gap. **Whole-frame Bar A: YES; Bar B: NO.** This is not closure of X04, the creature roster, riding presentation, the Meadows chapter or the overall visual goal.

Remaining visible work is explicit: primitive rider legs/boots and stirrup fit; busy grass/ground/flower composition; creature material hierarchy and attack expression. The full visual goal remains active. Native desktop frames do not establish Ally performance or production-night lighting.

## Defect and replacement

The prior single-surface Meadowhart carried a baked saddle. Its runtime adapter deleted indexed components by centroid position, also deleting the forelegs and torso, then inserted a pelvis-attached ellipsoid. Native production-body captures showed disconnected front-leg remnants and an oval torso separating the neck from the hindquarters. A diagnostic capture of the untouched source confirmed that the anatomical loss came from the stripping adapter.

The replacement is a complete bare skinned animal, with no saddle geometry in the asset and no runtime triangle removal or torso filler. It retains the established antlers, expressive eyes, cream chest, olive leaf mantle, spotted golden-brown coat and cloven hooves. RidingController remains the sole source of crafted/fitted tack.

The existing 3.45 m height, collider, physical seat `[0, 2.187805, -0.252439]`, speed and rider-clearance data are unchanged. A smooth rest-mesh/rest-rig adjustment raises the back into the existing saddle interface without changing ground or total antler height. The ordinary material is matte with restrained normal strength. The new UV layout has its own silver spirit-hart shiny repaint; it never uses the old skin's UV overlays.

The complete source PackedScene is retained once for Meadowhart, replacing the old stripped-mesh cache. This preserves mesh sharing across spawn/despawn and alpha-size cycles without rebuilding geometry at runtime.

## Provenance and reproducibility

- Existing design: `assets/creatures/tetherbound/meadowhart/reference/three_quarter.png`.
- Inspected bare derivative: `assets/creatures/tetherbound/meadowhart_bare/reference/three_quarter.png`, made with the built-in imagegen tool. The full edit prompt, reference hash, generation parameters and authorization are in `assets/creatures/tetherbound/meadowhart_bare/models/provenance.json`.
- One Meshy image-to-3D submission, `meshy-7.1`, task `01a0df71-2390-70c4-88e6-3f19f0b9c573`; **30 credits consumed**. No batch or purchase. The credential is absent from assets, manifests and source.
- Build: Blender 4.2.9 LTS, `tools/art_pipeline/blender/build_meadowhart_bare.py`, using the downloaded task GLB in `assets_raw/meadowhart_bare/a/model.glb`. The script welds coincident vertices before skinning, validates the mesh, bounds triangle count, limits/normalizes four skin influences and authors six clips. Ground correction is baked into animation; gameplay retains horizontal motion.
- Installed GLB SHA-256: `d02c229bc9c33b8e2717bb7524027ece0ec7e81cba71f013eae183eeb84405f8`.
- Final export: one skinned mesh, one material, 15 joints, 27,999 triangles, six clips. No unweighted vertices. Runtime texture sidecars use VRAM compression and mipmaps.

The image/3D sources are generated through the owner's authorized workflow and existing Meshy license. The local raw task response and source GLB are retained in `assets_raw`; signed download URLs and account details are not committed.

## Validation

| Check | Result |
|---|---|
| Focused riding/skin/capture contracts | 22 tests, 248 assertions, zero failures |
| `smoke_playground.gd` | `smoke: OK`, exit 0; existing headless dummy-renderer null-material diagnostic remains, so this is not an error-free renderer claim |
| `smoke_meadowhart_alpha_rebuild_0912.gd` | 24 ordinary/alpha cycles share one mesh; collider/art scaling stays aligned |
| Texture import policy | Three runtime texture sidecars pass VRAM compression policy |
| Native stage, ordinary/shiny | 1920×1080 Compatibility captures; 720p downscale inspected |
| Production Meadows riding harness | Six of six frames; real summon, saddle fit and mount paths; no reported fixture failures |
| Native motion | All six clips recorded at 1920×1080 / fixed 30 fps; 30-second witness, with a reproducible capture harness |
| Independent CPU skin evaluation | All exported samples grounded within approximately 0.000001 source units; idle/walk/run endpoints match; hit starts/ends at rest; attack lowers the head and recovers |

Commands:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=test_meadowhart_riding_visual_repair_0912,test_riding_saddle,test_meadows_final_visual_capture_batch_0912
godot --headless --path . --script tests/smoke_meadowhart_alpha_rebuild_0912.gd
godot --headless --path . --script tests/smoke_playground.gd
python tools/art_pipeline/texture_import_policy.py --check assets/creatures/tetherbound/meadowhart_bare/models
godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/capture_visual_audit.gd -- --section=roster --only=meadowhart --out=res://shots/meadowhart-stage-<fresh-round>
godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/_capture_riding.gd -- --species=meadowhart --output=res://ralph/reports/VISUAL/meadowhart-riding-<fresh-round>
godot --path . --rendering-driver opengl3 --resolution 1920x1080 --fixed-fps 30 --write-movie <local-path.avi> --script tools/art_pipeline/capture_meadowhart_motion.gd -- --out=res://shots/meadowhart-motion-<fresh-round>
```

Recorded on Windows, Godot 4.7 `5b4e0cb0f`, Compatibility / NVIDIA GTX 1060 3GB. The committed `_sheet_meadowhart_anatomy.png` is the single contact sheet for the final review. Individual PNGs and motion recordings stay local under `shots/`, the named riding batch and `D:/tetherbound/visual-acceptance-local/` per WORKFLOW evidence hygiene. The night riding harness adds diagnostic fill lights to inspect the interfaces; it cannot certify ordinary night illumination. Its framed camera is also disclosed rather than called an ordinary gameplay camera.

## Independent reviews

First fresh visual judge (`meadowhart_visual_judge`) saw neutral L/M sets, all twelve 1080/720 frames and the established references, without implementation context. M was the complete candidate; L was the old runtime body. It found no major anatomical/identity regression, accepted M's direction for Bars A/B on the neutral stage, and rejected L's missing limbs/oval torso. It requested clearer attack action and quieter material/detail hierarchy. That review led to the final material response and clip revisions; it was not treated as a whole-scene pass.

Final fresh code-blind judge (`meadowhart_final_visual_judge`) inspected the final stage, shiny and six world-riding frames at both rasters against the original Meadowhart, Meadows key art and all five Palworld references. Its verdict:

> Creature body/anatomy: acceptable as a bounded result. Whole-frame acceptance: no.

It found no detached limbs, open seams or collapsed joints, and no obvious floating saddle/back gap. It judged the leggier silhouette coherent and the mount/trainer scale plausible. Ranked remaining gaps:

1. Smooth blue rider leg segments and rectangular brown feet conflict with the detailed upper body; footwear/stirrup integration and readable reins remain unresolved.
2. Continuous bright grass, repeated flowers and busy ground compete with the subject; the purple plant conceals hoof contact and the bare tree tangles with the head silhouette.
3. Dense fur relief and thick collar pieces compete for attention; the shiny merges fur/foliage into one silver family, and the attack still reads as a cautious step/prance rather than a committed strike.

It also retained pale/angular background mountains and inconsistent foliage values as open scene findings. **Bar A YES; Bar B NO.** These remain defects, not exceptions granted to obtain acceptance.

Independent code reviewer (`meadowhart_code_review`) inspected the actual diff and exported skin. No remaining correctness findings. It verified normalized weights, six clips, texture binding, grounded samples, loop endpoints and preserved seat/collider data. Its motion-harness partial-success finding was corrected by validating the AnimationPlayer and all required clips before any capture. It separately accepted the one-source lifecycle cache. Code review did not substitute for the blind visual review or native playback.
