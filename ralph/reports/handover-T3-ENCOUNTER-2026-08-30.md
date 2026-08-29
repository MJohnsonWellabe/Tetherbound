# Handover — T3-ENCOUNTER

**Branch:** `ralph/T3-ENCOUNTER`, off `origin/main` @ `477a296a`, with
**`origin/ralph/T3-CREATURES` merged forward** — a clean merge, no conflicts. That is the only
tip I merged; it carries the nine-creature expansion, dual typing, the four aspect variants and
the per-entry respawn cooldown this lane extends. (`T3-CREATURES` had itself already merged
`origin/ralph/T3-TYPECHART`, so the type chart comes in through it.)

**Companion:** `ralph/reports/ENCOUNTER_DESIGN_2026-08-30.md`, pushed before implementation as
instructed.

Every number here is measured against the tree, not estimated.
`tools/_probe_rolled_population.gd` is how, and it is committed so the next person can re-run it.

---

## 1. What was asked, and what shipped

The owner:

> *"We should build the new encounter system that spawns the creatures randomly, but some of the
> alphas and such will always get placed in the same spots as that's part of the storyline."*

Shipped: two populations in one director. A `spawns.json` entry that names a **`table`** has its
species rolled from a weighted table; an entry with no `table` is an **anchor** and is untouched.
**Anchor is the default** — a cluster cannot become rolled by accident, only by an edit that
appears in a diff with its own `_why_rolled`.

| | |
|---|---|
| clusters in the chapter | 266 |
| **rolled** | **208** |
| **anchored** | **58** |
| wild population | 886, unchanged at every seed |
| clusters that actually change species on a rolled seed | **129–140** (measured over five seeds) |

---

## 2. The anchor / rolled split, and its reasoning

Worked out against the tree, not guessed. An entry is an **anchor** if any rule fires:

| rule | why it is authored design | entries |
|---|---|---|
| **r1** `order <= 12` | the `tests/fixtures/band_split_baseline/` frozen mirror diffs these entry-for-entry, and they are the tutorial population — the opening walks a brand-new player to order 0 | 13 |
| **r2** carries `alpha` or `elder` | §11's roster-temptation floor is pinned on exactly these blocks | 13 |
| **r3** carries a `time` or `weather` gate | **the gate IS the statement.** "Storms are worth exploring" and the nocturnal ecology are the design; rolling a species into a rain-gated slot destroys what the slot exists to say | 22 |
| **r5** an `order` a test names | the §11/§15 pins — 1005, 1900, 3002, 3004, 5001, 5003, 5004 | 4 (the rest already caught by r1/r2/r3) |
| **r5b** `_why` prose framing a designed encounter | 3003 ("the first water species of the region ... met before the player reaches the narrows"), 3037 (the aggressor guarding the Old Mill Crossing) | 2 |
| **r6** Creek Hollow | `test_creek_hollow_is_a_compact_multi_habitat_first_adventure` asserts the exact order list, species list and headcount | 4 (rest caught by r1) |
| **r7** carries `respawn_seconds` | T3-CREATURES' aspect variants | 0 — all five already caught by r2/r3 |
| **r8** hand-placed outside the table | the Warrens Guardian and the vault's Elder Trailpup come through `spawn_wild()`. **Not touched.** The Elder Trailpup's wander leash fixes a real unreachability bug and was left alone. | — |

### One rule from the design note was dropped, and it matters

The design note listed a rule **r4: "an entry whose species answers a `roles` entry"**, and
predicted ~190 rolled / ~76 anchored. Implementing it showed it was both over-broad and pointing
at the wrong thing: it would have anchored **76 clusters** — every one of 30 Galecrest, 25
Duskhush, 17 Bramblebun and 4 Reedwing — to protect a guarantee that only needs *one* cluster per
role.

And the guarantee it was protecting is not "this species is mostly anchored". It is
"`_role_species()` can still find a live creature of this species at any seed". All four roles
already satisfy that through r1 and r3: `practice`→bramblebun is order 0, `aggressor`→galecrest is
order 12 (both in the frozen-mirror window), `nocturnal`→duskhush and `weather_gated`→reedwing are
gated and therefore anchored.

So the rule was replaced by **a test that asserts the invariant directly** —
`test_every_role_species_keeps_an_anchored_cluster` — rather than by a data rule that
over-anchored 76 clusters to make it true by accident. Final split: **208 rolled / 58 anchored.**

