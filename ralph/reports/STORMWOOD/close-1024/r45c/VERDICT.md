# r45c: storm sky with soft rims (CPU, code-blind, 27 Oct): NO GAIN (-0.11). The sky-form approach is PARKED.

**Arms:** the same four open stands as r45b (Crown Overlook, Struck Sentinel, Glass Field, Rodline Post), calm and break.
- **OFF:** a fresh capture on the current lane. The Crown Overlook vista has landed on main since r45b, so r45b's OFF frames no longer match.
- **ON:** `ceiling.form` with the SW19 fix (`lit` 0.8 -> 0.25, `edge` 0.04 -> 0.08; dark bases, deck and the `skyline` treeline unchanged).

**Result:** mapped **6.03 -> 5.92 (-0.11)**. Judges scored 5.8/5.7, 5.7/5.6, 6.3/6.3; all three call the sides "nearly identical". Linear fit r 0.88, no warnings.
- **Were the frames really different?** Yes: mean per-pixel difference between the arms is 24-54 per stand.
- **Smear slabs:** PARTIAL on both arms (the break-phase sheet glow brightens the deck on both).
- **Flat sky:** PARTIAL on both.
- **Empty horizon:** PRESENT/PARTIAL on both.

**Why:** r45b's gain came from the bright, hard-edged rims, the same feature the GPU judges then read as white smear slabs (SW19). With the rims softened, the masses are dark shapes at nearly the deck's value and the judges no longer see a different sky. Bold rims add the smear; soft rims add nothing.

**Decision:** the second miss after SW19, so procedural cloud form on the ceiling dome is **PARKED** under the two-strikes rule. No SW19 retry arm is posted. `form` and `skyline` stay OFF.
- **New idea threshold**, per the judges (15/15 on GPU, 3/3 here): carry the storm into the scene, not the dome.
  - a per-phase ground and foliage grade;
  - a cool lightning rim light on trunks and figures;
  - lightning that lights the ground.
