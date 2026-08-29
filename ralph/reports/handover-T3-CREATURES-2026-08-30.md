# Handover — T3-CREATURES

**Branch:** `ralph/T3-CREATURES`, off `claude/tetherbound-coordinator-onboard-7pz3ah`
with **`origin/ralph/T3-TYPECHART` merged forward** (not re-derived — the lane
brief asked for that explicitly and the chart is untouched except where noted
in §6).
**Companion:** `ralph/reports/DUALTYPE_DESIGN_2026-08-30.md`, the dual-type
design note, pushed before implementation as instructed.

Every number here is measured against the tree, not estimated.

---

## 1. What I was asked

Land the owner's creature expansion
(`docs/owner-direction/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md`, nine
creatures, ten reference boards): dual typing first, then the rarity/habitat/
gating system, then the four variants that need no new mesh. Author the five
mesh-blocked creatures' data anyway so that a Meshy key is the only thing
missing. Do not touch trainer rosters. Do not weaken tests. Disagree with
evidence.

---

## 2. The finding that shaped everything else

**The Meadows has no random encounter system, and the brief is written as
though it does.**

`encounter_director.gd::_spawn_creatures()` walks `spawns.json`, and every
cluster **names its own species** and instantiates its `count` members at
seeded scatter positions at world load. They stand there. There is no roll, no
table, no weighted selection, and nothing to weight. Verified by reading the
function end to end.

So the brief's central vocabulary — "2% of ordinary eligible spawn chance",
"1–3% of eligible habitat encounters", "0.25–0.75% of qualifying Burrowback-area
spawn opportunities" — has **no denominator in this build**. Rarity here is
**headcount**: how many individuals exist, where, and behind which gates.

That is not a reason to ignore the owner's numbers. It is a reason to translate
them, and where the translation is exact I said so and used it. **The census
makes two of them exact and two of them undefined:**

| creature | brief's figure | the actual denominator | result |
|---|---|---|---|
| Nightburrow | 0.25–0.75 % of Burrowback opportunities | **123** wild Burrowbacks | 0.5 % of 123 = 0.6 → **1 individual**, which is also exactly what the brief's other sentence asks for ("one active Nightburrow maximum in the Meadows at a time"). The two formulations agree. |
| Stormtrail | 0.5–1 % normally | **116** wild Trailpups | ~1 → **2 individuals**, in different regions 1380 m apart |
| **Riftfrill** | 1 % or less of qualifying Paddlenewt spawns | **6** wild Paddlenewts in the entire chapter | 1 % of 6 = **0.06 — the literal reading ships nothing** |
| **Ashtusk** | 0.5–1 % of qualifying Tuskroot opportunities | **0** — Tuskroot has **no wild spawns anywhere**, it exists only as Mudsnout's evolution and on trainer rosters | **0/0, undefined** |

For the last two I used the brief's **own stated fallbacks** rather than
inventing a reading: *"Potentially higher around specifically authored
mysterious pools"* and *"Could also be handled as one or two semi-authored
roaming individuals instead of ordinary RNG."* One authored individual each.

**This is the single most important thing for the coordinator to carry back to
the owner.** The percentages in the brief are a reasonable specification for a
game with encounter rolls, and this is not that game. Nothing was lost by
translating — but if the owner *wants* percentage-driven rarity, that is a new
encounter system, not a tuning pass, and it should be decided deliberately.

---

## 3. The dual-type rule, and its justification

**Multiply both multipliers.** Full argument in the design note; the short
version is the part that decided it:

`type_chart.gd`'s foundational property is that **an unnamed pairing resolves to
`neutral`** — that is what lets Fire, Electric, Ice, Psychic and Dark ship as
data with no code, and it is why this lane was cheap. **All five dual-typed
creatures pair an authored type (ground/water/air) with an unauthored one.** So:

| rule | Nightburrow (Ground/Dark) hit by a Water move | what it means |
|---|---|---|
| **multiply** | 1.25 × 1.0 = **1.25** | the Dark half is a true no-op |
| best-for-defender | min(1.25, 1.0) = **1.00** | the Dark half **erases** the Ground weakness |
| average | **1.125** | the Dark half halves it |

Under `min` or `average`, a second type is a **free defensive buff whose size
depends on how much of the chart has been authored** rather than on anything in
the fiction — and the day someone writes the Dark rows, five creatures silently
get harder with no edit to any of them. Multiplication is the only rule under
which `neutral` is an identity element.

### Measured: this moves no damage number in the shipped game

