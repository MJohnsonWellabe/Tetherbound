# BELOW6-RESTORED-SEA: restoring the currents changes the sea (F39#17, 5.50)

**Flag:** `data/config/water_current_flow_visual.json restored_sea_1112` (OFF; overlay turns it on).
**Code:** `scripts/world/water_restored_sea.gd` (new), attached in `water_veilfall.gd` beside the flow view and drift markers. Test: `tests/test_water_restored_sea.gd`.

**The gap:** WORLD §6.5 says that when the Guardian is freed "the currents return". On main the only thing that follows `water_currents_restored` is the foam: streak density, speed and opacity drop. LANE-PLACES measured live against restored at one camera as a mean difference of 1.23; the judges call the frames "the same picture" (3/3).

**What the arm does while the fact is set:**
- The sea material takes six restored values: lighter, clearer shallows (`shallow_colour`, `alpha_shallow`, `depth_falloff`), a slightly lighter deep colour, half the wave strength and a stronger fresnel. The live values come back if the fact is cleared.
- The drifting logs and weed mats in the lanes are hidden (debris cleared). The anchored buoys stay.

It reads the same replicated world fact as the foam view, once a second, so load, reload and every peer show the same state. No flow vector, strength, physics, route, save or authority change, and no new mechanic.

**CPU look** (`_sheet_cpu_S1_live_left_restored_right_base_top_arm_bottom.jpg`): on base the two states differ only by a few flecks. With the arm the live frame is unchanged and the restored frame shows smooth, calmer water, pale shoals ringing the three islands and no debris. Mean difference live against restored: S1 2.4 -> 10.0, S2 2.0 -> 11.6. 0 script errors. No CPU judge batch.

**Risks:** the restored sea has less of the bright rippled turquoise mid-water than live, so a judge may read it as flatter. CPU cannot show the GPU's water transparency, so the shoals may read stronger or weaker there.
