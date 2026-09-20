# Progression and pacing

This is a build contract, not a claim of a completed campaign. **Built** means the described behavior is implemented at `b8eda885`, not merely that a path or config key exists; **partial** means the player path or rule is incomplete; **not built** denotes the target being commissioned. COMBAT owns damage, CREATURES owns individuals/bond, SYSTEMS owns supplies and recovery, WORLD owns gates and geography.

## 1. What progression buys

The player becomes competent with five remembered companions and gains access to a connected world. Levels supply a gradual margin for error; skills, move geometry, routes, riding and relic selection supply new decisions. A higher number alone is not a chapter reward.

**Built:** level/stat arithmetic in `scripts/creatures/progression.gd`, instance persistence in `scripts/creatures/creature_instance.gd`, level and XP values in `data/config/progression.json`. **Partial:** the four source ladders and flags exist, but an earned clear and balanced five have not been accepted. **Partial branch slice:** Grandpa's current-party acknowledgement after Water restoration, with personal saved completion (`scripts/story/regional_homecoming.gd`). The full Tidewake return/credits/ending and economy solvency remain unbuilt or unproved. **Candidate targets:** universal L4 Y skill and revised bond credit. The skill and bond revisions are not prerequisites for the first owner fun check.

**Owner pacing override:** there is no mandatory 12–16-hour campaign floor or 3–4-hour chapter floor. An earned, enjoyable clear around eight hours is acceptable. Do not add fights, errands, travel, resource scarcity or XP requirements to fill time. First prove the existing expedition loop in one 15–30 minute owner check; expand or implement candidate mechanics only when that check identifies a concrete need. Keep this mechanics testing to the minimum needed for the decision.

Out of scope: character combat levels, skill trees, respec currency, prestige resets, infinite scaling, daily quests, battle passes and a postgame grind needed to see the ending.

## 2. Arithmetic and award ownership

Retain the current source curve initially:

- `XP_to_next(L) = floor(40 × max(L,1)^1.15)`; starter level3; cap100.
- A defeated opponent of levelL pays `floor(30 + 16L)` to the active eligible creature. Each other eligible living party creature receives `floor(award × 0.50)`; this is a share award, not a division of a fixed pool by five.
- Current source growth is HP6%, attack5%, defence5% of base per level above1. CREATURES owns IV, boost and bond formula order.
- Authored trainer/quest XP bonuses remain in their source rows. An opponent's defeat and encounter completion are separate event IDs: each individual defeat pays once, and its encounter bonus pays once. Reconnecting, accepting a queued reward twice or losing the last member cannot repeat completed payouts.
- A successful capture receives only the catch path's existing award, never a forged defeat event. Do not add another generic catch XP source. Fainted members miss combat XP but can receive the separate rest bonus.
- **Target revision:** retain the current flat rest bonus5, once per party member after a night preceded by a new eligible encounter or discovery. Persist the earned-day receipt. No repeated sleep-for-XP loop. C4's proposed5%-of-next-level/cap40 is deliberately dropped.

There is no XP loss on death, no party XP tax for co-op and no reward for killing a creature already removed by another accepted host transaction. Catch, dialogue reward and trainer victory use their existing distinct ledgers; changing them requires save migration.

## 3. Four chapter curve

| Chapter | Entry/exit target | Current evidence | New power and strategic change |
|---|---|---|---|
| Meadows | L3 → L21 lead; other retained members within3 levels | `data/config/chapter_curve.json`, five `data/config/bands/*/{spawns,trainers}.json`, Warden18/18/19/19/20 | L4 skill; caught team; camp; first TMs; saddle; Mudsnout evolution; Meadowstride |
| Cloudreach | L18–21 overlap → L33 | `data/config/cloudreach_chapter.json::trainer_ladder`, `data/config/cloudreach_encounters.json::trainers`, trainer19–34, wild18–33 | Wingroads and Fly; aerial route judgment; Skyborne |
| Stormwood | L33 → L44 | `data/config/stormwood_encounters.json`, `data/config/stormwood_world.json` | Stormglass routes/Arch, grounding, new move matchups; Livewire; later Ripplet return ability |
| Tidewake | L43 overlap → L55 | `data/config/water_characters.json::trainers`, `data/config/water_encounters.json::named_encounters` plus its scripted references, `data/config/water_world.json` | Human-swim/current routes; optional owned swim mounts; Tidal Guard, final team test, regional ending |

