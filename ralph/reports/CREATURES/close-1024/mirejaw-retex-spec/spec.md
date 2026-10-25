# Mirejaw: retexture spec for the existing mesh (coordinator rule 2, 25 Oct)

Texture only, the same route as the Mosshock retexture (+1.76 on GPU). The mesh, silhouette, rig, clips, f36 recipe and 2.8 m height stay; no remake.

**Mesh:** `assets/creatures/tetherbound/mirejaw/candidate/models/creature_mirejaw_native.glb` (embedded Image_0, 2048x2048; retexture with the original UVs). Start from main's albedo, not the lane's `lift_dark_back` touch.

**Why:**
- GPU batch 2 (tb/gpu-pass 6c12bf6f6) scored it 6.92. Its one dominant defect: the faint end "goes near-black: the tail curl turns its dark back to the camera" ("a dark smear", 2 of 3).
- Two albedo nudges each gained under 0.5, so rule 1 applies:
  - belly-to-camera roll: CPU b34, 6.77 -> 5.60;
  - lift of the dark scale fill: CPU b35, 6.95 -> 6.90.
- The back is a near-black hex net painted into the atlas, and recolouring keeps its value.

**Target:** a naturalistic marsh crocodilian-newt at the style bar's finish (`_sheet_refs.png`: the owner style bar, then the current Mirejaw stand, hit and faint). The read to fix is value: the back must sit clearly above black so the dorsal side reads as form, not a hole.

**Palette:**

| role | hex | where |
|---|---|---|
| back scales | #4A4636 | dorsal hex scales: a dark olive-umber, about value 0.28, never below 0.18 |
| scale seams | #8A7A4E | the hex net between scales, muted ochre, thinner than now |
| flank grade | #6E6648 | flanks lighten toward the belly line |
| belly, throat and inner legs | #D8CDA8 | keep the source's cream placement |
| frills and crest | #D69A3A to #E7B85A | amber-gold, as now (the red check is already fixed; keep it) |
| eyes | iris #E8A23A, pupil #120E08 | readable |

**Must stay:**
- the hex scale pattern, as surface relief and colour, softened;
- the cream belly;
- the amber frills;
- no red, oxblood or pink (hard rule);
- matte, not glossy.

**Must not:**
- a back darker than value 0.18 anywhere larger than a seam;
- high-contrast black-and-gold checkerboard;
- glow or emissive (no glow on hide, owner 25 Oct).

**Check:**
- CPU yardstick against main's head on the same stage tiles (stand, hit, faint end), then GPU.
- Re-pin the f36 `source_sha256`.
- Rebuild the vivid PNG (`--only vivid mirejaw`).
- Re-run the red check (`shift_reserved_red.py` band).
