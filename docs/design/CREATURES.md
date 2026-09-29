# Creatures

**Status:** Product and roster contract. Every rule below says whether it is **current** or a **target**. A target is unimplemented until code, tests and human acceptance prove it. Source references describe main at `b8eda885` unless a line names `1c3f0b0d`; recovery references use the archived decision record's full slug where ambiguity exists. Owner redesign decisions of 2026-09-29 are cited as "(owner, 2026-09-29, RD-nn)" from `CODEX_START_HERE.md` §1; every one of them is **Not built (target)** here.

**Product:** Tetherbound is a finite, authored creature expedition action RPG for one to four players, with co-op required for release. Four chapters in the order Meadows → Tidewake → Cloudreach → Stormwood form the release campaign, with a 15–25 hour normal clear (RD-01, RD-10). **Superseded (owner, 2026-09-29, RD-01):** "around eight good hours is acceptable". Building the best five-creature team is the spine (RD-02): catching, care, training, team building and traversal deepen that journey; they do not turn it into an endless breeding, storage or survival game.

**Routing.** This file owns the catalogue, stats, individuality, bond and catching. `docs/design/TRAINING.md` owns the mechanics of creature power: essence and Tether Candy, level caps and breakthroughs, Masters and Ascension Feasts, evolution lines, traits and Trait Seeds, move acquisition and mastery, the research log and Ripplet's swim/dive progression. COMBAT owns in-fight verbs.

## 1. Ownership, party and identity

| Contract | Status and evidence |
|---|---|
| A stable character owns at most **five** creatures. One may be active; there is no sixth reserve or emergency fighter. | **Current contract, retain.** `autoload/party.gd`, D02/D03, D90, D100-character-persistence-portable-character-world-state-split-and-join-reconciliation. |
| Each creature is a durable individual: stable id, nickname, species, level/xp, HP, energy, bond task state, condition, IVs, traits, boosts and evolution history persist. | **Current.** `scripts/creatures/creature_instance.gd`, `scripts/save/save_game.gd`; D30, D76. |
| The individual also carries its completed breakthrough tiers, rolled and taught traits, move loadout `{quick, charged, utility, ultimate}` and per-move mastery. All survive evolution, save/reload and rejoin. | **Not built (target)** (owner, 2026-09-29, RD-03, RD-11, RD-30); TRAINING §2, §6, §7. Saves reset for this redesign (RD-35), so these fields need no migration from v27. |
| Exactly one party member may carry the **Best Creature** flag. It is mechanical, not a cosmetic favorite: current species data grants either survivability or quick-hit energy gain; legendary `prestige` entries deliberately have no current combat hook. | **Current, retain.** `autoload/party.gd::best`, `scripts/creatures/creature_instance.gd::effective_defence`, `scripts/combat/combat_manager.gd`, `data/creatures/species.json::best_creature`; D30. |
| Catching a sixth is refused before the throw. Capturing never silently releases, boxes or overwrites a creature. | **Current contract.** D03; catch flow and Party capacity. |
| A freed legendary offered as a volunteer is never an Orb target. **Every participant in the fight that freed it receives their own offer, and each participant who accepts keeps their own**, bound to their stable character (owner decision; supersedes the former single-recipient rule). Participation is the host's own record of who fought; a non-participant receives nothing, and no character is offered the same freeing twice. At five, the ceremony requires permanent release or refusal; the legendary is not an owned sixth. | **Target with existing Meadows ceremony foundation.** WORLD §2.3, D84, D96, D100-character-persistence-portable-character-world-state-split-and-join-reconciliation. Tidewake (Abyssal Guardian), Cloudreach (Solmane, freed after Veyra (owner, 2026-09-27)) and Stormwood (Stormheart) must implement and verify the same durable recipient semantics, in the new chapter order (F19#4). |

The creature's owner is the stable character, while spawn state, legendary availability and offer resolution are world facts. MULTIPLAYER owns transfer and reconnect enforcement. There is no breeding, nursery, box, bank, trade market or species storage in the minimum product. Releasing a caught creature is permanent; **target (RD-05, RD-30):** release at the Altar pays type essence once per creature uid and may distil one of its traits into a Trait Seed (TRAINING §1, §6). Release is never a storage workaround: the released individual is gone. The existing authored NPC creature swap remains: exactly one creature leaves and one enters atomically, once per shop rotation; the current source refuses trading the last owned creature, so party size cannot become zero. **Target restriction:** starters and legendary recipients cannot be offered (now potentially one per participant, so this check matters more, not less); the current `scripts/trade/creature_trade.gd::swap()` does not yet enforce those identity checks. Peer-to-peer creature trading is out of scope. Recovery: D39-the-village-economy.

