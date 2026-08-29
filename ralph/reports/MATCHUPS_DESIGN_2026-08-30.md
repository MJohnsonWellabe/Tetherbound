# Eight-type matchup chart — design note

**Lane:** `ralph/T3-MATCHUPS` · **Base:** `origin/main` @ `477a296a` with
**`origin/ralph/T3-CREATURES` @ `5bdc2c68` merged forward** (dual typing, the
five new types, the ten new-type moves). Merge was clean; the chart and the
dual-type code are untouched by the merge itself.

**Status:** design, pushed before implementation per the lane brief.

Every number below is measured against the merged tree by a harness that
mirrors `combat_math.gd::base_damage` and `progression.gd::stat_at_level`
against the real `species.json`, `moves.json`, `tms.json`, `combat.json`,
`progression.json` and all five `bands/*/trainers.json`. Nothing here is
estimated.

---

## 0. The owner's instruction, and what it fixes

> *"Do whatever makes sense for the new matchups. Fire beats Ice, Water beats
> Fire, Electric beats Water, Ground resists Electric, Dark or Psychic beat
> Electric. Just make a circle basically of types beating other types and
> resisting some. Every type doesn't have to be equal — for example Dark could
> beat multiple and only be weak to one making it a stronger type."*

Five fixed points, all honoured, none bent:

| # | owner's words | chart entry |
|---|---|---|
| 1 | Fire beats Ice | `fire → ice` = 1.25 |
| 2 | Water beats Fire | `water → fire` = 1.25 |
| 3 | Electric beats Water | `electric → water` = 1.25 |
| 4 | Ground **resists** Electric | `electric → ground` = 0.80 |
| 5 | Dark **or** Psychic beat Electric | `dark → electric` = 1.25 **and** `psychic → electric` = 1.25 |

On #5 I took the "or" as **both**. It is the safe reading — either alone is a
subset of it — and it is what makes Electric a genuine high-risk / high-reward
type rather than a type with one exotic counter nobody owns yet.

On #4 I preserved the distinction the owner drew. **Ground resists Electric
without beating it.** `ground → electric` has no entry and resolves to 1.00.
This is the one place the chart demonstrates that resist and advantage are
separate tools, and it is deliberately the owner's own example rather than
mine. It also happens to be the correct balance call: Ground is 57.6 % of the
chapter's authored opposition, so an offensive edge for Ground is the last
thing this chart should hand out.

---

## 1. Transcription of the owner board's two relevant panels

`docs/reference/owner-board-2026-08-15-systems-and-castle.png`, read directly
rather than quoted from another report.

**TM SYSTEM (ALL TYPES)** — *"TMs are upgrades over base moves. Multiplier:
1.1x – 2.0x (2.0x = very rare)."*

| Ground TMs | Water TMs | Air TMs |
|---|---|---|
| Vine Whip 1.1× | Aqua Jet 1.1× | Zephyr Strike 1.1× |
| Earthen Slam 1.2× | Ice Spore 1.2× | Razor Wind 1.2× |
| Rock Barrage 1.3× | Torrent 1.3× | Sky Cutter 1.3× |
| Spore Burst 1.4× | Bubble Storm 1.4× | Tempest 1.4× |
| Verdant Nova 2.0× | Tidal Nova 2.0× | Hurricane 2.0× |

**FUTURE TYPES (Planned)** — Fire, Ice, Nature, Light, Shadow, Electric.

Two discrepancies worth recording, because they change what "the planned set"
means:

- The board says **Shadow**; the owner's newer creature-expansion brief and his
  matchup instruction both say **Dark**, and `species.json` ships `dark`.
  Under `CLAUDE.md`'s precedence rule (newer owner directive wins) **Dark is the
  name**, and Shadow should be read as its earlier label rather than as a ninth
  type.
- The board does not list **Psychic**; the creature brief introduces it
  (Riftfrill, Water/Psychic) and the matchup instruction names it. It is live.
- **Nature and Light are still planned and unpopulated.** No species, no move,
  no row. They stay exactly where Fire and Dark were yesterday: playable at
  1.00 the moment something claims them. **This chart does not close the
  extension point** — see §6.

