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

## r3 (12 Nov, after the SPLIT verdict)

G-below6-restored-sea: the row's own frames gained (S1/S2 6.21 -> 6.88, 3/3) but S3 waterfall and S4 sunset lost (6.61 -> 6.17, 0/3): the sunset foreground went near-black and the day turquoise thinned. Cause: r1 set an absolute `depth_falloff` of 2.2 while the live Tidewake profile runs at 16 or more, so the shallow colour shrank to rings and everything else took the deep colour, which is black at low sun.

r3 keeps the live colours and takes its two changes as a fraction of whatever profile is live (`water_scale`: depth falloff 0.8, wave strength 0.65), plus `alpha_shallow 0.3` and the cleared debris. r2 (falloff 0.5) still darkened the sunset on CPU and was not sent.

CPU (`_sheet_cpu_r3_restored_S1-S4_base_top_arm_bottom.jpg`, restored frames at all four stands, base above, r3 below): S3 is unchanged in value, S4 keeps its teal ripples with a slightly darker near foreground (mean luminance 22 -> 17; r1 was near black), and S1/S2 still differ from live by about 8 (base about 2). The change at S1/S2 is smaller than r1's, so the row's gain may be smaller too.
