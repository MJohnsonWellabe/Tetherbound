# Dual-type resolution — design note

**Lane:** `ralph/T3-CREATURES` · **Base:** `claude/tetherbound-coordinator-onboard-7pz3ah`
with `origin/ralph/T3-TYPECHART` **merged forward, not re-derived**.
**Status:** design, pushed before implementation so the coordinator and the
owner see the multiplier decision before it is baked in, per the lane brief.

Every number below is measured against the merged tree, not estimated.

---

## 0. The question

Five of the nine creatures in
`docs/owner-direction/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md` are dual-typed:

| creature | typing |
|---|---|
| Nightburrow | Ground / Dark |
| Stormtrail | Ground / Electric |
| Cindercub | Fire / Ground |
| Riftfrill | Water / Psychic |
| Ashtusk | Ground / Fire |

`scripts/combat/type_chart.gd` keys on **the attacking move's type against the
defending creature's species type**. It has exactly one answer per defender.
So the only question this lane has to settle is: **what does a defender with
two types do to an incoming move?**

The three standard answers are multiply both multipliers, take the more
favourable, or average them.

---

## 1. The decision

**Multiply.** `mult = chart(move, primary) × chart(move, secondary)`.

I did not pick this on genre convention. I picked it because it is the only one
of the three that does not break a property the type chart already depends on.

---

## 2. Why the other two are wrong here, specifically

`type_chart.gd`'s header states its foundational property, and it is load-bearing
for this entire expansion:

> an unnamed pairing resolves to `neutral`, so a new type is playable the moment
> it exists and becomes interesting when somebody authors its rows.

That is what lets Fire, Electric, Ice, Psychic and Dark ship as **data only,
with no code**. It is the reason this lane is cheap.

**Today, every one of the five dual types pairs one authored type
(ground/water/air) with one unauthored one (fire/electric/psychic/dark).** So
the second type's contribution is `1.0` in every reachable case. Now apply each
rule to Nightburrow (Ground/Dark) being hit by a Water move — `water → ground`
is 1.25, `water → dark` is unnamed and therefore 1.0:

| rule | result | what it means |
|---|---|---|
| **multiply** | 1.25 × 1.0 = **1.25** | The Dark half is a true no-op. Nightburrow keeps Ground's honest weakness to Water. |
| **best-for-defender (min)** | min(1.25, 1.0) = **1.00** | The Dark half **erases** the Ground weakness. |
| **average** | (1.25 + 1.0) / 2 = **1.125** | The Dark half dilutes the weakness by half. |

Under `min` or `average`, **adding a second type is a defensive buff purchased
with nothing**, and the size of the buff is a function of *how much of the chart
has been authored yet* rather than of anything in the fiction. Nightburrow would
be tankier than a plain Burrowback against Water not because it is a shadow-
flame apex but because nobody has written the Dark rows. The day someone does
author them, five creatures silently get harder — a balance change with no edit
to any creature.

Multiply is the only rule under which `neutral` composes as an identity element.
That is not an aesthetic preference; it is the same argument `type_chart.gd`
already makes for why an unknown type must read as 1.00 rather than as free
damage or a silent penalty, extended one layer out.

---

## 3. What multiply actually does to the curve — measured

### 3.1 It is a provable no-op today

Reachable multipliers for all five dual-typed creatures against all three
authored move types:

| defender | ground move | water move | air move |
|---|---|---|---|
| Nightburrow (Ground/Dark) | 1.0000 | **1.2500** | 0.8000 |
| Stormtrail (Ground/Electric) | 1.0000 | **1.2500** | 0.8000 |
| Cindercub (Fire/Ground) | 1.0000 | **1.2500** | 0.8000 |
| Riftfrill (Water/Psychic) | 0.8000 | 1.0000 | **1.2500** |
| Ashtusk (Ground/Fire) | 1.0000 | **1.2500** | 0.8000 |

**Maximum reachable type multiplier across the entire roster: 1.25 — exactly
what a mono-type creature already produces.** No number in the game changes
shape. The compounding analysis in `TYPECHART_DESIGN_2026-08-30.md` §3.2, which
found that a 2.0× apex TM plus a 1.25 advantage never produces a one-shot,
therefore still holds unmodified. **This lane does not move the damage curve at
all.** It is safe to land today on evidence, not on argument.

### 3.2 The reciprocal cancels *exactly*, which is a small gift

The chart's 0.80 is `1/1.25` and — checked, not assumed — `1.25 * 0.8 == 1.0`
is **exactly true in IEEE-754 double**, not merely close. So a future creature
weak in one half and resistant in the other lands on precisely neutral, with no
floating-point residue for `type_chart.classify()`'s `is_equal_approx` to have
to forgive. The chart's magnitude choice, made for entirely unrelated reasons,
happens to make dual typing arithmetically clean.

### 3.3 The one real hazard, and the guard for it

Multiply's genuine risk is the double weakness: **1.25 × 1.25 = 1.5625**.