Meadows band entries/exits remain **3→9→12→15→17→21**, replacing the archived3→8→10→13→16→20 draft. Current wild ranges are2–6,6–8,9–12,11–15,14–17: these are source facts, not certification that late replacements meet the target. The band5 range can place a replacement more than two levels behind the intended entrant; this is an explicit tuning defect to inspect on the earned route, not a reason to silently update the table here.

Retain recovered curve constraints: wild high≤regional exit; wild low≤entry; wild high≥entry−2; no backwards regional band; at least six wild options per Meadows band; ordinary replacement catch deficit≤2 relative to intended regional entry. Optional trainers may be harder, visibly signposted and avoidable.

`min_level` belongs only on a named critical gatekeeper, never a crossing, route volume or ordinary trainer. Its value is derived from the next band's measured `team.enter − 1`, not copied as a fixed8/11/14/16 table. The check reads the party's **highest** creature. First refusal is in-character; repeated guidance may reveal the exact target and the nearby way to train/recover. Do not install the gate until the preceding region has adequate encounter density, visible level/progression feedback and reachable recovery. Crossings remain physical/story/item gates and never inspect level. Outside the opening readiness lesson, an invisible generic “must reach level X” wall is prohibited. Recovery: D75-the-level-gate-placement-rule and D79-the-level-gate-measures-the-partys-highest-creature.

Meadows Band5 is a named cadence exception: it is short on purpose and must not be padded to satisfy a generic density average. Only three basic supplies may sit on its road; the final waystop offers no heal; recovery precedes the attrition; and no ordinary recovery lies between the Sigil gate and Outer Works except a rare authored reward. D70-band-5-is-short-on-purpose and D78-band-5-findables-sit-off-the-road govern this exception.

The current Meadows test `tests/test_trainers_data.gd::test_the_critical_path_alone_pays_for_the_warden_ready_level` is useful arithmetic evidence. It does not prove that five creatures level together, rewards are reached without teleporting, potion use is affordable, or playtime is right. The historical progression comments report11,003 main-path XP against10,904 to raise a L3 starter to20; treat that as a dated calculation and regenerate from current IDs before tuning.

## 4. First-clear pacing illustration

The sequence below is an **adjustable illustration**, not a duration promise or a set of content quotas. Count only earned ordinary play when measuring it. Around eight good hours for the four current chapters is an acceptable first clear. Record any measured shorter duration honestly and review whether the decisions and chapter identities still land. Never raise XP costs, require optional catches, repeat errands or add backtracking to make a clock pass.

| Sequence | Intended experience and earned state |
|---|---|
| Opening | Grandpa, named starter, real practice fight/catch, five-space rule, village camp and tournament readiness. The candidate L4 skill may be absent for the first fun check. |
| Meadows | Cross South Bridge; use Quarry/Warrens and River Lock; ride into Upper Meadows; earn Sigils; prepare for and defeat the Warden; resolve the legendary offer and cross into Cloudreach. |
| Cloudreach | Learn vertical wayfinding and Fly, reconnect the wind roads, challenge Veyra and open Stormwood. Cloudreach has no legendary offer. |
| Stormwood | Read grounded/exposed terrain, repair the Stormglass route, prepare for the Long Storm, resolve Stormheart and reach Tidewake. |
| Tidewake | Learn safe human swimming/currents, optionally earn a compatible mount without forced replacement, approach Nerissa and the final guardian, restore the regional network, return to Grandpa with the retained team and roll credits. Aquaryn and Tidecoil remain optional. |

