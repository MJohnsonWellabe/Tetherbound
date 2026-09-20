# Expedition systems

## Purpose and status vocabulary

Every system supports leaving with a chosen five, finding something useful, overcoming a challenge and choosing when to recover. No system earns its place merely by resembling a survival game. **Built** means a source consumer exists at `b8eda885`; **partially built** means a reachable foundation lacks some specified behavior/proof; **not built** means a target to implement. This plan changes no game code. Numerical targets below become config, not scattered constants.

| System | Baseline status and proof | Remaining target |
|---|---|---|
| Gather/harvest | Built: `scripts/world/{harvest_node,harvest_logic,vegetation_harvest_point,felled_resource}.gd`; `data/config/bands/*/harvest.json` | Reliable prompt/impact/stock transaction and four-player solvency. |
| Craft/repair | Built: `scripts/build/`, `data/recipes/*.json`, `scripts/ui/craft_panel.gd`; catalogue consumed by item/recipe readers | Station/gate/cost presentation and complete chapter recipe access. |
| Building/storage | Built: `scripts/build/{build_placer,storage_container,creature_bed}.gd`, `data/items/buildables.json`; `Game.placed_buildings` | Proven sites, persistence/concurrency and bounded room/camp quality. |
| Care/rest | Built: `scripts/creatures/creature_condition.gd`, `scripts/world/night_rest.gd`, `scripts/world/rest_point.gd`, creature-bed recovery in `autoload/game_state.gd` | Efficient care UI and meaningful road cadence; Strain remains a candidate below. |
| Satiety/food | Built: `scripts/player/player_vitals.gd`, `data/config/vitals.json`, `data/items/items.json`, `data/config/creature_condition.json` | Preserve light pressure; show effects consistently. |
| Farming | Built: `farm_plot.gd`, `farm_logic.gd`, `farm.json`, `test_farming.gd` | Reliable small household loop, no expansion. |
| Death/satchels | Built: `player_death.gd`, `water_player_death.gd`, `death_satchel*.gd`; network ownership tests | All-realm safe retrieval and finalized-death cleanup. |
| Trade/economy | Built: `trade_db.gd`, `creature_trade.gd`, `trade.json` | Per-visit supply and finite-world four-player budget. |
| Ride/Fly/Swim/arches | Partially built: riding controller, `fly_controller.gd`, `swim_controller.gd`, Water mount and Stormwood arch runtimes | Starter promises, cross-realm gate safety, comfortable beginner routes. |
| Day/weather | Built: `world_look.gd`, `day_cycle.gd`, `world_weather.gd`, `Game.clock`, save v24 | Measured chapter identity and retained clock/reload proof. |
| Relics | Built: `realm_heart_shrine.gd`, realm-heart state and configs | Correct reusable/one-active presentation; prove each power. |
| Fishing | No minimum-release loop accepted; older GAME_DESIGN proposed it | Deliberately cut. Do not author fish recipes or fishing gates. |

## 1. Gathering and harvesting

Harvest lifecycle: `standing tree/stone → target offered → swing committed → impact validated → felled persistent pickup at the exact position and amount → gathered and gone`. A missed/occluded impact costs no node stock; tool wear is charged once on valid impact. Wrong/broken tool gives the exact tool requirement without committing a swing. Full inventory refuses before removing node stock or wearing the tool. A network request identifies node/stock revision and tool instance; host serializes it. Pickup identity is the stable placement id, never the item id. Do not resolve stock from a UI slot index.

Human tools are axe for wood, pickaxe for stone/ores, knife for fibre/reeds, hands for berries/pickups and hoe for soil. Tools do not damage creatures or humans. Axe/pickaxe/knife base durability40 (`data/items/items.json`). One valid harvest=one wear. A tool at0 remains carried/broken; it is not deleted. Existing tool-specific impact timings remain animation/config driven; **target** first successful resource impact≤0.8s after press, no hold, one clear material label. **Current repair** is one free press anywhere in the Satchel (`scripts/ui/tab_backpack.gd::_read_use`, around line1424); retain that behavior for minimum release. Do not describe a workbench gate as current or add one without a deliberate economy/route decision. Durability upgrades preserve instance metadata through storage, dropping and death.

