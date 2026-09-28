# Gull Rest isolated mask-input comparison

**Diagnostic run failed its strict equality invariant; no candidate is accepted.** Session `81716` exited **1**, the original manifest remains `complete=false`, and all three recorded failures concern exact camera-transform equality. Four of four JPEGs were nevertheless saved at actual **1920×1080**. This review preserves that outcome; it does not retroactively pass the run or request a rerun.

The reviewer read the source and the first reviewer's observations before independently viewing all four original native files, so this is a technical review, **not a code-blind art verdict**. Raw files remain local under `.artifacts/phase2/p2008-bluff-input-02/`; the retained compact sheet is an index, not a substitute for these native observations.

## Invariants and projection significance

All three changed-input frames have the same camera basis. Relative to baseline, maximum component change is **2.9802322998317976e-8**, and basis-matrix Frobenius difference is **4.4703483997876616e-8**. The normalized X/Y/Z-axis angular differences are respectively **0**, **3.26261159e-8** and **2.91510707e-8 radians**. Camera origins are exactly equal, as are player positions, selected stand XZ/offset/lateral, ground height, surface state, frozen clock, Sun transform/settings and actual terrain readbacks: **mesh_size 48, mesh_lods 7, vertex_spacing 1.0**. All frames read back the expected active diagnostic shader and enabled process-local dunes.

The camera-rig origin itself has a **2.3841858e-7 m Y** difference after baseline; the final Camera3D origin is unchanged. Thus “exact camera” must not be used to describe all stored transforms. The run correctly failed its exact final-camera-basis comparison.

For scale, the recorded FOV is 70° and viewport is 1920×1080. A CPU projection check used the actual basis matrices as columns: construct baseline camera rays `r=(x/f,y/f,-1)`, transform into world by `B0*r`, then into the changed camera by `inverse(B1)`, and reproject with the same focal length. A 257×257 grid covering the image, including its corners, gives maximum displacement **0.000046314 pixels** when 70° is vertical (focal length 771.199924 px). Since the manifest does not record `keep_aspect`, repeating with 70° horizontal gives **0.000051318 pixels** (1371.022086 px). These are sampled projection estimates, not an engine pixel-difference measurement or a formal whole-frustum bound. Equal origins make the ideal perspective result independent of subject depth. This numerical perturbation cannot plausibly explain the visible multi-pixel edge changes; nevertheless, the recorded invariant failure remains a failure.

Logs contain the three explicit catalogue camera-equality errors and one `instance_reset_physics_interpolation()` deprecation warning. No `SCRIPT ERROR`, `Parse Error`, `Compile Error`, `SHADER ERROR` or shader-compilation failure was found. Logs are **not** described as clean. Terminal exit 1, PID `15876` absent, and subsequent lock release were confirmed by the launching parent; this reviewer did not launch or terminate an engine or alter the lock.

## Native observations

| Original native suffix | Independently observed result | Technical limit |
| --- | --- | --- |
| `__mask_baseline.jpg` | Large dark triangular intrusions remain along the upper left cap, with a toothed lower boundary across the large left bank and the right bank. | This is the exact final mask displayed unshaded; white/black are mask sides, not an accepted sand/mineral palette. |
| `__height_only.jpg` | The upper cap remains toothed. The near lower-left foot gains conspicuous repeated vertical/scalloped lobes, particularly across roughly x=0–800, y=420–520. It does not improve the large boundary. | Four-height reconstruction changes only the final height fade. It leaves height-dependent bluff noise and both slope terms unchanged. Reject this isolated reconstruction as a boundary improvement at this view. |
| `__control_only.jpg` | The principal cap and foot boundaries look very close to baseline, including the large teeth. No convincing structural improvement. | Stock control is already interpolated on valid `bilerp` fragments; this variant mostly changes the nearest branch. An unchanged appearance does not prove painted control irrelevant, nor record which branch each visible pixel used. |
| `__slope_only.jpg` | Some transitions become softer, and the deepest upper-left intrusions are locally reduced. Large cap teeth and the lower boundary teeth remain on both banks. | This tests interpolation of raw height gradients followed by normalization. It is not a spatial metre-radius filter and changes near interpolation as well as the nearest branch. It is insufficient as a standalone correction. |

