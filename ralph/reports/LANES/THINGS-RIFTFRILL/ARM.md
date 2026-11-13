# THINGS-RIFTFRILL: matte finish (F36#62 close-out)

**Row.** F36#62 Riftfrill: High 7.31 with the clear ruler (`G-things-ruler-rescore.md`); needs +0.19. Judges' hold: "glossy plastic purple".

**Change** (flag `creature_coat_flags.json things_riftfrill_matte_1112`, OFF): a matte finish on the Riftfrill aspect coat only (roughness 0.88 in place of the map, specular 0.22, metallic 0). Paddlenewt keeps its wet skin. Config only, no new texture.

**CPU** (`_sheet_matte_off_vs_on_cpu.jpg`; left main, right arm, hit 000): the flag applies (the highlights along the back and flank are gone), but the change is small on CPU, where the Compatibility renderer shows little of the gloss the GPU judges saw. This one needs the GPU to tell.

**Expected.** Unknown size; a close-out try under the 7.0 exception. If it does not move the row, park it: the next idea would be a regraded purple, not the finish.

**Ask.** Riftfrill, `capture_f36_poses.gd --whole-body --context --roles=hit,faint`, base vs arm, High; Medium if 7.5 or above.