### Current body scale

`data/creatures/species.json` defines the 57 base species at **1.90–7.20m** tall; every one is taller than the1.80m trainer. Pipwing is1.90m, Terrapup3.85m, Veridian5.80m and Abyssal Guardian7.20m, so Veridian is not the tallest creature. Preserve these source values as the current catalogue. Relative-scale repair may grow the smaller side but never shrink a large creature to hide a camera, doorway, slope-contact, arena or attack-distance defect. Water adapters reuse installed presentation under their namespaced semantic definitions and require the same live geometry checks.

## 2. Stats, levels, individuality and damage inputs

**Current source truth:** `data/config/progression.json`, `scripts/creatures/{progression,creature_instance}.gd`, `scripts/combat/{combat_math,type_chart}.gd`.

For base stat `B`, level `L` and per-level growth `g`:

`level_stat = B × (1 + g × (max(L,1) − 1))`

Current growth is HP **0.06**, attack **0.05**, defence **0.05**. Each stat has its own hidden IV `i∈[0,1]`:

`IV_multiplier = 1 + 0.12 × (clamp(i,0,1) − 0.5) × 2`

Thus individuality is **±12%** at the extremes and exactly neutral at 0.5. Show appraisal as 1–5 stars using the current 0.2/0.4/0.6/0.8 thresholds; never expose exact IV numbers. Elixir points add flat after level and IV scaling: Health Elixir **+12 HP**, Power Elixir **+6 attack**, Guard Elixir **+6 defence**. Each creature is capped at+24 permanent elixir points in each stat, and elixirs are never sold. Temporary tonics are a separate current buff system; the same buff id refreshes duration rather than stacking strength. The global creature level cap is **100**. Sources: `data/items/items.json`, `data/config/progression.json::elixirs`, `scripts/creatures/creature_instance.gd::drink_elixir/apply_buff`.

`max_HP = level_stat(base_HP,L,0.06) × IV_HP + HP_boost`

Attack and defence use the same shape at 0.05. Effective attack/defence then apply +1% per completed bond node and any active buff once. The Best Creature survivability multiplier applies only to effective defence; the energy kind applies only to landed-quick energy gain. COMBAT owns the final damage equation and must not apply these bonuses a second time.

**Current type graph, retain:** move type attacks defender species type; attacker species type does not drive the lookup. Named cells use **1.25** advantage or **0.80** resistance, omitted cells are 1.0. Dual types multiply and clamp to **0.64…1.5625**. The current non-neutral graph is:

| Attacking move | 1.25 against | 0.80 against |
|---|---|---|
| Ground | Air | Water |
| Water | Ground, Fire | Air, Ice |
| Air | Water | Ground |
| Fire | Ice, Dark | Water |
| Electric | Water, Air | Ground |
| Ice | Ground | Fire |
| Psychic | Electric | Dark |
| Dark | Electric, Psychic | — |

This is a quiet current rule, not a proposal for louder type dominance. Nature and Light remain outside the current eight-type vocabulary. Recovery: D30, D47, D53-type-effectiveness-move-based-data-driven-three-type-chart and D77-the-baseline-fight-costs-something.

**Target levels and caps (owner, 2026-09-29, RD-03, RD-08):** levels come mostly from essence spent at the Altar, with combat XP as a reduced trickle; caps at L10, 20, 30, 40 and 50 each need a breakthrough, and L60 is this pass's ceiling. The data cap of 100 stays for biomes 5–8. TRAINING §1–§2 owns the rules; PROGRESSION owns the curve.

Out of scope: breeding for IVs, rerolling IVs, exact-IV UI, level scaling the world to the party, a physical/special split, elemental immunity and expanding the chart as an isolated balance change.

## 3. Traits and bond

### 3.1 Individual traits

**Current:** every creature starts with one trait selected from Bold, Calm, Sturdy, Swift, Gentle, Stubborn, Curious and Watchful. A hidden secondary becomes visible at five bond nodes. Traits are identity/flavor data today; they do not alter combat. Evidence: `creature_instance.gd`, `progression.gd::trait_unlocked`, `progression.json`; D30.

**Target (owner, 2026-09-29, RD-30):** traits become a real pursuit. About 30 traits in **Common, Rare and Epic** tiers; each wild creature rolls 0–3, and alphas, night and weather spawns roll better. Traits show on the catch readout and inspect screens. Releasing a caught creature distils one chosen trait into a **Trait Seed**, taught to one of the five in trait slots unlocked at the L10, L30 and L50 breakthroughs. Traits come to the five: there is no pressure to replace a companion to get one. TRAINING §6 owns the pool, rolls, seeds, slots and costs; acceptance is F30#0–#4. Traits never become breeding or a storage metagame.

