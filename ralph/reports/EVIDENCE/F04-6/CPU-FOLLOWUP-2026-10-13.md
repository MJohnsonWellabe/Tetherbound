# F04 source follow-up — 13 Oct 2026

No new visual scores, engine execution or candidate artwork. Exact r13 baseline and r15 candidate remain preserved; visual_candidate_enabled stays false. Historic r13 single-judge6.5 is not a three-judge Medium/High acceptance or a comparable consecutive round.

## Dell ground contact

Actual3315 POSITION vertices from installed tether_pylon.glb, identity glTF node, transformed by scale1.6 and roll−78degrees using props.gd placement semantics (`root.y = ground - sink_m`). Yaw does not change vertex heights. With inherited sink−1.6(r14), lowest vertex is+0.4751m above anchor ground. With r15 sink−0.7, it is−0.4249m below anchor ground. Highest vertex changes2.1388→1.2388m. Full machine-readable audit and model hash: dell-contact-cpu.json.

This explains the reported floating and confirms the offset lowers the model. It does NOT prove terrain contact: props samples one ground height at the placement origin, while the toppled pylon extends across a slope. About0.42m penetration into the anchor plane may bury important detail. Do not replace native review with aggregate bounds or another speculative sink adjustment. Root-admitted Dell Medium r13/r15 before/after images must show real terrain, foot/extents, silhouette, and wall materials. No flat ground substitute.

## Vess rope readability

Ridge site config uses Rope_1 with before scale_xyz[6,1.4,0.06]. Installed asset bounds span0.557389×0.097859×0.606304m, making the before envelope approximately3.344×0.137×0.0364m before yaw. The narrow3.64cm depth supports investigating the historic weak-rope reading, but this is the envelope of the complete coiled asset, not a measured strand diameter. Its after override restores a ground coil; that alone does not supply the requested visibly cut dangling post end. Preserve the r13/r15 comparison first. A later separate candidate can address thickness and severed-end identity once the current fixed-camera view is judged; do not silently add it to r15.

## Next bounded request

Prepared packet: `D:/tetherbound/.artifacts/visual-takeover/aftermath-cb5e011813/capture-manifest.json`, exact sourcecb5e0118130be130e151b54677948a644723513b. Dell Medium baseline then candidate, each120seconds max/two PNGs. Fullworld memory admission remains unresolved and belongs to root. CandidateOFF and before/after state guards are implemented in probe but not yet native-tested. The full20process/40image matrix remains unrun. Direct settle is visual diagnostic only; earned fight, save/reload and co-op remain separate proofs. Purple wall surfaces and sword-hilt presentation require native context; no cause assigned from source alone.
