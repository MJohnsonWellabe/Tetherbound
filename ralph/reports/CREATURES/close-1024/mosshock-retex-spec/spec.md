# Mosshock: retexture spec for the existing mesh (only if GPU batch 2 leaves it below 6)

Texture only. The mesh, silhouette, rig, clips and 3.6 m height stay; no remake.

**Why:** the camo blotches are painted into the current atlas. Recolouring (b30, b32 and 4e5217f1b) can only recolour them, and the judges keep reading busy camouflage.

**Target:** a naturalistic mossy newt at the style bar's finish. `_sheet_refs.png` shows, left to right: Stormursa in game (natural coat with thin element lines); Tanglevolt in game (value split: darker back, paler throat and legs); the current Mosshock, which is what must change.

**Palette:**

| role | hex | where |
|---|---|---|
| moss coat | #4E5A2C | back, flanks, tail: one even mossy hide with soft low-contrast mottling, no hard blotches |
| moss shadow | #2F371B | folds, underside of the dorsal growth, between scales |
| lichen highlight | #8F8E55 | sparse, small, on the tips of the dorsal growth only |
| cream belly and throat | #D6CBA4 | belly, throat, inner legs (keep the source's cream belly placement) |
| eyes | iris #F0A63A, pupil #16120A | keep large and readable; the face is the read |
| electric accent | #EDE7A6 | a few thin pale current lines along the spine and dorsal growth. Natural lightning for an electric creature, thin and sparse, no glow seams on the hide |

**Must stay:**
- the eyes, with their size and placement;
- the cream belly;
- the dorsal growth silhouette;
- no red, oxblood or pink (hard rule);
- out of the grass hue band (80-175 deg): the moss sits at about 70 deg;
- matte skin (roughness high), not glossy.

**Must not:**
- neon or emissive green;
- high-contrast camo blotches;
- speckle noise at small size;
- glowing seams over the hide (owner glow rule, 25 Oct).

**Check:** CPU yardstick before GPU, against the batch-2 head (4e5217f1b), on the same stage tiles (stand, hit, faint).
