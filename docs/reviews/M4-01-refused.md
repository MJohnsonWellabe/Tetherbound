# M4 gate, round 1: REFUSED

**Date:** August 2026
**Judge:** blind sub-agent, `.claude/skills/systems-judge`
**Shown:** the ten M4 acceptance bullets, `shots/session_party.log`, two frames.
**Not shown:** source, diffs, commits, or any description of the design.

> **REFUSED** — 2 bullets are not met or not shown.

Recorded because a gate whose refusals are not written down is a gate that
quietly stops being one.

## The two bullets

**Catch pal — NOT SHOWN.** The section contained one line, `director reports
caught: 5`, printed immediately after five direct roster insertions:

> That is a counter printed by the system that owns it, and it is the weakest
> form of evidence in this rubric... A counter reading 5 immediately after five
> `add` calls is consistent with the counter simply counting adds.

It also noted the session used species ids like `wild_rabbit`, which are "data
labels, not evidence of a capture", and that no attempt was made to catch a
trainer-owned pal — a hard rule in `CLAUDE.md`.

**Nickname — NOT SHOWN.** Every nickname was `Pal1`…`Pal5`, matching the slot
indices:

> On this evidence "nickname" is indistinguishable from "auto-assigned default
> label"... **A nickname the player cannot change is not the feature the bullet
> names.**

Both failures were in the SESSION, not in the party system — which is exactly
what the rubric's NOT SHOWN rule is for. The code could have been perfect and
the evidence still would not have earned a pass, and "the harness did not test
it" is indistinguishable from "it does not work" to everyone except the person
who wrote both.

## Three defects no test would have caught

- **The party menu opened on the `inventory` action.** Its reading: "Either the
  party menu has taken the inventory binding, or there is no distinct party
  action and the session reached for the nearest one. Both are problems."
- **The M1 debug HUD rendered over the menu**, clipped mid-word by the panel
  edge — `worst landing`, `jump [ ] spri`, `keyboard: W`. "Raw internal state...
  `health 98` sitting next to a party of full-HP pals is actively confusing."
- **`[$] Choose`.** The footer used U+2195; the font has no glyph for it. "A
  player cannot tell which control chooses."

## One thing it was right to distrust

`granted 100000 xp → "xp": 9184`. It could not tell from the evidence whether
90k had gone missing or whether the field meant something narrower, and said so
rather than assuming. It means progress *within* the current level. The field
now documents that and the transcript prints its denominator.

## What it praised, for calibration

It is not a rubber stamp in either direction. On persistence: "this is the part
of the session that is properly constructed... a level-26 pal with 390 HP and a
non-default active index came back intact, so this is not just re-serialising
defaults." On traits it verified the arithmetic itself — `22.0 × 0.96 = 21.12`,
`20.0 × 1.14 = 22.8` — and confirmed the modifiers actually apply. On the party
screen: "I can tell without being told that I am on a party screen, which entry
is selected... and that selection moved between frames."

## Round 2

All six items addressed. Re-judged blind, with no knowledge that a previous
round existed or what it said.
