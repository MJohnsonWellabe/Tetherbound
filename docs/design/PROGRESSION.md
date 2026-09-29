# Progression and pacing

This is a build contract, not a claim of a completed campaign. **Built** means the described behavior is implemented at `b8eda885` (or at `1c3f0b0d` where named), not merely that a path or config key exists; **partial** means the player path or rule is incomplete; **not built** denotes the target being commissioned. Owner redesign decisions of 2026-09-29 are cited as "(owner, 2026-09-29, RD-nn)" from `CODEX_START_HERE.md` §1; **every one of them is Not built (target)**. COMBAT owns damage, CREATURES owns individuals/bond, TRAINING owns the mechanics of creature power (essence, caps, Masters, feasts, evolution, traits, move mastery, research), HOMESTEAD owns stations, recipes and gear, SYSTEMS owns supplies and recovery, WORLD owns gates and geography. This file owns the level curve, the time budget, ledgers and solvency, the reward schedule and the repeatables.

## 1. What progression buys

**The spine is creature power (RD-02).** The player is always building the best five-creature team. Levels, breakthroughs, gear, moves, mastery and traits make the five clearly stronger; portal keys, relics and traversal open the world. The homestead is the required engine that produces creature power, and each biome asks for real preparation: gather, train, craft, build (RD-01). A higher number alone is still not a chapter reward: each tier should also bring a decision (which creature to raise, which trait to teach, which loadout, evolve or stay).

**Built:** level/stat arithmetic in `scripts/creatures/progression.gd`, instance persistence in `scripts/creatures/creature_instance.gd`, level and XP values in `data/config/progression.json`. **Partial:** the four source ladders and flags exist in the old chapter order, but an earned clear and balanced five have not been accepted; Grandpa's current-party acknowledgement after Water restoration, with personal saved completion (`scripts/story/regional_homecoming.gd`), exists but moves to after Stormwood (F20). **Not built (target):** hybrid leveling, caps and breakthroughs, the new chapter order and curve, essence and material ledgers, repeatables and the 15–25 hour clear.

