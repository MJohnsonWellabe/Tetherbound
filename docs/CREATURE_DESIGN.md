# Tetherbound — Creature Design Source of Truth

Consolidated from `data/creatures/species.json`, `docs/art/wild/21_MEADOWS_WILD_ROSTER_CANON.md`,
`docs/art/ROSTER_MANIFEST.md`, `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md`,
`docs/art/HUMANOID_ASSET_INVENTORY.md`, `docs/art/REFERENCE_CANON.md`,
`docs/owner/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md`,
`docs/owner/OWNER_DIRECTIVES_2026-09-01.md`, and decisions D10, D12, D13, D17, D19,
D30, D37, D69, D70, D71. Canon precedence (`CLAUDE.md`): newer owner
directive > `MEADOWS_PROGRESSION_SPEC.md` > `GAME_DESIGN.md` > task prompts >
backlog history. States current data-driven fact plus the decisions that
produced it; does not restate superseded reasoning — see cited files.

---

## 1. Roster — all 25 species

Source: `data/creatures/species.json` (25 entries). Columns: height (m,
`placeholder.height`), `catch_rate` (0-1), `aggressive` (challenges on sight).

### Starters (3)

| Species | Type | Height | Catch rate | Aggressive | Role |
|---|---|---|---|---|---|
| Terrapup | Ground | 2.30 | 0.30 | No | Starter — forgiving/tanky |
| Ripplet | Water | 2.15 | 0.30 | No | Starter — balanced |
| Galewisp | Air | 1.90 | 0.30 | No | Starter — offense/energy |

### Core Meadows wild roster (12)

| Species | Type | Height | Catch rate | Aggressive | Notes |
|---|---|---|---|---|---|
| Bramblebun | Ground | 1.00 | 0.60 | No | Rabbit; common, signature small species |
| Mudsnout | Ground | 0.95 | 0.55 | No | Piglet/rooting runt; pre-evolution |
| Trailpup | Ground | 1.28 | 0.38 | No | Canine; not a starter, no stone mantle |
| Burrowback | Ground | 1.70 | 0.40 | No | Badger; broad, defensive |
| Meadowhart | Ground | 2.05 | 0.45 | No | Rideable mount; not the legendary |
| Paddlenewt | Water | 1.15 | 0.50 | No | Amphibian/newt |
| Mosshell | Water | 1.40 | 0.40 | No | Turtle; tanky, shell-forward |
| Brooktail | Water | 1.05 | 0.45 | No | Otter |
| Reedwing | Water | 1.50 | 0.48 | No | Waterfowl, Water/Air-flavoured |
| Pipwing | Air | 0.76 | 0.55 | No | Small bird; smallest in the roster |
| Duskhush | Air | 1.28 | 0.42 | No | Owl; nocturnal |
| Galecrest | Air | 2.10 | 0.28 | Yes | Hawk/raptor; not the Air starter |

### Evolution (1 line, 2 branches)

| Species | Type | Height | Catch rate | Aggressive | Notes |
|---|---|---|---|---|---|
| Tuskroot | Ground | 2.15 | 0.28 | Yes | Evolved from Mudsnout via Heartstone. Never spawns wild (D20/D17). |
| Ashtusk | Ground/Fire | 2.15 | 0.12 | Yes | Evolved from Mudsnout via Sunstone (D71); also an aspect variant of Tuskroot — the one exception to "variants never evolve" (`evolution_authorized: true`, `tests/test_dual_type.gd`). |

See §2 for branch mechanics.

### Legendary (1)

| Species | Type | Height | Catch rate | Aggressive | Notes |
|---|---|---|---|---|---|
| Veridian Stag | Ground | 3.60 | 0.02 | Yes | Legendary. Rideable, `requires_item: ""` — joins voluntarily, no tack needed. Tallest creature in the game. |

### Aspect variants (3, from `TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md`)

Rare, environmentally-triggered recolors/VFX layers on an existing base
species. Same lineage/mesh as their base; typing and appearance change,
nothing else. Build path: existing model + recolor + modest resize +
emissive materials + VFX — **not** a Meshy regeneration.

| Species | Base | Type | Height | Catch rate | Rarity tier |
|---|---|---|---|---|---|
| Nightburrow | Burrowback | Ground/Dark | 2.10 | 0.10 | Exceptional alpha |
| Stormtrail | Trailpup | Ground/Electric | 1.45 | 0.14 | Rare alpha, storm-biased |
| Riftfrill | Paddlenewt | Water/Psychic | 1.15 | 0.16 | Rare variant, not alpha |
| Ashtusk | Tuskroot | Ground/Fire | 2.15 | 0.12 | Mini-alpha; also an evolution outcome, see §2 |