Maximum type multiplier the **real** roster can produce, every move in
`moves.json` against every species in `species.json`:

| | before this lane | after |
|---|---|---|
| largest multiplier | 1.25 | **1.25** |
| strongest resistance | 0.80 | **0.80** |

Identical, because no creature pairs two *authored* types. `TYPECHART_DESIGN`
§3.2's compounding result — a 2.0× apex TM plus an advantage never one-shots the
Warden — therefore still holds unmodified. This is pinned by
`test_dual_type.gd::test_the_worst_multiplier_the_real_data_can_produce_is_still_one_advantage`.

### The hazard, and the guard

`1.25 × 1.25 = 1.5625`, and `TYPECHART_DESIGN` §3.2 measured **1.5 as the point
where the Warden fight folds**. Not reachable today; reachable the instant
someone authors a Fire or Dark row (Cindercub is Fire/Ground, so a `water → fire`
of 1.25 would do it alone). Guarded by a data-declared cap `[0.64, 1.5625]` and,
more importantly, by that reachability test, whose failure message points at the
analysis instead of inviting someone to widen the bound.

One small gift, checked rather than assumed: `1.25 * 0.8 == 1.0` is **exactly**
true in IEEE-754, so opposed halves cancel to precisely neutral with no
floating-point residue for `classify()` to forgive.

### Representation

Additive. `species.json` gains an optional `type_secondary`;
`creature_instance` gains `secondary_type` defaulting to `""`. **`creature_type`
keeps its name, type and meaning as the primary type**, so the save format, all
four UI read sites and TM compatibility take no change and all seventeen
pre-existing species are byte-for-byte unchanged.

**Flagged, not buried:** a dual-typed creature learns its **primary** type's TMs
only. Unobservable today (no Fire/Electric/Ice/Psychic/Dark TMs exist), but when
they do, someone must decide whether Nightburrow can learn Dark TMs. That is
`T3-REWARD`'s surface.

---

## 4. What was built, per creature

### Shipped and test-verified — the four aspect variants

All four are species-table rows with a `variant_of` back-link, reusing their
base species' mesh. Two carry `alpha` blocks, per the brief's direction that
Nightburrow and Stormtrail specifically be treated as Alphas — so *aspect* and
*alpha* compose rather than collide.

