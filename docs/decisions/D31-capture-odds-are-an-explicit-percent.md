# D31 — Capture odds are an explicit percentage, not a worded tier

**Date:** 2026-08-13 · **Decided by:** the owner, as one of four canon
changes approved alongside `D29`, `D30` and `D32`.

## The decision

The capture-aim HUD shows a large explicit percentage near the target,
coloured by tier (UI spec §10.2), replacing `combat_hud.gd`'s worded odds
ladder — "great odds" down to "poor odds" — entirely.

```
      72%
  CAPTURE CHANCE
```

Tier colours stay (spec §10.2's bands: red under 25%, amber 25–49%, teal
50–74%, bright teal/green 75–94%, pale mint/gold 95–100%), but colour is now
decoration on top of an explicit number, never the only signal.

## Why

`combat_hud.gd`'s own comment is the old rationale, word for word: *"the
aim-mode odds readout, worded and coloured by tier rather than shown as a
percentage — '38%' is a spreadsheet, 'fair odds' is a read on the animal."*
That was a reasonable call at the time it was made, but it was **an agent
design choice**, not owner canon — nobody asked for it, it was decided
in-line while building the capture HUD. The UI spec's §10.2 is explicit that
the percentage is the display, sourced directly from Palworld's own capture
screen (spec PW-05: "capture probability near the target, not in a distant
corner"). The owner reviewed both and chose the number. That is the whole
decision: not a new catch-math formula, a different way of showing the one
`catch_math.gd` already computes.

## What changes on disk

- `scripts/ui/combat_hud.gd` — `ODDS_TIERS`' worded labels
  (`"great odds"` … `"poor odds"`) are replaced by the tier *colours* alone,
  read against the raw `catch_math.catch_chance()` fraction formatted as a
  percentage. The five-band threshold list stays — it is now a colour table,
  not a label table.
- Layout: the number moves from wherever the worded tier sat to
  target-centred, per spec §10.2's 46–60px large-number sizing, near the
  reticle rather than in a corner HUD block.
- Nothing in `data/config/catching.json` changes. `catch_math.gd`'s formula,
  curve and clamps are untouched — this decision is presentation, not
  balance.

## What it supersedes

The worded-tier design in `combat_hud.gd` and its accompanying comment
block, which is now stale and gets corrected in the same edit. The
short-terse-label constraint that comment names ("the first capture showed
the long bottom-tier label wrapping the whole aim verb row onto a second
line") stops being a constraint at all once the readout is a number — a
percentage cannot wrap the way a phrase can.

## What was deliberately not built

- **A precision change to the underlying odds.** The catch-chance formula,
  its HP curve, its centre/edge accuracy bonuses — all `D08`/`catching.json`
  territory, all unchanged.
- **A tooltip or breakdown of why the number is what it is.** The spec's
  §10.2 shows the number alone; explaining the formula in-HUD is a
  different, larger feature nobody asked for here.
