> **Provenance.** Owner-supplied, delivered 2026-08-11, dated 2026-08-10 in its
> own header. Everything below the rule is the owner's document, unedited.
> Made canon by `docs/decisions/D23-the-meadows-is-the-first-game.md`, which
> records what it supersedes in `GAME_DESIGN.md` and `MEADOWS_VERTICAL_SLICE.md`
> and the production constraints (§20–§22) it makes binding.
>
> Where this file and an older design doc disagree, **this file wins** — except
> where D23 names an explicit carve-out. There are two, and they matter:
> `CLAUDE.md`'s Biome 2 rule still stands over §38 step 45, and
> `GAME_DESIGN.md` §33's twelve exit criteria are not renumbered.

---

# TETHERBOUND — MEADOWS OWNER FIXES + FULL PROGRESSION STORY

**Status:** Owner-directed implementation specification  
**Date:** 2026-08-10  
**Scope:** Meadows biome / first several hours of Tetherbound

## Purpose

The current build now has the major ingredients of a playable first day: farmhouse opening, Grandpa, starter selection, village, combat/catching, gathering, camp/bedroll, day/night, villagers, authored paths, and a visible stronghold. The next priority is to make the experience reliable and give the Meadows a real multi-hour progression arc.

The Meadows should not be a 15-minute tutorial followed by "walk to the gym." It should be the game's first complete chapter.

Target first-completion time: **4–7 hours**, longer for exploration, team-building, optional trainers, gathering, and catching.

---

# 1. OWNER-REPORTED FIXES — IMPLEMENT BEFORE STORY EXPANSION

## A. Burrowback and Terrapup are too similar

Keep Terrapup's existing starter identity. Change Burrowback.

### Burrowback palette
- charcoal / near-black primary coat
- cool gray or pale cream face stripe
- slate stone nodules
- muted rust-brown lower-leg/belly accents
- minimal moss/green
- dark heavy claws

### Shape differentiation
- lower and wider body
- shorter ears
- heavier front shoulders
- larger digging claws
- flatter back
- more obvious badger face stripe
- avoid puppy-like eye framing

**Acceptance:** Terrapup and Burrowback are unmistakable at normal gameplay distance and in silhouette.

---

## B. The birds need separate identities

Do not let Pipwing, Duskhush, Galecrest, Reedwing, and the Air starter read as palette swaps.

### Pipwing
Common field bird.
- warm meadow gold / ochre
- cream belly
- charcoal wing tips
- tiny sky-blue accent only
- round, compact silhouette

### Duskhush
Nocturnal owl.
- slate gray
- dusty lavender-gray
- muted cream facial disk
- amber eyes
- almost no saturated blue
- vertical barrel silhouette

### Galecrest
True hawk/raptor.
- dark rust / chestnut
- charcoal flight feathers
- pale sand underside
- gold eye/beak accent
- broad wings, hooked beak, horizontal predator silhouette
- must not resemble the Air starter

### Reedwing
Water/Air waterfowl.
- deep teal head/neck
- cream body
- copper/tan wing panels
- blue-gray tail
- orange/tan bill and webbed feet
- longer neck / buoyant waterfowl body

Keep the Air starter's already-established design.

**Acceptance:** all five remain distinguishable as black silhouettes.

---

## C. PC mouse must control the camera

Mouse-look is mandatory for Windows.

Required behavior:
- gameplay captures mouse
- mouse controls yaw/pitch immediately
- Escape releases cursor for menus
- closing menu restores capture
- dialogue/UI that needs cursor can temporarily release it
- Alt-Tab/focus-loss cannot permanently break mouse-look
- clicking/re-entering gameplay restores intended capture
- sensitivity remains config-driven
- exploration, combat, and Orb aiming all use appropriate mouse control

Do not rewrite the camera system unless necessary. The current camera already consumes mouse motion when the cursor is captured; fix the **capture/re-capture lifecycle**.

### Acceptance
A fresh Windows launch can be played for 10 minutes with mouse/keyboard without the player having to think about cursor capture.

---

## D. Grandpa must be impossible to skip at the start

The opening depends on Grandpa and should not rely on the player discovering the correct prompt.

### Canon rule
**The player cannot leave Grandpa's house until the required Grandpa opening interaction is complete.**

Preferred implementation:
1. player approaches/tries to cross the exterior doorway
2. if opening state is incomplete, crossing is stopped
3. Grandpa calls to the player
4. camera/dialogue redirects attention to Grandpa
5. the required conversation begins automatically
6. required items/story beats complete
7. door becomes available when the proper beat is reached

Prefer an in-world line such as:
> "Hold on. You're not walking out there empty-handed."

Do not use a sterile "Talk to Grandpa first" error if the sequence can trigger naturally.

Once the opening is complete, the door behaves normally and never re-triggers this gate.

---

## E. The player cannot fall off the world

The Meadows must not read as a floating level.

Build a believable physical perimeter using:
- fieldstone walls
- ranch fencing
- hedgerows
- terrain ridges
- rivers
- rock formations
- dense impassable growth
- authored Team Tether barriers at specific routes

Use invisible collision only as support for visible boundaries, not as the only boundary.

