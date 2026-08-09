# brooktail — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/brooktail/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 |
|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 6 | 6 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 8 | 7 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 3 | 2 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 17 | 15 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | **YES — paddle tail** | **YES — paddle tail, bolted-on seam** |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [x] species feature reads as bolted-on rather than grown — **b only**: a visible seam/collar ring where the tail meets the haunch (back and three-quarter views)
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [ ] eyes uncanny
- [ ] anatomy deforms badly
- [ ] stops matching the reference at gameplay distance

## Chosen

**a, with a hard fail carried forward — this is not a clean win.**

Both candidates fail the single signature feature this species is built around: neither has the canon's BROAD FLAT SCALED TAIL like a paddle. The reference back view shows a wide, flat, spade-shaped tail flush to the ground, clearly as broad as the hips. Both a and b instead give a thick, round, gradually-tapering tail that narrows to a blunt point — a shape problem, visible on white geometry, not a texture/colour one. **This needs a sculpting pass before R0.6** regardless of which candidate ships; it is not something retexturing (R0.5) can fix.

a wins the tie-break over b on secondary grounds: b's tail additionally has a visible seam/ring where it meets the body, reading as a separate part bolted onto the haunch rather than grown out of it (a's tail blends smoothly, no seam) — a second, distinct hard-fail condition that a does not share. b's face also reads with squinted/closed eyes and no whisker geometry, undercutting the "friendly clever face" the brief calls for; a has clearly open, round-socketed eyes and modeled whisker strands. Body/head/limb proportions (chunky torso, big rounded head, short stout legs, bipedal stance) are close to reference and essentially tied between the two — this criterion did not separate them. Neither shows a true webbed membrane between the toes, just broad flat pads with faint toe separation; equal between the two, not decisive. No extra/missing limbs or broken topology on either.
