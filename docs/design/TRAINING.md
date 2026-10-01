# Training — creature power

**Status: Not built (target) — every system in this contract.** Source references describe main at `1c3f0b0d`. Foundations that exist today are named in each section as **current**; everything else is a target from the owner design interview of 2026-09-29 (`CODEX_START_HERE.md` §1, §3.1) and is unimplemented until code, tests and the named ACCEPTANCE §6.2 rows prove it. Cite decisions as "(owner, 2026-09-29, RD-nn)".

**Why this exists:** the spine of the game is creature power. Building the best five-creature team is the goal, and the homestead is the required engine that produces it (RD-02). This file owns how a creature *acquires and grows* power: essence and levels, caps and breakthroughs, Masters and Ascension Feasts, evolution, traits, move acquisition and mastery, the research log and Ripplet's swim/dive progression.

**Routing.** CREATURES owns the catalogue, stats formula, individuality, bond and catching. COMBAT owns in-fight verbs, slot inputs, timings, damage, the ultimate meter and Tether Commands. BOSSES owns Master fight profiles. HOMESTEAD owns stations, attachments, recipes' material lists, gear and forward camps. PROGRESSION owns the level curve, ledgers, reward schedule and time budget. MULTIPLAYER owns transport/reconnect enforcement of the scopes declared here. UX owns the Altar and inspect screens.

Hard rules that bound everything below: five owned creatures total, no storage or sixth; catch only in wild combat; starters exclusive and never evolve (RD-28); the human never deals damage; no creature expeditions, training trials or automation (RD-05); nothing produces while the player is away; no held-button gameplay except Fly.

| System | Section | Feature / acceptance | Status | Current foundation |
|---|---|---|---|---|
| Type essence, Tether Candy, Altar spend, auto-XP trickle, release payout | §1 | F27 | Not built (target) | `scripts/creatures/progression.gd`, release ceremony |
| Level caps and breakthroughs | §2 | F28 | Not built (target) | global cap 100 |
| Five Masters | §3 | F28, F44 (rematch) | Not built (target) | — |
| Ascension Feasts | §4 | F28, F31 (Kitchen) | Not built (target) | recipe/craft code |
| Evolution lines | §5 | F29, F36 (storm bear art) | Not built (target) | Mudsnout evolution, `evolution.gd` |
| Traits and Trait Seeds | §6 | F30 | Not built (target) | eight flavor traits |
| Move acquisition, loadout, mastery, ultimate growth | §7 | F23, F35 | Not built (target) | quick/charged, TMs |
| Research log | §8 | F45 | Not built (target) | — |
| Ripplet swim and Dive | §9 | F37 | Not built (target) | human swim, water adapter mounts |
| Route solvency of all of the above | PROGRESSION | F27#5, F47 | Not built (target) | — |

The player loop this serves: portal out, fight/catch/release/gather, Home Key back, spend essence at the Altar on the creature you chose, cook and feed feasts, swap loadouts, teach seeds, portal out again (`CODEX_START_HERE.md` §2).

## 1. Type essence and Tether Candy (F27)

**Current:** combat XP is the only level source besides the found `good_candy` / `great_candy` / `rare_candy` consumables (`data/items/items.json`). Release exists as the release ceremony in `scripts/ui/tab_creatures.gd` (reached when a catch or volunteer offer meets a full party) and pays nothing.

**Target items** (stackable, character inventory, never sold to shops):

| Item | Ids | Source |
|---|---|---|
| Type essence ×8 | `essence_ground`, `essence_water`, `essence_air`, `essence_electric`, `essence_fire`, `essence_dark`, `essence_ice`, `essence_psychic` | See sources below |
| Tether Candy | `tether_candy` | Rare and generic: bosses, Masters, occasional bounty (RD-04) |

**Sources (RD-05), all tunable in `data/config/essence.json`:**

