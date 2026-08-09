# paddlenewt — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/paddlenewt/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 |
|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 7 | 6 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 6 | 6 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 7 | 4 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 20 | 16 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | No | **YES — spine crest is beads, not frills** |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [x] species feature reads as bolted-on rather than grown — **b only**: the spine crest is a row of round beads/nubs, not fin frills, contradicting the canon's explicit "frills running as a crest down its spine" — a different feature entirely, not a stylization of the right one
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [ ] eyes uncanny
- [ ] anatomy deforms badly
- [ ] stops matching the reference at gameplay distance

## Chosen

**a.** a's spine and head frills clearly read as translucent-fin-style geometry — layered, fan-like, grown into the back — matching the single most important signature feature from canon. b's spine crest instead reads as a beaded/segmented ridge, a different feature entirely, needing redesign as actual frills before it could be reconsidered. a's eyes are also large and round, closer to "huge round golden-orange eyes"; b's eyes are smaller and more oval/almond-shaped, weakening the intended cute/expressive read.

**Where the runner-up did better, flagged for follow-up on the winner:** b's tail is long and smoothly tapering, matching the reference much more closely than a's — a's tail is short and ends in an abrupt paddle-fin rather than a long taper. This is a real defect in the winning candidate; **lengthen/taper a's tail before R0.6.** b's head-side fin flares are also slightly larger/showier than a's, but that doesn't offset the spine-crest failure, the more heavily weighted signature element per the brief.
