# CREATURES-RALPH r25: board item F41#13, electric creature finish (CPU, three blind judges)

**Arm:** `creatures_ralph_electric_charge` (committed **OFF**). The remakes' glow maps are lit at energy 2.6 over a matte body (roughness 0.8, specular 0.25). The CPU baseline and candidate are from the same run.

**Anchors:** gap C3, craft before/after, npc C8. The fit has slope 1.41, r 0.80, RMSE 0.52, no warnings.

| Creature | Live (mapped) | Flag ON (mapped) | Change |
|---|---|---|---|
| Stormraven | 5.26 | **6.72** | +1.46 (at or above 6.0) |
| Fulgocobra | 5.83 | 5.92 | +0.09 (flat) |

**What the judges said:**
- **Stormraven:** "mostly uniform cobalt" goes PRESENT → PARTIAL, with visible cyan speckled charge. The raised wing reads as a flat black card in hit and faint (mesh or skin).
- **Fulgocobra:** no visible charged seam on either side. It needs real emissive veins along its gold bands.

**Next (for the new lane session):**
- Split the arm into a Stormraven-only flag, turned ON with 6.72 in `_why` and a `JUDGED_ON` entry.
- Build a separate Fulgocobra vein mask (the `arc_emission.json` hue band on its gold bands).
- F41#13 then counts Stormraven at 6.72 CPU, with Fulgocobra still under.