**Starting effects for the existing eight:** when they join the new pool (proposed as its Common tier; the exact unification is an F30 choice flagged in TRAINING §12), their effects start as small, legible role nudges capped at **5%**:

| Trait | Target effect |
|---|---|
| Bold | Charged-move power ×1.05. |
| Calm | Wind regeneration ×1.05. |
| Sturdy | Effective defence ×1.05. |
| Swift | Combat movement speed ×1.05. |
| Gentle | Healing and care recovery received ×1.05. |
| Stubborn | Poise threshold ×1.05. |
| Curious | Skill cooldown duration ×0.95. |
| Watchful | Burst Wind cost ×0.95; burst distance, timing and lack of invulnerability are unchanged. |

Traits stack with the revealed secondary because each is deliberately small. No duplicate trait on one individual. UI states the effect in plain language. **All trait effects are target work; current traits remain flavor-only.** COMBAT must verify formula order, caps and network presentation before these become current. F30#4 requires the bond-revealed secondary rule to be unified with the new system rather than kept as a parallel one.

### 3.2 Five bond tasks

**Current implementation:** `scripts/creatures/bond_milestones.gd::tier()` counts any completed tasks; tasks are **unordered** despite stale ordered comments in `data/config/bond_milestones.json` and older live prose. Current thresholds are 50 **wild** victories, 3 globally discovered landmarks while the creature is present, 4,000m together, 4 bed nights and 10 feeds. This corrects the earlier audit. Recovery: D76-bond-ladder-is-unordered-and-progression-has-one-feed, FINDINGS DR02. The herd visit now explicitly credits the current owned party through `credit_landmark_visit()` on first personal discovery of `meadowhart_grazing_ground`; the saved map ID prevents repeat credit. This uses current whole-party discovery semantics. It does not implement the candidate per-creature discovery model below or credit later recruits for a place already discovered.

**Parked candidate, outside the four-chapter completion pass under ACCEPTANCE §3:** retain five unordered nodes, discrete completion feedback and the existing +1% attack/+1% defence per node, but replace the thresholds and ownership semantics only through a later evidence-backed spec amendment:

| Node | Target completion rule |
|---|---|
| Victories | This creature participates in **20** victorious wild or trainer encounters. |
| Discovery | This creature is present at **3 distinct landmarks**, even when the stable character already knew them. Credit is per creature and per landmark. |
| Distance | Travel **4,000m** together; current ownership and anti-teleport accounting remain. |
| Rest | Complete **3** creature-bed night rests. Each credited rest must be separated from the previous credited rest by a new credited victory or discovery. |
| Care | Complete **5** credited feeds. A feed counts only when it replenishes at least **10 nourishment** since that creature's previous credited feed. |

The five can complete in any order. Each newly completed node gets a one-time toast, sound and Team-screen mark. Migration must never remove an earned node: preserve all completed old task ids; map incomplete counters forward conservatively; never infer a newly completed per-creature discovery from a global landmark flag. Old saves with five earned nodes stay fully bonded. This target deliberately treats the archived owner's “50 wins” wording as an example to tune, not an owner-locked number.

Out of scope: passive bond merely for elapsed days, ordered gating, relationship decay, repeatable bond farming after five nodes and romance-style dialogue trees.

## 4. Moves, loadout and ultimates

**Current:** every species row below has one quick and one charged move (`species.json::moves`); TMs teach primary-type moves (`data/moves/tms.json`, `scripts/creatures/teaching.gd`).

**Target (owner, 2026-09-29, RD-11):** every creature fights with **three slots plus a signature ultimate**: quick, charged, utility and ultimate. Each species has a learnset (`data/moves/learnsets.json`): base quick and charged at L1, utility options at L5 and L15, further options at breakthroughs. TMs stay under the primary-type rule. Each known move has mastery ranks 1–5 that raise damage and upgrade its effect tier. Loadouts change only at the Altar or a forward camp. **Superseded (owner, 2026-09-29, RD-11):** the one-quick-one-charged move set as the product target, and the parked candidate of one universal L4 Y skill with one equipped skill only. TRAINING §7 owns acquisition, learnsets and mastery; COMBAT owns slot inputs, timings, damage and effect geometry; acceptance is F23#0–#5.

