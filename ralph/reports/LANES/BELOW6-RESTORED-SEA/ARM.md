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

CPU (the r3 sheet (replaced by the r4 sheet), restored frames at all four stands, base above, r3 below): S3 is unchanged in value, S4 keeps its teal ripples with a slightly darker near foreground (mean luminance 22 -> 17; r1 was near black), and S1/S2 still differ from live by about 8 (base about 2). The change at S1/S2 is smaller than r1's, so the row's gain may be smaller too.

## r4 (12 Nov, after the r3 pre-check hold)

The GPU lane held r3 before judging: S4's restored foreground was still darker than base (mean luminance 25 -> 20, near-black share 70 -> 80 percent). Everything r1-r3 changed lowers light on low-sun water: a narrower shallow band, calmer waves, clearer shallows.

r4 goes the other way. While the fact is set, the shallow colour reaches 1.3 times further than the live profile (`water_scale.depth_falloff 1.3`: restored shallows), the waves ease to 0.8 of live, and the debris is cleared. Colours and alpha are untouched.

CPU (the r4 sheet (replaced by the r5 sheet); restored frames at S1-S4, base above, r4 below): the turquoise shallows spread well out from the islands at S1 and S2, S3 is unchanged in value, and the S4 sunset foreground is lighter and more teal than base, not darker. Foreground mean luminance, base -> arm: S1 62 -> 88, S2 79 -> 110, S3 35 -> 36, S4 22 -> 35. Live against restored: S1 15.2, S2 16.3 (base about 2). Live frames are untouched.

## r5 (12 Nov, after G-below6-sea-r4-stronghold)

r4 fixed the sunset (S3/S4 5.84 -> 6.37, 3/3) but the row went level (6.26 -> 6.23): with lighter shallows "the restoration event does not read on either side" at S1/S2. r1 had read there (+0.67) with deeper water, and failed only at low sun.

r5 gives each time of day its own values (`by_time`, keyed by the world look's time-of-day preset; code in `water_restored_sea.gd`):
- **day:** the shallow colour draws in to a quarter of the live reach (`depth_falloff 0.25` of live), waves 0.55 of live, `alpha_shallow 0.28`: r1's deeper, calmer restored channel, with the live colours kept.
- **every other preset** (golden, dusk, night): r4's values (falloff 1.3 of live, waves 0.8).
- **both:** stronger surf on the sandbars (`surf_strength 1.0`, surf reach 1.8 and foam depth 1.5 of live), the shoreline foam the judges asked for; debris cleared.

CPU (`_sheet_cpu_r5_restored_S1-S4_base_top_arm_bottom.jpg`; restored frames at S1-S4, base above, r5 below): S1 and S2 show deep calm channels with pale rings around each island; S3 (day, the waterfall view) keeps base's value; the S4 sunset keeps its teal and is lighter than base. Foreground mean luminance, base -> arm: S1 62 -> 46, S2 79 -> 55, S3 35 -> 35, S4 22 -> 35. Live against restored: S1 14.3, S2 16.8. 0 script errors. The preset is read once a second, so the look follows the clock in play.
