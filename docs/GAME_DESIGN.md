# TETHERBOUND — MASTER GAME DESIGN

**Status:** Implementation-ready pre-production specification  
**Engine:** **Godot** — LOCKED  
**Primary target:** Windows desktop + Windows handheld PCs (especially ROG Ally)  
**Input priority:** Controller first, mouse/keyboard second  
**Scope:** Build the Meadows vertical slice only. Do not begin Biome 2 until the Meadows exit criteria are met.

---

## 1. Core Fantasy

Tetherbound is a third-person open-world survival/crafting creature-training game centered on one promise:

> **Catch, train, bond with, customize, and build the strongest possible team of five pals.**

The game draws structural inspiration from:
- Valheim: open wilderness, danger by biome, gathering, crafting, building, preparation, food buffs, death recovery.
- Creature-survival games: visible creatures roaming a 3D world and useful traversal companions.
- Pokémon: creature levels/types/moves/TMs, trainer teams, eight major regional masters, rare unique creatures.
- Pokémon GO: real-time creature combat and catching during battle.

This is not a collection game where hundreds of creatures live in storage. The five-pal limit is the core differentiator.

---

## 2. Non-Negotiable Design Pillars

1. **Five pals means five total.**
   - No box.
   - No reserve team.
   - No stable.
   - No hidden storage loophole.
   - Catching a sixth forces a permanent release decision.

2. **The five should become emotionally important.**
   - Naming.
   - Bond.
   - Favorite foods.
   - Resting together.
   - Physical pal beds.
   - Traits.
   - Best Pal progression.
   - Battle history.
   - Emotional release ceremony.

3. **The trainer does not fight.**
   - No swords, guns, bows, or combat tools.
   - Tools gather/build/fish.
   - Pals fight pals.
   - Aggressive wild pals can threaten the trainer before combat starts.

4. **The world is not level-gated by UI.**
   - Players may physically reach harder regions early.
   - Difficulty and environmental danger tell them they are not ready.

5. **Building supports adventure rather than replacing it.**
   - Home.
   - Safety.
   - Beds.
   - Recovery.
   - Storage.
   - Crafting.
   - Food.
   - Berry farming.
   - Lights/fires/fences.
   - No pal labor automation.

6. **Build fast and iterate.**
   - Prove moment-to-moment fun before expanding content.
   - Meadows only until it is genuinely enjoyable.

---

## 3. Story Frame

The player lives with their grandfather, a former trainer who is now too old to travel the world as he once did.

Team Tether has returned and seized eight important regional places of power. They are holding exceptional pals there and using them as part of a larger system. Grandpa cannot stop them himself and entrusts the player with a starter and the beginning of the journey.

The player chooses between three unique starter pals:
- Ground
- Water
- Air

The other two remain with Grandpa. Starter species never appear as wild catches and do not evolve.

There are eight major regional Team Tether strongholds, one associated with each dominant biome/type. Each contains a unique captive legendary/special pal that cannot be obtained elsewhere.

General stronghold conclusion:
1. Defeat Team Tether trainers.
2. Defeat regional Warden/master trainer.
3. Disable/free the tether mechanism.
4. Free the unique pal.
5. Story moment.
6. The unique pal voluntarily offers to join.
7. If the player already has five, trigger the release ceremony.
8. Region meaningfully changes / Team Tether influence is reduced.
9. The world points toward further progression.

Team Tether should have nuance. Some members are true believers, employees, opportunists, conflicted Wardens, or genuinely cruel leaders. Do not write them as universally cartoonish villains.

The exact endgame motive remains intentionally open.

---

## 4. Engine and Delivery

### LOCKED
Use **Godot**.

Primary shipping target:
- Windows desktop.
- Windows handheld PCs such as ROG Ally.
- Native executable/export.

Secondary possibilities:
- Web export may be investigated later.
- Phone is not a first-version requirement.

Do not constrain the game to browser limits.

### Development requirements
- Prefer Godot scenes/resources/data files over hardcoded content.
- Use version-control-friendly project organization.
- Keep creatures, moves, traits, recipes, spawns, items, and balance data externally configurable.
- No major game-design invention merely to unblock coding. Mark unanswered design questions clearly.

---

## 5. Player Movement and Camera

### LOCKED
Modern third-person movement:
- Walk.
- Sprint.
- Jump.
- Camera orbit.
- Controller-first.
- Mouse/keyboard equivalent.
- Stamina.
- Fall damage.
- No climbing system in the initial vertical slice.