The five former Y-skill families remain useful starting material for the at-least-ten utility moves F23#2 requires (every role can equip at least two):

| Family | Starting geometry/effect (COMBAT owns final values) |
|---|---|
| Snare | Root the struck target for **1s**. |
| Slow field | Place a **2.5m radius** field for **3s**; movement ×0.50 inside. |
| Shove | Swept push up to **2m**, stopped by collision. |
| Dash | Swept **6m** advance, no invulnerability. |
| Veil | After0.20s windup and0.30s recovery, movement×1.40 for **1.5s**; no damage reduction, invulnerability, untargetability or incoming-damage cancellation. |

Utility moves never add blocking, shields, invulnerability or held-button gameplay. The catalogue's "first utility" column (§5) records each species' intended first utility family, which its learnset should offer at L5.

**Ultimates (owner, 2026-09-29, RD-27):** unique ultimates for starters, legendaries and evolved forms only: **Terrapup, Ripplet, Galewisp, Veridian, Abyssal Guardian, Solmane, the Stormwood legendary (Stormheart; current placeholder presentation `fulgocobra`), Tuskroot, Ashtusk, Cannonback, Stormcapra and the storm bear.** Every other species maps to one of 16–20 shared type × role ultimates. Each ultimate grows at every breakthrough. Acceptance is F35#0–#4; COMBAT owns the meter and presentation. Wild Cannonback and Stormcapra use the same unique ultimate as the evolved form.

Out of scope: skill trees, held-charge skills, arbitrary status stacks and a fifth move slot. Recovery for the family designs: D68-the-authored-controller-map-has-no-held-buttons, D77-the-baseline-fight-costs-something and FINDINGS S05/DR08; COMBAT §6.

## 5. Base catalogue — current data and target role

`HP/ATK/DEF`, catch rate, quick/charged move and Best effect are **current source values** from `data/creatures/species.json`. `S` means survivability, `E` energy and `P` prestige; percentage is the configured value. Ride is current. Role and first utility family are **targets** (RD-11, §4). Every row remains one species even when another chapter registers a namespaced semantic adapter. Evolution targets are marked in §7; the storm bear row at the end is the one new creature authorized this pass (RD-28) and does not exist in source.

