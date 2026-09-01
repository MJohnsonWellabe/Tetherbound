# Owner directives — 2026-09-01

Recorded verbatim so it survives session turnover. Per CLAUDE.md's canon
precedence, explicit owner directives outrank settled specs, historical
backlog wording, and any blind critic's visual-census finding.

## OD-0901-1 — creature scale: bigger than the player is the goal, not a defect

> "I think almost all creatures should stand taller than the character.
> That's part of the allure of the game is these big beautiful fantastical
> creatures."

**Context this corrects:** `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md`
defect 64 (`BACKLOG-VISUAL-STARTER-SCALE`) called both starters (Terrapup
1.92m, Ripplet 1.93m) rendering taller than the 1.80m trainer a defect, on
the reasoning that a Palworld-style scale-agreement read expects the human
reference to dominate the frame. A lane fixed it literally — shrinking
Terrapup to 1.62m and Ripplet to 1.55m, landed on `main` at `ebb97677` — and
that was the wrong call. It optimized for a blind critic's rubric over the
owner's actual stated intent, which is the opposite: creatures should loom,
not shrink to fit beside the player.

**This directive supersedes defect 64 outright.** A creature standing taller
than the 1.80m trainer is not, on its own, something to fix. This also
colours defect 65 (`BACKLOG-VISUAL-BADGER-LINE-SCALE`, Terrapup vs
Burrowback) and 67 (`BACKLOG-VISUAL-ALPHA-SCALE`, alpha Galecrest vs
Veridian legendary) differently than their original write-ups assumed: any
future work in this area should default to "make it bigger / keep it big"
rather than "shrink toward the player," and any *relative* ordering these
defects care about (cub vs. adult, alpha vs. legendary) should be resolved
by raising the smaller side, not lowering the larger one, wherever that's
consistent with `docs/decisions/D17`'s evolution-size rule and the
0.60-2.60m band `D12`/`D19`/`D69` already settled.

**Status:** `ralph/VISUAL-STARTER-BADGER-SCALE-REVERT` in flight to correct
Terrapup/Ripplet back up, taller than before, not merely back to their
pre-fix values.

`ralph/VISUAL_LEDGER.md` and `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md`
are left as historical record of what a blind critic said — not amended —
per this repo's own practice of correcting forward rather than rewriting
what a report got wrong. This file is the standing correction any future
lane should read before touching creature scale again.