The exact feel is a prototype tuning problem, not a paper-design problem.

Goals:
- Responsive on controller.
- Comfortable on ROG Ally.
- Camera avoids fighting the player.
- Traversal through rolling terrain should feel good before creature systems are layered on top.

---

## 6. Save Structure

### LOCKED
- Multiple save slots.
- Target 3–5 slots.
- Each save contains its own world/player progression.
- Frequent autosave.
- Save & Quit.
- World is authored, not a new procedural seed per save.

Exact save serialization implementation is technical, not a design decision.

---

## 7. World Structure

Use **authored macro geography + procedurally populated wilderness**.

Authored:
- Biome locations.
- Rivers/lakes.
- Mountains.
- Roads.
- Villages.
- Strongholds.
- Caves.
- Islands.
- Traversal secrets.
- Sightlines.
- Major landmarks.

Procedural/rule-based dressing:
- Trees.
- Rocks.
- Grass/bushes.
- Gatherables.
- Minor wilderness detail.
- Wild pal populations.
- Some loot.

Everyone broadly experiences the same geography.

World map begins blank and reveals as explored.

No free fast travel before teleport-capable progression.

---

## 8. Eight Types

LOCKED:
- Ground
- Water
- Air
- Fire
- Electric
- Ice
- Psychic
- Dark

Rules:
- Dual typing exists but is uncommon.
- Each biome has a dominant type.
- Other types can appear where ecologically sensible.
- Normal long-term target: about 4–5 species per type, subject to scope/assets.
- Unique starters and stronghold legendaries are outside normal wild availability.

### Type system direction
Keep it much simpler than Pokémon.
- Rough target: 2 strengths + 2 weaknesses per type.
- Neutral matchups should dominate.
- Same-type moves get a modest bonus.
- Compatible off-type moves exist.
- Dual types can multiply/cancel matchup effects.

Exact chart is tunable and should be defined before full Meadows balancing.

---

## 9. Biome Spine — Concepts Only

1. **Ground — Meadows/Prairie**
   - rolling grassland, oak groves, streams, ponds
   - first Team Tether sacred Hall/stronghold

2. **Water — Coast/Wetlands**
   - river/coast/marsh
   - flooded temple, dam, or water-control site

3. **Electric — Stormlands**
   - storms, machinery
   - power station / storm-harvesting stronghold

4. **Fire — Volcanic Highlands**
   - heat/lava
   - stronghold in or around volcano

5. **Ice — Frozen Mountains**
   - snow/cold/altitude
   - frozen summit fortress

6. **Air — Cliffs/Highlands**
   - vertical terrain
   - high tower / skyward stronghold

7. **Psychic — Strange Ancient Wilderness**
   - unnatural ancient geography
   - observatory or old complex

8. **Dark — Blighted Endgame Region**
   - most hostile region
   - major Team Tether headquarters

Do not build 2–8 now.

---

## 10. Pal Ownership

- Hard maximum: five owned pals.
- Pals are not always summoned.
- Player chooses which pal to deploy when combat begins.
- Pals can be renamed.
- New captures can keep species name by default.
- Sixth capture pauses progression for a keep/release ceremony.
- Released pals are permanently gone.
- Ceremony should show:
  - name
  - species
  - level
  - bond
  - traits
  - equipped moves
  - time together
- Use an emotional physical presentation rather than a sterile list when practical.

---

## 11. Pal Stats and Progression

### Levels
- 1–50.
- Combat is primary XP.
- Smaller XP can come from exploration and bonding activities.
- No player-scaling of wild pal levels.

### Core stats
- HP
- Attack
- Defense

No generic Speed stat. Cadence/energy lives in move definitions and traits.

### Individuality
- Same-species pals have slightly different underlying stat quality.
- Show appraisal through stars/bars, not exact IV numbers.
- Each pal starts with one trait.
- A second trait can develop later through progression/bond.

### Evolution
- Limited, not universal.
- Starters do not evolve.
- Some rare pals do.
- Evolution must visually make sense with available assets.
- Example: rooting pig → armoured boar.
- Requirements: level + high bond + item/condition.
- Preserve nickname, appraisal, traits, bond, TMs, Best Pal progress, and history.

---

## 12. Bond and Best Pal

Bond increases through:
- fighting together
- time together
- resting
- feeding
- favorite food