| creature | typing | base | size | where | gate | count |
|---|---|---|---|---|---|---|
| **Nightburrow** | Ground/**Dark** | Burrowback | 2.10 m (+23.5 %) | band 2, deep warrens rock | **night** | 1 |
| **Stormtrail** | Ground/**Electric** | Trailpup | 1.45 m (+13 %) | band 3 relay + band 4 ridge | **rain** | 2 |
| **Riftfrill** | Water/**Psychic** | Paddlenewt | 1.15 m (unchanged) | band 3 still pool | **night** | 1 |
| **Ashtusk** | Ground/**Fire** | Tuskroot | 2.15 m (unchanged) | band 5 Tether industrial | geography only | 1 |

Only Nightburrow and Stormtrail resize, because only sheets 1 and 2 say RESIZE
in their build path; sheets 7 and 8 say "VARIANT RECOLOR + VFX". Radii scale by
the **same ratio** as height per D12. The `alpha` blocks use `scale: 1.0`
deliberately — size already lives in the species height, and scaling again would
apply the owner's 15–25 % band twice.

### Authored but mesh-blocked — the five

`data/creatures/species_pending.json`, **which nothing loads**. Sparkit,
Cindercub, Shadelet and Frostclaw are complete — typing, statline, moves, catch
rate, behaviour, scale, and a `pending_spawn_plan` carrying habitat, weather,
time, geography and target headcount. **`placeholder.model` is the single open
field.** Bramblebun is the fifth and is not in that file because it already
exists: its redesign is a mesh swap for the same id.

They are not in `species.json` because **`smoke_art.gd` asserts every entry
there names a model that exists on disk** — and `species.json`'s own
`_comment_wild_roster` already states the resulting rule, "Species appear in
this file as each is produced". Putting them in with an empty path breaks a real
test; relaxing that test would remove the only thing standing between this
project and a creature rendering as a fallback capsule in front of the owner.

### Ten moves

Two per new type. A dual-typed creature gets **one move of each of its types**,
pinned by a test — otherwise its second type is pure defence and the player never
sees it exists. Powers sit in the species band (0.95–1.10), not the TM ladder.

**Balance note:** because the chart authors no rows for the new types, every one
of these resolves at exactly 1.0 against every defender. They are strictly *less*
swingy than a ground/water/air move — a wild Stormtrail's Electric attack cannot
roll 1.25 into anything. Identity therefore lives in timing and reach: Electric
has the lowest windup in the file (0.11 s), Psychic the highest and longest reach,
Ice the longest charged lunge, Fire the only `area` quick.

---

## 5. The rarity system — what I reused, and the one thing I built

**Reuse first, per `CLAUDE.md` and `chapter_rewards.json`'s invariants.** Of the
brief's seven Spawn Protection Rules, **six already existed**:

| the brief asks for | status |
|---|---|
| habitat requirements | already: where an entry is authored, plus the `habitat` tag |
| weather requirements | **already exists** — `spawns.json`'s `weather` array, `_gate_active()` |
| time-of-day restrictions | **already exists** — `time: "night"` |
| geographic restrictions | already: the `centre` coordinate and band |
| one major Alpha per local region | structural — author one such entry per region |
| weighted spawn tables | **nothing to weight** (§2): species choice is 100 % authored |
| **cooldowns after rare variant spawns** | **did not exist — built** |

The one addition is a per-entry `respawn_seconds` override in
`encounter_director.gd` (`_wild_respawn`, `_respawn_delay_for()`). Absent on all
881 pre-existing creatures, so the default path is untouched. Without it the
chapter's apex wild encounter comes back on the same 45-second timer as a
Mudsnout, which turns it into a farmable resource a minute after it is beaten.
Nightburrow and Ashtusk get 900 s, the Stormtrails and Riftfrill 600 s.

**I verified the gate system rather than trusting it** — the brief warned that
`habitat` had been documented as reliable and was not. Findings: `habitat` is
indeed presentation-only (`encounter_director` says so itself and ignores it), so
I used it as a tag and carried the real restriction in the coordinate. The
`time`/`weather` gates *are* real and complete: a gated-out creature is set
invisible, and `encounter_director` checks `wild.visible` at all three engagement
sites, so it cannot be fought while gated out.

### The population, measured

| | before | after |
|---|---|---|
| wild creatures | 881 | **886** |
| clusters | 261 | 266 |
| the five new individuals | — | **0.564 %** of the world |
| creatures behind a time/weather gate | 79 | 84 (9.5 %) |

The owner's stated failure mode — *"the player walks through one clearing and
sees Sparkit + Cindercub + Shadelet + Frostclaw + Nightburrow"* — is
structurally impossible for the four shipped variants: they are in four
different bands, the closest pair 1380 m apart, three of the five behind
different gates.

---

## 6. Done-verified / done-unverified / still-open

### Done and verified by test

- dual-type resolution, all three combat call sites — `test_dual_type.gd`, 14 tests / 132 assertions
- the reachability pin (max multiplier still 1.25) — measured over the real roster
- the four variants' data, `variant_of` links, mesh reuse, move typing
- aspect variants unreachable by evolution (pins the rarity argument)
- species types validated against a declared vocabulary — **coverage that did not exist before**
- save round-trip of `secondary_type`
- band content merge, frozen-mirror window untouched (verified: the mirror covers orders 0–12; my new orders are 2100/3100/3101/4100/5100)

### Done, NOT verified in play

- **Nobody has seen any of these four creatures in the running game.** They are
  data-correct and test-green; they have not been walked up to. The night and
  rain gates in particular have only ever been exercised by the existing
  Duskhush and Reedwing entries, not by mine.
- **The per-entry respawn cooldown has not been observed elapsing.** The code
  path is a one-line lookup with a default, and the default path is covered by
  every existing fight test, but no test waits 900 seconds.
- **No visual verification, deliberately.** The four variants currently render as
  their unmodified base meshes — a Nightburrow is a Burrowback at 2.10 m with no
  recolour, no purple emissive and no shadow-flame VFX. That work is
  T1-CREATURE-ART's and the brief assigned it there. **Rendering them now would
  produce frames that judge the missing art, not this lane's work**, which is the
  same argument `T3-TYPECHART` made about its own HUD frames and I think it is
  right. Until that lane lands, the owner's own sheet 1 warning applies verbatim:
  *"Without emissive/VFX treatment, this variant is not successful."*

### Still open, deliberately not mine

- the five meshes (no `MESHY_API_KEY`)
- trainer roster rebalance (`data/config/bands/*/trainers.json`) — pending owner decision
- matchup rows for the five new types — a real design pass, see §3's hazard
- the captain-identity question `T3-TYPECHART` §5 raised

---

## 7. Disagreements and things not visible in the diff

**1. The brief's percentages have no denominator, and two are undefined.** §2.
The most valuable single finding here. Ashtusk's "0.5–1 % of qualifying Tuskroot
opportunities" is 0/0 because **Tuskroot has no wild spawns anywhere in the
chapter** — a fact I did not expect and which also means Ashtusk will be the only
wild Tuskroot-family creature the player can meet.

**2. There is no storm in this game.** `data/config/weather.json` declares
exactly four presets — clear, cloudy, fog, rain — and `world_weather.gd`'s own
header says *"thunderstorms are explicitly out of scope here"*. The brief builds
a whole player lesson on them: *"The player should learn: **storms are worth
exploring**."* I gated Stormtrail and Sparkit on `rain`, the nearest thing that
exists, which delivers the mechanic ("absent in clear weather, present in rain")
but not the spectacle. **When a storm preset exists, changing one array in each
entry is the whole job.** This is an owner-facing gap, not something I should
have invented a thunderstorm to close.

**3. The owner's size guide disagrees with the shipped game about Burrowback,
and it matters for Nightburrow.** The master sheet's size guide is checkable,
because it lists three creatures that already exist: Bramblebun 1.0 m (game
0.96), Paddlenewt 1.1 m (game 1.15), Trailpup 1.2 m (game 1.28) — all within
6 %, which is what let me use the guide directly for the new creatures. But it
puts **Burrowback at 2.6 m against a shipped 1.70 m**, and Tuskroot at 2.6 m
against 2.15 m.

That is not academic. Nightburrow is meant to be *"one of the most visually
dramatic wild creatures"*, at +15–25 % over Burrowback. Off the **live** base
that is 2.04–2.13 m; off the **sheet** base it is 3.0–3.25 m, larger than
Veridian the legendary. I obeyed the owner's **ratio** (2.10 m, +23.5 %), which
lands it joint-largest ordinary wild creature and does read as apex — but if the
owner intends Burrowback itself to be a 2.6 m animal, then the whole large tier
is undersized and that is a separate, deliberate rescale nobody should do
quietly. **Owner question.**

**4. Bramblebun's two owner statements are in tension.** Section 6 says
*"increase its size substantially"*; the same owner's size guide says 1.0 m
against a shipped 0.96 m — a 4 % difference. They reconcile only if "size" there
means visual **mass**, which is what the sheet's own note ("Larger and more
substantial") and its artwork show. So I moved `height` to exactly 1.00 to sit on
the guide and did nothing else; the mass has to come from the replacement mesh.
**Whoever lands that mesh should not also inflate `height` chasing the word
"substantially"** — that would take the creature straight back off the owner's
own guide.

**5. The wild population is 3.7 % Water, and the chart makes Water the answer to
the chapter.** This one is not in the brief at all and I think it is the most
consequential thing I measured. Census of all 886 wild creatures:

| | ground | air | water |
|---|---|---|---|
| count | **532** | 321 | **33** |
| share | **60.0 %** | 36.2 % | **3.7 %** |

`T3-TYPECHART` censused *trainer* rosters and found 57.6 % Ground; the *wild*
population is worse, and its Water share is a rounding error — 4 Mosshell,
6 Paddlenewt, 10 Brooktail, 12 Reedwing, 1 Riftfrill. Under the chart, Water
deals 1.25 into Ground and is the best answer to 60 % of the world — and it is
the hardest type in the game to actually obtain. A player who correctly works
out "I need a Water creature" then has 33 individuals in 886 to find one among.

That is a real design tension between two systems that both landed today. **I did
not act on it**: fixing it means reshaping the wild roster, which is a much
bigger call than "add nine creatures" and is adjacent to the trainer-roster
rebalance the owner already owns. It is the first thing I would put in front of
them after the mesh key.

**6. `test_type_chart.gd` contradicted its own design note.** It required a
matchup ROW for every species and move type, while the design note it shipped
beside states the planned types are "deliberately NOT stubbed" and playable at
1.00 the moment they exist. Both could not be obeyed once creatures carrying
those types landed. I moved both assertions onto a declared **vocabulary**
(`type_chart.json`'s new `types`), which keeps exactly what they protected — a
misspelt or missing type resolving to neutral forever with no error — and
extended it to `type_secondary`, where a typo would be quieter still. **Two
tests were added so nothing is lost on net**: one pins that the chapter's own
three types all still have rows, and one pins that the matchup table can never
name an undeclared type. The original comment's objection is preserved verbatim
in the amended test and answered there.

**7. Two comment-placement bugs, same root cause, worth knowing.** Neither
`creature_species.gd` nor `move_db.gd` filters underscore-prefixed keys, so a
`_comment` inside the `species` or `moves` object is iterated as a real entry. I
hit it twice. Every other comment in both files lives at top level and now I know
why. Anyone documenting those files inline should put the comment beside its
object, not inside it.

**8. `--only=` needs a `--` separator.** `--script tests/run_tests.gd --only=x`
silently runs the entire suite; `--script tests/run_tests.gd -- --only=x`
filters. I lost about twenty minutes to a "targeted" run that was the full suite.
The file documents this correctly at line 7; I did not read it first.

---

## 8. Contract given to the T1-CREATURE-ART lane

Told here because that lane owns the visual treatment and needs a stable target:

- Four species ids exist and are final: **`nightburrow`, `stormtrail`,
  `riftfrill`, `ashtusk`**.
- Each carries `variant_of` naming its base species, and **points at the base's
  existing `.glb`**. A test now fails if a variant acquires a mesh of its own,
  so the art lane cannot accidentally be blamed for a Meshy spend it did not
  make — and cannot accidentally make one.
- Each carries a fallback `colour` taken from its sheet's palette swatch, and
  `placeholder._comment_model` naming the sheet the treatment comes from.
- Nightburrow and Stormtrail are **already resized in data** (2.10 m, 1.45 m).
  The art lane should not scale the model — `creature_body._fit()` sizes it to
  the species height, and the `alpha` blocks are deliberately `scale: 1.0` so
  nothing multiplies twice.
- Both alphas will additionally receive `creature_body.set_alpha()`'s existing
  rim treatment on top of whatever materials the art lane authors.
- Move VFX colours are authored per new type in `moves.json`
  (`dark #9b5fd0`, `electric #f5d24a`, `fire #f07a2b`, `psychic #c39bf0`,
  `ice #a8dcf0`), taken from the same palettes, so creature and attack read as
  one thing.