The shipped TM ladder (`data/moves/tms.json`) is 14 rungs, not the board's 15,
and its multipliers are the moves' own `power` values: ground 1.0 / 1.1 / 1.15
/ 1.3 / 1.4 / **2.0**, water 1.15 / 1.3 / 1.5 / **2.0**, air 1.2 / 1.4 / 1.6 /
**2.0**. **All three apex 2.0× rungs exist in shipped data**, so the
compounding question in §5 is a live one, not a hypothetical.

---

## 2. The chart

Eight types. Advantage **1.25**, resist **0.80**, everything else 1.00 by
omission.

| attacking move ↓ / defending creature → | ground | water | air | fire | electric | ice | psychic | dark |
|---|---|---|---|---|---|---|---|---|
| **ground**   | — | 0.80 | **1.25** | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| **water**    | **1.25** | — | 0.80 | **1.25** | 1.00 | 0.80 | 1.00 | 1.00 |
| **air**      | 0.80 | **1.25** | — | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| **fire**     | 1.00 | 0.80 | 1.00 | — | 1.00 | **1.25** | 1.00 | **1.25** |
| **electric** | 0.80 | **1.25** | **1.25** | 1.00 | — | 1.00 | 1.00 | 1.00 |
| **ice**      | **1.25** | 1.00 | 1.00 | 0.80 | 1.00 | — | 1.00 | 1.00 |
| **psychic**  | 1.00 | 1.00 | 1.00 | 1.00 | **1.25** | 1.00 | — | 0.80 |
| **dark**     | 1.00 | 1.00 | 1.00 | 1.00 | **1.25** | 1.00 | **1.25** | — |

### 2.1 It really is a circle — two of them, hinged on the owner's own pair

The owner asked for *"a circle basically"*. The chart contains two closed
5-cycles, and they share exactly one edge — `water → fire`, which is one of his
five fixed points:

```
  elemental ring:   water → fire → ice → ground → air → water
  storm/mind ring:  water → fire → dark → ... no:
                    dark → psychic → electric → water → fire → dark
```

Every one of those ten edges is 1.25. The two rings meet at Fire, which is why
Fire ends up one of the two strong types without anyone deciding it should be.

Two chords sit outside the rings and are what produce the asymmetry the owner
asked for:

- `dark → electric` (his fixed pair) — Dark's **second** advantage;
- `electric → air` — Electric's second advantage, paying for its two weaknesses.

### 2.2 Who is strong, who is not — the asymmetry, stated

| type | beats | weak to | resists |
|---|---|---|---|
| **dark** | electric, psychic | fire | psychic |
| **fire** | ice, dark | water | ice |
| **electric** | water, air | dark, psychic | — |
| **water** | ground, fire | air, electric | ground, fire |
| **ground** | air | water, ice | air, electric |
| **air** | water | ground, electric | water |
| **ice** | ground | fire | water |
| **psychic** | electric | dark | — |

**Dark beats two and is weak to one, and additionally resists the type it
beats.** That is the owner's own worked example, implemented literally. Fire
lands in the same place, arrived at independently — it is the hinge of both
rings.

Every type has **at least one advantage and at least one weakness**. No type is
a dead end and none is invulnerable. That is the one structural property I did
not let the asymmetry eat, and it is the same property `TYPECHART_DESIGN`
§2 argued the full triangle for.

### 2.3 Why each new row is what it is

- **`fire → ice`, `water → fire`, `electric → water`, `electric → ground`
  (resist), `dark → electric`, `psychic → electric`** — owner-fixed. No
  argument needed and none offered.
- **`fire → dark` 1.25** — Dark needs exactly one weakness (the owner's
  example) and Fire is the only currently-live type that reads as
  *illuminating*. Light is the obvious long-term answer and is still planned;
  when it ships it can join Fire here without disturbing anything, because
  adding a row is a data edit.
- **`dark → psychic` 1.25 and `psychic → dark` 0.80** — genre-canonical, and it
  closes the storm/mind ring. It also gives Dark the resist that makes it the
  "stronger type" rather than merely a type with two arrows.
- **`electric → air` 1.25** — lightning into a flier. Strong literacy, and it
  is what pays for Electric carrying two weaknesses. Measured cost to the Air
  starter across the authored ladder: **zero** — no trainer creature in the
  chapter can throw an Electric move (§4.1).
