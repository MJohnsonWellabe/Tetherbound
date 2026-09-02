# Branching evolution design — Mudsnout → Tuskroot *or* Ashtusk

**Author:** T3-SUNSTONE. **Pushed before implementation**, per this lane's own
standing instructions, the same way `DUALTYPE_DESIGN_2026-08-30.md` was
reviewed before its code landed.

**The owner's instruction, verbatim:** *"Make sure the Riftfrill and Ashtusk
get put in the game. For Ashtusk there should just be some kind of sunstone
you get then you evolve a Mudsnout using the stone to get the Ashtusk."*

This note covers Ashtusk's half only — the data-shape decision for branching
evolution, what it does to D13's "only evolution in the biome" claim, and the
call on the wild Ashtusk individual T3-CREATURES already placed. Riftfrill is
a verification job (§ below, brief Job 3) with no data-shape question in it.

---

## 1. The two shapes on the table, and which one ships

The brief offered two obvious shapes for letting one species evolve into
either of two targets, selected by which catalyst item the player holds:

- **A — item-keyed targets.** `species.json`'s `evolves_into` stops being a
  single string and becomes a map: `{"heartstone": "tuskroot", "sunstone":
  "ashtusk"}`. Cleanest conceptually — the field literally says "these items
  lead to these species."
- **B — a parallel key.** `evolves_into` stays exactly what it is today (a
  single string, the default/primary target), and a new sibling field,
  `evolves_into_variants`, carries the additional item→target branches beside
  it.

**Shipped: B.** Here is why, and it is a narrower, more mechanical reason than
"which reads better":

`tests/test_evolution.gd` is not a data test — it is a system test with nine
passing cases built on hand-authored `cfg` dictionaries (`CFG_NO_ITEM`,
`CFG_WITH_ITEM`) whose entire premise is that
`cfg.evolution.<species>.item_id` is a single string read straight off
`data/config/progression.json`'s shape, paired with `species.json`'s
`evolves_into` naming a single target. Shape A does not touch `item_id`
directly, but it changes what `evolves_into` *means* — from "the target" to
"a lookup keyed by item" — and `evolution.gd::requirements()` is the one place
that reads it to decide what `target` even is. Every one of those nine tests
would need to change **not because the Heartstone→Tuskroot behaviour
changes at all**, but because the code path computing it now runs through a
map instead of a bare string. Rewriting nine green tests to prove unchanged
behaviour is exactly the kind of diff CLAUDE.md's "no half-finished
implementations" and this lane's own "never weaken a test to get green"
instruction should make me suspicious of.

Shape B has a real, measured advantage: it ships with **zero changes to
`data/config/progression.json` and zero changes to any pre-existing test.**
The Heartstone path is bit-for-bit the code path it was before this lane —
same cfg shape, same `item_id` field, same `evolves_into` string, same
`requirements()`/`check()`/`evolve()` call shape for anyone who was already
calling it with no `evolves_into_variants` in play. The branch is purely
additive: a species with no `evolves_into_variants` (every other species in
the game, forever, unless someone deliberately gives it one) sees no
behaviour change whatsoever. I verified this by running the full pre-existing
`test_evolution.gd` suite unmodified against the new code — all nine cases
pass without a single line of them touched.

The honest cost, which the brief itself named: B is "slightly less honest
about what the data now means" — `evolves_into` alone no longer tells the
whole story for a branching species, a reader also has to check
`evolves_into_variants`. I accept that cost. It is a comment-and-discipline
problem, not a correctness one, and I have written the comment.

### The shape, precisely

`data/creatures/species.json`, `mudsnout`:

```json
"evolves_into": "tuskroot",
"evolves_into_variants": { "sunstone": "ashtusk" },
```