| Source | Rule | Starting value |
|---|---|---|
| Defeating a wild | Pays the defeated species' type essence once per defeat event (same event id as its XP). | 1 per defeat, +1 per 10 opponent levels |
| Releasing a caught creature | `release_essence_base + release_essence_per_level × level` of the creature's type; dual types split, remainder to the primary type. Once per creature uid. | base 3, per level 0.5 |
| Attuned nodes | Hand-gathered type-essence nodes, 1–2 per type per biome, mostly off-route; respawn on a configured timer (HOMESTEAD/F32). | 2–4 per harvest |
| Type crops | Eight crops on homestead plots; planted and harvested by hand (HOMESTEAD `farm.json`). | 3 per harvest, plus 2 attuned ingredients |
| Research tasks | §8. | per task, see §8 |
| Care trickle | Den grooming (once per owned creature per in-game day, HOMESTEAD) credits that creature's type essence, capped per character per day. | 1 per grooming, cap 5 per day |

Not sources: training trials, creature expeditions, idle/offline yield, trainer battles paying XP-like essence beyond their authored rewards.

**Spending at the Altar (RD-03).** The player chooses a creature and pays essence of that creature's type to raise its level by one; repeatable up to its current cap. Dual types pay in either type. Starters level through their own type. One Tether Candy pays the whole cost of one level for any creature (starting rule). Cost per level rises with level and is set per level band in `essence.json`; the starting curve is `ceil(XP_to_next(L) / essence_xp_value)` with `essence_xp_value = 25`, so it tracks PROGRESSION's XP curve. Spending never exceeds the cap and never refunds.

**Automatic XP stays (RD-03).** The existing award formula (PROGRESSION §2) × `auto_xp_scale`, starting **0.35**, never zero; the rest bonus stays. A capped creature banks no XP beyond the cap. The existing `*_candy` consumables also respect the cap (target); whether they convert into Tether Candy is an open question (§12).

**Transactions.** Each award and spend carries a transaction id: defeat payouts reuse the host's defeat event id; release payouts use `release:<uid>`; Altar spends use a client-generated spend id the host validates once. Acceptance: F27#0–#5.

## 2. Level caps and breakthroughs (F28)

**Current:** a global cap of 100 in `data/config/progression.json`; no tier caps.

**Target (RD-08):** `level_caps = [10, 20, 30, 40, 50, 60]` live in this pass; `[70, 80, 90, 100]` are reserved in data for biomes 5–8 (RD-09). L60 is this pass's ceiling: there is no L60 breakthrough until a fifth biome exists. A creature at its cap stops gaining levels from every source and shows **"breakthrough needed"**. Its breakthrough state is a per-creature list of completed tiers.

Breaking a cap takes, in order: win that tier's Master (§3), learn its Ascension Feast recipe, gather and cook the feast at the Kitchen (§4), and feed it to the creature. Feeding lifts that creature's cap one tier, grows its ultimate (§7), unlocks trait slots at the L10/L30/L50 tiers (§6), may add learnset options (§7) and, for the four evolution lines, offers evolve or stay (§5). The L30 tier also grants Ripplet Dive (§9).

**Caught creatures above a cap.** Wild creatures can exceed a cap (Stormwood wilds reach 54). Proposed starting rule, pending F28 and owner confirmation (§12): a caught creature arrives with every tier below its level counted as cleared for the cap only; trait slots and ultimate growth for those tiers are granted on catch too; missed evolution offers are not retroactive.

## 3. The five Masters (F28, RD-06, RD-07)

One Master per tier, each a named character from the installed humanoid cast, off the main path and signposted. BOSSES owns each Master's creature, patterns and arena; WORLD owns placement geometry.

| Tier | Placement | Access |
|---|---|---|
| L10 | Mid-Meadows (River Lock / Quarry) | on foot |
| L20 | Upper Meadows before the Warden's stronghold | on foot |
| L30 | An outer Tidewake island | swim (human-swimmable) |
| L40 | A Cloudreach high perch | Fly |
| L50 | Deep Stormwood | on foot |