- **`ice → ground` 1.25** — the ecological statement the creature brief asks
  for: the cold region is what the Ground biome has to fear, and a rare
  Frostclaw *should* feel consequential. **This is the highest-leverage number
  in the chart and I am flagging it rather than burying it** — see §7.1.
- **`fire → water` 0.80, `ice → fire` 0.80** — reciprocals of the two
  owner-fixed advantages, in the shipped chart's own reciprocal style.
- **`water → ice` 0.80** — non-reciprocal, giving Ice a defensive identity so
  it is not purely an offensive type, and stopping Water (already the strongest
  starter at 1.143) from being the answer to everything. Zero effect today: no
  Ice species is obtainable.

### 2.4 What I did NOT do: the three shipped types are untouched

The brief warned that extending a circle to eight types must not silently
rewrite the three already tuned and shipped. It does not, and this is a
checkable property rather than a claim:

> **All nine cells of the `{ground, water, air} × {ground, water, air}` block
> are byte-identical to the shipped chart.** Every value the T3-TYPECHART lane
> measured, argued and tuned survives unchanged.

The `water` row gains two entries — `fire` (owner-fixed) and `ice` — but both
name *new* types. The `ground` and `air` rows gain nothing at all. Ground's and
Air's new defensive exposure lives entirely in the new types' own rows
(`electric → ground` 0.80, `ice → ground` 1.25, `electric → air` 1.25), which
is where a new type's opinions belong.

**This is pinned by a test**, not left as prose.

---

## 3. Magnitudes: 1.25 / 0.80 everywhere, and why not per-type

The brief invited the new types to carry their own magnitudes. **They should
not**, for a reason that is about the anchor rather than about taste.

`TYPECHART_DESIGN` §3.1 priced 1.25 against the owner board's TM ladder — *"a
type advantage is worth about one TM rung"*. That anchor is **type-agnostic by
the board's own heading: "TM SYSTEM (ALL TYPES)"**, and the shipped ladder
confirms it — ground, water and air all run the same 1.1×–2.0× shape and all
three top out at exactly 2.0×. A per-type chart magnitude would therefore have
nothing to be calibrated *against*: "Dark advantage is 1.4 but Water advantage
is 1.25" would be a number with no referent, and it would make the one sentence
a designer can hold in their head — *matching type is worth about one TM rung* —
false for five of eight types.

There is a second reason, and it is the one that decides it. **The owner asked
for asymmetry between types, and asymmetry is already fully expressible in the
graph.** Dark is stronger than Psychic because it has two advantages, one
weakness and a resist, not because its arrows are bigger. Buying strength with
magnitude instead of with topology would make the chart unlearnable — a player
can count arrows from play; they cannot feel the difference between a 1.25 and
a 1.35 across the variance in `combat.json` (`damage.variance` is 0.1, i.e.
±10 % on every hit, which swallows a 1.25→1.35 change whole).

So: **one advantage magnitude, one resist magnitude, asymmetry entirely in the
shape.** 0.80 stays the exact reciprocal of 1.25, which §5.3 shows is worth
more than it looks.

---

## 4. What this chart does to the authored game — measured

### 4.1 The censuses that decide everything

Measured over all five `bands/*/trainers.json`:

| | value |
|---|---|
| authored trainer rungs | **27** |
| trainer creature-instances | **66** |
| distinct species used | 14 |
| **dual-typed creatures on any trainer roster** | **NONE** |
| **move types any trainer creature can throw** | **ground, water, air — only** |

Both of those last two lines are load-bearing and neither was previously
recorded. Every one of the 66 is mono-typed, and every move any of them owns is
one of the three shipped types. The four dual-typed species live only in
`bands/*/spawns.json` — i.e. **the wild**.

### 4.2 The headline: the authored ladder does not move at all

Per-rung cost for each starter, shipped chart vs. this chart, across all 27
rungs (same pessimistic quick-only, solo, no-dodge model
`TYPECHART_DESIGN` §4.3 used, so the numbers are comparable):

> **+0 % on 27 of 27 rungs, for all three starters.**

