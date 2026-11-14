# LAND-MT-SEADEPTH round 2: depth gradient only (`overlay_r2.json`)

**GPU eye check of round 1 (GPU lane, G-land-mt-seadepth-states).**
- The routes are clean: the terraces channel goes from navy to mid-blue.
- But the current-state frames (S1 live and restored, S2 live) gain long diagonal light and dark streak bands across the open water, plus more white flecks (mean difference 11 to 14).

**Cause (from the candidate's own settings).** `cause_tidewake.sea` also turns on wind slicks (`slick_strength` 0.16 at `slick_scale` 0.006, long smooth streaks) and whitecaps (`cap_strength` 0.22). Those are the bands and the flecks, and neither is part of the depth-gradient ask.

**Round 2 change.** Overlay `overlay_r2.json`: the same sea part ON, with `slick_strength` 0 and `cap_strength` 0. The depth stops (shallow, mid, deep), falloff, contour wander, range haze and surf line stay.

**By-eye.**
- Routes: the channel is still mid-blue with a soft edge.
- Current-state S1 and S2: no new diagonal bands or flecks against base.

**Not looked at on CPU.** The bands showed on GPU.

---

Round 1 notes follow.

# LAND-MT-SEADEPTH: Tidewake sea with a soft depth gradient

**Rows.** Every Tidewake frame with open water. Scored rows: F39#15 6.14, F13#5 6.28, F39#16 6.55, F39#17 6.55, F39#1 6.14, F39#30 6.70, F39#2 6.79; F39#10 (7.02) as no-loss.

**Defect.** LANE-JUDGE re-scores on main (13 Nov): "replace the hard navy shallow-to-deep edge with a soft depth gradient. It is in every current frame." G-rescore-stale-ext-tidewake (3/3): "a hard navy-to-cyan depth edge where a gradient should be; shallows as rimmed discs".

**Cause, and how I know.** The shipping water has two stops, pale cyan shallows and navy deep, with a short falloff, so every shelf edge is a hard line. A depth-graded candidate already sits in `tidewake_look.json` (`cause_tidewake.sea`, tb/cause-tidewake, 1 Nov): a teal mid stop at 4 m, a 16 m falloff with a wandering contour, a lighter deep blue that keeps some sky reflection, range haze, and a broken surf line. I found no GPU verdict for it in VERDICT-LINES. Check: switching only that part on removes the navy band in all three CPU frames (sheet).

**Change.** Overlay only: `cause_tidewake.sea.enabled` true. No new code. The capture switch `--tidewake-cause=sea` does the same thing.

**CPU before / after.** `_sheet_seadepth_off_vs_on_cpu.jpg`: left base, right arm; horizon_stones route_day, terraces route_day, terraces walk_01. 0 script errors.

**By-eye line for the GPU lane.** terraces route_day: the navy channel between the beach and the far island is mid-blue, and the cyan shallows fade into it without a hard line. If the channel is still navy with a crisp edge, the overlay did not apply: hold.

**Risks and no-loss frames.**
- The shoal rings are softer but still concentric. Making them irregular is the next step and is not in this arm.
- The whole sea gets lighter and less saturated at range. F39#10 (water and island depth, 7.02) and the current-state frames (F39#16, F39#17: the restoration read depends on water colour) are the no-loss checks. The part's own note says an earlier royal-navy palette lost, so the colours stay in the shipping family.
- Night, dawn and golden were not looked at on CPU.

## Round 3 (`overlay_r3.json`), the judges' last tone round for F39#10

The verdict on r2 said the base has the depth but a hard edge, while the arm has a soft edge but reads lighter cyan. The ask: keep base's deep navy and soften only the transition band.

The lighter read had three sources:
- the candidate's brighter shallow colour (#74c2b6), carried out by a 16 m falloff;
- its range haze (#a3c3ce at 0.3), which washes the distance toward cyan;
- a light mid stop.

Round 3 changes:
- shallow colour back to base #79b4ac;
- haze off;
- a darker mid band (#2a7686) at 3.5 m;
- falloff 10 m (base 5, r2 16);
- navy offshore #0f3f5a, full by 14 m;
- slicks and caps stay off.

**CPU** (`_sheet_r3_cpu.jpg`, left main, right r3; rows: terraces route, walk_01, walk_02, then First Shore route, walk_01, walk_02):
- The offshore water stays deep navy (slightly deeper).
- The shelf edge is softer on the terraces route and walk_01.
- First Shore's chevron bands soften only slightly.
- The concentric islet halos remain; they need the rebake.

**By-eye line:** terraces route_day. Navy as deep as main, with a wider teal step at the shelf instead of a hard line.

If this panel is a wash too: PARKED for F39#10, as agreed.