Add a backup kill/respawn volume below the world only as a failsafe.

### Seven future-biome spokes

The Meadows perimeter should visibly contain **seven outward routes** toward the other biomes.

Examples:
- Water: river gorge / broken bridge
- Electric: old road toward storm country
- Fire: mountain trail
- Ice: high pass
- Air: cliff/highland road
- Psychic: ancient stone gate/road
- Dark: sealed blighted road

They do not need to be usable yet, but they should make the world feel physically connected.

Future-route blocking should be believable:
- collapsed bridge
- rockslide
- flood
- environmental hazard
- damaged lift
- Team Tether blockade
- sealed ancient gate

Avoid menu-style "Biome Locked" messaging.

---

# 2. MEADOWS PROGRESSION PHILOSOPHY

Blend the useful progression energy of:

### Pokémon
- routes and trainer battles
- blocked paths
- keys/permissions
- regional story beats
- meaningful prerequisites before the gym

### Palworld
- open visible creature ecology
- dangerous pockets
- world landmarks
- optional wandering
- bases/camps

### Valheim
- preparation matters
- materials define progression bands
- caves/nests/ruins give reasons to explore
- grinding has a purpose
- boss is the culmination of regional preparation

But preserve Tetherbound's own pillars:
- trainer never fights
- Creatures fight
- only five Creatures total
- survival supports adventure
- no mandatory starvation
- no Creature labor automation
- team decisions matter

The core loop should become:

**Explore → fight/catch → improve five → gather → unlock route → face harder challenge → repeat.**

---

# 3. MEADOWS MAIN PROGRESSION — 4 TO 7 HOURS

## BAND 0 — HOMEBOUND
**~20–40 minutes**

Area:
- Grandpa's farmhouse
- yard
- starter clearing
- village edge

Required sequence:
1. Wake upstairs.
2. Trying to leave forces Grandpa interaction if needed.
3. Grandpa gives opening items/context.
4. Choose starter.
5. Name starter.
6. Learn interaction.
7. First wild fight/catch.
8. Reach village.
9. Learn harvesting/camp basics.

Grandpa establishes:
- Team Tether is active again
- they occupy the Meadows Hall/stronghold
- routes through the region are being controlled
- walking straight there unprepared is a bad idea
- the player needs to build a team first

Do not dump the entire plot in one speech.

---

## BAND 1 — LOWER MEADOWS
**~1–1.5 hours cumulative**

Areas:
- village
- lower grasslands
- farm paths
- oak grove
- starter stream
- old south bridge

Purpose:
Teach normal Tetherbound progression through trainer fights, catches, gathering, and preparation.

### Trainer circuit
Use roughly three named local trainers.

Possible existing village NPCs can fill these roles if their existing characterization fits.

Examples:

**Mira — Meadow Keeper**
- introductory trainer battle
- reward: XP + useful early item/TM/recipe

**Oskar — Bridgehand**
- moderate trainer battle
- controls or possesses the old bridge mechanism
- reward: **South Bridge Key**

**Tam — Field Scout**
- battle emphasizing switching/type awareness
- reward: TM, Orb-related item, or map hint

### Gate 1 — South Bridge

The deeper Meadows is visible but separated by an old bridge.

The player may reach it early.

It has a physical key/mechanism, not a UI level lock.

Defeating the required trainer earns access.

Recommended natural team level by crossing: roughly **5–8** (tunable, not a hard level requirement).

---

## BAND 2 — STONE & ROOT
**~2–3 hours cumulative**

This is the first Valheim-like progression tier.

New areas:
- Old Quarry
- Burrow Warrens
- ridge trails
- deeper oak forest
- abandoned ranger camp

### New tier material: ROOTSTONE

Working name; can be renamed later.

Found in:
- quarry deposits
- burrow chambers
- old foundations

Rootstone should upgrade existing systems rather than create ten new systems.

Possible uses:
- improved Orb tier
- workbench upgrade
- better gathering tool
- saddle component
- useful TM unlock component
- modest camp/storage improvement

### Required dungeon: BURROW WARRENS

Compact cave/nest dungeon:
- aggressive Ground Creatures
- Rootstone deposits
- navigation through chambers
- stronger guardian fight
- rare side branch/loot

Guardian can be a strong normal species; do not invent another legendary.

Reward:
- Rootstone cache
- meaningful upgrade recipes
- evidence Team Tether has been moving equipment/material through the area

Optional rewards:
- TM
- rare trait spawn
- evolution item lead

---

## BAND 3 — THE RIVER LOCK
**~3–4 hours cumulative**

A substantial river divides the deeper Meadows.

This should become a real biome landmark and improve world depth.

### Main gate: OLD MILL CROSSING

Team Tether controls or has disabled the crossing.

The bridge keeper / ranger / researcher who knows the mechanism has been captured.

The player learns:
- the captive knows how to restore the upper crossing
- Team Tether operates a smaller relay compound nearby
- the final stronghold is still farther beyond

### Mini-stronghold: TETHER RELAY STATION

This is the first mini-gym / Team Tether dungeon.

