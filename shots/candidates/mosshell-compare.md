# mosshell — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/mosshell/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 |
|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 6 | 8 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 6 | 8 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 5 | 8 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 17 | 24 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | No | No |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [ ] species feature reads as bolted-on rather than grown
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [ ] eyes uncanny
- [ ] anatomy deforms badly
- [ ] stops matching the reference at gameplay distance

## Chosen

**b**, cleanly. a's shell reads more as an elongated ridge/keel down the spine than a "broad domed" mass — it doesn't bulge out past the leg stance the way the reference overhangs the body on both sides, so at small size it reads as "turtle with a bump on its back" rather than "shell-forward tank." a's plate segmentation is present but shallow/subtle, closer to a generic smooth-ish shell than the reference's chunky, distinct stone plates, and its back view shows more leg/hip visibility (a gap between shell rim and ground near the hindquarters), reading less "low centre of gravity, stumpy limbs tucked under a dominant shell."

b's shell is broad and clearly dominant in every view, overhanging the body similarly to the reference, with a distinct scalloped rim edge at the shell base standing in geometrically for the "pale cream rim" the brief describes — a grown-in touch a lacks. b's plate segmentation reads as individual raised stone plates rather than a smooth dome with etched lines, and its proportions (chunkier, lower-slung) are closer to the reference's "steady tank" stance.

Minor note on the winner, not a hard fail: b's back three-quarter view shows a slightly odd thin protrusion near the hind end that could read as an errant tail/spike rather than a tucked-in leg — worth a topology check before R0.6.
