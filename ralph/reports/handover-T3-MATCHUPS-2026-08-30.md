# Handover — T3-MATCHUPS

**Branch:** `ralph/T3-MATCHUPS`, off `origin/main` @ `477a296a`, with
**`origin/ralph/T3-CREATURES` @ `5bdc2c68` merged forward** (clean, no
conflicts). That merge is what brought in dual typing, the five new types, the
ten new-type moves and the four dual-typed species this lane's rows act on.

**Companion:** `ralph/reports/MATCHUPS_DESIGN_2026-08-30.md` — the design note,
pushed before implementation as instructed. It carries the full argument and
every measurement; this carries what was built, what was verified, and what is
still open.

Every number here is measured against the tree by a harness mirroring
`combat_math.gd::base_damage` and `progression.gd::stat_at_level` over the real
data files. After the chart landed I re-pointed that harness at
`data/config/type_chart.json` itself and asserted the chart I measured is
byte-identical to the chart that shipped, so nothing below describes a draft.

---

## 1. What I was asked, and the one-line answer

Turn on the five types the creature expansion shipped inert, honouring the
owner's five fixed pairs, and report honestly what it does to the game.

**It does almost nothing to the game, and that is the finding.** The chart adds
five working types without moving a single number in any of the 27 authored
trainer fights, for any of the three starters, including the Warden. One
creature — Ashtusk — changes, and its change is forced by the owner's own
instruction rather than chosen by me.

---

## 2. The chart

Advantage **1.25**, resist **0.80**, everything else 1.00 by omission.

| attacking move ↓ / defending creature → | ground | water | air | fire | electric | ice | psychic | dark |
|---|---|---|---|---|---|---|---|---|
| **ground**   | — | 0.80 | **1.25** | · | · | · | · | · |
| **water**    | **1.25** | — | 0.80 | **1.25** | · | 0.80 | · | · |
| **air**      | 0.80 | **1.25** | — | · | · | · | · | · |
| **fire**     | · | 0.80 | · | — | · | **1.25** | · | **1.25** |
| **electric** | 0.80 | **1.25** | **1.25** | · | — | · | · | · |
| **ice**      | **1.25** | · | · | 0.80 | · | — | · | · |
| **psychic**  | · | · | · | · | **1.25** | · | — | 0.80 |
| **dark**     | · | · | · | · | **1.25** | · | **1.25** | — |

### 2.1 The circle the owner asked for

Two closed 5-cycles, sharing exactly one edge — and that edge is one of his own
pairs:

```
elemental ring:   water → fire → ice → ground → air → water
storm/mind ring:  dark → psychic → electric → water → fire → dark
```