| Species id | Type | HP/ATK/DEF | Catch | Quick / charged | Best | Traversal | Target role; first utility |
|---|---|---:|---:|---|---|---|---|
| `terrapup` | ground | 120/22/20 | 0.30 | `pebble_toss` / `stone_rush` | S:15% | Ride | balanced bulwark; shove |
| `ripplet` | water | 110/23/18 | 0.30 | `ripple_jab` / `undertow` | E:12% | — (target: swim mount, Dive at L30) | current duelist; dash |
| `galewisp` | air | 105/24/17 | 0.30 | `gale_peck` / `sky_rend` | E:15% | — (target: Fly) | mobile ranged scout; veil |
| `bramblebun` | ground | 95/18/16 | 0.60 | `bramble_whip` / `warren_charge` | S:10% | — | route-denial trapper; snare |
| `mudsnout` | ground | 100/17/18 | 0.55 | `root_nibble` / `rootquake` | E:10% | — | attrition tank; slow field |
| `trailpup` | ground | 105/23/15 | 0.38 | `pack_bite` / `trailblaze_pounce` | E:14% | — | pursuit skirmisher; dash |
| `burrowback` | ground | 110/15/23 | 0.40 | `burrow_strike` / `tremor_roll` | S:18% | Ride | front-line wall; shove |
| `meadowhart` | ground | 115/16/17 | 0.45 | `hoofbeat` / `verdant_burst` | S:12% | Ride | mobile support runner; veil |
| `tuskroot` | ground | 130/24/19 | 0.28 | `root_nibble` / `rootquake` | E:16% | Ride | heavy breaker; shove |
| `paddlenewt` | water | 90/20/12 | 0.50 | `splash_snap` / `riptide_rush` | E:13% | — | ranged setup scout; snare |
| `mosshell` | water | 130/12/26 | 0.40 | `shell_bash` / `tremor_roll` | S:20% | — | endurance anchor; slow field |
| `brooktail` | water | 92/18/13 | 0.45 | `tail_splash` / `riptide_rush` | E:12% | — | reactive current skirmisher; dash |
| `galecrest` | air | 105/28/15 | 0.28 | `talon_dive` / `storm_strike` | E:16% | — | dive ace; dash |
| `duskhush` | air | 96/15/18 | 0.42 | `quick_flit` / `night_swoop` | S:14% | — | evasive ambusher; veil |
| `pipwing` | air | 78/20/10 | 0.55 | `quick_flit` / `gust_burst` | E:15% | — | fragile spotter; dash |
| `reedwing` | water | 90/16/14 | 0.48 | `tail_splash` / `sky_rend` | E:11% | — | cross-type controller; snare |
| `veridian` | ground | 420/46/44 | 0.02 | `hoofbeat` / `antler_slam` | S:20% | Ride | legendary guardian; slow field |
| `nightburrow` | ground/dark | 132/22/28 | 0.10 | `burrow_strike` / `gloom_surge` | S:22% | — | counter tank; veil |
| `stormtrail` | ground/electric | 120/30/18 | 0.14 | `spark_bite` / `trailblaze_pounce` | E:18% | — | pursuit disruptor; dash |
| `riftfrill` | water/psychic | 104/24/16 | 0.16 | `splash_snap` / `rift_pulse` | E:17% | — | ranged mind controller; slow field |
| `ashtusk` | ground/fire | 152/28/24 | 0.12 | `ember_bite` / `rootquake` | S:20% | — | heavy burst breaker; shove |
| `sparkit` | electric | 88/26/13 | 0.45 | `spark_bite` / `arc_lash` | E:15% | — | close spark skirmisher; dash |
| `cindercub` | fire/ground | 108/22/19 | 0.35 | `ember_bite` / `rootquake` | S:14% | — | brawling zone breaker; shove |
| `shadelet` | dark | 98/21/17 | 0.40 | `shadow_nip` / `gloom_surge` | E:14% | — | attrition ambusher; veil |
| `frostclaw` | ice | 112/29/16 | 0.22 | `frost_claw` / `glacier_break` | E:17% | — | glass breaker; snare |
| `cannonback` | water | 95/24/18 | 0.35 | `splash_snap` / `tremor_roll` | S:12% | — | artillery anchor; slow field |
| `riptusk` | water | 95/24/18 | 0.35 | `splash_snap` / `undertow` | E:12% | — | river bruiser; shove |
| `mirejaw` | water | 95/24/18 | 0.35 | `ripple_jab` / `tremor_roll` | E:12% | — | ambush counterattacker; veil |
| `aquaryn` | water | 95/24/18 | 0.35 | `ripple_jab` / `tremor_roll` | S:12% | — | mobile duelist; dash |
| `torrentoad` | water | 95/24/18 | 0.35 | `splash_snap` / `tremor_roll` | S:12% | — | burst gap-closer; dash |
| `cragclaw` | water | 95/24/18 | 0.35 | `shell_bash` / `undertow` | S:12% | — | defensive counter-bruiser; shove |
| `riverdrake` | water | 95/24/18 | 0.35 | `ripple_jab` / `riptide_rush` | E:12% | — | flanking skirmisher; dash |
| `sirenseal` | water | 95/24/18 | 0.35 | `splash_snap` / `tremor_roll` | S:12% | — | ranged controller; snare |
| `mangrove_monitor` | water | 95/24/18 | 0.35 | `ripple_jab` / `tremor_roll` | E:12% | — | shore flanker; dash |
| `tidecoil` | water | 95/24/18 | 0.35 | `ripple_jab` / `tremor_roll` | E:12% | — | surface sweeper; slow field |
| `abyssal_guardian` | water | 220/42/30 | 0.05 | `splash_snap` / `tremor_roll` | P:30% | — | legendary burst controller; slow field |
| `voltwig` | electric | 95/24/18 | 0.35 | `spark_bite` / `arc_lash` | S:12% | — | line harrier; snare |
| `mosshock` | electric | 95/24/18 | 0.35 | `spark_bite` / `arc_lash` | S:12% | — | ambush disruptor; veil |
| `staticub` | electric | 95/24/18 | 0.35 | `spark_bite` / `arc_lash` | S:12% | — | compact peel tank; shove |
| `voltarach` | electric | 140/32/24 | 0.15 | `spark_bite` / `arc_lash` | P:20% | — | arena anchor; slow field |
| `fulgocobra` | electric | 220/42/30 | 0.05 | `spark_bite` / `arc_lash` | P:30% | — | apex lane sweeper; snare |
| `stormraven` | electric | 95/24/18 | 0.35 | `spark_bite` / `arc_lash` | E:12% | — | aerial dive disruptor; dash |
| `pebbik` | air | 95/24/18 | 0.35 | `talon_dive` / `gust_burst` | S:12% | — | air-screen harrier; snare |
| `craghorn` | air | 95/24/18 | 0.35 | `gale_peck` / `sky_rend` | S:12% | — | aerial bruiser; shove |
| `stormbrush` | electric | 95/24/18 | 0.35 | `spark_bite` / `arc_lash` | S:12% | — | mobile screen controller; slow field |
| `tanglevolt` | electric | 95/24/18 | 0.35 | `spark_bite` / `arc_lash` | E:12% | — | tether-zone controller; snare |
| `thundertunnel` | electric | 95/24/18 | 0.35 | `spark_bite` / `arc_lash` | S:12% | — | burrow breaker; shove |
| `glimmermoth` | electric | 95/24/18 | 0.35 | `spark_bite` / `arc_lash` | S:12% | — | fragile ranged decoy; veil |
| `stormcapra` | air | 95/24/18 | 0.35 | `gale_peck` / `storm_strike` | E:12% | — | charge interceptor; shove |
| `skyrill` | air | 95/24/18 | 0.35 | `talon_dive` / `night_swoop` | S:12% | — | night pursuit hunter; dash |
| `aeriex` | air | 95/24/18 | 0.35 | `gale_peck` / `storm_strike` | S:12% | — | high-line duelist; dash |
| `ribbonray` | air | 95/24/18 | 0.35 | `talon_dive` / `gust_burst` | S:12% | — | area screen controller; slow field |
| `breezetail` | air | 95/24/18 | 0.35 | `gale_peck` / `storm_strike` | S:12% | — | ranged kiter; snare |
| `cloudfang` | air | 95/24/18 | 0.35 | `quick_flit` / `sky_rend` | E:12% | — | ambush diver; veil |
| `cliffspike` | air | 95/24/18 | 0.35 | `quick_flit` / `storm_strike` | S:12% | — | terrain punisher; shove |
| `tempestwing` | air | 140/32/24 | 0.15 | `quick_flit` / `gust_burst` | P:20% | — | elite air controller; slow field |
| `solmane` | air | 220/42/30 | 0.05 | `quick_flit` / `sky_rend` | P:30% | — | legendary sky guardian, volunteered after Veyra, never wild or catchable (the summit wild tables use `tempestwing`); veil |
| storm bear (*Stormursa*, working name) | electric | **target**, set by F29 | not wild | **target** learnset | **target** | — | **Not built (target):** Staticub's L50 evolution; larger than Staticub and taller than the trainer; flag-gated until its code-blind PASS (F29#3) |

