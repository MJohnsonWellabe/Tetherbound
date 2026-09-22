# D71 — Mudsnout branches: Tuskroot with a Heartstone, Ashtusk with a Sunstone

**Decided:** 2026-08-30, by the owner, in session.
**Status:** Settled. Amends D13's "the twelve Meadows wild species and the
one evolution." D17 and D20 are unchanged in principle and re-verified against
the new branch, below.

## The instruction

> *"Make sure the Riftfrill and Ashtusk get put in the game. For Ashtusk there
> should just be some kind of sunstone you get then you evolve a Mudsnout
> using the stone to get the Ashtusk."*

Riftfrill needed no design decision — it is verified in place (§5). This
record is Ashtusk's half.

## What D13 said, and what changes

D13 canonised *"the twelve Meadows wild species and the one evolution"* —
Mudsnout → Tuskroot, and nothing else. That is no longer literally true:
Mudsnout now evolves into Tuskroot **or** Ashtusk, selected by which of two
catalyst stones the player spends. D13's body is not rewritten; it carries a
header note pointing here, the same convention it already used for D19 and
D23, and the same one D69 used to amend D19's scale band without touching
D19's own text.

The biome still has exactly **one evolving species**. D13's real substance —
this is a small, mostly-single-line roster, evolution is rare rather than
routine, and the whole system exists to reward one specific creature line —
is untouched. What changes is that the line forks at its last step.

## Why T3-CREATURES's own call is being reversed

T3-CREATURES, landing Ashtusk as one of the expansion's four buildable aspect
variants, deliberately withheld `evolves_from` from it:

> *"Carries NO `evolves_from` on purpose: an Ashtusk is FOUND as an Ashtusk.
> Wiring it into the Mudsnout line would make a rare authored variant
> reachable by levelling the commonest creature in the chapter, which is the
> exact rarity collapse the brief's Spawn Protection Rules section exists to
> prevent."*

That reasoning was sound against the brief as written. It is being reversed
here because the owner has since given more specific direction than the
brief's own text carried, and it resolves a real problem T3-CREATURES also
found and flagged as unresolved: Ashtusk's brief-specified rarity language
(*"0.5–1% of qualifying Tuskroot opportunities"*) is undefined in this game,
because Tuskroot has zero wild spawns anywhere — the denominator is 0, and
the percentage is 0/0. T3-CREATURES's own fallback (one authored wild
individual, per the brief's stated escape hatch) was a reasonable reading of
an ambiguous brief. The owner's later, plainer instruction is not ambiguous,
and implementing a clear owner instruction is ordinary work, not invention
(`CLAUDE.md`, "Ask instead of inventing").

The reversal is not a silent reopening of the rarity rule T3-CREATURES was
protecting. `species.json`'s `ashtusk` entry now carries
`"evolution_authorized": true` beside its new `evolves_from` — an explicit,
visible flag, checked by `tests/test_dual_type.gd`'s aspect-variant test,
which still forbids any OTHER aspect variant (Nightburrow, Stormtrail,
Riftfrill) from being reachable by evolution. One species is exempted,
deliberately and legibly, not the rule.

## The wild Ashtusk individual: removed

T3-CREATURES placed one wild, catchable, alpha-tier Ashtusk in
`band5_stronghold_approach/spawns.json` (order 5100), at the time the only
way to put the creature in the game at all. That placement is now removed.

Three options were considered — remove it, keep it as an uncatchable
sighting, or keep it catchable:

- **Catchable** is foreclosed by an existing test,
  `tests/test_spawns_data.gd::test_no_evolved_form_spawns_wild`, which already
  forbids any species carrying `evolves_from` from appearing in the spawned
  wild population (D20: *"an evolution you can just walk up to and catch
  makes evolving pointless"*). Ashtusk gaining `evolves_from` — required for
  the owner's instruction to mean anything — makes that assertion fire on
  exactly this cluster. Weakening that test to keep the cluster was not
  considered: this lane's own standing instructions forbid it, and the rule
  it protects (an evolution you can just catch makes evolving pointless) is
  sound and older than this task.
- **An uncatchable sighting** was rejected because nothing in this codebase
  distinguishes "wild, visible, fightable, but refuses to be caught" from an
  ordinary wild creature — every `spawns.json` entry is structurally
  catchable. Building that distinction for one flavour beat is real new
  scope this task's own brief asked me to flag rather than build.
- **Removed** is what shipped. The owner's own wording — *"there should
  **just** be some kind of sunstone... to get the Ashtusk"* — reads as the
  evolution being the whole acquisition story, and removal is the smallest
  change that satisfies the real, pre-existing test.

Band 5 does not lose its D70-mandated "final tempting roster opportunity" by
this removal — that requirement was already pinned to a *different* entry,
order 5004, a solitary special-encounter Mudsnout sited off-spine at the same
detour as the chapter's apex Air TM
(`tests/test_spawns_data.gd::test_band5_clears_the_roster_temptation_floor_and_its_own_final_opportunity`).
The Sunstone (below) sits roughly 45m from that same Mudsnout, in the same
general off-spine pocket — a fortunate proximity this task did not have to
engineer, since the Sunstone's own habitat requirement (scorched, industrial
ground) placed it there independently. A player who finds the "worth
catching" Mudsnout and, nearby, a strange hot stone, has both halves of the
choice in the same short detour, without either object needing to explain
itself.