**Pacing and scope decision (owner, 2026-09-29, RD-01): a loop that is fun to grind but optional to repeat.** Target **15–25 hours** for a normal clear. The main path is finishable without padding and without mandatory repeat grinding (F27#5, F47#1); players who grind get clearly stronger, and optional grinding must measurably speed progress. Preparation is real play (a Master to find, a feast to gather, gear to forge), not filler: do not add errands, empty travel, backtracking or XP walls to meet the clock. **Superseded:** "around eight good hours is acceptable", "no grind" and "do not add … XP requirements to fill time" as binding rules (§9).

Out of scope: character combat levels, skill trees, respec currency, prestige resets, infinite scaling, battle passes, real-time daily login rewards, and a postgame grind needed to see the ending.

## 2. Arithmetic and award ownership

**Hybrid leveling (owner, 2026-09-29, RD-03), target:** essence and Tether Candy spent by choice at the Altar are the main level source; combat XP continues as a reduced automatic trickle; caps every ten levels need a breakthrough. TRAINING §1–§2 owns the rules; this section owns the arithmetic.

Retain the current source curve as the base:

- `XP_to_next(L) = floor(40 × max(L,1)^1.15)`; starter level 3. **Current:** global cap 100. **Target:** `level_caps = [10, 20, 30, 40, 50, 60]` live, `[70, 80, 90, 100]` reserved for biomes 5–8 (RD-08, RD-09); L60 is this pass's ceiling. A capped creature banks no XP.
- A defeated opponent of level L pays `floor(30 + 16L)` to the active eligible creature. Each other eligible living party creature receives `floor(award × 0.50)`; this is a share award, not a division of a fixed pool by five. **Target:** both are multiplied by `auto_xp_scale`, starting **0.35** (tune in F47), never zero.
- **Target essence spend:** the cost to raise a creature one level rises with level, set per band in `data/config/essence.json`; starting curve `ceil(XP_to_next(L) / essence_xp_value)` with `essence_xp_value = 25`. One Tether Candy pays one level for any creature (starting rule).
- Current source growth is HP 6%, attack 5%, defence 5% of base per level above 1. CREATURES owns IV, boost and bond formula order.
- Authored trainer/quest XP bonuses remain in their source rows. An opponent's defeat and encounter completion are separate event IDs: each individual defeat pays once (XP and, target, its essence), and its encounter bonus pays once. Reconnecting, accepting a queued reward twice or losing the last member cannot repeat completed payouts.
- A successful capture receives only the catch path's existing award, never a forged defeat event. Do not add another generic catch XP source. Fainted members miss combat XP but can receive the separate rest bonus.
- Retain the flat rest bonus 5, once per party member after a night preceded by a new eligible encounter or discovery. Persist the earned-day receipt. No repeated sleep-for-XP loop.

There is no XP loss on death, no party XP tax for co-op and no reward for killing a creature already removed by another accepted host transaction. Catch, dialogue reward, trainer victory, release payout, research and bounty use distinct ledgers with their own transaction ids (TRAINING §10). The redesign resets saves (RD-35); later changes to these ledgers require save migration again.

## 3. Four-chapter curve (new order)

**Target (owner, 2026-09-29, RD-10):** Meadows → Tidewake → Cloudreach → Stormwood. `data/config/biome_order.json` (F16) holds the order; F19 applies the curve and pins it with a curve test (F19#1).

| Biome | Team in→out | Wild | Boss team | Masters (breakthrough) | New power and strategic change | Boss drops (every participant) |
|---|---|---|---|---|---|---|
| Meadows | 3→22 | 2–20 | Warden ~21–22 | L10 mid-Meadows (River Lock/Quarry); L20 upper Meadows before the Crossing Hall | Named starter and team; camp and homestead; Altar and essence; first TMs; saddle; Mudsnout's L20 evolution; Meadowstride | Heart of the Meadows relic + Tidewake portal key |
| Tidewake | 20→33 | 18–32 | Nerissa ~32–33 | L30 outer island | Human swimming and currents; Ripplet swim mount and L30 Dive; Mosshell's L30 evolution; Tidal Guard; Abyssal Guardian offer; dock exchange closes the chapter | Tideglass relic + Cloudreach portal key |
| Cloudreach | 31→44 | 29–43 | Veyra ~43–44 | L40 high perch (Fly) | Wingroads and Fly; aerial route judgment; Craghorn's L40 evolution; Skyborne; Solmane offer | Wings relic + Stormwood portal key |
| Stormwood | 42→55 | 40–54 | Finale ~54–55 | L50 deep storm | Stormglass routes, grounding; Staticub's L50 evolution; Livewire; Stormheart offer; Home Key homecoming and credits | Spark relic + fifth portal key |

Every biome exit exceeds a cap (22, 33, 44, 55 against 20, 30, 40, 50), so each biome requires its Master and feast before its boss is comfortable; Meadows requires two. L55–60 is post-credits headroom for the endgame rematch tier (§6).

**Superseded (owner, 2026-09-29, RD-10):** the old order Meadows → Cloudreach → Stormwood → Tidewake and its curve (Meadows L3→21 with bands 3→9→12→15→17→21 and Warden 18/18/19/19/20; Cloudreach L18–21→33; Stormwood 33→44; Tidewake 43→55 ending the game). Those values remain the **current source facts** in `data/config/chapter_curve.json`, `data/config/bands/*`, `cloudreach_*.json`, `stormwood_*.json` and `water_*.json` until F19 re-derives every wild range and named-trainer team in the new order, including the Meadows band splits inside 3→22.

Retain the recovered curve constraints: wild high ≤ regional exit; wild low ≤ entry; wild high ≥ entry − 2; no backwards regional band; at least six wild options per Meadows band; ordinary replacement catch deficit ≤ 2 relative to intended regional entry. Optional trainers may be harder, visibly signposted and avoidable.

**Gates (RD-10, RD-17, RD-20).** The boss-dropped portal key, used once on its arch, is the only hard gate between biomes. Each portal sign shows the recommended level; no hidden level gate exists (F19#5). **Superseded:** physical crossings between biomes, and `min_level` as an inter-biome gate. The D75/D79 rule (a visible, in-character `min_level` on a named critical gatekeeper, reading the party's highest creature, derived from the next band's measured entry) survives only inside a biome; an invisible generic "must reach level X" wall stays prohibited. Recovery: D75-the-level-gate-placement-rule and D79-the-level-gate-measures-the-partys-highest-creature.

Meadows Band 5 is a named cadence exception: it is short on purpose and must not be padded to satisfy a generic density average. Only three basic supplies may sit on its road; the final waystop offers no heal; recovery precedes the attrition; and no ordinary recovery lies between the Sigil gate and Outer Works except a rare authored reward. D70-band-5-is-short-on-purpose and D78-band-5-findables-sit-off-the-road govern this exception. F19 decides whether the re-derived Meadows split keeps it intact.

The current Meadows test `tests/test_trainers_data.gd::test_the_critical_path_alone_pays_for_the_warden_ready_level` is useful arithmetic evidence for the old curve only. Under hybrid leveling it is replaced by the F27#5 route ledger (§7).

## 4. Time budget and pacing illustration

**Target (RD-01):** a 15–25 hour normal clear, estimated by an agent-piloted normal route and confirmed by the owner's play pass (F47#0). Count only earned ordinary play. The core loop is 15–30 minutes: pick a goal, portal out, fight/catch/release/gather, Home Key back, spend and craft, portal out (`CODEX_START_HERE.md` §2). Starting planning estimate, measured and not a quota: opening + Meadows 5–7 h, Tidewake 3.5–6 h, Cloudreach 3.5–6 h, Stormwood 3.5–6 h.

| Sequence | Intended experience and earned state |
|---|---|
| Opening | Grandpa, named starter, **Home Key**, a patch of land, real practice fight/catch, five-space rule, village camp and tournament readiness. |
| Meadows | Cross South Bridge; Quarry/Warrens and River Lock; first Altar spend; L10 Master and feast; ride into Upper Meadows; earn Sigils; L20 Master before the Hall; prepare for and defeat the Warden; resolve Veridian's per-participant offer; hang the relic, unlock Meadows attachments; open the Tidewake portal. |
| Tidewake | Learn safe human swimming/currents; optionally ride Ripplet; L30 Master on the outer island; approach Nerissa and the Abyssal Guardian; dock exchange closes the chapter (no credits); Tideglass relic and Cloudreach key. Aquaryn and Tidecoil remain optional. |
| Cloudreach | Learn vertical wayfinding and Fly; reconnect the wind roads; L40 Master on a high perch; challenge Veyra; free Solmane (per-participant offer, owner 2026-09-27); Wings relic and Stormwood key. |
| Stormwood | Read grounded/exposed terrain; repair the Stormglass route; L50 Master; the Long Storm; Stormheart's offer; the finale; Spark relic and fifth key; use the Home Key for Grandpa's homecoming with the actual five; credits; the fifth arch stirs (RD-22). |
| After credits | Bounties, rematches at L55–60, alpha respawns, research completion (§6). |

Retain the opening's 35–55 minute and Meadows stronghold's 30–60 minute ranges as provisional pacing checks, not floors. If measured play runs long, remove repeated errands and compulsory backtracking and adjust earned-route rewards before cutting authored land or chapter identity. If it runs short, deepen preparation choices (Masters, feasts, gear, traits) rather than padding. Named-fight timing stays with COMBAT/BOSSES.

## 5. Reward schedule and optional content

**Target:** rewards arrive where the route creates a useful choice, without a fixed minute interval. Prefer creature power (essence, a breakthrough recipe, a Trait Seed, a TM, gear materials, an evolution), a route or traversal capability, a world change or a recipe. Coins and duplicate berries alone are weak milestone rewards.

| Source | Pays (target) | Once or repeatable |
|---|---|---|
| Wild defeat | Reduced XP, type essence, occasional shed drop | Per defeat event |
| Catch then release | Type essence by level; optional Trait Seed; research credit | Once per creature uid |
| Master win | Feast recipe (per character), Tether Candy | Recipe once; rematch rewards cycle (§6) |
| Boss | Relic and next portal key per participant, Tether Candy, legendary offer per participant | Once per character |
| Feast fed | Cap lift, trait slot at L10/L30/L50, ultimate growth, evolution offer | Once per creature per tier |
| Research task | Type essence; biome title at 100% | Once per task per character |
| Bounty / rematch / alpha | §6 | Cycle-limited |

Each chapter retains 6–10 meaningful optional activities, at least one per principal region. WORLD specifies their identity. A reward is committed with objective completion once. Later catches remain optional; primary rewards deepen the five the player already loves rather than pressure replacement.

Classify every activity: **team** (move, breakthrough, evolution, trait, gear), **route** (shortcut, waystone, safe camp, traversal), **world** (local change, person rescued), **care** (recoverability, recipe). Each chapter contains all four classes. At most half may end in a generic item chest. Information about an already-known destination is not a reward unless it opens a real alternate approach.

Preserve the primary-type TM restriction, consumable TM application and current item catalogue. Essence and Tether Candy are new progression items (RD-04); no shop sells them and no other new currency is added. Required recipe inputs lie on the accessible side of the gate they unlock (F28#5); optional TMs, boosts and gear may never be needed to make entry-level combat survivable.

## 6. Repeatables (owner, 2026-09-29, RD-31), target

All four are optional, never required to see the ending, and bounded so none mints unbounded value (F47#4).

| Repeatable | Rule | Scope | Acceptance |
|---|---|---|---|
| Bounty board | Halda's board posts three bounties each in-game morning from unlocked biomes only: catch with a trait, defeat an alpha, deliver materials, win a rematch. Pays essence, Tether Candy, materials, occasionally a Trait Seed, once per bounty instance. | Personal (character); host validates | F43#0–#3 |
| Rematches | After a biome's boss, its named trainers, captains and Master rematch at the next biome's level for better rewards. After credits, leaders and bosses return at L55–60. Unique rewards pay once; repeatable rewards follow a cycle (starting value: once per trainer per 3 in-game days, `data/config/rematches.json`). | Availability world; reward receipts character | F44#0, #1, #3 |
| Alpha respawns | Alphas respawn every configured number of in-game days (starting value 3) with freshly rolled, better traits. | World | F44#2 |
| Research log | Species tasks and biome completion (TRAINING §8). | Character | F45#0–#3 |

**Superseded (owner, 2026-09-29, RD-31):** "no enemy scaling tier after the ending" and "a trainer rematch is not assumed" (all 31 Meadows trainer entries currently set `rechallenge` false; F44 changes that data).

## 7. Economy proof: ledgers and safety margin

**Built:** item/recipe catalogues, `data/config/trade.json`, harvest/pickup configs and trainer payout rows. **Not built (target):** essence and tier-material ledgers for the new order, and four-character contention ledgers. SYSTEMS specifies starter 30 coins, Orb 22, potion 28, revive 80 and proposed limited road stocks. The exact opening pack in UX is protected.

For each required route, compute every ledger from reachable source rows, not circular map radius:

`ending stock = starting stock + guaranteed reachable reward + affordable vendor purchase − required crafts − observed consumption`.

**Essence ledger (F27#5, F47#1).** Per biome band and per type: `main-path essence (defeats, required catches released, on-route attuned nodes, care trickle, research tasks met on route) + main-path Tether Candy + auto-XP levels` must raise a five-creature team from band entry to the next band's entry without mandatory repeat grinding. Because a team's types need not match a biome's wilds, every type must be reachable in every biome (1–2 attuned nodes per type per biome and the eight home type crops, HOMESTEAD F32). A second report measures essence per hour for the optional loops (alpha hunting, catch-and-release, crops, bounties) and shows grinding measurably speeds progress.

**Material ledger (F28#5, F47#1).** Per tier: five feasts (tier materials plus five attuned ingredients), a Harness and Charm for five creatures with the upgrades the tier's boss assumes (F33#2), that biome's four station attachments, and the forward-camp kit. Every input is reachable in or before its biome.

Run each ledger for novice successful play, a two-loss recovery case and four characters sharing permanent nodes. The first camp costs 18 wood / 8 stone / 18 fiber; complete tournament preparation adds two beds for a total 30 wood / 8 stone / 34 fiber. The optional workbench adds 10 wood / 4 stone. Starting resources and gifts cannot be counted again on reload. Set available supply ≥ 150% of solo mandatory cost along the intended path; for four players include four personal required kits (feasts, gear) plus world-owned structures only once. If supply fails, add authored sources or personal guaranteed quest bundles; do not silently turn all nodes into infinite respawn.

**Co-op (RD-21).** Every fight participant receives their own portal key, relic and legendary offer; recipes, tiers, essence and gear are personal; station buildings are world-owned and a guest uses the host's stations at the host's tier. **Superseded:** "essential keys and a single legendary do not multiply". Shared physical chests and resource nodes remain contested according to MULTIPLAYER (F47#2 contention ledgers).

**Exploits (F47#4).** No loop mints unbounded value: buy/resell cannot profit; repeated rest cannot mint stock, XP or essence; a release pays once per uid and the catch-and-release net rate (payout minus Orb cost and time) stays within the intended optional rate; bounty rerolls are impossible; rematch and alpha rewards are cycle-limited. No shop sells elixirs, essence or Tether Candy; permanent boosts cap 24/stat.

Target emergency reserve before each major gauntlet: one viable entry-level creature, a reachable legal recovery bed (home, inn or forward camp), and capacity to obtain two basic heals through existing rewards, trade or craft. A player who spends every coin retains free bed recovery, free repair and reachable basic food, and can resume without a new save. Never solve insolvency with human-huntable drops or leather; shed drops only (RD-14).

Out of scope: auction house, dynamic prices, offline production, a real-time daily reset economy and a separate co-op currency.

## 8. Gates and accounting

Readiness should make the opening teach the real game. `data/config/tournament.json` requires five owned creatures and level 5 across the five strongest; those are sticky learned milestones. The current source registers an ordered three for each round, and only those three are checked for fed, rested and happy state at consent. The recovered care contract still requires one affordable physical creature bed per entrant. The initial one-bed camp is insufficient: tent + campfire + bedroll + three beds total **30 wood, 8 stone, 34 fibre**, and the bedroll must fit inside shelter large enough to read as usable. Show every unmet requirement before consent. A completed readiness lesson is a saved milestone, not a rule forcing every future released replacement back through the tutorial. The L5 readiness sits below the L10 cap, so no breakthrough is needed before the tournament.

The tournament is an eight-slot board with exactly three player fights (Mira, Tam, Oskar) and four simulated named entrants. The Team Tether South Bridge grunt gates the crossing before Oskar's later final. Oskar's final uses a mounted Meadowhart; winning grants the saddle recipe before later Rootstone access. Target loss handling preserves the round, heals the registered three and permits retry; the final line restores the party, while Halda's post-win line explains the mounted payoff without owning the reward. Sources: `data/config/tournament.json`, `data/config/bands/band1_lower_meadows/trainers.json`, `data/dialogue/bands/band1_lower_meadows.json`, `scripts/world/tournament.gd`.

Later gates use earned story flags, portal keys and in-biome passages, never an unseen party-average calculation. WORLD §2.5 fixes ordinary wild-site return after two world days. XP, essence, Orb and recovery solvency must pass an earned route with no mandatory repeat wild encounters; respawn and repeatables are optional, never mandatory grind.

Task counts derive from stable source IDs: 31 Meadows battle entries are not 31 unique people; 16 overworld alpha sites plus Warrens are distinct; caught or beaten resolves an alpha until its respawn (§6). Resource surveys count permanent nodes; camp tasks require a rest at that location. No second reward for displaying an earned Sigil pin.

**Target acceptance:** the player can explain the next goal before a gate (F46#1); the ordinary earned route makes the retained five viable at each chapter exit without mandatory repeated farming; optional grinding makes them clearly stronger; later catches are optional and, when chosen, become useful from rewards earned on that route. Retaining the same five beloved companions is a successful progression outcome. A comparison of completed saves verifies no duplicate XP, essence, currency, recipe, key, relic or legendary after failure, reload or client reconnect (F48#1). F47 tunes the curve from measured route data; the retained XP exponent stands, and the longer clear comes from preparation, never from an inflated XP curve or a per-region activity quota.

### Tournament selection resolution

The current source distinguishes ownership/training from the tournament field: own five and achieve level 5 for all five once, then register an ordered three for each round. `autoload/party.gd` stores the three by durable creature UID, resolves them after party reorder, and clears the registration when a selected member is released; it never fills a missing slot with a replacement. `scripts/world/tournament.gd` checks care only for those three, while `scripts/ui/tournament_team_picker.gd` keeps all five visible and limits deployment to the registered order. `scripts/save/save_game.gd` and `scripts/save/character_save.gd` persist the selection through the v27/v6 migration; older saves keep readiness and wins but begin unregistered (the redesign's save reset, RD-35, refuses v27-and-older saves instead). Selection and the three-bed preparation consumers are implemented: the journal counts existing bed milestones, Halda checks them before first entry, and the gathering target includes all three beds. Already-entered saves retire the lesson. Full earned supply/care, rendered readiness and chapter acceptance remain unproved.

## 9. Superseded rules record

| Former rule | Disposition |
|---|---|
| "No mandatory 12–16 h floor; an earned clear around eight good hours is acceptable" | Superseded (owner, 2026-09-29, RD-01): 15–25 h normal clear. |
| "Do not add fights, errands, travel, resource scarcity or XP requirements to fill time"; no grind | Superseded in part (RD-01): the main path still carries no padding or mandatory repeat grind, but each biome requires real preparation and optional grinding is a designed loop. |
| Combat XP as the sole level source | Superseded (RD-03): hybrid leveling with essence and caps. |
| Chapter order Meadows → Cloudreach → Stormwood → Tidewake; ending in Tidewake | Superseded (RD-10, RD-22): Meadows → Tidewake → Cloudreach → Stormwood; ending after Stormwood by the Home Key. |
| Physical crossings and `min_level` between biomes | Superseded (RD-17, RD-20): portal keys are the only hard gate. |
| Mudsnout evolution at L15 + bond tier 3 | Superseded (RD-28): L20 feast (TRAINING §5). |
| No trainer rematches; no scaling tier after the ending | Superseded (RD-31): §6. |
| "Daily quests" out of scope | Superseded in part (RD-31): bounties refresh each in-game morning; real-time daily rewards stay out. |
| Keys and legendary offers do not multiply in co-op | Superseded (RD-21; owner 2026-09-27 for legendaries). |
| "No new currency" | Amended (RD-04): essence and Tether Candy are items, not a shop currency. |