### New Meshy species (4, from the same expansion brief)

Wholly new creatures, each with owner-supplied reference art under
`docs/art/reference/creature-expansion-2026-08-30/`. Wanderers, not native
dominant species — the Meadows stays Ground-dominant; these foreshadow
future regions (Electric, Fire, Ice, Dark) at deliberately low encounter
rates.

| Species | Type | Height | Catch rate | Aggressive | Rarity tier |
|---|---|---|---|---|---|
| Sparkit | Electric | 0.85 | 0.45 | No | Uncommon-to-rare wanderer; storm-biased |
| Cindercub | Fire/Ground | 1.40 | 0.35 | No | Rare wanderer; warmth-tied habitat |
| Shadelet | Dark | 1.60 | 0.40 | No | Uncommon nocturnal wanderer |
| Frostclaw | Ice | 2.00 | 0.22 | Yes | Rare wanderer; geographically constrained to the cold Meadows edge |

### Population philosophy (owner brief)

Common (base 12 + starters) is the overwhelming majority of wild encounters.
Uncommon ≈ 5-10% of eligible habitat spawns. Rare ≈ 1-3%. Exceptional/Alpha is
well below 1%, one active Alpha (e.g. Nightburrow) per region at a time, never
several elemental Alphas visible simultaneously. Directional targets, not
locked balance values; full per-species habitat/weather/time rules are in the
expansion brief.

---

## 2. Evolution line

**Mudsnout → Tuskroot | Ashtusk** — the Meadows' only evolution line (D13),
now with two branches (D71).

- `species.json`'s `mudsnout` carries `evolves_into: "tuskroot"` (the
  original D13/D17 path) plus a sibling field
  `evolves_into_variants: {"sunstone": "ashtusk"}`.
- `scripts/creatures/evolution.gd` merges both and picks the branch by which
  catalyst item the player's inventory actually holds: Heartstone → Tuskroot,
  Sunstone → Ashtusk. Holding neither defaults to Tuskroot; holding both
  refuses with a named-ambiguity reason rather than silently picking one.
- Both branches share one progression gate — `progression.json`
  `evolution.mudsnout`: level 15, bond 55, item Heartstone or Sunstone. No
  second gate exists for Ashtusk.