Two chords sit outside the rings and carry the asymmetry he licensed:
`dark → electric` (his fixed pair; Dark's second advantage) and
`electric → air` (Electric's second advantage, paying for its two weaknesses).

### 2.2 Why each row is what it is

| row | reason |
|---|---|
| `fire → ice`, `water → fire`, `electric → water`, `electric → ground` (resist), `dark → electric`, `psychic → electric` | **Owner-fixed.** Implemented literally. "Dark **or** Psychic" taken as **both** — the safe reading, and it makes Electric genuinely high-risk/high-reward rather than a type with one counter nobody owns |
| `fire → dark` 1.25 | Dark needs exactly one weakness (his worked example) and Fire is the only live *illuminating* type. Light is the obvious long-term second answer and can join later as a data edit |
| `dark → psychic` 1.25 / `psychic → dark` 0.80 | Genre-canonical; closes the storm/mind ring; the resist is what makes Dark the "stronger type" rather than merely a type with two arrows |
| `electric → air` 1.25 | Lightning into a flier. Measured cost to the Air starter across the authored ladder: **zero** — no trainer creature can throw an Electric move |
| `ice → ground` 1.25 | The cold region is what the Ground biome fears; a rare Frostclaw should feel consequential. **Highest-leverage number in the chart — see §6.1** |
| `fire → water` 0.80, `ice → fire` 0.80 | Reciprocals of the two owner-fixed advantages, in the shipped chart's own reciprocal style |
| `water → ice` 0.80 | Non-reciprocal. Gives Ice a defensive identity so it is not purely offensive, and stops Water — already the strongest starter — being the answer to everything. Zero effect today |

### 2.3 Magnitudes: 1.25 / 0.80 uniformly, and why not per-type

The brief invited the new types to carry their own magnitudes. **They should
not.**

The anchor for 1.25 is the owner board's TM ladder, and the board's own heading
is **"TM SYSTEM (ALL TYPES)"** — confirmed by shipped `data/moves/tms.json`,
where ground, water and air all run the same shape and all three top out at
exactly 2.0×. A per-type chart magnitude would have nothing to be calibrated
*against*, and it would make the one sentence a designer can hold in their head
— *matching type is worth about one TM rung* — false for five of eight types.

The deciding reason is different, though. **The owner asked for asymmetry
between types, and asymmetry is already fully expressible in the graph.** Dark
is stronger than Psychic because it has two advantages, one weakness and a
resist — not because its arrows are bigger. And `combat.json`'s
`damage.variance` is **0.1**, so every hit already swings ±10 %: a player
genuinely cannot feel 1.25 against 1.35, but they can *count arrows* from play.
Buying strength with magnitude would be unreadable where buying it with topology
is not.

---

## 3. What it does to the game — measured

### 3.1 The two censuses that decide everything, neither previously recorded

| | value |
|---|---|
| authored trainer rungs | **27** |
| trainer creature-instances | **66** |
| **dual-typed creatures on any trainer roster** | **NONE** |
| **move types any trainer creature can throw** | **ground, water, air — only** |

The four dual-typed species live only in `bands/*/spawns.json` — the wild.
**`test_no_trainer_roster_creature_is_dual_typed` now pins this**, because it is
a property of *content* that a roster edit in another lane could break without
ever hearing about this file.

### 3.2 The authored ladder does not move

Per-rung cost for each starter, before vs after, across all 27 rungs (same
pessimistic quick-only, solo, no-dodge model `TYPECHART_DESIGN` §4.3 used, so
the numbers are directly comparable):

> **+0 % on 27 of 27 rungs, for all three starters.**

Per-starter exchange ratio over the whole ladder, unchanged to three decimals:
Terrapup **1.055**, Ripplet **1.143**, Galewisp **0.829**.

This is not a weak chart; it follows necessarily from §3.1. A mono-typed starter
meeting mono-typed ground/water/air opposition throwing ground/water/air moves
never touches a new row.

### 3.3 The Warden fight is bit-for-bit identical

All fifteen multipliers and all fifteen hits-to-kill against `warden_aldis`'s
five, with the apex 2.0× Water TM in hand, are unchanged. **Not one number
moves.** All five of his creatures are mono-typed, so no double multiplier is
reachable in the chapter's final exam. Full table in the design note §4.3.

### 3.4 The one thing that changes: piloting a dual-typed creature

| creature | rungs that move | what and why |
|---|---|---|
| **Nightburrow** (Ground/Dark) | **0 of 27** | Nothing beats or resists both halves |
| **Riftfrill** (Water/Psychic) | **0 of 27** | Same |
| **Stormtrail** (Ground/Electric) | 27 of 27, **−20 % to +25 %, roughly a wash** | Its *quick* is Electric (`spark_bite`), so the owner's `electric → ground` resist costs it into Ground rungs and `electric → air`/`→ water` pays it back elsewhere |
| **Ashtusk** (Ground/Fire) | **8 of 27, +8 % to +44 %** | Takes **1.5625** from Water moves — the game's first double weakness. Exactly the 8 rungs that field a Water creature |

**Do not act on Stormtrail's percentages.** `player_charged.power` is 38 against
`player_quick.power` 9, so the charged attack is the kill vector, and
Stormtrail's charged (`trailblaze_pounce`) is **Ground**, which no new row
touches. The quick-only model overstates this badly; its real cost is to the
energy economy, not the damage curve.

---

## 4. The compounding analysis, and the pin I changed

### 4.1 Worst-case reachable multiplier

| | before | **after** |
|---|---|---|
| max over the real roster | 1.2500 | **1.5625** |
| reached by | 21 ordinary pairings | **exactly one: a Water move into Ashtusk (Ground/Fire)** |
| min over the real roster | 0.8000 | **0.8000 — unchanged** |
| double resist (0.64) | unreachable | **still unreachable** |

**Worst compounded case this chart makes reachable: 1.5625 × the 2.0× apex Water
TM = 3.125**, against a shipped ceiling of 2.5. Measured against wild Ashtusk at
L16 (289 hp) that is **3 charged hits either way** — the ceiling rises 25 % and
the fight length does not change.

### 4.2 The pin change, stated as a decision

`test_dual_type.gd` asserted the maximum the real data can produce is 1.25, with
a comment saying *"the right response is NOT to delete this test or widen its
bound. It is to decide, deliberately, whether the game wants double
weaknesses — and if it does, to re-measure the Warden."*

**This is that day. The decision was taken and the Warden was re-measured
(§3.3).** Three things decided it:

1. **It is forced, not chosen.** `water → ground` is shipped and tuned;
   `water → fire` is the owner's own second pair; Ashtusk's Ground/Fire typing
   is settled owner direction. There is no chart obeying all three that avoids
   1.5625, short of gutting dual typing with a clamp.
2. **The inherited alarm points somewhere else.** `DUALTYPE_DESIGN` §3.3
   flagged 1.5625 as past the 1.5 at which the Warden folds. That threshold was
   measured **on the Warden's own five, none of which is dual-typed.** The
   hazard the two previous lanes correctly flagged turns out to be aimed at a
   fight it cannot reach.
3. **It costs no hits** (§4.1).

The replacement pin is **stronger, not weaker**: it asserts the number, *and*
that exactly one pairing reaches it, *and* which pairing. A second creature
becoming double-weak now fails the test. Cindercub (Fire/Ground, currently in
`species_pending.json`) is expected to join Ashtusk there the day its mesh
lands — a second name in the failure message, not a new number.

### 4.3 Two other test premises this genuinely invalidates

Both changed deliberately with the reasoning recorded in place, neither
loosened:

- **`test_an_unauthored_second_type_changes_nothing`** iterated
  fire/electric/ice/psychic/dark as examples of "unauthored". They are authored
  now, so naming them would assert the opposite of what the chart does. It now
  uses `nature`/`light`, **plus a general form** that walks every declared
  triple and asserts the identity wherever the second half is neutral — a
  strictly wider assertion than the hand-listed one it replaces.
- **`test_unknown_and_empty_types_are_neutral`** listed fire/ice/electric for
  the same reason. Now `nature`/`light`. I also removed `shadow` from it, for a
  different reason: it is the board's earlier label for what shipped as `dark`
  (§6.3), and leaving it there as a blessed "unknown type" would quietly
  endorse the exact confusion that makes someone author `shadow` rows against a
  `dark` roster.

### 4.4 One float fact, checked rather than assumed

`1.25 * 0.8 == 1.0` and `1.25 * 1.25 == 1.5625` are **exactly** true in
IEEE-754, so opposed halves land on precise neutral and the `dual_type.max`
bound is exactly non-binding. But **`0.8 * 0.8 == 0.6400000000000001`, not
0.64** — harmless today (`min` is a floor and returns the larger), but anyone
who later turns that floor into an equality check should know the config's
`0.64` sits a hair below the true double resist.

---

## 5. The HUD colours

The gap T3-CREATURES flagged, and it was worse than "missing": the five new
types fell through `combat_hud.gd::_type_color`'s default arm to
**`GROUND_OCHRE`**, so a Dark creature drew as **the Ground colour** on the
enemy type tag — the very label the matchup arrow rides on. Harmless while
those types were inert; actively misleading the moment they have chart rows.
`playground_hud.gd::_type_colour` had a second hand-written `match` with a
*different* fallback (`TEXT_SECONDARY`); the two had already drifted.

Added to `ui_tokens.gd`: `FIRE_EMBER`, `ELECTRIC_GOLD`, `ICE_FROST`,
`PSYCHIC_LILAC`, `DARK_VIOLET`, one `TYPE_COLOURS` table and a
case-folding `type_colour(type, fallback)` accessor. **Both HUDs now read one
table**; each keeps its own fallback, because they genuinely differ — mid-fight
the tag must stay readable on the enemy plate, out in the field an unrecognised
type should recede.

Hues come from the owner's own art: the board's FUTURE TYPES swatches and the
creature-expansion reference sheets (Nightburrow's purple emissive cracks,
Stormtrail's yellow-gold lightning, Cindercub's terracotta, Frostclaw's icy
blue, Riftfrill's lilac frills). Two constraints shaped the exact values and
both cost something:

- **Ice** had to separate from `WATER_BLUE` and `AIR_SKY`, already two adjacent
  blues. It is therefore much paler and less saturated than either — "frost",
  not "a colder water".
- **Dark and Psychic** are both purple in the owner's art. Separated by **hue**
  (violet vs pink-magenta) rather than lightness, because lightness is what a
  19px label on a 7-inch handheld loses first.

**Nature and Light deliberately have no colour.** They have no species, no move
and no row; a colour for a type nothing can be is a stub.

### 5.1 Rendering them found a second, larger gap — the one that actually mattered

`tools/capture_type_tell.gd` gained frames for Dark, Electric, Psychic and Fire
foes. **Rendering them immediately showed the colours never appear**, and the
reason is worth more than the colours were:

> **The enemy type tag only ever wrote the foe's PRIMARY type.** Ashtusk drew as
> `GROUND`. Nightburrow as `GROUND`. Riftfrill as `WATER`.

`combat_manager.gd` has resolved damage through `multiplier_dual` since
T3-CREATURES — both call sites *and* `active_matchup()` — so the arithmetic was
always right. Only the *tell* was mono-typed. That was invisible while the five
new types had no rows and every second half was worth exactly 1.0. **This lane
is what made it visible**: the game's first double weakness is a Water move into
Ashtusk at 1.5625, and a player seeing only `GROUND` had no way to tell why that
hit landed harder here than on the Burrowback behind them.

Fixed: the tag now reads **`GROUND/FIRE`** when a second half exists. A slash
rather than a second widget, for the same reason the arrow rides this tag rather
than getting its own — real-time, directly piloted, 7-inch handheld; the plate
has room for one more word, not one more element. **Rendered and inspected at
1920×1080**: it fits on one line and does not overflow the plate.

And the colours turn out to be **latent on the enemy tag but live on the action
grid**, which I would not have known without looking:

- The tag paints the *verdict* colour whenever a matchup is non-neutral, and
  all four live dual-typed creatures have a ground or water primary — so **no
  shipped foe can put a new colour on that tag**. It becomes reachable when
  Sparkit, Cindercub, Shadelet or Frostclaw ship, all of which have a new
  *primary* type and all of which are mesh-blocked.
- The action grid's move hairlines read `_type_color(_move_type(...))` on the
  **player's** creature, and the ten new-type moves are on creatures that exist.
  Rendered: piloting Stormtrail draws **ELECTRIC_GOLD** under `Spark Bite` where
  it used to draw GROUND_OCHRE, clearly separable from the ochre Ground hairline
  under its own charged `Trailblaze` in the same grid.

So the fallback bug was real and is fixed on the surface a player can reach
today; the rest is correctly in place for the meshes that are coming.

---

## 6. Disagreements, and what other lanes need from this

### 6.1 `ice → ground` is the highest-leverage number here, and the roster lane must agree with it

Ground is **57.6 %** of authored trainer creatures, so an advantage into Ground
is an advantage into most of the chapter. Today this row costs and gains
**nothing**: no obtainable creature is Ice (Frostclaw is mesh-blocked), no
trainer throws an Ice move, measured per-rung delta 0 %.

The day Frostclaw ships as catchable, or an Ice TM exists, **Ice becomes the
chapter's best offensive type**, joining Water as a second answer to a Ground
monoculture. I took the edge anyway because the brief told me not to balance
around today's skew as permanent and because the owner asked ecology to do the
storytelling. **If Ground stays near 57.6 %, revisit this row.** The
lower-leverage alternative I rejected was `ice → air` (27.3 %), which would have
given Air a third weakness — and Air is already the deficit starter at 0.829.

### 6.2 The measurement changed the design once, and that is worth reading

An earlier draft had **`fire → ground` 0.80** ("earth does not burn") — my
invention, not the owner's. Measured, it taxed Ashtusk on **26 of 27 rungs**
instead of 8, because Ashtusk's quick move is Fire (`ember_bite`) and 57.6 % of
the ladder is Ground. It was also weak genre literacy: Fire vs Ground is neutral
in the convention every player arrives with. **Dropped.** This is the one place
the harness overturned the design rather than confirming it, and it is the
argument for building the harness first.

### 6.3 The board says Shadow; the game says Dark

`docs/reference/owner-board-2026-08-15-systems-and-castle.png`'s FUTURE TYPES
panel names Fire, Ice, **Nature**, **Light**, **Shadow**, Electric. The newer
creature brief and the owner's matchup instruction both say **Dark**, and
`species.json` ships `dark`. Under `CLAUDE.md` precedence, **Dark is the name
and Shadow is its earlier label, not a ninth type.** The board also does not
list **Psychic** at all — the creature brief introduced it with Riftfrill.

Recording it because a future author reading the board alone would write
`shadow` rows against a `dark` roster and get a chart that silently does
nothing — the failure mode `neutral`-by-omission makes invisible. The `types`
vocabulary in `type_chart.json` is the guard and `test_dual_type.gd` holds every
species to it.

### 6.4 Ashtusk is now measurably worse to pilot than a plain Tuskroot

A rare, owner-designated "mini-Alpha tier" prestige variant that is *strictly
worse to own* than the common species it varies would be a trap. It is worse on
8 rungs and better on none, because its Fire quick meets no advantage anywhere
in the authored ladder. The 1.5625 is unavoidable (§4.2); the compensation is
not mine — a Fire TM (`T3-REWARD`), or its spawn level, or accepting that its
value is the encounter rather than the catch.

### 6.5 I did not take a Ground offensive edge, and the owner's wording and the numbers agreed

The genre-obvious move is Ground beating Electric. The owner said **resists**.
Honouring the word is also the correct balance call — at 57.6 %, an offensive
edge for Ground is the most inflationary entry this table could hold. Rare for
phrasing and measurement to point the same way; worth recording that they did.

### 6.6 What I did not touch

`data/config/bands/*/trainers.json` (roster rebalance — not mine, and a separate
pass is under way), `encounter_director.gd` and `spawns.json` (T3-ENCOUNTER),
`species.json` typing (settled), move and TM data, anything visual beyond the
type-tell colours.

---

## 7. Done-verified vs still-open

### Done and verified

| thing | verified by |
|---|---|
| The eight-type chart, as data | `test_type_chart.gd`, 23 tests |
| The owner's five fixed pairs | `test_the_owners_five_fixed_pairs_are_honoured` |
| Ground resists Electric without beating it | `test_ground_resists_electric_without_beating_it` |
| The shipped 3×3 block is byte-identical | `test_the_shipped_three_by_three_block_is_untouched` (literal table, not derived from the file it checks) |
| Ground's and Air's rows gained nothing | `test_the_two_untouched_rows_gained_no_entries` |
| Every type has an advantage and a weakness | `test_every_type_has_at_least_one_advantage_and_one_weakness` |
| Dark is the owner's worked asymmetry | `test_dark_is_the_asymmetry_the_owner_asked_for` |
| One magnitude across all eight types | `test_one_advantage_magnitude_and_one_resist_magnitude_across_all_eight` |
| The extension point survived | `test_the_unplanned_types_are_still_neutral_everywhere` |
| Max reachable = 1.5625, one pairing, named | `test_the_worst_multiplier_the_real_data_can_produce_is_one_double_weakness` |
| No trainer roster creature is dual-typed | `test_no_trainer_roster_creature_is_dual_typed` |
| Neutral is still an identity, generally | `test_an_unauthored_second_type_changes_nothing` |
| **No code changes needed** | The chart is data by design; this lane is the proof |

### Still open

- **The HUD frames have not been judged at handheld resolution.** They render at
  1920×1080. The type tag is a pre-existing 19px label whose *colour* I changed
  and whose *text* is now up to one word longer, so it stays above
  `smoke_hud_handheld_legibility.gd`'s cap-height floor — but `GROUND/ELECTRIC`
  is the longest string that label has ever had to hold, and the
  ICE_FROST-vs-AIR_SKY and DARK_VIOLET-vs-PSYCHIC_LILAC separations are exactly
  the judgements that could fail at 1280×800 on the ROG Ally proxy. Nobody has
  looked. **`GROUND/ELECTRIC` (Stormtrail) is the string to check first**; the
  frame I rendered is the shorter `GROUND/FIRE`.
- **ICE_FROST, PSYCHIC_LILAC and DARK_VIOLET have never been rendered**, because
  no shipped foe can put them on the tag (§5.1) and no shipped creature carries
  an Ice move. They are reasoned, not seen. The first Frostclaw or Shadelet
  build should re-run `tools/capture_type_tell.gd` before anything else.
- **No fight in any test has ever resolved a non-neutral NEW-type matchup.**
  `smoke_combat.gd`'s director draws ground-vs-ground (T3-TYPECHART §6 records
  this); the new rows' arithmetic is covered by unit tests where the pairing can
  be pinned. Forcing a Dark or Electric pairing through a real fight is the
  stronger check and I did not reshape an established test's subject to get it,
  for the reason that lane gave.
- **`tools/_probe_pacing.py` is still stale** — T3-TYPECHART §7 flagged that it
  reimplements the damage model in Python with no type multiplier, and it is the
  tool the xp curve was tuned with. This lane widens the gap. Not on any CI path
  and nothing is broken today; whoever next owns pacing should teach it the
  chart or make it call the real formula.

---

## 8. Test evidence

| run | result |
|---|---|
| `--only=test_type_chart` | **23 tests, 0 failed** |
| `--only=test_dual_type` | **15 tests, 431 assertions, 0 failed** |
| `--only=test_type_chart,test_dual_type` | **41 tests, 856 assertions, 0 failed** |
| `--only=test_type_chart,test_dual_type,test_combat,test_moves,test_creature,test_trainers,test_hud` | **252 tests, 2977 assertions, 1 failed** — the one failure is inherited, see §8.1 |
| `tests/smoke_combat.gd` | **OK** — "a fight can be entered, piloted, won and left" |
| `tests/smoke_relay.gd` | **OK** — captain beaten, captive freed, Gear carried |
| `tests/smoke_stronghold.gd` | **OK** — "stronghold smoke test passed" |
| `tests/smoke_stronghold_reload.gd` | **OK** — "stronghold reload smoke test passed" |
| `tests/smoke_gate_e_finale.gd` | **OK** — "gate E finale smoke test passed"; roster decision recorded, region answered |
| `tools/capture_type_tell.gd` | **OK** — nine frames, arrows 1 / −1 / 0 as the chart predicts |

### 8.1 The one red test on this branch is not mine, and whoever lands it should know

`test_hud_widgets.gd :: test_every_installed_species_has_the_hud_portrait_it_resolves`
fails with:

```
nightburrow portrait missing: res://assets/ui/portraits/creatures/nightburrow.png
stormtrail  portrait missing: ...
riftfrill   portrait missing: ...
ashtusk     portrait missing: ...
```

**Inherited from the `origin/ralph/T3-CREATURES` merge**, which added those four
species (`361eb23a`) without portraits; there are 34 portraits on disk and none
for them. Established rather than assumed: my own commits after the merge touch
exactly ten files — `type_chart.json`, four test/tool files, three UI scripts and
two reports — and **nothing under `assets/` or `data/creatures/`**. Portrait art
is not this lane's ownership and I have not touched it. Flagging it because it
will be red on this branch at land time and somebody will otherwise spend the
time I just spent proving whose it is.

### 8.2 Every run finished, and the only red one is the inherited portrait test

**All five combat-bearing smoke tests the brief named are green.** The most
load-bearing is `smoke_gate_e_finale.gd`, which drives real trainer fights frame
by frame through the Warden and out the far side of the chapter ending — every
hit in it goes through the chart, and the authored ladder still resolves:
"the decision resolved: 'Kettle' released, the legendary on a belt of five …
the Meadows acknowledged the victory and the objective chain terminated."

That is the strongest available confirmation of §3.2's "+0 % on 27 of 27 rungs"
— the arithmetic said the authored ladder does not move, and playing it through
to the ending agrees.

Nothing was left in flight.

---

## 9. File footprint

**Modified:**
- `data/config/type_chart.json` — five new rows, two entries on the `water` row, and the comment block carrying the owner's instruction verbatim
- `tests/test_type_chart.gd` — 9 new tests; 1 amended (`test_unknown_and_empty_types_are_neutral`)
- `tests/test_dual_type.gd` — reachability pin rewritten; `test_an_unauthored_second_type_changes_nothing` generalised; `test_no_trainer_roster_creature_is_dual_typed` added
- `scripts/ui/ui_tokens.gd` — five type colours, `TYPE_COLOURS`, `type_colour()`
- `scripts/ui/combat_hud.gd` — `_type_color` reads the shared table
- `scripts/ui/playground_hud.gd` — `_type_colour` reads the shared table
- `tools/capture_type_tell.gd` — four new-type frames

**New:**
- `ralph/reports/MATCHUPS_DESIGN_2026-08-30.md`
- `ralph/reports/handover-T3-MATCHUPS-2026-08-30.md`

**Not touched, by ownership:** `scripts/combat/type_chart.gd` (no code was
needed — the point), `scripts/combat/combat_math.gd`,
`scripts/combat/combat_manager.gd`, `data/creatures/species.json`,
`data/moves/*`, `data/config/bands/**`, `scripts/world/encounter_director.gd`.
