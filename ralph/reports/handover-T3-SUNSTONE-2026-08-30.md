# Handover — T3-SUNSTONE

**Branch:** `ralph/T3-SUNSTONE`, off `claude/tetherbound-coordinator-onboard-7pz3ah`,
with **`origin/ralph/T3-CREATURES` merged forward** (tip `5bdc2c6`, "Handover:
record the missing UI type colours for the five new types") — the nine-creature
expansion, dual typing and the type chart underneath it. The merge was clean,
no conflicts.
**Design note, pushed before implementation:**
`ralph/reports/SUNSTONE_DESIGN_2026-08-30.md`.
**Decision record:** `docs/decisions/D71-mudsnout-branches-into-tuskroot-or-ashtusk.md`.

---

## 1. What I was asked

The owner, verbatim: *"Make sure the Riftfrill and Ashtusk get put in the
game. For Ashtusk there should just be some kind of sunstone you get then you
evolve a Mudsnout using the stone to get the Ashtusk."*

Two jobs: give Mudsnout a second, item-selected evolution destination
(Ashtusk, via a new Sunstone) without breaking the existing one, and confirm
Riftfrill — already data-complete on T3-CREATURES — actually resolves in the
running game.

---

## 2. The branching design, and why

Full reasoning in `SUNSTONE_DESIGN_2026-08-30.md`, pushed as its own commit
before any implementation landed. Summary:

`data/creatures/species.json`'s `mudsnout` keeps its original single-string
`evolves_into: "tuskroot"` **untouched**, and gains a new sibling field,
`evolves_into_variants: {"sunstone": "ashtusk"}`.
`scripts/creatures/evolution.gd` merges the two and picks a branch by which
catalyst the player's inventory actually holds:

- **neither stone held** → Tuskroot stays the reported default target
  (byte-identical to pre-branch behaviour for a species with no variants)
- **exactly one stone held** → that stone's branch is used
- **both held at once** → `check()` refuses, naming the problem ("carrying
  more than one evolution stone — drop one so the choice is deliberate")
  rather than silently picking one

I rejected turning `evolves_into` itself into an item-keyed map (the brief's
other offered shape) because `tests/test_evolution.gd`'s nine pre-existing
cases are built entirely around `evolves_into` being a single string and
`item_id` being a single string in `progression.json`; that shape change
would have forced rewriting nine green tests to prove behaviour that does not
change at all for the shipped Heartstone path. The shape I shipped needed
**zero changes to `data/config/progression.json`** and **zero changes to any
pre-existing test** — verified by running the untouched suite against the new
code before adding a single new test.

I also considered and rejected building a real "choose your stone" UI screen
for the both-held case (the release ceremony's farewell panel is a ready
template for it). Reasoning in the design note § 2: it is new controller-first
UI surface for an edge case the five-creature cap already makes narrow, and
the screen's own refusal-string idiom already teaches every other gate
("needs level 15", "needs a stronger bond") the same way. If play evidence
says this reads as a wall rather than an instruction, the template is there
and scoped.

---

## 3. What changed about D13's "the only evolution in the biome"

D13 canonised exactly one evolution: Mudsnout → Tuskroot. That sentence is no
longer literally true. D13's body is not rewritten — it carries a header
amendment note (the convention the file already uses for D19/D23) pointing at
`D71`, which is the full record: what changed, why T3-CREATURES's own
`evolves_from`-withholding reasoning is being deliberately reversed for this
one species, and the wild-Ashtusk call below. The biome still has exactly one
**evolving species**; that species no longer has exactly one destination.

---

## 4. Where the Sunstone comes from

Mirrors Heartstone's item shape exactly (`kind: resource`, `stack: 1`, same
shared honest-stand-in stone icon). Its **acquisition mechanism** is
deliberately different: Heartstone is a dungeon prize behind a guardian; the
Ashtusk brief restricts the whole family to open-world geography ("scorched
terrain, warm stone... Team Tether industrial sites"), so the Sunstone is a
bare one-time world pickup using `scripts/world/key_pickup.gd` — the same
generic class `castle_gate_key` already uses, not a bespoke dungeon `prize`
block (there is no dungeon here to hang one on).

**Placed at `(121, 7336)`** in `scripts/world/playground_world.gd`
(`SUNSTONE_AT`, `_place_sunstone()`/`_spawn_sunstone()`, wired into `_ready()`
and `restore_progression_from_game()` exactly like `castle_gate_key`) — a few
metres inside the scorched Team Tether industrial pocket by band 5's Sigil
gate that held T3-CREATURES's wild Ashtusk cluster before I removed it (§5).
**Verified live**: booted the real scene, confirmed the `Sunstone` node exists
at the expected position with valid (non-NaN) ground under it — no
`push_error`.

`key_pickup.gd` gained a `shape` parameter (`"key"` default, unchanged;
`"stone"` new) because its existing visual is hardcoded to a shaft-and-ring
key — reusing it unmodified for a stone item would have shipped a Sunstone
that looks like a house key. The new `"stone"` branch is a faceted emissive
sphere, the same technique `burrow_warrens.gd::_build_prize`'s Heartstone gem
already established (stripped of that prop's plinth and dedicated light,
which its dark dungeon room needs and open Meadows daylight does not) — reuse
of an existing idiom, not new art. `castle_gate_key`'s call site passes no
`shape` argument, so its rendering is byte-for-byte unchanged.

**Told to the coordinator (T3-DENSITY):** this is a bare ground pickup, not a
`harvest.json` node, `TM_AT` entry, or `objectives.json` row — it doesn't
touch any file that lane owns, but it sits inside the same scorched-industrial
pocket that lane's density audit is measuring, so it should show up there as
one new non-harvest prop rather than a harvest node someone forgot.

**A fortunate proximity I found, not engineered:** band 5's existing
special-encounter Mudsnout (order 5004, already pinned by
`test_band5_clears_the_roster_temptation_floor_and_its_own_final_opportunity`
as the region's owner-direction §15 "final tempting roster opportunity") sits
~45m from the Sunstone, in the same general off-spine detour as the chapter's
apex Air TM. Both requirements were satisfied independently by their own
constraints (the Mudsnout by prompt 66's special-encounter siting, the
Sunstone by the brief's habitat restriction) and happen to land near each
other.

---

## 5. The wild Ashtusk individual — removed

T3-CREATURES's band5 cluster (order 5100, one catchable alpha-tier Ashtusk)
is **removed**. This was not optional once Ashtusk gained `evolves_from`:
`tests/test_spawns_data.gd::test_no_evolved_form_spawns_wild` already forbids
any evolved-form species from spawning wild (D20), and weakening that test
was off the table per this lane's own standing instructions. Of the three
options the brief named (remove / uncatchable sighting / keep catchable):

- **catchable** is foreclosed by the test above, full stop
- **uncatchable sighting** would need a "wild but refuses the catch attempt"
  state that does not exist anywhere in this codebase — real new scope for
  one flavour beat, which I flagged rather than built
- **removed** is what shipped, both because it is the smallest change that
  satisfies a real test and because the owner's own wording ("there should
  **just** be some kind of sunstone... to get the Ashtusk") reads as the
  evolution being the whole story

Band 5 keeps its D70-mandated final roster temptation regardless (§4 above —
it was already pinned to a different, unaffected entry). Full reasoning in
`D71`.

---

## 6. The aspect-variant test carve-out

`tests/test_dual_type.gd::test_no_aspect_variant_is_reachable_by_evolving`
pinned that no `variant_of` species may carry `evolves_from`, protecting the
rarity argument for Nightburrow/Stormtrail/Riftfrill/Ashtusk alike. Rather
than special-case `"ashtusk"` by id inside the test, or delete the assertion,
Ashtusk's species entry gained an explicit flag:

```json
"evolution_authorized": true
```

The test now reads: a variant **without** this flag is held to the original
rule exactly as before; a variant **with** it is instead checked for actually
having an `evolves_from` (a flag with nothing behind it now fails its own
assertion). The rule survives as a rule for Nightburrow, Stormtrail and
Riftfrill; Ashtusk's exception is visible in the data, not hidden in test
logic.

---

## 7. Riftfrill — verified live, not just re-read

T3-CREATURES's own handover said plainly: *"Nobody has seen any of these four
creatures in the running game."* I closed that for Riftfrill specifically
with `tools/_probe_riftfrill_gate.gd`, which boots the real
`meadows_playground.tscn` and checks, live, in one run:

```
ground under Riftfrill's coordinate: -8.21m -- real, walkable heightfield
found riftfrill wild body at (-182.0, 4101.4), 6.9m from the authored centre
hour 12.0 (day)   riftfrill.visible = false
hour 2.0 (night)  riftfrill.visible = true
```

- **Species entry**: resolves (`creature_species.gd` finds `riftfrill`).
- **Spawn cluster**: a live wild body exists near band 3's authored coordinate
  (`(-176, 0, 4098)`, order 3101), well inside its 8m scatter radius.
- **Habitat/gate**: real, non-NaN ground under it — reachable terrain, in the
  same pond system as the already-shipped Paddlenewt cluster 34m away.
- **The night gate is not just correct on paper**: forcing the world clock to
  hour 12 hides it; forcing it to hour 2 shows it, live, through the actual
  `_sync_spawn_gates()` code path every other gated creature in the game
  already runs through. This is executed evidence, not a second reading of
  the same source T3-CREATURES already read.

**No visual verification attempted, deliberately** — per this lane's own
brief and T3-CREATURES's own correct reasoning: the four variants render as
unmodified base meshes until T1-CREATURE-ART lands the recolour/VFX pass, and
a frame of that now would judge the missing art, not this lane's work or
T3-CREATURES's.

---

## 8. Other data corrections made in the same commits

- `data/config/chapter_rewards.json` — the "Burrow Warrens clear" row's
  `enables` text called the Heartstone the gate to "the chapter's one
  evolution." Fixed to name both branches; the row's numbers are unchanged,
  and it stays the only reward row naming either stone (the Sunstone is a
  bare pickup, not a payout from any audited activity).
- `data/config/chapter_curve.json` — band 2's `tools`/`temptations` now say
  "one of Mudsnout's two destinations" instead of implying it's the only one;
  band 5's `tools`/`temptations` now name the Sunstone and its five-creature-
  slot stakes, tying it to the same beat as the legendary join offer.

---

## 9. Done-verified vs still-open

### Done and verified by test (targeted suites run clean, then the full suite)

- `test_evolution.gd` — 15 tests including 5 new ones for the sunstone branch
  and the ambiguous-both-held refusal; all 9 pre-existing cases pass
  **unmodified**
- `test_evolution_links.gd` — mirrored every existing D17/reverse-link/
  existence check onto `evolves_into_variants`
- `test_dual_type.gd::test_no_aspect_variant_is_reachable_by_evolving` —
  updated for the `evolution_authorized` carve-out; every other aspect variant
  still forbidden
- `test_spawns_data.gd::test_no_evolved_form_spawns_wild` and
  `test_band5_clears_the_roster_temptation_floor_and_its_own_final_opportunity`
  — both pass with the wild Ashtusk cluster removed
- `test_item_icons.gd`, `test_chapter_rewards.gd`, `test_band_content.gd`,
  `test_type_chart.gd` — unaffected, all green
- `smoke_art.gd` — Ashtusk now renders through the evolution-only-species
  path (`ashtusk model 2.15m, collider 2.15m (evolution-only)`), exercised by
  an existing test for the first time
- `smoke_evolution.gd` — the real Team-screen ceremony (menu, focus, two-beat
  confirm, hand-back) still evolves a ready Mudsnout into Tuskroot end to end,
  unmodified
- Full suite (`tests/run_tests.gd`, no `--only`) run to completion — see
  final status below

### Done, verified live via a purpose-built probe (not a permanent test)

- `tools/_probe_riftfrill_gate.gd` — Riftfrill's spawn, ground and night gate,
  §7 above
- Sunstone pickup boots at its authored position with valid ground under it
  (ad hoc probe, not committed)

### Still open, deliberately not mine

- The five pending-mesh creatures' Meshy generation (no `MESHY_API_KEY`)
- T1-CREATURE-ART's recolour/VFX pass on all four aspect variants, Riftfrill
  and Ashtusk included
- The Ashtusk reference sheet's own build-path discrepancy ("VARIANT RECOLOR
  + RESIZE + VFX" on the image sheet vs. no-resize in the written brief and
  T3-CREATURES's data) — flagged in `D71`, not acted on: Ashtusk already
  clears Mudsnout by a wide margin either way, so nothing about the evolution
  gate depends on resolving it, and a resize call belongs to the art lane
- T3-CREATURES's other open items (matchup rows for the five new types, the
  Water-scarcity finding, trainer roster rebalance) — untouched, not this
  lane's brief

---

## 10. File footprint

**New:**
- `ralph/reports/SUNSTONE_DESIGN_2026-08-30.md`
- `ralph/reports/handover-T3-SUNSTONE-2026-08-30.md` (this file)
- `docs/decisions/D71-mudsnout-branches-into-tuskroot-or-ashtusk.md`
- `tools/_probe_riftfrill_gate.gd`

**Modified:**
- `data/creatures/species.json` — `mudsnout.evolves_into_variants`; `ashtusk`
  gains `evolves_from`, `evolution_authorized`, updated `_why`/`_why_evolution`
- `data/items/items.json` — new `sunstone` item
- `data/config/bands/band5_stronghold_approach/spawns.json` — wild Ashtusk
  cluster (order 5100) removed, replaced with a `_comment_ashtusk_removed`
  pointer
- `data/config/chapter_rewards.json`, `data/config/chapter_curve.json` — drift
  fixes, § 8
- `scripts/creatures/evolution.gd` — branch-aware `requirements()`/`check()`/
  `evolve()`, `variant_branches()`, catalyst-naming helpers
- `scripts/world/playground_world.gd` — `SUNSTONE_AT`, `_place_sunstone()`,
  `_spawn_sunstone()`, restore-on-load wiring
- `scripts/world/key_pickup.gd` — optional `shape` parameter (`"key"`
  unchanged default, new `"stone"` visual)
- `tests/test_evolution.gd` — 5 new tests for the branch
- `tests/test_evolution_links.gd` — mirrored checks for
  `evolves_into_variants`, docstring updates
- `tests/test_dual_type.gd` — `evolution_authorized` carve-out
- `docs/decisions/D13-the-wild-roster-is-recanonised.md` — header amendment
  note pointing at D71

**Not touched, by ownership:** `data/config/bands/*/harvest.json`,
`objectives.json`, `TM_AT`, trainer rosters, creature materials/VFX/meshes,
`scripts/ui/tab_creatures.gd` (no change needed — its refusal-string display
already surfaces whatever `evolution.gd::check()` returns, so the branch's
messaging reaches the player with zero UI-layer changes).
