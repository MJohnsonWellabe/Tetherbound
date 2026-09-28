# Gull Rest controlled surface diagnosis

Five native Compatibility frames, 1920×1080, seed 2042. All five passed the
production-camera and selected-stand checks; camera displacement from baseline
was exactly zero. Both dune gates were enabled only for capture and restored
false. The local diagnostic source is retained as `diagnostic.gd.txt`; raw images
remain in `.artifacts/phase2/p2008-surface-01-ablation/`.

| Variant | Observed result |
|---|---|
| Baseline | Repeated fine ground bands and jagged light/shadow boundary on the left bluff |
| Ripple strength zero | Fine bands and jagged boundary remain |
| Shadow opacity zero, shadow map retained | Fine bands disappear; the cliff boundary is smoother, but trainer/contact shadows disappear too |
| Flat lighting normals | Terrain triangles become more visible; does not solve the defect |
| Dune grain and ripples removed | Fine bands and jagged boundary remain; underlying color noise is removed |

The shadow contribution is the dominant source of the fine bands. The procedural
sand ripple hypothesis is contradicted by the matched frames. Removing shadows
is a diagnostic, not an acceptable final change. Next measurement compares bias
and terrain vertex normals while retaining shadow opacity one. No visual gate is
accepted by this diagnostic; it is root technical analysis, not a code-blind art
judgment.
