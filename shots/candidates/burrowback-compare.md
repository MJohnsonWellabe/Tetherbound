# burrowback — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/burrowback/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 | c /10 |
|---|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 5 | 5 | 7 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 5 | 5 | 7 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 3 | 4 | 5 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 13 | 14 | 19 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | **YES — no claws, continuous shell** | **YES — no claws, continuous shell** | No |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [x] species feature reads as bolted-on rather than grown — **a and b**: nodules tile continuously across the entire back, shoulders, flanks and legs, reading as one molded shell rather than "loose... clusters... never one continuous shell"
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [ ] eyes uncanny
- [ ] anatomy deforms badly
- [ ] stops matching the reference at gameplay distance

## Chosen

**c.** a and b both read as a stocky bear cub — torso too tall/rounded, legs too long, belly not low enough to the ground. c is noticeably lower and more elongated in the side view, closest of the three to the reference's low, ground-hugging, broad stance.

a and b's rock nodules cover the entire back, shoulders **and** flanks/legs in uniform bumps, reading as a full molded shell bolted onto a bear body — a direct contradiction of the canon's "loose... clusters... never one continuous shell," and a hard fail on both. c's nodules taper off toward the shoulders and sides, leaving visible smooth-fur gaps at the flanks and legs — a much closer geometric match to "clusters... in gaps."

**Shared defect across all three, carried forward regardless of the pick:** none of the candidates shows the signature ENORMOUS SHOVEL CLAWS with conviction. All three give generic small rounded paw-mitts with only faint digit separation; c is marginally better (slightly more individuated, elongated toe forms in the side/three-quarter views) but still falls well short of "enormous." **Flag for a follow-up claw pass at R0.6**, independent of which candidate ships — this is a cross-candidate gap, not a c-specific weakness.

c wins on the two criteria that most determine whether this reads as burrowback at a glance (silhouette, proportion) and is at least even-or-better on nodule clustering.