`data/config/progression.json`'s `evolution.mudsnout` block is **untouched**:
`{"level": 15, "bond": 55, "item_id": "heartstone"}`, exactly as SD17 shipped
it. Both branches share this one level/bond gate — the owner's instruction
gives no reason to think Ashtusk should be reachable at a different level or
bond than Tuskroot, and inventing a second gate for it would be exactly the
kind of unrequested feature CLAUDE.md warns against. Only the **item held at
the moment of evolving** decides which of the two species comes out.

`scripts/creatures/evolution.gd::requirements()` now merges the primary path
(cfg's `item_id`/`level`/`bond` plus species.json's `evolves_into`) with any
`evolves_into_variants` on the same species, and picks a branch by asking the
inventory which catalyst is actually on hand:

- **Neither stone held:** the primary (Heartstone→Tuskroot) stays the
  reported target — unchanged from before this lane, and the refusal message
  now names both stones ("needs a Heartstone or a Sunstone to evolve") so a
  player who has found neither yet still learns the fork exists the first
  time they check.
- **Exactly one of the two stones held:** that stone's branch is what
  `check()`/`evolve()` use. Holding the Heartstone evolves to Tuskroot exactly
  as before; holding only the Sunstone evolves to Ashtusk.
- **Both stones held at once:** `check()` refuses with a reason naming the
  problem — *"Mudsnout is ready to evolve, but you're carrying more than one
  evolution stone — drop one so the choice is deliberate."* — rather than
  silently picking one. See § 2 for why this, and not a choice-of-two UI
  screen, is what ships.

## 2. Why the ambiguous-both-stones case is a refusal string, not a new UI screen

"The player must be able to understand the choice" is one of this job's hard
requirements, and the case where a player has picked up **both** one-time
stones before evolving any Mudsnout is real — both are ordinary world
pickups, nothing stops a completionist finding both before catching and
levelling a Mudsnout to 15/55.

I considered building a real choice screen: `tab_creatures.gd`'s evolution
ceremony already has a multi-stage, player-paced structure (`glow` → `reveal`
→ `done`), and the release ceremony two screens over
(`_build_farewell_panel()`) already shows the pattern for a real two-button
choice with native Godot focus. It would not be a large feature.

I did not build it, and I want to say so with the specifics rather than
quietly deciding it, per this lane's own standing instruction. Reasons:

- It is **new UI surface for an edge case that mostly does not arise.** The
  ordinary path — find one stone, evolve with it, maybe find the other stone
  later for a *second* Mudsnout — never hits the ambiguous branch at all,
  because CLAUDE.md's five-creature cap means a second Mudsnout is already a
  deliberate, separate catch and a deliberate, separate slot commitment. The
  ambiguous case only fires for a player holding two catalysts against one
  eligible Mudsnout at the same moment, which is a narrower window than it
  first sounds.
- The existing refusal-string mechanism **already is** how this screen
  teaches every other part of the evolution gate — "needs to reach level 15
  first", "needs a stronger bond", "needs a Heartstone or a Sunstone to
  evolve" are all one-line reasons surfaced on the same G-press, with no
  dedicated panel. A fourth reason in the same voice, telling the player
  exactly what to do about it (manage the satchel, which the game already
  supports), is consistent with the screen's own established idiom rather
  than a special case bolted beside it.
- It costs **zero new input actions, zero new Controls, zero new focus
  wiring** — a real concern on a controller-first 7-inch build where every
  screen this project ships has already had at least one blind-judge pass
  specifically about verb legibility (`DETAIL_HINT_BASE`'s own comments are
  full of these). A build-it-now choice screen is the "half-built branching
  system" this lane was warned against, for a scenario that is rare and has
  a legible, in-voice way to resolve it that costs nothing.

If this call turns out to be wrong in play — if players routinely hoard both
stones and the refusal reads as a wall rather than an instruction — the fix is
scoped and already has a template to extend (`_build_farewell_panel()`'s
two-button shape). I would rather hand that back with the evidence than build
it speculatively now.

## 3. What D13 said, and what changes

