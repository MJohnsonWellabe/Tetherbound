# Handover — T3-TYPECHART

**Branch:** `ralph/T3-TYPECHART`, off `origin/main` @ `a97f3e84`
**Companion document:** `ralph/reports/TYPECHART_DESIGN_2026-08-30.md` — the
design note, pushed before implementation. It carries the full argument; this
carries what was built, what was verified, and what is still open.

---

## 1. What I was asked

Build a real type chart for the three live types: the chart, its integration
into damage resolution, the data representation, the UI tell, and tests. Report
honestly on what it does to the existing balance. **Do not** rebalance trainer
rosters or spawn tables — that is a separate, deliberate pass, probably with
owner input.

The owner authorised this in session; `CLAUDE.md` otherwise reserves "changing
the type system" as an ask-don't-invent decision.

---

## 2. The premise, verified before building on it

The `T3-STRONGHOLD` lane's finding — **no type chart exists anywhere in this
build** — is correct. Verified three ways before I wrote a line:

- `scripts/combat/combat_math.gd` read end to end. `base_damage` /
  `rolled_damage` took `power, attack, defence, roll, move_power`. No type.
- `creature_instance.gd::effective_attack` / `effective_defence` read bond and
  buffs only. `creature_type` is stored on the instance (line 26) and was read
  by no combat code.
- Repo-wide grep for `type_chart|typechart|resist|weakness|advantage|
  super.?effective|type_mult|effectiveness` across `scripts/`, `data/`,
  `tests/`. Only unrelated prose.

And the repo already said so in its own voice, which I did not expect and which
is the strongest confirmation available — `tests/test_trainers_data.gd:591`
states there is no type-effectiveness system and that "did you build a balanced
five" therefore cannot be pinned without inventing one.

---

## 3. What was built

### Done and verified

| Thing | File | Verified by |
|---|---|---|
| The chart, as data | `data/config/type_chart.json` (new) | `test_type_chart.gd` |
| Chart lookup / classification | `scripts/combat/type_chart.gd` (new, `.uid` committed) | 14 tests, 270 assertions |
| Multiplier in the damage formula | `scripts/combat/combat_math.gd` | unit tests incl. a no-op-default guard |
| Applied at **both** damage call sites | `scripts/combat/combat_manager.gd` | `smoke_combat.gd` integration check |
| `hit_effectiveness` signal, `active_matchup()` | `scripts/combat/combat_manager.gd` | `smoke_combat.gd` |
| `move_db.type_of()` | `scripts/creatures/move_db.gd` | unit tests |
| Matchup arrow on the enemy type tag | `scripts/ui/combat_hud.gd` | `active_matchup()` asserted in `smoke_combat.gd`; parse-checked; rendering not eyeballed |
| Per-hit STRONG/WEAK banner | `scripts/ui/combat_hud.gd` | parse-checked; **rendering not eyeballed — see §6** |
| Unit tests | `tests/test_type_chart.gd` (new, `.uid` committed) | 14/14 green |
| Real-fight integration check | `tests/smoke_combat.gd` | green |

### The three decisions that matter