Use observed play to move, combine or remove beats. Preserve the chapter identities and four-biome ending, but cut repetition and compulsory detours before adding content. The opening check is one 15–30 minute owner expedition through existing systems. It decides whether further pacing work or any candidate mechanic is justified; it is not the start of a repeated cohort or harness programme.

Retain the opening's 35–55 minute and Meadows stronghold's 30–60 minute ranges as provisional pacing checks, not mandatory floors or content-filling instructions. Individual named-fight timing remains with COMBAT/BOSSES. If measured play runs long, remove repeated errands, reduce compulsory backtracking and adjust earned-route rewards before cutting authored land or chapter identity.

## 5. Reward schedule and optional content

**Target, partial foundations:** rewards should arrive where the earned route creates a useful choice, without a fixed minute interval. Prefer a TM, equipment, route, existing-team upgrade, evolution catalyst, recipe, faction/world change or traversal capability. Coins and duplicate berries alone are weak milestone rewards.

Each chapter retains 6–10 meaningful optional activities, at least one per principal region, as release content rather than a prerequisite for the initial owner check or a duration floor. WORLD specifies their identity. A reward is committed with objective completion once. One activity may pay a move plus an acknowledgement; it still counts once. A trainer rematch is not assumed: all31 Meadows trainer entries currently set rechallenge false. Wild spawn count is neither encounter-design variety nor authored runtime. Later catches remain optional; primary rewards should deepen the five the player already loves rather than pressure replacement.

Classify every activity before authoring: **team** (new role/move/evolution), **route** (shortcut/safe camp/traversal), **world** (local change/person rescued), **care** (better recoverability/recipe). Each chapter must contain all four classes. At most half may end in a generic item chest. Information about an already-known destination is not a reward unless it opens a real alternate approach.

Preserve primary-type TM restriction, consumable TM application and current item catalogue. No paid skill tree or new currency. Required traversal recipe resources must lie on the accessible side of the gate they unlock; optional TMs/boosts may never be needed to make entry-level combat survivable.

## 6. Economy proof and safety margin

**Built:** item/recipe catalogues, `data/config/trade.json`, harvest/pickup configs and trainer payout rows. **Partial:** a closed, replayable resource ledger for each full chapter and four-player depletion. SYSTEMS specifies starter30coins, Orb22, potion28, revive80 and proposed limited road stocks. The exact opening pack in UX is protected; it is not income to remove merely because a model says a perfect player needs less.

For each required route, compute a ledger from reachable source rows, not circular map radius:

`ending stock = starting stock + guaranteed reachable reward + affordable vendor purchase − required crafts − observed consumption`.

Run it for novice successful play, a two-loss recovery case and four characters sharing permanent nodes. The first camp costs18wood/8stone/18fiber; complete tournament preparation adds two beds for a total30wood/8stone/34fiber. The optional workbench adds10wood/4stone. Starting resources and gifts cannot be counted again on reload. Set available basic-material supply≥150% of solo mandatory craft cost along the intended path; for four players include four personal required kits plus shared structures only once. If supply fails, add authored sources or personal guaranteed quest bundles; do not silently turn all nodes into infinite respawn.

Four-player chapter rewards must provide equivalent personal essential progression. Shared physical chests/resources remain contested according to MULTIPLAYER; essential keys and a single legendary do not multiply. Selling every optional item must not be necessary to buy normal recovery. A player who spends every coin retains free bed recovery, free repair and reachable basic food, and can resume without a new save. Never solve insolvency by making enemy drops human-huntable or introducing leather.