Content:
- 2–3 Team Tether trainer battles
- partially industrialized natural site
- compact traversal/environment challenge
- relay captain battle

After victory:
- free captive NPC
- disable local tether/control equipment
- rescue scene
- captive restores or provides the **Upper Crossing Key / Mill Bridge Gear**
- crossing opens

Rewards:
- significant XP
- useful TM
- higher-tier recipe
- story information

This is the moment Team Tether stops being something Grandpa described and becomes a threat the player has personally confronted.

---

## BAND 4 — UPPER MEADOWS / IRONWOOD
**~4–5.5 hours cumulative**

Working tier resource: **Ironwood**.

It does not need to literally be iron. It represents the second preparation tier.

New areas:
- Upper Meadows
- old-growth forest
- wind ridge
- high pasture
- ruined watchtower
- Team Tether patrol camps
- trainer road

Ironwood supports:
- stronger crafting/preparation
- riding equipment
- better utility
- final-stronghold preparation

Keep the economy small and readable.

### Riding unlock

Riding should become available by Band 3 or early Band 4.

Use **Meadowhart** as the normal rideable Meadows Creature.

Require:
- compatible Creature
- generic Riding Saddle
- Rootstone/Ironwood components

Riding should dramatically improve revisiting known areas.

### Three Regional Captains

To open the final stronghold route, defeat three Team Tether regional captains.

Example structure:

**Field Captain**
- Ground-focused team
- reward: **Field Sigil**

**Ridge Captain**
- Air-focused team
- reward: **Ridge Sigil**

**Riverwatch Captain**
- Water/balanced team
- reward: **River Sigil**

The three physical Sigils open the old Hall/stronghold approach.

This gives trainer battles direct progression meaning.

Natural team expectation entering this band: roughly **10–16**, tunable and never player-scaled.

---

# 4. ONLY ONE MEADOWS EVOLUTION LINE

Current Meadows canon:

## Mudsnout → Tuskroot

No other normal Meadows line evolves.

Use it to teach the limited evolution system.

### Mudsnout
- young Ground pig
- sturdy
- rooting
- useful early/mid game

### Tuskroot
- larger armored Ground boar
- strong charge
- stone plating
- more defensive/powerful

Recommended evolution shape:
- level requirement
- bond requirement
- one Rootstone/Heartstone-type evolution condition or item

Example target:
- around level 15
- high bond
- special Heartstone from Burrow Warrens / deep optional challenge

Exact numbers and item name are tunable.

Evolution should feel earned, not automatic.

---

# 5. THE FIVE-CREATURE LIMIT MUST MATTER BEFORE THE WARDEN

The Meadows should deliberately create more desirable options than five slots.

A player may want:
- Ground tank
- Water counter
- Air offense
- rideable Meadowhart
- rare trait Creature
- Mudsnout/Tuskroot line
- favorite early catch

By the time the legendary offers to join, the player's team should contain real history.

The release ceremony only works emotionally if the player already cares about all five.

Do not let the first biome avoid the central "choose your five" tension.

---

# 6. OPTIONAL CONTENT

Create around **6–10 meaningful optional activities**, not 40 shallow quests.

Good candidates:

### Lost Creature
Track and recover a villager's missing bonded Creature.

### Broken Cart
Gather materials to repair a bridgehand's cart.

### Night Watch
Investigate nighttime activity and introduce Duskhush.

### The Old Champion
Optional difficult retired-trainer battle; can reveal history with Grandpa.

### Deep Warren
Optional harder branch of Burrow Warrens; good place for evolution item / rare trait spawn.

### River Nest
Aggressive Water/Air creatures block a fishing location.

### Team Tether Patrols
Optional trainer fights with XP, consumables, and small lore clues.

### Meadowhart Herd
Discovery activity that points toward the Riding Saddle progression.

---

# 7. FULL MAIN STORY BEAT SHEET

## ACT I — GRANDPA'S DOOR
1. Wake.
2. Grandpa prevents accidental departure.
3. Starter choice.
4. First encounter/catch.
5. Village introduction.
6. Learn Team Tether controls deeper roads.

Question: **Can I actually do this?**

## ACT II — EARN THE ROAD
7. Fight local trainers.
8. Build first real team.
9. Gather/camp.
10. Earn South Bridge Key.
11. Cross deeper into Meadows.

Question: **Can my team handle the wild?**

## ACT III — BENEATH THE MEADOWS
12. Reach Old Quarry.
13. Discover Rootstone.
14. Clear Burrow Warrens.
15. Upgrade tools/orbs/preparation.
16. Discover evidence of Team Tether activity.

Question: **What are they doing here?**

## ACT IV — THE CAPTIVE
17. River blocks progression.
18. Learn bridge controls were seized.
19. Find Tether Relay Station.
20. Beat Team Tether trainers.
21. Beat relay captain.
22. Free captive NPC.
23. Restore Mill Crossing.

Question: **Why is Team Tether controlling the region?**

## ACT V — UPPER MEADOWS
24. Cross river.
25. Unlock riding.
26. Explore upper region.
27. Gather Ironwood-tier materials.
28. Defeat three regional captains.
29. Earn three Sigils.
30. Open Meadows Hall approach.

