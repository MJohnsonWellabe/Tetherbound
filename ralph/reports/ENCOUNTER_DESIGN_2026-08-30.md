# Design note — the Meadows encounter system

**Lane:** `ralph/T3-ENCOUNTER`
**Branch base:** `origin/main` @ `477a296a`, with **`origin/ralph/T3-CREATURES` merged forward**
(clean merge, no conflicts — it carries the nine-creature expansion, dual typing, the four
aspect variants and the per-entry respawn cooldown this note extends).
**Pushed before implementation**, per the lane brief.

The owner's instruction, verbatim:

> *"We should build the new encounter system that spawns the creatures randomly, but some of
> the alphas and such will always get placed in the same spots as that's part of the storyline."*

---

## 1. What is actually there, measured

`encounter_director.gd::_spawn_creatures()` walks the merged `spawns.json` array. Every entry
**names its own species** and instantiates its `count` members at seeded scatter positions at
world load. Verified by reading the function end to end; T3-CREATURES §2 found the same thing
and it is still true.

Census of the tree as merged on this branch:

| | |
|---|---|
| clusters | **266** |
| wild creatures | **886** |
| clusters carrying `alpha` | 12 |
| clusters carrying `elder` | 1 |
| clusters carrying a `time` gate | 22 |
| clusters carrying a `weather` gate | 6 |
| clusters carrying `habitat` | 12 |
| clusters carrying `respawn_seconds` | 5 |

So there is **no roll, no table, no weighted selection, and nothing to weight**. The owner's
brief specifies rarity as percentages — *"2% of ordinary eligible spawn chance"*,
*"0.25–0.75% of qualifying Burrowback-area spawn opportunities"* — and those percentages have
had no denominator. T3-CREATURES translated them to headcount, correctly, and flagged that
percentage rarity needs a real encounter system decided deliberately. The owner has decided it.

---

## 2. The shape: two populations, one director

**Authored anchors** and **rolled spawns** coexist in the same table, read by the same
director. No parallel system — `CLAUDE.md` and `chapter_rewards.json`'s invariants both
forbid one, and the existing alpha/elder/shiny/gate/cooldown machinery is all worth keeping.

A spawn entry becomes **rolled** by naming a `table`:

```json
{
  "order": 1042, "species": "trailpup", "count": 3,
  "centre": [ ... ], "radius": 14.0,
  "table": "meadows_open",
  "_why_rolled": "ordinary ambient wildlife on the spine; nothing authored depends on it being trailpup"
}
```

An entry with no `table` is an **anchor** and behaves exactly as it does today. **Anchor is the
default.** That is deliberate and load-bearing: an entry cannot become rolled by accident, only
by an edit that is visible in a diff and carries its own `_why_rolled`.

The entry keeps its `species`. It is no longer only "what stands here" — it is now also this
cluster's **identity fallback**, which §4 makes the whole determinism story turn on, and which
keeps `spawns.json` readable as a description of the world a designer intended.

### What is rolled

Species, per cluster (not per individual — see §7), from a weighted table, filtered by hard
gates, subject to caps. Optionally an alpha promotion.

### What is never rolled

Position, `count`, `order`, level band, IVs, traits, shiny. Those stay exactly where they are,
drawn from exactly the rng they are drawn from today. §4 explains why that is not a
convenience.

---

## 3. The anchor / rolled split, and its justification

Worked out against the tree rather than guessed. An entry stays an **anchor** if any of these
hold; everything else is ordinary ambient wildlife and becomes rolled.

