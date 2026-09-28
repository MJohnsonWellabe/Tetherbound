# Cloudreach bank material code review

Scope: the initial uncommitted bank-material candidate in `D:/tetherbound/visual-acceptance`, before the coordinator's planned test/fast-path changes. Read-only source review; no Godot process started, no visual judge reports read. This report is the only written artifact.

## Blocker

- **Existing contract tests will fail after extraction.** `shaders/cloudreach_cliff.gdshader:3` moves the implementation to an include, while `tests/test_cloudreach_cliff_strata_contract.gd:7` and `:20` still read only the wrapper. Assertions at lines 8–12 and 21–23 can no longer find the extracted symbols, and line 25 requires the old literal `NORMAL=normalize` formatting. Update these tests to inspect the include together with its caller and preserve the actual geology assertions. This is a definite source-level failure, not an engine-run result. The coordinator has acknowledged and owns the fix.

## Correctness findings

- No additional functional blocker found in the requested scope.
- All 16 extracted uniform declarations, including values, color/normal hints, filtering, and repeat settings, match the previous cliff shader exactly. An automated text comparison confirmed the extracted fragment body is identical after replacing ALBEDO with the output argument and moving the existing world-to-view normal conversion to the caller; roughness remains 0.96 in that caller. Existing cliff shading is therefore preserved by this extraction.
- The crown shader computes world position with MODEL_MATRIX and world normals with MODEL_NORMAL_MATRIX, normalizes the interpolated normal in fragment(), evaluates both material families in world space, and converts the resulting normal to view space once. The fully turf endpoint preserves the turf function, roughness 0.98, and geometric normal. No added vertex displacement exists.
- The slope mask has correctly ordered cosine endpoints: cos(56 degrees) < cos(34 degrees). More vertical upward-facing banks receive rock; flat terrain remains fully turf. The bounded +/-0.055 breakup intentionally shifts the nominal boundary: slopes below approximately 27.9 degrees remain wholly turf everywhere, and slopes above approximately 59.7 degrees are wholly rock everywhere.
- `cloudreach_environment_materials.gd:70–74` copies every non-null value from the actual built cliff material, including both texture resources. Since both shaders use the same include, any unset parameters retain identical shader defaults. No turf uniform collides with the rock uniforms. Both current world factory calls pass the populated geology material after its configuration is set. No other ground() caller was found in the repo search.
- `Shader.get_shader_uniform_list()` and dictionary iteration have an existing repository precedent at `tests/test_cloudreach_summit_paving.gd:15`; the supplied ShaderMaterial has an assigned shader before use. The new include/out-argument shader structure has no apparent language/API violation. Engine compilation remains the coordinator's runtime check.
- The world diff contains exactly the two material-factory changes at lines 802–803. Mesh generation, vertex placement, surface topology, collision, and traversal code are unchanged. The JSON diff only introduces `ground_rock_transition`.

## Cost risk

`shaders/cloudreach_surface.gdshader:23–24` evaluates the full geology function and turf function on every ground fragment, even when the mask is wholly turf. That raises texture lookups from two to eight and adds the cliff's procedural ALU across all visible upland surfaces. This is a credible Compatibility/ROG Ally cost risk, not a measured frame-time regression. A fully-turf fast path is appropriate; the coordinator has acknowledged and plans that change. The two-time material parameter copy is initialization work and is not a frame-loop concern.

Acceptance remains conditional on fixing the contract tests and the coordinator's shader/runtime and visual validation. No GPU timing or rendered appearance claim is made here.

## Final candidate re-review

**Disposition: no code blockers.** Re-read the updated surface shader and contract tests and checked that the other scoped diffs remain unchanged. No Godot process was launched and no visual judge material was read.

- The original blocker is resolved: `tests/test_cloudreach_cliff_strata_contract.gd:8` and `:21` now inspect both the cliff wrapper and the shared include, and line 26 tolerates spaces in the NORMAL assignment. The coordinator reports focused engine tests passed (9/149, zero failures); that runtime result was supplied by the coordinator, not independently rerun here.
- `cloudreach_surface.gdshader:18–19` now classifies actual triangle slope using the cross product of world-position screen derivatives. These derivatives lie in the triangle plane, so their normalized cross product is a world-space geometric normal. Absolute Y removes screen-coordinate/winding sign ambiguity; the mask does not depend on which way the camera views the face. A steep triangle can no longer receive turf merely because its interpolated vertex normal points upward. The repository already uses cross products of fragment derivatives for terrain normals (`shaders/terrain_ground.gdshader:551`, with Compatibility derivative aliases at lines 60–61).
- This is intentionally a flat geometric slope classifier, while lighting and triplanar detail still use the smooth world normal at lines 15 and 29. It does not accidentally turn lighting into flat shading. Adjacent triangles with different geometric slopes can receive different coverage, so visible faceting remains a visual-review concern rather than a code defect. Absolute Y also treats horizontal underside triangles as horizontal; that does not violate the current crown/bank scope, and the previous ground shader was turf on those faces as well.
- The fast path at lines 20–23 is mathematically safe with the configured positive breakup strength: `noise3` is bounded to [-1, 1], so `up >= grass_slope_cos + edge_breakup` guarantees the full expression would yield turf=1. It retains the original turf albedo, roughness, and engine-provided smooth NORMAL. The expensive rock evaluation is now limited to the other branch; actual GPU savings and boundary appearance remain render/performance checks. Full-rock fragments still evaluate the two turf samples, which is a smaller remaining optimization opportunity, not a blocker.
- The geometric normal is evaluated before the branch. There is no world/view-space mismatch, changed geometry/collision, or new correctness issue found in this final diff.

Final acceptance still depends on the coordinator's visual/runtime evidence; this disposition covers source correctness only.