Best Pal is meaningful progression, not a cosmetic badge.

Best Pal abilities should be species-specific where possible:
- combat survivability
- better charged-energy behavior
- improved traversal
- other defining perks

Avoid punitive low-bond behavior in the first version.

---

## 13. Moves and TMs

Each pal can know:
- 2 Quick moves
- 2 Charged moves

Equip:
- 1 Quick
- 1 Charged

Quick moves:
- deal damage
- generate energy
- have varied damage/cadence/energy generation

Charged moves:
- consume energy
- have varied cost/power
- create spam-vs-nuke decisions

TMs:
- Found in the world.
- Finding one permanently unlocks that move as teachable.
- Not consumed after one teaching.
- Species have compatibility lists.
- Off-type moves are allowed when physically/thematically sensible.

Exact statuses/move counts are not locked.

---

## 14. Combat Mode

Combat remains in the physical world.

When combat begins:
- Camera moves in.
- Trainer stays visible.
- Player selects/deploys one pal.
- Enemy pal stays visible.
- Combat UI appears.

Commands:
1. Quick Attack
2. Charged Attack
3. Throw Orb
4. Run
5. Switch

Rules:
- Real time.
- No shields.
- No trainer attacks.
- Trainer fights are team-vs-team.
- Trainer-owned pals cannot be caught.
- Switching has a cooldown.
- No dodge in initial design unless playtest demands it.

**Amended by `docs/decisions/D07-combat-is-piloted-not-commanded.md`.** The five
commands above are not a menu. On entering Combat Mode the player takes over the
deployed pal — camera and controls transfer to the creature — and both fighters
move freely inside a bounded arena centred on where the fight started. Attacks
are aimed and can miss. The trainer still never attacks and cannot be targeted.

There is still no dodge button: **movement is the dodge**. That resolves the
"unless playtest demands it" clause above by removing the verb rather than
adding one.

### Critical trainer safety rule
Once combat mode begins, attacks are **pal-vs-pal**. The enemy does not simply attack the human while the combat UI is active.

Outside combat, aggressive wild pals can threaten the trainer. The player must flee or initiate/deploy into combat.

Combat initiation:
- Player challenges/interacts.
- Player targets and chooses battle.
- Aggressive pal initiates.
- **Not** simple proximity for peaceful pals.

---

## 15. Catching

- Throw Orb is always available during a wild fight.
- Full-health throws are allowed.
- Powerful/full-health pals should be extremely difficult to catch.
- Damaging a pal improves catch viability.
- Over-damaging it and causing a faint ends the capture opportunity.
- Fainted wild pals remain visible temporarily but cannot be captured.

### Throw interaction
Use a physical aiming interaction:
- Select Throw Orb.
- Brief over-the-shoulder / aiming mode.
- Aim at target.
- Physical projectile.
- Accuracy/timing affects catch chance.

Do not automatically throw/roll without player aim.

### Orb economy
- Basic orbs should be affordable enough that players are encouraged to try catching.
- Better orbs become meaningful crafting/progression rewards.
- Avoid making players afraid to experiment because orbs are excessively scarce.

Exact catch formula and orb tiers are tuning data.

---

## 16. Fainting and Recovery

Pal at 0 HP:
- passes out
- unavailable
- does not auto-revive with time in the field

Revive via:
1. Special revival item.
2. Recovery in its physical pal bed at home.

Beds:
- Up to one per owned pal.
- Speed normal HP recovery.
- Contribute to rest/bond.
- Pals can visibly sleep/rest at home.

When the player dies:
- owned pals return home to their beds
- no pal loss
- preserve their damage/fainted state as appropriate

---

## 17. Traversal Pals

Only some species can support traversal.

Normal progression:
1. Ride
2. Swim
3. Fly
4. Teleport

Ride/swim/fly require crafted saddle/harness-type equipment.

Riding saddle is generic across compatible rideable pals.

Traversal pals remain viable combat pals; do not create "utility-only" dead slots in a five-pal team.

Legendary pals have exceptional versions:
- Riding: faster / huge jump / exceptional stamina.
- Swimming: underwater access.
- Flying: faster and potentially no stamina limitation.
- Teleporting: normal teleporters can return to discovered destinations; legendary can reach unknown/ancient destinations.

Exact later systems remain roadmap-only.

---

## 18. Trainer Survival