All three inputs are insufficient **as implemented and viewed independently here**. Do not combine them by default or enable the preferred height-only patch: the height experiment introduces a visible new defect. The observations support sensitivity to slope reconstruction and height-fade reconstruction; they do not identify a single root cause for the remaining large teeth.

The earlier `../bluff-mask-01/findings.md` establishes that the shape exists before lighting. This round still does not prove a terrain-LOD/silhouette defect. The generated Terrain3D shader uses morphed height samples in `vertex()` and interpolates `v_vertex`/UV over the rendered terrain, while fragment normals use the height-lattice stencil. Reconstructing a bilinear height for the mask can disagree with the rendered triangle's height; the new scalloping is consistent with such a disagreement, but that is an inference, not a measured diagnosis of the actual Gull data. Nothing here justifies physical height/control edits, LOD changes, another Sun-bias pass, or broader mineral coverage.

## One next bounded causal experiment

If another diagnostic is scheduled, compare the original exact mask against a **noise-neutral mask** built afresh from the original shader, replacing only:

```glsl
float bluff_patch = coast_noise(v_vertex.xz * 0.16 + vec2(v_vertex.y * 0.025));
```

with `float bluff_patch = 0.5;`. Both existing `(bluff_patch - 0.5)` perturbations then become zero without changing thresholds, control, height fade, slope reconstruction, geometry, lighting normals or LOD. This removes a remaining shared, untested input from both slope classifiers with **zero additional texture fetches**. Use two unshaded masks and the same fixture; do not compound the height/control/slope variants from this run. It is a causal probe, not a proposed shipping material or coverage adjustment.

If large teeth remain, the bluff-noise perturbation is not necessary for them at this view; then inspect which steep/painted branch supplies the maximum and the underlying height-gradient field before choosing a heavier spatial filter. If they collapse, isolate the existing height-dependent noise phase versus the XZ noise separately. Either outcome keeps palette/art direction as a separate question. No new diagnostic was prepared or launched as part of this review.

## Provenance receipts

Actual source is `ebd5c6258fdfbabcc0bcb1b4b1b6b93dbf19df66`; intervening changes above production `1f3e6397e52e186eb98c22eade58ef4303728bee` were catalog/top20 only. The config ZIP SHA-256 is `f28a8ac9e5001c9dd4f435832ebfae777280a94145a759d003c66b6f5b436c12`. Production gates remain off; the retained ZIP enables this diagnostic process. Original installed shader hash is `47ba3113bb856300414b421ab06b164b423346767e46a8e3b83a762f77afed03`, matching the prior mask diagnostic. This review checked each actual shader readback against its expected manifest hash:

| Variant | Actual shader SHA-256 | Original native JPEG SHA-256 |
| --- | --- | --- |
| Baseline mask | `b91c1bc5678fb5b1e4491905fdbbb3fd8d08749d2aed386896630840dfabb6e7` | `ed146caa791ac4293f9d9b372c26e3aeae64544e751178eb268a51f5c9ed5138` |
| Height only | `f262d65366ace30f0ac6cdaa1a46d35f5500ca418c695bb836ac77dbb7831379` | `24080a2a53345a2294ed43fb09ff7378cfac218569ef2f39e22e1bf53e6b12a1` |
| Control only | `ac836d27d4a0699a856b0590a2d4697d992a64de4e22e3f2c6d5d4db030114a6` | `70902b3525cc77c84484ad6423d3a1160eeb63d1216ec9d15db5df4493f86c3e` |
| Slope only | `a9a02100f03e14dfc02cd440fc7c4a535c5153c5f0db2ab1d30afa79db2c85a5` | `b9580b41a4c8a9876eb981fe586cddd71d5902a45400250d210f3ce50d2904ee` |

Stdout SHA-256: `ebedb0619e4da2c88a05a36b8522c7cf198da0705e47b2e11dbaaa7d4f944a0a`. Stderr SHA-256: `24426757117a465a2321383a5d57f533519205c64528d1fc40aa8f7f3d6a73bf`. Retained wrapper/snippets/logs and their receipts are adjacent; `numeric-verification.json` separately preserves the launcher's failed status. Fog/tonemapping, JPEG compression, moving vegetation/creatures and different elapsed real time preclude treating global image differences as calibrated mask-value changes. No P2-008 fix, native beauty acceptance, performance claim, or regional bar closes.