The eleven mono-Electric species deliberately stop being one `spark_bite/arc_lash` role: Sparkit closes, Voltwig pins a line, Mosshock counters, Staticub peels, Voltarach anchors, Fulgocobra sweeps lanes, Stormraven dives, Stormbrush screens, Tanglevolt zones, Thundertunnel breaks formations and Glimmermoth decoys. Their first utility family is only the first differentiator; encounter behavior, ranges and presentation must prove the role without changing mesh identity.

## 6. Tidewake semantic adapter catalogue

**Current:** `data/config/water_roster.json` registers twelve `water_*` ids atomically. Each has its own semantic stats, moves, role, catch rate and Best source while reusing installed presentation safely. Each registered creature still uses the common individual IV, trait, bond and condition systems in §§2–3. Namespacing prevents `water_mosshell` from overwriting base `mosshell`. Presentation inheritance never grants traversal; only five explicit compatible rows are swim mounts. `water_mounts.json` contains measured starting geometry but its own comments correctly withhold final visual/network acceptance. Recovery: D118/D119 and FINDINGS MP/decision inventory.

| Runtime id | HP/ATK/DEF | Catch | Quick / charged | Adapter / Best source | Current semantic role | Swim mount | Target first utility |
|---|---:|---:|---|---|---|---|---|
| `water_cannonback` | 140/19/27 | 0.30 | `aqua_shot` / `tidal_burst` | `mosshell` / `mosshell` | ranged anchor | 6.3m/s, stamina 210, drain 1.8/s | slow field |
| `water_riptusk` | 138/29/20 | 0.25 | `pack_bite` / `riptide_rush` | `tuskroot` / `tuskroot` | shore bruiser | — | shove |
| `water_aquaryn` | 154/30/24 | 0.16 | `aqua_shot` / `riptide_lance` | `paddlenewt` / `paddlenewt` | alpha mobile duelist | 10m/s, stamina 200, drain 2/s | dash |
| `water_tidecoil` | 165/33/20 | 0.12 | `splash_snap` / `leviathan_surge` | `paddlenewt` / `paddlenewt` | late apex surface sweeper | — | slow field |
| `water_mirejaw` | 125/28/18 | 0.30 | `splash_snap` / `undertow` | `paddlenewt` / `paddlenewt` | ambush counterattacker | — | veil |
| `water_torrentoad` | 118/26/18 | 0.40 | `ripple_jab` / `riptide_rush` | `ripplet` / `ripplet` | burst gap closer | — | dash |
| `water_cragclaw` | 138/21/29 | 0.32 | `shell_bash` / `tremor_roll` | `burrowback` / `burrowback` | defensive counter bruiser | — | shove |
| `water_riverdrake` | 118/28/18 | 0.30 | `tail_splash` / `riptide_rush` | `paddlenewt` / `paddlenewt` | flanking skirmisher | 9.2m/s, stamina 160, drain 2/s | dash |
| `water_sirenseal` | 116/23/20 | 0.35 | `aqua_shot` / `undertow` | `brooktail` / `brooktail` | ranged controller | 8.5m/s, stamina 180, drain 2/s | snare |
| `water_mangrove_monitor` | 108/27/17 | 0.38 | `splash_snap` / `trailblaze_pounce` | `paddlenewt` / `paddlenewt` | shore flanker | — | dash |
| `water_mosshell` | 130/12/26 | 0.40 | `shell_bash` / `tremor_roll` | `mosshell` / `mosshell` | endurance tank | 6.8m/s, stamina 240, drain 1.7/s | slow field |
| `water_abyssal_guardian` | 178/34/27 | 0.08 | `aqua_shot` / `leviathan_surge` | `paddlenewt` / `paddlenewt` | legendary burst controller | — | slow field |