A second test came out of the same reasoning and is not in the design note at all:
`test_the_species_gameplay_systems_require_keep_anchored_clusters`. **A rolled population can
make a species unobtainable, and unobtainable is a different problem from rare.** Meadowhart is
the chapter's only rideable animal and the saddle is a Band 2/3 unlock; Mudsnout is the only
species that evolves (D20). If a roll could take every reachable one, riding and evolution become
dead ends with nothing failing anywhere. Both are derived from `species.json` rather than named,
so a second rideable or a second evolution line is covered the day it lands.

### The case the brief flagged, and the decision

> *a cluster whose `_why` comment frames it as "the region's team-building temptation" is doing
> authored design work even though it is an ordinary species*

Right, and it is why r5 and r5b exist. **The §11 pins stay anchored and the tests do not move.**

`test_band1_clears_the_roster_temptation_floor` and its siblings assert specific orders hold
specific species — four of them (1005, 3004, 5003, 5004) carry no mechanical tag at all; their
temptation lives entirely in prose. A guarantee that a *specific region holds a specific tempting
creature* is not a promise a weighted table can make: a table promises a distribution, and §11's
floor is a floor, not an average. Rewriting those pins to assert "some temptation exists here"
would have replaced a check that catches a real regression with one that cannot. **Not moved, not
weakened, still green.**

The general principle, stated so the next author can apply it: **prose framing is authored
design.** Where a `_why` says what a cluster is *for*, it stays an anchor.

---

## 3. Determinism — what a Gate F operator must do differently

### Right now: **nothing.**

`roll_new_worlds` ships `false` and `TB_WORLD_SEED` is unset, so the world is byte-identical to
the one the current segments were authored against. Measured, not asserted:
`tools/_probe_rolled_population.gd` reports **"0 clusters changed species"** at seed 0, and
`test_the_authored_seed_reproduces_the_authored_world` pins that the roller is not entered at
all. Those segments name `bramblebun` 58 times, `meadowhart` 42, `pipwing` 33 and `mudsnout` 21;
none of them moved.

### The design

Seed 0 is the authored world. Any other seed rolls. The roll is a pure function of
`(world_seed, order)` and draws from **its own generator** — it never consumes from the
per-cluster `hash("wild_spawn_%d" % order)` rng that produces scatter position, level, IVs,
traits and the shiny draw, so all of those land on byte-identical numbers at every seed. That
separation is not tidiness: taking a single value from the existing generator would silently
relevel and reroll all 886 creatures in the chapter.

### When the flag is turned on — carry this to T2-GATEF

- **Every run must pin its seed** (`TB_WORLD_SEED=<n>`) and record it in the evidence. A run
  with no recorded seed is no longer reproducible evidence.
- **`TB_WORLD_SEED=0` reproduces exactly what the current segments assert against**, so the
  existing protocol keeps working unchanged and is the right default for regression segments.
- Segments asserting *a specific species at a specific place* are valid only at the seed they
  were authored at. Segments asserting *an encounter happened* are seed-independent and are the
  shape new segments should prefer.
- **Nothing under `tools/gate_f/` was touched.** Reported, not taken, per the lane brief.

I did not flip the flag, and that is the one deliberate scope call I most want on the record —
see §7.

---

## 4. Save and load

`save_game.gd` **VERSION 14 → 15**, carrying `world_seed`. `_migrate_v14` sets it to 0.

That migration is the strongest argument for the whole design. An existing save comes back into
**the exact world it was saved from**, with no per-creature persistence, no population snapshot
and no migration guesswork — because 0 *is* the world every existing save has always had.

The brief's questions, answered directly:

- **Catch a rolled creature, walk away, return?** Unchanged from today. The caught individual
  leaves the world; the spawn point refills after `_respawn_delay_for()` with a fresh individual
  of that cluster's species. Streaming (STREAM-D) never rebuilds a body.
- **Reload?** The population is a pure function of `(world_seed, order)` and both are in the
  save, so the world comes back identical. **A rolled population does not regenerate on load
  because there is nothing to regenerate** — it is derived, not stored. The failure mode the
  brief named ("a population that regenerates on every load makes catching meaningless") is
  structurally absent: load is not a re-roll, it is the same pure function returning the same
  answer.
- **Does the world change over time within one save?** No, and deliberately. Weather and time
  gates still change the *visible* population between visits — a rain cluster appears when it
  rains — which is the real per-visit variety, and it already worked. See §7 for the epoch
  re-roll I did not build and why.

---

## 5. Spawn protection, as enforced mechanism

