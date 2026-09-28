# Mask-space reconstruction 04 — UNAPPLIED proposal

The requested mechanism is reviewable, but the CPU results expose a significant coverage-expansion risk. **Do not treat this as a shipping repair or apply it merely to obtain a smoother edge.** No production file, engine, GPU, capture harness, configuration or source-safety certification system was changed.

Files beside this review:

- bluff-maskspace04-snippet.gdshader.txt: exact insertion, including guards and their stated limitation.
- bluff-maskspace04-proposal.patch: generated unapplied diff against current coastal_rock_material.gd.
- bluff-maskspace04-profiles.py / .json: reproducible CPU guard/profile checks and full numeric results.

## Mechanism and unchanged behavior

The original final bluff expression still executes first. A new shader-only uniform, coast_dune_maskspace_enabled=false, optionally replaces just that scalar for valid bilerp fragments. It evaluates the current steep and painted classifiers at each stock index_normal/coast_paint corner, takes the corner's max, then interpolates the four complete coverage values with the existing weights.

It does not alter either threshold pair, the current fragment's bluff_patch noise value or amplitudes, rendered-height fade, palette, lighting normal, roughness/normal-response formulas, Veilfall exclusion or any vertex/height/control/collision/LOD data. Original normal/material response still follows the resulting coverage, so changed coverage intentionally changes where existing sand/mineral responses apply; it does not claim pixels' normal response stays identical.

The two branches are combined at each corner before reconstruction. Baseline instead normalizes the interpolated unit normal and interpolates paint, then performs both nonlinear smoothstep classifiers/max. This is an isolated order-of-operations experiment. It is not the earlier raw-gradient interpolation experiment, another height reconstruction or a palette pass.

**Additional texture reads: zero.** The valid bilerp path already supplies all four normals, heights, control words and weights. No texelFetch, texture, textureLod or textureGrad call appears in the insertion. Nearest fragments do not enter the block or read uninitialized extra normals/heights.

## Fallback and safety limit

Disabled gate, nearest branch, fully excluded Veilfall interior, nonfinite/bad weights, missing layer, remapped/cross-region corner coordinates, known corner holes, nonfinite corner heights/normals or nonpositive normal Y leave the original computed bluff unchanged. A conservative two-texel positive-edge margin keeps the full stock eight-height normal stencil inside one installed region. This intentionally falls back even at otherwise valid region seams.

**The other four normal-stencil neighbors' control/hole bits are not fetched by the stock fragment code.** This proposal does not infer their absence from finite normals or claim new hole safety for those samples. Full stencil hole checking would require four extra control texelFetch reads (at offsets (1,2), (2,1), (2,0), (0,2)) and coordinate validation. That is a separately quantified alternative, not hidden in this zero-extra-read proposal. Existing stock normals are reused unchanged.

The near/nearest switch and the conservative region-edge fallback can create a material discontinuity where this different classifier turns on/off. Preserving baseline fallback is necessary but does not establish a seamless distance/region transition.

## CPU profiles

The evaluator reproduces the generated shader's four forward-difference height normals, independent normalization, bilinear weights, final normal normalization, interpolated painted weights and both classifier formulas. It uses the current config thresholds (0.38/0.72 and 0.70/0.90) and 1 m spacing. All synthetic surfaces are above 3.5 m, so the unchanged height fade is exactly one. Profiles span -4 to 8 m in 0.001 m steps, using offsets (0.173, 0.317) to avoid sampling only lattice vertices.

Sharp transitions use a continuous softplus ramp of width 0.12 m reaching slope 3 (about 71.6 degrees); the soft case has width 2 m. Diagonal ramps use perpendicular coordinate (x+z)/sqrt(2). These are analytic synthetic inputs, not extracted Gull terrain data. Integrated coverage is the area under a 1D scalar profile, reported in equivalent fully covered metres, not projected pixels or island area. Half-coverage displacement is signed along the profile; negative means mineral begins earlier.

| Profile, noise 0.5 unless stated | Integrated coverage change | Half-coverage displacement | Implication |
| --- | ---: | ---: | --- |
| Flat, painted/unpainted | 0 | no crossing | Constant sand endpoint preserved |
| Constant steep, painted/unpainted | 0 | no crossing | Constant mineral endpoint preserved |
| Sharp flat→steep, unpainted | +0.244582 m | -0.245215 m | More mineral despite unchanged thresholds |
| Soft 2 m transition | +0.027693 m | -0.013529 m | Smaller but nonzero coverage shift |
| Sharp diagonal | +0.262969 m | -0.213802 m | Direction does not remove expansion |
| Painted sharp transition | -0.088807 m | +0.084621 m | Not a simple uniform dilation; branch weighting matters |
| Diagonal paint+slope transition | +0.200781 m | -0.213802 m | Paint transition does not ensure neutrality |
| Finite steep band between flat caps | +0.489164 m (+13.933%) | -0.245215 / +0.245215 m | Expands both mineral boundaries; gray-wall risk |
| Sharp transition, fixed noise 0 | +0.170557 m | -0.172486 m | Expansion persists at low perturbation |
| Sharp transition, fixed noise 1 | +0.309207 m | -0.311302 m | Expansion persists at high perturbation |

The finite-band baseline integrates to 3.510836 m; candidate integrates to 4.0 m. Maximum pointwise coverage difference is about 0.549777. Those are substantial material changes, not tiny precision noise. Full profile values/crossings and percent changes are in the JSON.

The CPU near-to-nearest discontinuity envelope remains as high as 1.0 for the sharp examples; the diagonal candidate reaches about 0.9998. The soft case remains about 0.4083. These maxima compare hypothetical near/nearest evaluation at the same coordinates, not a rendered camera sweep or a prediction that the switch occurs at the worst point. This proposal does **not** solve the distance seam risk.

CPU checks pass for unchanged constant planes; nearest/missing/remapped/corner-hole/nonfinite/weight/region-edge baseline fallback; valid negative-world coordinates resolved inside a region; zero added texture calls; and the exact current insertion anchor. The unapplied patch also passes git apply --check --ignore-space-change. No engine parser or shader compiler has run.

## Review decision

Keep this proposal unapplied. It is a precise, inexpensive probe of scalar reconstruction order, but CPU evidence does not support calling it a coverage-preserving repair. A later native diagnostic could determine whether it reduces Gull's teeth; it must also measure lost sand coverage and reject broadly increased gray mineral coverage. Such a diagnostic is not prepared or authorized here.

The next implementation decision belongs after reviewing these expansion and seam results. Do not add compensating palette/threshold changes to make this candidate appear successful: that would lose the current causal isolation. Nothing here establishes the actual Gull branch dominance, its hole neighborhood, rendered edge displacement, performance or visual acceptance.