Question: **Is my team ready for the Warden?**

## ACT VI — MEADOWS STRONGHOLD
31. Enter stronghold.
32. Trainer gauntlet.
33. Environmental/story reveal.
34. Warden dialogue.
35. Warden battle.
36. Disable tether mechanism.
37. Free Ground legendary.
38. Legendary offers to join.
39. If five are owned, run full release ceremony.
40. Meadows world state changes.

Answer: **Yes. This is my team.**

---

# 8. FINAL STRONGHOLD STRUCTURE

Target first-clear time: **30–60 minutes**.

### Outer Works
- patrol trainer
- visible Team Tether industrial intrusion

### Courtyard / Hall Approach
- trainer fight
- environmental storytelling

### Tether Chamber Approach
- elite trainer
- recovery opportunity

### Warden Arena
- dialogue
- multi-Creature boss trainer battle

### Legendary Chamber
- tether mechanism
- freeing sequence
- voluntary join
- release ceremony if needed

Do not turn this into a giant puzzle dungeon unless separately decided.

---

# 9. WORLD-STATE CHANGE AFTER WINNING

The Meadows must visibly respond after the Warden.

Examples:
- Team Tether barriers deactivate/remove
- patrol density drops
- rescued NPC returns to settlement
- villagers acknowledge victory
- stronghold effects change
- legendary is no longer tethered
- one or more outward-biome routes receive new dialogue/world hints

Do not leave the region visually identical.

---

# 10. PROGRESSION ECONOMY

Keep the Meadows material economy simple.

Baseline:
- Wood
- Stone
- Fiber
- Berries

Progression:
- Rootstone
- Ironwood (working name)

Special:
- Mudsnout evolution item
- bridge keys / Sigils
- TMs
- Orb materials

Every material should have an understandable reason to collect it.

---

# 11. WHAT "GRINDING" SHOULD MEAN

Good grind:
- level the five
- increase bond
- seek better traits/appraisal
- catch team alternatives
- find TMs
- gather Rootstone/Ironwood
- clear nests/warrens
- fight optional trainers/patrols
- improve Orb tier
- craft saddle
- prepare food buffs
- evolve Mudsnout

Bad grind:
- walk in circles killing identical weak enemies only to inflate a number

The intended feeling is:

> **I know a harder challenge is ahead, so I am deliberately improving my five.**

---

# 12. TRAINER BATTLE DENSITY

Approximate first-biome target:

- 3 local Lower Meadows trainers
- 2–3 Team Tether trainers in relay station
- 3 regional captains
- 2–4 final stronghold trainers
- 2–4 optional trainers/patrols

Total: roughly **12–17 trainer battles**.

Spread them across meaningful locations instead of creating one long trainer tunnel.

---

# 13. WILD SPECIES BY AREA

Use ecology to make deeper regions change the team-building options.

### Lower fields
- Bramblebun
- Mudsnout
- Pipwing

### Grove
- Trailpup
- Duskhush at night
- Burrowback

### Quarry / Warrens
- Burrowback
- Mudsnout
- rare Tuskroot/strong Ground spawns as appropriate

### River
- Paddlenewt
- Mosshell
- Brooktail
- Reedwing

### Upper ridge
- Galecrest
- Meadowhart
- stronger Trailpup

No random battle screens.

---

# 14. HOME MUST REMAIN RELEVANT

Reasons to return:
- Grandpa dialogue evolves
- Creature beds/recovery
- storage/crafting
- villagers update information
- rescued NPC returns
- story check-ins
- optional side content

Grandpa's home should remain emotionally and mechanically relevant.

---

# 15. REQUIRED PROGRESSION SYSTEM

The opening can stay specialized, but a multi-hour Meadows arc needs reusable progression state.

Implement the smallest reusable system that supports:
- objective flags
- completion flags
- trainer defeated state
- keys/tokens
- bridge unlocked state
- dungeon/relay cleared state
- captive rescued state
- Sigils 0/3
- stronghold unlocked
- Warden defeated
- post-Warden world state

Do not build a giant MMO quest engine.

Prefer data-driven objective definitions where practical.

---

# 16. UI

Use one concise tracked objective.

Examples:
- **Earn access to the South Bridge.**
- **Find the missing bridge keeper.**
- **Break Team Tether's relay control.**
- **Defeat the Upper Meadows captains. 2/3**

Map:
- reveals explored areas/landmarks
- does not reveal everything automatically

Quest log:
- Main Story
- Local Requests

Keep it simple.

---

# 17. IMPLEMENTATION ORDER

## P0 — immediate owner fixes
1. mouse capture/camera
2. forced Grandpa door sequence
3. world perimeter + failsafe
4. seven outward spokes
5. Burrowback palette change
6. bird palette/silhouette separation

## P1 — progression framework
7. objective/flag state
8. physical key/token gate
9. trainer completion rewards
10. basic tracked objective UI

## P2 — Lower Meadows
11. trainer circuit
12. South Bridge gate

## P3 — Rootstone
13. quarry
14. Burrow Warrens
15. first material tier