And the per-starter exchange ratio over the whole ladder is unchanged to three
decimals:

| starter | shipped | this chart |
|---|---|---|
| Terrapup (Ground) | 1.055 | **1.055** |
| Ripplet (Water) | 1.143 | **1.143** |
| Galewisp (Air) | 0.829 | **0.829** |

This is not luck and it is not a weak chart — it follows necessarily from
§4.1. A mono-typed starter meeting mono-typed ground/water/air opposition
throwing ground/water/air moves never touches a new row. **The chart adds five
types to the game without re-tuning a single authored trainer fight**, which is
the best possible answer to the brief's worry about a fight becoming trivial or
unwinnable before anyone plays it.

### 4.3 The Warden fight is bit-for-bit identical

Every multiplier and every hits-to-kill against `warden_aldis`'s authored five,
with the apex 2.0× Water TM in hand:

| Warden's creature | water | ground | air |
|---|---|---|---|
| Burrowback L16 (209 hp) | 1.2500 → **1.2500** (3 charged) | 1.0000 → **1.0000** (3) | 0.8000 → **0.8000** (4) |
| Brooktail L17 (180 hp) | 1.0000 → **1.0000** (2) | 0.8000 → **0.8000** (3) | 1.2500 → **1.2500** (2) |
| Galecrest L17 (206 hp) | 0.8000 → **0.8000** (3) | 1.2500 → **1.2500** (2) | 1.0000 → **1.0000** (3) |
| Meadowhart L18 (232 hp) | 1.2500 → **1.2500** (3) | 1.0000 → **1.0000** (3) | 0.8000 → **0.8000** (4) |
| Tuskroot L20 (278 hp) | 1.2500 → **1.2500** (3) | 1.0000 → **1.0000** (4) | 0.8000 → **0.8000** (5) |

**Not one number moves.** All five of the Warden's creatures are mono-typed, so
no double multiplier is reachable in the chapter's final exam.

### 4.4 The one thing that does change: piloting a dual-typed creature

A player who catches one of the four live dual-typed wild creatures brings two
rows into a trainer fight. This is the entire player-facing delta:

| creature | rungs that move | what moves, and why |
|---|---|---|
| **Nightburrow** (Ground/Dark) | **0 of 27** | Nothing beats or resists both halves; its Dark charged move meets no authored row |
| **Riftfrill** (Water/Psychic) | **0 of 27** | Same |
| **Stormtrail** (Ground/Electric) | 27 of 27, **−20 % to +25 %, roughly a wash** | Its *quick* is Electric (`spark_bite`), so the owner's `electric → ground` resist costs it into Ground rungs and `electric → air`/`→ water` pays it back on the others |
| **Ashtusk** (Ground/Fire) | **8 of 27, +8 % to +44 %** | The one real cost. Takes **1.5625** from Water moves — the game's first double weakness. Exactly the 8 rungs that field a Water creature |

On **Stormtrail**, the quick-only model overstates the swing badly:
`player_charged.power` is 38 against `player_quick.power` 9, so the charged
attack is the kill vector, and Stormtrail's charged (`trailblaze_pounce`) is
**Ground**, which no new row touches. Its real cost is to the energy economy,
not the damage curve. I would not act on those percentages.

On **Ashtusk**, the cost is real and I am not softening it — see §5.

---

## 5. The compounding analysis, re-run at these magnitudes

### 5.1 The worst-case reachable multiplier

Every species in `species.json` against every move type in `moves.json`:

| | shipped chart | **this chart** |
|---|---|---|
| **max reachable** | 1.2500 | **1.5625** |
| reached by | 21 ordinary pairings | **exactly one: a Water move into Ashtusk (Ground/Fire)** |
| **min reachable** | 0.8000 | **0.8000 (unchanged)** |
| double resist (0.64) | unreachable | **still unreachable** |