`docs/decisions/D13-the-meadows-wild-roster-is-recanonised.md` canonises
*"the twelve Meadows wild species and the one evolution"* — Mudsnout →
Tuskroot, and nothing else. That sentence is no longer true after this lane:
Mudsnout now evolves into Tuskroot **or** Ashtusk, depending on the catalyst.
D13 gets a header amendment note (the same convention the file already carries
for D19/D23) pointing at `docs/decisions/D71-*.md`, which is the full record
of this change. D13's body is not rewritten — the file's own convention,
followed by D69's amendment of D19, is to layer a newer decision on top and
say so at the top, not to edit history.

## 4. The wild Ashtusk individual — removed, not kept as a sighting

T3-CREATURES placed one wild, catchable Ashtusk in `band5_stronghold_approach
/spawns.json` (order 5100), because at the time nothing else could source the
creature. That placement is now in direct conflict with an existing, real
test: `tests/test_spawns_data.gd::test_no_evolved_form_spawns_wild` asserts
that **any** species carrying `evolves_from` must not appear in the spawned
wild population, on the existing D20 rule that *"an evolution you can just
walk up to and catch makes evolving pointless."* Ashtusk gaining
`evolves_from: "mudsnout"` (required for the owner's instruction to mean
anything at all) makes that assertion fire on the very cluster T3-CREATURES
authored.

Three options were on the table, per this lane's own brief: remove it, keep
it as an uncatchable sighting, or keep it catchable.

**Keeping it catchable is out** — it means either weakening
`test_no_evolved_form_spawns_wild` (explicitly forbidden: "never weaken a test
to get green") or leaving Ashtusk simultaneously a wild catch and an evolution
target, which is the exact rarity-collapse shape D20 and the brief's own
Spawn Protection Rules exist to prevent: a rare authored individual is not
rare if it is *also* free-standing in a field.

**Keeping it as an uncatchable sighting** was the second option, and I did
not build it, because nothing in this codebase currently draws that
distinction. Every wild spawn in `spawns.json` is, structurally, a catchable
creature — there is no "wild but flagged uncatchable" mechanism anywhere
(trainer-owned creatures are uncatchable, but that is a completely different
code path: they are never `spawns.json` entries at all, they are
`trainers.json` rosters). Building "spawned, visible, fights, but refuses the
catch attempt" as a new creature-state would be a real new mechanic for a
single flavour beat, and it is the kind of unrequested scope this lane's
brief explicitly asked me to flag rather than build.

**Shipped: removed.** The owner's own wording supports this reading directly
— *"there should **just** be some kind of sunstone you get then you evolve a
Mudsnout... to get the Ashtusk"* — "just" reads as the evolution being the
whole acquisition story, not one of two paths. Removing the cluster is also
the smallest diff that satisfies the real test, and it does not leave band 5
without its D70-mandated "final tempting roster opportunity": the Sunstone
pickup goes at the **same site** the wild Ashtusk occupied (§5), so the
location keeps its narrative payload — this ground is where a fire-touched
Tuskroot comes from — and the temptation becomes sharper, not weaker: finding
the Sunstone is the moment a player has to decide whether a *second* Mudsnout,
raised again from scratch, is worth one of their five permanent holders. That
is a real choice with a real cost, where a wild encounter the player may not
even have room to catch was a weaker one.

Band 4's Stormtrail clusters and band 3's Riftfrill still give band 5's
approach its elemental-discovery lineage even without a wild Ashtusk in it;
this lane does not need to invent a replacement encounter there.

## 5. The Sunstone

Mirrors Heartstone's shape exactly, per this lane's brief ("mirror however
the heartstone actually comes from... unless you have a reason not to"):
`kind: "resource"`, `stack: 1`, the same shared honest-stand-in icon
(`assets/ui/icons/items/stone.png`, already carried by `stone`, `rootstone`
and `heartstone`), consumed by `evolution.gd::evolve()` exactly the way
Heartstone is.

**Where it comes from is different, deliberately**, because the two stones
answer different halves of the brief. Heartstone is a dungeon prize, found
past a guardian, in the one required dungeon in the chapter. The Ashtusk
brief restricts its whole family to *"scorched terrain, warm stone, burned
clearings, Team Tether industrial sites"* — open-world geography, not a
dungeon. So the Sunstone is a **physical world pickup** using
`scripts/world/key_pickup.gd`, the exact generic class already used for
`castle_gate_key` — "a one-time physical pickup: an item sitting on the
ground that joins the satchel and never comes back", flagged
(`pickup:sunstone`) so it never respawns. This is the smaller, more honest
mirror of Heartstone's *shape* (a real thing you find once, in a place that
means something) without borrowing Heartstone's *mechanism* (a bespoke
dungeon `prize` block), because there is no dungeon here to hang that
mechanism on.

