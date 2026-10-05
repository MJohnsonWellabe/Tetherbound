# Homestead, materials and gear

**Status:** Product contract for the homestead redesign (owner, 2026-09-29, RD-02, RD-14..RD-16, RD-20, RD-21, RD-33). Every bare "RD-nn" below means (owner, 2026-09-29, RD-nn) in `CODEX_START_HERE.md` §1. Everything under a **Not built (target)** heading is design, not built behavior. **Built** means a source consumer exists on `main` today; **Partial** means a reachable foundation lacks the specified behavior. Numbers marked *starting value* are first guesses to tune in the named config (F47 owns the solvency pass); numbers without that mark come from the owner plan.

**Owns:** the homestead plot, the six stations and chests, the attachment rule, material tiers and refining, attuned ingredients and type crops, shed drops, creature gear, trainer gear, forward camps, the no-automation rule and homestead co-op ownership. **Routes elsewhere:** essence spending, caps, feasts' effect, traits and mastery → TRAINING; Tether Commands → COMBAT; Home Key, portals, waystones, Crossing Hall and Shrine Room placement → WORLD; ledgers and time budget → PROGRESSION; transaction plumbing → MULTIPLAYER; station screens → UX; everyday gathering, food, rest, death and traversal → SYSTEMS. Acceptance: ACCEPTANCE §6.2 F31 (stations), F32 (materials), F33 (gear), F34 (forward camps), plus F28#3 (feast cooking) and F47 (economy).

**Owner caution (RD-16): do not overcomplicate.** Six stations, four of which take exactly one attachment per biome, and each station shows one next upgrade. Any proposal that adds a station, a second upgrade track, a tech-tree screen, a queue or a production chain is out of scope unless the owner decides otherwise.

## 1. Why the homestead exists

The spine is creature power (RD-02). The homestead is the required engine that turns what the player gathers, wins and grows into creature power: tiered gear, Ascension Feasts, essence spent by choice, loadouts, traits and trainer protection. The loop (15–30 minutes): portal out to a waystone, fight, catch, release, gather, harvest shed drops, tap the Home Key, walk up the road, refine, cook, spend, plant, portal back (see GAME_BIBLE and CODEX_START_HERE §2). The main path is finishable without padding; grinding the loop makes the player clearly stronger (RD-01). The homestead must never demand a chore that does not feed that loop.

## 2. The plot

**Built:** Grandpa's house stands at `[-22,-16]` in the village (`data/config/village.json`), with six berry farm plots south of it (`data/config/farm.json`, `scripts/world/farm_plot.gd`, `scripts/world/farm_logic.gd`). The 12-piece build catalogue (`data/items/buildables.json`: tent, campfire, bedroll, floor, wall, door, roof, fence, workbench, storage, creature_bed, stormglass_arch) places through `scripts/build/build_placer.gd` into `Game.placed_buildings`, anywhere valid. The first-campsite requirement (`data/config/progression.json::home.required_pieces`) is unchanged.

**Not built (target):** the homestead plot is Grandpa's farm at the head of the single village road, beside the Meadows exit, with the Crossing Hall visible at the far end (RD-29; WORLD owns the road). The plot is a declared area in `data/config/stations.json` (`homestead_plot`: centre, radius or polygon; *starting value* a 40 m × 30 m pad around the existing farm yard, clear of the house footprint and the road). The six stations may be placed **only** inside it; a placement elsewhere is refused with the reason `station_home_only`. Existing camp and house pieces (tent, campfire, bedroll, beds, floor, walls, roof, door, fence, storage) keep their current anywhere-valid placement and stay useful at home (RD-15). Saves reset for this redesign (RD-35), so no old out-of-plot workbench needs migration.

## 3. Stations