### Equipment
- Helmet
- Upper body
- Lower body
- Boots
- Backpack

Trainer armor protects the human, not pals.

### Stamina
Used by movement and physical world actions.

### Food
Valheim-like buff philosophy:
- No starvation death.
- Eating improves health/stamina/regeneration or other preparation stats.

### Environmental danger
Later biomes require gear:
- cold resistance
- heat resistance
- other biome-specific protection
- underwater/breathing support later

---

## 19. Inventory and Tools

Inventory:
- Slot + stack system.
- No weight limit.

Need:
- clear Inventory button
- clear Map button
- quick tool selection

Tools:
- Axe
- Pickaxe
- Knife
- Hammer
- Fishing Rod

Tools:
- have durability
- repair for free at appropriate station
- cannot damage pals or humans

There is **no hunting/butchering gameplay**.

Do not create a meat/leather economy that assumes killing pals/wildlife.

---

## 20. Building and Base

Base purpose:
- safety
- recovery
- respawn
- storage
- crafting
- simple food preparation
- berry farming
- light/fire
- pal beds
- personalized home

Expected categories:
- floors
- walls
- roofs
- doors
- fences
- beds
- pal beds
- lights
- campfire
- workbench
- storage
- simple farm plots

Pals do not work jobs.

Recipes primarily unlock through discovering materials/crafting progression.

### Early mandatory tutorial
Player must:
1. Build shelter.
2. Build bed.
3. Build campfire.
4. Rest with starter.

After that, build scale is largely player choice.

---

## 21. Farming and Fishing

Farming:
- Meadows only needs berries initially.
- Plant → wait → harvest.
- No watering chores.

Fishing:
- Rod.
- Cast.
- Wait for bite.
- Simple timing interaction.
- Keep scope small.

---

## 22. Player Death

On player death:
- carried inventory drops into a satchel at death location
- old satchels do not move
- multiple satchels can coexist
- each remains marked on map/minimap
- no XP loss
- no level loss
- pals go home

Exact item exemptions can be tuned.

---

## 23. Map / Minimap

World map:
- blank initially
- reveals through exploration
- supports manual markers

Minimap:
- local terrain
- direction/compass
- player markers
- discovered locations
- bed/home
- death satchels

Do not reveal every wild pal automatically.

No free map fast travel before teleport progression.

---

## 24. Weather and Day/Night

Meadows weather:
- clear
- cloudy
- rain
- thunderstorms
- fog

Weather can affect spawn/activity rules.

Day/night:
- nocturnal species exist
- night can be more dangerous due to different species
- do not just add levels to every pal at night

Rare pals can depend on:
- habitat
- time
- weather

---

## 25. Meadows Visual Direction

This is the only biome to build now.

Visual target:
- rolling grassy hills
- oak woodland patches
- streams
- ponds
- rocky outcroppings
- wildflowers
- dirt trails
- distant landmarks
- small settlement
- cozy but adventurous

Art direction:
> **Between Valheim and Palworld.**

- Stylized.
- Colorful.
- Grounded enough that cabins, terrain, tools, and weather feel believable.
- Creatures may be recognizable fantasy-styled animals rather than heavily abstract monster designs.
- Cohesion matters more than whether an asset was free.

Player:
- one authored character initially
- no character creator required

Opening:
- player lives with Grandpa
- small settlement
- Grandpa's home is safe starting location

---

## 26. Meadows Pal Scope

Completed Meadows:
- 3 unique starters
- 12 catchable wild species
- 1 unique Ground legendary
- at least one evolved form for a rare species

Starter types:
- Ground
- Water
- Air

Starter roles:
- Ground = durable / forgiving
- Water = balanced / efficient
- Air = aggressive / fast-energy

### Provisional wild ecological roster
Ground:
- rabbit — common/tutorial
- rooting pig → armoured boar — rare evolution
- canine — mobile generalist
- deer/horse-like — rideable
- badger-like — aggressive

Water:
- frog/newt — common
- turtle — defensive
- otter/beaver — quick river species
- waterfowl — uncommon Water/Air

Air:
- small bird — common
- owl — nocturnal
- hawk/eagle — rare

These are roles/silhouettes, not locked names/assets.

Pal size should vary substantially.

Not every pal needs obvious magical effects.

---

## 27. Meadows Difficulty

No player scaling.

