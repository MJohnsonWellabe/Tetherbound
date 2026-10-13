# F21#5 r3: confirming judge on the shipped combination (Systems lane)

Tue 13 Oct 2026 (CT), tb/ev-systems fb1887ef (core_pop removed: the old burst, plus 40 px outlined
damage numbers and the plated verdict/stagger caption).
Capture: the same recipe as r2, `tools/capture_f04_strike_beats.gd --trainer=captain_riverwatch
--policies=stand,stand`, 1280x800, software GL, fixed 20 fps, two strikes x start/mid/strike/out-hit.
Pair: the shipped leg vs the r2 "before" leg (0f93047f), under fresh neutral labels P/Q.
The mapping is in `private/mapping.json`; it was not shown to the judge.

## Verdict (one judge subagent, pictures only): prefers Q (shipped), medium-high confidence
- Captions: P's bare orange text on grass is hard to read at 7 inches (P-01/02, P-03/04, P-07/08).
  Q's captions sit on a compact dark backing and are clearly legible (Q-01/02, Q-03/04).
- Damage numbers: Q's "▲47" and its strike-2 number are larger and bolder and readable. P's "▲40" is thin
  and its "34" is barely visible.
- Impact burst: about the same in both (the same old burst). There is no opaque disc and no new clutter.
- Disclosed: combat RNG differs between legs (strike 2 has no outcome caption in Q). The shared
  foreground occluder covers more of Q-05/06; it is not a presentation change and is routed to Visuals.
