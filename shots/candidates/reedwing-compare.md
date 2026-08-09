# reedwing — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/reedwing/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 |
|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 8 | 6 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 7 | 6 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 8 | 4 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 23 | 16 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | No | **YES — no webbing, wings unreadable** |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [x] species feature reads as bolted-on rather than grown — **b only**: broad wing geometry fails to read as a distinct structure in the back view, blending into general body lumpiness instead of forming a clear feathered wing panel
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [ ] eyes uncanny
- [ ] anatomy deforms badly
- [ ] stops matching the reference at gameplay distance

## Chosen

**a.** b's feet fan into individual pointed digits with visible gaps and no connecting membrane — this reads as a clawed/land-bird foot, not the webbed waterfowl foot the brief calls for. a's feet show a continuous web flowing between all three forward toes with blunt, rounded (non-clawed) tips, matching the reference's webbed silhouette.

b's wings also do not read as a distinct "broad feathered wing" separate from the body — most visible in the back view, where the wing area is indistinguishable from general pebbly body texture, with no wing-panel edge or feather-layer break. a keeps a clear, distinct layered wing silhouette (visible feather rows, a defined wing-panel edge breaking from the torso) consistently across all four views — the wing reads as an intentional anatomical feature, not just in flattering angles. Two independent signature-feature failures on b (feet and wings) against two clean reads on a.

Minor note on the winner: a's neck reads slightly longer/more slender than the reference's stouter, more tucked neck — not disqualifying, still supports "long graceful neck," but worth a small proportion pass later. Where the runner-up did better: b's torso mass/roundness arguably reads a touch closer to the reference's very compact, chunky round chest than a's slightly leaner body — the only respect in which b edges out a, and it doesn't offset the two signature-feature failures.