| # | anchor rule | why | count |
|---|---|---|---|
| 1 | `order <= 12` | the frozen-mirror window `tests/fixtures/band_split_baseline/spawns.json` diffs entry-for-entry. Also the tutorial population: the opening walks a brand-new player to order 0. | 13 |
| 2 | carries `alpha` or `elder` | this is authored special-encounter design, and §11's roster-temptation floor is pinned on exactly these blocks | 13 |
| 3 | carries a `time` or `weather` gate | **the gate IS the authored statement.** "Storms are worth exploring" and the nocturnal ecology are the design; rolling a species into a rain-gated slot destroys the thing the slot exists to say | 26 |
| 4 | its species answers a `roles` entry (`practice`, `aggressor`, `nocturnal`, `weather_gated`) | code and five smoke tests address these by role; the role must resolve to something that actually spawns | — |
| 5 | its `order` is named by a test or an objective | the §11/§15 pins — 1005, 1900, 3002, 3004, 5001, 5003, 5004 | 7 |
| 6 | carries `habitat` **and** sits in the Creek Hollow footprint | `test_creek_hollow_is_a_compact_multi_habitat_first_adventure` asserts the exact order list, species list and headcount | 8 |
| 7 | carries `respawn_seconds` | T3-CREATURES' four aspect variants and the Ashtusk — semi-authored rare individuals, which is what the brief itself prefers for that tier | 5 |
| 8 | hand-placed outside the table | the Burrow Warrens Guardian and the vault's Elder Trailpup come through `spawn_wild()`, not `_spawn_creatures()`. **Untouched by this work.** The Elder Trailpup's wander leash fixes a real unreachability bug and is not disturbed. | — |

Rules 1–3 and 5–7 are mechanical and checkable. Rule 4 is mechanical via the `roles` block.

### The interesting case the brief warned about, answered

> *a cluster whose `_why` comment frames it as "the region's team-building temptation" is doing
> authored design work even though it is an ordinary species*

Correct, and it is the reason rule 5 exists. `test_band1_clears_the_roster_temptation_floor`
and its siblings assert **specific orders hold specific species** — 1900 mosshell + `elder`,
1005 meadowhart, 3002 burrowback + `alpha`, 3004 brooktail, 5001 galecrest + `alpha`, 5004
mudsnout, 5003 trailpup. Two of those (1005, 3004, 5003, 5004) carry no mechanical tag at all;
their temptation lives in prose.

**Decision: those entries stay anchored. The pins do not move.** A guarantee that a specific
region holds a specific tempting creature is not a guarantee a weighted table can make — a table
can only promise a distribution, and §11's floor is a floor, not an average. Rolling them and
then rewriting the pins to assert "some temptation exists here" would replace a check that
catches a real regression with one that cannot. The tests are right and the system bends around
them.

That is the general principle for the whole split: **prose framing is authored design.** Where a
`_why` says what a cluster is *for*, it is an anchor.

### Result

Roughly 190 of 266 clusters become rolled; ~76 stay anchored. Exact numbers go in the handover
once the selector has run against the tree. Every rolled entry gets a `_why_rolled`.

---

## 4. Determinism — the hazard nobody would flag

`encounter_director.gd` seeds each cluster from `hash("wild_spawn_%d" % order)` and draws, in a
fixed order, **scatter position → level → 3 IVs → 2 trait rolls → shiny**. Every comment in that
function says why: a smoke test walking to a spot that moves between CI runs is a flake factory.
That determinism is load-bearing across the codebase.

And Gate F is worse than that. `tools/gate_f/segments/*.json` drive a scripted player through the
world and assert on what is there. **Measured:** those segments name `bramblebun` 58 times,
`meadowhart` 42, `pipwing` 33, `mudsnout` 21. A population that differs between runs invalidates
the protocol's entire value. A Track 2 lane is mid-run right now.

### The design

**A world seed, carried by the save. Seed 0 is the authored world.**

```
species(cluster) = cluster.species                      if world_seed == 0
                 = roll(table, gates, caps, rng)        otherwise
```

with the roll rng seeded `hash("wild_species_%d_%d" % [world_seed, order])` — **a separate
generator from the cluster's own.** The existing rng's draw sequence is not touched, not
reordered, and not consumed from. Position, level, IVs, traits and shiny land on the exact
numbers they land on today, at every seed.

Three properties fall out, and all three are why this is the design:

1. **Seed 0 reproduces today's world byte-for-byte.** Every smoke test, every Gate F segment,
   every screenshot, every save: unchanged. Not "should be" — *identical by construction*, because
   at seed 0 the roller is never entered.
2. **Any given save has one fixed world.** A save carries its seed, so reload, re-visit and
   re-run all produce the same population. Gate F gets reproducible evidence at any seed, not
   just at 0.
3. **Different playthroughs differ.** Which is what the owner asked for.

### Default, and the deliberate deferral

**A new game gets seed 0 unless something asks for otherwise.** `data/config/spawn_tables.json`
carries `roll_new_worlds`, and it **ships `false`**.