## P4 — Relay rescue
16. river
17. mini-stronghold
18. captive rescue
19. bridge restoration

## P5 — Upper Meadows
20. Ironwood tier
21. riding
22. three captains
23. three Sigils

## P6 — Final stronghold
24. stronghold route/interior
25. Warden
26. legendary release
27. five-Creature release ceremony
28. post-Warden state change

## P7 — pacing pass
29. XP tuning
30. trainer difficulty
31. material costs
32. travel time
33. spawn density
34. remove dead walking

---

# 18. ACCEPTANCE GATE

The Meadows is not complete until a fresh player can:

- wake in Grandpa's house
- be unable to accidentally skip Grandpa
- use mouse camera correctly on PC
- never fall off an exposed game-world edge
- see believable hints of seven future regions
- choose/name starter
- catch wild Creatures
- form a meaningful five
- fight trainers to progress
- earn a bridge key
- cross into deeper territory
- clear a cave/warren
- unlock a material tier
- confront Team Tether in a mini-stronghold
- rescue someone
- restore a major crossing
- unlock riding
- prepare through an upper progression tier
- defeat three captains
- open the final stronghold
- defeat the Warden
- free the legendary
- make a real five-Creature decision if the roster is full
- see the Meadows change afterward

The real owner-facing exit criterion is:

> **"I had a reason to keep playing for several hours before the first Warden."**

---

# 19. NON-GOALS

Do not add:
- human combat weapons
- shields
- mandatory hunger/thirst
- Creature base labor
- unlimited Creature storage
- procedural world seeds
- random encounter screens
- all seven future biomes
- giant generic quest engine
- MMO dialogue trees
- dozens of crafting resources
- arbitrary level-lock UI

---

# FINAL PRINCIPLE

## The Meadows is not the tutorial before the game.

## **The Meadows is the first game.**

It must express the full Tetherbound loop in miniature:

**explore → survive → catch → choose → bond → train → prepare → overcome → free**

The first Warden should be the culmination of hours of becoming capable, not the first meaningful destination on the map.

---

# 20. PRODUCTION CONSTRAINT — NO MORE CREATURE RERENDERS FOR MEADOWS

This is now a hard production constraint.

## Creature art rule

**Do not require new creature meshes or new Meshy generations to complete the Meadows.**

The existing Meadows creature meshes are the meshes to use.

Any differentiation work must be achieved through:

- material recoloring
- palette separation
- texture edits
- roughness/value changes
- modest scale variation
- animation/personality
- VFX
- habitat placement
- behavior
- combat role
- spawn context

Do not reopen creature concept design because a silhouette is imperfect.

The owner is not spending more generation credits on Meadows creatures.

### Consequence for Burrowback vs Terrapup

Since geometry is fixed, separate them aggressively through color/material.

Burrowback should be recolored toward:

- charcoal black
- cool gray
- pale gray face stripe
- slate stone
- restrained rust/brown accent

Terrapup keeps its established warm starter palette.

The separation must be obvious even if geometry remains similar.

### Consequence for bird roster

Do not regenerate bird geometry.

Differentiate through strong palettes:

- Pipwing: ochre/gold + cream + charcoal
- Duskhush: slate/lavender-gray + muted cream + amber eyes
- Galecrest: rust/chestnut + charcoal + pale sand
- Reedwing: deep teal + cream + copper/tan + orange feet/bill
- Air starter: retain existing established palette

Use stronger color separation than would normally be necessary because mesh silhouettes may overlap more than ideal.

---

# 21. HUMAN NPC PRODUCTION STRATEGY — REUSE EXISTING RIGS

The Meadows story needs more NPCs, but each named NPC does **not** need a unique Meshy model.

Existing human archetypes:

1. Main character
2. Grandpa
3. Meadows Warden

Treat these as reusable base bodies.

## Main-character base can become

- young villagers
- scouts
- field trainers
- bridge workers
- travelers
- junior Team Tether personnel if the outfit can be pushed far enough

Differentiate through:

- hair color
- shirt/jacket color
- pants color
- boot color
- backpack on/off
- belt tint
- accessory visibility
- simple hats/props where possible
- body scale within reasonable bounds

Do not recolor everything with one global tint if it destroys material separation.

Use per-material or per-region variation where possible.

## Grandpa base can become

- older villagers
- retired trainers
- craftsmen
- bridge keeper
- quarry foreman
- ranger elder

Differentiate through:

- hair/beard tint
- beard visibility if separable
- coat palette
- scarf/hat/accessories
- walking stick/satchel
- modest scale/posture changes if safe

## Warden base can become

- Team Tether officers
- regional captains
- elite trainers
- relay commander

Differentiate through:

- coat palette
- fur/shoulder treatment
- mask color
- insignia colors
- hair tint
- cape visibility
- rank accents
- accessory loadout

Do not make every Team Tether NPC look literally identical to the Warden. If geometry is reused, rank and color language must do heavy lifting.

---

# 22. OPTIONAL ONE OR TWO NEW HUMAN GENERATIONS

The owner may be able to afford **one or two** additional human generations.

These are optional, not blockers.

If credits are available, use them only for reusable archetypes.