Every authored harvest and world pickup is once-per-world with stable ID/order; repeated loads cannot respawn spent wood, stone, Rootstone, Heartstone, Stormglass or a claimed placed item. Player farm plots are the renewable exception. This finite stock has deliberate co-op and late-join consequences; do not silently turn authored nodes into daily respawns. Essential basic resources must exist before their tool/station gate. Each region has a proof route to its next recipe with≥150% solo mandatory stock and a four-player stock budget (PROGRESSION). Selling or optional building must not be required to discover a hidden softlock.

Pickups are diegetic consumables/materials, not universal glowing boxes. Normal prompt≤3.6m; no collection through wall/floor. Interaction succeeds or gives a specific refusal in≤0.25s locally; connected requests show pending after0.25s and never duplicate on repeated press. A landmark/candy display cannot be used as a walkable collider blocking its route.

Out of scope: hunting, butchering, meat/leather drops, tool combat, creature labour, unattended extraction, a universal auto-loot radius. `saddle_frame`'s existing leather-flavoured blurb is stale wording, not authorization for a leather economy.

## 2. Crafting, inventory and equipment

Craft transaction validates recipe unlock, nearby required station, all costs and output capacity **before** consuming anything. Commit once or change nothing. One craft per tap, batch selection in menus explicitly chooses amount; no passive queue. Missing conditions list ingredient counts and named station/unlock. Learning is a durable player/world entitlement as MULTIPLAYER specifies; ingredients remain the spending character's.

Progression flags are a flat set of string ids without payload. A dialogue gift and its flag commit atomically on the same line; replay cannot pay the gift without its flag or set the flag without its gift. A recipe with `unlocked_by` remains hidden from the craft list and is refused by the transaction until that flag exists. A TM is a stack-1 inventory item taught to one compatible creature and consumed only after the move replacement commits. Its world-placement flag records that placed pickup, not ownership of a permanent teaching unlock; saves from before the item conversion receive no free disc. Sources: `autoload/progression_state.gd`, `scripts/story/{sequence_director,story_ledger}.gd`, `autoload/game_state.gd::recipe_known`, `data/recipes/recipes.json`, `data/items/items.json`, `scripts/creatures/teaching.gd`, `scripts/ui/tab_backpack.gd`, `scripts/world/tm_pickup.gd`.

Baseline recipe tiers: ordinary supplies, Rootstone/Greater Orb/saddle, Ironwood/preparation, Cloudreach utility, Stormwood arch materials and Water swim preparation. Keep current costs as catalogue truth until PROGRESSION's solvency pass changes a whole route budget. Do not invent a workstation for a recipe already consumed by existing craft UI. Water's separate recipe metadata must have a runtime consumer; metadata alone is not enforcement.

Inventory is24 slots; stacks use each item definition (berries30, basic resource stacks generally50, potions/revives10, gear/tools1). **No carry weight.** `autoload/inventory.gd` retains six hotbar storage cells for compatibility; controller release exposes five usable bindings (B plus D-pad). A sixth legacy assignment remains a save field, never an inaccessible required action. UX defines a migration/display rule; do not silently lose the item because a binding disappears. Splitting/moving/dropping preserve durability/instance metadata. Failed transfer leaves both containers unchanged. Source `storage_state.gd`, `death_satchel_rules.gd` validate before mutation.

Authored `reward_grant` items and personal flags use a durable per-world-instance/per-source/per-character delivery id. The world instance is a persisted random namespace, independent of reusable save names such as `slot-0`. The host saves the finite delivery journal before publishing it; the character saves an inaccessible portable escrow row before acknowledging it. A full satchel keeps the earned row pending and settles the complete item grant and optional flag together when room exists. It is not storage and exposes no deposit or withdrawal verb. Legacy peer-id receipts cannot prove which stable character was unpaid; only that source is marked `legacy_unresolved` for manual recovery, while fresh sources continue normally.

Equipment: helmet, upper, lower, boots and backpack are human equipment, with explicit carried/worn states (`player_equipment.gd`, `test_equipment_portable_save.gd`). Human armour mitigates environmental HP damage only; it never raises creature defence. Do not add a combat weapon slot. Equipped and inventory versions cannot coexist as duplicated assets. Controller equip/use commands return focus to the source slot and show the new total, even after reordering.

