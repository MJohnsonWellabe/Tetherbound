# Lightning capsule-segment independent source review

Scope: current `scripts/world/stormwood_lightning.gd`, `data/config/stormwood_surge.json`, and `tests/test_stormwood_surge_presentation.gd` in `D:/tetherbound/visual-acceptance`. This review supersedes the earlier tube, ribbon, and hard-ended segment dispositions. No source edits, engine runs, or current-candidate screenshot inspection were performed.

**Disposition: no source blocker identified for the checked-in configuration.** The new longitudinal distance profile directly addresses the hard-end mechanism diagnosed in `lightning-ribbon-artifact-review.md`. That is not a claim that the rendered defect is fixed; the current capture remains the acceptance evidence.

## Capsule construction and UV correctness

For each refined segment from A to B, the implementation computes its finite length L and unit tangent, chooses a constant radius r for that segment, and emits one quad with centerline endpoints A - r*tangent and B + r*tangent. Each endpoint has two signed transverse vertices. UV is `(side, r)`; UV2 is `(-r, L)` at the extended start and `(L+r, L)` at the extended end. Vertex/normal/UV/UV2 array lengths agree, and `[a,a+1,a+2, a+1,a+3,a+2]` references only those four vertices.

In the fragment shader:

- `max(max(-UV2.x, UV2.x - UV2.y), 0)` is exactly the longitudinal distance outside the original interval [0,L]. It is zero between the original endpoints.
- Division by radius converts that end distance to the same normalized units as transverse UV.x.
- `d2 = UV.x² + end_distance²` therefore supplies squared distance from the finite centerline, normalized by r², in the ribbon plane.
- `exp(-4*d2)` is smooth and nonnegative. The cutoff smoothly reaches zero at d2=1, including the extended centerline endpoints and transverse sides. This removes the old hard end truncation.

The radius and segment length are constant across each quad. Both triangles therefore use the same coordinate frame and profile; the diagonal introduces no attribute discontinuity. Perspective-correct interpolation is appropriate for this planar geometry. The unit view-plane transverse axis is mathematically consistent at the two endpoints of a straight segment, apart from its explicitly handled near-parallel fallback.

## Placement, culling, and runtime safety

- The shader applies MODELVIEW to positions and to the tangent with w=0, adds the transverse offset in view space, then applies PROJECTION once. Core and halo use identical logic. No double transform is apparent.
- CPU positions already include the longitudinal extensions, so the generated mesh AABB includes them. `extra_cull_margin=1` covers the remaining shader-only transverse expansion: current maximum halo radius is bounded by 0.095*4=0.38 m. This assumes the current unit-scale effect node; the shader does not implement arbitrary nonuniform object-scale compensation.
- Each primitive is one plane with culling disabled. There is no duplicate rear shell. The core uses normal alpha blending; halo uses additive blending; both retain scene depth testing, no depth writes, no shadow casting, and their shared 0.18-second lifetime.
- Geometry generation is deterministic: each path uses its own explicitly seeded RandomNumberGenerator, shared identically by core/halo builds. Their original finite centerlines match. Expanded endpoints differ by the intended radius ratio, producing a wider and longer halo capsule around the same finite segment.
- All current authored segments have nonzero Y differences, including individual segments on both sides of the return-leader apex. Fracture offsets remain XZ-only. Segment lengths/tangents are therefore nonzero and finite for the checked-in finite positive height. Radius modulation remains between 0.64 and 1, and all base radii remain positive. Length/index calculations are safe for the current nonempty paths.
- The prior camera-origin issue is addressed: the view vector now divides by `max(length(centre),0.0001)` before the cross product, then selects a finite fallback when the cross product is tiny. It no longer directly normalizes a zero center vector. Malformed nonfinite config or a collapsed object transform is not comprehensively validated; these are trusted local tunables, and no such current input was found.
- Sixteen paths now produce 632 independent segments: 2,528 vertices and 1,264 triangles per cached mesh. This is a bounded source count, not an on-device performance measurement.

## Remaining rendering risks

**Soft overlap can still brighten joints.** Capsule extensions intentionally overlap. Additive halo energy from several short segments or intersecting branches can accumulate into bright knots. The nominal 0.08 opacity is per contribution, not a total pixel ceiling. The new geometry removes hard end cutoffs but does not implement a union/compositing operation that guarantees uniform brightness. If the new capture has smooth bright blobs instead of triangular fans, inspect overlap density rather than treating that as a failure of the capsule-distance equation.

**Caps vary by viewing angle.** These are projected 3D ribbon-plane capsules, not a screen-space distance field. Nearly end-on segments can foreshorten, and the finite transverse-axis fallback can rotate the ribbon at extreme views. Check the actual player camera sequence before broadening that concern into a blocker.