## Priority 1 — Generic adult civilian/trainer base

Create one neutral adult NPC, roughly age 30–50, with:

- simple Meadows clothing
- no hero silhouette
- no Team Tether identity
- no legendary/story-specific accessories
- clean humanoid rig
- modular colorable materials

This single model can support:

- villagers
- trainers
- bridge keeper
- ranger
- rescued NPC
- shop/crafting NPCs
- future biome civilians

This is the highest-value extra generation.

## Priority 2 — Team Tether grunt base

Only if a second generation is affordable.

Design:

- standardized Team Tether field uniform
- simpler than the Warden
- modular
- colorable
- no fur mantle required
- clear faction silhouette
- reusable in all biomes

This supports:

- patrols
- relay station trainers
- stronghold trainers
- later-biome Team Tether personnel

If only one extra generation is possible, choose the civilian/trainer base first unless the existing Warden rig proves unusable for faction variants.

---

# 23. TEAM TETHER — CORE STORY CANON

This is now the preferred macro-story direction.

## The original world

The eight biomes were not meant to exist as isolated islands/regions.

They were once part of one connected ecosystem.

The eight legendary Creatures are living conduits/anchors for different natural forces.

Each legendary is deeply tied to one biome's energy.

Examples:

- Ground
- Water
- Air
- Fire
- Ice
- Electric
- Psychic
- Dark

Exact final type list remains governed by global game canon.

## What Team Tether discovered

Team Tether learned how to bind the legendary Creatures into massive Tether systems.

By siphoning their energy, Team Tether can maintain unnatural divisions between regions.

These divisions are not merely political borders.

They are physical/magical separations of the world itself.

Examples:

- impossible ravines
- widened rivers
- unnatural mountain walls
- permanent storms
- frozen passes
- severed plateaus
- broken land bridges
- distorted terrain seams

These are called:

## **Tether Rifts**

Working canon term; rename later only if a stronger term is chosen.

---

# 24. WHY TEAM TETHER KEEPS THE WORLD DIVIDED

A divided world is easier to control.

When each biome is physically isolated:

- settlements cannot trade freely
- rare resources cannot move freely
- specialized Creatures cannot migrate naturally
- knowledge is isolated
- travel becomes dependent on Team Tether
- transportation routes can be monopolized
- shortages can be managed politically
- each Warden becomes indispensable

Team Tether's real power is not merely having strong trainers.

Their power comes from controlling the movement of:

- resources
- creatures
- people
- information
- trade

between isolated regions.

## Their public justification

Team Tether should not see itself as cartoonishly evil.

Their official doctrine is:

> The connected world was unstable.

They claim that before separation:

- dangerous Creatures migrated unpredictably
- regions competed over resources
- disasters spread between ecosystems
- conflicts escalated
- natural energies interfered with one another

According to Team Tether:

> The barriers created peace.

Some of this may even be historically true.

That creates a meaningful ideological conflict.

---

# 25. TEAM TETHER'S REAL FAILURE

Even if separation solved some old instability, Team Tether turned a temporary solution into permanent centralized control.

They now benefit from:

- scarcity
- dependency
- restricted travel
- controlled trade
- regional isolation

Their system prevents communities from becoming self-sufficient together.

They no longer maintain the barriers only for safety.

They maintain them because the barriers preserve Team Tether's authority.

This distinction matters.

The Wardens can be sincere while the system is still oppressive.

---

# 26. THE PLAYER'S THEMATIC ROLE

The game's central conflict becomes:

## Team Tether believes control creates stability.

## The player proves cooperation creates stability.

This fits the rest of Tetherbound.

The player does not dominate dozens of disposable creatures.

They build trust with five.

They do not reunite the world by conquering it alone.

They reunite it through:

- bonds
- cooperation
- freeing legendaries
- helping settlements
- connecting ecosystems

The five-Creature limit supports the theme:

> Strength comes from deep relationships, not ownership of everything.

---

# 27. WHAT HAPPENS WHEN A LEGENDARY IS FREED

This should become one of Tetherbound's signature moments.

When a Warden is defeated and the biome's legendary is freed:

1. the legendary stops feeding energy into that region's Tether system
2. the corresponding Tether Rift destabilizes
3. the artificial separation begins to collapse
4. the neighboring biome physically reconnects to the existing world

The player does not unlock a level on a menu.

## The world physically becomes larger.

Possible presentation:

- distant landmass moves closer
- ravine contracts
- stone rises from below
- roots bridge a gap
- mountains settle
- a storm wall dissipates
- a frozen wall fractures
- rivers change course
- ancient road sections reconnect

Use whichever presentation fits each biome.

---

# 28. MEADOWS ENDING — FIRST WORLD RECONNECTION

The Meadows Warden ending should demonstrate this system for the first time.

Before the final battle, the player discovers:

> The Meadows legendary is being used to maintain one of the major Tether Rifts.

The Warden should warn the player.

Not:

> "You cannot stop me."

More like:

> "You don't understand what these barriers are holding apart."

The Warden genuinely believes freeing the legendary is reckless.

After the Warden loses:

1. player reaches legendary chamber
2. legendary is freed
3. legendary voluntarily offers to join
4. five-Creature decision occurs if necessary
5. Tether machinery fails
6. huge exterior world event begins
7. the next biome is visibly pulled/reconnected against the Meadows

This is the reward for finishing the biome.

---

# 29. THE SEVEN MEADOWS SPOKES ARE TETHER RIFTS

The seven outward routes described earlier now have a stronger explanation.

They are remnants of the old connected roads between regions.

At the start of the game, each ends at a Tether Rift.

The player can see:

- broken roads
- severed bridges
- distant land
- old signs
- ruined gates
- abandoned trade infrastructure

This proves the regions used to connect.

Team Tether did not build seven random dead-end roads.

They severed existing connections.

## Gameplay boundary rule

The physical perimeter still needs visible fencing/terrain/collision so the player cannot fall off the map.

But those boundaries should now support the fiction of Tether Rifts.

Do not make the edge look like a floating island.

---

# 30. PROGRESSIVE WORLD REASSEMBLY

Every time another legendary is freed:

- another region physically joins the existing landmass
- old travel routes reopen
- trade becomes possible
- new resources become available
- new Creatures can migrate
- older regions change subtly

By the late game, the world should feel radically larger and more connected than it did at the beginning.

This gives the player a strong visual sense of progress.

The map itself becomes the long-term progression screen.

---

# 31. RECONNECTION MUST HAVE CONSEQUENCES

Team Tether must not be wrong about everything.

When regions reconnect, there should be benefits **and** consequences.

Benefits:
- free travel
- trade
- resource exchange
- migration
- new quests
- relationships between settlements

Risks:
- stronger wild Creatures migrate
- predators enter new areas
- invasive species/ecology issues
- resource competition
- environmental instability
- new conflicts

This keeps the story morally interesting.

The player's job becomes more than breaking barriers.

They must help prove a connected world can function.

---

# 32. MEADOWS STORY REVEAL PACING

Do not tell the player the full Team Tether plan in Grandpa's opening dialogue.

Reveal it gradually.

## Early Meadows

Villagers know:
- Team Tether controls travel
- trade is restricted
- some old roads have become unusable
- crossings are controlled

They do not know the full legendary mechanism.

## Rootstone / Quarry

Player discovers:
- unusual conduits
- Team Tether excavation/activity
- energy-routing hardware
- evidence materials are being moved toward the stronghold

## Relay Station

Player learns:
- energy is being routed through regional relays
- bridge/travel restrictions are intentional
- someone investigating the border has been captured

## Rescued NPC

The captive has evidence that:
- the Tether Rifts are artificial
- regional separation is being actively maintained
- power flows toward the Warden's stronghold

They may still not know the legendary is the source.

## Upper Meadows

Player sees:
- major conduits/pylons
- old roads ending at unnatural world seams
- evidence that the world used to connect

## Stronghold

Final reveal:
- legendary is the living power source
- Team Tether is siphoning it
- the Warden knows what freeing it will do

Then the player makes the choice.

---

# 33. REVISED WARDEN CHARACTER MOTIVATION

The Meadows Warden should sincerely believe:

- separation prevents chaos
- controlled trade prevents regional conflict
- dangerous migration must be limited
- ordinary people do not understand the risks
- Team Tether bears the burden of maintaining order

The Warden can still abuse power.

But they are not a moustache-twirling villain.

Their worldview should be:

> Freedom without control becomes disorder.

The player challenges that worldview through action.

---

# 34. REVISED MEADOWS MAIN STORY

Update the previous beat sheet with the macro-story reveals.

## ACT I — GRANDPA'S DOOR

Player learns:
- Team Tether controls regional travel
- the Meadows stronghold matters
- Grandpa distrusts them

No full Tether Rift reveal yet.

## ACT II — EARN THE ROAD

Trainer progression proves the player is becoming capable.

The controlled bridge demonstrates that local movement is restricted.

## ACT III — BENEATH THE MEADOWS

Rootstone quarry and Burrow Warrens introduce the first physical evidence that Team Tether is routing energy/resources beneath the region.

## ACT IV — THE CAPTIVE

Relay Station reveals Team Tether's travel-control infrastructure.

Rescued NPC suggests the region's isolation is artificial.

## ACT V — UPPER MEADOWS

Player reaches the outer Tether Rift sites.

They can visibly see another biome beyond an unnatural separation.

The three captains protect the infrastructure feeding the main system.

## ACT VI — STRONGHOLD

Player discovers the Meadows legendary is the source.

Warden explains the doctrine.

Player defeats Warden.

Legendary is freed.

The first Tether Rift collapses.

The next biome physically reconnects.

This should be the final cinematic/gameplay reward of the Meadows chapter.

---

# 35. REVISED NPC CAST — DESIGNED AROUND REUSED MODELS

The following story can be built without unique NPC models.

Use material variants and existing rigs.

Suggested Meadows cast:

## Grandpa
Existing Grandpa model.
Unique.

## Mira — local trainer / Meadow Keeper
Use main-character or generic civilian base.
Distinct palette.

## Oskar — bridgehand
Use Grandpa base if older, or generic civilian base.
Workwear palette.