## The branching data shape

Full design and rejected alternative in
`ralph/reports/SUNSTONE_DESIGN_2026-08-30.md`, pushed before implementation.
Summary: `species.json`'s `mudsnout` keeps its original single-string
`evolves_into: "tuskroot"` untouched, and gains a new sibling field,
`evolves_into_variants: {"sunstone": "ashtusk"}`. `scripts/creatures/
evolution.gd` merges the two, and picks a branch by which catalyst the
player's inventory actually holds — neither held keeps Tuskroot as the
default target (so a Mudsnout with no stone in reach behaves exactly as it
did before this decision); both held refuses with a reason naming the
ambiguity, rather than silently choosing one.

The alternative — turning `evolves_into` itself into an item-keyed map — was
rejected because it would have required rewriting `tests/test_evolution.gd`'s
nine pre-existing, passing cases to prove behaviour that does not change at
all for the shipped Heartstone→Tuskroot path. The shipped shape needed zero
changes to `data/config/progression.json` and zero changes to any
pre-existing test.

`data/config/progression.json`'s `evolution.mudsnout` block
(`level: 15, bond: 55, item_id: "heartstone"`) is untouched. Both branches
share this one gate; the owner's instruction gives no reason to think Ashtusk
should need a different level or bond than Tuskroot, and inventing a second
gate would be unrequested scope.

## D17 re-verified against the new branch

D17 — *"whatever creature is an evolution of another needs to be larger in
size"* — binds every branch now, not just the primary one.
`tests/test_evolution_links.gd` gained a mirror set of assertions for
`evolves_into_variants` (target existence, the strictly-larger height rule,
the reverse link agreeing) rather than only covering the field that existed
first. Mudsnout (0.95m) → Ashtusk (2.15m) clears the rule by 1.20m, with more
room than the Mudsnout → Tuskroot line already had.

Ashtusk's own reference sheet
(`docs/art/reference/creature-expansion-2026-08-30/08_Ashtusk_tuskroot_variant.png`)
states its build path as **"VARIANT RECOLOR + RESIZE + VFX"** — a discrepancy
against both the written brief text (which specifies no resize) and
T3-CREATURES's own reading of the sheet (which built it at Tuskroot's
unchanged 2.15m). This decision does not resolve that discrepancy: Ashtusk
already clears Mudsnout by a wide margin regardless of which reading is
right, so nothing about the evolution gate depends on it, and a resize is a
visual-treatment call that belongs to T1-CREATURE-ART, not to this lane.
Flagged in the T3-SUNSTONE handover for that lane to pick up.

## The Sunstone

A new item, `data/items/items.json`, mirroring `heartstone`'s shape exactly
(`kind: resource`, `stack: 1`, the same shared honest-stand-in stone icon) but
not its acquisition mechanism: Heartstone is a dungeon prize behind a
guardian; the Ashtusk brief restricts its whole family to open-world
geography (*"scorched terrain, warm stone, burned clearings, Team Tether
industrial sites"*), so the Sunstone is a bare one-time world pickup
(`scripts/world/key_pickup.gd`, the same generic class `castle_gate_key`
already uses), placed in `scripts/world/playground_world.gd` at the same
scorched-industrial pocket by band 5's Sigil gate that held the now-removed
wild Ashtusk. `key_pickup.gd` gained a `shape` parameter (`"key"` default,
unchanged; `"stone"` new) so this pickup renders as a faceted gem rather than
a house key — a small, backward-compatible addition reusing the exact faceted-
sphere technique `burrow_warrens.gd`'s own Heartstone prop already
established, not new art.

## Canon holds

Shiny, Alpha and Aspect Variant stay separate concepts, per the brief. Ashtusk
is still an aspect variant of Tuskroot (`variant_of`, `variant_kind: "aspect"`
unchanged — same lineage, mesh and typing classification) and is now
*additionally* an evolution outcome (`evolves_from`, acquisition path). The
two facts are orthogonal, both declared explicitly in the data, and neither
overwrites the other. No new inventory, currency, recipe or loot system: the
Sunstone is one new id in the existing item system. No new creature mesh, no
Meshy spend. Trainer rosters untouched. The five-creature cap is untouched
and, if anything, is what makes the Sunstone a real choice rather than a
formality — getting an Ashtusk this way costs a second Mudsnout raised from
nothing, and a permanent holder to keep it in.
