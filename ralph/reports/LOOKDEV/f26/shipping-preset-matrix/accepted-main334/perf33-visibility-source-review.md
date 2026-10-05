Bounded independent PERF visibility source review

Candidate: origin/tb/perf33e131afb6f1a693951dc8c621ec83e882491f1b. Reviewer:/root/f26_lookbar_review. Read-only source review; no engine/image judgments or source changes.

Verdict: NOT fully cleared for general cull safety. scripts/world/detail_cull.gd124–153 ignores individual MultiMesh instance basis/scale. Object size uses raw meshAABB with node scale; combined spread uses instance origins. A1m mesh with two nearby origins and10x instance scale can get roughly309m reach instead of3.1km, so visible geometry can disappear before its intended pixel threshold. Compute transformed instance bounds or conservatively skip unsupported transforms. Actual Cloudreach bridgekit applies per-instance transforms; that source example alone does not establish a native bridge regression (some module scaling shrinks).

Original fixes present: pickup_glow.gd237 explicitly skips runtime-filled glow batches; unknown/wide spread stays unranged at detail_cull162–170; Stronghold descendants exempt at179–189; static_mesh_batch149–154 preserves parents with drawn/scripted descendants;177–201 excludes alpha blending, billboards, object-space triplanar/custom vertex materials and unsafe nextpasses. local_light_shadow_fade73–79 retains enclosed shadows until light extinction.

This is a bounded source verdict, not wholePERF/Jolt/physics/visual approval. No blocked candidate was benchmarked. Exact safe main-compatible PERF pin/CLI remains requested on#525. Current shipping release performance remains FAIL at the owner Medium60average/40low target.

The proposed resolution-sensitivity diagnostic was not launched: accepted334 tools/capture_lookdev_route.gd line90 forces root.size from authored lookdev_routes.capture.resolution1920x1080, overriding launch --resolution. Existing packaged route cannot perform the proposed960x540 comparison by that CLI. No source/helper/harness workaround was built.
