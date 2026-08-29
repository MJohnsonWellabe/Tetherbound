# Type chart — design note

**Lane:** `ralph/T3-TYPECHART` · **Branch base:** `origin/main` @ `a97f3e84`
**Status:** design, pushed before implementation so the coordinator and owner
can react. Numbers below are measured against the tree at that commit, not
estimated.

---

## 0. The finding, verified independently

`ralph/reports/handover-T3-STRONGHOLD-2026-08-29.md` claimed this build has no
type chart anywhere. **It holds.** Verified by:

- reading `scripts/combat/combat_math.gd` end to end — `base_damage` /
  `rolled_damage` take `power, attack, defence, roll, move_power` and nothing
  else;
- reading `scripts/creatures/creature_instance.gd::effective_attack` /
  `effective_defence` — bond scale and buff scale only, never `creature_type`,
  which is stored on the instance (line 26) and read by no combat code;
- grepping `type_chart|typechart|resist|weakness|advantage|super.?effective|
  type_mult|effectiveness` across `scripts/ **/*.gd`, `data/`, `tests/`. The
  only hits are unrelated prose (the legendary's riding advantage, farm yield).

The repo already says so in its own voice, which is the strongest confirmation
available — `tests/test_trainers_data.gd:591`:

> "There is no type-effectiveness system anywhere in this combat build to check
> that against … So 'did you build a balanced five' cannot be pinned by a
> rock-paper-scissors matchup here without inventing one."

Both damage call sites are single, clean and adjacent:
`combat_manager.gd:717` (player strikes) and `:1067` (enemy strikes). That is
the entire integration surface.

---

## 1. The one structural fact that decides the whole design

`data/moves/moves.json` gives every move its **own** `type`, and its header
comment states the rule explicitly:

> "`type` is flavour/vocabulary (ground|water|air) and is **not cross-checked
> against the wielding species' own type** — Reedwing borrows an air-flavoured
> charged move on purpose."

So the chart has a choice of key, and it is not a detail:

| Keyed on | Consequence |
|---|---|
| attacker **species** type vs defender species type | Coverage is a property of *who is in your five*. Answer: carry one of each. Switch. Chore. |
| attacker **move** type vs defender species type | Coverage is a property of *what your five can do*. Answer: use the TM economy. Decision. |

**Key on the move.** This is the single most important choice in the note, and
it is what stops a three-type chart from being degenerate:

- A five-slot party has **ten move slots**. Coverage is a ten-into-three
  problem, not a five-into-three one — it does not solve itself by having three
  bodies.
- It makes §9's preparation loop (*"catch or improve team → **teach a move** →
  equip"*) mechanically real instead of a flavour verb.
- It uses the TM ladder the owner's own board already specifies, rather than
  inventing a parallel system beside it.
- It is already load-bearing in the data: **Mosshell** (Water, charged
  `tremor_roll` = Ground) and **Reedwing** (Water, charged `sky_rend` = Air) are
  the two species with off-type coverage today, both deliberate per that
  comment. The chart gives their existing quirk a mechanical payoff instead of
  retconning it.

Audit of the other 15: **every species' quick move matches its own species
type**, and every charged move except those two does. So on day one the chart
reads to the player almost exactly like a species chart — which is what makes
it *learnable* — and the TM economy is the lever that breaks a creature out of
its birth type later. That progression is the mechanic.

---

## 2. The chart

Three live types. Full reciprocal triangle:

```
            water  →  ground  →  air  →  water
```

| attacking move ↓ / defending creature → | ground | water | air |
|---|---|---|---|
| **ground** | 1.00 | 0.80 | **1.25** |
| **water**  | **1.25** | 1.00 | 0.80 |
| **air**    | 0.80 | **1.25** | 1.00 |

Thematics, in the order of how well they hold: water floods and erodes earth;
thrown stone brings a flier down; wind scatters water. Standard genre literacy —
every player arrives already knowing it, which is worth more here than novelty.

### Why a full triangle rather than a partial chart

**Correcting an earlier draft of this note**, which claimed partial charts
always widen the per-type spread. Measured against the real roster census (§3.3)
rather than assumed, that is false, and the true numbers are worth having:

| chart | ground | water | air | spread |
|---|---|---|---|---|
| full triangle | 1.055 | 1.143 | 0.829 | **1.380** |
| drop `ground → air` | 0.934 | 1.143 | 1.070 | **1.223** |
| drop `water → ground` | 1.130 | 0.885 | 0.829 | 1.364 |
| drop `air → water` | 1.055 | 1.293 | 0.774 | 1.671 |

So two of the three partial charts are *flatter* on today's numbers. The
triangle is still right, for two reasons that are structural rather than
numerical:

1. **A missing edge is unfair by construction**, however the arithmetic lands —
   one type carries a weakness with no advantage, another an advantage with no
   weakness.
2. **Decisively: a partial chart's fairness depends entirely on the current
   census, and that census is a known defect scheduled for repair.** §4 argues
   57.6 % Ground opposition should be diversified. A chart tuned to a
   distribution that is about to change would be wrong the moment it changed.
   The triangle is symmetric under *any* roster distribution — that is the
   property worth buying, and it is worth 0.16 of spread today.

---

## 3. Multiplier magnitude — the actual design argument

**1.25 advantage / 0.80 disadvantage** (reciprocal: 0.80 = 1/1.25). Not
Pokémon's 2.0/0.5. Four independent arguments, all measured:

### 3.1 It is calibrated against the owner's own TM ladder

The board sets TM multipliers at **1.1× – 2.0×, "2.0× = very rare"**. A type
advantage is *permanent and applies to every hit*, unlike a TM which is a
one-time scarce purchase. Pricing the always-on modifier at 1.25× puts it level
with a **mid-ladder TM** (shipped `stone_spike` is 1.3×, `rock_barrage` on the
board is 1.3×). The sentence a designer can hold in their head is: **"matching
type is worth about one TM rung."** At 1.5× a type advantage would be worth more
than every TM in the game except the three 2.0× apexes — the chart would
outrank the reward economy it is supposed to sit beside.

### 3.2 It survives compounding with the 2.0× apex TMs

Measured against the real Warden roster (`warden_aldis`), a L18 Tuskroot
attacker, `combat.json`'s `player_charged.power = 38`, `scale = 2.0`, and the
linear stat curve in `progression.json`:

| Warden's creature | charged hits to kill, base move | with 2.0× TM | 2.0× TM **and** type advantage |
|---|---|---|---|
| Burrowback L16 (209 hp) | 5 | 3 | 3 |
| Brooktail L17 (180 hp) | 4 | 2 | 2 |
| Galecrest L17 (206 hp) | 5 | 3 | **2** |
| Meadowhart L18 (232 hp) | 5 | 3 | 3 |
| Tuskroot L20 (278 hp) | 7 | 4 | 3 |

The apex TM is already the dominant term; the chart moves one or two of these
by a single hit and **never produces a one-shot**. That is the compounding
check the brief asked for, and 1.25 passes it. At 1.5× the same table drops
Galecrest and Brooktail to two-hit kills across the board and the Warden — the
fight meant to test the whole chapter's team-building — starts to fold to one
prepared creature.

### 3.3 It halves the unfairness the existing rosters would otherwise create

**This is the finding that most constrains the magnitude, and it is not
visible without counting.** I censused every creature on every authored trainer
roster in the chapter (66 creature-instances across all five bands):

| | ground | water | air |
|---|---|---|---|
| count | **38** | 10 | 18 |
| share | **57.6 %** | 15.2 % | 27.3 % |

**Ground is 58 % of every trainer creature in the Meadows.** Any chart lands on
a monoculture. Expected offensive multiplier and damage-exchange ratio across
that whole ladder:

| player's type | deals | takes | exchange ratio |
|---|---|---|---|
| ground | ×1.038 | ×0.983 | 1.055 |
| water  | ×1.089 | ×0.953 | **1.143** |
| air    | ×0.923 | ×1.114 | **0.829** |

Best-to-worst spread: **1.38×**. At 1.5/0.667 the same census gives 1.267 vs
0.714 — a spread of **1.77×**.

So the magnitude choice is not a feel call. **1.25/0.80 keeps the starter choice
a flavour (±8 % around neutral); 1.5/0.667 turns Galewisp into a trap** across
more than half the chapter's authored opposition. Reversing the triangle only
moves the deficit onto a different starter — the skew is demographic, not
chart-shaped, and cannot be fixed by bending the elements.

**Galewisp's escape hatch is the same mechanic, not an exception:** because the
chart keys on move type, a Galewisp taught `rock_throw` meets Ground at neutral
instead of 0.80. That is precisely §9's "teach a move", and it is the argument
for keying on the move rather than the species restated as a player experience.

### 3.4 It is still readable at 25 %

Over a real fight — 4–7 charged hits, 15–28 quicks — 25 % is one or two fewer
exchanges, visible on the health bar. And it does not have to be inferred,
because of §5.

---

## 4. What the chart does to the existing ladder

Landing the chart silently re-tunes every authored encounter. Measured:

### 4.1 Ten rungs become walkable by one counter-type

These rosters are **mono-type** — a player with one right-typed creature gets
1.25 out and 0.80 in for the entire fight (a 1.56× exchange swing):

| rung | band | roster |
|---|---|---|
| `practice_trainer` | 1 | ground ×2 |
| `trainer_mira` | 1 | ground ×1 |
| `south_bridge_grunt` | 1 | ground ×2 |
| `tournament_quarter_mira` | 1 | ground ×2 |
| `quarry_picket_dorn` | 2 | ground ×2 |
| `relay_picket_hess` | 3 | ground ×2 |
| **`captain_field`** | 4 | **ground ×3** |
| **`captain_ridge`** | 4 | **air ×3** |
| `pasture_drover_juno` | 4 | ground ×2 |
| `stronghold_patrol` | 5 | ground ×2 |

**Two of the three Captains are mono-type.** That is the largest single balance
consequence of this change and the content lane needs it in writing.

### 4.2 The rungs that *cannot* be walked on one type — and the good news

| rung | band | roster |
|---|---|---|
| `relay_officer_dell` | 3 | ground / water / air |
| `stronghold_checkpoint` | 5 | ground / water / air |
| **`warden_aldis`** | 5 | **ground ×3, water ×1, air ×1** |
| `captain_riverwatch` | 3 | water ×2, ground ×1 |

**The Warden already fields a deliberate three-type five.** The chart turns the
chapter's final exam into a genuine "did you build a balanced five" test
*without a single edit to his roster* — the encounter was authored for a system
that did not exist yet. This is the strongest evidence that a chart is the right
answer to what the owner asked for: the content is already shaped for it.

### 4.3 The Warrens Guardian

A single hand-placed Ground alpha (`burrow_warrens.json`), not a trainer roster.
The chart makes §6's stated intended response — *"improve type coverage"* —
literally true for the first time: a Water answer is worth 1.56× on the
exchange. §6's list of intended responses reads today as aspiration; after this
it is a mechanic.

---

## 5. The UI tell

A hidden multiplier is a mystery, not a mechanic. Constraints: real-time,
directly piloted, controller, must not become menu-reading.

**Half of it already exists.** `scripts/ui/combat_hud.gd:353` already draws the
enemy's type as a colour-coded `TypeTag`. What is missing is the *relation* and
the *confirmation*. Three additions, all glanceable, none readable-at-leisure:

1. **Matchup arrow on the existing enemy TypeTag** — `▲` when the active
   creature's equipped moves are advantaged into this foe, `▼` when
   disadvantaged, nothing at neutral. One glyph on a label that is already on
   screen, already type-coloured, and already updated every frame. It answers
   "is this creature the right one" **before** committing, and it updates on
   switch, which is what makes switching a decision.
2. **Per-hit confirmation** — on a landed hit whose multiplier is not 1.0, a
   short word at the impact ("**STRONG**" / "**WEAK**"), riding the existing
   `impact_flash` / `hit_landed` path. This is the teaching surface: the player
   learns the chart by being told the answer at the exact moment it mattered,
   at zero reading cost.
3. **Nothing else.** No matchup screen, no pre-fight advisory panel, no
   per-move effectiveness list. §9 says *"do not tell the player exactly which
   creature to use"* — an arrow that says "this one is favoured" respects that;
   a panel that ranks all five does not.

Because a creature's quick and charged moves can differ in type (Mosshell,
Reedwing, any TM'd creature), the arrow reports **the best of the two equipped
moves** and the per-hit word reports **the move actually thrown**. A player who
sees `▲` and then reads WEAK on a charged attack has just been taught, in one
exchange, that their two moves are different types — which is the whole
coverage mechanic surfacing itself without a tutorial.

---

## 6. Captain identity — the ambiguity, and the reading I used

Two lanes have flagged this. Three axes give three different answers for which
Captain is §8's "Captain 2 — team composition":

| axis | Captain 2 is |
|---|---|
| design-list order (spec, and every in-code label) | `captain_ridge` |
| in-game encounter order (Riverwatch 59 %, Field 76 %, Ridge 88 % along the corridor) | `captain_field` |
| purpose-fit / the roster as actually authored | `captain_riverwatch` |

**I used the purpose-fit reading, and the rosters decide it on evidence rather
than on labels:**

- `captain_field` — **ground ×3**, mono-type. Under the chart this is a *power*
  test that one counter-type shortcuts. It is §8's Captain 1.
- `captain_ridge` — **air ×3**, mono-type. Same shape.
- `captain_riverwatch` — **water ×2 + ground ×1**, and its own code comment
  says it is *"deliberately BALANCED … so a party built to answer the first two
  cannot walk this one on type alone."* That is §8's Captain 2, written before a
  chart existed to make it true.

**I am not renaming, re-ordinaling or re-rostering any captain** — that is the
content lane's and the owner's call, and `T3-REWARD` has already mapped §14's
reward shape onto the design-list ordinals. I am recording that the *mechanical*
composition test is Riverwatch, and that after this chart lands the label
"Captain 2" and the encounter that behaves like Captain 2 are different fights.

**Flag for the owner:** this changes what a player experiences. Riverwatch is
reached **first** of the three, so under the chart the player meets the
composition exam before either power exam. Either that is the intent (the
composition lesson lands early, and the two mono-type captains are then a
victory lap for a player who learned it), or the captains want reordering /
re-rostering. **That is a design decision, not an implementation detail, and I
am not taking it.**

---

## 7. The six planned types

The board names **Fire, Ice, Nature, Light, Shadow, Electric** under "FUTURE
TYPES (Planned)". Per the brief they are a **documented extension point, not
stubs**:

- the chart is **data**, in `data/config/type_chart.json`, not a hardcoded
  match statement — adding a type is a data edit;
- an unknown type on either side resolves to **1.00**, so a species or move
  introduced with a new type is playable at neutral the moment it exists and
  becomes interesting when its rows are authored;
- no species, no moves and no type entries are added by this lane.

---

## 8. What this lane will NOT do

Per the brief's file ownership: **no rebalancing of trainer rosters or spawn
tables.** `data/config/bands/**` belongs to the content lane. §4's ten mono-type
rungs and the Captain-identity question are handed over as a measured account,
not acted on. The handover will carry exact per-rung numbers.

---

## 9. Summary of decisions

| # | decision | why |
|---|---|---|
| 1 | Chart keys on **move type vs defender species type** | Makes coverage a ten-move problem, not a five-body one; uses the existing TM economy; already latent in Mosshell/Reedwing |
| 2 | Full reciprocal triangle, **water → ground → air → water** | Symmetric; standard literacy; partial charts measurably widen the per-type spread |
| 3 | **1.25 / 0.80** | ≈ one TM rung; survives 2.0× TM compounding with no one-shots; halves the starter unfairness the 58 % Ground monoculture creates |
| 4 | Applies to **both** damage call sites | The exchange ratio is the mechanic; a one-sided chart is just a damage buff |
| 5 | Tell = **arrow on the existing TypeTag** + **per-hit STRONG/WEAK** | Glanceable at speed; teaches by confirmation; respects §9's "don't name the creature" |
| 6 | Chart lives in **`data/config/type_chart.json`**, unknown types → 1.00 | The six planned types are a data edit, not a code change |
