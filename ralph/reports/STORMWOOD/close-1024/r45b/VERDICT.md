# r45b: Stormwood storm sky, hard cloud masses + distant skyline (CPU, code-blind, 26 Oct): GAIN +0.83, arm m45

**Arms:** four open stands in calm and break: Crown Overlook, Struck Sentinel, Glass Field and Rodline Post. The OFF frames are r45's.
- **OFF:** the current storm ceiling.
- **ON:**
  - `stormwood_surge.json presentation.ceiling.form` (edge 0.04, deck 0.85, dark 0.7, lit 0.8, gap 0.08, curtains 0.7, scale 0.8);
  - `ceiling.skyline` (the r22 distant two-layer treeline, never judged before).

**Result:** mapped **5.75 -> 6.58 (+0.83)**. Linear fit r 0.74, slope 1.12, no warnings. 3/3 judges prefer ON: 5.6/6.3, 5.5/6.2, 5.3/6.1.
- **Flat sky:** PARTIAL -> **FIXED** for 3/3 judges.
- **Empty horizon:** PRESENT -> PARTIAL for 3/3 judges ("a dark treeline band now closes it, though thin in cols 1-2").

**Remaining asks from the judges:**
- **White smear slabs:** two judges flag bright slabs in the Struck Sentinel calm sky that read as a texture artefact. These are the lit rims (lit 0.8). This is the next refinement.
- **Outside the sky:** generic green trees, a uniform moss carpet, the Meadows cottages at Rodline Post, the lime fern at Crown Overlook, and no fog layering or copper/glass/pools.

**Checks on the arm config:** `test_stormwood_surge_presentation.gd` 53/0 and `test_stormwood_surge.gd` 4/0.

**Photosensitivity:** no flash onsets are added. The form is a static shape on the deck, and the existing flash, sheet glow and crawler terms are unchanged.

**Arm:** `tb/stormwood-m45-on` 94adcb41. It is lane HEAD with `form.enabled` and `skyline.enabled` true; the lane keeps both OFF.
