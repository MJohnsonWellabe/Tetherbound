# D37 — Individuality rolls are real stat variance; traits stay flavour, not balance

**Date:** 2026-08-15 · **Decided by:** this firing, implementing R4.2 against
`GAME_DESIGN.md` 11 and D30's own explicit deferral.

## The decision

R4.2 ("Core stats and per-instance individuality") builds both halves of
`GAME_DESIGN.md` 11's "Individuality" section:

1. **Stat quality varies per instance.** Every creature now carries three
   0.0–1.0 rolls (`iv_hp`/`iv_attack`/`iv_defence`), applied as a real
   multiplier on top of the level curve (`progression.json`'s
   `individuality.variance_pct`, shipped at 0.12 — a stat can run ±12% off
   the species base). Shown to the player as 1–5 stars/bars
   (`appraisal_stars`), never the raw roll — the spec is explicit that exact
   IV numbers are not the intended read.
2. **Traits are data and display only — no numeric combat effect.** Every
   creature rolls a primary trait at creation from a small flavour pool
   (`data/traits/traits.json`: Bold, Calm, Sturdy, Swift, Gentle, Stubborn,
   Curious, Watchful), and a hidden secondary trait rolled at the same time
   but withheld until bond crosses `progression.json`'s
   `traits.unlock_bond_nodes` (shipped at 5, i.e. fully bonded).

## Why traits stop at flavour

`GAME_DESIGN.md` 11 says a creature "starts with one trait" and "a second
trait can develop later through progression/bond," but nowhere in
`GAME_DESIGN.md` or `MEADOWS_PROGRESSION_SPEC.md` is there a definition of
what a trait mechanically *does* — no stat-bonus table, no ability-effect
list, nothing D30 or any later doc names. D30 itself hit this and punted
outright ("Traits stay deliberately out of scope"). Inventing numeric
effects now (e.g. "Bold: +10% attack") would be inventing balance-affecting
game mechanics with no owner brief behind them — exactly what `CLAUDE.md`'s
"do not silently invent major design decisions" exists to stop, even though
"trait effects" is not literally on that file's example list.

So this pass ships the honest, spec-satisfying subset: a trait is a real,
persisted, per-instance identity a player can see and appraise a creature
by, the same register a nature/personality tag would occupy — but it changes
nothing about combat math. If the owner wants traits to carry a mechanical
effect later, that is a new, explicit decision (a stat-bonus table, an
ability hook, or something else) — not a default this pass should assume.

## What changes on disk

- `data/config/progression.json` — new `individuality` and `traits` blocks,
  both `ALL TUNABLE` in the house style `combat.json`/`progression.json`
  already use.
- `data/traits/traits.json` — new, replacing the empty `data/traits/.gitkeep`
  placeholder D30 left. Flavour only, per the reasoning above.
- `scripts/creatures/trait_db.gd` — new, same shape as `move_db.gd`.
- `scripts/creatures/progression.gd` — `individuality_multiplier`,
  `appraisal_stars`, `trait_unlocked`: pure arithmetic, same house style as
  every other function in the file.
- `scripts/creatures/creature_instance.gd` — `iv_hp`/`iv_attack`/
  `iv_defence`/`trait_primary`/`trait_secondary` fields; `from_species` gains
  two more opt-in array parameters (`iv_rolls`, `trait_rolls`) following the
  exact `level_roll`/`cfg` opt-in shape D30 established — every existing
  caller that does not pass them keeps getting today's stats byte-for-byte,
  because the defaults (0.5 average, "" untraited) are no-ops.
- `scripts/combat/encounter_director.gd` — wild spawns roll individuality
  and both trait slots through the same seeded `rng` the level roll already
  uses, so a creature met at a given spot stays reproducible across boots.
- `scripts/ui/tab_creatures.gd` — the Team screen's detail panel shows a
  5-character appraisal bar and the revealed trait(s).
- Save format — VERSION 4 → 5. A pre-R4.2 save migrates every party member to
  average individuality and no traits (`_migrate_v4`), the same "nothing to
  migrate FROM" answer every prior version bump has given a field that did
  not exist yet.

## What was deliberately not built

- **Starters.** `GameState.make_creature` (used for the three starter picks)
  still defaults to average individuality and no trait — the deterministic,
  known-quantity feel of "pick your starter by type" is preserved rather
  than adding a hidden quality roll to a choice the player makes once by
  hand. Wild creatures are where `MEADOWS_PROGRESSION_SPEC.md` 11's own
  "seek better traits/appraisal" grinding loop actually applies. Wiring
  starters in later is a small, additive follow-on if the owner wants it —
  not a gap in this decision.
- **Trait mechanical effects**, as covered above.
- **A UI glyph/icon for appraisal.** The Team screen renders the bar as
  plain ASCII (`*`/`-`), not a unicode star or a new icon asset — `kenney_
  future` has no confirmed glyph coverage for U+2605, and `CLAUDE.md`/D24
  forbid a new icon generation for this. A real icon is a small follow-on,
  not a blocker.