| the brief asks for | what it is now |
|---|---|
| habitat requirements | **hard gate.** A rolled cluster's table is chosen by the ecological role its authored species occupied — a pond cluster draws `meadows_water` and cannot roll a Burrowback |
| weather / time-of-day | **hard gate** per table entry, reusing the existing `_gate_active()` path; a rolled cluster that draws a gated species acquires the gate |
| geographic restrictions | **hard gate** — a table entry's `regions` list against the cluster's own chapter region |
| weighted tables, not uniform | **the roller's core.** Measured: an uncommon lands at 7.1% of a table's eligible weight, a rare at 2.0%, an exceptional at 0.6% — all three inside the brief's own 5–10 / 1–3 / "well below 1" bands, pinned by `test_the_tier_weights_land_inside_the_owner_s_own_rarity_bands` |
| one major Alpha per local region | **separation, not a cap** — see below |
| cooldowns after rare variant spawns | **T3-CREATURES' per-entry `respawn_seconds`, extended rather than rebuilt beside**, per the lane brief |
| *(implied)* no clearing full of exotics | **`min_separation_m` = 220.** Measured across five seeds: 0–3 scarce encounters exist in the whole chapter, closest pair 230 m |

### The alpha rule, and why the obvious implementation was wrong

I first implemented "one major Alpha within a local region" as a per-chapter-region cap. Then I
measured the authored world: **its 13 alpha/elder clusters sit as close as 67 m apart.** So the
chapter itself deliberately does not obey that rule at a fine grain, and a cap tight enough to
express it would either have been violated by the authored world or would have refused every
rolled alpha outside Band 1 — which is the half of the owner's sentence this system exists to
deliver.

So the cap is loose (6/region) and **separation does the real work**: a rolled alpha must stand
400 m clear of any other alpha. **Authored alphas seed that list first**, so the story's alpha is
never the one that gets moved. Measured: authored alphas per region are `1 / 4 / 2 / 4 / 2`; a
rolled seed gives `2 / 4–5 / 2–3 / 5–6 / 2`. Random alphas appear, authored ones are untouched.

---

## 6. Measured: what a rolled world actually looks like

`godot --headless --path . --script tools/_probe_rolled_population.gd`

| species | authored | seeds 1 / 7 / 42 / 1337 |
|---|---|---|
| bramblebun | 64 | 119 / 124 / 82 / 73 |
| burrowback | 123 | 88 / 94 / 87 / 75 |
| duskhush | 85 | 125 / 121 / 114 / 104 |
| galecrest | 100 | 57 / 67 / 80 / 70 |
| meadowhart | 60 | 29 / 37 / 37 / 41 |
| mudsnout | 165 | 135 / 111 / 142 / 141 |
| pipwing | 136 | 165 / 179 / 166 / 180 |
| trailpup | 116 | 127 / 106 / 133 / 156 |
| mosshell | 4 | 8 / 14 / 12 / 13 |
| the four aspect variants | 5 | **5, always** (anchored) |
| **total** | **886** | **886, always** |

**The measurement changed the design twice, and both were invisible to every test:**

1. **The aggressor was quietly being halved.** With Galecrest at `uncommon`, the chapter's
   aggressive flier fell from 100 individuals to 27–50 — halving how often the world comes at
   the player, which is GAME_DESIGN.md pillar 3, while `test_something_in_the_meadow_is_dangerous`
   stayed green because it reads the table. Galecrest and Duskhush are `common` now, with their
   scarcity carried by **region gates** rather than by weight.
2. **Duskhush was flooding Band 1.** Ungated it swelled 85 → 130–159 and became the second most
   common creature in the chapter, in a region the authored table puts zero Duskhush in. Gated to
   bands 2–5, which is exactly where OW5D itself moved it ("deeper into Band 2's forest").

The biome still reads the way the brief demands — Ground-dominant, water near water, air
overhead — and that is now pinned by `test_a_rolled_world_is_still_the_ground_dominant_meadows`
rather than left to authoring care.

---

## 7. Done-verified / done-unverified / deliberately deferred

### Verified by test (27 tests in `test_spawn_tables.gd`, plus two added to `test_spawns_data.gd`)

- **seed 0 reproduces the authored world** — the load-bearing one
- same seed → same world twice; different seeds → different worlds; a rolled world actually moves
  ≥25% of its rolled clusters
- the plan only ever touches clusters that opted in; it carries species/gate/alpha and **nothing
  else** — never position, count or order