## Tam — field scout
Use main-character base.
Different hair/jacket palette.

## Quarry Foreman
Use Grandpa/generic civilian base.
Dark stone/workwear colors.

## Rescued Ranger / Researcher
Use generic civilian base if generated; otherwise main-character base.
Distinct teal/cream or tan palette.

## Relay Captain
Use Warden base.
Reduced prestige:
- darker simpler coat
- no full Warden colors
- different hair/mask
- simpler rank accents

## Field Captain
Warden/grunt base variant.

## Ridge Captain
Warden/grunt base variant.

## Riverwatch Captain
Warden/grunt base variant.

## Stronghold trainers
Reuse Team Tether base variants with:
- different trim
- different masks
- different hair
- different insignia rank colors

The player should read faction and role instantly, not necessarily unique face geometry.

---

# 36. TEAM TETHER COLOR/RANK SYSTEM FOR REUSED NPCS

Because geometry may repeat, establish rank colors.

Example:

### Grunt
- charcoal
- muted forest green
- minimal gold

### Relay/Field Officer
- deeper green
- bronze trim

### Captain
- dark green
- stronger gold/brass
- colored regional accent

### Warden
- richest materials
- cream fur mantle
- strongest gold
- signature mask/coat treatment

This lets the same base model communicate hierarchy.

---

# 37. IMPLEMENTATION DIRECTIVE FOR CLAUDE

This document should be executable under the real art budget.

Claude must **not** block Meadows implementation waiting for unique 3D assets for every NPC or creature.

Use:

- existing creature meshes
- material variants
- existing human rigs
- clothing/hair/material variants
- simple attachable props
- existing animations
- modest scale changes

Only use a new Meshy human generation if the owner supplies one.

Do not invent a dependency on new paid generations.

---

# 38. UPDATED ONE-SHOT BUILD ORDER

If executing this whole Meadows expansion as one major build plan, work in this order:

## Phase A — fix the current play experience
1. Fix PC mouse capture lifecycle.
2. Force Grandpa interaction at house exit.
3. Build visible/collidable world perimeter.
4. Establish seven Tether Rift spokes.
5. Recolor Burrowback.
6. Recolor/separate all bird species.

## Phase B — establish reusable content infrastructure
7. Build NPC palette/material variant system.
8. Create Team Tether rank palette variants.
9. Build smallest reusable objective/progression-state system.
10. Build physical key/Sigil gate support.
11. Build objective tracker UI.

## Phase C — Lower Meadows
12. Implement local trainer NPC variants.
13. Implement local trainer fights.
14. South Bridge gate/key.
15. Lower-area progression rewards.

## Phase D — Rootstone tier
16. Old Quarry.
17. Burrow Warrens.
18. Rootstone resource.
19. meaningful first upgrade tier.
20. Mudsnout evolution setup/path.

## Phase E — River / Relay story
21. Major river.
22. Old Mill Crossing.
23. Tether Relay Station.
24. Team Tether officer variants.
25. Relay trainer battles.
26. Relay captain.
27. Captive NPC.
28. rescue story beat.
29. crossing restoration.
30. first strong evidence of artificial regional separation.

## Phase F — Upper Meadows
31. Ironwood tier.
32. Meadowhart riding progression.
33. outward Tether Rift views.
34. three regional captains.
35. three Sigils.
36. reveal old roads once connected to other regions.

## Phase G — Stronghold / macro reveal
37. stronghold gameplay route.
38. stronghold trainer gauntlet.
39. Meadows Warden.
40. reveal legendary is powering the Rift.
41. legendary release.
42. five-Creature release ceremony if full.
43. fail Tether machinery.
44. trigger first biome reconnection world event.
45. next biome physically joins Meadows.
46. update Meadows post-Warden world state.

## Phase H — pacing/QA
47. tune 4–7 hour target.
48. tune XP.
49. tune trainer levels.
50. tune resource costs.
51. tune travel time.
52. tune encounter density.
53. confirm mouse/Grandpa/world-edge bugs are actually gone in real play.
54. confirm no implementation step assumes new creature Meshy credits.

---

# 39. UPDATED ACCEPTANCE GATE

The Meadows chapter is complete only when:

- PC mouse-look feels normal.
- Grandpa cannot be skipped.
- player cannot fall off the world.
- seven future-world connections are visually established.
- creatures are differentiated using existing meshes/materials.
- NPC cast works primarily through reused rigs/material variants.
- player has meaningful trainer progression.
- player unlocks deeper areas through physical/story gates.
- player completes a cave/warren progression tier.
- player attacks a Team Tether mini-stronghold.
- player rescues an NPC.
- player learns the biome separation may be artificial.
- player unlocks riding.
- player defeats three regional captains.
- player enters the Warden stronghold after several hours of preparation.
- player learns the legendary is powering the Meadows Tether Rift.
- player defeats the Warden.
- player frees the legendary.
- the next biome physically reconnects to the Meadows.
- Meadows visibly changes afterward.

The game should end the first biome with the player thinking:

> **"I didn't unlock the next level. I put part of the world back together."**

That is the signature payoff.

