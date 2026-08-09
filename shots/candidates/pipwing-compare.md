# pipwing — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/pipwing/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 | c /10 |
|---|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 8 | 8 | 6 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 6 | 9 | 6 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 5 | 9 | 7 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 19 | 26 | 19 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | No | No | No |

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

**b.** a's eyes read as small, almond/heavy-lidded shapes rather than oversized round bulging orbs — half-closed/sleepy in the front and three-quarter views, undercutting the single most important canon feature ("OVERSIZED ROUND EYES taking up much of the face"). Its crest is also thinner/sparser than the reference's fuller tuft. c's eyes are reasonably round but noticeably smaller/more recessed than b's, weakening the "takes up much of the face" quality; its bigger issue is a long swept-back tail plume that extends well past the body in side/three-quarter views, breaking the tiny-round-songbird silhouette and pulling toward a leaner, elongated bird shape — the reference's tail is short and tucked, not a trailing plume.

b is the strongest match on the signature feature: eyes large, clearly spherical, and bulge forward to dominate the face much as the reference does; the crest is full, sits naturally on the crown, and reads as grown-in rather than stuck-on. Body stays compact and egg-round through all four views, with only minor feather-layer texture at the rear breaking the silhouette slightly (very minor, not disqualifying).

Shared note across all three, not disqualifying: every crest is built from thin, blade-like feather spikes rather than the reference's slightly softer, chunkier tuft — a stylization gap worth a follow-up pass regardless of which candidate ships. No hard-fail anatomy problems (no extra/missing limbs, no broken topology) observed on any candidate.