**Visual support extends beyond authored endpoints.** Original branch/contact centerline endpoints are preserved, but rounded capsule support now extends by radius past them, including near the ground. Depth testing can clip that soft support against terrain. Earlier claims that only the exact original point participates in visual ground contact should not be applied literally to the extended geometry.

The seven short return leaders and stronger current core widths are presentation changes already present in the reviewed candidate. Their combined impact readability and contact shape are visual judgments; this review does not certify them.

## Gameplay and test scope

Warning-center selection/cleanup, host scheduling, damage resolution, networking, event deduplication, phase/restored-sky settings, 3 m damage radius, 1.2-second warning, and configurable 0.3-second final ramp remain unchanged by the capsule implementation. It adds no flash event or extra lifetime. Ground-leader Gaussian shading and reduced-motion progression remain as previously reviewed.

Cleanup remains resolved: unused fill uniform/setter/config, both misleading fill assertions, and unused emission config are absent. Remaining focused tests cover parameters/state/source wiring only, not capsule pixels. No historical test-count result is presented as a result for these current bytes.

## Evidence and identity

Re-read current mesh/material construction, config, and exact hashes; `git diff --check` passed. Source reasoning establishes the profile and culling bounds above. The coordinator reports that core-only isolation localized the earlier large wedges predominantly to the halo's hard ends; that reported observation supports the diagnosis, but this reviewer has not independently inspected that isolation or the in-progress capsule capture.

Current reviewed SHA256 values:

- `scripts/world/stormwood_lightning.gd`: `33DDF6E003EF008FEA4FE2B55D460816707400C15167672409A4A6603846C3D2`
- `data/config/stormwood_surge.json`: `048D74D534B92F85CEBC4C17DCA3A8E9FA74E91EDC7E442E5AD427E8F1BEE943`
- `tests/test_stormwood_surge_presentation.gd`: `2CAC76CEF71FCBA58C3456550C0B1821987D51CADE03C147D73AD7831FD0D83E`

## Final committed-source disposition — 20f86ab4698bb4dbd4273939234a548e7086a294

**PASS: no remaining source-review blocker found at this exact commit.** This final section supersedes the candidate identities and tuning-dependent numbers above. Inspected `git show 20f86ab46` and the full committed capsule/material construction. The scoped working-tree files have no diff against this commit. Other active work was excluded.

The final change contains only positive shape/profile constants: core exponent -4 becomes -6, the pale-core color blend becomes 0.85, primary/secondary branch width fractions become 0.48/0.26, and their terminal radius becomes 0.004 m. Config core endpoint radii are now 0.045/0.085 m, halo radius scale 1.8, and halo opacity 0.03. These preserve the capsule-distance equation, zero-alpha support boundary, deterministic shared centerlines, finite positive radii, UV2 semantics, array/index counts, and guarded camera-direction handling. The narrower halo reduces the maximum shader-only lateral expansion to 0.085*1.8 = 0.153 m, still comfortably inside the retained 1 m extra cull margin.

No scheduling, damage, radius, warning duration, final-ramp timing, reduced-motion policy, warning-center positioning, multiplayer, or phase/restored-sky behavior is changed by this final commit. Cleanup of unused fill/emission and misleading fill assertions remains intact. Soft capsule overlap and extreme end-on projection remain ordinary visual characteristics; no new source defect was found from the final tuning.

Validation distinction: I read the focused log summary `64 tests, 819 assertions, 0 failed`; the coordinator identifies this as the final source plus main validation. I did not rerun the suite or independently derive that log's source identity. The coordinator also reports a fresh 38-frame r7 code-blind scoped PASS. That visual result is separate evidence, not my own visual judgment. `git show --check` for the final scoped change passed. This review does not extend the scoped visual acceptance to whole F10 or unrelated work.

Recorded working-tree SHA256 values (files have no normalized-content diff against the final commit):

- `scripts/world/stormwood_lightning.gd`: `D54108BFD283109C4802099CD0FFCB562B4D8E08776866A755FAE0492A2540B6`
- `data/config/stormwood_surge.json`: `45328202C954512EBA830CC2C34CD768BBE62CC34A2C620BC53523332C3B8A97`
- `tests/test_stormwood_surge_presentation.gd`: `2CAC76CEF71FCBA58C3456550C0B1821987D51CADE03C147D73AD7831FD0D83E`

Exact Git blob identities, independent of checkout newline conversion:

- Lightning script: `02833d0cf7cb38ac23c31be7309e7292cc534757`
- Surge config: `695f738d82e9dfce1cf348529fe368f564d81580`
- Presentation test: `ae6d3b284860e069e144ad8132bbb4cec12da1a7`
