# D20 — The wild table is data

> Extended by D23 (owner spec, 2026-08-11): the spec's §13 supplies a
> wild-species-by-area table, which is the schema extension this decision
> deliberately deferred. `R5.3` in `docs/CURRENT_STATE.md` is where it lands.

**Status:** accepted
**Milestone:** the owner's first-playtest overhaul, 2026-08-09

## The problem

`EncounterDirector.WILD_SPAWNS` was a two-entry const in
`scripts/combat/encounter_director.gd`: one Bramblebun to practise on, one
aggressive Tuskroot to be ambushed by. It was exactly right for M2 — "is a
second fight worth having?" — and exactly wrong for a world that now has a
village, paths, a tutorial route and a first day. Populating a biome by
editing a const in combat code is the kind of data-in-gameplay-code
`CLAUDE.md` tells us to move out the moment it varies by species — and a
spawn table varies by nothing *but* species.

It was also wrong on content: Tuskroot is the **evolved** form (D13), and the
const had it wandering the meadow as an ordinary wild spawn while Mudsnout,
the base form the pack says you actually meet, never spawned at all.

## What was decided

### 1. `data/config/spawns.json` replaces the const

The wild population is a data file: roughly **twelve clusters, twenty-two
creatures** across the authored meadow — around the pond, the practice
meadow, the ridge line, the village outskirts. A cluster is a species, a
position, a count and its behaviour flags; `encounter_director.gd` reads the
file and owns none of the numbers. Cluster placement, counts and densities
are all tunable and labelled as such.

### 2. A `roles` block, so tests never hardcode a species id

The file carries a small `roles` map — currently
`{"practice": "bramblebun", "aggressor": "galecrest"}` — naming which species
fills which structural job in the world. **Tests address species by role,
never by id.** The smoke tests that need "a peaceful creature near the start"
or "something that will charge the player" resolve the role at runtime, so
retuning the wild table is a data edit that breaks no test. The old pattern —
`smoke_opening` passing *despite* an aggressive Tuskroot because someone
checked by hand (`DONE.md`, R0.9) — is what this exists to end.

The aggressor is now **Galecrest**, the roster's serious predator, placed
away from the tutorial path rather than across the opening's walk line.

### 3. Tuskroot is out of the wild — evolution-only

Tuskroot appears in no cluster. The only way to own one is to catch a wild
**Mudsnout** piglet and evolve it — which also makes Tuskroot the first
creature in the game you cannot simply find, a small long-term goal the wild
table creates for free. Mudsnout now actually spawns.

**The evolution system itself remains unbuilt**, deliberately. This decision
changes what the world contains, not what the code can do; the mechanic is
Ralph Phase 4 (`docs/CURRENT_STATE.md`), and until it lands a caught Mudsnout
simply stays a Mudsnout. That gap is acceptable for the slice's current play
gates and is recorded in the backlog rather than rushed here.

### 4. Respawn policy travels into the data

The flat `RESPAWN_DELAY := 6.0` const goes with the table: defeated wild
creatures respawn at their cluster after a per-file delay, tunable in
`spawns.json`. Six seconds was an M2 number ("don't make the owner restart
the game to get a second fight") and is almost certainly too fast for a
populated world — but that is a tuning question the data file now makes
answerable without touching combat code.

## What was rejected

**A full spawn-condition system** (time of day, weather, rarity tiers).
That is R5.5's scope, already on the backlog, and it needs day/night and
weather to exist first. `spawns.json`'s schema should grow those fields when
that task arrives, not speculatively now.

**Keeping one hardcoded spawn as a fallback.** A fallback table in code is a
second source of truth that only shows up when the first one fails, which is
the worst possible time to discover it disagrees.

## Consequences

- Adding, moving or removing wild creatures is a data edit. CI-relevant
  behaviour (what the opening walks past, what tests can rely on) is pinned
  by the `roles` block, not by ids.
- `test_spawns`-style validation gets a real target: every cluster's species
  exists in `species.json`, every role resolves, and **no cluster names an
  evolved form** — that last check is this decision's guard, the same way
  `test_evolution_links.gd` is D17's.
- The evolution mechanic (R4.5) inherits a firm intent: Mudsnout piglets are
  catchable now, so the first evolution the owner ever sees will be a
  creature they already own. The ceremony should be built knowing that.
