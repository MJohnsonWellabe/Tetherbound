# CODEX_START_HERE — The Redesign Build (Waves 0–3)

**Owner-authorized build plan, from the owner design interview of 2026-09-29.** This
file supersedes the Phase 1 brief (`CLAUDE_START_HERE.md`, now a pointer here) and the
old Phase 2 visual brief that stood in this file. Every agent, Codex or Claude, works
from this plan. AGENTS.md/CLAUDE.md still govern hard rules and precedence; they
were updated the same day to carry the owner changes listed in §1. STATE records
status; this file records the plan. Do not write status here. Update STATE and the board.

**Goal:** turn Tetherbound into a game people choose to play and keep playing.
Every visual fix targets the full game bar (Palworld/Animo-class creatures and world, with
Valheim-class light and atmosphere), not just passing the defect. The creature game
gets the draw it is missing: a loop that is fun to grind, where the player is always
building the best five-creature team.

**Definition of done:** the whole plan is done, meaning every criterion F16–F49 in ACCEPTANCE §6.2
is met on `main`, plus the still-open F01–F15 criteria (closed or formally superseded
with evidence). The work spans many nights. Lanes resume from STATE and the board,
never from memory.

---

## 0. Read order and ground rules for every lane

1. `AGENTS.md` (Codex) or `CLAUDE.md` (Claude). They are identical, and they hold the hard rules and precedence.
2. This file: §1 decisions, §2 the game, §3 system specs, §4–§6 your lane.
3. `docs/STATE.md` §0 for what already landed, then the board
   (`ralph/reports/COORDINATOR/dashboard/criteria.json`) for your rows.
4. Your feature's criteria in `docs/ACCEPTANCE.md` §6.2, and the owning design contract
   named in the register (§5). New contracts: `docs/design/TRAINING.md` (creature
   power) and `docs/design/HOMESTEAD.md` (stations, materials, gear, camps).
5. Restore the reference boards in a fresh container before any visual judging:
   `git ls-files -v docs/reference | grep '^S' | cut -c3- | xargs git update-index --no-skip-worktree && git checkout -- docs/reference`.

Ground rules (unchanged unless §1 says otherwise):
- Multiplayer-native from the first commit. Declare authority, scope (world or character),
  transaction ids and save behavior before polish.
