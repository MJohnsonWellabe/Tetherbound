# Colony 08: unapplied fuller dune tuft proposal

This implements the proposed eight-leaf dune clump in an unapplied scratch patch. Three leaves (indices 0, 3, 6) have 60% of the existing leaf-height multiplier and a .026m base half-width instead of .018m. Five leaves retain the existing height/width variation. Three stem centers form a .045m-radius triangle with at most .012m deterministic local root jitter. Full blade count assigns indices 0–2, 3–5 and 6–7 to the three centers, placing one short basal leaf on each center. Four segments and the existing pointed-tip topology remain.

The comparison control is **colony07 zero-shift coverage with the existing five-leaf / 54,000-requested-tuft mesh**. The candidate uses the identical zero-shift shader, eight leaves and 36,000 requested tufts. Colony06's .18 shift was rejected; zero shift and this mesh remain visually unjudged. The config stays `enabled: false`. No production file, engine, GPU, render lock or capture harness was changed or launched.

## Review files and application boundaries

- `colony08-proposal.patch` is the complete proposal against the source hashes in `colony08-checks.json`. It includes the unchanged colony07 zero-shift probability proposal plus this mesh/config delta. It passed `git apply --check --ignore-space-change` against the current production source without applying it.
- `colony08-mesh-only.patch` contains only the mesh and candidate config delta **after** `coastal-colony07-proposal/proposal.patch`. It was applied to that exact preimage in memory and checked to produce the same complete candidate. Use this when reviewing or integrating on top of colony07; do not apply both colony08 patches.
- `colony08-grass-field-preview.gd` and `colony08-cover-preview.json` are exact review previews. The preview controller includes colony07 uniform forwarding. No runtime ZIP is prepared.
- `colony08-build.py` rebuilds only colony08 scratch outputs, verifies pinned source/dependency hashes and false production gates, and runs bounded CPU/source checks. `colony08-checks.json` records results, source/dependency/output hashes, per-leaf values and allocation arithmetic. `colony08-file-hashes.json` also hashes the builder and this README.

The mesh delta introduces one optional dictionary, `ground_cover.dune_tuft_shape`, read at mesh construction. Near and LOD mesh builders forward the same dictionary. Public `surface_tuft_mesh` retains its original call and defaults. All geometric changes occur inside `dune_tussock` branches; ordinary profile/config files are absent from the patch. Empty/default recipes preserve the existing dune fan.

| Tunable | Default | Candidate | Bound |
|---|---|---|---|
| `basal_blades` | `[]` | `[0,3,6]` | Only emitted blade indices can match |
| `basal_height_scale` | 1 | .6 | .1–1 |
| `basal_half_width_m` | .018 | .026 | .001–.05 |
| `stem_count` | 0, retain existing fan | 3 | 0–8 |
| `stem_radius_m` | 0 | .045 | 0–.1 |
| `stem_jitter_m` | 0 | .012 | 0–.05 |

Dimensions above are authored mesh dimensions. The existing `.85` shader width multiplier scales both blade widths and root X/Z offsets, so the nominal stem-center radius renders as .03825m before arc/wind deformation, and local root jitter is at most .0102m. The patch deliberately preserves that shader behavior. Short leaf height is carried through UV2.y, which the existing shader uses for height and blade arcs. Leaf tint IDs, taper, normals, world-origin hashes, lattice assignment, clearances and terrain sampling remain the existing implementation. Reducing tuft count changes allocated slots; it does not introduce time-varying/random placement. Blade-count changes alter local leaf yaw/UV2 IDs, so cross-variant leaf identity is not claimed.

## Source and CPU checks

The builder applies both patches in memory with exact old-line anchors and checks cumulative and incremental results agree. Reversing only the added mesh source edits recovers the entire zero-shift controller exactly; the shader equals the colony07 candidate snapshot. CPU mesh-loop transcription verifies ordinary meshes ignore the populated recipe for 12 blade/segment/keep combinations, default dune recipes match empty recipes, candidate geometry has finite vertices/in-range indices, all eight tips remain pointed, basal leaves occupy distinct stems, and kept LOD blades retain the full mesh's vertex/index/UV2 prefixes. Ordinary topology remains `2 * blades * (segments + 1)` vertices and `2 * blades * segments` triangles; dune topology remains `blades * (2 * segments - 1)` triangles.