Target emergency reserve before each major gauntlet: one viable entry-level creature, a reachable legal recovery bed, and capacity to obtain two basic heals through existing rewards/trade/craft routes. This is a solvency test, not an unconditional free refill at the boss door. No shop sells elixirs; permanent boosts cap24/stat. Buying and reselling cannot profit, and repeated rest cannot mint stock or XP indefinitely.

Out of scope: auction house, dynamic prices, offline production, daily reset economy and a separate co-op currency.

## 7. Gates and accounting

Readiness should make the opening teach the real game. `data/config/tournament.json` requires five owned creatures and level5 across the five strongest; those are sticky learned milestones. The current source registers an ordered three for each round, and only those three are checked for fed, rested and happy state at consent. The recovered care contract still requires one affordable physical creature bed per entrant. The initial one-bed camp is insufficient: tent+campfire+bedroll+three beds total **30 wood,8 stone,34 fibre**, and the bedroll must fit inside shelter large enough to read as usable. Show every unmet requirement before consent. A completed readiness lesson is a saved milestone, not a rule forcing every future released replacement back through the tutorial.

The tournament is an eight-slot board with exactly three player fights (Mira, Tam, Oskar) and four simulated named entrants. The Team Tether South Bridge grunt gates the crossing before Oskar's later final. Oskar's final uses a mounted Meadowhart; winning grants the saddle recipe before later Rootstone access. Target loss handling preserves the round, heals the registered three and permits retry; the final line restores the party, while Halda's post-win line explains the mounted payoff without owning the reward. Sources: `data/config/tournament.json`, `data/config/bands/band1_lower_meadows/trainers.json`, `data/dialogue/bands/band1_lower_meadows.json`, `scripts/world/tournament.gd`.

Later gates use earned story flags, machinery and physical passages, not an unseen party-average calculation. Wild respawn policy remains an owner decision; neither finite authored placement nor current spawn behavior silently settles whether ordinary wilds respawn in the target campaign.

Task counts derive from stable source IDs:31 Meadows battle entries are not31 unique people;16 overworld alpha sites plus Warrens are distinct; caught or beaten resolves an alpha. Resource surveys count permanent nodes; camp tasks require a rest at that location. No second reward for displaying an earned Sigil pin. Partial requests retain their historical accepted/completed/rewarded flags through migration.

**Target acceptance:** the player can explain the next goal before a gate; the ordinary earned route makes the retained five viable at each chapter exit without mandatory repeated low-level farming; later catches are optional and, when chosen, become useful from rewards earned on that route rather than a grind timer. Retaining the same five beloved companions through the campaign is a successful progression outcome. A comparison of completed saves verifies no duplicate XP/currency/legendary after failure, reload or client reconnect.

Changing the curve is allowed only after comparing earned route XP, bench XP and failures on the actual shorter route. Current level and economy numbers remain source facts, not hours to fill. Tune existing awards so the ordinary route can support its intended encounters; do not invent a new confirmed total, use XP to disguise weak fights or empty travel, or require bond/L4 skill/Strain/normalized poise to make the first fun check pass. This deliberately disagrees with the abandoned high-exponent curve and the inflated per-region activity quota: both manufacture more time without producing more game.

### Tournament selection resolution

The current source distinguishes ownership/training from the tournament field: own five and achieve level5 for all five once, then register an ordered three for each round. `autoload/party.gd` stores the three by durable creature UID, resolves them after party reorder, and clears the registration when a selected member is released; it never fills a missing slot with a replacement. `scripts/world/tournament.gd` checks care only for those three, while `scripts/ui/tournament_team_picker.gd` keeps all five visible and limits deployment to the registered order. `scripts/save/save_game.gd` and `scripts/save/character_save.gd` persist the selection through the v27/v6 migration; older saves keep readiness and wins but begin unregistered. Selection and the three-bed preparation consumers are implemented: the journal counts existing bed milestones, Halda checks them before first entry, and the gathering target includes all three beds. Already-entered saves retire the lesson. Full earned supply/care, rendered readiness and chapter acceptance remain unproved.