- Tunables go in `data/config/*.json`, never literals in scripts.
- New modals join `input_owner`. No held-button gameplay (Fly and the Home Key's tap animation are fine).
- The five-creature cap stays: no storage, no sixth, no loaner loophole.
- The human never deals damage (Tether Commands are support only).
- No hunting, butchering, automation or factory. Nothing produces while the player is away.
- Oxblood/red stays reserved for Team Tether.
- An agent's self-report is not verification. Every criterion closes on evidence plus an
  independent strict re-check (§7).

---

## 1. Owner decisions (2026-09-29), numbered for citation as RD-nn

| # | Decision |
|---|---|
| RD-01 | **Grind philosophy reversed (option B).** A loop that is fun to grind but optional to repeat. Each biome needs real preparation (gather, train, craft, build). The main path is finishable without padding; players who grind get clearly stronger. Target **15–25 h** normal clear. This replaces the "8 good hours / no grind" rule. |
| RD-02 | **The spine is creature power.** Building the best five is the goal. The homestead is the *required engine* that produces creature power (gear, feasts, essence, moves). |
| RD-03 | **Hybrid leveling.** Combat still gives reduced automatic XP. Essence and candy, spent by choice at the Altar, is the main path. **Level caps every 10 levels** need a breakthrough. |
| RD-04 | **Per-type essence** (8 types) plus rare generic **Tether Candy** from bosses and Masters. |
| RD-05 | **Essence sources:** defeating wilds, releasing caught creatures (by type), attuned gathering nodes, essence farming (type crops), research tasks, a small capped care trickle. **Not** training trials, **not** creature expeditions. |
| RD-06 | **Breakthrough quest (owner's design).** Travel to a Master, win a **1v1**, the chest teaches an **Ascension Feast** recipe; gather, cook and feed to break the cap. |
| RD-07 | **One Master per tier; recipe learned once per character.** The feast needs that biome's materials plus **one type-attuned ingredient matching the creature**. The 1v1 uses a creature of the player's choice. Recipes are personal in co-op. |
| RD-08 | **Caps at L10, 20, 30, 40, 50.** L10 sits mid-Meadows. Level ceiling **60** this pass. Data supports tiers to **100** for biomes 5–8. |
| RD-09 | **Plan for eight biomes.** Portal hall has 8 portal slots (4 dormant), shrine room 8 pedestals, material and gear schemas 8 tiers. Biomes 5–8 are not built in this pass. |
| RD-10 | **Level bands (new order):** Meadows 3→22, Tidewake 20→33, Cloudreach 31→44, Stormwood 42→55 (§3.3). Portal signs show recommended level; the portal key is the only hard gate. |
| RD-11 | **Moves: three slots plus a signature ultimate** (quick, charged, utility, ultimate), species learnsets, TMs kept, **move mastery 1–5**. |
| RD-12 | **Tether Commands.** The trainer gets support actions on a meter filled by creature hits: item throw, Rally, tag-switch combo, Tether Snare. Upgraded through homestead trainer gear. **The human still never deals damage.** |
| RD-13 | **Combat rework targets:** impact (hitstop, knockback, reactions, numbers), spectacle (move effects), enemy patterns and telegraphs, anti-mash, role distinction, fight camera. Benchmark: Palworld- and Monster-Hunter-class fun. |
| RD-14 | **Creature gear:** Harness plus Charm, crafted in biome tiers. **Trainer gear** protects only against the trainer's actual hazards (falls, storm static, cold heights, drowning and currents, hazard terrain) and upgrades Tether Commands. Materials come from gathering, farming, mining and *shed* drops, never butchering. |
| RD-15 | **Homestead at Grandpa's farm plus forward camps.** Big stations only at home. Forward camps in any biome hold a bed, portable cookpot and field workbench (travel tier only). |
| RD-16 | **Six stations, kept simple:** Workbench, Forge, Kitchen, Altar (includes training, loadouts, mastery), Den, Farm, plus chests. **Only Forge, Kitchen, Altar and Den take upgrades: exactly one attachment per biome.** Each station shows one "next upgrade". Owner caution: do not overcomplicate. |
| RD-17 | **Village stays inside the Meadows.** The **Crossing Hall** at the end of the village road holds the home arch plus 7 portal arches (3 live, 4 dormant) and the Shrine Room. The physical crossings between biomes are retired. |
| RD-18 | **Home Key** from Grandpa at the start, in the backpack. Tap to use: the trainer raises the key (~2 s) and arrives at the Hall's home arch. Free, **no cooldown**. Not usable in combat, dialogue, cutscenes, swimming or mid-flight. Personal to each player. Cannot be dropped, sold or lost. |
| RD-19 | **Waystones:** 3–5 per biome, touch to activate. A portal returns you to your last activated waystone in that biome. |
| RD-20 | **Shrine Room:** hanging a biome relic is required. It unlocks the **next tier's** homestead recipes and attachments; the Meadows tier is available from the start, so each boss is fought with its own biome's gear. The player then carries **one** chosen relic power (the existing one-active rule). The boss drops the next **portal key as a real item**, used once on its arch. |
| RD-21 | **Co-op:** every fight participant gets their own key and relic. A portal is open for the whole session if **the host world or your own character** has unlocked it. Station buildings are world-owned; tiers and recipes are personal. A guest uses the host's stations at the host's tier and keeps what they craft. |
| RD-22 | **Ending:** Tidewake's dock exchange stays as Tidewake's chapter close. After the Stormwood finale the player **uses the Home Key** for Grandpa's homecoming, then credits. Stormwood drops a **fifth portal key**: using it makes the fifth arch *stir* but not open. It is not a cliffhanger. This overrides the Bible's "no fifth-chapter tease" line. |
| RD-23 | **Move effects: about 24 archetypes with real objects** (pebbles, boulder, fireball, lightning bolt from the sky…) plus bespoke ultimates, within an Ally performance budget. |
| RD-24 | **Art target: Palworld/Animo-style creatures and world plus Valheim lighting and atmosphere.** |
| RD-25 | **Renderer:** build a Forward+ path with Low (Compatibility)/Medium/High presets. It becomes the default only after the **owner's ROG Ally test** passes (Medium handheld ≥30 fps, 40 preferred). |
| RD-26 | **Meshy overnight:** a bounded agent-attended batch of **about 25–30 named priority assets**, **30 generations per night cap**. Each needs a drafted reference, scale check, code-blind before/after judge and provenance; failures stay flag-off. This replaces the "no unattended generation batches" restriction for this list. |
| RD-27 | **Ultimates:** unique for **starters, legendaries and evolved forms**. Everyone else shares a type×role ultimate. |
| RD-28 | **Starters do not evolve.** **One evolution line per biome**, all at breakthrough feasts, evolving optional: Mudsnout→Tuskroot/Ashtusk (L20), Mosshell→Cannonback (L30), Craghorn→Stormcapra (L40), **Staticub→a new Stormwood storm bear** (L50, a new creature via the Meshy workflow; working name *Stormursa*). Tuskroot moves to the L20 feast. |
| RD-29 | **Village layout:** one straight road. The homestead is at the start by the Meadows exit, 8–10 houses line both sides, and the Crossing Hall caps the far end, visible from the farm. |
| RD-30 | **Traits:** 0–3 rolled traits in three rarities. Releasing a creature distils one into a **Trait Seed**, taught to your five in slots unlocked at L10/L30/L50 breakthroughs. Traits come to your five; there is no pressure to replace them. |
| RD-31 | **Repeatables, all four:** bounty board (3 rotating each morning), trainer, captain and Master rematches (next-biome level; leaders at L55–60 after credits), alpha respawns with fresh traits, research log completion. This overrides "no enemy scaling tier after the ending". |
| RD-32 | **Starter traversal:** Terrapup rides (Meadows). **Ripplet swims (surface mount in Tidewake) and Dives at its L30 breakthrough.** Galewisp flies (Cloudreach). Ripplet's old Teleport promise is dropped; the Home Key does fast travel. Required water routes stay human-swimmable. |
| RD-33 | **Material tiers reuse existing items** (§3.4). |
| RD-34 | **This plan supersedes Phase 1 and Phase 2.** Still-valid open rows fold into the new features. Obsolete ones close as "superseded by owner redesign 2026-09-29" with the replacing criterion cited. |
| RD-35 | **Saves reset.** v27-and-older saves are refused with a clear message. This is an owner override of the migration hard rule, for this redesign only. Migration discipline resumes for every later change. |
| RD-36 | **Minimum necessary testing; batch validation (owner, 2026-09-29).** Prioritize content and code generation. Run only checks needed for acceptance or to prevent substantial rework; batch them across coherent changes and reuse passing evidence when the relevant source and path are unchanged. This supersedes the per-criterion full-suite repetition and strict one-criterion work queue. Related criteria may share a reviewable implementation/validation batch, but each retains its own evidence and independent verdict. Save preservation, multiplayer authority/transactions, required real player paths, code-blind visual judgments and named acceptance proofs remain required. Never skip, disable or quarantine tests to get green. |
| RD-37 | **Selective checks; keep implementation moving (owner, 2026-09-29).** Unit tests and full CI are not defaults for every change/PR. Use only named acceptance proofs or substantial-rework-risk checks, with reuse of relevant passing evidence. Full suites/full CI require an explicit acceptance need or integration risk that scoped checks cannot cover; a process-only green never proves engine behavior. Work on independent next tasks while validation/CI runs, on lane branches against a pushed dependency candidate where needed; land only after required dependencies. Keep ownership, serialized import/render/export and no test skipping/disabling/quarantine. |

Carry-over owner rules that still apply: five owned total, catch only in wild combat,
starters exclusive, per-participant legendary offers, light satiety with no starvation
death, stack/slot inventory without carry weight, multiple death satchels, creatures
taller than the 1.80 m trainer, reuse of the installed humanoid cast, and the Claude/Codex
art split (Codex owns new meshes and Meshy; Claude may kitbash installed families).
Internet co-op needs invitation joining (Steam) and is still an open owner resource item.

---

## 2. The game after the redesign (what a player experiences)

You start at Grandpa's farm at the head of a single village road. Houses line it on
both sides, and a huge stone **Crossing Hall** closes the far end. Grandpa gives you your
starter, a **Home Key** and a patch of land. You catch, camp and win the village
tournament as before. Then you walk out across the South Bridge into the Meadows.

**The loop (15–30 minutes, repeated):** pick a goal (a Master, a material, a bounty,
the next boss). Portal out to your last waystone. Fight, catch and release, gather
nodes, harvest shed drops, tick research tasks. When your bag is full or your team is
tired, **tap the Home Key**: you raise it, light floods, and you stand in the Hall.
Walk up the road to your homestead. Refine ore at the Forge, cook at the Kitchen,
spend essence at the Altar to level the creature you chose, swap loadouts, teach a
Trait Seed, plant type crops. Then portal back out.

**Progression you can feel:**
- **Levels** come mostly from essence you choose to spend; combat XP trickles.
- **Every 10 levels a creature hits a cap.** The next Master waits somewhere in the
  world. Win a 1v1 with a creature you pick, open the Master's chest, learn that tier's
  **Ascension Feast**. Gather its materials plus one ingredient matching your
  creature's type, cook it and feed it: the cap breaks. Four species can **evolve** at their feast.
- **Moves:** quick, charged and utility slots plus a **signature ultimate** that grows at
  each breakthrough; learnsets, TMs, mastery ranks 1–5 with visibly bigger effects.
- **Gear:** a Harness and a Charm per creature, one tier per biome from the Forge. Each biome's boss is
  meant for that tier.
- **Traits:** hunt wild creatures with rare traits, release them, distil a seed, teach
  your five.
- **The trainer:** fights beside the team with **Tether Commands** (no damage) and wears
  gear against falls, storms, cold and currents.

**Biomes (new order):** Meadows → **Tidewake** → Cloudreach → Stormwood. Each boss
drops a relic and the next portal key. Hanging the relic in the Shrine Room upgrades
your homestead's stations. The Stormwood finale ends with **you using the Home Key to
go home**. Grandpa names your five, the credits roll, and the fifth arch *stirs*. After
the credits: bounties, rematches, alpha respawns and research completion.

---

## 3. System specifications (summary; owning contracts hold the detail)

### 3.1 Creature power: TRAINING.md (new), CREATURES, PROGRESSION
- **Essence:** 8 type items (`essence_ground` … `essence_psychic`) plus `tether_candy`.
  Spending at the Altar raises a chosen creature's level. Cost per level comes from config and
  rises with level. Dual types may pay in either type. Starters use their type.
- **Auto XP:** the existing award formula × `auto_xp_scale` (start at 0.35, tune in F47). The
  rest bonus stays.
- **Release payout:** `release_essence_base + per_level × level` of the creature's type(s),
  once per creature uid (transaction id).
- **Caps and breakthroughs:** `level_caps = [10,20,30,40,50,60]` live, and
  `[70,80,90,100]` are reserved. A capped creature banks no XP beyond the cap (the display says
  "breakthrough needed").
- **Masters:** five named 1v1 fights (§3.3 table). Win → chest → feast recipe (character
  scope, once). Retryable. A Master fight uses one creature chosen at the arena.
- **Feast:** `feast_tN` = tier materials + `attuned_<type>` ingredient. Kitchen only.
  Feeding one feast to one creature lifts its cap one tier and offers evolution where a line exists.
- **Evolution lines:** RD-28. Evolving keeps identity (uid, nickname, level, bond, IVs,
  traits, mastery).
- **Traits:** about 30 traits; 0–3 per wild creature; Common/Rare/Epic. Alphas, night and weather
  roll better. Distil on release at the Altar. Slots unlock at L10/L30/L50. Teaching costs
  essence.
- **Research log:** at least 3 tasks per species; pays type essence; biome completion titles.

### 3.2 Homestead: HOMESTEAD.md (new), SYSTEMS
- **Plot:** Grandpa's farm, at the head of the road. The existing home/camp pieces
  (tent, campfire, bedroll, beds, floor, walls, roof) stay.
- **Stations:** Workbench (tools, building, trainer gear, forward-camp kit), Forge (refine
  ingots; Harness; tool upgrades), Kitchen (meals, buff food, feasts), Altar (essence spend,
  loadouts, mastery, traits, charms), Den (rest, happiness, grooming shed drops, gear display),
  Farm plots (type crops; the Greenhouse is a Farm buildable, not an attachment), chests.
- **Attachments (one per biome, Forge/Kitchen/Altar/Den only):**

| Station | Meadows | Tidewake | Cloudreach | Stormwood | 5–8 |
|---|---|---|---|---|---|
| Forge | Bellows | Tide quench tank | Wind furnace | Storm coil | reserved |
| Kitchen | Spice rack | Smoker | Cold cellar | Storm oven | reserved |
| Altar | Meadow lens | Tide lens | Sky lens | Storm lens | reserved |
| Den | Straw bedding | Hot spring | Cliff perches | Grounded bedding | reserved |

  Meadows attachments are available from the start. Hanging a biome's relic unlocks the **next** column
  (Meadows relic → Tidewake attachments, … Stormwood relic → reserved tier 5), so gear for a biome is
  craftable from that biome's materials before its boss. Each attachment gates that tier's recipes.
- **Forward camps:** kit from the Workbench. Bed, portable cookpot and field workbench. Travel-tier
  recipes only.
- **No automation:** crops need planting and harvesting by hand; the Forge smelts only while the
  player interacts (a short timed interaction, not an offline queue).

### 3.3 World, hub and order: WORLD, BOSSES
- **Village:** RD-29 layout. Named residents in every house. Halda's tournament board and
  bounty board, Mira's shop, Tam's workshop, the inn, the research keeper.
- **Crossing Hall:** nave (home arch plus 7 portals: Tidewake, Cloudreach, Stormwood live;
  biome 5–8 sealed), Shrine Room (8 pedestals). It is the tallest village landmark.
- **Home Key, portal keys and waystones:** RD-18..RD-21.
- **Level table and Masters:**

| Biome | Team in→out | Wild | Boss team | Master (unlocks) | Boss drops |
|---|---|---|---|---|---|
| Meadows | 3→22 | 2–20 | Warden ~21–22 | L10 mid-Meadows (River Lock/Quarry); L20 upper meadows before the Warden's stronghold | Heart of the Meadows relic + Tidewake portal key |
| Tidewake | 20→33 | 18–32 | Nerissa ~32–33 | L30 outer island | Tideglass relic + Cloudreach portal key |
| Cloudreach | 31→44 | 29–43 | Veyra ~43–44 | L40 high perch (Fly) | Wings relic + Stormwood portal key |
| Stormwood | 42→55 | 40–54 | Finale ~54–55 | L50 deep storm | Spark relic + fifth portal key |

- **Ending:** RD-22. **Repeatables:** RD-31.

### 3.4 Materials (RD-33, existing ids reused)

| Tier | Biome | Raw | Forge output | Harness | Charm base |
|---|---|---|---|---|---|
| 1 | Meadows | wood, stone, fiber, rootstone, ironwood, sunleaf | Rootiron ingot | Rootiron Harness | Sunleaf charm |
| 2 | Tidewake | driftwood, reed_fiber, reef_stone, sluice_metal, tide_bloom, + Tide Pearl (new) | Tidesteel ingot | Tidesteel Harness | Pearl charm |
| 3 | Cloudreach | windworn_heartwood, cliffglass_ore, gale_fiber, skyplume, cloudberry | Skyglass ingot | Skyglass Harness | Plume charm |
| 4 | Stormwood | thunderwood, stormglass, conductor_vine, glowmoss, sparkfur, voltcap | Stormglass plate | Stormglass Harness | Spark charm |
| 5–8 | future | reserved | reserved | reserved | reserved |

Shed items (skyplume, sparkfur and similar) come from wins and Den grooming. The heartstone and sunstone evolution stones become Mudsnout
feast ingredients. Attuned (type) ingredients: `attuned_ground` … `attuned_psychic`, from
essence nodes and type crops.

### 3.5 Combat and effects: COMBAT, BOSSES, UX, AUDIO
- **Slots:** X quick, Y charged (tap-start), B utility, RB + face = ultimate when the meter is full, A
  dodge/burst. Tether Commands on the d-pad (or LB + face), filled by the piloted creature's hits.
- **Impact:** hitstop by move weight, knockback, reaction pose, damage numbers (crit,
  super-effective and resisted styles), stagger on poise break, shake and rumble (toggles).
- **Enemies:** each role has at least 2 patterns with telegraphs. Wilds reposition, dodge and punish.
  Named fights get distinct patterns (BOSSES).
- **Effect archetypes (about 24):** pebble/rock/boulder throw; fireball; flame cone; ember burst;
  sky lightning strike; chain lightning arc; water jet; bubble volley; tidal wave; wind
  blade; tornado; ice shard volley; frost breath; shadow bolt; psychic pulse; root/stone
  spikes; quake ring; claw/bite slash trail; charge-dash trail; heal pulse; buff aura;
  debuff hex; guard flash (a visual only, since blocking does not exist); catch/tether beam. Every move maps to one;
  the parameters distinguish pebble toss (3 small stones) from rock throw (1 boulder).
- **Ultimates:** shared type×role set (16–20) plus unique ones for starters, legendaries
  and evolved forms (RD-27).

### 3.6 Visual bar: ART_DIRECTION, ACCEPTANCE §4
- **Bars A/B are redefined** as: *Palworld/Animo-class creature and world appeal, and
  Valheim-class light and atmosphere, judged at ordinary gameplay distance*. The code-blind
  judge compares against the per-biome reference boards and the look bar that F26 writes.
- **Codex catalog:** `ralph/reports/VISUAL/phase2/catalog.csv` has 116 rows, 106 of them with impact >12, plus
  `{biome}/top20.csv`. Recurring themes: terrain landforms, landmark identity, creature
  poses and scale, fight and catch camera, magenta effects, UI, item identity, NPC silhouettes.
  Re-score after F26. Every item >12 is fixed to the full bar (F38–F41), one or two items
  per PR, in impact order. Deferral is not a status. A blocked item stays open with an owner.
- **Meshy:** RD-26. The priority list and provenance live in ART_DIRECTION. Log every task id.

---

## 4. Waves and lanes

Lanes in the same wave run in parallel **only on disjoint files** (the owned paths in §6).
A shared file (combat_manager, HUD, species.json, items.json, project.godot) has one
owning lane per wave. Others request an edit through STATE's WIP list, or wait for it to land.
Godot import, render and export writers are serialized (one at a time per machine).

| Wave | Lanes (branch) | Starts when |
|---|---|---|
| 0 | `tb/foundations` (F16) | now |
| 1 | `tb/hub` (F17, F18), `tb/reorder` (F19, F20), `tb/combat` (F21–F24), `tb/vfx` (F25, later F35), `tb/lookdev` (F26) | F16 landed for landing; RD-37 permits branch implementation against the pushed F16 candidate while its checks/CI run |
| 2 | `tb/training` (F27–F30, F37), `tb/homestead` (F31–F34), `tb/creature-art` (F36), `tb/visual-meadows`, `tb/visual-tidewake`, `tb/visual-cloudreach`, `tb/visual-stormwood` (F38–F41), `tb/hud` (F42) | their dependencies in §6 landed |
| 3 | `tb/loop` (F43–F46), `tb/balance` (F47), `tb/coop` (F48), `tb/release` (F49) | Waves 1–2 feature-complete |

A **board duty** (not a coordinator; lanes still self-land) rotates to whichever lane lands next after each hour mark. It rebuilds the board and
pushes it (§7.3).

---

## 5. Feature register

| ID | Feature | Wave | Lane | Player outcome | Owning spec | Criteria |
|---|---|---|---|---|---|---:|
| F16 | Foundations: save reset, schemas and biome order | Wave 0 | `tb/foundations` | One schema and one biome-order config every later lane builds on; old saves are refused cleanly. | TECHNICAL §4–5, MULTIPLAYER, TRAINING, HOMESTEAD | 5 |
| F17 | Village road and the Crossing Hall | Wave 1 | `tb/hub` | The village is one straight road lined with houses, the homestead at its start and the giant Crossing Hall capping the far end. | WORLD (hub), ART_DIRECTION, UX | 7 |
| F18 | Home Key, portal keys and waystones | Wave 1 | `tb/hub` | Grandpa's Home Key returns you to the Hall from anywhere; boss keys open portals; waystones send you back out where you left off. | WORLD (hub/fast travel), UX, MULTIPLAYER | 6 |
| F19 | Biome reorder and level curve | Wave 1 | `tb/reorder` | Meadows → Tidewake → Cloudreach → Stormwood with re-derived levels, keys and relic hand-offs. | PROGRESSION §3, WORLD, BOSSES, CREATURES | 6 |
| F20 | Ending after Stormwood and the fifth key | Wave 1 | `tb/reorder` | Tidewake resolves its own chapter; the Stormwood finale leads home by the Home Key to Grandpa, credits and a stirring fifth arch. | GAME_BIBLE §5, WORLD, UX, AUDIO | 5 |
| F21 | Combat impact and camera | Wave 1 | `tb/combat` | Hits land: hitstop, knockback, reactions, damage numbers, crits and a camera that keeps the fight readable. | COMBAT, UX, AUDIO | 6 |
| F22 | Enemy patterns, anti-mash and role identity | Wave 1 | `tb/combat` | Enemies telegraph learnable patterns, mashing loses, switching matters and each role plays differently. | COMBAT, BOSSES, CREATURES | 5 |
| F23 | Move loadout: three slots, ultimate, learnsets and mastery | Wave 1 | `tb/combat` | Each creature fights with quick, charged and utility moves plus a signature ultimate, learns moves and masters them. | COMBAT, CREATURES, TRAINING, UX | 6 |
| F24 | Tether Commands (trainer support, no damage) | Wave 1 | `tb/combat` | The trainer supports the fight with a command meter: item throw, Rally, tag-switch combo and Tether Snare. | COMBAT, UX, MULTIPLAYER | 6 |
| F25 | Move effects library (real pebbles, fireballs, lightning) | Wave 1 | `tb/vfx` | Every move shows its real object: pebbles fly, fireballs burn, lightning strikes from the sky. | COMBAT (presentation), ART_DIRECTION, AUDIO | 6 |
| F26 | Renderer and look development (Palworld + Valheim bar) | Wave 1 | `tb/lookdev` | A Forward+ look with quality presets delivers Valheim-class light and atmosphere around Palworld-class creatures and world. | ART_DIRECTION, TECHNICAL §10, ACCEPTANCE §4/§7 | 6 |
| F27 | Type essence and chosen leveling | Wave 2 | `tb/training` | Eight type essences and Tether Candy let the player choose who grows; combat XP still trickles. | TRAINING, PROGRESSION, CREATURES | 6 |
| F28 | Breakthroughs, Masters and Ascension Feasts | Wave 2 | `tb/training` | Every ten levels a creature needs a breakthrough: beat a Master 1v1, earn the feast recipe, gather, cook and feed. | TRAINING, BOSSES (Masters), HOMESTEAD (Kitchen), WORLD | 6 |
| F29 | Evolution lines (one per biome) | Wave 2 | `tb/training` | Mudsnout, Mosshell, Craghorn and Staticub can evolve at breakthrough feasts; evolving is optional. | CREATURES, TRAINING, ART_DIRECTION | 5 |
| F30 | Traits and Trait Seeds | Wave 2 | `tb/training` | Wild creatures roll traits; releasing one distils a Trait Seed you teach to your five. | TRAINING, CREATURES, UX | 5 |
| F31 | Homestead stations and upgrades | Wave 2 | `tb/homestead` | Six stations at Grandpa's farm; four of them take one upgrade per biome; Meadows upgrades are open from the start and each hung relic unlocks the next biome's. | HOMESTEAD, UX, MULTIPLAYER | 7 |
| F32 | Materials, attuned nodes and essence farming | Wave 2 | `tb/homestead` | Each biome has its material tier, rare type-essence nodes and crops worth planting. | HOMESTEAD, SYSTEMS, WORLD, PROGRESSION | 6 |
| F33 | Creature gear and trainer gear | Wave 2 | `tb/homestead` | Harness and Charm tiers make each biome's gear matter; trainer gear protects against the trainer's real hazards. | HOMESTEAD, COMBAT, SYSTEMS | 5 |
| F34 | Forward camps | Wave 2 | `tb/homestead` | A small travel-tier camp you can build in any biome: bed, cookpot and field workbench. | HOMESTEAD, SYSTEMS | 5 |
| F35 | Signature ultimates | Wave 2 | `tb/vfx` | Starters, legendaries and evolved forms get unique ultimates; everyone else shares a type-and-role ultimate. | COMBAT, CREATURES, ART_DIRECTION, AUDIO | 5 |
| F36 | Creature art: priority models, poses and scale | Wave 2 | `tb/creature-art` | The creatures players see most look and move like they belong in a Palworld-class game. | ART_DIRECTION, CREATURES | 4 |
| F37 | Ripplet swim and dive | Wave 2 | `tb/training` | Ripplet becomes a swim mount in Tidewake and learns to dive at its L30 breakthrough. | CREATURES, WORLD, SYSTEMS | 5 |
| F38 | Meadows and village: visual catalog burn-down to the full bar | Wave 2 | `tb/visual-meadows` | Meadows and village looks like a game people want to play: every catalog defect scored over 12 fixed against the full bar, not just past the defect. | ART_DIRECTION, ACCEPTANCE §4, ralph/reports/VISUAL/phase2/catalog.csv | 6 |
| F39 | Tidewake: visual catalog burn-down to the full bar | Wave 2 | `tb/visual-tidewake` | Tidewake looks like a game people want to play: every catalog defect scored over 12 fixed against the full bar, not just past the defect. | ART_DIRECTION, ACCEPTANCE §4, ralph/reports/VISUAL/phase2/catalog.csv | 6 |
| F40 | Cloudreach: visual catalog burn-down to the full bar | Wave 2 | `tb/visual-cloudreach` | Cloudreach looks like a game people want to play: every catalog defect scored over 12 fixed against the full bar, not just past the defect. | ART_DIRECTION, ACCEPTANCE §4, ralph/reports/VISUAL/phase2/catalog.csv | 6 |
| F41 | Stormwood: visual catalog burn-down to the full bar | Wave 2 | `tb/visual-stormwood` | Stormwood looks like a game people want to play: every catalog defect scored over 12 fixed against the full bar, not just past the defect. | ART_DIRECTION, ACCEPTANCE §4, ralph/reports/VISUAL/phase2/catalog.csv | 6 |
| F42 | HUD, menus and new-system screens | Wave 2 | `tb/hud` | Controller-first screens for the Altar, stations, gear, research and bounties; the HUD reads on a 7-inch screen. | UX, ACCEPTANCE §6.1 device profile | 4 |
| F43 | Bounty board | Wave 3 | `tb/loop` | Halda's board always has three bounties worth doing. | WORLD, PROGRESSION, MULTIPLAYER | 4 |
| F44 | Rematches and alpha respawns | Wave 3 | `tb/loop` | Beaten biomes stay worth visiting: stronger rematches and fresh alphas. | BOSSES, WORLD, PROGRESSION | 4 |
| F45 | Research log | Wave 3 | `tb/loop` | Species-by-species research turns meeting creatures you won't keep into progress. | CREATURES, UX, PROGRESSION | 4 |
| F46 | Onboarding for the new systems | Wave 3 | `tb/loop` | Grandpa and the village teach each new system when it first matters. | UX, WORLD | 3 |
| F47 | Economy, balance and the 15–25 hour clear | Wave 3 | `tb/balance` | The whole loop pays off: solvent ledgers, fair difficulty and a 15–25 hour normal clear. | PROGRESSION, COMBAT, HOMESTEAD, TRAINING | 5 |
| F48 | Co-op across the new loop | Wave 3 | `tb/coop` | Friends play the whole new loop together without losing or duplicating progress. | MULTIPLAYER | 4 |
| F49 | Integrated four-biome run and release proof | Wave 3 | `tb/release` | One save plays the new game from Grandpa to credits, on the device that matters. | ACCEPTANCE §6–§7, WORKFLOW | 4 |

**34 features, 179 criteria.** The board now counts 101 + 179 = 280 criteria.

Criteria text for every row is in ACCEPTANCE §6.2 and on the board. The board lists the
same criteria, numbered from zero (`F27#3`).

---

## 6. Work orders per feature

### F16 · Foundations: save reset, schemas and biome order  (`tb/foundations`)

- **Outcome:** One schema and one biome-order config every later lane builds on; old saves are refused cleanly.
- **Depends on:** —
- **Owns:** scripts/save/**, autoload/game_state.gd (schema only), data/config/biome_order.json (new), data/schema/** (new), scripts/data/**, flag_scopes registry, tests/test_save_*.gd, tests/test_schema_*.gd
- **Build:**
  1. Bump SaveGame.VERSION (27 → 28) and CharacterSave; replace every migration path from ≤27 with a refusal that returns a typed 'incompatible_old_version' result; the title screen shows the message and offers New Game; the old file stays on disk untouched.
  2. Add data/config/biome_order.json: live [meadows, tidewake, cloudreach, stormwood], reserved [biome5..biome8] with display names 'Sealed'. Route every realm-order read (realm_hearts.json order, map realm tabs, journal, credits) through one accessor.
  3. Author JSON schemas plus loaders for: essences, tether_candy, material_tiers (8), stations and attachments, gear tiers, traits, masters and feasts, evolution_lines, portals/keys/waystones, level_caps. Loaders fail loudly on unknown ids.
  4. Register every new durable field with scope (world|character) and transaction id rules; add a two-peer save/reload round-trip smoke.
  5. Retire (do not delete) the realm_key_* flag gates behind a single 'legacy_physical_crossings' flag defaulting off; F18 replaces them.
- **Proof:** Unit tests above; full unit suite green on 4 shards; a v27 fixture save proves the refusal.
- **Acceptance (F16#0–#4):**
  - `#0` Save schema bumped past v27; loading any v27-or-older save shows a clear 'older version, start a new game' message, never crashes and never overwrites the old file (unit test with a v27 fixture).
  - `#1` Data schemas exist and validate for type essences, material tiers (8 slots, 4 live), stations and attachments, gear tiers, traits, Masters and feasts, evolution lines, portals, keys and waystones, level caps (10–100); a schema test fails on a missing or unknown id.
  - `#2` Biome order is one config list (meadows, tidewake, cloudreach, stormwood, then four reserved slots); a test proves no gameplay code hard-codes the old Meadows→Cloudreach→Stormwood→Water order.
  - `#3` Every new durable field declares scope (world or character) and transaction semantics in the flag-scope registry; a two-peer save/reload round trip preserves them.
  - `#4` New game from the title reaches Grandpa's opening on the new schema with an empty satchel apart from authored gifts; the full unit suite is green.

### F17 · Village road and the Crossing Hall  (`tb/hub`)

- **Outcome:** The village is one straight road lined with houses, the homestead at its start and the giant Crossing Hall capping the far end.
- **Depends on:** F16
- **Owns:** data/config/village.json, village_npcs.json, village_boundary.json, building_prefabs.json (village entries), scripts/world/village*.gd, grandpa_house.gd, new scripts/world/crossing_hall*.gd, new data/config/crossing_hall.json, terrain_playground.json (village pad only)
- **Build:**
  1. Re-plan the village as one straight road: homestead plot at the start beside the Meadows exit/South Bridge road, 8–10 MegaKit houses facing the road on both sides (Mira's shop, Tam's workshop, inn, Halda's tournament board and arena lawn, research keeper, named residents), the Crossing Hall at the end. Keep Grandpa's farmhouse as the homestead anchor; move it only if the plan needs it and pin its new position in tests.
  2. Kitbash the Crossing Hall from installed families (MegaKit stone, timber, props): a nave with the home arch plus 7 portal arches (3 live-capable, 4 sealed/dark with biome-5..8 placeholders), a side Shrine Room with 8 pedestals. Scale it as the tallest village landmark, visible from the farm door.
  3. Re-bake terrain/scatter for the village pad only; keep the South Bridge route and M1 chain intact.
  4. Two-peer layout agreement smoke; day/night controller walk to every NPC, arch and pedestal.
- **Proof:** Overhead capture, walk logs, M1 chain re-run, code-blind village+Hall judge against the new bar.
- **Acceptance (F17#0–#6):**
  - `#0` Overhead plan and topology test: one straight road, 8–10 houses facing it on both sides, the homestead plot at the road's start beside the Meadows exit, the Crossing Hall at the road's end; road-graph test passes.
  - `#1` From Grandpa's farm door at the normal camera, the Crossing Hall reads as the destination down the road (code-blind judge YES, day and night).
  - `#2` The Hall nave holds the home arch plus 7 portal arches (3 live-capable, 4 sealed and dark but visible), each signed by biome; a Shrine Room holds 8 pedestals; a controller walk reaches every arch and pedestal with no collision snag.
  - `#3` Every house has a named resident or lived-in dressing; shop, workshop, inn, tournament board and research keeper are reachable on a controller day and night walk.
  - `#4` The M1 opening chain (starter, practice catch, camp, three-bed readiness, three tournament rounds) still completes on the new layout.
  - `#5` Host and guest see the same layout, arch states and shrine states after join and reload.
  - `#6` Village and Hall frames pass the new visual bar (ACCEPTANCE §4: Palworld/Animo creatures and world, Valheim lighting and atmosphere) with a code-blind judge.

### F18 · Home Key, portal keys and waystones  (`tb/hub`)

- **Outcome:** Grandpa's Home Key returns you to the Hall from anywhere; boss keys open portals; waystones send you back out where you left off.
- **Depends on:** F16, F17
- **Owns:** new scripts/world/portal_arch.gd, home_key.gd, waystone.gd, new data/config/portals.json, waystones.json, data/items/items.json (key items), scripts/world/realm_gate.gd, rift_crossing.gd, stormwood_water_gate.gd (retire), Game.enter_realm call sites, data/dialogue/opening.json (Grandpa gives the Home Key)
- **Build:**
  1. Home Key item (key category, undroppable, unsellable, excluded from satchels). Grandpa hands it over in grandpa_first_catch or the tournament send-off (choose the earlier natural beat; document it).
  2. Use flow: tap → input_owner lock → 2 s raise animation with glow and sound → fade → spawn at home arch. Refusal reasons for combat, dialogue, cutscene, swimming, flight.
  3. Portal keys: tidewake_portal_key, cloudreach_portal_key, stormwood_portal_key, fifth_portal_key items. Using one at its arch writes a character-scope unlock plus a world-scope unlock for the host world.
  4. Portal access rule: open if host world unlocked OR this character unlocked. Destination = this character's last activated waystone in that biome, else the biome entry.
  5. Place 3–5 waystones per live biome at existing camps/landmarks (config); touch to activate; each has a small shrine mesh from installed families.
  6. Retire physical crossings: realm gates become scenery or one-way returns to the Hall; nothing else enters a later biome.
- **Proof:** Unit tests per rule; ordinary-input loop witness; two-peer and cross-host key smoke.
- **Acceptance (F18#0–#5):**
  - `#0` Grandpa gives the Home Key during the opening; it sits in the backpack and cannot be dropped, sold, traded or lost in a death satchel.
  - `#1` Using the Home Key is one tap: a ~2 s raise-and-glow animation, then arrival at the home arch; it is refused with a stated reason in combat, dialogue, cutscene, while swimming and mid-flight; free with no cooldown.
  - `#2` Portal keys are real inventory items; using one at its arch unlocks that portal permanently; locked arches refuse with a readable reason; retired physical crossings no longer lead between biomes (test proves portals are the only realm path).
  - `#3` Each live biome has 3–5 waystones activated by touch; a portal sends the player to their last activated waystone in that biome (entry point if none); activation persists through reload.
  - `#4` Co-op: every player has their own Home Key and it moves only that player; a portal opens for the whole session when the host world or that character has unlocked it; a guest's own unlock follows their character to another host.
  - `#5` Ordinary-input loop witness: deep in a biome → Home Key → use a homestead station → portal back to the waystone, with a save/reload between steps.

### F19 · Biome reorder and level curve  (`tb/reorder`)

- **Outcome:** Meadows → Tidewake → Cloudreach → Stormwood with re-derived levels, keys and relic hand-offs.
- **Depends on:** F16, F18
- **Owns:** data/config/chapter_curve.json, data/config/bands/**, cloudreach_encounters.json, cloudreach_chapter.json, stormwood_encounters.json, stormwood_trainers.json, water_characters.json, water_encounters.json, spawn tables, realm_hearts.json, chapter_rewards.json, tests/fixtures/earned_saves/**, tests/fixtures/band_split_baseline/**
- **Build:**
  1. Apply the level table (§3.3). Re-derive every wild range and named-trainer team per band with PROGRESSION's constraints (wild high ≤ exit, wild low ≤ entry, no backwards band).
  2. Rewire boss hand-offs to portal-key items and relic grants per participant.
  3. Stormwood legendary: replace the Sparkit placeholder (`stormwood_dynamo.json` captive.placeholder_species, nickname 'the Stormheart') with Fulgocobra, the existing species the Stormwood roster board marks Legendary. This is an existing species, not a roster expansion. Keep the nickname if the story needs it.
  4. Scan gates for traversal assumptions (Tidewake without Fly; Stormwood without Tidewake-only abilities being assumed beyond what the order grants).
  5. Regenerate earned saves and band baselines; update smoke scripts that assume the old order (smoke_four_biome_continuous and card scripts).
- **Proof:** Curve test, gate-scan test, legendary offer smokes in new order, regenerated fixtures committed with provenance.
- **Acceptance (F19#0–#5):**
  - `#0` The order Meadows → Tidewake → Cloudreach → Stormwood drives the config, map, journal, portal signs and credits.
  - `#1` Level bands: Meadows 3→22 (wild 2–20, Warden ~21–22), Tidewake 20→33 (wild 18–32, Nerissa ~32–33), Cloudreach 31→44 (wild 29–43, Veyra ~43–44), Stormwood 42→55 (wild 40–54, finale ~54–55); wild tables and named trainer teams re-derived; a curve test pins them.
  - `#2` Boss hand-offs: Warden → Tidewake key; Tidewake finale → Cloudreach key; Veyra → Stormwood key; Stormwood finale → fifth key; each biome relic still granted; every participant receives their own.
  - `#3` Traversal: nothing in Tidewake requires Fly; nothing in Cloudreach or Stormwood assumes a later legendary or relic (gate-scan test).
  - `#4` Per-participant legendary offers (Veridian, Abyssal Guardian, Solmane, Stormwood's legendary) still work in the new order, accept and refuse, at capacity and with space.
  - `#5` Earned checkpoint saves under tests/fixtures/earned_saves/ regenerated for the new boundaries; each portal sign shows its recommended level and no hidden level gate exists.

### F20 · Ending after Stormwood and the fifth key  (`tb/reorder`)

- **Outcome:** Tidewake resolves its own chapter; the Stormwood finale leads home by the Home Key to Grandpa, credits and a stirring fifth arch.
- **Depends on:** F18, F19
- **Owns:** scripts/story/regional_homecoming.gd, data/dialogue/homecoming.json, regional_credits.json, scripts/ui/regional_credits.gd, regional_ending_objectives.json, water dock-exchange flow (credit trigger only), stormwood finale aftermath (hand-off only)
- **Build:**
  1. Move credits and Grandpa's homecoming trigger from Tidewake to after the Stormwood finale; Tidewake's dock exchange stays as its chapter close.
  2. After the Stormwood finale, prompt the player to use the Home Key; the homecoming plays at the farm with the actual five.
  3. Fifth arch: key use → stir effect (glow, low hum, dust) and a one-line NPC or Grandpa remark; no quest marker.
  4. Post-credits completed-world state enables F43/F44 content.
- **Proof:** Solo and two-peer ending smokes; reload after credits.
- **Acceptance (F20#0–#4):**
  - `#0` Tidewake's dock exchange completes as Tidewake's chapter resolution and no longer rolls credits.
  - `#1` After the Stormwood finale the player uses the Home Key; Grandpa names the current five, the starter's status, one bond memory and chapter choices; credits roll once per character.
  - `#2` Using the fifth key at the fifth arch makes it stir (glow, sound, one line: not ready yet) but not open; no quest, cliffhanger or sequel prompt.
  - `#3` After credits, reload resumes a safe completed world with bounties, rematches and remaining activities available.
  - `#4` Two peers each get their own homecoming acknowledgement and credits exactly once through disconnect/reload.

### F21 · Combat impact and camera  (`tb/combat`)

- **Outcome:** Hits land: hitstop, knockback, reactions, damage numbers, crits and a camera that keeps the fight readable.
- **Depends on:** F16
- **Owns:** scripts/combat/combat_manager.gd (impact section), combat_math.gd, impact_flash.gd, new scripts/combat/hit_feedback.gd, scripts/vfx/**, data/config/combat.json (impact block), data/config/camera.json (fight block), scripts/ui/combat_hud.gd (damage numbers)
- **Build:**
  1. Add hit_feedback: hitstop (per-weight ms), knockback impulse, target reaction pose/shake, floating damage numbers with crit/effective/resisted styles, rumble and shake with accessibility toggles.
  2. Stagger state on poise break with bonus window; readable flash and sound.
  3. Fight camera: frame both actors across the body-size matrix; fix P2-062/P2-092 class overlap and empty-arena framing.
  4. Capture before/after sequences for a code-blind judge.
- **Proof:** Unit tests on config reads and stagger timing; judge verdicts; frame-time capture.
- **Acceptance (F21#0–#5):**
  - `#0` Every landed hit produces tunable hitstop, knockback scaled by move weight, a target hit-reaction pose and a damage number; all values live in config.
  - `#1` Critical and super-effective hits read differently from ordinary hits (number size/colour, sound, flash); resisted hits read weaker.
  - `#2` Poise break produces a visible stagger state with a bonus-damage window.
  - `#3` Heavy hits add camera shake and controller rumble, each with an accessibility toggle.
  - `#4` Fight camera keeps both actors framed without overlap for small, normal and giant bodies (catalog P2-062/P2-092 class); code-blind judge PASS on a size matrix.
  - `#5` Code-blind judge prefers after over before on 'hits feel weighty and readable' from matched frame sequences; fights hold frame rate on the Medium preset capture.

### F22 · Enemy patterns, anti-mash and role identity  (`tb/combat`)

- **Outcome:** Enemies telegraph learnable patterns, mashing loses, switching matters and each role plays differently.
- **Depends on:** F21
- **Owns:** scripts/combat/combat_ai.gd, encounter_director.gd, data/config/combat.json (AI/pattern block), BOSSES-profile data for named fights, tests/smoke_meadows_named_c2c3.gd and siblings
- **Build:**
  1. Data-driven attack patterns per role (≥2 each) with telegraph windows; wild AI repositions, dodges and punishes.
  2. Tag-switch value: switching within a window after a hit triggers a follow-up (with F24).
  3. Re-run reader/masher C2 per band in the new order; tune; re-capture named fights for C3.
  4. Close or supersede the six open Phase 1 fight criteria with evidence.
- **Proof:** C2 smoke across 12+ seeds per band; code-blind role identification; named-fight C3 judges.
- **Acceptance (F22#0–#4):**
  - `#0` Each combat role has at least two data-driven attack patterns with readable telegraphs; wild creatures reposition, dodge and punish rather than stand and trade.
  - `#1` Across 12+ seeds per biome band, a reader pilot beats a masher pilot (reader win ≥0.9; masher loses the lead creature materially more often).
  - `#2` Switching has measurable value: tag-switch combos and type matchups let a switching reader beat a non-switching reader.
  - `#3` A code-blind judge names the role of five different creatures from fight footage alone.
  - `#4` Named fights (Warden, captains, relay officers, Nerissa, Veyra, Stormwood finale) each present a distinct pattern and pass C2/C3 on the new timings; this closes or supersedes F04#1, F04#2, F04#6, F04#7, F10#6 and F14#1.

### F23 · Move loadout: three slots, ultimate, learnsets and mastery  (`tb/combat`)

- **Outcome:** Each creature fights with quick, charged and utility moves plus a signature ultimate, learns moves and masters them.
- **Depends on:** F16, F21
- **Owns:** data/moves/moves.json, data/moves/learnsets.json (new), data/moves/tms.json, data/creatures/species.json (moves/learnset refs), scripts/creatures/teaching.gd, new scripts/creatures/move_mastery.gd, scripts/combat/combat_manager.gd (slot dispatch), scripts/ui/combat_hud.gd (slots, ultimate meter), input map
- **Build:**
  1. Extend creature instance with loadout {quick, charged, utility, ultimate} and mastery map; migrate nothing (save reset).
  2. Author learnsets for all 57 species plus the storm bear: base quick/charged at L1, utility options at L5/L15, extra options at breakthroughs.
  3. Add ≥10 utility moves; ultimate meter from landed hits.
  4. Loadout edits only at Altar or forward camp; persist; two-peer rejoin test.
- **Proof:** Unit tests for dispatch, learnsets, mastery; controller mapping test (no held gameplay).
- **Acceptance (F23#0–#5):**
  - `#0` Every creature has quick, charged and utility slots plus an ultimate; default mapping X quick, Y charged, B utility, RB+face ultimate, A dodge; no held-button gameplay (charged moves are tap-to-start).
  - `#1` Every species has a learnset unlocking moves at levels and breakthroughs; TMs still work under the primary-type rule.
  - `#2` At least ten utility moves exist (dash-strike, heal pulse, trap and others) and every role can equip at least two.
  - `#3` Loadouts change at the Altar or a forward camp and persist through save/reload and two-peer rejoin.
  - `#4` Move mastery ranks 1–5 rise with use; each rank raises damage and upgrades the move's effect tier; mastery persists.
  - `#5` The ultimate meter fills from landed hits, the HUD shows it, and the ultimate fires only when full.

### F24 · Tether Commands (trainer support, no damage)  (`tb/combat`)

- **Outcome:** The trainer supports the fight with a command meter: item throw, Rally, tag-switch combo and Tether Snare.
- **Depends on:** F21, F23
- **Owns:** new scripts/combat/tether_commands.gd, data/config/tether_commands.json, scripts/combat/catch_math.gd (snare modifier), combat HUD command meter, scripts/player/player_equipment.gd (pouch tiers)
- **Build:**
  1. Command meter, four commands, host validation.
  2. Damage-attribution test: no damage source is the trainer.
  3. Snare catch modifier bounded; refused on trainer-owned creatures.
- **Proof:** Unit + two-peer smoke.
- **Acceptance (F24#0–#5):**
  - `#0` A command meter fills from the piloted creature's hits and powers four commands: quick item throw, Rally (short team buff), tag-switch combo and Tether Snare.
  - `#1` The trainer never deals damage: a test proves every damage event is creature-attributed.
  - `#2` Switching within the combo window after a hit triggers a joint attack from both creatures.
  - `#3` Tether Snare slows a wild creature and raises catch chance; it cannot target a trainer-owned creature.
  - `#4` Workbench trainer-gear tiers upgrade commands (meter rate, pouch size, snare strength).
  - `#5` Co-op: each player's commands affect only their own creature and are host-validated.

### F25 · Move effects library (real pebbles, fireballs, lightning)  (`tb/vfx`)

- **Outcome:** Every move shows its real object: pebbles fly, fireballs burn, lightning strikes from the sky.
- **Depends on:** F16 (can start with F21)
- **Owns:** scripts/combat/move_projectile.gd, scripts/vfx/** (new archetypes), assets/vfx/** (new), data/config/vfx.json, moves.json vfx blocks, audio cue ids in data/config/audio.json
- **Build:**
  1. Build the archetype library (list in §3.5). Each archetype: body (mesh or CPUParticles3D; GPUParticles3D only where the Compatibility preset has a fallback), trail, impact, sound id, budget.
  2. Map every move; parameterize pebble count, size, colour, arc.
  3. Sync damage to arrival; keep the existing 'arrived' signal contract.
  4. Mastery tiers scale the effect.
- **Proof:** Mapping test; judge frames for pebble toss, rock throw, fireball, lightning; four-creature frame-time capture.
- **Acceptance (F25#0–#5):**
  - `#0` About 24 effect archetypes exist, each with a real mesh or particle body, trail, impact and sound, configured in data.
  - `#1` Every move in data/moves/moves.json maps to an archetype with parameters; a test fails on an unmapped move.
  - `#2` A code-blind judge identifies from frames: pebble toss shows several small stones in flight, rock throw one boulder, fireball a burning orb with a trail and explosion, lightning a bolt striking the target from above.
  - `#3` Damage resolves when the effect arrives (or the exception is documented per archetype); no damage number appears before the visible hit.
  - `#4` Each effect has a particle budget; a worst-case four-creature fight holds frame rate on the Medium preset capture; nothing depends on an effect the Compatibility preset cannot draw without a fallback.
  - `#5` Mastery ranks visibly upgrade the effect (size, count, trail).

### F26 · Renderer and look development (Palworld + Valheim bar)  (`tb/lookdev`)

- **Outcome:** A Forward+ look with quality presets delivers Valheim-class light and atmosphere around Palworld-class creatures and world.
- **Depends on:** F16
- **Owns:** project.godot (rendering), data/config/art.json, *_look.json, *_atmosphere.json, environment resources, shaders/**, scripts/ui/tab_settings.gd (graphics presets), docs/design/ART_DIRECTION.md look-bar section, ralph/reports/VISUAL/lookdev/**
- **Needs the owner:** Owner runs one build on the ROG Ally.
- **Build:**
  1. Add a Forward+ rendering path with Low (= Compatibility), Medium and High presets; per-preset toggles for volumetric fog, SSAO, SSIL, glow, shadows, LOD distance.
  2. Look-dev each biome and the village to the new bar: Palworld/Animo creature and world appeal, Valheim sky, fog, sun shafts, time-of-day grade, weather mood. Write the bar with reference boards into ART_DIRECTION.
  3. Keep the default renderer unchanged until the owner's Ally run passes; ship the preset choice in settings for the test build.
  4. Hand the owner an Ally test checklist (route, preset, fps readout) in STATE owner_needs.
- **Proof:** Per-preset frame-time captures; code-blind judge per biome; owner Ally result.
- **Acceptance (F26#0–#5):**
  - `#0` A Forward+ path renders the village, Hall and all four biomes with no missing materials; Compatibility remains selectable as the Low preset.
  - `#1` Low/Medium/High presets control volumetric fog, SSAO, SSIL, glow, shadow quality and draw distance; the setting persists.
  - `#2` Each biome has a documented look bar (sky, fog, sun shafts, time-of-day grade, weather mood) with reference boards in ART_DIRECTION.
  - `#3` A code-blind judge rates each biome's frame matrix as meeting the new bar on High and Medium.
  - `#4` Computer captures at 1920×1080 record frame time per preset for a scripted route in each biome.
  - `#5` Owner ROG Ally test: Medium handheld holds ≥30 fps (40 preferred) on the scripted route; Forward+ becomes the default only after this passes (owner-dependent).

### F27 · Type essence and chosen leveling  (`tb/training`)

- **Outcome:** Eight type essences and Tether Candy let the player choose who grows; combat XP still trickles.
- **Depends on:** F16
- **Owns:** new scripts/creatures/essence.gd, data/config/essence.json, data/items/items.json (essence, candy), scripts/creatures/progression.gd (XP rate, spend), release flow in scripts/ui/tab_creatures.gd, new Altar UI (with F42)
- **Build:**
  1. Essence items and sources; reduced auto-XP (config, e.g. 0.35×).
  2. Altar spend: level cost curve per level band in config; cap respected.
  3. Release payout by type; transaction ids to prevent duplication.
  4. Ledger script for the route.
- **Proof:** Unit + two-peer duplication smoke + ledger report.
- **Acceptance (F27#0–#5):**
  - `#0` Eight type essences (ground, water, air, electric, fire, dark, ice, psychic) and Tether Candy exist as stackable items.
  - `#1` Sources work: defeating wilds, releasing a caught creature (its type), attuned nodes, essence crops, research tasks and a capped daily care trickle; no creature expeditions or automation.
  - `#2` Automatic combat XP continues at a reduced configured rate and is never zero.
  - `#3` At the Altar the player spends essence to raise a chosen creature's level up to its cap; dual types may use either essence; starters level through their type.
  - `#4` Release payouts and essence spends cannot duplicate through reconnect or reload (two-peer test).
  - `#5` A route ledger shows the ordinary path reaches each biome's entry level without mandatory repeat grinding, and optional grinding speeds it measurably.

### F28 · Breakthroughs, Masters and Ascension Feasts  (`tb/training`)

- **Outcome:** Every ten levels a creature needs a breakthrough: beat a Master 1v1, earn the feast recipe, gather, cook and feed.
- **Depends on:** F16, F27, F31 (Kitchen)
- **Owns:** new scripts/creatures/breakthrough.gd, data/config/masters.json, data/recipes/feasts.json, new Master encounter scenes/placements per biome, BOSSES Master profiles
- **Build:**
  1. Caps and breakthrough state per creature.
  2. Five Masters: named characters from the installed humanoid cast, a 1v1 arena each, off-path with signposts; chest grants the feast recipe per character.
  3. Feast recipes: tier materials + type-attuned ingredient; Kitchen cooks; feeding lifts cap.
  4. Ledger check for ingredients.
- **Proof:** Unit tests; ordinary-input Master win + feast + cap lift; two-peer recipe receipts.
- **Acceptance (F28#0–#5):**
  - `#0` Caps at 10, 20, 30, 40 and 50 (ceiling 60 this pass; data holds up to 100); a capped creature stops gaining levels and shows 'breakthrough needed'.
  - `#1` Five Masters are placed off-path and signposted: L10 mid-Meadows, L20 upper Meadows before the Warden's stronghold, L30 an outer Tidewake island, L40 a Cloudreach high perch (Fly), L50 deep Stormwood.
  - `#2` Each Master fight is a 1v1 with a creature of the player's choice; a win opens a chest teaching that tier's Ascension Feast once per character; a loss is retryable.
  - `#3` The feast needs that tier's biome materials plus one type-attuned ingredient matching the creature; it is cooked at the Kitchen and fed to one creature to lift its cap.
  - `#4` Each co-op participant earns their own recipe; nobody receives it twice.
  - `#5` A ledger proves every feast ingredient is reachable in or before its biome.

### F29 · Evolution lines (one per biome)  (`tb/training`)

- **Outcome:** Mudsnout, Mosshell, Craghorn and Staticub can evolve at breakthrough feasts; evolving is optional.
- **Depends on:** F28, F36 (storm bear)
- **Owns:** scripts/creatures/evolution.gd, data/config/evolution_lines.json, species.json evolution fields, storm bear asset folder (assets/creatures/tetherbound/<name>/)
- **Build:**
  1. Generalize evolution to breakthrough-triggered lines with evolve/stay choice.
  2. Move Mudsnout to L20 feast with heartstone/sunstone ingredient.
  3. Storm bear: drafted reference → Meshy → rig/animation → scale → judge → provenance; flag-gated until PASS.
- **Proof:** Unit tests per line; identity-preservation test; judge verdict for the bear.
- **Acceptance (F29#0–#4):**
  - `#0` Four lines: Mudsnout → Tuskroot or Ashtusk at L20 (heartstone/sunstone as feast ingredient), Mosshell → Cannonback at L30, Craghorn → Stormcapra at L40, Staticub → the new Stormwood storm bear at L50.
  - `#1` The breakthrough offers evolve or stay; staying is permanent for that tier.
  - `#2` Evolution preserves uid, nickname, level, bond history, IVs, traits and mastery.
  - `#3` The new storm bear exists via an agent-drafted reference and Meshy, larger than Staticub and taller than the trainer, with provenance recorded and an in-engine code-blind PASS; flag-gated until then.
  - `#4` Cannonback and Stormcapra remain wild where they already appear; Tuskroot, Ashtusk and the storm bear are not wild.

### F30 · Traits and Trait Seeds  (`tb/training`)

- **Outcome:** Wild creatures roll traits; releasing one distils a Trait Seed you teach to your five.
- **Depends on:** F27
- **Owns:** new scripts/creatures/traits.gd, data/config/traits.json, spawn roll hooks, catch readout, Altar trait UI
- **Build:**
  1. Trait pool with effects; roll rules; alpha/night/weather bonus.
  2. Distil on release; teach seed into slots unlocked at breakthroughs.
  3. Unify with existing bond trait and IV code.
- **Proof:** Unit test per trait; roll distribution test; persistence.
- **Acceptance (F30#0–#4):**
  - `#0` About 30 traits in Common, Rare and Epic tiers; wild creatures roll 0–3; alphas and night or weather spawns roll better.
  - `#1` Traits show on the catch readout and creature inspect screens.
  - `#2` Releasing a caught creature at the Altar distils one chosen trait into a Trait Seed.
  - `#3` A seed teaches into trait slots unlocked at the L10, L30 and L50 breakthroughs and costs essence.
  - `#4` Each trait's effect applies in combat or traversal (unit test per trait); the existing bond second-trait rule is unified with this system.

### F31 · Homestead stations and upgrades  (`tb/homestead`)

- **Outcome:** Six stations at Grandpa's farm; four of them take one upgrade per biome; Meadows upgrades are open from the start and each hung relic unlocks the next biome's.
- **Depends on:** F16, F17
- **Owns:** data/items/buildables.json, new data/config/stations.json, scripts/build/** (station pieces), new scripts/build/station_*.gd, scripts/ui/craft_panel.gd, shrine pedestal logic in crossing_hall
- **Build:**
  1. Six stations as buildables with interaction panels; attachments as adjacent buildables with tier checks.
  2. Shrine hang → unlock the next tier's attachment recipes (Meadows tier from the start); relic power selection moves to the Shrine Room.
  3. Personal tier/recipe state; world-owned buildings; guest crafting rule.
- **Proof:** Unit + two-peer craft smoke + judge frames.
- **Acceptance (F31#0–#6):**
  - `#0` Workbench, Forge, Kitchen, Altar, Den and Farm plots (plus chests) can be built on the homestead plot.
  - `#1` Forge, Kitchen, Altar and Den each take exactly one attachment per biome (4 live, 8 slots) built from biome materials; recipe tier requires the attachment.
  - `#2` Meadows (tier 1) attachments are available from the start; hanging a biome's relic in the Shrine Room unlocks the next tier's attachment recipes (Meadows relic → Tidewake tier, and so on; Stormwood's relic → reserved tier 5); the player then carries one chosen relic power.
  - `#3` Each station shows a single 'next upgrade' target; no tech tree screen is required to understand progress.
  - `#4` No automation: crops, smelting and cooking need the player's interaction (test).
  - `#5` Co-op: buildings are world-owned; tiers and recipes are personal; a guest uses the host's stations at the host's tier and keeps what they craft.
  - `#6` Stations read as distinct objects at the normal camera (code-blind judge).

### F32 · Materials, attuned nodes and essence farming  (`tb/homestead`)

- **Outcome:** Each biome has its material tier, rare type-essence nodes and crops worth planting.
- **Depends on:** F16
- **Owns:** data/config/harvest.json + per-biome harvest/resource configs, new essence node placements, data/config/farm.json, scripts/world/farm_logic.gd, harvest_node.gd, water_crafting.json registration
- **Build:**
  1. Place tier material nodes and essence nodes per biome; respawn timers in config.
  2. Forge refining recipes; type crops and Greenhouse.
  3. Shed-drop tables; no-butchery naming test.
- **Proof:** Node census per biome; ledger inputs for F47.
- **Acceptance (F32#0–#5):**
  - `#0` The four tier material sets (Meadows rootstone/ironwood…, Tidewake driftwood/reef stone/sluice metal/tide bloom/Tide Pearl, Cloudreach heartwood/cliffglass/gale fiber/skyplume, Stormwood thunderwood/stormglass/conductor vine/glowmoss/sparkfur/voltcap) are gatherable in their biome.
  - `#1` The Forge refines Rootiron, Tidesteel, Skyglass and Stormglass plate.
  - `#2` One or two type-essence nodes per type sit in each biome, mostly off-route, and respawn on a configured timer.
  - `#3` Eight type crops grow on homestead plots; the Greenhouse (a Farm buildable, not an attachment) grows off-biome crops; every harvest is by hand.
  - `#4` Shed items (skyplume, sparkfur and others) drop after wins and from Den grooming; no item implies hunting or butchering (test).
  - `#5` The ten Tidewake water_crafting proposals are registered at runtime; four-character node contention follows MULTIPLAYER.

### F33 · Creature gear and trainer gear  (`tb/homestead`)

- **Outcome:** Harness and Charm tiers make each biome's gear matter; trainer gear protects against the trainer's real hazards.
- **Depends on:** F31, F32
- **Owns:** new scripts/creatures/creature_gear.gd, data/config/gear.json, scripts/player/player_equipment.gd, creature material accent shader hook
- **Build:**
  1. Harness/Charm slots and stat effects; +1..+3 upgrades.
  2. Visual accent per tier on the creature body.
  3. Trainer hazard mitigations per piece.
  4. Boss simulations per tier for the gear-matters criterion.
- **Proof:** Unit tests; C2-style boss sims per tier.
- **Acceptance (F33#0–#4):**
  - `#0` Creatures have Harness and Charm slots in Rootiron, Tidesteel, Skyglass and Stormglass tiers, each upgradable +1 to +3.
  - `#1` Equipped gear shows on the creature as a trim or glow accent.
  - `#2` Gear matters: a simulation of each biome's boss shows the matching tier passes C2 and the previous tier is clearly harder.
  - `#3` Trainer gear mitigates the trainer's actual hazards (falls, storm static, cold heights, drowning and currents, hazard terrain), each covered by a test.
  - `#4` Trainer tool pouch tiers extend Tether Commands; all gear persists and is personal in co-op.

### F34 · Forward camps  (`tb/homestead`)

- **Outcome:** A small travel-tier camp you can build in any biome: bed, cookpot and field workbench.
- **Depends on:** F31
- **Owns:** scripts/build/camp_tent.gd, campfire.gd, new forward_camp.gd, buildables.json (kit)
- **Build:**
  1. Kit item, placement validity, three pieces, travel-tier recipe filter (meals and field kits; no feasts, tier gear or refining), rest and loadout.
- **Proof:** Unit + placement smoke in each biome.
- **Acceptance (F34#0–#4):**
  - `#0` A forward-camp kit crafted at the Workbench places on valid ground in any biome with a bed, portable cookpot and field workbench.
  - `#1` Forward camps craft travel-tier items only (basic meals and field kits); Ascension Feasts, tier gear and refining need the homestead and are refused with a reason.
  - `#2` Resting recovers the team and saves; loadouts can be changed there.
  - `#3` Existing camp functions (tournament beds, rest bonus) keep working.
  - `#4` Placement is host-authoritative and persists through reload and rejoin.

### F35 · Signature ultimates  (`tb/vfx`)

- **Outcome:** Starters, legendaries and evolved forms get unique ultimates; everyone else shares a type-and-role ultimate.
- **Depends on:** F23, F25, F29
- **Owns:** data/moves/ultimates.json, scripts/vfx/ultimates/**, assets/vfx/ultimates/**
- **Build:**
  1. Shared type×role ultimates, then the twelve unique ones; breakthrough growth; 2–3 s presentation.
- **Proof:** Mapping test; judge per unique ultimate.
- **Acceptance (F35#0–#4):**
  - `#0` 16–20 shared type×role ultimates exist and every non-unique species maps to one (test).
  - `#1` Unique ultimates exist for Terrapup, Ripplet, Galewisp, Veridian, Abyssal Guardian, Solmane, Fulgocobra (the Stormwood legendary), Tuskroot, Ashtusk, Cannonback, Stormcapra and the storm bear.
  - `#2` Each ultimate visibly grows at breakthroughs.
  - `#3` Presentation lasts 2–3 s with no longer loss of control and stays readable in four-player fights.
  - `#4` A code-blind judge distinguishes every unique ultimate from the others.

### F36 · Creature art: priority models, poses and scale  (`tb/creature-art`)

- **Outcome:** The creatures players see most look and move like they belong in a Palworld-class game.
- **Depends on:** F26 (look bar)
- **Owns:** assets/creatures/**, assets/characters/** (priority list only), data/creatures/species.json (size/scale), scripts/creatures/creature_animator.gd, creature_body.gd, ART_DIRECTION provenance table
- **Build:**
  1. Write the priority list into ART_DIRECTION with reasons; nightly cap 30 generations.
  2. For each: drafted reference (inspect it) → Meshy → import → scale check → in-engine before/after judge → provenance → flag on only on PASS.
  3. Poses: hurt, faint/collapse (grounded), swim, fly-grip, ride for every species.
  4. Scale fixes grow the smaller side, never shrink larger creatures.
- **Proof:** Judge verdicts per asset; pose matrix capture; provenance rows.
- **Acceptance (F36#0–#3):**
  - `#0` About 25–30 priority assets (starters, most-seen main-path creatures, boss aces, legendaries, the six most repeated NPC faces) are regenerated or confirmed with drafted references and provenance; each passes a before/after code-blind judge or stays flagged off.
  - `#1` Hurt, faint/collapse, swim, fly-grip and ride poses read correctly for every species (P2-015, P2-016, P2-071, P2-028).
  - `#2` Every creature meets the scale rule against the 1.80 m trainer and fight scale is consistent (P2-017, P2-062).
  - `#3` The nightly Meshy cap (30 generations) is respected and logged with task ids.

### F37 · Ripplet swim and dive  (`tb/training`)

- **Outcome:** Ripplet becomes a swim mount in Tidewake and learns to dive at its L30 breakthrough.
- **Depends on:** F28, F19
- **Owns:** scripts/player/riding*.gd, human swim scripts, new dive logic, Tidewake optional dive content placements
- **Build:**
  1. Ripplet swim-mount; Dive at L30 breakthrough; optional sunken content; required routes stay human-swimmable.
- **Proof:** Unit + ordinary-input witness + two-peer rejoin.
- **Acceptance (F37#0–#4):**
  - `#0` An owned Ripplet can be ridden as a surface swimmer from Tidewake's opening, faster than human swimming and able to cross currents.
  - `#1` At the L30 breakthrough Ripplet gains Dive, reaching sunken caches, nodes and hidden optional routes.
  - `#2` Every required water route stays human-swimmable without Ripplet.
  - `#3` The old Ripplet Teleport promise is removed from docs and UI.
  - `#4` Riding and diving survive save/reload and two-peer rejoin.

### F38 · Meadows and village: visual catalog burn-down to the full bar  (`tb/visual-meadows`)

- **Outcome:** Meadows and village looks like a game people want to play: every catalog defect scored over 12 fixed against the full bar, not just past the defect.
- **Depends on:** F26, F17
- **Owns:** Meadows and village scene dressing, meadows_look.json, vegetation/terrain presentation configs for Meadows, catalog fix folders
- **Build:**
  1. Re-capture, re-score, fix top-20 then all >12 in impact order; one to two items per PR.
- **Proof:** Before/after judges; biome frame matrix verdict.
- **Acceptance (F38#0–#5):**
  - `#0` After F26 look-dev, the biome is re-captured (≥200 frames) and its catalog rows re-scored against the new bar.
  - `#1` Every top-20 item for the biome is fixed on main with a before/after code-blind PASS.
  - `#2` Every remaining catalog item touching the biome with impact >12 is fixed on main with a code-blind PASS.
  - `#3` The biome frame matrix (approach, gameplay camera, reverse, detail, day/night, weather, a real fight) passes the new bar on High and Medium.
  - `#4` The hero landmark (the village road and Crossing Hall) reads at distance and up close.
  - `#5` No flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the matrix.

### F39 · Tidewake: visual catalog burn-down to the full bar  (`tb/visual-tidewake`)

- **Outcome:** Tidewake looks like a game people want to play: every catalog defect scored over 12 fixed against the full bar, not just past the defect.
- **Depends on:** F26
- **Owns:** Tidewake scene dressing and water_* visual configs
- **Build:**
  1. As F38 for Tidewake.
- **Proof:** As F38.
- **Acceptance (F39#0–#5):**
  - `#0` After F26 look-dev, the biome is re-captured (≥200 frames) and its catalog rows re-scored against the new bar.
  - `#1` Every top-20 item for the biome is fixed on main with a before/after code-blind PASS.
  - `#2` Every remaining catalog item touching the biome with impact >12 is fixed on main with a code-blind PASS.
  - `#3` The biome frame matrix (approach, gameplay camera, reverse, detail, day/night, weather, a real fight) passes the new bar on High and Medium.
  - `#4` The hero landmark (Veilfall) reads at distance and up close.
  - `#5` No flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the matrix.

### F40 · Cloudreach: visual catalog burn-down to the full bar  (`tb/visual-cloudreach`)

- **Outcome:** Cloudreach looks like a game people want to play: every catalog defect scored over 12 fixed against the full bar, not just past the defect.
- **Depends on:** F26
- **Owns:** Cloudreach scene dressing and cloudreach_* visual configs
- **Build:**
  1. As F38 for Cloudreach.
- **Proof:** As F38.
- **Acceptance (F40#0–#5):**
  - `#0` After F26 look-dev, the biome is re-captured (≥200 frames) and its catalog rows re-scored against the new bar.
  - `#1` Every top-20 item for the biome is fixed on main with a before/after code-blind PASS.
  - `#2` Every remaining catalog item touching the biome with impact >12 is fixed on main with a code-blind PASS.
  - `#3` The biome frame matrix (approach, gameplay camera, reverse, detail, day/night, weather, a real fight) passes the new bar on High and Medium.
  - `#4` The hero landmark (the Sky Aviary) reads at distance and up close.
  - `#5` No flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the matrix.

### F41 · Stormwood: visual catalog burn-down to the full bar  (`tb/visual-stormwood`)

- **Outcome:** Stormwood looks like a game people want to play: every catalog defect scored over 12 fixed against the full bar, not just past the defect.
- **Depends on:** F26
- **Owns:** Stormwood scene dressing and stormwood_* visual configs
- **Build:**
  1. As F38 for Stormwood.
- **Proof:** As F38.
- **Acceptance (F41#0–#5):**
  - `#0` After F26 look-dev, the biome is re-captured (≥200 frames) and its catalog rows re-scored against the new bar.
  - `#1` Every top-20 item for the biome is fixed on main with a before/after code-blind PASS.
  - `#2` Every remaining catalog item touching the biome with impact >12 is fixed on main with a code-blind PASS.
  - `#3` The biome frame matrix (approach, gameplay camera, reverse, detail, day/night, weather, a real fight) passes the new bar on High and Medium.
  - `#4` The hero landmark (the Stormheart tree) reads at distance and up close.
  - `#5` No flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the matrix.

### F42 · HUD, menus and new-system screens  (`tb/hud`)

- **Outcome:** Controller-first screens for the Altar, stations, gear, research and bounties; the HUD reads on a 7-inch screen.
- **Depends on:** F23, F27, F31
- **Owns:** scripts/ui/** (new screens and HUD), data/config/hud.json, ui_tokens.gd, input_contexts.json
- **Build:**
  1. Build new-system screens; fix UI catalog rows; HUD meters; readability captures.
- **Proof:** Judge at 1920×1080 and 1280×800; input_owner tests.
- **Acceptance (F42#0–#3):**
  - `#0` Catalog UI rows (map without terrain context, bare menus, heavy HUD boxes, low-contrast text) are fixed with code-blind PASS.
  - `#1` Altar (levels, essence, loadout, traits, mastery), station, gear, research log and bounty screens exist, are controller-first and registered with input_owner.
  - `#2` The HUD shows ultimate meter, command meter and move slots without clutter; the 7-inch device-profile judge passes.
  - `#3` Every new screen passes a 1920×1080 and 1280×800 readability capture.

### F43 · Bounty board  (`tb/loop`)

- **Outcome:** Halda's board always has three bounties worth doing.
- **Depends on:** F27, F30, F32
- **Owns:** new scripts/world/bounty_board.gd, data/config/bounties.json, Halda dialogue
- **Build:**
  1. Daily rotation, four kinds, personal receipts.
- **Proof:** Unit + reconnect smoke.
- **Acceptance (F43#0–#3):**
  - `#0` Three bounties refresh each in-game morning, drawn only from unlocked biomes.
  - `#1` Bounty kinds: catch with a trait, defeat an alpha, deliver materials, win a rematch.
  - `#2` Rewards (essence, Tether Candy, materials, occasional Trait Seed) pay once per bounty instance and cannot duplicate through reconnect.
  - `#3` Bounties are personal in co-op and survive save/reload.

### F44 · Rematches and alpha respawns  (`tb/loop`)

- **Outcome:** Beaten biomes stay worth visiting: stronger rematches and fresh alphas.
- **Depends on:** F19, F20
- **Owns:** trainer rematch data, alpha respawn config, BOSSES rematch profiles
- **Build:**
  1. Rematch tiers and rewards; post-credits leaders at L55–60; alpha respawn timer and rolls.
- **Proof:** Unit + one rematch witness per biome.
- **Acceptance (F44#0–#3):**
  - `#0` After a biome's boss, its named trainers, captains and Master can be rematched at the next biome's level for better rewards.
  - `#1` After credits, leaders and bosses return at the endgame tier (L55–60).
  - `#2` Alphas respawn every configured number of in-game days with freshly rolled, better traits.
  - `#3` Unique rewards pay once; repeatable rewards follow a cycle that cannot be farmed without limit.

### F45 · Research log  (`tb/loop`)

- **Outcome:** Species-by-species research turns meeting creatures you won't keep into progress.
- **Depends on:** F27
- **Owns:** new scripts/creatures/research_log.gd, data/config/research.json, scripts/ui/tab_quest_log.gd or new journal tab
- **Build:**
  1. Tasks per species, payouts, completion titles.
- **Proof:** Unit + persistence.
- **Acceptance (F45#0–#3):**
  - `#0` Every species has at least three research tasks (for example: see its move, catch one at night, defeat three) that pay type essence.
  - `#1` Completion percentage per biome, with a title or cosmetic at 100%.
  - `#2` The journal screen shows tasks and progress; released and never-kept creatures count.
  - `#3` Research progress is personal, persists and cannot pay twice.

### F46 · Onboarding for the new systems  (`tb/loop`)

- **Outcome:** Grandpa and the village teach each new system when it first matters.
- **Depends on:** F18, F27, F28, F31
- **Owns:** data/dialogue/opening.json and village dialogue, objective beacons, tutorial prompts
- **Build:**
  1. Lessons at first use; skippable; next-goal clarity check.
- **Proof:** Agent-piloted run noting next goal at each gate.
- **Acceptance (F46#0–#2):**
  - `#0` Grandpa or a village NPC introduces the Home Key, homestead, Altar and essence, breakthroughs and Masters, portals and shrines as each unlocks; each lesson can be skipped.
  - `#1` At every gate a new player can state the next goal (A-criteria check by an agent-piloted run).
  - `#2` No stacked modals; every prompt uses input_owner.

### F47 · Economy, balance and the 15–25 hour clear  (`tb/balance`)

- **Outcome:** The whole loop pays off: solvent ledgers, fair difficulty and a 15–25 hour normal clear.
- **Depends on:** Waves 1–2
- **Owns:** balance configs (combat.json, essence.json, gear.json, masters.json, spawn tables), ledger scripts
- **Build:**
  1. Measure route time; tune ledgers; C2 per band; exploit audit.
- **Proof:** Ledger reports; C2 smokes; owner play pass.
- **Acceptance (F47#0–#4):**
  - `#0` An agent-piloted normal route estimates a 15–25 hour clear; the owner's play pass confirms the range.
  - `#1` Essence and material ledgers: the main path reaches each band's entry without mandatory repeat grinding; optional grinding measurably speeds progress.
  - `#2` Four-character contention ledgers are solvent.
  - `#3` C2 difficulty holds for every biome band in the new order.
  - `#4` No exploit loop (buy/resell, rest, release farming beyond the intended rate, bounty rerolls) mints unbounded value.

### F48 · Co-op across the new loop  (`tb/coop`)

- **Outcome:** Friends play the whole new loop together without losing or duplicating progress.
- **Depends on:** Waves 1–2
- **Owns:** tests/smoke_net_* for new systems, scripts/net/** (only fixes)
- **Build:**
  1. Two-peer full-loop smoke; transaction reconnect matrix; four-peer boss.
- **Proof:** Multiplayer CI shards green.
- **Acceptance (F48#0–#3):**
  - `#0` A two-peer session runs hub → homestead crafting → portal → Master → feast → boss → relic hang, with each player's receipts separate.
  - `#1` Disconnect and rejoin at each transaction (craft, release payout, feast, key use, relic hang) neither duplicates nor loses anything.
  - `#2` A four-peer session completes one biome boss with every participant receiving their own key and relic.
  - `#3` A behind friend follows a host through an unlocked portal, and their own progress stays honest (no permanent key without the fight).

### F49 · Integrated four-biome run and release proof  (`tb/release`)

- **Outcome:** One save plays the new game from Grandpa to credits, on the device that matters.
- **Depends on:** All
- **Owns:** tests/smoke_four_biome_continuous.gd (new order), release workflow
- **Needs the owner:** Owner play pass and ROG Ally hardware.
- **Build:**
  1. One-save integrated run; owner play pass; Ally gate; publish.
- **Proof:** Run log; owner notes; device numbers; release tag.
- **Acceptance (F49#0–#3):**
  - `#0` One save runs new game → Meadows → Tidewake → Cloudreach → Stormwood → Home Key homecoming → credits in the new order, with shortcuts disclosed.
  - `#1` The owner completes a human play pass and records findings.
  - `#2` The ROG Ally device gate passes on the chosen renderer.
  - `#3` The rolling development download is published from the passing commit.

---

## 7. How to run the overnight build

### 7.1 Orchestration

- **Owner operational direction (2026-09-30):** use separate visible local Codex tasks for whole-feature code/content generation, including all owned criteria, then batch the necessary integration/runtime proofs across coherent cuts. Owner-authorized feature worktrees use `tb/fNN`; one shared-file owner remains. Keep source-ready drafts distinct from accepted/main criteria. Replace finished task slots with the next available implementation, retaining prerequisite landing order. RD-36/RD-37 still require named player/save/co-op/visual proofs and independent strict verdicts; no blanket unit/full-CI per change.
- One orchestrating Codex session per wave spawns sub-agents, one per lane. Each gets exact file
  ownership (§6), its criteria, and the stop conditions below. Senior model at high effort
  for design, integration, combat and look-dev. Lower tiers for mechanical data authoring
  (learnsets, trait tables, research tasks, node placement lists) with review.
- Each lane: `tb/<lane>`, branched from current `main`, reused for all its landings. After
  each landing, merge `origin/main` back in.

- New separate work sessions must explicitly use `approval_policy=never` and
  `sandbox_mode=danger-full-access`; verify the effective permission context before
  assigning mutations. The projectless app `create_thread` path silently overrides
  configuration and must not launch lanes. Preserve exact file ownership and the
  exclusive Godot writer token.

### 7.2 Landing a criterion or coherent batch (self-landing, no human gate)
1. Implement content and code first. Under RD-36, use existing focused checks where sufficient;
   add tests only for required acceptance or substantial rework risk. Exercise the required actual
   player path. Related criteria may share a bounded batch and its necessary checks.
2. **Independent strict re-check:** a read-only sub-agent scores the evidence against the
   criterion wording. It closes only on MET. Disclose shortcuts (fixture starts, teleports,
   harness input) in the evidence text.
3. Merge `origin/main`. Choose the smallest necessary validation set for the batch, recording
   the covered risks, source SHA and any reused evidence. Run the full unit suite once per coherent
   batch when acceptance explicitly requires it or scoped checks cannot cover a substantial
   integration/rework risk (RD-37) (`--script tests/run_tests.gd -- --shard=I/4`, 4 shards, no exclusions).
   Import only when the cache is absent or affected assets/scripts require it. Do not repeat a
   passing suite for each criterion, evidence-only commit or docs update; after a fix, rerun only
   affected checks unless the change creates wider uncertainty. Required CI still runs on the PR.
4. Update the board row (`status`, `evidence`, `gap`), STATE §0 (one line), then open the PR with
   the template, `tools/check_pr_traceability.mjs`, and auto-merge. **RD-37 supersedes automatic
   `full-ci` labelling for code/data/scenes/tests.** Select full CI only for an explicit acceptance
   need or substantial integration risk that the scoped proofs cannot cover. Otherwise cite the
   smallest actual named checks or independent review sufficient for the bounded risk. Current
   `ci.yml` runs no build/test jobs on an unlabelled PR: call that process-only evidence, never engine
   verification. Required selected CI must pass; do not remove a label to evade a failure.
5. If CI goes red on your PR, fix it on the same PR. Never skip, disable or quarantine a test.

### 7.3 Pushing and the hourly board
- **Push at least every hour** of active work, even when a criterion has not closed
  (WIP commits on the lane branch). Nothing lives only in a container.
- **Hourly board update:** the board-duty holder (§4) runs
  `python3 ralph/reports/COORDINATOR/dashboard/build_dashboard.py` after refreshing
  `status.json` (headline, lanes, WIP). It commits JSON plus HTML through a small docs PR with
  auto-merge. Publish the landed HTML to the existing owner-private Site in
  `ralph/reports/COORDINATOR/README.md` when Sites tools are available, and give the owner its
  rendered remote link. Keep the same Site/URL and private audience; the legacy Artifact
  tool may additionally refresh its old URL when available. Board headline format:
  `Criteria met: N of 280` (it grows only if the owner adds features).
- Evidence goes in `ralph/reports/<LANE>/` (for example `ralph/reports/TRAINING/f28/`).

### 7.4 Stop and escalate
- Two failed attempts at the same fix or measurement: change approach or re-scope, and
  record it.
- One confirming rerun for a suspected infrastructure failure. A flake is not a root cause.
- An owner-only item (the Ally test, a play pass, Steam resources, a pillar change) goes to
  STATE "Open owner decisions" and `status.json` `owner_needs`. Then continue with other
  work. Never idle.
- A conflict with a hard rule or with §1: stop that item, write it into STATE with a
  recommended answer, and keep the current rule.
- Work is never "done" while a criterion it touches is red on main.

### 7.5 Superseded Phase 1/2 items (RD-34)

| Old item | Disposition |
|---|---|
| F04#1, F04#2, F04#6, F04#7 (Meadows named fights) | Fold into F22#4. Close them with F22's evidence, or mark them superseded when F22 lands. |
| F10#6 (Stormwood HUD device) | Folds into F42#2. |
| F14#1 (Nerissa C2/C3) | Folds into F22#4 (re-judged at her new Tidewake level). |
| M2, M3, S2, T2 cards | Re-run under F49's integrated run in the new order. |
| F05#8 physical gate into Cloudreach, F08#1 Stormwood key, F11 Water gate, F15 Tidewake credits | Stay met as history. The behavior is replaced by F18 (portals), F19 (hand-offs) and F20 (ending). |
| Old Phase 2 steps 2c/2d, look-dev bar, `tb/hud-legibility` | Replaced by F26, F38–F41 and F42. |
| CLAUDE_START_HERE §6 reorder list | Replaced by F19/F20 (same items, plus portals). |

---

## 8. Owner-dependent items (never block other work on these)
1. **ROG Ally test** for F26. When the Forward+ build is ready, STATE gets a one-page
   checklist: install, preset Medium, handheld 15 W, the scripted route, read the fps overlay.
2. **Owner play pass** for F47/F49.
3. **Steam AppID, partner access and accounts** for internet co-op (unchanged open item).
4. **Meshy credits:** the cap is 30 generations per night unless the owner raises it.
5. Naming the storm bear (working name *Stormursa*).

### 8.1 Defaults taken in the documentation pass (conservative; the owner may override)

These fill gaps the interview did not settle. Lanes build them as written unless STATE records an owner change.

- Each co-op character wins its own Master 1v1 for its recipe. Other players may watch but not join.
- Creatures caught above a cap count lower tiers as cleared; evolution offers are not retroactive.
- The existing Good, Great and Rare Candy stay and respect caps. Taught trait slots are extra to rolled traits.
- The Tether Command pouch uses the existing backpack slot. `hide_*` armour keeps its ids with non-butchery display names. Tool repair stays the free Satchel press.
- Attachment order: Meadows attachments are available from the start, and each hung relic unlocks the next biome's attachments (RD-20 "next tier"; HOMESTEAD §4).
- The Stormwood legendary is **Fulgocobra**, replacing the Sparkit placeholder (the roster board's legendary; not a roster expansion).
- Portal access through a character's own unlock is a per-traveler check (RD-21 "your own character"). A guest who is ahead may lead a host into a later biome (Valheim-style), and the guest's progress counts only for the guest.
- The shrine display becomes world-visible on the first hang in that world.
- **The Home Key works anywhere outside its refusal list, including inside strongholds**. The owner said "from anywhere in the game", so leaving to heal and returning by waystone is intended.
- The home arch is the "Meadows portal": it sends the player to their last Meadows waystone.
- Portal keys, like the Home Key, cannot be dropped or lost.
- The magenta telegraph changes form; COMBAT/UX pick its colour. Daily caps keyed to the host day are checked for world-hopping (F47#4).
- Meshy refine, retexture and retry tasks count toward the 30-per-night cap.
- Ordinary consumable use in combat stays free; the Tether Command item throw only buys an instant throw.
- Proposed placements and numbers in WORLD/BOSSES/TRAINING/HOMESTEAD (Master sites and species, waystone candidates, Ripplet mount and dive values, rematch cycles, 3-day alpha respawn) are starting values, tuned in F47.
- The Tidewake dock-exchange line that names Cloudreach contacts is rewritten in F20 for the new order.