All twelve remain Water type under current data. Adapter registration must fail as a unit on collision or bad data. Save/load uses the namespaced id. Catch rate is only the species term in catch math; weakening, orb modifier and the physical aim/throw still decide the attempt. The player pays for catching by handing control from the active creature to the exposed human, not by sacrificing a party slot. Recovery: D08, D53-water-runtime-roster-atomic-registration-and-semantic-separation.

## 7. Evolution, starters and traversal promises

**Current evolution line:** Mudsnout is the only evolving base species. At level **15** and bond tier **3**, the held catalyst selects **Heartstone → Tuskroot** or **Sunstone → Ashtusk**. `data/config/progression.json` carries the shared gate/default Heartstone requirement; `data/creatures/species.json::evolves_into_variants` and `scripts/creatures/evolution.gd::requirements()` add the Sunstone branch. Holding both refuses with an ambiguity reason instead of silently choosing. Neither Tuskroot nor Ashtusk spawns wild. Evolution preserves the same stable id, nickname, level/xp, bond task history, condition, IVs, traits, boosts and Best flag. It is transformation, never replacement. Recovery: D17, D20, D71-mudsnout-branches-into-tuskroot-or-ashtusk and D76.

**Target (owner, 2026-09-29, RD-28): one evolution line per biome, each at a breakthrough feast, evolving optional.** **Superseded:** Mudsnout's L15 + bond-tier-3 gate; Heartstone and Sunstone become the extra ingredient of Mudsnout's L20 feast.

| Line | Breakthrough | Evolved form in the wild |
|---|---|---|
| Mudsnout → Tuskroot (Heartstone) or Ashtusk (Sunstone) | L20 | No |
| Mosshell → Cannonback | L30 | Yes, where it already appears (Tidewake) |
| Craghorn → Stormcapra | L40 | Yes, where it already appears |
| Staticub → storm bear (new; working name *Stormursa*) | L50 | No |

Feeding the tier's feast to an eligible creature offers **evolve or stay**; staying is permanent for that tier and the cap still lifts. Evolution keeps the complete individual: uid, nickname, level, bond history, IVs, traits, loadout and mastery (F29#2). Evolved forms are always larger than their source (D17) and taller than the trainer; the storm bear is a Codex Meshy asset, flag-gated until its code-blind PASS. TRAINING §4–§5 owns the mechanics; acceptance is F29#0–#4.

**Starters and legendaries do not evolve** (RD-28 keeps the starter rule). Terrapup, Ripplet and Galewisp are mutually exclusive starters; the uncaught two do not enter the ordinary wild pool. Each starter and legendary gets a unique ultimate instead (§4).

**Traversal (owner, 2026-09-29, RD-32; target except Ride):**

| Starter | Traversal | From |
|---|---|---|
| Terrapup | Ride (**current**) | Meadows |
| Ripplet | Surface swim mount, faster than human swimming and able to cross currents; **Dive** (tap toggle, never held) at its L30 breakthrough | Tidewake opening |
| Galewisp | Fly (held input allowed) | Cloudreach unlock |