Out of scope: weight, inventory Tetris, backpack storage of creatures, crafting queues, factory stations, loot rarity colours as a new gear progression, split-stack duping on reconnect.

## 3. Building and camps

Keep the12-piece baseline. Costs below are source values, not invented future costs:

| Piece | Wood | Stone | Fibre | Role |
|---|---:|---:|---:|---|
| Tent |6|0|4| Shelter/identity. |
| Campfire |2|8|0| Light and preparation point. |
| Bedroll |4|0|6| Human rest. |
| Creature bed |6|0|8| One physically assigned creature. |
| Workbench |10|4|0| Optional crafting station; baseline repair remains free in the Satchel. |
| Storage |8|0|4| Items only, persisted contents. |
| Floor |0|4|0| Small home footprint. |
| Wall |6|2|0| Enclosure. |
| Door |5|0|0| Openable passage. |
| Roof |4|3|0| Enclosure. |
| Fence |3|0|0| Decoration/boundary. |
| Stormglass Arch |—|—|—|6 Stormglass+2 Thunderwood Frame+4 Conductor Vine; learned chapter mechanic. |

First required campsite (`data/config/progression.json::home.required_pieces`) is tent+campfire+bedroll+one creature bed:18 wood,8 stone,18 fibre. This is the initial camp, not the full tournament readiness provision. The target tournament registers three of the same owned five, as specified in UX/PROGRESSION; those three entrants require three creature beds; tent+campfire+bedroll+three beds cost **30 wood,8 stone,34 fibre** and shelter/bed placement must physically fit. Workbench/home architecture is optional. Beds do not increase party capacity. A creature assigned to a bed remains one of the five, physically represented, unavailable to summon/ride/fight until recalled; waking preserves accrued healing but forfeits completed-night rested credit.

The torch remains a carried hotbar tool, never a placeable. Baseline camp darkness is no longer an open defect: a real placed campfire creates its own visible light through `scripts/build/campfire.gd`/`scripts/world/campfire_glow.gd`, while tent, bedroll, creature bed and storage attach the smaller night-only `scripts/world/camp_fill_light.gd` floor. Preserve that hierarchy instead of restoring the retired placeable torch or describing current camps as unlit.

Placement lifecycle: catalogue→preview→valid/invalid ghost→confirm→host payment/placement receipt. No payment for invalid/denied placement. **Target limits:** within6m player, grounded on supported pad, slope≤20° for camp furniture and≤10° for floor, no wall penetration, no intersecting interactable clearance. Keep at least2m walking path through camp and measured clearance for assigned creature mesh. Exclude authored gates, spawn/admission pads, landing anchors and story controls by actual footprint+2m margin. A valid ghost never commits to a different snapped transform. Grid/rotation displayed before confirm. Dismantle requires two taps separated by explicit confirmation, full material refund to owner when capacity fits; otherwise deny. No held chord. Occupied bed, nonempty storage or linked story arch cannot be dismantled until emptied/unlinked safely.

Persist piece ID, transform, stable owner/instance ID and per-piece state including storage contents/bed occupant. Existing `_sync_placed_building_state()` already saves container state: live TECHNICAL's former contrary statement was wrong. Shared chest interaction serializes transfer; no peer can overwrite newer contents with a stale panel.

Six existing Meadows roadside rests, later chapter camp catalogues and player camps use the same rest contract. **Target:** mandatory travel legs offer a safe rest/preparation choice every12–20 active minutes and before each gauntlet; never require a return-to-home hike solely to recover a fainted team. Authored camp access must be earned where its chapter requires it. Emergency return is a real defeat/recovery transition, not free waypoint travel.

Out of scope: structural integrity simulation, building destruction/raids, defensive turrets, creature jobs, landlord permissions hierarchy, a second structure family, mandatory elaborate house.

## 4. Food, healing and Strain

Preserve satiety: player100 maximum,0.8/min drain; below35% stamina regeneration×0.6, below15%×0.35 and movement×0.92. Creature nourishment100, start70,1.1/min drain, no drain while bedded, fed≥55%, hungry<30%. No starvation health damage, death or involuntary release. Food restores and grants configured buffs. Berries give player18 satiety/1.15 stamina regeneration120s or creature35 nourishment/8 happiness. Cloudberry20/35/9. Consuming at full condition refuses if no buff/recovery would change, preserving the item.