1. **Keyed on the attacking MOVE's type vs the defending CREATURE's species
   type**, not species vs species. This is the decision that stops a three-type
   chart being degenerate. `moves.json` already declares a move's type
   independently of its wielder ("Reedwing borrows an air-flavoured charged move
   on purpose"), so coverage becomes a **ten-move-slot** problem rather than a
   five-body one — "carry one of each and switch" stops being the answer, and
   the TM economy becomes the lever that changes it. Mosshell and Reedwing
   already ship off-type charged moves; the chart gives their existing quirk a
   payoff instead of retconning it.

2. **Full reciprocal triangle, water → ground → air → water.** I tried partial
   charts (dropping the thematically weakest edge to neutral) and they are
   measurably worse: one type ends up carrying a weakness with no advantage and
   the per-type spread widens.

3. **1.25 / 0.80, not 2.0 / 0.5.** Three measurements, all in the design note:
   it prices a permanent advantage at roughly one TM rung against the owner
   board's own 1.1×–2.0× ladder; it survives compounding with the 2.0× apex TMs
   against the real Warden roster with no one-shots; and it roughly halves the
   unfairness the chapter's Ground monoculture would otherwise create.

### Extension point, not stubs

The board's six planned types (fire, ice, nature, light, shadow, electric) are
**not** stubbed. Nothing in `type_chart.gd` enumerates the three live types; an
unnamed pairing resolves to `neutral`, so a new type is playable at 1.00 the
moment a species or move claims one and becomes interesting when someone
authors its rows. Adding a type is a data edit.

---

## 4. What the chart does to the existing ladder — the numbers

**This is the part the content lane needs.** Everything below is measured
against the tree, not estimated.

### 4.1 The chapter is a Ground monoculture

Census of every creature on every authored trainer roster, all five bands —
66 creature-instances:

| | ground | water | air |
|---|---|---|---|
| count | **38** | 10 | 18 |
| share | **57.6 %** | 15.2 % | 27.3 % |

Any chart lands on that skew. Expected damage-exchange ratio across the whole
ladder at 1.25/0.80: water **1.143**, ground **1.055**, air **0.829** — a
best-to-worst spread of 1.38×. At 1.5/0.667 it would be 1.77×. **The magnitude
choice is mostly this number.**

### 4.2 Ten authored rungs are mono-type

A player with one right-typed creature gets 1.25 out and 0.80 in for the whole
fight — a 1.56× exchange swing:

`practice_trainer`, `trainer_mira`, `south_bridge_grunt`,
`tournament_quarter_mira` (band 1); `quarry_picket_dorn` (2);
`relay_picket_hess` (3); **`captain_field` (ground ×3)**, **`captain_ridge`
(air ×3)**, `pasture_drover_juno` (4); `stronghold_patrol` (5).

**Two of the three Captains are mono-type.** That is the single largest balance
consequence of this change.

### 4.3 Per-rung impact, per starter

Modelled with quick attacks only, a solo creature, no charged attacks and no
dodging — deliberately pessimistic, so it **bounds the worst case: a genuinely
one-dimensional team.** Figures are the fraction of the player creature's own
HP spent clearing the roster; the percentage is the change the chart makes.

| rung | Terrapup (G) | Ripplet (W) | Galewisp (A) |
|---|---|---|---|
| South Bridge grunt | 0.38 → 0.38 (**+0 %**) | 0.39 → 0.25 (−36 %) | 0.49 → 0.76 (**+56 %**) |
| `captain_field` (ground ×3) | 0.60 → 0.60 (+0 %) | 0.61 → 0.40 (−35 %) | 0.77 → 1.20 (**+56 %**) |
| `captain_ridge` (air ×3) | 0.40 → 0.26 (−34 %) | 0.42 → 0.65 (+56 %) | 0.53 → 0.53 (+0 %) |
| **`captain_riverwatch` (mixed)** | 0.47 → 0.63 (+35 %) | 0.47 → 0.41 (−12 %) | 0.60 → 0.57 (−5 %) |
| **`warden_aldis` (3-type five)** | 0.91 → 0.89 (−2 %) | 0.93 → 0.81 (−13 %) | 1.16 → 1.56 (+35 %) |

Read it this way:

- **`captain_riverwatch` is the only rung nobody gets a free ride on** — every
  starter moves, none by more than 35 %, and one type cannot walk it. It behaves
  as owner-direction §8's Captain 2 without a single roster edit.
- **`warden_aldis` barely moves for two of three starters** and cannot be
  gamed by one type. **The chapter's final exam becomes a genuine "did you build
  a balanced five" test with no edit at all** — it was authored for a system
  that did not exist yet. This is the strongest evidence the chart is the right
  answer to what the owner asked for.
- **The mono-type rungs are the swingy ones**, handing one starter a ~35 %
  discount and taxing another ~56 %.
- **A ~56 % tax is "noticeably harder", not a wall** — 1.20 party-HP at Field
  means one heal or one switch, which is exactly §8's brief for a
  one-dimensional team. I do not think this needs "fixing"; I think it needs
  **knowing**.

### 4.4 The Warrens Guardian

A single hand-placed Ground alpha (`burrow_warrens.json`), not a roster. §6's
stated intended response to struggling — *"improve type coverage"* — becomes
literally true for the first time; a Water answer is worth 1.56× on the
exchange. That line read as aspiration before this.

### 4.5 Compounding with the TM ladder — checked, and fine

Against the real Warden roster, a 2.0× apex TM already dominates the damage
curve. Adding a 1.25 advantage moves a kill by at most one charged hit and
**never produces a one-shot** (pinned by a test). At 1.5 it does.

| Warden's creature | base move | 2.0× TM | 2.0× TM + advantage |
|---|---|---|---|
| Burrowback L16 (209 hp) | 5 charged | 3 | 3 |
| Galecrest L17 (206 hp) | 5 | 3 | **2** |
| Tuskroot L20 (278 hp) | 7 | 4 | 3 |

---

## 5. The captain-identity ambiguity

Two lanes flagged it; I did not resolve it and I am not empowered to. Three
axes give three answers for §8's "Captain 2 — team composition":

| axis | answer |
|---|---|
| design-list order / every in-code label | `captain_ridge` |
| in-game encounter order (Riverwatch 59 %, Field 76 %, Ridge 88 % along the corridor) | `captain_field` |
| purpose-fit / the rosters as authored | `captain_riverwatch` |

**I used the purpose-fit reading**, and §4.3 is why: measured under the chart,
Riverwatch is the only captain no starter walks and no single type answers,
while Field and Ridge each hand one starter a large discount. Riverwatch's own
code comment already says it is *"deliberately BALANCED … so a party built to
answer the first two cannot walk this one on type alone"* — written before a
chart existed to make it true.

**Nothing was renamed, re-ordinaled or re-rostered.** `T3-REWARD` has already
mapped §14's reward shape onto the design-list ordinals and I did not disturb
that.

**For the owner, because it changes what a player experiences:** Riverwatch is
reached **first** of the three. Under this chart the player meets the
composition exam before either power exam. That is either the intent — the
lesson lands early and the two mono-type captains are then a victory lap for a
player who learned it — or the captains want reordering or re-rostering. **A
design decision, not an implementation detail.**

---

## 6. Done-but-unverified, and still-open

**Unverified — the honest list:**

- **The two HUD tells have never been looked at.** `active_matchup()` is
  asserted by `smoke_combat.gd` and `combat_hud.gd` parse-checks clean, but no
  frame has been rendered. Font size (26), position (y 232–268, under the enemy
  plate) and colour choices are reasoned, not seen. `ralph/conventions.md`'s
  visual-judge requirement for visual-affecting work is **not met**. Whoever
  picks this up should render a fight frame with a non-neutral matchup before
  calling the tell done.
- **The smoke integration check has only ever run on a mirror matchup.** The
  director spawned ground-vs-ground, so the fight emitted three neutral
  verdicts. The assertion is real (agreement between the fight and an
  independent lookup, plus "emitted no verdict at all" fails), but a manager
  that passed the *wrong* types would not be caught by a mirror. The non-neutral
  arithmetic is covered by unit tests where the pairing can be pinned. A
  stronger version would force a water starter against the ground practice
  cluster; I did not, because reshaping an established test's subject for my own
  convenience is how other assertions in it quietly stop meaning what they say.

**Open, and deliberately not mine:**

- **The roster rebalance.** §4 is the account. Nothing in
  `data/config/bands/**` was touched.
- **The captain-identity decision.** §5.

---

## 7. What I learned that is not visible in the diff

- **The rosters were already written for a chart that did not exist.** The
  Warden's deliberate three-type five, Riverwatch's "cannot walk this on type
  alone" comment, `warrens_watch_pell`'s `_why_team` ("the Air creature is the
  point: the first trainer creature the Ground answer the player just built does
  nothing about"), §6's "improve type coverage" — this chapter has been writing
  *as if* a chart existed for a long time. Several authored intentions become
  true on this branch without anyone editing them. That is a much better
  argument for building the chart than the design documents' language about
  "type coverage" was, and I did not expect to find it.
- **The keying decision was already made for me, in a comment.**
  `moves.json`'s header says a move's type is deliberately not cross-checked
  against its wielder's. Species-keying would have contradicted an existing,
  reasoned data decision; move-keying builds on it. Anyone re-opening this
  should read that comment before assuming species-keying is the obvious choice.
- **`combat.json`'s `player_charged.power` is 38 against `player_quick`'s 9.**
  The charged attack is 4.2× a quick and costs ~4 quicks to charge, so the
  charged attack is the real kill vector and quick attacks are the energy
  economy. Every balance claim about this chart should be reasoned in charged
  hits; a "hits to kill" number computed on quicks is 4× too pessimistic. §4.3's
  table is quick-only *on purpose* (it bounds the worst case) and should not be
  read as expected play.
- **The `_miss_text` channel hides the action grid.** `_draw_grid` sets
  `_grid_panel.visible = false` whenever a message is up. Correct for a rare
  miss, and a real defect for anything that fires per-hit — I nearly shipped the
  type verdict through it. Anyone adding frequent combat feedback to this HUD
  should build their own widget, as the orb cluster and party strip already do.
- **`hit_landed` has nine two-argument callables across tests and tools.**
  Godot errors when a signal emits more arguments than a connected callable
  accepts, so widening it would have broken six files. Hence a separate
  `hit_effectiveness` signal.
- **Environment:** Godot 4.7 install per the brief worked verbatim. The cold
  `--import` exited **0**, not non-zero — the brief's warning did not
  reproduce here. `--check-only --script <file>` is a fast parse check that
  does not boot a scene and does not appear to contend with a concurrent
  headless run; it caught nothing this time but cost seconds.

---

## 8. Disagreements

**I do not disagree with building the chart.** I went in prepared to argue it
was the wrong answer and the evidence went the other way — see §7's first
point.

Three narrower disagreements:

1. **The brief frames the Ground monoculture as something the chart creates. It
   does not; it exposes it.** 57.6 % of the chapter's authored trainer
   creatures being one type is a content defect that existed before this branch
   and will outlive it. The chart is the first instrument that makes it
   *visible*. The fix is diversifying opposition, not tuning the chart — and
   emphatically not inverting the elements, which only moves the deficit to a
   different starter.

2. **"A one-dimensional team has a noticeably harder time" is now true, and the
   temptation will be to call the +56 % figures a balance problem.** I think
   they are the feature. What would be a balance problem is the mono-type
   captains' −35 % *discounts*, which let a prepared player trivialise two of
   the three Sigil fights. If anything gets retuned first, it should be
   `captain_field` and `captain_ridge` gaining a second type, not the tax on
   mono-type parties coming down.

3. **The design note's per-starter census (§4.1) reads more alarming than play
   will be, and I want that on the record so nobody over-corrects from it.**
   Those exchange ratios describe a *mono-type five*. A real Galewisp player
   catches Ground creatures in bands 1–2 because that is what is there. The
   penalty is for refusing to diversify, which is the mechanic working.

---

## 9. File footprint

**New:**
- `data/config/type_chart.json`
- `scripts/combat/type_chart.gd` (+ `.uid`)
- `tests/test_type_chart.gd` (+ `.uid`)
- `ralph/reports/TYPECHART_DESIGN_2026-08-30.md`
- `ralph/reports/handover-T3-TYPECHART-2026-08-30.md`

**Modified:**
- `scripts/combat/combat_math.gd` — `type_mult` param on `base_damage` / `rolled_damage`
- `scripts/combat/combat_manager.gd` — lookup at both call sites, `hit_effectiveness`, `active_matchup()`
- `scripts/creatures/move_db.gd` — `type_of()`
- `scripts/ui/combat_hud.gd` — matchup arrow, per-hit banner
- `tests/smoke_combat.gd` — `_the_type_chart_reaches_a_real_fight`

**Not touched, by ownership:** `data/config/bands/**`, `scripts/world/*`,
terrain/grass/scatter/material files, `data/creatures/species.json` (no type
data needed changing), `data/moves/moves.json` (every move already carried a
type).

---

## 10. Test evidence

| run | result |
|---|---|
| `--only=test_type_chart` | **14 tests, 270 assertions, 0 failed** |
| `--only=test_combat,test_creature,test_moves,test_progression,test_trainers` | **249 tests, 2122 assertions, 0 failed** |
| `tests/smoke_combat.gd` | **OK** — "type chart reached the fight: 3 verdicts, ally ground vs foe ground (hit 0 / 0, arrow 0)" |
| `tests/smoke_boss.gd` | *(see §12)* |
| `tests/smoke_relay.gd` | *(see §12)* |
| `tests/smoke_stronghold.gd` | *(see §12)* |
| `tests/smoke_stronghold_reload.gd` | *(see §12)* |
| `tests/smoke_gate_e_finale.gd` | *(see §12)* |
| full `tests/run_tests.gd` | *(see §12)* |

---

## 11. What I would do next, in order

1. **Render a fight frame with a non-neutral matchup and look at both tells.**
   The one piece of this branch with no visual evidence behind it.
2. **Put §5's captain question to the owner.** It changes what a player
   experiences and it is now blocking a coherent §8.
3. **Roster rebalance pass, with §4 as the brief.** My recommendation, in
   priority order: give `captain_field` and `captain_ridge` a second type each
   (the −35 % discounts are the real problem, not the +56 % taxes); then look at
   whether 57.6 % Ground opposition is what the chapter wants now that type is
   mechanical.
4. **Consider whether the TM economy has enough Air coverage.** The chart makes
   TMs the way a creature escapes its birth type, which raises the stakes on
   `T3-REWARD`'s already-diagnosed Air-TM gap in band 4 (`TM_AT` in
   `scripts/world/playground_world.gd`). That was a content gap before; it is
   now a coverage gap in a live mechanic.
