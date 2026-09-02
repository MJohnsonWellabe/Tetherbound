# D29 — Satiety is a light hunger, and it is now real

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Date:** 2026-08-13 · **Decided by:** the owner, after the UI spec's §6.6
laid out a Palworld-style HP/satiety pairing and asked, in the same session,
for the mechanic underneath it to become real rather than cosmetic.

## The decision

Tetherbound gains a genuine **satiety** stat on player vitals. It drains
slowly over time, food restores it and grants the buffs food already gave,
and low satiety now costs something: soft debuffs — slower stamina
regeneration, and a small movement-speed reduction only once satiety is
critical. **There is still no starvation death.** That half of
`CLAUDE.md`'s old rule was never in question and survives intact; only the
"no meter at all" half changes.

## Why

Two things arrived together and only one of them is new. The UI spec's §6.6
is explicit that it is a *visual* specification and does "not silently
change Tetherbound's hunger/survival rules just to match Palworld's
mechanics" — a bar with nothing behind it would be exactly that. Building
the bar honestly means building the stat it displays. The owner confirmed
this directly: a light hunger mechanic is one of the four canon changes
approved in the follow-up session (alongside pal progression, explicit
capture odds, and mid-combat switching — `D30`, `D31`, `D32`).

This is a scoped amendment, not the mandatory-hunger system `CLAUDE.md`'s
ask-first list warns against. `docs/AGENT_WORKFLOW.md`'s "no starvation-death
meter and never will be" is about the death clock specifically, and that
clock still does not exist.

## What changes on disk

- `scripts/player/player_vitals.gd` — gains a `satiety` / `max_satiety`
  pair alongside the existing `stamina` / `health`, following the same
  dependency-free `RefCounted` shape (see the class comment: "no starvation
  meter and food is a buff system, so nothing here drains on its own over
  time" — that sentence is now half true and gets corrected in place).
  Satiety drains at a slow constant rate; it does not respond to movement or
  actions the way stamina does.
- `data/config/vitals.json` — new. Drain-per-second, restore-per-food-item,
  the debuff thresholds ("low" and "critical"), the stamina-regen penalty
  and the movement-speed penalty, all `ALL TUNABLE` in the house style
  `movement.json` and `combat.json` already use. Kept separate from
  `movement.json` rather than folded into its existing `stamina`/`health`
  blocks, because satiety is a new subsystem with its own debuff curve, not
  a variant of the fall-damage/stamina numbers already living there.
- `scripts/ui/playground_hud.gd` — a thin satiety bar drawn under the HP bar
  (spec §6.6.1, §6.6.4), sharing the left edge and typography of the vitals
  cluster rather than getting its own floating card. Reads `ui_tokens.gd`
  (`D28`) for its warm fill colour, not a locally declared one.
- `data/items/items.json` — food items keep their existing buff effects and
  gain a satiety-restore amount alongside them.

## What was deliberately not built

- **Starvation death, in any form.** No damage-over-time, no forced faint,
  no death state tied to satiety reaching zero. Zero satiety is simply
  "permanently at the critical debuff" until the player eats.
- **Thirst.** Not asked for, not part of this decision. A second meter is a
  second design conversation.
- **Per-item hunger economy tuning.** Restore amounts start as reasonable
  placeholders in `vitals.json`, same as every other tunable in the project
  — not judged final until playtested.

## What it supersedes

`CLAUDE.md`'s hard rule `Food buffs; no starvation-death meter.` becomes
`Light satiety: slow drain, food restores and buffs, soft debuffs when low;
NO starvation death (D29).` — see the edit to that file. The Ask/Flag list's
`adding mandatory hunger/thirst` entry is annotated rather than removed: this
decision is what the owner approved, and it does not license going further
(a real thirst meter, starvation damage) without asking again.
