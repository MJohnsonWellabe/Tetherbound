# CARD:T2 device profile (7-inch): current direction + small HUD text, Systems lane, PARKED at best 5.5/10

Tue 13 Oct 2026 (CT), tb/ev-systems. Capture: `tools/capture_tidewake_f13_5.gd --only=currents`, 1920x1080,
software GL. Sheets: each cell is a 7-inch panel width (590 px), `rN_sheet_7inch.jpg`. A fresh code-blind judge
each round, scored /10 (WORKFLOW §8.1 rule 10: ≥8.5 done, each round must gain ≥0.5).

| Round | Head | Currents | HUD | Overall | Change |
|---|---|---|---|---|---|
| r1 | 69ac6067 | 3 | 5 | 4.5 | baseline: comets read as debris; hotbar 1–5 and M/I/B about 1 mm |
| r2 | 1867bb9f | 3 | 7 | 5.5 | ribbon-centred chevrons; key-text chips (hotbar + legend); FOOD lighter |
| r3 | b613008f | 3 | 6.5 | 5.0 | long narrow chevrons; clock plate; hotbar tray 0.55; FOOD white |
| r4 | 03555e08 | 3.5 | 7 | 5.5 | drift logs/kelp/buoys on lanes, swimmer-view frames, card beside minimap |
| r5 | 16a894c8 | 3 | 7 | 5.0 | coordinator a+b: channel tint + drifting dashed bank rim; HUD text +15%, Food value beside bar, padded "I" |

r5 capture change (disclosed): each view is a 4-frame strip over 3 s (0/1/2/3 s), not a 0.5 s pair; at the
authored 0.84 m/s a half-second pair moves a floater about 0.4 m.

## Disposition (coordinator rule, 13 Oct): r5 gained < 0.5, so T2 is parked at its best read (r2/r4, 5.5). No r6.
Gap to 8.5, from the r5 judge:
- Currents (3/10): the lane reads as "a marked route", not moving water; direction guessed at about 30% from
  the dock and 45% in the swimmer view. Frame-to-frame drift reads as shapes popping, not flowing.
- Capture defect: the swimmer rows posed the trainer on the sand/at the waterline, not carried in deep water,
  so those rows cannot show current carry. A future round should pose the swimmer in the lane first.
- HUD (7/10): smallest text is the clock at about 1.8 mm (ask ≥2.2 mm); "100 / 100" on the green bar is weak;
  the padded "I" still reads as a divider; r5 "100%" overran the plate edge (fixed after the judge, below).
- Untried lever (owner/UX decision): a swimmer-relative HUD current arrow while in a current.

Post-judge fix (0fab46f0): Food value ends one outline inside the plate, caption at readable size, meter ~40 px
(checked in `capture_exploration_hud` hud_full/hud_hungry, not re-judged).
Smoke: `smoke_exploration_legend` PASS (legend sized for key-text chips; it had failed since r2).