- Tuskroot never spawns wild (`tests/test_spawns_data.gd::test_no_evolved_form_spawns_wild`,
  D20: "an evolution you can just walk up to and catch makes evolving
  pointless"). Ashtusk's wild placement was removed once it gained
  `evolves_from`, for the same reason — reached only through the Sunstone.
- Heartstone is a dungeon prize behind a guardian (Burrow Warrens). Sunstone
  is a bare open-world pickup (`scripts/world/key_pickup.gd`, `shape: "stone"`)
  in Band 5's scorched-industrial pocket, near Band 5's off-spine special
  "worth catching" Mudsnout.

---

## 3. Scale rules

Four decisions moved the creature scale band since the game's earliest form.
**Current state governs; do not "fix" heights back toward an older number.**

1. **D12 — creatures are peers, not pets.** Original band 1.35–2.00 m,
   scaled up from sub-1.0m "pet" sizes so creatures read as characters, not
   ankle-height companions.
2. **D19 — starters are boar-sized.** Owner playtest finding: the piloted
   starter still felt small. Starters jump further than the rest of the
   band (+0.30/+0.35 m vs. +0.15 m), landing in the top quarter of the wild
   band.
3. **D69 — the band widens from the bottom.** Owner: *"widen the creature
   band size if appropriate."* Every metre of widening comes from shrinking
   the SMALL tier (Pipwing 1.35→0.60 m); starters and the large tier do not
   move. Band becomes 0.60–2.60 m (4.33x spread, up from 1.93x). D13's
   relative ordering (smallest/largest) is preserved bit-for-bit.
4. **OD-0901-1/2 (`docs/owner/OWNER_DIRECTIVES_2026-09-01.md`) — grow the
   ceiling, don't shrink toward it.** Explicit owner correction: *"I think
   almost all creatures should stand taller than the character... these big
   beautiful fantastical creatures."* Reverses a prior lane's mistake
   (`ebb97677`) that had shrunk Terrapup/Ripplet toward the 1.80 m trainer,
   and a second mistake that capped the alpha Galecrest below the
   legendary's multiplier. **Standing rule:** a relative-scale complaint
   (alpha vs. legendary, cub vs. adult, starter vs. player) is fixed by
   raising the smaller side, never lowering the larger one.
   `ralph/VISUAL-STARTER-BADGER-SCALE-REVERT` and
   `ralph/VISUAL-VERIDIAN-GROWTH` are in-flight corrections this triggered —
   `species.json` (§1's table) is the ground truth for current numbers.

**D17 — an evolution is always strictly larger than its source.** Enforced
by `tests/test_evolution_links.gd` for both `evolves_into` and
`evolves_into_variants`. Mudsnout (0.95 m) → Tuskroot (2.15 m) and →
Ashtusk (2.15 m) both clear this by over a metre.

**The 1.80 m trainer is the fixed reference.** Every height in
`species.json` is a game-scale decision, divorced from the reference
sheets' real-world centimetre figures, which remain the creature's
"biology" (D12's carve-out). No model geometry is ever rebuilt for a
rescale — height is one number per species; collider radius scales with it,
so attack reach and catch-formula accuracy bonus carry over unchanged.

---

## 4. Legendary — Veridian Stag

Ground type, `species.json` id `veridian`. Height 3.60 m — always the
tallest creature in the game; its headroom over the largest wild/evolved
tier is a value to protect, not shrink (OD-0901-2). `rideable.requires_item:
""` — voluntarily joins, no tack required, unlike Meadowhart. Lowest catch
rate in the roster (0.02). Reached through the stronghold's
`legendary_chamber` (`KEEP_CHAMBERS`, `scripts/world/stronghold.gd:1350`) as
part of the legendary roster choice beat at the end of the Meadows chapter.
Production name history: earlier called "Terracrown"; the art carries
"Veridian Stag" and that is the name the project uses.

---

## 5. Stats, moves, traits, individuality (D30, D37)

- **Level/XP (D30).** Wild creatures spawn inside a level band rather than a
  fixed level; XP is earned from combat victories per `progression.json`'s
  `level`/`xp_award` tables.
- **Moves are named per species.** Every species carries a `moves` list (2
  entries per species, from `data/moves/moves.json`, 48 moves total). Moves
  map onto the two existing combat verbs (`player_quick`/`player_charged`
  from `combat.json`) via a `power` multiplier on `combat_math.base_damage()`
  — names/flavour on the existing two-verb system, not a four-move-slot
  system. Every move shipped at `power: 1.0` (balance-neutral).
- **Bond is a 5-node stat**, gated to a milestone ladder — see §6.
- **Individuality (D37).** Every instance carries three 0.0–1.0 rolls
  (`iv_hp`/`iv_attack`/`iv_defence`), a real ±12% multiplier
  (`individuality.variance_pct`) on the level curve, shown as 1-5
  stars/bars, never the raw roll. Starters are the exception:
  `GameState.make_creature` gives them average individuality and no trait
  roll, so picking a starter stays a known-quantity choice; wild creatures
  carry the "seek better individuality/traits" loop.
- **Traits are flavour, not balance (D37).** Every creature rolls a primary
  trait from `data/traits/traits.json` (8: Bold, Calm, Sturdy, Swift, Gentle,
  Stubborn, Curious, Watchful) and a hidden secondary withheld until bond
  crosses `traits.unlock_bond_nodes` (5, fully bonded). No stat-bonus table
  or ability-effect exists — do not invent one; that is a new owner decision.

---

## 6. Bond milestone ladder (D70)

Bond is an **ordered ladder of five concrete, nameable tasks**
(`data/config/bond_milestones.json`, `scripts/creatures/bond_milestones.gd`),
not a 0-100 meter. A creature is always working toward exactly one named task
("38/50 wild creatures defeated together"); finishing a task advances the tier
by exactly one, and a later task's counter climbing first does not skip ahead.

| # | Task | Target | Status |
|---|---|---|---|
| 1 | `battles_fought` — wild creatures defeated together | 50 | Owner's own words, exact, unmodified |
| 2 | `landmarks_visited_together` — landmarks discovered together | 3 | Judgment call (of 9 shipped landmarks) |
| 3 | `distance_m_together` — meters travelled together | 4000 | Judgment call (~1/3 of the 11,519 m critical-path spine) |
| 4 | `rest_nights_together` — nights rested together | 4 | Judgment call |
| 5 | `feeds_together` — meals fed together | 10 | Judgment call; lowest target since it can't be advanced for the whole roster at once |

Only milestone 1's target is settled canon in the owner's own words; 2-5 are
flagged, tunable judgment calls. `bond_nodes()` (0-5 completed milestones) is
what downstream systems read: `bond.effects_per_node` (small attack/defence
scale per node), `traits.unlock_bond_nodes` (second trait at node 5), and the
Mudsnout evolution gate (`bond_tier: 3`). Distance/landmarks/rest credit
every party member present at once; feeding is per-creature and manual.

Design goal, from the owner directly: a full five-creature team should reach
all five milestones before leaving the Meadows, not merely clear the first
one or two.

---

## 7. Art constraints

**No new creature meshes or Meshy generations for Meadows**, except the nine
species named in `TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md` (Nightburrow,
Stormtrail, Sparkit, Cindercub, Shadelet, Bramblebun-redesign, Riftfrill,
Ashtusk, Frostclaw) — a named, scoped exception with owner-supplied reference
art vendored beside that brief, not a general license. Outside that list,
differentiate by material, texture, modest scale, animation, VFX, habitat,
behavior, and encounter context — never a fresh mesh.

**Never spend a Meshy generation without owner-supplied reference art.**
Satisfied for the nine expansion creatures; still binds for anything else.

**Sourced creature art is a stand-in (D10).** Every creature mesh exists to
prove the systems around it — rigging, clip mapping, collider scaling,
combat-state animation — not to be the game's final look. The gap to the
owner's visual bar is recorded and left open, not argued away; it closes
only by commissioning or making art. Do not let a stand-in set a design
decision — species identity and roster composition come from the canon docs
above, never reverse-engineered from a sourced pack.

**Humanoid reuse (D24 + `HUMANOID_ASSET_INVENTORY.md`).** One nature family,
one village family, one prop family; Meshy is reserved for Team Tether hero
objects. 28 installed humanoid `.glb` bodies exist on `main` (6 base
families + 22 generated village/trail NPCs) — reuse before generating. The
Warden is already rebuilt from the owner-supplied board-16 sheet
(`assets/characters/warden/warden_lod0.glb`); do not reopen the historical
"painted face" complaint against the old board-06 version.

---

## 8. Asset locations

- Species data: `data/creatures/species.json` (25 entries), plus
  `species_pending.json` (empty stub), `aspect_variants.json`,
  `shiny_colourways.json` (10 cosmetic colourways layered on the 25 species).
- Moves: `data/moves/moves.json` (48), `data/moves/tms.json` (14 TMs).
- Traits: `data/traits/traits.json` (8). Bond: `data/config/bond_milestones.json`.
  Progression tunables: `data/config/progression.json`.
- Creature models: `assets/creatures/tetherbound/<species>/models/` — verify
  the exact path against current `main` before assuming a species is
  installed; `MEADOWS_WILD_PRODUCTION_REPORT.md` tracks per-species rig/clip
  status, not this file.
- Runtime creature code: `scripts/creatures/` (19 files, 4,912 lines) —
  `creature_body.gd` (1,549, the piloted/AI body), `wild_creature.gd`,
  `creature_instance.gd`, `creature_species.gd`, `move_db.gd`, `trait_db.gd`,
  `evolution.gd`, `bond_milestones.gd`, `alpha_aura.gd`.
- Spawn placement: per-band `data/config/bands/<band>/spawns.json` (68+57+54+
  81+23 = 283 entries), driven by `scripts/combat/encounter_director.gd` and
  `scripts/combat/spawn_tables.gd`.

---

## 9. Known presentation gaps (open items)

Recorded gaps, not tasks to silently resolve by guessing a fix — verify
current state on `main` before acting; follow D10's rule that a stand-in
mesh's shortcomings are a measured gap, not a design defect to argue away.

- **Creature material split vs. trainer.** Historical blind review (D10)
  found creatures and the trainer sourced from different pipelines reading
  as visually incohesive — zero albedo variation between two creatures from
  different sources, proportion mismatches against key art. Whether this is
  still true on current `main` needs a fresh visual pass, not an assumption.
- **Creature visibility in grass.** With the band down to 0.60 m (D69), the
  smallest creatures (Pipwing, Bramblebun) are genuinely small on screen.
  D69 itself flags this as open: whether a fight against something that
  size reads well and holds in the combat camera is a playtest finding, not
  resolved here.
- **Bed poses.** No specific defect is pinned in the consolidated inputs for
  this pass; flagged per the task brief. Check `docs/CURRENT_STATE.md` and recent
  visual-census reports for the current specific complaint before working on it.
- **Combat camera crowding.** D12/D19 flagged that peer-sized (and now
  taller-than-player) fighters may crowd the fixed 11 m arena and frame more
  body than ground. D69 narrowed this for small-wild fights but not for
  starter-vs-starter or starter-vs-large-wild. `combat.json`'s arena radius
  and `camera` block are the tunable dials; a tune is a playtest finding,
  not assumed here.
