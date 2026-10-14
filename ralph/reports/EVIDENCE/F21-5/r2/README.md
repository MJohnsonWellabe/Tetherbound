# F21#5 r2: code-blind before/after judge on a matched Oreth duel (Systems lane)

Tue 13 Oct 2026 (CT), tb/ev-systems.
Capture (both legs on the same head, software GL, 1280x800, fixed 20 fps):
`tools/capture_f04_strike_beats.gd --trainer=captain_riverwatch --policies=stand,stand`.
- Before: F21#5 edits stashed (head 0f93047f).
- After: e2df1b36, which adds a contact flash core (`core_pop`), damage numbers 28->40 px with a
  6 px outline, and a dark plate behind the verdict/stagger caption.
Two strikes per leg (shell_bash, tremor_roll) x start/mid/strike/out-hit, in sheets
`sequence-A.jpg` / `sequence-B.jpg`. The mapping is in `private/mapping.json`; it was not shown to the judge.
Disclosed: combat RNG differs slightly between legs, and a foreground occluder appears in both.

## Verdict (one judge subagent, pictures only): prefers A (after), medium confidence
- Damage numbers: A's "▲47"/"33" are readable at sheet scale; B's are half-size and faint.
- Captions: A's captions sit on a dark pill and are legible. B's orange text over grass is illegible at 7 inches.
- Regression in A: the new flash core reads as an opaque off-white disc that hides the creature.
  B's translucent burst with rays read better.

## Action on the regression (this commit)
`core_pop`/`core_hold` are removed from combat.json's impact.quick/charged. With core_pop 0,
impact_flash.gd draws exactly the old burst (the code path is unchanged). The shipped look is
B's burst plus A's numbers and plate, which is the judge's "best combination". Not re-captured.
Hitstop and shake are unchanged (COMBAT §11 limits). The Medium frame-time half is Codex's.
