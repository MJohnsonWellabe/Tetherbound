# Shared grass point-tip 01 — withdrawn

Status: **WITHDRAWN globally after two matched blind ties.** Production must return to the retained `0.78` taper after the currently running bush-identity diagnostic finishes. That diagnostic mounted while the pointed-tip candidate was applied, so its images/runtime receipt carry this disclosed grass-shape confound and are not clean baseline grass evidence.

## Candidate and reason

`scripts/world/grass_field.gd::_tuft_mesh()` described each blade as “a point at the tip,” while its width expression was `1.0 - t * t * 0.78`. At `t=1` this retains 22% of the authored base half-width. The candidate changed only `0.78` to `1.0`, making the terminal vertex pair coincident. Base width, blade height and centreline, retained arc, instance transforms/counts, shaders, materials, terrain masks, density and gameplay were unchanged.

The resulting final indexed quad contains one useful triangle and one zero-area triangle. No special index rewrite was made: preserving indices, UVs and normals kept the experiment a taper-only comparison and avoided changing mesh layout or LOD cost beyond the vertex positions under test.

The held candidate remains at `.artifacts/broad-visual-0910/grass-point-tip01/grass-point-tip01.patch`. The validated matched control is `tools/probe_grass_point_tip_legacy_control.gd`; it reconstructs the exact former `0.78` tuft arrays for the live near/mid/far specifications and replaces grass meshes only. Meadows, Stormwood and Water target the `GrassField` root or `GrassTile*` nodes. Cloudreach targets only `ProceduralGroundCover/CoverPatch*/Grass`; flowers and understorey are excluded. The final control corrected an initial Variant-inferred vertex-count parse failure and uses the actual per-biome node names.

## Verification and visual result

- Focused mesh/profile tests: 22 tests, 87,832 assertions, clean.
- Meadows candidate: `grass-point-tip-meadows-on-first`, 10:06:35–10:08:04, two day/night frames, clean.
- Meadows control: the first OFF invocation failed on the Variant-inferred count and is preserved. `grass-point-tip-meadows-off-second`, 10:09:08–10:10:34, two frames, clean.
- Water candidate: `grass-point-tip-water-on-first`, 10:10:51–10:11:38, two frames, clean.
- Water control: the first invocation used the wrong node and failed; the second correctly refused a reused output directory. Both are preserved. `grass-point-tip-water-off-third`, 10:13:28–10:14:05, two frames, clean.
- `JUDGE-GRASS-POINT-MEADOWS01.md`: candidate/control tie.
- `JUDGE-GRASS-POINT-WATER01.md`: candidate/control tie.

Both independent location judgments found no persuasive visible improvement. Stormwood Glass Field and Cloudreach Observatory comparisons were therefore not spent. The control supports those paths, but this trial does **not** claim all-four-biome runtime or visual verification.

The source discrepancy is real, but correcting the prose-level “point” contract did not improve ordinary gameplay presentation in the tested biomes. The dominant grass issues remain broader silhouette, grouping, value integration and scene composition. No further taper iteration is justified in this pass.