---

## 9. File footprint

**New:**
- `ralph/reports/DUALTYPE_DESIGN_2026-08-30.md`
- `ralph/reports/handover-T3-CREATURES-2026-08-30.md`
- `data/creatures/species_pending.json`
- `tests/test_dual_type.gd` (+ `.uid`)

**Modified:**
- `data/creatures/species.json` — four aspect variants; Bramblebun height 0.96 → 1.00
- `data/moves/moves.json` — ten moves for the five new types
- `data/config/type_chart.json` — `types` vocabulary, `dual_type` rule block
- `scripts/combat/type_chart.gd` — `multiplier_dual()`, `known_types()`
- `scripts/combat/combat_manager.gd` — three call sites onto the dual lookup
- `scripts/combat/encounter_director.gd` — per-entry respawn cooldown
- `scripts/creatures/creature_instance.gd` — `secondary_type`
- `scripts/save/save_game.gd` — round-trip `secondary_type`
- `data/config/bands/band{2,3,4,5}/spawns.json` — five clusters, +97 lines, **0 deletions**
- `tests/test_type_chart.gd` — two vocabulary tests amended, two added
- `tests/test_moves.gd`, `tests/test_moves_data.gd` — `KNOWN_TYPES` onto one source

**Not touched, by ownership:** `data/config/bands/*/trainers.json`,
`*/harvest.json`, creature materials/VFX/meshes, terrain/grass/scatter/sky,
`scripts/world/stronghold*.gd`, `landmark.gd`, `building_prefabs.json`,
`scripts/ui/**`, `data/creatures/shiny_colourways.json`.

---

## 10. What I would do next, in order

1. **Get the Meshy key in front of the owner.** Five creatures are one field
   short, and Bramblebun — the *common* one, the one that defines how the whole
   biome reads — is among them.
2. **Put §7.5 to the owner: the wild population is 3.7 % Water while the chart
   makes Water the answer to a 60 %-Ground chapter.** Two systems that both
   landed today, pulling against each other.
3. **Ask about Burrowback's scale (§7.3).** It gates whether the chapter's large
   tier is right, and Nightburrow is the first creature to make it visible.
4. **Land T1-CREATURE-ART's treatment, then judge the variants in play.** Until
   then the owner's own warning stands: without the emissive and VFX, Nightburrow
   is a big grey Burrowback.
5. **Decide whether the five new types get matchup rows** — deliberately, with
   `test_dual_type.gd`'s reachability pin and the 1.5625 hazard in hand.
