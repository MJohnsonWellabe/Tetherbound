# Tidewake close-1024 round fc1: crown family down the Veilfall face, probe (26 Oct 2026, CT): PARKED, not judged

## What was tried (coordinator GO; OFF in play)

- **Face terraces:** `water_world.json` `terrain.veilfall_summit_cap.terrace_m` 22, riser 0.3, strength 0.85.
  - Stratified tiers on the capped cone, masked like `veilfall_relief`, and zero on every walk band.
  - The test now samples the hike's whole walked width: unchanged. Anchors and the gate are unchanged.
  - About 67% of the flank changed, by up to 13 m.
- **Falls:** `falls_columns_by_id` on the crown entry restarts the falls at the plateau edge while the crown is ON.

## Probe (`_sheet_fc1.jpg`; top: nv1 crown, bottom: crown + terraces, 750 m vista)

- **The ledges came out as zigzag sand stripes.** Every flat ledge takes the bake's sand texture, so the face reads as banding, not cliff tiers.
- **The falls still do not read.** The crown's ~520 m-wide base covers the plateau edge where they begin.
- **Not judged:** visibly worse than nv1.

## Decision

- **Terraces:** `terrace_m` is back to 0 (off) and the capped bake is rebuilt without them.
  - The code and the extended walk-band test stay, and the test still passes.
- **The crown stays OFF (nv1 lost).**
- **Three attempts at the Veilfall face have not beaten shipping on the new stand:** mt1 (cropped), nv1 and fc1.
- **What it would take:**
  1. A terrain material pass, so ledges get rock and grass instead of sand.
  2. A crown re-seat narrower than the plateau, so the falls show.
  3. Or a full-mountain Meshy asset in place of the crown.
- **Reported to the coordinator.**
