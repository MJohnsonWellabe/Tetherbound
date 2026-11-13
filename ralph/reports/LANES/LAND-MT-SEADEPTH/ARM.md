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