**This is the pin change, and it is deliberate.** `test_dual_type.gd` currently
asserts the maximum the real data can produce is 1.25, with a failure message
that says *"the day this fails, someone has authored the game's first true
double weakness."* That day is today, and the reason is an owner fixed point:
**Water beats Ground** (shipped, tuned, untouchable) **and Water beats Fire**
(the owner's own second pair). Ashtusk is Ground/Fire. There is no way to
honour pair #2 and leave Ashtusk at 1.25 short of gutting dual typing.

I am changing that pin to assert **1.5625, reachable by exactly one pairing,
against a creature on no trainer roster** — a stronger assertion than the one it
replaces, because it names the pairing rather than only the number. The old
pin is not weakened, it is superseded and its reasoning is recorded here.
Cindercub (Fire/Ground, in `species_pending.json`) will join Ashtusk there the
day its mesh lands; the test will say so.

### 5.2 The inherited "1.5 folds the Warden" threshold does not apply here

`DUALTYPE_DESIGN` §3.3 flagged 1.5625 as past the 1.5 that `TYPECHART_DESIGN`
§3.2 measured as the point where the Warden fight folds. **That threshold was
measured on the Warden's own five creatures, and none of them is dual-typed
(§4.3).** 1.5625 is unreachable in that fight in either direction. The hazard
the two previous lanes correctly flagged turns out to be aimed somewhere else,
and saying so is more useful than inheriting the alarm.

Where 1.5625 actually lands:

- **player → wild Ashtusk** (one hand-placed individual, band 5, an owner-
  designated "serious fight"). With the apex 2.0× Water TM the compounded
  multiplier is **1.5625 × 2.0 = 3.125**, against a shipped ceiling of 2.5.
  Measured hits-to-kill: **3 charged hits either way** — Ashtusk L16 has 289 hp
  and the 25 % does not cross a hit boundary. So the ceiling rises 25 % and the
  fight length does not change at all.
- **enemy → player's Ashtusk**, on the 8 rungs that field a Water creature.
  §4.4's +8 % to +44 %.

**3.125 is the number to quote as the worst case this chart makes reachable.**
It is reachable by one move type, against one species, with the rarest TM in
the game, in an optional wild encounter.

### 5.3 The reciprocal still cancels exactly

Verified rather than assumed, in IEEE-754 double:

- `1.25 * 0.8 == 1.0` — **exactly true**. So Ice into Ashtusk is
  `1.25 (→ground) × 0.80 (→fire) = precisely 1.0`, with no residue for
  `classify()`'s `is_equal_approx` to forgive. The chart now has three such
  opposed pairings and all three land on exact neutral.
- `1.25 * 1.25 == 1.5625` — exactly true, so the `dual_type.max` bound is
  exactly non-binding rather than nearly so.
- `0.8 * 0.8 == 0.6400000000000001`, **not** 0.64. Harmless — `min` is a floor
  and `maxf(0.64000…1, 0.64)` returns the larger — but the config's `0.64` is
  therefore very slightly below the true double resist, and anyone who later
  turns that floor into an equality check should know it.

### 5.4 What I decided NOT to do about 1.5625

I considered lowering `dual_type.max` to 1.5 to keep the inherited threshold
satisfied. **Rejected.** It would make the cap bind on the single most ordinary
dual-type case in the game, which is precisely what `DUALTYPE_DESIGN` §3.3
designed the bounds *not* to do; it would buy a 4 % reduction in a number that
§5.2 shows never reaches the fight the threshold was measured for; and it would
hide a real design consequence behind a clamp instead of reporting it. The
bounds stay at the natural `[0.64, 1.5625]`.

---

## 6. The extension point is still open

Unnamed pairings still resolve to `neutral`. Nothing in
`scripts/combat/type_chart.gd` enumerates any type — this lane adds **no code**,
only rows, exactly as the file's own header predicted. **Nature and Light can
be added by a future author as a data edit**, and until someone does they are
playable at 1.00 the moment a species or move claims them. `type_chart.json`'s
`types` vocabulary list gains nothing either: it is a spelling checker for
types that *exist*, and Nature and Light do not yet.

This property is what let Fire, Electric, Ice, Psychic and Dark ship inert
yesterday and be turned on today without touching a line of GDScript. It is
worth more than any row in the table and I have not spent it.

---

## 7. Disagreements, flags, and what I am handing to other lanes

### 7.1 `ice → ground` is the highest-leverage number here, and the roster lane must agree with it

Ground is **57.6 %** of authored trainer creatures. An advantage into Ground is
an advantage into most of the chapter. Today `ice → ground` costs and gains
**nothing**: no obtainable creature is Ice (Frostclaw is mesh-blocked in
`species_pending.json`), no trainer throws an Ice move, and the measured
per-rung delta is 0 %.

The day Frostclaw ships as catchable — or an Ice TM exists — **Ice becomes the
chapter's best offensive type**, joining Water as a second answer to a Ground
monoculture. I took the edge anyway, for two reasons the brief supports: the
owner's brief asks ecology to do the storytelling and "the cold region is what
the Ground biome fears" is the story; and the brief told me not to balance
around today's skew as permanent, because the diversification pass is already
under way. **If Ground stays near 57.6 %, this row should be revisited** — and
the two passes must agree, which is why it is in writing.

The lower-leverage alternative I rejected was `ice → air` (27.3 %), which would
have given Air a third weakness. Air is already the deficit starter at 0.829
and I would not pile onto it.

### 7.2 I did not take a Ground offensive edge, and that was the right call

The obvious genre move is Ground beating Electric. The owner explicitly said
**resists**, and honouring the word is also the correct balance: at 57.6 %,
handing Ground an offensive edge would be the single most inflationary thing
this chart could do. **The owner's phrasing and the measurement agree**, which
is rare enough to record.

### 7.3 Ashtusk is now measurably worse to pilot than a plain Tuskroot

Its 1.5625 to Water is unavoidable (§5.1). But I want the content lane to know
the shape of it: a rare, owner-designated "mini-Alpha tier" prestige variant
that is *strictly worse to own* than the common species it is a variant of
would be a trap. Currently it is worse on 8 rungs and better on none, because
its Fire quick meets no advantage anywhere in the authored ladder.

**I caught myself making this worse and backed it out.** An earlier draft of
this chart had `fire → ground` 0.80 ("earth does not burn"), my invention, not
the owner's. Measured, it taxed Ashtusk on **26 of 27 rungs** instead of 8,
because Ashtusk's quick move is Fire (`ember_bite`) and 57.6 % of the ladder is
Ground. It was also weak genre literacy — Fire vs Ground is neutral in the
convention every player arrives with. Dropped. This is the one place the
measurement changed the design rather than confirming it.

The remaining fix is not mine: it is either a Fire TM, or Ashtusk's spawn level
carrying the compensation, or accepting that its value is the encounter rather
than the catch. `T3-REWARD` owns the first.

### 7.4 The board's Shadow / Dark discrepancy

§1. Recording it because a future author reading the board alone would author
`shadow` rows against a `dark` roster and get a chart that silently does
nothing — which is exactly the failure mode `neutral`-by-omission makes
invisible. The `types` vocabulary list in `type_chart.json` is the guard, and
`test_dual_type.gd` already holds every species to it.

---

## 8. Summary of decisions

| # | decision | why |
|---|---|---|
| 1 | All five owner-fixed pairs implemented literally; "Dark **or** Psychic" taken as **both** | Safe reading; makes Electric high-risk/high-reward |
| 2 | Ground **resists** Electric without beating it | The owner's word, and the correct call at 57.6 % Ground |
| 3 | Two 5-cycles hinged on `water → fire`, plus two chords | "A circle basically", with the asymmetry in the chords |
| 4 | **1.25 / 0.80 uniformly**, no per-type magnitudes | The TM ladder is the anchor and it is type-agnostic; ±10 % damage variance swallows finer distinctions; asymmetry belongs in topology |
| 5 | Dark: 2 advantages, 1 weakness, 1 resist | The owner's own worked example, implemented literally |
| 6 | The `{ground,water,air}²` 3×3 block is byte-identical | The shipped chart was tuned; extension must not be a rewrite. Pinned by test |
| 7 | Max reachable rises **1.25 → 1.5625**; pin changed deliberately | Forced by owner pair #2 meeting the shipped `water → ground`. Reachable by one pairing, on no trainer roster |
| 8 | `dual_type` bounds stay `[0.64, 1.5625]` | Clamping to 1.5 would bind on the most ordinary dual case and hide a real consequence |
| 9 | **No code changes** | The chart is data by design; this lane proves it |
| 10 | Nature and Light left unauthored | The extension point is the most valuable thing here and is not spent |