Use geographically rising danger:
- near Grandpa: low
- deeper Meadows: moderate
- far wilderness: higher
- around Team Tether stronghold: highest local danger
- regional Warden/master trainer = biome culmination

Exact numbers should be tuned by playtesting.

Later biomes remain physically discoverable early and lethal if the player is unprepared.

---

## 28. Meadows Stronghold and Legendary

First stronghold:
- ancient/sacred Meadows location
- visibly occupied and industrialized by Team Tether
- old stone/natural forms contrasted with:
  - machinery
  - cables
  - barricades
  - cages/tether equipment
  - trainers

First unique pal:
- Ground type
- ultimate riding mount
- substantially better traversal than normal riding pals
- exceptional speed and/or huge jump
- exact species/asset to be chosen later

---

## 29. Meadows 4–8 Hour Arc

1. Wake at Grandpa's home.
2. Learn Team Tether has returned/seized the regional stronghold.
3. Choose Ground/Water/Air starter.
4. Learn movement and basic gathering.
5. First wild pal encounter.
6. Learn combat.
7. Learn aimed catching.
8. Gather enough to establish a shelter.
9. Build campfire + bed and rest with starter.
10. Explore.
11. Catch and shape team.
12. Learn simple food/berry/fishing systems.
13. Discover better crafting/orbs.
14. Encounter rideable pal.
15. Discover/craft generic riding saddle.
16. Use riding to explore farther.
17. Discover increasingly dangerous territory.
18. Encounter Team Tether in the world.
19. Prepare team/equipment.
20. Assault stronghold.
21. Fight Warden/master trainer.
22. Free legendary Ground mount.
23. If full, perform release ceremony.
24. Establish larger mystery and future-biome direction.

---

## 30. Meadows Size

LOCKED DIRECTION:
- Not enormous.
- Dense enough that exploration regularly yields something interesting.
- Do not choose a huge kilometer count before movement is fun.

Implementation rule:
Prototype player speed, riding speed, sightlines, terrain density, and encounter pacing first. Then size the authored Meadows so the target 4–8 hour arc feels dense rather than empty.

---

## 31. Assets and Licensing

Assets do not need to be CC0 for personal development.

Allowed during development:
- CC0/free assets
- permissively licensed assets
- paid assets
- other assets the owner is legally entitled to use privately

Track:
- asset name
- source URL/store
- author
- license
- purchase requirement
- modifications
- destination path

If the game is ever publicly distributed, perform a license audit and purchase/replace anything necessary.

Do not allow random asset accumulation to destroy visual cohesion.

---

## 32. Features Explicitly NOT Required for First Meadows

Do not implement unless they become necessary for the Meadows slice:
- Biomes 2–8
- swimming traversal
- flying traversal
- teleport traversal
- base raids
- pal worker automation
- multiplayer
- phone UI
- full web support
- character creator
- hunting/butchering
- deep farming
- large crafting tree
- dozens of status effects
- universal evolution
- procedural world seeds
- dodge combat
- structural integrity simulation unless building proves to need it

---

## 33. Exit Criteria Before Biome 2

**Do not begin Biome 2 until the owner can play Meadows and genuinely say the following are true:**

1. Third-person exploration feels good on controller.
2. Repeated combat is enjoyable, not merely functional.
3. Throwing/catching feels satisfying.
4. Building and improving a five-pal team creates meaningful choices.
5. The five-pal limit creates attachment and interesting release decisions.
6. Building a small home feels useful and enjoyable.
7. Resting/recovering with pals makes the base feel like home.
8. The Meadows looks visually cohesive rather than assembled from unrelated assets.
9. Performance is comfortable on the target Windows handheld/PC.
10. Controller UI is natural.
11. The player can understand the systems without reading a design document.
12. After completing the current test objective, the owner would voluntarily keep playing.

If those are not true, iterate Meadows instead of adding content.

---

## 34. Agent Authority

Claude Code/Codex MAY:
- choose sensible temporary values for tunable balance constants
- prototype implementations
- refactor architecture
- source candidate assets according to the asset rules
- create placeholder data/content clearly labeled as such

Claude Code/Codex MAY NOT silently decide:
- new core mechanics
- extra owned-pal storage
- trainer weapons
- new mandatory survival meters
- new biomes
- monetization
- multiplayer
- fundamental art direction
- major story changes
- replacement of the five-pal rule
- permanent combat complexity not specified here

When a genuine major design choice blocks work, surface it rather than quietly redesigning the game.
