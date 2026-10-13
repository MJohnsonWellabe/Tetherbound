# F36#0 Solmane wing root — blocked, candidate OFF

- Baseline: `tb/codex-creatures` `c78a3afb7de1d8a460461898298f623d3b830094`; current `origin/main` `1f6d7e210888244d544ea4290770cb844ca21a66` is already an ancestor.
- Scope: localized topology only. Existing standing height stays 6.70 m; preserve installed model, candidate texture/UV/skin, and terminal repose.
- Read-only GLB census (reproducible with `tools/art_pipeline/analyze_solmane_wing_root.py`): 23,482 vertices, 29,398 triangles, 26 bones, 6.700001 m; weld at 0.0001 m reproduces 2,702 boundary edges and 107 edges with >2 incident faces.
- The forward root is not one closed hole: largest local left/right boundary networks have 94/99 edges and 6/8 branch vertices; each spans ~0.9–1.0 of both UV axes and mixes wing-root with spine/neck skin weights.
- Nearby local contours also overlap across wing_1/wing_2/spine ownership. Closing or filling them would bridge feather layers, stretch UVs across the atlas and alter deformation; no localized patch is justified from current topology evidence.
- Candidate input SHA-256: `1a8a5389a1936e98b65f75a5a066ea6841ee6f34f0ef1a9f84352b809332064d`. No mesh, material, animation, species scale or runtime gate changed.
- Native packet: `D:/tetherbound/.artifacts/codex-service-creatures/solmane-wing-root/native-capture-request.json`; do not run until a bounded patch exists. If useful, capture only the current-source baseline in the root-owned native session.
- Next per issue #572 (13 Oct, 6:05 AM CT): F36#0 giant variants use Guardian, Fulgocobra and Voltarach as the failing stands. Try camera/stand framing first; any growth change needs a named authored fit in `CREATURES.md` and never shrinks a creature. This Solmane session did not take that next item.
- Verdict: BLOCKED, not READY; no F36 criterion closes.