**Superseded (owner, 2026-09-29, RD-32):** the Ripplet starter's Teleport promise after Stormwood completion and a Stormglass-arch attunement. The Home Key now provides fast travel (WORLD). Every required water route stays human-swimmable without Ripplet (F37#2). Each promise follows that individual starter and cannot be replaced by catching a duplicate because no duplicate is legally available. TRAINING §9 owns swim/dive progression; acceptance is F37#0–#4. The current Heart of Meadows power, **Meadowstride**, doubles the trainer's maximum stamina (`data/config/realm_hearts.json::max_stamina_multiplier=2.0`); it does not double creature combat Wind.

Galecrest may be a temporary Cloudreach loaner for a trial and authored routed transport. It is never added to the owned five, carries no portable progression, cannot enter combat as a sixth and cannot bypass the party cap or permanently substitute for the Galewisp promise.

Out of scope: broad evolution trees beyond the four lines, evolving starters or legendaries, de-evolution, evolution losing history, catching starters later, permanent rental-party slots, flying past unopened portals and fast travel that bypasses story or interior residency gates.

## 8. Catching, release, care and acceptance

**Current:** only a weakened wild can be caught; trainer and legendary encounters refuse. Aim hands control to the human while the active creature remains exposed. Species catch rate, HP state and orb determine probability; the host resolves shared attempts. A successful catch inserts one durable individual only when capacity exists. Recovery: D07/D08/D31, MP encounter protocol.

**Target additions:** Tether Snare (COMBAT, F24) slows a wild and raises catch chance within a bounded modifier; it can never target a trainer-owned creature (RD-12). The catch readout shows the wild's rolled traits (F30#1). **Catch and release are a loop, not a storage system (RD-05, RD-30):** releasing a caught creature at the Altar pays its type essence once per uid and optionally distils one trait into a Trait Seed; the research log credits species met, released and never kept (F45). The payout rate is bounded so catch-and-release cannot mint unbounded value (F47#4). TRAINING §1, §6 and §8 own the numbers.

Care is light: nourishment and happiness persist, feeding helps, beds heal **assigned** creatures over world time and a night completes occupied-bed recovery. Zero nourishment does not deal health damage. **Target:** care at the Den pays a small capped essence trickle (TRAINING §1). **Current:** Strain is absent from `scripts/creatures/creature_condition.gd` and `scripts/creatures/creature_instance.gd`. **Candidate target, not built and not a first-fun prerequisite:** SYSTEMS owns the bounded0.25 Strain rule and effective-HP ceiling; UX owns its presentation. COMBAT consumes the same value for switching, poise normalization and uninjured-health acceptance. Recovery: FINDINGS S25–S26 and the plan's explicit bounded-injury replacement.

Retaining the same five companions through the campaign is success; later catches are optional and their rewards (essence, seeds, research) primarily deepen the existing team. The move loadout (RD-11) is now authorized scope; the revised bond thresholds and Strain remain parked candidates. Acceptance for the redesign lives in ACCEPTANCE §6.2: F23 (moves), F27 (essence), F28 (breakthroughs), F29 (evolution), F30 (traits), F35 (ultimates), F36 (art and scale), F37 (Ripplet) and F45 (research). These regression expectations still hold for every creature change:

- Every catalogue id loads, saves, rejoins and reconstructs the same individual; all five cap paths refuse a sixth.
- Every species' quick, charged and utility actions have a distinct readable role in live combat, with specific attention to the eleven shared Electric pairs.
- Target bond migration preserves every earned node and prevents global-landmark, spam-feed and repeated-sleep shortcuts.
- Evolution preserves the complete individual and refuses ambiguous catalyst consumption.
- Each promised traversal works for owner and remote peers, through mount/dismount, portal travel, save/load and reconnect.
- Every eligible fight participant's personal legendary ceremony is durable, announces that character's irreversible choice before commitment and never duplicates on reconnect; the world freeing occurs once.
- Catch UI exposes the control-handover risk and capacity refusal before spending an Orb.
- Release payouts, seed distils and feasts never duplicate through reconnect or reload.

Keep mechanic testing minimal: do not create repeated cohorts or a new harness programme. Required regression, save/reconnect and two-player/four-player network evidence remains required for whichever target features are selected. Existing tests are regression foundations, not proof that roles are fun or silhouettes readable. Out of scope remains breeding, peer-to-peer trading or a trade market, creature storage, PvP creature loadouts, procedural species, endless postgame tiers (the bounded rematch tiers of RD-31 are not endless) and any sixth owned slot.
