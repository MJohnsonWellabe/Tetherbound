# BELOW6-COREV2 (F41#1 heartwood core, after the 5.66 landing): PARKED, NOT SENT

Judges on the landed core: "a flat gradient slab, hard edges"; asks: internal arcs, bloom falloff, light cast onto the bark.

Flag `stormheart_presentation.json heartwood_1111.core_v2` (OFF): a core shader (`scripts/world/stormheart_heartwood_core.gdshader`) with per-facet value, an edge lift and internal arc lines; core lights 2.0 -> 5.0.

Three CPU looks (`_sheet_cpu_landed_vs_v2.jpg`: landed core left, v2 right; the third look):
1. The arcs drew as a thick horizontal white bar and the facets speckled (a quantised hash of the facet normal).
2. Arcs made near-vertical and the facet value continuous: speckle gone, a horizontal white band remained (the up- and down-facing ledges between crystal segments took the edge lift).
3. Edge lift limited to upright facets: the crystal is a deeper blue with clear facet contrast, **but a thin horizontal white line still crosses it at mid height** (an arc where its phase turns flat), and the roots are not visibly bluer at light energy 5.

What worked: the per-facet value. It gives the crystal depth and answers "flat gradient slab" on CPU.
What did not: arc lines from a phase function. Two shapes both produced horizontal bars. Bloom and falloff cannot be seen on CPU at all.

Parked under the two-failed-attempts rule for the arc approach. A next try should be different in kind: arcs as geometry inside the crystal (the vein tubes already on its surface read as lightning in every frame), and the facet value alone as the shader. Not built.