This is the call I want on the record. Flipping a global determinism switch on the day nine
branches land, with a Gate F run in flight and no time to re-baseline the protocol, is the
version that does not land — and the lane brief is explicit that I should choose the version
that does. Everything is built, wired, tested and playable; one boolean turns the world on, and
that boolean should be flipped in coordination with T2-GATEF, not underneath it.

So it is immediately usable without flipping anything: **`TB_WORLD_SEED` in the environment
overrides the seed** for that process. `TB_WORLD_SEED=7 godot ...` plays a rolled world today.
Gate F operators get the same lever, and Gate F's own runs stay at 0 until its owner says
otherwise.

### What a Gate F operator must do differently

**Right now: nothing.** With `roll_new_worlds: false` and `TB_WORLD_SEED` unset, the world is
identical to the one the current segments were authored against, and every species assertion in
them still holds.

**When the flag is turned on**, and this is the part to carry to T2-GATEF:

- Every run must **pin its seed** — `TB_WORLD_SEED=<n>` — and record it in the run's evidence.
  A run with no recorded seed is no longer reproducible evidence.
- `TB_WORLD_SEED=0` reproduces the world the existing segments assert against, so **the current
  protocol keeps working unchanged at seed 0** and is the right default for regression segments.
- Segments that assert a *specific species at a specific place* are only valid at the seed they
  were authored at. Segments that assert *an encounter happened* are seed-independent and are
  the shape new segments should prefer.
- Nothing under `tools/gate_f/` is touched by this lane. Reported, not taken.

---

## 5. Save and load

`world_seed` becomes save state. `save_game.gd` VERSION 14 → **15**; `_migrate_v14` sets
`world_seed = 0`.

That migration is the strongest argument for the whole design: an existing save comes back into
**the exact world it was saved from**, with no per-creature persistence, no population snapshot,
and no migration guesswork. "Nothing to migrate FROM" resolves to the authored world, which is
the world that save has always had.

The brief's question, answered directly:

> *If a player catches a rolled creature, walks away and returns, what happens? What about a
> reload?*

- **Walk away and return:** unchanged from today. The caught individual leaves the world, the
  spawn point refills after `_respawn_delay_for()` with a fresh individual of that cluster's
  species. Distance streaming (STREAM-D) never rebuilds a body.
- **Reload:** the population is a pure function of `(world_seed, order)`, both of which are in
  the save. The world comes back identical. **A rolled population does not regenerate on load**,
  because there is nothing to regenerate — it is derived, not stored.
- **The failure mode the brief named is structurally absent.** "A population that regenerates on
  every load makes catching meaningless" cannot happen here: load is not a re-roll, it is the
  same pure function returning the same answer.

**What this deliberately does not do:** the population does not change *within* one save over
time. A save's world is that save's world. Weather and time gates still make the visible
population change between visits — a rain cluster appears when it rains — which is the real
per-visit variety the brief's "storms are worth exploring" asks for, and it already works.

An epoch-based re-roll (population re-drawn every in-game week) is the obvious extension and I
am **not** building it: it can make a creature the player is walking toward vanish, it breaks
the "reload gives you your world back" property that makes save/load free, and it is the single
change most likely to invalidate Gate F. Deferred, with reasons, not overlooked.

---

## 6. Spawn protection is part of the roller, not a later pass

The brief's Spawn Protection Rules exist because a rolled population can produce absurdity:

> *"Avoid a situation where the player walks through one clearing and sees Sparkit + Cindercub +
> Shadelet + Frostclaw + Nightburrow. That would destroy the rarity."*

Six of the seven rules already existed as authoring conventions; the roller turns them into
enforced mechanism. `data/config/spawn_tables.json`:

| brief's rule | how the roller enforces it |
|---|---|
| habitat requirements | **hard gate.** A cluster's table is chosen by the ecological role its authored species occupied — water clusters draw from `meadows_water`, rock/burrow from `meadows_rock`, and so on. A pond cluster cannot roll a Burrowback. This is also what keeps the biome reading as the brief's Population Philosophy demands: *"Ground creatures, Water creatures near water, Air creatures overhead."* |
| weather requirements | **hard gate**, per table entry, reusing `_gate_active()` |
| time-of-day restrictions | **hard gate**, same mechanism |
| geographic restrictions | **hard gate** on the cluster's own `centre.z` against a band/z range |
| weighted tables, not uniform | **the roller's core.** Each entry carries a `tier` and a weight; probability is `weight / eligible_total`, so the brief's percentages finally have their denominator |
| one major Alpha per local region | **budget.** The pass walks clusters in `order` sequence, deterministically, tracking an alpha budget per region. Anchored alphas are counted first and spend the budget, so a rolled alpha can never crowd an authored one |
| cooldowns after rare variant spawns | **T3-CREATURES' per-entry `respawn_seconds`, extended** — read what it built and grew it rather than building beside it, per the lane brief |

