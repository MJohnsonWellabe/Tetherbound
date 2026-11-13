# LAND-MT-BASEMIST: the Veilfall base mist that never rendered (HOLD, not sent)

**Rows.** F39#31 Veilfall hero landmark (6.02; new clear-day frame set `veilfall-vista`, `veilfall-near`), F39#2 Veilfall silhouette (6.79), F39#30.

**Defect.** G-floor2-dawn-haze-storm-grade, 3/3 called new_art: "the fall is a single opaque white ribbon draped like cloth, with no mist at the base".

**Cause, and how I know (CPU probes on the two F39#31 views).**
1. `falls.spray_shader` colour magenta at opacity 1.0: nothing magenta on screen.
2. Alpha forced to 1 in `water_veilfall_spray.gdshader`: a solid box at the main fall's base. So the quads draw.
3. A varying for the puff corner instead of reading UV2 in fragment(): no change (wrong guess, reverted, never committed).
4. Alpha = opacity * radial (billow term removed): a soft magenta glow at the base. **So the billow gate `smoothstep(0.2, 0.75, billow + radial * 0.35)` is what zeroes the mist.**
- Headless position check: only 5 puffs exist, all at the two side falls' feet (y 4 to 13 m over the sea). The main cascade's puffs sit at its configured `foot_y_m` of 200 m, mid-cliff, so none are where the visible fall meets the shore.

**Change (flag-off).** In `shaders/water_veilfall_spray.gdshader`: `billow_floor` (default 0) keeps that share of each puff when the billow noise is low, and `size_scale` (default 1) enlarges every puff. The overlay sets 0.6 and 1.6.

**CPU before / after.** `_sheet_basemist_off_vs_on_cpu.jpg`: only a faint whitening at the base in `veilfall-vista`, nothing in `veilfall-near`. **Too small to spend judges on.**

**What would make it read (next step, not built).** Puffs where the visible falls end, seen from the F39#31 stands: a spray list for the cascade at its visible plunge, not at 200 m; and a slightly off-white, sky-lit mist tone so it separates from the white ribbon and the pale sand. This is config (`falls.columns[].spray`) plus this flag.

**Correctness note.** The billow gate hiding all mist is a real bug, but the fix is a visible change, so it stays flag-off until a placement round makes it worth judging.
