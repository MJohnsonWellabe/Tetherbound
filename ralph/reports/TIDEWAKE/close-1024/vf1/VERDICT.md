# Tidewake close-1024 round vf1: the Veilfall rock material (24 Oct 2026, CT)

- **Item:** F39#5's placeholder-material defect, which is also the black slab in the mx1 fight frames. Views: `F39-look.json` veilfall-near (clear) and veilfall-rain, two frames per side. CPU llvmpipe, Low, 1920x1080.
- **Control:** the shipping look. **Candidate:** the OFF `veilfall_rock_candidate` section, a material change only: pale limestone base (#a49d8c, was #45443f), mid-grey wet runnels (#6b675d, was near-black #1a1c1b), stronger strata ledges. No mesh is touched.
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges. `anchor_tiles.py --seed 515 --pairs 4 --include craft --include f36_0_npc:C1`. `calibrate.py` fitted a line (slope 1.160, r 0.954), anchor RMSE 0.41, top anchor 7.53, `confirming_batch: true`.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (shipping) | 2.9 / 3.8 / 3.1 | 3.35 |
| **Limestone candidate** | 3.6 / 4.5 / 3.9 | **4.20** |

+0.85, and every judge prefers the candidate. **Far below 6.7, so it stays OFF.** The rule is "OFF until judged passing", and passing means the bar, not beating the control.

| Defect | Control | Candidate |
|---|---|---|
| Placeholder or untextured materials | PRESENT x3 | PARTIAL x3 |
| Near-black faceted slabs, no strata | PRESENT x3 | PARTIAL x3 |
| Camera in or against geometry | PRESENT x3 | PRESENT x3 |

## What holds it at 4

The material reached every face the terrain shader owns, and the judges saw it ("a mossy grey-green stone texture"). Three things it cannot touch:

1. **The geometry is faceted.** The judges call it "huge low-poly slabs with hard facets", and the texture "stretched and smeared along the long faces".
2. **The crown boulders are separate kitbash meshes** (`water_veilfall_crag_kitbash.json`), still near-black.
3. **The camera stand sits at the cliff foot,** so most of each frame is cliff face and the falls are "a small white smear" under the HUD.

Points 1 and 2 are new art: Meshy requests 7-8, the stratified cascade tier and the plunge rocks, which all six judges across mx1 and vf1 name as the top change. Point 3 is the camera set's own framing.

## For the coordinator: F39#4 should be re-checked

F39#4, "the hero landmark (Veilfall) reads at distance and up close", is marked **met** on the board from PR #577 (7 Oct), judged before the yardstick was fixed. On today's yardstick the shipping Veilfall close-up maps to **3.35** with a strong fit. The distance read is a separate question and was not re-judged here. The close-up half does not hold up.
