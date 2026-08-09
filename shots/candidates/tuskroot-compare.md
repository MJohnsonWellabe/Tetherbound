# tuskroot — candidate scorecard

Scored against `docs/art/reference/` and the crops in `assets/pals/tetherbound/tuskroot/reference/`.

**A HARD FAIL is a rejection regardless of the total.** `TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total score.* A candidate that scores 68/80 with a face that lost the starter personality loses to one that scores 61 and did not.

**R0.4 blind pass scored silhouette, proportion and the signature feature only — candidates are untextured white geometry, so face appeal, material/colour, topology, rigging and gameplay-distance readability are marked N/A below and remain for a later pass.**

| Criterion | What it asks | a /10 | b /10 | c /10 |
|---|---|---|---|---|
| Silhouette similarity | Does the outline read as this creature at 40px? | 7 | 5 | 6 |
| Face appeal | Starter personality preserved, or generic animal? | N/A | N/A | N/A |
| Body proportion similarity | Head/body ratio, leg thickness, shoulder height | 7 | 6 | 6 |
| Species feature similarity | The distinctive thing: mantle, fins, ear tufts | 7 | 3 | 5 |
| Material/colour similarity | Against the sheet's own swatch strip | N/A | N/A | N/A |
| Topology usability | From inspect_glb.py, not from looking | N/A | N/A | N/A |
| Rigging suitability | Deformation zones, symmetry, limb separation | N/A | N/A | N/A |
| Gameplay readability | Holds up at combat distance on a handheld | N/A | N/A | N/A |
| **TOTAL (3 judged criteria)** | /30 | 21 | 14 | 17 |
| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | No | **YES — tusks reduced to stubs** | **YES — stray geometry fragment on cheek** |

## §10 rejection list, checked explicitly

- [ ] silhouette substantially different from the sheet
- [ ] face lost the friendly starter personality
- [ ] reads as an ordinary real-world animal
- [x] species feature reads as bolted-on rather than grown — **b**: tusks are short stubby nubs that barely curve, not long tusks sweeping up from the jaw as canon requires
- [ ] proportions drifted photoreal
- [ ] materials look plastic
- [ ] fur/feather treatment conflicts with the rest of Tetherbound
- [ ] eyes uncanny
- [x] anatomy deforms badly — **c**: a flat rectangular panel/fragment is embedded mid-cheek on the face, unconnected to the tusk or plate systems, reading as broken topology or a stray bolted-on scrap rather than organic anatomy
- [ ] stops matching the reference at gameplay distance

## Chosen

**a.** b is weakest on the signature feature: its tusks are reduced to small stubby curls that don't project or sweep as canon demands, and its back "plates" are small uniform warts/studs spread evenly over the whole body — a generic bumpy skin texture, not distinct layered stone armor. It also loses silhouette readability at small size as the low-relief bumps wash out against the body outline.

c has locally flatter, more plate-like bump shapes in a few spots on the back (closer to "shingled stone" than a's boulder-cluster look) — a genuine point in its favor — but it is disqualified by a clear geometry artifact: a flat rectangular panel sitting mid-cheek on the face, belonging to no system (not an ear, eye, tusk, or back plate), reading as broken/leftover topology. Its tusks are also shorter/thinner than a's, sitting closer to the snout instead of sweeping up past it.

a's tusks are unambiguously the strongest of the three: long, thick, and sweeping up from the jaw in a dramatic curve closely tracking the reference's proportion and silhouette contribution. Its back bumps, while rounder than true stone slabs, are large and clearly separated, forming a coherent armored hump grown into the shoulder/back rather than pasted on, with no visible mesh damage or stray geometry anywhere on the model.

**Shared defect across all three, carried forward regardless of the pick:** none delivers the reference's signature THICK GREY STONE PLATES as distinct angular, flat-edged slabs stacked like cobblestones — all three render the plating as rounded pebble/boulder-like or wart-like bumps. **Flag for a follow-up sculpt pass at R0.6**: the plates need harder edges/flatter tops to read as stone rather than tumors or acne, independent of which candidate ships.
