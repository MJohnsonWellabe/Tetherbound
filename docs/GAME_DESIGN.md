# TETHERBOUND — MASTER GAME DESIGN

**Status:** Implementation-ready pre-production specification  
**Engine:** **Godot** — LOCKED  
**Primary target:** Windows desktop + Windows handheld PCs (especially ROG Ally)  
**Input priority:** Controller first, mouse/keyboard second  
**Scope:** Build the Meadows vertical slice only. Do not begin Biome 2 until the Meadows exit criteria are met.

---

## 1. Core Fantasy

Tetherbound is a third-person open-world survival/crafting creature-training game centered on one promise:

> **Catch, train, bond with, customize, and build the strongest possible team of five creatures.**

The game draws structural inspiration from:
- Valheim: open wilderness, danger by biome, gathering, crafting, building, preparation, food buffs, death recovery.
- Creature-survival games: visible creatures roaming a 3D world and useful traversal companions.
- Pokémon: creature levels/types/moves/TMs, trainer teams, eight major regional masters, rare unique creatures.
- Pokémon GO: real-time creature combat and catching during battle.

This is not a collection game where hundreds of creatures live in storage. The five-creature limit is the core differentiator.

---

## 2. Non-Negotiable Design Pillars

1. **Five creatures means five total.**
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
   - Physical creature beds.
   - Traits.
   - Best Creature progression.
   - Battle history.
   - Emotional release ceremony.

3. **The trainer does not fight.**
   - No swords, guns, bows, or combat tools.
   - Tools gather/build/fish.
   - Creatures fight creatures.
   - Aggressive wild creatures can threaten the trainer before combat starts.

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
   - No creature labor automation.

6. **Build fast and iterate.**
   - Prove moment-to-moment fun before expanding content.
   - Meadows only until it is genuinely enjoyable.

---

## 3. Story Frame

The player lives with their grandfather, a former trainer who is now too old to travel the world as he once did.

Team Tether has returned and seized eight important regional places of power. They are holding exceptional creatures there and using them as part of a larger system. Grandpa cannot stop them himself and entrusts the player with a starter and the beginning of the journey.

The player chooses between three unique starter creatures:
- Ground
- Water
- Air

The other two remain with Grandpa. Starter species never appear as wild catches and do not evolve.

There are eight major regional Team Tether strongholds, one associated with each dominant biome/type. Each contains a unique captive legendary/special creature that cannot be obtained elsewhere.

General stronghold conclusion:
1. Defeat Team Tether trainers.
2. Defeat regional Warden/master trainer.
3. Disable/free the tether mechanism.
4. Free the unique creature.
5. Story moment.
6. The unique creature voluntarily offers to join.
7. If the player already has five, trigger the release ceremony.
8. Region meaningfully changes / Team Tether influence is reduced.
9. The world points toward further progression.

Team Tether should have nuance. Some members are true believers, employees, opportunists, conflicted Wardens, or genuinely cruel leaders. Do not write them as universally cartoonish villains.

**Amended by `docs/decisions/D23` — the motive is no longer open.** The line
that stood here ("the exact endgame motive remains intentionally open") is
false as of the owner's 2026-08-11 specification. See
`docs/MEADOWS_PROGRESSION_SPEC.md` §23–§31: the eight legendaries are living
conduits for natural forces, and Team Tether binds them into Tether systems to
hold **Tether Rifts** open — physical separations that keep the eight regions
from being one landmass. Their power is a monopoly on the movement of
resources, creatures, people and trade. Their doctrine, which they believe and
which may be partly true, is that the connected world was unstable and the
barriers made peace. Freeing a legendary collapses its Rift and physically
reconnects a region.

The nuance rule above survives intact and matters more now: a Warden can be
sincere while the system is oppressive.

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
- Wild creature populations.
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

**Amended by `docs/decisions/D23`.** The eight biomes are severed pieces of one
landmass, not eight islands. The concepts below are unchanged; the *reason*
they are apart is now canon (`MEADOWS_PROGRESSION_SPEC.md` §23–§30), and each
region reconnects to the world as its legendary is freed.

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

## 10. Creature Ownership

- Hard maximum: five owned creatures.
- Creatures are not always summoned.
- Player chooses which creature to deploy when combat begins.
- Creatures can be renamed.
- New captures can keep species name by default.
- Sixth capture pauses progression for a keep/release ceremony.
- Released creatures are permanently gone.
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

## 11. Creature Stats and Progression

### Levels
- 1–50.
- Combat is primary XP.
- Smaller XP can come from exploration and bonding activities.
- No player-scaling of wild creature levels.

### Core stats
- HP
- Attack
- Defense