HP and satiety are different. Small Potion50 creatureHP, Ridge/Glowmoss80, cannot revive. Revive only fainted, brings creature to50% effective maximum. Human heals through meals that actually carry healing and rest, never creature potions. Inventory description and outcome must agree (Ridge Tonic's existing 'more than twice'50HP prose is false at80). Food and potions use separate valid targets. Buffs of same ID refresh duration, not multiply strength; per-stat strongest temporary buff wins; at most3 visible buff icons with remaining time. No timer pauses by repeatedly opening co-op menus.

### Strain candidate target — not built, not a first-fun prerequisite

Archived C4's owner requirement was meaningful camping; its particular stacked penalty was a proposal. Current `scripts/creatures/creature_instance.gd`, `scripts/creatures/creature_condition.gd` and `data/config/creature_condition.json` contain no Strain. First test the existing recovery loop in the single 15–30 minute owner expedition. Only if that check identifies a concrete recovery problem should implementation proceed with **one** visible Strain fraction `s`, initially0, cap0.25:

`s_after_encounter = min(0.25, s_before + 0.10 × damage_taken/uninjured_max_HP + (fainted_in_encounter ? 0.10 : 0))`.

Count actual damage, not overkill; count faint once. No extra on revive, nighttime, low happiness or being unrested. Effective healing ceiling=`uninjured_max_HP × (1−s)`. When applying new Strain, clamp livingHP to ceiling; it cannot itself faint a creature. Potions/food/candy/level-up do not erase the fraction. Level-up changes maximum and preserves current HP fraction under the new ceiling, not a free full heal. A fainted creature stays fainted until an explicit revive/rest.

Only occupied physical bed recovery or home bed clears Strain. Over120s ordinary world time, recover HP linearly to true maximum and Strain to0 from the assignment-start values. An actual completed night immediately finishes those beds. **Unbedded party members keep HP and Strain**; sleeping is not a free five-creature hospital. Show a hatched end cap on HP with 'Rest to recover', and numerical detail in the team panel. One contextual hint at first10% Strain; no new hunger/fatigue bar.

This is intentionally milder than C4's20% damage conversion+25% faint+10% revive/cap40% with night/unrested multipliers. Skilled play should need fewer rests; a struggling player must not enter a spiral of weaker creatures and expensive revives. Reject C4's forced120% damage-per-leg acceptance, its contradictory unbedded-healing claim and restXP farming increase. Do not tune hunger upward if players skip camps.

Target care flow can assign, feed and inspect five in≤90s of menu handling. Outside the explicit three-entrant tournament readiness lesson, one-bed sequencing remains legal, with each assignment/rest shown rather than a hidden five-bed capacity. Tutorial explains that more beds allow simultaneous recovery; it requires the three affordable tournament beds but never an expensive house. A prepared player chooses a camp because of Strain/next challenge, not because an invisible timer orders it.

Out of scope: fatigue/cold/thirst/exposure meters, contagious disease, random injury rolls, permanent scars/stat loss, rest penalties for a player who navigates or fights well.

## 5. Rest, happiness and farming

Built happiness100/start55; ordinary drift−0.15/min, hungry−0.6/min, feed+8, completed rest+12, victory+5, faint−12, level+6; happy≥60%. Rested lasts45 awake minutes and clears on faint (`creature_condition.json`). Happiness gates opening readiness; it is not permanent bond and never causes disobedience. Do not expand it into another road debuff. COMBAT's nourishment/bond wind bonuses remain separate.

The progression UI consumes one **64-event**, sequence-numbered, polled feed from `scripts/creatures/progression_feed.gd` and `data/config/progression_feedback.json`. XP, bond, item and world producers own their awards and publish results; the feed never grants progression. A late-mounted presenter seeds its cursor and cannot replay old awards as new after reload or reconnect.

Solo rest: tap bed→fade→next morning→heal human→finish occupied beds→save. Existing1.2s fade plus0.4s blackout is retained baseline. Multiplayer: all connected non-downed players must choose rest, wherever their valid beds are; host advances clock once. Show who remains awake, allow cancel anytime, no forced vote timeout punishment. Disconnect recalculates vote; joining peer does not duplicate night rewards. Ordinary world time does not stop for a single co-op menu.

Retain existing5 rest XP only for a qualifying new rest, not rapid repeat sleeping: **target** one victory or new discovery since previous rewarded rest. Bond rest credit uses CREATURES' per-creature rule. New game/day save load cannot manufacture a second credit. Current rest-credit deduplication is partial and requires tests.

Farming remains six starter plots plus legal small planted plots: hoe valid soil→spend one seed→growing1 in-game day→harvest4 berries→empty. No watering, fertilizer, season failure, crop theft by creatures or automation. Growth follows host world day; unloaded plots derive readiness from planted day, not running timers. Shared harvest claim atomic. Farming is optional basic food insurance, not essential for a campaign that already provides food.

Out of scope: crop economy, livestock, fishing minigame, cooking skill tree, farming quests that block chapter progress.

## 6. Death and recovery

Distinguish **creature defeat** from human death. Losing an encounter faints the involved five; no creature disappears and no human becomes an enemy target. End combat cleanly and offer recovery at last earned camp/home with the chapter's existing loss outcome. Trainer victory flags/rewards do not advance on loss. Repeat the uncompleted fight; already defeated trainers remain non-rechallengeable.

Human environmental death drops carried inventory in a persistent owned satchel; no XP, level, bond or creature loss. Multiple deaths leave multiple bags with unique IDs and map markers; no replacement of the oldest. Equipped-item treatment follows the portable equipment schema and must be displayed before release; **target** worn gear remains equipped, bag contents drop. Retain durability in either case. For water/cliff invalid locations, put satchel at the last verified safe approach/shore in the same realm, record actual death point separately for diagnostics; never strand it under terrain or across an unopened gate.

Solo recovery at last earned safe camp, else Grandpa/home arrival; restore humanHP/stamina100%, preserve creature condition except explicit existing recovery service. Co-op opens45s downed window; revive target35%HP/stamina,3s at≤2.5m. **Input correction implemented on the first-expedition branch:** `downed_state.gd` starts progress with a tap; damage, motion beyond the configured0.3m horizontal deadzone, leaving radius, invalid state or another tap ends it. No held button; `smoke_net_revive.gd` verifies the two-peer input/recovery path. **Still target authority:** host finalizes death once when the window expires, withdraws that participant from combat before moving their body, creates satchel once and keeps others' encounter alive. A disconnected downed player resolves through the same durable journal. The input correction retains the inherited direct-peer revive-completion RPC; it does not prove host authorization or the complete durable-death contract.

Retrieving partial satchel contents leaves the rest and marker. Another player sees owner's name and cannot loot it. Story keys in bags remain recoverable; a persisted world unlock never re-locks because its spent key is absent. No selling/discarding irreplaceable unopened-gate keys. Validation requires death twice, save/reload and both bags intact in every realm.

Out of scope: permadeath, XP debt, creature theft/loss, corpse decay, PvP loot, deleting satchels for performance convenience.

## 7. Trade and bounded economy

One currency, coins; base30 starting (`data/config/trade.json`). Coins are ordinary, loseable satchel inventory rather than a protected wallet. Existing prices retained as starting point: orb22, small potion28, revive80, berry6; sales generally around one-third purchase. Permanent elixirs are never sold: Health+12 HP, Power+6 attack, Guard+6 defence, flat after the level/IV curve and capped at+24 per creature per stat (`data/items/items.json`, `data/config/progression.json`). Never buy→sell at profit. Vendors transact exact count atomically and deny overflow.

**Current NPC swap:** `scripts/trade/creature_trade.gd::swap()` performs a coin-free one-for-one replacement, records one use per shop rotation and refuses trading the last owned creature. It previews outgoing history/incoming stats and never offers storage or breeding. **Target gap, not current:** refuse outgoing starters and the unique legendary recipient before mutation. In co-op the host transaction/receipt remains target integration. Peer-to-peer creature trading and a market remain out of scope.

**Target supply policy:** opening stocks remain current. After tournament, roadside supply stock per character per earned day:2 small potions,1 revive,3 food. World-time pass alone does not earn restock: require one completed encounter/discovery since prior restock. No limitless coin farm from one-time trainers. Four players receive individual purchase stock; placed shared pickups remain single claim. A player with zero coins can repair freely, reach a free bed and gather basic food; recovery is never a paid-only service.

New currency faucets and totals live in PROGRESSION, not NPC prose. Named first-time victories pay rewards once even if dialogue/reload repeats. Optional spending and extra homes can exhaust discretionary stock; mandatory path is independently solvent. Creature/skill candy is placed exploration loot, not craftable, purchasable or a repeated task payout.

Out of scope: player auction house, fluctuating commodity prices, creature sale exploitation, multiple currencies, paid recovery gate, monetized progression.

## 8. Riding, swimming, flying and teleport

### Ground riding — built, integration partial

Compatible owned creature+saddle in inventory; saddle appears on deployed creature, never baked into wild body. Mount tap through shared interact arbiter; dismount at supported nearby clearance, otherwise show refusal. No mounting fainted/resting creature. Rider visible, jump apex no higher than trainer1.35m; no climbing beyond ordinary45° except authored legendary60°. Same physical keys/barriers whether mounted or walking. Ground riding costs no stamina; food drain continues. Existing species speed multipliers are retained (Terrapup1.7, Burrowback1.5, Tuskroot1.8, Meadowhart2.0, Veridian2.8); use source definitions if a later approved tune changes them. Combat admission dismounts safely first. No mounted catch/combat.

### Human/mounted swimming — built, completion proof open

**Owner-retained-team target:** the critical Water route cannot require catching/replacing a creature or owning a swim mount. Use baseline human swimming and safe shores for required travel; mounts retain faster travel and marked optional-route value. This is a route/gate integration target, not proof the current quest and every crossing already satisfy it. No boat, sixth creature or loaner-ownership exception is introduced.

Human can swim from Water arrival. Source `data/config/water_swimming.json`:3.8m/s,2.8 stamina/s, entry depth1.2m/exit0.9m, exhausted drowning4HP/s. No instant deep-water death. Swimming skill reduces drain; human ordinary stamina100. Combat freezes swim stamina, drowning **and regeneration**, preventing combat-to-refill exploits. Exit only onto supported shore slope≤35°,≥0.6m above water,1.5m clear radius; host checks anchor. Recovered mandatory-gap measurements are **80.0/104.13/90.74/109.02m** and must leave at least15% of the100-stamina baseline under the exact3.8m/s,2.8/s arithmetic; remeasure from the final baked shore anchors rather than trusting config endpoints.

Swim saddle from Iona after Aquaryn/Swim Stone:8 Reed Fibre+6 Driftwood+4 Reef Stone. The Swim Stone is a durable personal unlock flag, never a consumable inventory item and never spent per saddle or mount. Five supported Water swimmers and their species stamina/speed/drain are enumerated in CREATURES. Mount stamina is creature identity state; dismount/switch/potion/combat/reload cannot refill it. Safe land recovery12/s. At zero mount stamina, drowning3HP/s; dismount remains possible but isn't a free full human bar. **Target route bar:** weakest eligible swimmer at skill0 reaches every mandatory hop with≥20% reserve, including reasonable steering deviation15%; optional shortcuts may require training and must be marked. Retune route/current before demanding grinding swimming skill. No forced legendary adoption to progress.

### Flight — built, starter integration partial

Earned Cloudreach mentor trial/unlock required. `data/config/fly_traversal.json`:16m/s, launch8 stamina/minimum18, cruise1/s, climb1.6/s, max180s, normal sink2m/s, descent8m/s, exhausted sink9m/s, updraft cap18m/s. Preserve cruise and authored updraft behavior. **Target no-hold climb:** one valid A press starts a0.5s upward pulse at8m/s and pays climb stamina at1.6/s while active; another fresh tap refreshes remaining pulse to0.5s maximum and never stacks duration or speed. Holding A does not repeat. Refuse climb before the unlock or outside a valid flight state. Collision/anchor safety beats visual desire. Source currently supports Galecrest/loaner; **target** honor Galewisp's starter promise with the same lawful flight capability after unlock, no sixth owned slot. Mentor loaner is explicit trial/transport assistance, not another combat party member or permanent free traversal inventory. No flight in combat/interiors or past unopened chapter gates; earned returning-region shortcuts may bypass previously opened local obstacles. Land/recover to a current-realm host-accepted safe anchor, never stale previous-world coordinates.

### Stormglass arches and Ripplet promise — partially built

Stormwood arches are built infrastructure, not global menu fast travel. Both endpoints must be paid, linked and legally placed; paired state is world authority. A world may carry at most three constructed pairs including the Crown pair. Still Grove requires **six Crown-grade Stormglass** for its footing and binds to Crown, preserving the chapter route; ordinary Stormglass cannot substitute. Free-build waives inventory cost only, never placement, pairing or story gates. Both endpoint UIDs commit atomically so save/reconnect cannot retain a half-pair. Rootgate/story gates remain authoritative. **New target design, not built:** only after Stormwood completion **and Water entry**, an owned deployed Ripplet may make a return trip to a previously used safe Stormglass arch and personally attune that visited anchor. It may then recall its trainer to one attuned safe arch in the **current realm**, out of combat,5s visible channel,120s cooldown, interrupted by movement/damage; costs no consumable and never reveals, remotely attunes or bypasses a locked endpoint. Ripplet therefore does not grant teleport during the Stormwood first clear. Implementation needs explicit per-character attunement/destination/cooldown persistence. Keyboard/debug Settings travel is not progression evidence.

Out of scope: boats, diving, underwater caves/combat, free-flight combat, world-map fast travel, mount breeding, gate bypass via a loaned creature.

## 9. Day, weather, relics and aftermath

Day baseline600s; night18:00–05:00. Time persists through save and synchronizes from host; no arbitrary clock reset on realm entry. Meadows clear/cloudy/fog/rain is the built weather set (240–480s episodes; maximum2 consecutive non-clear). No blanket night-level increase in minimum release. Night changes ecology, sound and visibility; peaceful remains peaceful and village is safe. Clouds/fog cannot hide a mandatory tell/prompt at its reading distance. Stormwood Long Storm/rods and Water currents are authored chapter mechanisms, not a global survival exposure model.

Relics: `unearned → earned/unplaced → placed → personally active/inactive`. Placing is durable world state; activating is per-player, one active at a time, reusable. No one-shot consumption of a placed relic. Powers in `data/config/realm_hearts.json`: Meadowstride doubles maximum human stamina; Skyborne removes flight stamina drain; Livewire multiplies creature move cooldown by0.75; Tidal Guard multiplies incoming creature damage by0.90. Test actual consumer effects, not just activation icons. No stacking four relics.

**Built Meadows response:** local relay shutdown regrows only its owned vegetation group and fades that relay's runtime drain skin over12s (`scripts/world/meadow_healing.gd::heal_stations`, `data/config/meadow_healing.json`). The quarry's baked colour/control scar is separate world art and does not heal through this runtime call. Chapter freeing changes the remaining machinery, weather/current/route affordances and NPC acknowledgement. Persist each change so leaving/rejoining cannot restore the old oppression. The final homecoming uses earned party identities and a changed world, not newly granted substitute creatures.

Out of scope: simulated ecological migration, seasons, dynamic economies after liberation, global weather hazards outside authored chapter contracts, fifth chapter.

## 10. Recovery disposition and release tests

Carries FINDINGS S06–08,S14–26,S30–35 and recovered owner care/build/tool instructions. Deliberately cuts fishing, resource/camp completion checklists before primary side stories, stacked C4 penalties, restXP5% farming and universal fast travel. Keeps one-time harvest, no hunting, slot inventory, multiple bags, physical beds, generic saddle, reusable relics and shared-world authority. UI strings must remove stale leather/potion/ordered-bond claims alongside implementation; this PR only specifies that work.

Before expanding these systems, use one 15–30 minute owner expedition to check the existing gathering/crafting/placing/resting/eating/recovery loop. Keep mechanics testing to that decision and do not start a repeated cohort or new harness programme. For implementation targets that are selected, retain the relevant regression, network and save tests: complete full-inventory refusal with no lost stock, two-player simultaneous shared-container claims, safe mount failures, four-player material solvency, two deaths/reload and real chapter traversal at baseline skills. Counts and source assertions alone do not close these systems.
