# meadowhart — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/meadowhart/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass. The saddle is modeled geometry, not colour, so it stayed in scope for the signature-feature score.**

| Criterion | What it asks | a /10 | b /10 | c /10 |
|---|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 8 | 6 | 8 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 8 | 6 | 8 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 8 | 5 | 8 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 24 | 17 | 24 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | No | **YES — saddle reads as bolted-on** | No |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [x] species feature reads as bolted-on rather than grown — **b only**: the saddle has no distinct raised pommel or cantle, reading as a flat pad melted onto the back rather than a modeled saddle object; the flank "leaf blanket" reads as bulbous growths/tumors and the haunch leaf tuft juts out as a sharp fin/blade rather than a layered leaf shape
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [ ] eyes uncanny
- [ ] anatomy deforms badly
- [ ] stops matching the reference at gameplay distance

## Chosen

**a**, over an extremely close c — this was the closest call of the roster. b is disqualified on signature-feature grounds: in side/three-quarter view the saddle has no distinct raised pommel or cantle, unlike a and c where pommel, seat, cantle, girth strap, stirrup and a satchel bump are all separately legible. b's antlers are also visibly thinner/sparser than the reference's fuller branching.

a and c are near-identical in quality: near-identical antler branching, near-identical saddle construction, near-identical slender leg proportions and modest antler size matching the reference. **A pixel diff between the two candidate rows shows a mean channel difference of only ~3.5/255** — close enough to flag to the art pipeline as a possible near-duplicate generation rather than two meaningfully distinct sculpts, worth checking before R0.6 spends rig work on both as if they were independent.

The pick of a over c is genuinely marginal: a's antler beams read very slightly bolder/thicker at small-size silhouette (the 40px legibility test), and its chest leaf point (the V-shaped leaf tip at the sternum) is a touch crisper. c did nothing worse than a — if forced to swap, c would serve equally well; c's saddle pommel horn was marginally more crisply defined than a's.

Shared, non-disqualifying defect across all three: the "layered leaves" mane/blanket down the neck and flank is sculpted as lumpy, potato-like rounded bumps rather than the flatter, feather-like overlapping leaf shapes in the 2D reference. Doesn't fail any hard-fail criterion but worth a sculpt pass once texturing begins.
