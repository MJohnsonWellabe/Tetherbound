# D19 — Starters are boar-sized

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Status:** accepted, by the owner. **Amends D12 and D13's scale band.**
**Decided:** after the owner's first real playtest of the build, 2026-08-09

## The decision

The three starters are raised to the scale of the old Tuskroot — the largest
creature the owner had stood next to — and the whole wild band moves up with
them. This is the owner's call, made after playing, and it overrides the
1.20–2.00 m band that D12 set and D13 confirmed. D12 and D13 are not edited
beyond a one-line pointer at the top of each; this file is the amendment.

The full table, all seventeen species, in `data/pals/species.json`:

| | old | new |
|---|---|---|
| **Terrapup** (starter) | 1.70 m | **2.00 m** |
| **Ripplet** (starter) | 1.60 m | **1.95 m** |
| **Galewisp** (starter) | 1.55 m | **1.90 m** |
| Pipwing | 1.20 m | **1.35 m** |
| Bramblebun | 1.35 m | **1.50 m** |
| Mudsnout | 1.40 m | **1.55 m** |
| Brooktail | 1.45 m | **1.60 m** |
| Paddlenewt | 1.50 m | **1.65 m** |
| Trailpup | 1.55 m | **1.70 m** |
| Duskhush | 1.55 m | **1.70 m** |
| Mosshell | 1.62 m | **1.77 m** |
| Reedwing | 1.65 m | **1.80 m** |
| Burrowback | 1.70 m | **1.85 m** |
| Meadowhart | 1.95 m | **2.10 m** |
| Galecrest | 2.00 m | **2.15 m** |
| Tuskroot | 2.00 m | **2.15 m** |
| Veridian Stag | 2.60 m | **2.60 m** (unchanged) |

## Why the relative ordering is preserved

The wild band is a **uniform +0.15 m shift**, nothing else. Every wild species
keeps its exact place in the line-up: Pipwing is still the smallest, Galecrest
and Tuskroot still tie at the top, Trailpup and Duskhush still tie in the
middle. D13 spent a whole section establishing the sheets' relative ordering
as the thing worth keeping when the absolute band moved; a shift that reorders
nothing keeps that promise, and keeps the roster reading as "varied creatures"
rather than "everything is the same size now".

The starters are the exception — they jump +0.30/+0.35, not +0.15 — because
they are the point. The owner's finding was specifically that *your* creature
felt small: the one you pilot in combat, the one that follows you all game.
At 1.90–2.00 m the starters now sit in the top quarter of the wild band, peers
of Meadowhart and Galecrest, which is the emphasis D12 was reaching for and,
at 1.55–1.70 m, did not quite land.

No model is rebuilt. Height is one number per species, applied at load by
`pal_body._fit()` — same as every previous rescale.

## D17 is maintained

Mudsnout 1.55 m → Tuskroot 2.15 m is still strictly increasing;
`tests/test_evolution_links.gd` passes without amendment. The starters never
evolve (`GAME_DESIGN.md` §5), so their larger jump touches no link.

## The combat-camera implication — flagged, tunable, not solved here

D12's own "watch for" list said two peer-sized fighters may crowd the combat
camera. That watch item just got worse: creatures up to 0.45 m taller now
fight in the **same 11 m arena**, and the piloted camera frames more body and
less ground. The arena radius and the `camera` block in
`data/config/combat.json` are the dials, both already labelled tunable. This
decision deliberately does not pre-tune them — whether the fight feels
cramped is a playtest finding, and the next play gate (the new first day,
`ralph/BACKLOG.md`) is where it gets found.

Attack reach and the catch formula's accuracy bonus derive from
`body_radius()`, so they scaled with the heights automatically, exactly as
they did under D12.

## What this does NOT change

- **The sheets.** The concept sheets' centimetre figures remain the
  creature's *biology*, true on the page — the same split D12 established and
  D13 reaffirmed. Only the game-scale number moves, for the third time, in
  the same direction all three times.
- **The Veridian Stag.** 2.60 m, still above everything. The legendary's
  headroom over the band shrank from 0.60 m to 0.45 m; if it stops reading as
  *larger than anything you own*, that is a finding to bring back here, not a
  number to quietly bump.
- **Proportions, colliders' relative tuning, the evolution rule.** All carry
  over by the same mechanisms D12 documented.