**Rules.** The fight is a **1v1**: the player chooses one creature at the arena and fights the Master's one creature. No switching; Tether Commands follow COMBAT. A loss is retryable with no penalty beyond ordinary recovery. A win opens the Master's chest, which teaches that tier's Ascension Feast recipe **once per character** and pays Tether Candy (starting value 2, `data/config/masters.json`). The Master's creature starts at the tier's cap level (starting value; BOSSES tunes). Winning does not itself break any cap. Post-boss rematches follow PROGRESSION §6 and F44.

**Co-op (RD-07, RD-21).** Recipes are personal. Each character who wins their own 1v1 at the arena earns their own chest receipt; a spectator earns nothing; nobody receives a recipe twice. The host validates the result and records the receipt against the stable character. Whether a co-op visit runs as sequential duels or one duel per visit is an F28 implementation choice; the per-character 1v1 requirement is a proposed reading flagged in §12. Acceptance: F28#0–#5.

## 4. Ascension Feasts (F28, RD-07)

A feast `feast_t<N>` = that tier's biome materials + one `attuned_<type>` ingredient matching the creature to be fed. It is cooked **only at the homestead Kitchen**, at a Kitchen tier that HOMESTEAD's attachment rule allows; forward-camp cookpots refuse feasts (F34#1). One feast feeds one creature and lifts one tier. Material lists live in `data/recipes/feasts.json` and are owned by HOMESTEAD; the tier-to-biome map is:

| Feast | Breaks | Materials from | Evolution ingredient |
|---|---|---|---|
| T1 | L10 | Meadows tier 1 | — |
| T2 | L20 | Meadows tier 1 | Heartstone or Sunstone for Mudsnout only |
| T3 | L30 | Tidewake tier 2 | — |
| T4 | L40 | Cloudreach tier 3 | — |
| T5 | L50 | Stormwood tier 4 | — |

Attuned ingredients (`attuned_ground` … `attuned_psychic`) come from essence nodes and type crops (HOMESTEAD; tier table in `CODEX_START_HERE.md` §3.4). A dual-type creature accepts either type's attuned ingredient. Every ingredient must be reachable in or before its biome (F28#5 ledger). Feeding is a character-scope transaction (`feast:<uid>:<tier>`); the feast item is consumed and the cap lifted atomically, or neither happens.

## 5. Evolution lines (F29, RD-28)

**Current:** Mudsnout evolves at L15 and bond tier 3, holding Heartstone → Tuskroot or Sunstone → Ashtusk (`scripts/creatures/evolution.gd`, `data/config/progression.json::evolution`, `species.json::evolves_into_variants`). **Superseded (owner, 2026-09-29, RD-28):** the L15 + bond gate. Evolution now happens only at a breakthrough feast.

| Line | Tier | Trigger | Evolved form wild? |
|---|---|---|---|
| Mudsnout → Tuskroot or Ashtusk | L20 | T2 feast with Heartstone (Tuskroot) or Sunstone (Ashtusk) as the extra ingredient | No |
| Mosshell → Cannonback | L30 | T3 feast | Yes, where it already appears |
| Craghorn → Stormcapra | L40 | T4 feast | Yes, where it already appears |
| Staticub → storm bear (working name *Stormursa*) | L50 | T5 feast | No |

**Evolve or stay.** Feeding the tier's feast to an eligible creature offers evolve or stay. Staying is permanent for that tier; the cap still lifts. **Starters never evolve** (Terrapup, Ripplet, Galewisp). Evolution is transformation: the same uid, nickname, level and XP, bond task history, condition, IVs, traits (rolled and taught), move loadout and mastery, boosts and Best flag survive; only species and derived stats change. Evolved forms are always taller than their source (D17) and taller than the 1.80 m trainer.

**The storm bear** is the one new creature authorized this pass (RD-28): Electric, larger than Staticub, built by Codex through an agent-drafted reference and the Meshy workflow with provenance and an in-engine code-blind PASS (ART_DIRECTION, F36). It stays flag-gated until that PASS; until then Staticub's T5 feast lifts the cap without an offer. Its final name is an owner item. Acceptance: F29#0–#4.

## 6. Traits and Trait Seeds (F30, RD-30)

**Current:** one personality trait of eight (Bold … Watchful) plus a hidden secondary revealed at five bond nodes; flavor only (CREATURES §3.1).

**Target.** A pool of about 30 traits in **Common, Rare and Epic** tiers in `data/config/traits.json`, each with one plain-language effect that applies in combat or traversal (a unit test per trait). Starting magnitude caps: Common ≤5%, Rare ≤8%, Epic ≤12%, one stat or behavior each, no duplicates on one creature.

- **Rolled traits:** the host rolls 0–3 traits when a wild spawns. Alphas and night or weather spawns roll more and better (weights in `traits.json`). Traits show on the catch readout and inspect screens (F30#1).
- **Distil:** releasing a caught creature at the Altar lets the player distil **one chosen trait** into a Trait Seed item, alongside the essence payout. One seed per release uid.
- **Teach:** a seed teaches one trait into a trait slot. Slots unlock at the L10, L30 and L50 breakthroughs (three taught slots at most) and teaching costs essence of the creature's type (starting value 10 × slot number). Overwriting a taught trait destroys the old one. Traits come to the five; there is no pressure to replace a creature to get a trait.
- **Unification:** the existing eight personality traits and the bond-revealed secondary join this pool; the exact mapping (proposed: the eight become Common traits and the secondary reveal stays a bond reward) is an F30 implementation choice flagged in §12.

Acceptance: F30#0–#4.

## 7. Move acquisition, loadout and mastery (F23, F35, RD-11, RD-27)

**Ownership split.** COMBAT owns the in-fight verbs: slot inputs (X quick, Y charged tap-start, B utility, RB + face ultimate, A dodge), timings, damage, utility effect geometry, the ultimate meter and presentation. TRAINING owns how moves are acquired and grow. **Current:** one quick and one charged move per species (`species.json::moves`), primary-type TMs (`data/moves/tms.json`, `scripts/creatures/teaching.gd`).

- **Loadout:** each creature holds `{quick, charged, utility, ultimate}` plus a mastery map. **Superseded (owner, 2026-09-29, RD-11):** the one-quick-one-charged set and the parked L4 Y-skill candidate.
- **Learnsets** (`data/moves/learnsets.json`, all 57 species plus the storm bear): base quick and charged at L1; utility options at L5 and L15; further options at breakthroughs. A creature caught above an unlock level already knows those options. TMs keep the primary-type rule and are consumed on use.
- **Editing:** loadouts change only at the Altar or a forward camp, never in the field or in combat.
- **Mastery:** each known move has rank 1–5, rising with landed uses (starting thresholds 0 / 25 / 75 / 150 / 300 landed uses, `data/config/move_mastery.json`). Each rank raises that move's damage (starting +5% per rank) and upgrades its effect tier (COMBAT/F25 presentation). Mastery belongs to the creature and survives evolution and relearning.
- **Ultimates:** unique for starters, legendaries and evolved forms (RD-27; the list is in CREATURES §4); every other species maps to a shared type × role ultimate. Each ultimate grows visibly at every completed breakthrough tier (F35#2).

Acceptance: F23#0–#5, F35#0–#4.

## 8. Research log (F45, RD-31)

Every species has at least three research tasks in `data/config/research.json` (for example: see its signature move, catch one at night, defeat three). Each task pays that species' type essence once per character (starting 5–15 by task difficulty). A biome's completion percentage appears in the journal; 100% grants a title or cosmetic, never combat power beyond the essence. Released and never-kept creatures count; nothing requires keeping a sixth. Credit comes from host-validated encounter events; each fight participant earns their own credit. Acceptance: F45#0–#3.

## 9. Starter traversal and Ripplet swim/dive (F37, RD-32)

| Starter | Traversal | Where |
|---|---|---|
| Terrapup | Ride (current) | Meadows onward |
| Ripplet | Surface swim mount; **Dive** at its L30 breakthrough | Tidewake onward |
| Galewisp | Fly (held input allowed) | Cloudreach onward |

The Home Key provides fast travel (WORLD). Ripplet's traversal unlocks remain on that owned creature's breakthrough history (RD-32).

The owned Ripplet can be ridden on the surface from Tidewake's opening, faster than human swimming and able to cross currents (starting values in `data/config/water_mounts.json`, beside the five existing water adapter mounts). Dive is a tap toggle to submerge and surface, never a held button, reaching optional sunken caches, nodes and routes. **Every required water route stays human-swimmable without Ripplet.** Because starters are exclusive, only the starter Ripplet ever gains Dive. Acceptance: F37#0–#4.

## 10. Co-op scope and authority

Every row: the host validates; the client requests. Character scope travels with the portable character; world scope stays in the host's world save.

| State | Scope | Authority | Transaction / duplication rule | Save and reconnect |
|---|---|---|---|---|
| Essence and Tether Candy items | character | host grants from its own event | Payout keyed to the source event id; a replayed event pays nothing | Saved with character inventory; rejoin resends nothing already acknowledged |
| Altar level spend | character (creature) | host, at an Altar in the host world | Spend id applied once; items and level change atomically | Uncommitted spend on disconnect is discarded, never half-applied |
| Release payout and seed distil | character | host | `release:<uid>`; a uid pays and distils once | The release journal survives reload so a retry cannot pay twice |
| Cap and breakthrough tiers | character (creature) | host | `feast:<uid>:<tier>` | Saved per creature |
| Master win and recipe | character | host records the winner of each 1v1 | Once per character per tier | Receipt persists; rejoin does not re-offer |
| Master arena availability and rematch | world | host | Rematch rewards follow F44's cycle | World save |
| Evolution choice | character (creature) | host | Bound to the feast transaction; evolve or stay is recorded once per tier | Saved per creature |
| Rolled traits on a wild | world until caught | host rolls at spawn | Traits copy into the creature on the catch transaction | Uncaught wilds follow ordinary respawn |
| Taught traits and Trait Seeds | character | host | Teach id consumes one seed once | Saved per creature and inventory |
| Loadout, mastery | character (creature) | host validates edits at Altar/forward camp; mastery credited from host hit events | Hit events count once | Saved per creature; F23#3 two-peer rejoin |
| Research progress | character | host credits from encounter events | Each task pays once per character | Saved with character |
| Ripplet mount and Dive unlock | character (creature) | host validates mount and dive state | — | Survives reload and rejoin (F37#4) |

A guest uses the host's Altar and Kitchen at the host's attachment tier and keeps what they craft or spend (RD-21); cooking a feast still needs the guest's own recipe (HOMESTEAD co-op reading). Recipes, trait slots and breakthroughs never transfer between characters. Two-peer duplication proof is F27#4, F28#4 and F48#1.

## 11. Data, tunables and non-goals

New tunable files: `data/config/essence.json`, `masters.json`, `traits.json`, `research.json`, `move_mastery.json`, `evolution_lines.json`; `data/recipes/feasts.json`; `data/moves/learnsets.json`. F16 authors their schemas; loaders fail loudly on unknown ids. Saves reset for this redesign (RD-35), so the new fields need no migration from v27; every later change resumes migration discipline.

Out of scope: breeding, IV rerolls, creature storage or a sixth slot, respec currency, skill trees, trading traits or recipes between players, offline production, creature expeditions, levels above 60 in this pass, evolving starters or legendaries.

## 12. Open questions and the defaults taken

CODEX_START_HERE §8.1 sets conservative defaults for items 1–3 and 5. Lanes build these until the owner changes one:
1. **Default:** Good, Great and Rare Candy stay as level items and respect caps.
2. **Default:** a creature caught above a cap counts lower tiers as cleared (§2 rule). Evolution offers are not retroactive.
3. **Default:** each co-op character wins its own 1v1. Others may watch but not join.
4. Mapping of the eight personality traits and the bond secondary into the new pool (§6). This is an F30 implementation choice; the proposal is Common traits.
5. **Default:** taught trait slots are extra to the 0–3 rolled traits. Starters roll traits like any creature.
6. The storm bear's final name (owner item).