- no starter, no evolved form, no aspect variant can be rolled
- tier weights inside the owner's own rarity bands
- scarce caps per region; scarce separation; alpha separation; no promotion onto an authored alpha
- region gates bind; every table species, tier, weather preset and region name resolves
- every role species keeps an anchored cluster; the rideable and the evolvable species keep
  anchored **ungated** clusters — a night-gated cluster is not a guarantee
- headcount unchanged at every seed (density is T3-DENSITY's)
- **the world seed's save round-trip, and the VERSION 14 migration landing on 0.** The
  save-format fake had no `world_seed`, so the field this whole design rests on was written and
  read by nobody. The migration test dirties the field before loading, so a no-op migration fails
  instead of passing by accident.

**Verified failable, each failing only its own assertion** — because "it passes" proves nothing:
disabling the seed-0 short-circuit, disabling scarce separation/caps, stopping authored alphas
from spending the alpha budget, disabling alpha separation, inverting the open table's tiers, and
dropping `world_seed` from the save payload. Six deliberate breaks, six correct single failures.

### Verified in the running game

- `smoke_combat`, `smoke_relay`, `smoke_stronghold`, `smoke_stronghold_reload`,
  `smoke_gate_e_finale`, `smoke_aggression`, `smoke_warrens` — the combat-bearing set, which is
  the only thing that reports an authored encounter having stopped happening.
- **`TB_WORLD_SEED=7 tests/smoke_combat.gd` passes** — a fight entered, piloted, won and left in
  a *rolled* world, through the real director path (plan → species → `populate()` → alpha →
  gates). That is the one thing the pure-function tests cannot prove.

### Done, not verified in play

- **No human has walked a rolled world.** `TB_WORLD_SEED=7 tests/smoke_combat.gd` exercises the
  real director path end to end — plan → species → `populate()` → alpha → gates → a real fight —
  which is more than the pure-function tests can prove, but it is a scripted walk, not play.
- **A rolled cluster acquiring a `time`/`weather` gate from its table entry is untested in
  anger.** No live table entry carries a gate today; the four pending five all do. The code path
  is exercised by the plan tests, not by a booted world.
- **`TB_WORLD_SEED`'s override branch cannot be tested from inside the suite** — Godot cannot set
  its own environment. It is exercised by running the suite or a smoke test with the variable
  set, which I did. The no-override branch is pinned.

### Deliberately deferred, with reasons

1. **`roll_new_worlds` ships `false`.** The single biggest call in this lane. Everything is
   built, tested and playable via `TB_WORLD_SEED`; what is not done is turning a global
   determinism switch on the day nine branches land, with a Gate F run in flight and no time to
   re-baseline the protocol. The lane brief said to choose the version that lands. **One boolean,
   flipped with T2-GATEF rather than underneath it.**
2. **No epoch re-roll.** A population that re-draws every in-game week is the obvious extension
   and I did not build it: it can make a creature the player is walking toward vanish, it destroys
   the "reload gives you your world back" property that makes save/load free, and it is the single
   change most likely to invalidate Gate F.
3. **Roll per cluster, not per individual.** A cluster is a group; per-member rolling puts four
   species in one ring and the brief explicitly wants "solo or pairs. Avoid large packs."
4. **The pending five are not in the tables.** They are mesh-blocked and `smoke_art.gd` rightly
   refuses a species whose model is not on disk. Their tier placements and the brief's own
   percentages are recorded in `spawn_tables.json`'s `_pending` block, so landing a mesh is a
   table edit rather than a design pass.
5. **The Water problem is flagged, not fixed** — see §8.

---

## 8. Disagreements, and things not visible in the diff

**1. The brief's percentages now have a denominator, and it is a table's eligible weight.**
T3-CREATURES §2's central finding is closed: "2% of ordinary eligible spawn chance" is now
expressible and checked. But note what the denominator *is* — it is per eligible *cluster*, not
per encounter, because this director populates a world rather than rolling an encounter when the
player walks into grass. The two coincide closely enough that the brief's bands transfer
directly, and I have said so in the config rather than letting it be assumed.

**2. Meadowhart drops from 60 individuals to ~37 in a rolled world.** It is `uncommon` in the
open table because it is the rideable prize and a herd you meet everywhere is not a prize. Riding
is *guaranteed* — its anchored, ungated clusters are pinned by a new test — but the herd reads
thinner. **This is a tuning value, one line, and the owner should look at it once they have
played a rolled world.** I did not paper over it with a per-entry weight override, because adding
a mechanism to dodge a number I was unsure about is how a tier system stops meaning anything.

**3. I did not fix the Water problem, and the system now makes it a one-line change.**
T3-CREATURES §7.5 measured the wild population at 3.7% Water while the type chart makes Water the
best answer to a 60%-Ground chapter — a player who correctly works out "I need a Water creature"
has 33 individuals in 886 to find one among. The tables make that a weight edit for the first
time. **I did not make it**: reshaping the wild roster is a much bigger call than this lane owns
and is adjacent to the trainer rebalance the owner already has in front of them. It is the first
thing I would put to them after Gate F.

**4. Only 3 of 266 clusters are water clusters that roll**, so the water table barely runs. It is
authored and tested and it will matter the moment the owner acts on §8.3 — but nobody should read
"a water table exists" as "the water problem moved". It has not moved at all.

**5. "One major Alpha within a local region" is not a rule the authored chapter obeys** (67 m
between two of its own), and I changed the implementation rather than the chapter. §5 has the
reasoning. If the owner *intends* the alphas to be that close, this is correct; if they do not,
that is a content note about the authored world, not about this system.

**6. There is still no storm in this game.** `weather.json` declares clear/cloudy/fog/rain only,
and the brief builds a whole player lesson on storms. T3-CREATURES flagged this and I am
re-flagging it because the roller makes it *cheaper* to fix, not fixed: `_pending`'s Sparkit and
Frostclaw entries gate on `rain` as the nearest thing that exists. When a storm preset lands,
changing one array per entry is the whole job.

**7. A rolled cluster's `_why` prose now describes a species that may not be standing there.**
Every rolled entry keeps its authored `species` and its original `_why`, and gains a
`_why_rolled` saying so — but at a non-zero seed a comment reading "a common species right beside
the spine's own vertex" may sit above a Duskhush. That is the honest cost of keeping the authored
species as the seed-0 identity, and I think it is worth paying (the alternative is losing the
identity fallback that makes seed 0 exact). Worth knowing before anyone reads a band file as a
description of a rolled world.

**8. `_probe_rolled_population.gd` needed `quit()`.** A `SceneTree` script that does not quit
sits in its main loop with its output still buffered, which is indistinguishable from a hang. It
cost me a timed-out run. Noted because the repo has several probe scripts and the failure mode is
silent.

---

## 9. File footprint

**New:**
- `ralph/reports/ENCOUNTER_DESIGN_2026-08-30.md` (the design note, pushed first)
- `ralph/reports/handover-T3-ENCOUNTER-2026-08-30.md`
- `data/config/spawn_tables.json`
- `scripts/combat/spawn_tables.gd`
- `tests/test_spawn_tables.gd`
- `tools/_probe_rolled_population.gd`

**Modified:**
- `scripts/combat/encounter_director.gd` — the plan is built once and folded into each entry
  (`_spawn_plan`, `_apply_plan`, `world_seed`); everything downstream is unchanged
- `data/config/bands/*/spawns.json` — 208 entries gain `table` + `_why_rolled`, **purely
  additive, verified programmatically: zero semantic changes to any other key**
- `data/config/spawns.json` — one `_comment_rolled` documenting the `table` key
- `autoload/game_state.gd` — `world_seed`, and its reset for a new game
- `scripts/save/save_game.gd` — VERSION 15, round-trip, `_migrate_v14`
- `tests/test_spawns_data.gd` — two tests added (role species and gameplay-critical species keep
  anchored clusters); the starter test gains a pointer to its new table-side half

**Not touched, by ownership:** `tools/gate_f/**`, `data/creatures/species.json` typing, creature
materials/VFX, `data/config/type_chart.json`, `*/harvest.json`, `TM_AT`, `objectives.json`,
`*/trainers.json`, the Hall, sky, terrain, grass, `tests/fixtures/band_split_baseline/**` (the
frozen mirror needed no edit: all 13 mirrored entries are anchors under r1, so no non-comment key
was added to any of them).

---

## 10. What I would do next, in order

1. **Play a rolled world.** `TB_WORLD_SEED=7` and walk Band 1 to the quarry. Everything here is
   measured or tested; none of it is *played*.
2. **Then decide `roll_new_worlds` with T2-GATEF**, and update the Gate F protocol per §3.
3. **Look at Meadowhart** (§8.2) with a rolled world in hand — one line either way.
4. **Put the Water problem to the owner** (§8.3). It is now a weight edit, which it has never
   been before.
5. **When a mesh lands, move its `_pending` entry into its table.** The percentages are already
   satisfied by the tier weights.