No generic Speed stat. Cadence/energy lives in move definitions and traits.

### Individuality
- Same-species creatures have slightly different underlying stat quality.
- Show appraisal through stars/bars, not exact IV numbers.
- Each creature starts with one trait.
- A second trait can develop later through progression/bond.

### Evolution
- Limited, not universal.
- Starters do not evolve.
- Some rare creatures do.
- Evolution must visually make sense with available assets.
- Example: rooting pig → armoured boar.
- Requirements: level + high bond + item/condition.
- Preserve nickname, appraisal, traits, bond, TMs, Best Creature progress, and history.

---

## 12. Bond and Best Creature

Bond increases through:
- fighting together
- time together
- resting
- feeding
- favorite food

Best Creature is meaningful progression, not a cosmetic badge.

Best Creature abilities should be species-specific where possible:
- combat survivability
- better charged-energy behavior
- improved traversal
- other defining perks

Avoid punitive low-bond behavior in the first version.

---

## 13. Moves and TMs

Each creature can know:
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

**Amended by `docs/decisions/D44`, 2026-08-15, on the owner's playtest report
("I can pick up a TM but it needs to go in my inventory and then I see it's
stats and choose who to teach it to"): a found TM is an ITEM in the satchel,
not a permanent unlock, and teaching SPENDS it — one disc, one creature. The
compatibility-list and off-type lines above are untouched.**

Exact statuses/move counts are not locked.

---

## 14. Combat Mode

Combat remains in the physical world.

When combat begins:
- Camera moves in.
- Trainer stays visible.
- Player selects/deploys one creature.
- Enemy creature stays visible.
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
- Trainer-owned creatures cannot be caught.
- Switching has a cooldown.
- No dodge in initial design unless playtest demands it.

**Amended by `docs/decisions/D07-combat-is-piloted-not-commanded.md`.** The five
commands above are not a menu. On entering Combat Mode the player takes over the
deployed creature — camera and controls transfer to the creature — and both fighters
move freely inside a bounded arena centred on where the fight started. Attacks
are aimed and can miss. The trainer still never attacks and cannot be targeted.

There is still no dodge button: **movement is the dodge**. That resolves the
"unless playtest demands it" clause above by removing the verb rather than
adding one.

### Critical trainer safety rule
Once combat mode begins, attacks are **creature-vs-creature**. The enemy does not simply attack the human while the combat UI is active.

Outside combat, aggressive wild creatures can threaten the trainer. The player must flee or initiate/deploy into combat.

Combat initiation:
- Player challenges/interacts.
- Player targets and chooses battle.
- Aggressive creature initiates.
- **Not** simple proximity for peaceful creatures.

---

## 15. Catching

- Throw Orb is always available during a wild fight.
- Full-health throws are allowed.
- Powerful/full-health creatures should be extremely difficult to catch.
- Damaging a creature improves catch viability.
- Over-damaging it and causing a faint ends the capture opportunity.
- Fainted wild creatures remain visible temporarily but cannot be captured.

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

Creature at 0 HP:
- passes out
- unavailable
- does not auto-revive with time in the field

Revive via:
1. Special revival item.
2. Recovery in its physical creature bed at home.

Beds:
- Up to one per owned creature.
- Speed normal HP recovery.
- Contribute to rest/bond.
- Creatures can visibly sleep/rest at home.

When the player dies:
- owned creatures return home to their beds
- no creature loss
- preserve their damage/fainted state as appropriate

---

## 17. Traversal Creatures

Only some species can support traversal.

Normal progression:
1. Ride
2. Swim
3. Fly
4. Teleport

Ride/swim/fly require crafted saddle/harness-type equipment.

Riding saddle is generic across compatible rideable creatures.

Traversal creatures remain viable combat creatures; do not create "utility-only" dead slots in a five-creature team.

Legendary creatures have exceptional versions:
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

Trainer armor protects the human, not creatures.

### Stamina
Used by movement and physical world actions.

### Food
Valheim-like buff philosophy:
- No starvation death.
- Eating improves health/stamina/regeneration or other preparation stats.

[Amended by `docs/decisions/D29`, 2026-08-13: satiety is now a real stat
that drains slowly and gives soft debuffs when low (slower stamina
regen, reduced move speed when critical). "No starvation death" still
holds exactly as written above — only "no meter at all" changed.]

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
- cannot damage creatures or humans

There is **no hunting/butchering gameplay**.

Do not create a meat/leather economy that assumes killing creatures/wildlife.

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
- creature beds
- personalized home

Expected categories:
- floors
- walls
- roofs
- doors
- fences
- beds
- creature beds
- lights
- campfire
- workbench
- storage
- simple farm plots

Creatures do not work jobs.

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
- creatures go home

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

Do not reveal every wild creature automatically.

No free map fast travel before teleport progression.

[Amended by `docs/decisions/D33`, 2026-08-13: minimap and full map now
share one data layer (`MapState` / `Game.map`), sourced from
`data/config/map_landmarks.json` and a baked top-down terrain texture
rather than a second live camera — never a wild-creature radar. Combat UI
around it also changed this session: capture odds display as an explicit
percentage (`D31`), creature switching is a real mid-combat action (`D32`), and
creatures now carry level/XP/moves/bond (`D30`).]

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
- do not just add levels to every creature at night

Rare creatures can depend on:
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

## 26. Meadows Creature Scope

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

Creature size should vary substantially.

Not every creature needs obvious magical effects.

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

First unique creature:
- Ground type
- ultimate riding mount
- substantially better traversal than normal riding creatures
- exceptional speed and/or huge jump
- exact species/asset to be chosen later

**Extended by `docs/decisions/D23`.** `MEADOWS_PROGRESSION_SPEC.md` §8 gives the
first stronghold a five-space interior — Outer Works, Courtyard / Hall
Approach, Tether Chamber Approach, Warden Arena, Legendary Chamber — and a
30–60 minute first-clear target. Explicitly **not** a giant puzzle dungeon
unless that is separately decided. §28 of the spec adds the reveal: the
legendary is the power source for the Meadows Tether Rift, the Warden knows it,
and freeing it collapses the Rift.

---

## 29. Meadows 4–8 Hour Arc

**Amended by `docs/decisions/D42`: the target is 3–4 hours, below this section's
own 4–8 hour band.** The heading's range is historical. Every beat below still
happens; the chapter is simply denser per minute.

**Superseded in ordering and detail by `docs/decisions/D23`.** Every beat below
still happens, and the 4–7 hour target in
`docs/MEADOWS_PROGRESSION_SPEC.md` sits inside this section's own 4–8 hour
band. But the spec's Bands 0–4 and Acts I–VI are now the authority on their
sequence, their gates and the preparation between them. Read this list as the
ingredients and the spec as the recipe.

1. Wake at Grandpa's home.
2. Learn Team Tether has returned/seized the regional stronghold.
3. Choose Ground/Water/Air starter.
4. Learn movement and basic gathering.
5. First wild creature encounter.
6. Learn combat.
7. Learn aimed catching.
8. Gather enough to establish a shelter.
9. Build campfire + bed and rest with starter.
10. Explore.
11. Catch and shape team.
12. Learn simple food/berry/fishing systems.
13. Discover better crafting/orbs.
14. Encounter rideable creature.
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

**Amended by `docs/decisions/D42`, with a carve-out.** The target arc is now
3–4 hours, but **the terrain does not shrink to match** — D42 explicitly
suspends the "size the authored Meadows so the target 4–8 hour arc feels dense"
sentence below as a *sizing* instruction. `D23` argued the footprint from arc
length in one direction only; that argument does not run backwards into a
rebake. The locked direction below — dense, not enormous — is unchanged and
reinforced: a world sized for the longer arc, played in 3–4 hours, is denser
per minute, which is where §30 already points.

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
- creature worker automation
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

**These twelve are deliberately not renumbered by `docs/decisions/D23`** —
`ralph/BACKLOG.md`'s `R9.5`, `R0.11`, `R2.9`, `R4.12` and `R6.3` all cite them
by number, and renumbering would silently break every one of those citations.
`docs/MEADOWS_PROGRESSION_SPEC.md` §39 adds a **second, chapter-level gate**
alongside these, testing the arc rather than the feel. Both must pass. The
spec's own owner-facing version of the question is worth keeping in view:
*"I had a reason to keep playing for several hours before the first Warden."*
(**`docs/decisions/D42`:** several hours is now a 3–4 hour target, not 4–7. The
criterion itself is unchanged — it was always the real test.)

**Do not begin Biome 2 until the owner can play Meadows and genuinely say the following are true:**

1. Third-person exploration feels good on controller.
2. Repeated combat is enjoyable, not merely functional.
3. Throwing/catching feels satisfying.
4. Building and improving a five-creature team creates meaningful choices.
5. The five-creature limit creates attachment and interesting release decisions.
6. Building a small home feels useful and enjoyable.
7. Resting/recovering with creatures makes the base feel like home.
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
- extra owned-creature storage
- trainer weapons
- new mandatory survival meters
- new biomes
- monetization
- multiplayer
- fundamental art direction
- major story changes
- replacement of the five-creature rule
- permanent combat complexity not specified here

When a genuine major design choice blocks work, surface it rather than quietly redesigning the game.