These are source and Python checks, not execution of the GDScript mesh builder. Godot parsing, actual ArrayMesh contents, native shader/mesh binding and visual acceptance remain unverified. No claim is made that a source check replaces native proof.

**Native-discovered correction:** root subsequently ran the actual ArrayMesh probe. Its 24 ordinary/default comparisons passed, but the JSON-loaded candidate failed basal height: blade 0 UV2.y was `.971844673` instead of `.583106804` (`.6 * reference`). Godot's `Array.has(integer blade)` did not match the JSON float indices. The first Python transcription used numeric membership that equated integers and floats, so it missed this engine behavior; its initial candidate-height conclusion was insufficient. The corrected patch explicitly checks `basal_blades.has(b) or basal_blades.has(float(b))`. This accepts either exact numeric index type without converting strings, booleans or fractional indices. The revised CPU checks reproduce the old strict-membership miss, emulate JSON numbers as floats, check integer/float/mixed recipes produce equal meshes, and reject wrong-type/fractional entries. Root's rerun of the corrected actual ArrayMesh probe is pending; the prior native failure is preserved in `colony08-checks.json` and `.local/phase2/colony08-mesh-probe02.log`.

## Exact allocation arithmetic

The unchanged profile uses a 56m radius, 2m lattice cells, .62 center bias, 16m cull tiles, nine layers and no active LOD/far thinning. The colony07 CPU lattice transcription reproduced the native06 57,836-instance control. This proposal reuses that pinned source-derived arithmetic and rechecks its layer sums and mesh topology; it does not claim a new native allocation measurement.

| | Zero-shift control | Fuller candidate |
|---|---:|---:|
| Requested tufts | 54,000 | 36,000 |
| Allocated instances | 57,836 | 38,760 |
| Leaves / segments | 5 / 4 | 8 / 4 |
| Vertices per tuft | 50 | 80 |
| Indexed triangles per tuft | 35 | 56 |
| Full-ring vertex equivalents | 2,891,800 | 3,100,800 |
| Full-ring triangle equivalents | 2,024,260 | 2,170,560 |
| Tiles / layers | 52 / 9 | 52 / 9 |

Control layer instance counts: `46968 + 5088 + 2432 + 1200 + 888 + 480 + 364 + 256 + 160 = 57836`. Candidate: `32136 + 2544 + 1824 + 900 + 444 + 400 + 208 + 192 + 112 = 38760`. Candidate totals are `38760 * 80 = 3100800` vertex equivalents and `38760 * 56 = 2170560` triangle equivalents. Actual ArrayMesh vertex storage is shared by instances; these products describe instanced full-ring geometry equivalents, not unique CPU mesh-buffer allocations or submitted/drawn counts.

There are 32.98% fewer tuft centers and 7.23% more full-ring vertex/triangle equivalents. Fewer centers may enlarge visible empty ground despite fuller plants. Wider low leaves may darken the base, increase overdraw or intersect sloping sand; the shader samples one terrain height per tuft. Existing wind displacement uses the full blade height variable even for short leaves, so their relative sway may be stronger and needs motion review. No performance improvement is claimed. Terrain walls, existing colony gaps and the distant density band are untouched.

Stop here for source review. A later geometry-aware native comparison must use zero shift on both sides and explicitly expect different mesh/counts; the colony07 harness's identical-geometry assertion cannot be reused unchanged.

## Root integration receipt

This proposal is now applied behind the unchanged false gate. The earlier pending-rerun statements describe preparation. Root actual ArrayMesh probe03 passed47checks, including24exact ordinary/default comparisons; the JSON-float regression is now in the production test suite. Focused34tests/87990assertions and the subsequent8tests/132assertions JSON regression run passed. These runs overlap and must not be summed as unique tests. Native appearance, wind/contact and frame cost remain unverified. See validation.json.
