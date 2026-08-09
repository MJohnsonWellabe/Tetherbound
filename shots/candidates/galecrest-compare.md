# galecrest — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/galecrest/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 | c /10 |
|---|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 7 | 4 | 5 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 7 | 5 | 5 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 6 | 4 | 5 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 20 | 13 | 15 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | No | **YES — wings read as bolted-on cape** | **YES — wings read as bolted-on cape** |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [x] species feature reads as bolted-on rather than grown — **b and c**: the back view shows a clear dark gap/hole between the wing bases and the neck/shoulder — the wing geometry does not close against the torso, draping like a cape instead of fusing into the shoulders (confirmed on a zoomed crop: hard edges match background grey, not shadow falloff)
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [ ] eyes uncanny
- [ ] anatomy deforms badly
- [ ] stops matching the reference at gameplay distance

## Chosen

**a.** The decisive factor is a geometry defect shared by b and c: in the back-view turnaround, both show a dark gap/hole where the wings meet the neck/spine — the wing "shells" drape down like a cape rather than fusing into the shoulders, leaving a visible void down the back. This directly fails the "grown into the body, not bolted-on" requirement for the wings, the single most important signature feature per the brief. a's back view is a clean continuous surface with no such gap; its tail feathers fan out in clean, even layers, much closer to the reference's back view.

b and c also both give the head a full ring of spiked feathers (a crown/mane effect visible in front and back views) that reads more like a generic fantasy-bird/gamecock than the reference's smooth, swept-back raptor crest — pushing proportion/silhouette away from canon on both.

a's own weak point, noted for follow-up: talons are stubby and blunt (small rounded nubs) rather than the "HEAVY GRIPPING TALONS" called for — b's talons, by contrast, were the sharpest/most convincingly curved and gripping-looking of the three. If a's talon sculpt can be beefed up without touching the rest of the mesh, that closes the remaining gap to the brief. All three candidates keep a clear hawk/raptor silhouette rather than drifting toward the small cute fox-eared glider (Galewisp) — none hit that specific hard fail.
