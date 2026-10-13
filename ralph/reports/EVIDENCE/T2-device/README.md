# CARD:T2 device profile (7-inch): current direction + small HUD text, Systems lane, PARKED at 5.0–5.5/10

Tue 13 Oct 2026 (CT), tb/ev-systems. Capture: `tools/capture_tidewake_f13_5.gd --only=currents`,
1920x1080, software GL; three crossings x two views 0.5 s apart. Sheets: each cell is a 7-inch panel width
(590 px), `rN_sheet_7inch.jpg`. A fresh code-blind judge each round, scored out of 10 (WORKFLOW §8.1 rule 10).

| Round | Head | Currents | HUD | Overall | Change |
|---|---|---|---|---|---|
| r1 | 69ac6067 | 3 | 5 | 4.5 | baseline: comets read as debris; hotbar 1–5 and M/I/B about 1 mm |
| r2 | 1867bb9f | 3 | 7 | 5.5 | ribbon-centred chevrons; key-text chips (hotbar + legend); FOOD lighter |
| r3 | b613008f | 3 | 6.5 | 5.0 | long narrow chevrons; clock plate; hotbar tray 0.55; FOOD white |

## Findings
- HUD: r1 -> r2 gained (the hotbar numbers and keys went from illegible to about 2 mm, high contrast). Remaining asks:
  the smallest text (FOOD, "MAIN STORY") about 1.6–1.8 mm; "100%" white on gold is low contrast; the bare "I" key
  is ambiguous; the objective card clips the horizon.
- Currents: three shader iterations, still 3/10. From the dock camera the lanes are seen nearly edge-on at
  30–80 m, and every foam mark lands as 1–2 px hairlines on the 7-inch cell. Two stills 0.5 s apart do not
  show a drift (about 0.4 m at the authored speed). Water-surface foam does not move the score; parked per
  the two-failed-attempts rule.

## Options (need a decision; see the coordinator message)
1. A swimmer-relative HUD current arrow while in a current (UX addition; owner/UX decision).
2. 3D drift markers from installed assets on the lanes (buoys with streaming pennants, driftwood) via Visuals.
3. Re-scope the capture to the in-water swimmer camera, which is what the player reads currents from.