Plus one the brief implies rather than states: **minimum separation.** A rare-or-above result
suppresses further rare-or-above results within a configured radius. That is the direct,
mechanical answer to "one clearing with five exotics" — the failure the owner named by name.

Target bands, directional per the brief: Common the overwhelming majority; Uncommon 5–10%; Rare
1–3%; Exceptional/Alpha well below 1%, and preferring authored placement, which is exactly what
anchor rule 7 already does for the four shipped aspect variants.

---

## 7. Decisions I am making, and what I am not

**Roll per cluster, not per individual.** A cluster is a group. Rolling per member puts four
different species standing in one ring, which reads as broken ecology, and the brief explicitly
wants Sparkit "solo or pairs. Avoid large packs." Per-member rolling is a later pass if the owner
wants mixed groups; per-cluster is right and cheap.

**`count` is not rolled.** Density is T3-DENSITY's file and its problem. A rolled cluster keeps
its authored headcount.

**The four aspect variants stay anchored.** Nightburrow, Stormtrail, Riftfrill and Ashtusk are
one or two individuals each behind time/weather/geography gates. The brief prefers
*"authored or semi-authored spawn logic over random saturation"* for that tier, and T3-CREATURES
placed them deliberately. The roller does not touch them; it makes the tier *below* them real.

**The pending five are not in the tables.** Sparkit, Cindercub, Shadelet and Frostclaw are
mesh-blocked (`data/creatures/species_pending.json`, which nothing loads) and `smoke_art.gd`
asserts every `species.json` entry names a model that exists. Their tier weights are authored in
the table file's `_pending` block — documentation, not live data — so landing a mesh is a
table edit, not a design pass.

**I am not fixing the Water problem.** T3-CREATURES §7.5 measured the wild population at 3.7%
Water while the type chart makes Water the answer to a 60%-Ground chapter. The roller makes that
a one-line weight change for the first time, which is worth saying — but reshaping the roster is
a much bigger call than this lane owns, adjacent to the trainer rebalance the owner already has
in front of them. **Flagged, not acted on.**

---

## 8. Test posture

Never weaken a test to get green. Specifically:

- `test_band_content.gd`'s frozen mirror: **no non-comment key is added to any entry in the
  mirror window (orders 0–12)**, because all 13 are anchors under rule 1. The mirror and its
  policy do not move. Nothing to relax.
- `test_starter_species_never_spawn_in_the_ordinary_wild_population` currently reads the *table*.
  Once species can be rolled, the table is no longer the whole population, so that test would
  silently stop covering what it claims to. **It gets extended to the roll tables**, which is a
  strengthening. Same for `test_no_evolved_form_spawns_wild` — no `evolves_from` species may
  appear in any table.
- New coverage: table well-formedness, tier vocabulary, weights positive, every table species in
  `species.json`, gates naming real weather presets, the caps and separation rules actually
  binding, seed 0 reproducing the authored species for every rolled entry, and the same seed
  producing the same world twice.

The last one is the load-bearing test: **seed 0 must reproduce the authored world exactly**, and
it is asserted, not assumed.

---

## 9. File footprint

**Own:** `scripts/combat/encounter_director.gd`, band `spawns.json` files, the new
`data/config/spawn_tables.json` and its reader, own tests. Plus, narrowly and by necessity:
`autoload/game_state.gd` (one field), `scripts/save/save_game.gd` (one field + one migration).

**Do not own, do not touch:** `data/creatures/species.json` typing, creature materials/VFX,
`data/config/type_chart.json`, `*/harvest.json`, `TM_AT`, `objectives.json`, `*/trainers.json`,
the Hall, sky, terrain, grass, and **`tools/gate_f/**` — reported, not taken.**
