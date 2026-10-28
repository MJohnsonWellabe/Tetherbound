# Terrapup dog3: retexture spec for the existing mesh (owner: "Terrapup should be a dog")

Texture only, on the rigged dog3 mesh. The mesh, rig, clips, 3.20 m height and the dog identity stay; no remake.

**Mesh:** `tb/creatures:assets/creatures/tetherbound/terrapup/candidate_dog3/models/creature_terrapup_dog3.glb`. Retexture Image_0, the base colour, with the original UVs. Start from the untouched dog3 albedo; the lane's `creature_touches` overlays (chestnut, plates, moss) are folded into this spec and will be dropped.

**Why** (GPU verdict M, tb/gpu-pass `F36-1/M-terrapup-dog3-17ce37f88`; path-to-7.5 item 1):
- The stone plates read as stuck on the dog.
- Texture overlays (b30/b33, f0ada94b5) cannot add fur crossing the plate rims or contact shadow under the plates.

**Target:** a large, earth-element working dog at the style-bar finish (Stormursa, Galecrest). Stone plates *grow out of* the coat along the spine and shoulders.

**Palette:**

| role | hex | where |
|---|---|---|
| coat | #7A4E2E, shading to #5A3920 | chestnut-brown dog coat (never orange-red: red is reserved) |
| muzzle, chest, paws | #CDB894 | pale cream markings, as now |
| plates | #6E6A5E, crevices #3E3B34 | weathered earth-grey stone, matte, with lichen flecks #7E8456 |
| plate rims | fur #6A4428 over the stone edge | fur grows over each plate's rim for 2-4 cm, with a dark contact shadow #2A2018 under every plate |
| moss | #556232 to #6C7A3C | moss creeps from the plates into the fur on the upper back and shoulders, broken clumps, not a band |
| seat pad | #8A6A48 leather, stitch line #C9B38C | a worn leather pad on the back between the shoulder plates, at the seat (rider at mount_offset y 2.36), shaped as a dip where the plates part |
| eyes | iris #B8862E, pupil #120C08 | readable, with a catch-light |

**Must:**
- keep it a dog (snout, ears and legs as now);
- no red, oxblood or pink;
- no glow (owner: glow only where natural; earth has none);
- matte stone, satin fur.

**After the texture lands, folded into the same candidate** (coordinator order 2):
- the seat: mount_offset lowered into the pad dip;
- the cower at strip size;
- coat rim (field_rim 0.3);
- f0ada94b5's tweaks.

**Check:** CPU yardstick, then GPU. Expected to clear 7.5 (gap 0.17 on M; item 1 alone was judged to close it).