That matters because `TYPECHART_DESIGN_2026-08-30.md` §3.2 measured **1.5 as
the threshold where the Warden fight folds** — at 1.5 the apex-TM table drops
Galecrest and Brooktail to two-hit kills. 1.5625 is past that line.

It is **not reachable today** (§3.1), because no creature pairs two authored
types. It becomes reachable the moment someone writes the first Fire or Dark
row — for example, Cindercub is Fire/Ground, so an authored `water → fire` of
1.25 would immediately make it 1.5625 to every Water move.

That is a trap laid for a future author who will have no reason to suspect it.
Two guards, both cheap:

1. **A data-declared cap.** `data/config/type_chart.json` gains
   `dual_type: {"rule": "multiply", "max": 1.5625, "min": 0.64}`. The bounds are
   the natural double-advantage and double-resistance values, so the cap is
   non-binding on any ordinary two-type creature and only bites if someone
   authors a row steeper than 1.25 or a third type is ever added. It is data, so
   retuning it is an edit rather than a code change, consistent with everything
   else about this chart.
2. **A regression test that pins the reachable maximum.**
   `test_dual_type.gd` walks every species in `species.json` against every move
   type in `moves.json` and asserts the largest multiplier the real data can
   produce is ≤ 1.25. **The day that test fails, someone has authored the game's
   first true double weakness** — and the failure message points them at this
   section rather than letting 1.5625 ship silently. This is the guard that
   matters; the cap is only the backstop.

I considered clamping to the chart's own single-type extremes (`[0.80, 1.25]`),
which would make a double weakness identical to a single one. Rejected: it
throws away the entire mechanical point of dual typing at the exact moment the
mechanic first does something, to solve a problem that a test can catch at
authoring time instead.

---

## 4. The representation, and why it is additive

`species.json` gains an optional `"type_secondary"` beside the existing
`"type"`. `creature_instance` gains `secondary_type: String`, defaulting to
`""`.

**`creature_type` stays a `String` and keeps its current meaning: the primary
type.** This is deliberate and it is the reason this change is safe:

- **Saves are unaffected.** `save_game.gd:672/723` writes and reads
  `"creature_type"` as a string. An old save loads into a dual-typed species
  with `secondary_type` empty and is then repaired from `species.json` the same
  way every other species field already is.
- **Every mono-type creature is byte-for-byte unchanged.** `""` secondary →
  `multiplier()` returns `neutral()` → `× 1.0`. Seventeen of seventeen existing
  species take no behaviour change whatsoever.
- **The UI keeps working untouched.** `playground_hud.gd:1264` matches on
  `creature_type` for the type colour, `swap_panel.gd:313` and
  `tab_creatures.gd:1070` display it. All still get a single valid string.
- **TM compatibility is untouched.** `tm_db.is_compatible()` and
  `teaching.can_learn()` key on `creature_type`, so a dual-typed creature learns
  its **primary** type's TMs and nothing changes about the reward economy.

That last point is a real design decision and I am flagging it rather than
burying it: **a dual-typed creature does not currently gain access to its
secondary type's TMs.** There are no Fire/Electric/Ice/Psychic/Dark TMs to gain
access to, so today it is unobservable. When those TMs exist, someone must
decide whether Nightburrow can learn Dark TMs. Widening `tm_db` is
`T3-REWARD`'s surface, not this lane's, so I am recording the question rather
than answering it.

---

## 5. What this note does not decide

- **Roster rebalance.** `data/config/bands/*/trainers.json` is untouched, per
  the lane brief and per `T3-TYPECHART`'s own §8. The 57.6 % Ground skew on
  trainer rosters is real, is not fixed by adding types to *wild* creatures, and
  is a pending owner decision.
- **The rows for the five new types.** Fire, Electric, Ice, Psychic and Dark
  ship with **no authored matchups** — every pairing is neutral. That is the
  chart's designed behaviour and it is the honest state: this lane is adding
  creatures that *carry* those types into the world, not designing five
  elemental sub-charts for regions nobody has built. Authoring them is a real
  design pass and should be done deliberately, with §3.3's hazard in hand.
- **The captain-identity question** raised by `T3-TYPECHART` §5. Still open,
  still the owner's.

---

## 6. Summary

| # | decision | why |
|---|---|---|
| 1 | Dual type resolves by **multiplying** both multipliers | The only rule under which `neutral` is an identity; `min`/`average` turn an unauthored second type into a free defensive buff whose size depends on how much of the chart has been written |
| 2 | Additive `type_secondary` / `secondary_type`, `creature_type` unchanged | Saves, UI, TM compatibility and all 17 existing species take zero behaviour change |
| 3 | Data-declared cap `[0.64, 1.5625]` | Bounds the compounding the brief asked about, at the natural double values, as data |
| 4 | A test pinning **max reachable = 1.25** over the real roster | 1.5625 is past the 1.5 the Warden folds at; the day it becomes reachable, that must be a decision, not an accident |
| 5 | No matchup rows authored for the five new types | They are playable at neutral by design; authoring them is a deliberate pass, not a side effect of adding creatures |