**Not built (target) unless marked.** Each station is a buildable (F31#0) with its own interaction panel that joins `input_owner`. Crafting at any station follows the SYSTEMS §2 craft transaction: validate unlock, station, tier, costs and output room first; commit once or change nothing; one craft per tap; no passive queue.

| Station | Makes / does | Starting cost (`buildables.json`, *starting value*) | Takes attachments |
|---|---|---|---|
| **Workbench** (Partial: exists as an optional buildable; the craft panel opens at campfire or workbench) | Tools and tool repairs, building pieces, trainer gear, Tether Command pouch, forward-camp kit, saddles | 10 wood, 4 stone (current) | No |
| **Forge** | Refines raw ore into the tier ingot (§5.2); Harness; tool upgrades (current axe/pickaxe reinforcement and bracing recipes move here) | 12 stone, 6 rootstone, 4 wood | Yes |
| **Kitchen** | Meals and buff food; **Ascension Feasts** (Kitchen only, F28#3; TRAINING owns the feast's effect) | 8 wood, 8 stone, 2 fiber | Yes |
| **Altar** | Essence and Tether Candy spending, move loadouts, move mastery, Trait Seed teaching and distilling (all TRAINING); Charms (§6) | 10 stone, 4 rootstone, 2 ironwood | Yes |
| **Den** | Home rest for up to five creatures, happiness, grooming (shed drops, §5.4), gear display and equip | 12 wood, 10 fiber | Yes |
| **Farm plots** (Built: six berry plots) | Berries (current) and the eight type crops (§5.3); Greenhouse (§5.3) | 2 wood, 1 fiber per extra plot | No |
| **Chests** (Built: `storage`) | Items only, world-owned contents with revision (`scripts/build/storage_container.gd`). Never creatures: the five-creature cap has no storage exception. | 8 wood, 4 fiber (current) | No |

The Den is an addition to, not a replacement for, creature beds: a creature bed at camp keeps its current one-creature rest behavior (SYSTEMS §3). Resting in the Den follows the same rest contract as a bed and the same one-rest-credit rules. Loadouts may also be changed at a forward camp (§8); essence spending, mastery, traits and Charms need the home Altar.

## 4. Attachments: one per biome

**Not built (target).** Only the Forge, Kitchen, Altar and Den take upgrades, and each takes **exactly one attachment per biome** (RD-16). The schema holds 8 slots per station; 4 are live and 4 reserved for biomes 5–8 (RD-09). Each attachment is an adjacent buildable (world building record) snapped to its station, built from that biome's materials, and its recipe (the blueprint) is available from the start for Meadows, and for later biomes is unlocked by hanging the previous biome's relic in the Shrine Room (RD-20 "next tier", F31#2; ¶ below).

| Station | Meadows | Tidewake | Cloudreach | Stormwood | 5–8 |
|---|---|---|---|---|---|
| Forge | Bellows | Tide quench tank | Wind furnace | Storm coil | reserved |
| Kitchen | Spice rack | Smoker | Cold cellar | Storm oven | reserved |
| Altar | Meadow lens | Tide lens | Sky lens | Storm lens | reserved |
| Den | Straw bedding | Hot spring | Cliff perches | Grounded bedding | reserved |

**What an attachment gates (settled from the owner's answer to RD-20, which says a hung relic unlocks the *next tier*).** Each attachment gates its own biome's tier, and the Meadows attachments (Bellows, Spice rack, Meadow lens, Straw bedding) can be built from the start. Hanging biome *N*'s relic unlocks biome *N*+1's attachment recipes. The Meadows relic unlocks the Tide quench tank, Smoker, Tide lens and Hot spring; Tidewake's unlocks the Cloudreach column; Cloudreach's unlocks the Stormwood column; Stormwood's unlocks reserved tier 5. When biome 5 lands, that tier's rewards also cover the post-credits set: rematch-tier meals, +3 Stormglass upgrades and the endgame grooming table for the L55–60 repeatables (RD-31). As a result, each biome's gear is craftable from that biome's own materials before its boss, and nothing deadlocks. The comfort bonus per Den step is a *starting value* of +25 % rest-bonus duration and happiness gain (`stations.json`).

**Starting attachment cost** (*starting value*, `stations.json`): 8 of each of that biome's two primary raws plus 2 of its refined ingot. Attachments cannot be dismantled for profit: dismantle refunds the full cost (SYSTEMS §3) and removes the tier it provided.

**One next upgrade (RD-16, F31#3).** Every station panel shows a single "Next upgrade" line: the next attachment's name, what it unlocks in one phrase, and the one missing requirement with where to get it ("Hang the Tideglass relic in the Shrine Room", "Needs 2 Tidesteel ingots: refine at the Forge"). The Workbench and Farm show their next unlock when one exists (forward-camp kit, Greenhouse), else nothing. No tech-tree screen, no branching choice, no hidden prerequisite.

## 5. Materials

### 5.1 Material tiers (RD-33, existing ids reused)

**Partial.** Tier 1, 3 and 4 raws are registered items in `data/items/items.json`. The Tidewake raws are proposals in `data/config/water_crafting.json` (`item_registration_proposals`, status `authored_proposals_not_runtime_registered`); F32#5 registers them at runtime. `tide_pearl` and every ingot, Harness and Charm are new ids (target). The schema holds 8 tiers; 4 are live (F16#1).

| Tier | Biome | Raw (item ids) | Forge output | Harness | Charm base |
|---|---|---|---|---|---|
| 1 | Meadows | wood, stone, fiber, rootstone, ironwood, sunleaf | Rootiron ingot | Rootiron Harness | Sunleaf charm |
| 2 | Tidewake | driftwood, reed_fiber, reef_stone, sluice_metal, tide_bloom, + tide_pearl (new) | Tidesteel ingot | Tidesteel Harness | Pearl charm |
| 3 | Cloudreach | windworn_heartwood, cliffglass_ore, gale_fiber, skyplume, cloudberry | Skyglass ingot | Skyglass Harness | Plume charm |
| 4 | Stormwood | thunderwood, stormglass, conductor_vine, glowmoss, sparkfur, voltcap | Stormglass plate | Stormglass Harness | Spark charm |
| 5–8 | future | reserved | reserved | reserved | reserved |

The heartstone and sunstone evolution stones (built items) become Mudsnout feast ingredients (TRAINING, RD-28). Tier material nodes and essence nodes are **renewable**: each respawns on a configured timer (`data/config/harvest.json` and the per-biome harvest configs; *starting value* 2 in-game days for tier nodes, 3 for essence nodes). Authored story pickups, caches and unique items remain once-per-world (SYSTEMS §1). This reverses the former "never turn authored nodes into daily respawns" rule for tier and essence nodes only (owner, 2026-09-29, RD-01; F32#0, F32#2).

### 5.2 Forge refining

**Not built (target).** Refining turns raws into the tier ingot (F32#1). *Starting recipes* (`data/recipes/`, new forge file): Rootiron ingot = 2 rootstone + 1 ironwood; Tidesteel ingot = 2 sluice_metal + 1 reef_stone; Skyglass ingot = 2 cliffglass_ore + 1 windworn_heartwood; Stormglass plate = 2 stormglass + 1 thunderwood. Smelting is a **tap-start timed interaction**, not a held button and not a queue: the player taps, chooses an amount, and each ingot completes after a short channel (*starting value* 1.5 s) while the player stays within the station radius (*starting value* 3 m). Walking away, opening another modal or entering combat stops the remainder; each ingot is its own committed transaction, so stopping loses nothing already paid for the unstarted ingots. Nothing smelts while the player is elsewhere or offline.

### 5.3 Attuned ingredients, type crops and the Greenhouse

**Not built (target).** Eight attuned ingredients, `attuned_ground`, `attuned_water`, `attuned_air`, `attuned_fire`, `attuned_electric`, `attuned_ice`, `attuned_psychic`, `attuned_dark` (the eight types in `data/config/type_chart.json`), come from essence nodes and type crops. A feast needs one attuned ingredient matching the fed creature's type (RD-07; either type for dual types).

Type crops extend the built farm loop (`farm.json`: berries grow 1 in-game day, yield 4, one seed per planting). Each type has a seed (`seed_<type>`) and a crop that yields attuned ingredients plus a little type essence (RD-05). *Starting values* (`farm.json`): 2 in-game days to grow; yield 2 attuned + 3 essence of that type; seeds from essence nodes (chance), Mira's shop after the tournament and bounties. Planting and harvesting are by hand, one tap each; there is still no watering, fertiliser, blight or theft. Growth follows the host world's day, which advances only while that world is running; readiness derives from the planted day (built rule).

**Greenhouse:** plots grow the homestead's native types (`farm.json` `native_types`, *starting value* the two most common types in the Meadows spawn tables); the Greenhouse lets plots grow the other types (F32#3). It is a single Farm buildable, not a per-biome attachment track (see §12 Q2).

### 5.4 Shed drops (no butchering)

**Partial.** `skyplume` ("naturally shed … never a hunting reward") and `sparkfur` ("shed charged fur earned from Stormwood encounters") are built items. **Target:** each species may declare a shed table (`data/creatures/species.json` or `data/config/gear.json`; RD-14). Shed items drop (a) after winning a wild fight against that species (*starting value* 25 % chance per defeated wild with a table) and (b) from Den grooming, once per owned creature per in-game day, which also pays the capped care-essence trickle (RD-05; amount and cap in TRAINING). Grooming is care the player performs by tap; the creature does no job. Nothing drops meat, hide, bone or blood, and no item name or blurb may imply hunting or butchering (F32#4 naming test). Built armour ids `hide_helm`, `hide_vest`, `hide_leggings` and `hide_boots` carry hide wording that this test will catch (§12 Q4).

## 6. Creature gear

**Not built (target).** Every owned creature has two gear slots, **Harness** and **Charm** (RD-14, F33#0). Harnesses come from the Forge, Charms from the Altar, one tier per biome (Rootiron, Tidesteel, Skyglass, Stormglass; 8-tier schema). Each biome's boss is tuned for that biome's tier: the matching tier passes C2 in a boss simulation and the previous tier is clearly harder (F33#2).

- **Effect (starting split, `data/config/gear.json`; COMBAT owns the damage formula):** Harness raises maximum HP and defence; Charm raises move power and ultimate-meter gain. Numbers per tier and upgrade live in `gear.json`.
- **Upgrades +1 to +3:** at the station that made the piece, each costing that tier's ingot plus a shed item (*starting value* 2 ingots + 1 shed item per step; each step adds ~10 % of the tier's base bonus).
- **Visible accent (F33#1):** equipped gear shows on the creature body as a trim or glow in the tier's colour through a creature material accent hook (`scripts/creatures/creature_gear.gd`, new). Accents never use oxblood/red (reserved for Team Tether) and never shrink or rescale the creature.
- **Identity:** a gear piece is a stack-1 item instance. Equipped gear is part of the creature instance (portable, character scope) and survives evolution, save, rejoin and the owner's death; it never drops into a death satchel. Releasing a creature returns its gear to the satchel, refused with a reason if there is no room. Gear is not storage and gives no way around the five-creature cap.

## 7. Trainer gear and the Tether Command pouch

**Partial.** `scripts/player/player_equipment.gd` has five slots (helmet, upper_body, lower_body, boots, backpack) and flat environmental mitigation; fall damage is built in `scripts/player/player_vitals.gd`; Stormwood insulation is consumed through `storm_mitigation()`. Built pieces: the hide set plus travel_pack, and the Stormwood insulated set (helm and vest crafted by `data/recipes/recipes_stormwood.json`, leggings and boots found).

**Target (RD-14, F33#3):** trainer gear protects only against the trainer's real hazards. It never deals damage, never blocks, never adds a weapon or shield slot, and never raises creature stats. Each piece declares per-hazard mitigation fields in `items.json`; each biome's Workbench set covers that biome's hazard.

| Hazard | Biome | Consumer | Mitigation target |
|---|---|---|---|
| Falls | all | Built: fall-damage curve, `player_vitals.gd` | Raise the safe landing speed or reduce fall damage |
| Drowning and currents | Tidewake | Built: `water_swimming.json` drowning; current push per WORLD | Lower swim stamina drain, drowning rate and current push |
| Cold heights | Cloudreach | Not built: an authored local zone only, never a survival meter (hard rule) | Reduce that zone's stamina-regen penalty |
| Storm static | Stormwood | Built: `storm_mitigation()` insulation fields | Reduce strike damage |
| Hazard terrain | Stormwood, Tidewake | Owner 2026-10-05: Stormwood charged ground deals light, never-lethal contact damage to the trainer only; `water_hazard.json` submersion counts as drowning | Reduce contact damage (Rootiron, Stormglass) |

The Stormwood insulated recipes move from field crafting to the home Workbench (big stations only at home, RD-15).

### 7.1 Owner idea: one signature protective piece per biome (2026-10-05, not yet scheduled)

The owner proposed that every biome after the Meadows gives the trainer one recognisable thing to build that protects them from that biome's terrain. Each piece should read at a glance as the answer to that place:

| Biome | Signature piece | Protects against |
|---|---|---|
| Cloudreach | A cape | Fall damage |
| Tidewake | A snorkel | Drowning |
| Stormwood | Armour or rubber-soled boots | Electrocution (storm static and charged ground) |
| Volcano mountain (future biome) | Warm-weather gear | Heat |
| Ice mountain (future biome) | Cold-weather gear | Cold |

This is an idea, not a settled spec. It gives the existing F33#3 hazard mitigation above a concrete item identity per biome; it adds no new hazard, meter or mandatory gear, and §7's limits still apply (protection only, no weapon, shield or creature stat). The volcano and ice mountains belong to the reserved biomes 5–8 (RD-09) and are built in a later pass. Turning any row into built content needs an owner go-ahead and an ACCEPTANCE criterion.

**Tether Command pouch (RD-12, F33#4):** a Workbench-crafted pouch in tiers 1–4 that extends Tether Commands (*starting* per-tier gains: meter capacity, item-throw charges, Snare strength; COMBAT owns the commands and numbers). *Starting design:* the pouch is a backpack-slot item, so the five-slot rule holds (§12 Q3). All trainer gear is personal, persists with the character and follows the existing worn-gear death rule (SYSTEMS §6).

## 8. Forward camps

**Not built (target) (RD-15, F34).** The Workbench crafts a **forward-camp kit** (*starting cost* 8 wood, 6 fiber, 4 stone, 1 Rootiron ingot). Placed on valid ground in any live biome, it places three pieces as one record: a **bed** (human and team rest), a **portable cookpot** and a **field workbench**.

- **Travel tier only (F34#1):** basic meals, the current campfire recipes (orbs, potions, basic tools, seeds), realm travel recipes (camp boards, cordage, tonics, preserves) and tool repairs. Tier gear, refining, attachments, Charms and essence spending are refused with the reason "Needs the homestead" and the station named. Feasts stay Kitchen-only (§12 Q5).
- **Rest (F34#2):** resting recovers the team per the rest contract, saves, and allows loadout changes. It is a rest and respawn point, not a fast-travel destination; waystones and the Home Key are the travel system (WORLD).
- **Limit:** *starting value* one forward camp per character per biome (`stations.json`); placing a second in the same biome asks to pack up the first (full refund).
- **Existing camps keep working (F34#3):** tent, campfire, bedroll and creature beds, the tournament three-bed readiness lesson, authored realm camps and the rest bonus are unchanged.

## 9. No automation

Nothing produces while the player is away or not interacting (hard rule; F31#4). Crops need a planting tap and a harvest tap; growth advances only with the running world's day. The Forge smelts only during the player's present, tap-started channel. The Kitchen cooks one craft per tap. Grooming is one tap per creature per day. There are no creature jobs, conveyors, hoppers, auto-harvesters, offline timers, idle yields or production chains; no station feeds another station.

## 10. Co-op ownership (RD-21, F31#5, F33#4, F34#4)

| State | Scope | Authority and transaction | Save |
|---|---|---|---|
| Station and attachment buildings, farm plots, forward-camp records, chest contents | World | Host validates placement and cost, debits and spawns one building record atomically (MULTIPLAYER §8); record carries the placer's stable character id | Host world save; late join receives it |
| Attachment blueprints known (from hung relics), feast recipes, Greenhouse unlock | Character | Host-validated grant under a per-source, per-character delivery id; never granted twice | Portable character save |
| Crafted output, ingots, gear, attuned ingredients, seeds | Character (inventory) | Craft transaction: host validates, consumes the crafter's own ingredients and grants output once under a craft transaction id; reconnect replays or rolls back, never both | Portable |
| Equipped creature gear, trainer gear, pouch | Character | Equip/unequip is a local inventory transaction mirrored to the host | Portable |
| Node stock, crop readiness and harvest claims | World | Host serializes claims; one claimant wins; four-player contention is solvent (F32#5, F47#2) | Host world |
| Grooming per creature per day | Character | Host-checked day stamp per creature uid | Portable |

**Reading used here:** a station's tier is the attachments physically built in that world. A guest uses the host's stations at the host's tier and keeps what they craft (RD-21). Recipes that need a personal entitlement (feast recipes, attachment blueprints) require the guest's own entitlement even at the host's station. A guest can build an attachment in the host's world only with their own blueprint; the building then belongs to the host world. Items a guest puts in a host chest stay in that world (built MULTIPLAYER behavior); the chest panel says so before the first deposit.

## 11. Source map

Built: `data/items/buildables.json`, `data/recipes/{recipes,recipes_rootstone,recipes_ironwood,recipes_cloudreach,recipes_stormwood}.json`, `data/config/water_crafting.json` (unregistered proposals), `data/config/farm.json`, `scripts/build/{build_placer,build_piece,build_door,build_grid,build_snap_contract,camp_tent,campfire,creature_bed,player_bed,storage_container,home_progress}.gd`, `scripts/ui/craft_panel.gd`, `scripts/world/{farm_plot,farm_logic,harvest_node,realm_heart_shrine}.gd`, `scripts/player/{player_equipment,player_vitals}.gd`, `data/config/realm_hearts.json`. Target (F31–F34): `data/config/stations.json`, `data/config/gear.json`, `scripts/build/station_*.gd`, `scripts/build/forward_camp.gd`, `scripts/creatures/creature_gear.gd`, a Forge recipe file and schemas under `data/schema/` (F16).

## 12. Open questions for the owner

Keep conservative behavior until answered; none blocks other work.

1. **Attachment gating order: settled.** Meadows attachments are available from the start. Hanging biome *N*'s relic unlocks biome *N*+1's attachments (§4; RD-20's "next tier"). This replaces the literal reading that deadlocked.
2. **Greenhouse: settled.** It is a Farm buildable, not an attachment (F32#3 now says so; RD-16 limits attachments to the Forge, Kitchen, Altar and Den).
3. **Pouch slot.** RD-12/F33#4 do not say where the pouch is worn. Treated here as the backpack slot so the five-slot rule in `player_equipment.gd` holds; a sixth slot would need owner approval.
4. **Hide armour wording.** The built `hide_*` pieces conflict with the no-butchery naming test (F32#4). Recommended: rename display names and blurbs (for example "Padded"), keep the ids.
5. **Feasts at forward camps: settled.** Feasts are Kitchen-only; F34#1 now reads "basic meals and field kits" and refuses feasts at forward camps.
6. **Repairs.** Tool repair is a free Satchel press today (SYSTEMS §1). F34#1 lists repairs as a forward-camp recipe. Keep the free press unless F47 finds it breaks the economy.
