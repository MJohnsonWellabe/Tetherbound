# duskhush — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/duskhush/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 | c /10 |
|---|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 8 | 7 | 7 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 8 | 6 | 7 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 8 | 3 | 5 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 24 | 16 | 19 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | No | **YES — eyes sculpted shut** | No |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [x] species feature reads as bolted-on rather than grown — **b only**: eyes are modeled fully closed in all four views, so the canon's "LARGE FORWARD-FACING EYES" cannot be judged present at all; a closed-eye owl reads as sleeping, contradicting "silent watcher"/"watchful"
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [x] eyes uncanny — **b only**, see above
- [ ] anatomy deforms badly
- [ ] stops matching the reference at gameplay distance

## Chosen

**a.** b is disqualified on the single most important checked item: its eyes are modeled shut in front, side and three-quarter views, so the brief's "LARGE FORWARD-FACING EYES ringed in gold ... calm watchful expression" cannot be evaluated as met — geometrically there are no visible eyes, just closed lids. Its wing surface is also uniform pillowy bumps rather than distinct layered feather shapes, and its feet/talons are the least defined of the three.

c's ear tufts are present and well-integrated into the head, but noticeably smaller/subtler than the reference's — they read as small notches in a head-crest rather than "PRONOUNCED" ear tufts. Its tail feathers also fan out oddly in the side view (a spread-tail look, not the reference's tucked, perched silhouette), and its torso reads a touch more slender/tall than the round reference body.

a best executes the signature feature: tall, clearly swept-back ear tufts unambiguously rising from the head, and large, open, forward-facing eyes sitting in a flattened facial-disc plane. Body proportions and the folded, rounded, layered wing shape are the closest match to the reference among the three; talons are clearly modeled and grounded.

Shared minor note, not disqualifying: a and c both give the brow/eye area a somewhat sharp, angled "angry" look via a V-shaped brow ridge, leaning harder than the reference's "calm watchful" read — worth a light pass in a later sculpt iteration.
