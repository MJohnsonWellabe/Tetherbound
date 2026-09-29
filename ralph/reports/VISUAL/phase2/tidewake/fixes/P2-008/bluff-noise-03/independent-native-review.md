# Independent technical review: Gull Rest noise03

**Capture integrity passes the checks reviewed here; the boundary defect remains.** I independently viewed both original 1920×1080 JPEGs after reading the task/source, so this is a technical review, not a blind art verdict. No engine, GPU, production change or additional harness was used. This review owns only this file.

## Verified scope and receipts

Raw evidence: .artifacts/phase2/p2008-bluff-noise03/manifest.json and its two JPEGs. Manifest is complete=true, failures=[], captured/planned counts 2/2. Actual source is 45c737025aec8d890270640d9fb2f279e9f7f5f2; its recorded tracked working-diff hash is the empty SHA256. Source hashes for coastal_rock_material.gd, phase2_capture_locations.gd, diagnostic wrapper, parent wrapper and launcher match the current reviewed files.

The original live shader hash is 47ba3113bb856300414b421ab06b164b423346767e46a8e3b83a762f77afed03, matching the earlier mask/input diagnostics. Both actual diagnostic shader readbacks equal their planned hashes. Wrapper lines 54–64 independently rebuild from that original code; the only variant-specific replacement is bluff_patch=0.5. Both receive the same unshaded exact-final-mask output. No input02 snippets are included. Added texture fetches are zero. The shared dune05 ZIP hash is f28a8ac9e5001c9dd4f435832ebfae777280a94145a759d003c66b6f5b436c12 and matches the actual file. Both production dune config gates still read false; this process enables them through the ZIP.

| Variant | Actual JPEG size / bytes | SHA256 |
| --- | --- | --- |
| mask_baseline | 1920×1080 / 117820 | 6a744ebbb8429814fe997b796b973a595d14d63c6145d8d6d8a4115bc12aa696 |
| noise_neutral | 1920×1080 / 117603 | 36686227049df8ecd0fbbc7a2e0be458f2401cae47f80920a6627d74539ea2ad |

Both file hashes and byte counts match the manifest. Player position, selected stand XZ/offset/lateral, terrain/resolved ground height, surface state, frozen clock, lens/projection/aspect, Sun settings/transform, camera identity and entire rig transform compare exactly. Final Camera3D origin is identical; basis maximum component delta is 2.9802322998317976e-8, below the declared 1e-6 bound. Both read back the same current production camera, native fullscreen viewport/window, and terrain mesh_size=48, mesh_lods=7, vertex_spacing=1.0.

Stdout ends NOISE DIAGNOSTIC OK: 2/2 frames. Neither log contains ERROR, SCRIPT ERROR, Parse Error, Compile Error, SHADER ERROR or shader-compilation failure. Stderr retains one existing instance_reset_physics_interpolation deprecation warning; do not call these warning-free logs. Root's retained bluff-noise-03/validation.json records launcher session 45373 exit 0, owned child 15012 absent and terminal lock release. I checked the files and source, not the original terminal tool event or process cleanup myself.

Manifest SHA256: f2a8c20c60abd5193f07872177da613591e2b9c7ee609350b96659423252c750. Stdout: 9b362ae4d9da45720e87647ab9e543458fcba4b8a184c07a73f73fad0cc703f4. Stderr: b166b7545c9ec5377c4302715f5ace6a7496f6c77d78e5bddb6c8d5b81cf2c2f.

## What the native images establish

Both retain the conspicuous dark triangular intrusions descending from the upper-left cap and repeated teeth along the large left bank's foot, including the rising boundary toward the central path. The right bank also retains its irregular dark/white edge. Neutralizing noise changes local transition widths/shading modestly; it does not remove the repeated large shape.

Therefore this particular bluff-noise perturbation is **not necessary** for the teeth at this Gull Rest view. Do not make noise frequency/amplitude or palette tuning the proposed repair. The result does not prove that noise never contributes elsewhere, that both slope branches contribute equally, or that terrain LOD caused the shape. These are unshaded material-mask images; fog/tonemapping/JPEG remain, and creatures/grass can move. Global pixel differences would conflate those changes.

Earlier retained evidence is relevant, with its original limits:

- receiver-01-ablation/findings.md: terrain-only caster depth addressed the fine self-shadow stripes while large cap/foot angularity remained.
- bluff-mask-01/findings.md: large shapes already occur in the final mask before lighting.
- bluff-input-02/findings.md and its adjacent height/control/slope shader snippets: height-only reconstruction added foot scalloping; control-only was visually close to baseline; slope-only softened some transitions but left large teeth. That run remains complete=false / exit 1 because of its exact camera-equality rule. The approximately 3e-8 basis perturbation is too small to explain its visible boundary changes, but the recorded failure is not reclassified as a pass.

## Likely mechanism and next coherent repair direction

The strongest remaining source-level hypothesis is **nonlinear slope classification reconstructed over the height lattice**, with the painted branch potentially preserving the same boundary. It is an inference, not a unique pixel-level diagnosis.

In .artifacts/phase2/terrain_generated.gdshader, lines 341–356 form the one-metre cell and four weights. Lines 362–379 switch to a single forward-difference normal when bilerp is false. Lines 412–428 fetch additional heights, normalize each corner normal separately and interpolate those normals when bilerp is true. coastal_rock_material.gd:139 normalizes that result again; lines 155–163 apply two smoothstep classifiers, multiply one by interpolated rock paint, take max, then apply the rendered-height fade. Thus the current material is not simply interpolating a scalar sand/mineral coverage field. A normal's direction, the painted weighting and the winning maximum can change across a cell before coverage is finally decided. The input02 slope experiment changed gradient interpolation, but still applied this same nonlinear classification afterward.

A small CPU example demonstrates the mechanism, not the actual Gull data: interpolate halfway between unit flat (0,1,0) and unit vertical (1,0,0) normals, then normalize. Y becomes 0.70710678. With the current unpainted 0.38/0.72 thresholds, the resulting mineral mask is about 0.0042, whereas interpolating the two endpoint coverage values gives 0.5. Smooth input normals therefore do not guarantee a smooth or spatially balanced coverage transition. Actual paint, corners, height fade and branch dominance remain unmeasured in these native images.

**Recommended next candidate: reconstruct coverage in mask space rather than thresholding an interpolated normal.** Under a separate default-off presentation gate, evaluate each existing valid corner's complete steep/painted coverage using its index_normal[i] and coast_paint[i], combine the two branches at that corner, then interpolate those four scalar coverages with the existing weights. Keep the original rendered-height fade, thresholds, bluff noise input, Veilfall exclusion, terrain lighting normals, material palette and all physical terrain untouched. In notation:

    corner[i] = max(steep(normal_y[i]), paint[i] * painted_slope(normal_y[i]))
    bluff = dot(corner, weights) * original_height_fade

This directly tests the untested order of reconstruction versus classification. It is not another height/control/normal intensity adjustment, and it retains installed mineral response wherever coverage is full. The near bilerp path already has all four normals, painted weights and interpolation weights: **zero additional height/control fetches** there. It is the inexpensive candidate to examine before a many-tap filter.

Limit the initial implementation/claim to valid bilerp fragments and preserve baseline fallback for absent/hole/nonfinite data. A shipping all-distance version must deliberately address the nearest branch and its transition: reconstructing the missing stock four-normal stencil costs five additional height reads and three additional control reads before any extra safety checks. Do not silently read uninitialized h[1]/index_normal[0..2], clamp across absent regions, or claim distance continuity from a near-only fixture. A world-space radius filter could follow only if mask-space reconstruction remains grid-shaped; it is not yet justified as the mandatory first 32–40-fetch solution.

This candidate may shift coverage even with unchanged thresholds. The rejected dunes05 gray-wall result makes that a material risk: it must not pass merely because a soft blur hides teeth by exposing more mineral. First compare CPU scalar profiles on constant planes, flat-to-cliff ramps, diagonal cap boundaries and negative-coordinate/region-edge cases; measure transition displacement and integrated coverage versus baseline. Then use the existing Gull mask fixture and ordinary shaded paired views to check both tooth suppression and retained sand caps/foot. Large coverage expansion, a new bilerp-distance seam or more scalloping is a rejection, not grounds to compensate with another palette pass.

No mask-space candidate has been implemented or rendered here. The exact dominant branch at Gull, the distribution of actual height gradients, whether bilerp is true at each visible tooth, and performance across all Tidewake distances remain unknown. The current result closes only the noise-neutral causal question; it does not close P2-008, the large landform/silhouette concern, grass-colony quality or any chapter acceptance criterion.