**Placement:** `scripts/world/playground_world.gd`, roughly `(121, 7336)` —
within the same scorched-industrial pocket by the Sigil gate that held the
now-removed wild Ashtusk cluster (centred `(118, 0, 7340)`, radius 10). Same
ground, already proven walkable by the creature cluster that stood there.
**Told to the coordinator, per this lane's brief:** this is a bare ground
pickup, not a `harvest.json` node and not a `TM_AT`/`objectives.json` entry —
it does not touch anything T3-DENSITY owns, but it sits inside the same
geographic pocket that lane's density audit is currently measuring, so it
should show up in that audit as one new non-harvest prop, not as a harvest
node someone forgot to account for.

## 6. `evolution_authorized` — the aspect-variant test's carve-out

`tests/test_dual_type.gd::test_no_aspect_variant_is_reachable_by_evolving`
pins, for good reason, that a species carrying `variant_of` (an aspect
variant — Nightburrow, Stormtrail, Riftfrill, Ashtusk) must never also carry
`evolves_from`, because a rare authored variant reachable by evolving a
common creature bypasses every rarity gate the brief's Spawn Protection Rules
exist to enforce. Ashtusk becoming an evolution target is a deliberate,
owner-directed exception to exactly that rule, for exactly one species.

Rather than special-case `"ashtusk"` by name inside the test (a silent,
easy-to-miss carve-out the next aspect variant could copy by accident) or
delete the assertion (weakening a real rule), Ashtusk's species entry gains an
explicit, visible flag:

```json
"evolution_authorized": true
```

The test now reads: an aspect variant without this flag is held to the
original rule exactly as before (no `evolves_from`, ever); an aspect variant
**with** the flag is checked instead for actually having an `evolves_from` (a
flag with nothing behind it is dead data and now fails its own test). The
rule survives as a rule — see `docs/decisions/D71` for why this one species is
the exception and why the flag, not the species id, is what the test reads.

## 7. What this does NOT do

- Does not add a choice-of-stone UI screen (§2).
- Does not change Ashtusk's height, typing, moves, stats, or its
  `variant_of`/`variant_kind: "aspect"` classification — it stays exactly the
  aspect variant T3-CREATURES authored. It is now *also* reachable by
  evolution; the two facts are orthogonal and both true, and the data says so
  explicitly (`variant_of: "tuskroot"` for lineage/mesh/typing,
  `evolves_from: "mudsnout"` for acquisition).
- Does not touch `data/config/bands/*/harvest.json`, `TM_AT`, or
  `objectives.json` (T3-DENSITY's ground).
- Does not touch trainer rosters.
- Does not resolve the sheet-vs-brief build-path discrepancy on Ashtusk's own
  reference sheet (`08_Ashtusk_tuskroot_variant.png` says "VARIANT RECOLOR +
  RESIZE + VFX"; the written brief text and T3-CREATURES's own data say
  recolour/VFX only, no resize) — flagged in the handover, not acted on here,
  because it is a visual-treatment call for T1-CREATURE-ART, not an evolution
  or acquisition question, and Ashtusk's current height already clears
  Mudsnout by a wide margin so nothing here depends on resolving it.
