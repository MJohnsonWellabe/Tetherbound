# Tetherbound — the Game Bible

**What this is.** The single description of what Tetherbound is: the experience
it promises, the four chapters, the systems, the canon, and the rules that stay
true. It replaces `GAME_VISION.md`, `CREATURE_DESIGN.md`, `WORLD_AND_CONTENT.md`,
`GAMEPLAY_SYSTEMS.md`'s design half, `VISUAL_BIBLE.md`'s target half, the
`docs/specs/` design set, the `docs/biomes/*/BUILD_*` briefs, 33 owner directives
and 125 decision records — all now under `archive/`.

**What it is not.** Not a status report (that is `STATE.md`), not a standard to
measure against (that is `ACCEPTANCE.md`), not a map of the code (that is
`TECHNICAL.md`).

---

# Part 1 — What the game is

## 1.1 The promise

Tetherbound is a third-person open-world creature-training adventure with
gathering, crafting, building, exploration, creature care and real-time creature
combat. Godot 4.7, Windows-first, controller-first, 1–4 player co-op.

> **Build the strongest, most capable, most personally meaningful team of five
> creatures you can — and live with the choices that five total slots force you
> to make.**

Five creatures means five. No reserve box, no storage, no hidden sixth slot.
That rule is not a restriction sitting on top of the game; it is the game's
emotional center. The player should know their five by name, and remember where
they found each one, which fights it survived, which became the favourite,
which became the mount, which evolved, which had to be carried through a hard
stretch, and which they eventually chose to release.

The player is the trainer, explorer, builder, gatherer and caretaker. **The
human never fights.** Creatures fight creatures. When combat begins the player
directly pilots the active creature in real time — aims attacks, moves to avoid
danger, builds charged energy, switches creatures, and may physically aim and
throw an Orb during wild battles.

Survival and crafting exist to support the team journey, never as their own
game: gathering unlocks preparation, building makes a home and camps, creature
beds turn injury into real expedition pressure, food influences readiness
without becoming starvation punishment, day/night and weather change what the
world offers, better materials let the player push farther.

Everything feeds one question: **is my team of five strong, healthy, prepared
and versatile enough for what is ahead?**

## 1.2 The core loop

**Explore → encounter → fight/catch → choose → train → gather → care → prepare
→ overcome → push farther.**

A good stretch of play naturally produces several of these decisions: I see a
creature I might want. I see a stronger one I'm not sure I can beat. A trainer
ahead is a useful test. That deposit is worth leaving the trail for because I
know what it builds. One of mine is hurt badly enough that continuing costs
something. Night is coming and this clearing would make a good camp. I could go
home and improve something, or risk pushing on. My five have a weakness. I
found a sixth I genuinely want, so somebody may have to leave.

Two failure modes, equally bad: long stretches of merely holding forward, even
through attractive scenery; and constant combat with no breathing room. The
world needs scenic rest, discovery, anticipation and choice. An open field can
be quiet while still pulling the player forward through a visible herd, a
distant trainer, an outcrop, a side trail, a ridge, a pylon line, a weather
front or a landmark.

## 1.3 The rules that never bend

These override lower-level prompts and implementation convenience. They are
repeated in `AGENTS.md` / `CLAUDE.md` because an agent reads those first.

- Godot is locked. Windows / ROG Ally primary. Controller first.
- **Five creatures total.** No storage, no reserve box, no sixth slot.
- **The human never fights.** Creatures don't perform base jobs.
- Combat is **real-time and directly piloted**. No shields, no blocking, no
  held buttons.
- Catching happens during wild combat. Trainer-owned creatures cannot be caught.
- No hunting, no butchering.
- **Light satiety only**: slow drain, food restores and buffs, soft drawbacks
  when low, never starvation death.
- Slot/stack inventory, no carry weight. Multiple death satchels persist.
- **Creatures stand taller than the 1.80 m trainer.** Fix any relative-scale
  problem by growing the smaller side, never by shrinking the larger.
- **No new creature meshes without owner-supplied reference art.** Differentiate
  by material, texture, modest scale, animation, VFX, habitat, behaviour and
  encounter context. One nature family, one village family, one prop family.
  Meshy is reserved for Team Tether hero objects (pylons, relay apparatus, the
  tether machine).
- **Never spend a Meshy generation without owner reference art.** One carve-out
  exists — see §1.4.
- **Reuse the installed humanoid cast.** `docs/art/HUMANOID_ASSET_INVENTORY.md`
  is authoritative: six base families plus 22 generated village/trail NPCs, 28
  installed `.glb` bodies. A new humanoid mesh is exceptional and still needs
  owner reference art.
- The Warden is already rebuilt from the owner's board-16 sheet — inspect
  `assets/characters/warden/warden_lod0.glb` rather than trusting older notes
  about a "painted face."
- Oxblood/red is reserved for Team Tether.
- Anything new is multiplayer-native from its first implementation.
- **Do not silently invent a major gameplay or story decision.**

## 1.4 The two standing carve-outs

**Agent-generated reference art, one pilot subject.** For exactly one subject —
a creature or character the agent chooses and justifies from blind verdicts —
the "no new mesh" and "no Meshy without owner art" rules are lifted: the agent
generates three reference images, a code-blind judge picks the winner, and
Meshy runs from that image. One subject. A second needs a new owner
instruction. Everything else in the art rules is unchanged.

**The nine expansion creatures.** Nightburrow, Stormtrail, Sparkit, Cindercub,
Shadelet, the Bramblebun redesign, Riftfrill, Ashtusk and Frostclaw each have
owner-supplied reference art vendored under
`docs/art/reference/creature-expansion-2026-08-30/`. They are a named, scoped
exception, not a general licence.

---

# Part 2 — The four chapters

The game is four chapters. Each is a complete region with its own identity,
mechanic, story, stronghold and legendary. The Meadows ships first and is the
proof of the whole shape.

| # | Chapter | Identity | New verb | Climax |
|---|---|---|---|---|
| 1 | **The Meadows** | rolling pastoral open world, Ground-dominant | riding | Meadows Hall → the Warden → the Veridian Stag |
| 2 | **Cloudreach Cliffs** | sheer vertical highland, wind and sky | flying | Summit stronghold, a domed aviary |
| 3 | **The Stormwood** | deep forest under a permanent storm | the Surge + Stormglass Arches | the Dynamo |
| 4 | **Tidewake** (the Water Archipelago) | twelve islands and open sea | swimming, mounted swimming | behind the Veilfall |

Chapters connect through a **realm key** spent once at a realm gate, and a
**realm heart/relic** earned at each climax. A later chapter is visible from an
earlier one as a distant, non-enterable view before its key is spent.

## 2.1 Chapter 1 — The Meadows

### The shape of the chapter

A focused first clear targets **3–4 hours**, with longer runs for exploration,
catching, team experimentation, optional trainers, gathering and building. It is
the first complete chapter, not a tutorial before the game.

**Opening / home.** The player wakes in Grandpa's farmhouse. Grandpa is a former
trainer who can no longer make the journey. The opening cannot be accidentally
skipped. He gives the starter choice and establishes that Team Tether holds the
deeper routes and occupies Meadows Hall, and that walking there unprepared is
foolish. The player names the starter, learns interaction, fights their first
real creature fight, and physically catches a wild one. The opening must
establish quickly that catching is not the objective — the player is building a
team *for* something.

**First-session goal: become a trainer.** The village tournament is the first
proof of readiness. Before entering, the player learns the actual loop by doing
it: catch creatures for a real team, fight and gain levels, learn switching and
composition, gather materials, unlock recipes and build pieces, build a small
home, build creature beds and their own bed, watch a creature need recovery,
feed and rest the team, then win the tournament. This segment should feel like a
small complete game. If it isn't fun, nothing later compensates.

**Lower Meadows.** Broad readable grassland, farm paths, groves, water,
local trainers, ordinary habitats, resources, optional discoveries, and at
least one special encounter that tempts the player off the direct route. The
player builds confidence toward the South Bridge, which is a **world** gate
opened by trainer/story progression — never a "level required" message.

**Stone & Root — Old Quarry and Burrow Warrens.** Materially more demanding.
Rootstone appears. The player harvests meaningful deposits, meets stronger
Ground creatures, clears the required Warrens dungeon, faces a memorable
guardian, finds the Heartstone in the vault past it, sees the first hard
evidence of Team Tether, and has at least one optional harder branch worth
returning for.

**River / Relay.** A substantial river becomes an unmistakable regional
landmark and a real barrier. The Old Mill Crossing is unavailable because Team
Tether controls the situation and a key person is captive. The player moves
through a living river region, then reaches the Tether Relay — the first real
confrontation, escalating grunts → officer → Captain Vance. Victory frees the
captive, disables the machinery, restores the crossing, and makes the world
physically different.

**Upper Meadows.** High pasture, old-growth pockets, ridges, ruins, patrols,
Ironwood-tier resources, stronger populations, and the riding payoff through
Meadowhart and the saddle. Three regional captains form the final preparation
ladder; their Sigils physically open the Meadows Hall approach. The player
should be able to look at their team here and feel history.

**Stronghold approach.** Meadows Hall grows visually dominant. Team Tether
hardware, pylons, patrols and drained land intensify. Wild encounters get more
dangerous. One last real chance to prepare, rest, adjust the five, or take a
tempting optional challenge before committing.

**Meadows Hall → Warden → legendary.** A compact culmination, not a puzzle
dungeon: Outer Works → Courtyard / Hall Approach → Tether Chamber Approach →
Warden Arena → Legendary Chamber. Old stone visibly occupied and
industrialized; deeper spaces increasingly reveal the machinery is drawing
power from the captive legendary. The Warden tests the team the player spent the
chapter building. After victory the player disables the tether and frees the
Veridian Stag, which **volunteers**. If the player already owns five, the
chapter's core rule becomes unavoidable: a permanent release, presented with
ceremony and enough history to hurt. The final answer of the Meadows is
**"these are my five."** The region then visibly heals, Team Tether recedes,
rescued people return, and the world points at Cloudreach without entering it.

### What the Meadows looks like

One coherent biome with deliberate regional variation. The **macro geography is
authored** — roads, water, caves, bridges, settlements, strongholds, sightlines,
region entrances and landmarks are placed intentionally. Wilderness dressing and
populations may be rule-driven, but they serve the authored composition.

The world alternates between broad rolling grassland with long sightlines;
sparse tree lines and copses; lush pockets at selected ponds, groves, river
edges and protected areas; rocky quarry and warren terrain; the river and its
crossings; elevated pasture and old growth; and increasingly occupied/drained
land near Team Tether infrastructure.

The dense vegetation around the Pond is the **approved lush reference**.
Preserve that quality; do not extrapolate its density across the whole map.
Open areas must be authored rather than empty — interest comes from terrain
shape, distant silhouettes, creatures, trainers, resource formations, paths,
ruins, weather, camps, pylons and landmarks, not asset spam.

Each progression band is a real place with loops, reconnecting paths, overlooks
and optional pockets. The world must not read as a single corridor with content
placed beside it. The player should be able to answer, without the minimap:
where did I come from, where can I go, what region is this, what am I orienting
around, what looks optional, what looks like progress.

### Structure: the five bands

The Meadows is **one continuous scene**. "Regions" are Z-axis corridor bands.
Authoritative bounds and level bands live in `data/config/chapter_curve.json`.

| Band | z to | wild levels | trainer levels | team size in/out | Landmarks |
|---|---|---|---|---|---|
| band1_lower_meadows | 1360 | 2–6 | 2–7 | 3 / 8 | Grandpa's Village, The Pond, The Rise |
| band2_stone_and_root | 3180 | 6–8 | 9–14 | 8 / 10 | The Old Quarry, The Burrow Warrens |
| band3_the_river_lock | 4760 | 9–12 | 8–16 | 10 / 13 | The Tether Relay, The Long Water, The Stonewater Reach |
| band4_upper_meadows_ironwood | 7000 | 11–14 | 13–16 | 13 / 16 | The Ironwood Grove, The Highfield |
| band5_stronghold_approach | rest | 14–17 | 15–20 | 16 / 20 | The Ridgeline Watch, The Broken Tower, Meadows Hall |

Band 5 is **short on purpose**, and its road deliberately carries no added
trainer, cache or cluster — its findables sit off the road at places the band
already names.

**Named locations for visual review: 23.** 20 unique places in
`map_landmarks.json` (22 rows, with the Tether Relay and Old Mill Crossing
appearing in both arrays) plus three external named destinations — The Inn and
Practice Meadow, authored in `terrain_playground.json`, and Stronghold Approach,
in `debug_teleport_spots.json`.

**Grandpa's Village.** Centred (6, −22), radius 60 m. 19 villagers in
`village_npcs.json`; vendors are Mira (goods), Oskar (creatures), Bram (goods).
Mira, Oskar and Tam also carry trainer challenges. Every village road has a gate
and the boundary cannot be jumped. The village population was already cut on
owner complaint — **do not add more villagers.**

### The Meadows creature roster — 25 species

Source of truth is `data/creatures/species.json`. Heights are game-scale
decisions against the fixed 1.80 m trainer, divorced from reference-sheet
centimetres. `species.json` now holds 57 entries; the 32 Cloudreach/Stormwood/
Water species are catalogued separately and are not in Meadows tables.

**Starters (3).** Terrapup (Ground, 2.30 m, forgiving/tanky), Ripplet (Water,
2.15 m, balanced), Galewisp (Air, 1.90 m, offence/energy). All catch rate 0.30.
Starters get average individuality and no trait roll, so picking one stays a
known-quantity choice.

**Core wild roster (12).** Bramblebun (Ground 1.00), Mudsnout (Ground 0.95),
Trailpup (Ground 1.28), Burrowback (Ground 1.70), Meadowhart (Ground 2.05,
rideable mount), Paddlenewt (Water 1.15), Mosshell (Water 1.40), Brooktail
(Water 1.05), Reedwing (Water 1.50), Pipwing (Air 0.76, smallest), Duskhush
(Air 1.28, nocturnal), Galecrest (Air 2.10, aggressive raptor).

**Evolution (1 line, 2 branches).** Tuskroot (Ground 2.15) and Ashtusk
(Ground/Fire 2.15). Neither spawns wild.

**Legendary (1).** The **Veridian Stag** (Ground, 3.60 m — always the tallest
creature in the game, catch rate 0.02, rideable with no tack required because it
volunteers). Production history called it "Terracrown"; the art and the project
use "Veridian Stag."

**Aspect variants (4).** Rare environmentally-triggered recolour/VFX layers on an
existing base species — same lineage and mesh, typing and appearance change,
nothing else. Nightburrow (Burrowback → Ground/Dark, exceptional alpha),
Stormtrail (Trailpup → Ground/Electric, rare storm alpha), Riftfrill (Paddlenewt
→ Water/Psychic, rare non-alpha), Ashtusk (Tuskroot → Ground/Fire, mini-alpha
and the one variant that is also an evolution outcome).

**New Meshy species (4).** Wanderers, not native dominants — the Meadows stays
Ground-dominant and these foreshadow later regions at deliberately low rates.
Sparkit (Electric 0.85), Cindercub (Fire/Ground 1.40), Shadelet (Dark 1.60),
Frostclaw (Ice 2.00, constrained to the cold Meadows edge).

**Population philosophy.** Common (the base 12 plus starters) is the
overwhelming majority. Uncommon ≈ 5–10 % of eligible habitat spawns, rare ≈
1–3 %, exceptional/alpha well under 1 %. One active alpha per region at a time;
never several elemental alphas visible at once. Directional targets, not locked
balance values.

### Creature canon

**Evolution.** Mudsnout → **Tuskroot** (Heartstone) or **Ashtusk** (Sunstone) is
the only line. One gate: level 15, bond tier 3, holding a catalyst. Holding
neither refuses and names both stones; holding both refuses for ambiguity rather
than picking silently. The Heartstone is the Burrow Warrens vault prize past the
guardian; the Sunstone is a bare Band 5 ground pickup near the Sigil gate. **An
evolved form never spawns wild** — an evolution you can walk up to and catch
makes evolving pointless. An evolution is always strictly larger than its
source.

The player evolves deliberately from the Team tab. The world tells them it
exists in three ways: the Team tab names every unmet requirement with its
current value beside it; the progression feed pushes an "evolution eligible"
moment and a "catalyst found" moment; and Mira mentions in ordinary greeting
that a Mudsnout "isn't finished growing" once it qualifies.

**Scale.** Four decisions moved the band and the current state governs — do not
"fix" heights back toward an older number. Creatures are peers, not pets;
starters are boar-sized; the band widened from the bottom (0.60–2.60 m) by
shrinking only the small tier; and the standing owner correction is that almost
all creatures should stand taller than the character. A relative-scale complaint
is always fixed by raising the smaller side.

**Stats and individuality.** Wild creatures spawn inside a level band, not at a
fixed level. Every species carries a 2-entry `moves` list drawn from 48 moves;
moves map onto the two combat verbs (quick / charged) via a `power` multiplier —
flavour and naming on a two-verb system, **not** a four-slot move system. Every
instance carries three 0.0–1.0 individuality rolls worth a real ±12 % multiplier,
shown as 1–5 stars, never as the raw number. Every creature rolls a primary
trait from eight (Bold, Calm, Sturdy, Swift, Gentle, Stubborn, Curious,
Watchful) and a hidden secondary revealed at full bond. **Traits are flavour,
not balance** — no stat-bonus table exists; inventing one is a new owner
decision.

**Bond is an ordered ladder of five named tasks**, not a 0–100 meter. A creature
is always working toward exactly one nameable task ("38/50 wild creatures
defeated together"); finishing one advances the tier by exactly one, and a later
counter climbing first does not skip ahead.

| # | Task | Target |
|---|---|---|
| 1 | wild creatures defeated together | 50 |
| 2 | landmarks discovered together | 3 |
| 3 | metres travelled together | 4000 |
| 4 | nights rested together | 4 |
| 5 | meals fed together | 10 |

Only #1's target is settled canon in the owner's own words; 2–5 are tunable
judgment calls. Distance, landmarks and rest credit every party member present;
feeding is per-creature and manual. **Design goal: a full five-creature team
reaches all five milestones before leaving the Meadows.**

**Sourced creature art is a stand-in.** Every current creature mesh exists to
prove the systems around it — rigging, clip mapping, collider scaling, combat
animation — not to be the final look. The gap to the owner's bar is recorded
and left open, not argued away. Never let a stand-in set a design decision.

### Meadows content census

| Content | Count | Source |
|---|---|---|
| Species | 25 Meadows (57 total in file) | `data/creatures/species.json` |
| Moves / TMs | 48 / 14 | `data/moves/` |
| Items | 56 | `data/items/items.json` |
| Recipes | 16 (7 base + 5 rootstone + 4 ironwood) | `data/recipes/` |
| Build prefabs / buildables | 20 / 11 | `data/config/building_prefabs.json`, `data/items/buildables.json` |
| Traits | 8 | `data/traits/traits.json` |
| Village NPCs | 19 | `data/config/village_npcs.json` |
| Dialogue | 130 conversations / 339 lines | `data/dialogue/` |
| Objectives | 33 (27 main + 6 local) | `data/progression/objectives.json` |
| Field trainers | 29 (9/4/5/5/6 per band) | `data/config/bands/*/trainers.json` |
| Wild spawn entries | 321 (69/71/66/91/24) | `data/config/bands/*/spawns.json` |
| Harvest nodes | 198 (48/46/49/45/10) | `data/config/bands/*/harvest.json` |
| Authored pickups | 101 (41 Good / 23 Great / 9 Rare candy + 28 recovery) | `data/config/bands/*/pickups.json` |
| Landmarks / bands | 12 / 5 | `map_landmarks.json`, `chapter_curve.json` |
| Boss encounters | 1 (the Warden) | `stronghold_climax.gd` |
| Shiny colourways | 10 (cosmetic) | `data/creatures/shiny_colourways.json` |

Total authored spine: **11,518 m**.

## 2.2 Chapter 2 — Cloudreach Cliffs

**Core fantasy.** A dramatic vertical highland: sheer cliffs, massive elevation
change, broken sky roads, rope and stone bridges, cliff paths, lookout towers,
ruined waystations, ancient shrines, exposed ridgelines, bird perches,
wind-carved plateaus, dangerous drops, high-altitude settlements, big horizon
views, vertical shortcuts, hidden ledges, and inaccessible-looking spaces that
later become reachable through **Fly**.

It should feel windswept, adventurous, awe-inspiring, ancient, high-risk,
bright but dangerous, open to the sky, vertical rather than flat, scenic without
becoming empty. It must not feel like another Meadows, a dense dark forest, a
swamp, a horror biome, a water biome, or a corridor with cliffs painted beside
it.

**Entry.** After the Warden falls, the Meadows ending is reworked to grant a
**Key to the Next Realm** and the **Heart of the Meadows** relic; the rift
collapse is the crossing to Cloudreach. Each realm heart sits in a shrine and
is spent once.

**Six regions, not six checkpoints** — use loops, alternate paths, overlooks,
shortcuts, optional pockets and reconnecting routes.

1. **Cloudreach Gate / Lower Cliffs** — arrival, vertical-terrain
   tutorialization, first settlement, first trainers, basic cliff ecology, the
   region's problem introduced.
2. **Broken Causeways** — rope bridges, shattered stone roads, side paths, the
   first major route choices, stronger encounters, resource pockets, visible
   inaccessible upper terrain.
3. **Windscar Ravine** — narrow traversal, a dramatic drop, wind hazards and
   their visual language, the mid-biome conflict, preparation for Fly.
4. **High Roost / Sky Shrine** — Fly-only. Story pivot, meaningful reward,
   chapter unlock.
5. **Upper Cloudreach** — a large elevated plateau system, stronger trainers,
   higher-tier resources, dangerous ecology, optional content, flight
   shortcuts, late preparation.
6. **Summit / Final Stronghold** — the climax. The summit stronghold is a
   **domed aviary**. Elite encounters, the final boss, the conclusion, and the
   Stormwood setup.

**The new verb is Fly**, unlocked mid-chapter, and there is a required
**fly-only sheer cliff** so the unlock changes the map rather than just moving
the player faster.

**Implementation note.** Cloudreach uses procedural stacked cliff meshes in
`scenes/world/cloudreach_cliffs.tscn` with the same Meadows surface textures
and procedural grass/flower family, not Terrain3D. `cloudreach_world.json`
defines six connected vertical regions and their route graph;
`cloudreach_chapter.json` defines story and content. Saves tag realm-local
poses, buildings and death satchels so the two worlds never share coordinates.

## 2.3 Chapter 3 — The Stormwood

**Core fantasy.** A deep old forest under a storm that has not stopped in years.
Giant trees; glass-fused trunks where lightning has struck a thousand times;
glowing moss and fungus lighting the understory because the sun never gets
through; copper-veined vines; still black pools mirroring lightning; and Team
Tether's rod lines — iron lightning rods marching through the canopy on scaffold
towers — pulling every strike toward the Dynamo.

The forest floor is lit **from below**, by moss, not from above. It should feel
like the world got darker and stranger after Cloudreach's open sky: closed in,
alive, crackling, beautiful the way a lit cave is beautiful.

**Mechanic 1 — the Surge.** The storm is a cycle the player learns to read and
use, not a weather preset that happens to be on. Four phases, tunable in
`data/config/stormwood_surge.json`:

| Phase | Default | What it looks like | What it changes |
|---|---|---|---|
| Calm | 240 s | blue-green moss light, drizzle, distant rumble | baseline spawns; arches idle-glow |
| Building | 90 s | copper flicker on vines, wind, rising hum, birds quiet | storm-linked species appear; ground-glow telegraphs start |
| Break | 120 s | strikes every 4–8 s on exposed ground, white-violet light | lightning hazard live; surge encounter tables; capacitor trees open; lit arches flare and read from far away |
| Fading | 60 s | ember afterglow, steam off glass, thunder rolling away | charged nodes stay open; rare afterglow spawns |

The cycle runs independently of day/night. Night in a Break is the most
dangerous state; day in Calm the safest. Regions 1–2 get a gentler cycle. Camps
with a lightning rod, settlements, the Still Grove and the Hollow Crown are
surge-safe. Disabling a rod station shortens Break and lengthens Calm in its
region, visibly. After the finale it becomes an ordinary storm *season*: rare
Breaks, mostly Calm, the sky visible. **It fails if a blind tester can't name
the phase from sound and light alone, or if the phase changes nothing about
what they meet and what they can gather.**

**Mechanic 2 — Stormglass Arches.** The Rodfolk's old road: paired gates of
fused lightning-glass, now dark. Relight or build a pair and step through one to
come out of its twin. The required arch-only destination is **the Hollow Crown**
— a grove on an island of glass no path reaches.

**Six regions.** Cinder Verge (arrival, the burnt edge, Ashfoot Waycamp, the
Surge tutorial) → Glowmoss Hollows (wet low forest, the Lantern Pools, the first
relit arch pair, the first view of the Crown) → The Conductor Run (the ridge
carrying the main rod line, full storm exposure, insulation and rod tutorials,
Rodline Post, the Capacitor Grove) → **The Hollow Crown** (arch only; story
pivot) → The Deepwood (largest region; Lantern Hollow settlement, the Fallen
Giant root bridge, the Old Rodfolk Hall optional dungeon) → **The Dynamo** (the
storm-harvesting station; outer works, the last camp, the officer, the captain's
core arena, the legendary's chamber).

Required structure: ≥4 loops returning the player to a known place by another
way, ≥3 shortcuts that open from the far side, ≥5 dead-end reward pockets, ≥2
alternate routes between consecutive regions after region 2, and every region's
main landmark visible from at least one neighbour.

## 2.4 Chapter 4 — Tidewake, the Water Archipelago

**Core fantasy.** One realm of open water and twelve authored islands, with the
Veilfall — a white-falls mountain — visible from the first shore and reached
last. Sea level 0 m; realm bounds x −1200…1900, z −500…4900, y −80…650.

**What is explicitly out:** boats, an oxygen meter, diving, underwater building,
thirst, a fishing minigame, grappling, and any universal wetness punishment.

**Twelve islands** — eight on the main path, four optional:

| Island | Purpose |
|---|---|
| First Shore | arrival, sheltered swimming lesson, trader, camp |
| Reedhaven | marsh settlement, repair the departure pier |
| Brine Steps | rocky terraces, local trainer challenge |
| Shellwatch | occupied dock, rescue and the first pump |
| Tidal Cradle | land/water Alpha arena, the Swim Stone, saddle craft |
| Salt Crown | first expedition crossing, main late settlement and shrine |
| Sluice Isle | pumps, patrol platforms, final channel controls |
| The Veilfall | the mountain, last preparation, the hike, the hidden stronghold |
| Lantern Cove *(opt)* | early swimming detour, recovery cache |
| Gull Rest *(opt)* | sheltered Reedhaven branch, stranded researcher |
| Drowned Garden *(opt)* | mounted-only ruins, rare rewards and habitat |
| Deep Watch *(opt)* | Tidecoil encounter, current shortcut, Skill Candy III |

**Shallows are real slopes, beaches are landings, and cliffs and currents
explain gated approaches. No invisible swim walls.** A far-side pier cannot be
bypassed by an adjacent gentle beach; wilderness detours carry authored current
and distance costs. Early exposed gaps are ~80–110 m, late ones ~400–660 m.
Target ≥4 land loops, 3 unlocked return shortcuts, 8 deliberate reward pockets,
≥8 km of land routes and ≥2 km of water routes.

**Story spine in three acts.** *The Broken Channels* — Dockkeeper Mara receives
the traveler, swimmer Pell teaches the calm-water route, Reedhaven's pier needs
repair, Brine Steps wants a trainer demonstration, Shellwatch's dock opens after
freeing residents and disabling its pump, researcher Iona identifies the
guardian. *A Back Across the Sea* — **Aquaryn**, the catchable Water Dragon
Alpha, alternates shore attacks and water sweeps; defeat **or** catch resolves
it and awards the Swim Stone either way; Iona teaches the Swim Saddle recipe,
craftable on one of five compatible species, with the required resources
reachable beforehand so catching Aquaryn never gates progress. *Behind the Veil*
— disable the two Sluice Isle controls, open the sheltered channel, provision at
Lastlight Camp, cross, hike the wet-rock terraces, beat Officer Venn, enter
behind the falls, release the sluices, defeat Captain Nerissa, free the
**Abyssal Guardian** (the captive legendary), resolve the five-slot ceremony,
earn the Tideglass Compass, and revisit a changed archipelago. **Tidecoil** is
the non-mount deep-water apex.

**Human swimming.** A state machine — LAND, SWIMMING, DROWNING, COMBAT_PAUSED —
with mounted variants sharing the same aquatic rules. Human speed 3.8 m/s, drain
2.8/s against existing vitals capacity, drowning damage 4 HP/s, ending
immediately on safe-ground exit. No deep-water idle regeneration. Reaching zero
is visible, audible and gradual. The Swimming skill reduces drain 1.5 %/level,
capped at 35 %. **The first required crossing must leave ≥15 % stamina for a
level-0 unfed swimmer — if it doesn't, shorten the channel. Never fix unfair
geometry by giving infinite stamina.**

**Global Skills.** Running, Catching, Riding, Swimming, Flying — and nothing
else. They accumulate from the Meadows onward and the menu is revealed on first
Cloudreach arrival. XP comes only from real activity: sprint distance, confirmed
legal wild catches, mounted distance, water distance, flight distance. No idle
or menu-open XP. Starting cap 30; next level costs 100 + 30 × level. The menu
shows level, progress, improvement source, current benefit, next benefit and
cap. **Skill Candy** I/II/III add 1/2/3 levels to a selected skill, preserve
fractional progress, and refuse consumption that would exceed the cap while
explaining why. Twelve authored rare placements: 7 × I, 4 × II, 1 × III,
primarily on optional islands, in coves, behind hard trainers and along current
routes.

---

# Part 3 — What every system is for

## 3.1 Combat

Real-time, **piloted, not commanded**. The player drives the active creature
directly: move, aim, quick attack, charged attack, switch mid-fight, flee, and
throw an Orb in wild fights. Readable, responsive and spatial. Major fights need
identity, not larger HP pools. Type matchups must be legible in the moment.

**No shields, no blocking, no held buttons** — the authored controller map has
none. Mid-combat switching is allowed. The baseline fight costs something.
Combat VFX are mesh-based and the flourish rides the deployed body.

## 3.2 Catching

Catching **costs you your pal** — a party slot is spent to throw. Capture odds
are an explicit percent: `species_rate × hp_factor × orb_multiplier ×
accuracy_bonus`, with three orb tiers (basic ×1.0, greater ×1.6, prime ×2.0).
The physical throw must be satisfying enough that seeing a desirable wild
creature is exciting rather than administrative. Trainer-owned creatures can
never be caught.

## 3.3 Wild ecology

Wild creatures are the living world and the primary source of team
alternatives. **Every region must introduce at least one legitimate temptation
to change the five.** The wild table is data, cut per band.

## 3.4 Trainers

Progression tests, XP and reward sources, and a human ladder of increasing
competence — authored in believable places, escalating from locals to the Team
Tether hierarchy to the Warden. Trainer levels climb from 2 to the Warden's
level-20 ace across 15 critical-path fights, with no jump larger than four
levels and nothing in the stronghold out-levelling the boss.

## 3.5 Progression

Levels, XP, moves, traits and bond exist so that getting stronger is **visible
and understandable**. The player should always be able to name several honest
ways to improve the team without being forced into repetitive low-value
grinding. Levels are not UI locks; expected team strength emerges from the
available encounters, XP, rewards, catches and resources. A level gate measures
the party's highest creature. The chapter is three to four hours and pacing is
tuned around that curve.

## 3.6 Gathering and crafting

Resources must have **known uses**. A visible deposit is interesting because the
player knows what it unlocks or builds, not because every shiny object should be
harvested. Every tree and stone is harvestable and **stays gone**; chopping a
tree stands a felled pickup rather than paying out directly. Recipes are gated
by dialogue flags, so talking to people unlocks capability. A TM is an item and
it is spent. Elixirs are rare and capped.

## 3.7 Building

Building **supports adventure and never becomes a factory game**. A basic
shelter should be fast and pleasant: modular pieces snap, rotate and dismantle
with refund. Camps and home enable recovery, crafting, storage, food and
personalization. The build menu deliberately does not pause the world ("Valheim
feel"). The hoe gates tilling and nothing else. The torch is carried, not built.
Free-build is temporary scaffolding, not a shipped player-facing mode.

## 3.8 Rest and creature care

Injury creates expedition decisions. A creature placed in a bed **physically
rests, becomes unavailable, and gradually recovers**; full rest takes meaningful
time or an overnight. Fainting needs a revive. The player should sometimes
choose to stop because the team needs it. Companion reactions are procedural
over the model pivot and yield to everything else.

## 3.9 Satiety

Light. Slow drain, food restores and buffs, soft drawbacks when low. **There is
no starvation death and there never will be.**

## 3.10 Home

Home stays emotionally and mechanically relevant through the whole chapter.
Returning provides changing Grandpa dialogue, creature recovery, crafting,
progression upgrades, rescued-NPC acknowledgment and preparation for the next
expedition.

## 3.11 Objectives and map

Objectives answer **what the player is trying to accomplish now and why the next
challenge matters** — a linear "next thing to do," not a branching quest engine
and not a GPS trail. The map records exploration and supports the mental map the
world already creates; it is **not** a wild-creature radar and must not
compensate for unreadable geography. There is exactly one map database.

## 3.12 Riding

Riding is a **world verb and costs no stamina**. A mounted sprint and hop cost
nothing and the saddle stays on. It is the stated traversal-speed solution —
there is no fast-travel waypoint system beyond the debug/teleport menu.

## 3.13 Death

Multiple death satchels persist, each with an owner. Downed precedes death.

## 3.14 Multiplayer

**1–4 player co-op, and anything new is multiplayer-native from the first
implementation.** Transport is Godot ENet on a listen server with two channels.
The host simulates every non-player body on the heightfield and is truth for the
clock. Different biomes at once are headless realm shells on the host. Each peer
renders its own rig. **Menus never pause a multi-peer session.** Catches,
pickups, storage and trades are host transactions with versions. Sleep is a
vote. Scaling is composition-first and rewards are per-participant, with an
unscaled base kept on the director. Every story flag has a declared scope, and
an undeclared one is a test failure. Saves split into a host-owned world file
and a portable character file. **Item trading is in; creature trading is out.**

---

# Part 4 — The visual target

## 4.1 In one paragraph

A lush, colourful, stylised, highly readable creature-adventure world: **stylised
realism between Valheim and Palworld.** Vibrant natural palette, silhouettes and
landmarks readable from distance, cozy and inviting with hints of mystery,
distinct day and night moods. Lush rather than sparse, layered rather than flat,
composed rather than scattered, populated rather than empty, with strong
foreground / mid-ground / distance separation. Not photoreal, not AAA cinematic,
not a pile of marketplace assets, and not a single good screenshot angle.
Real-time on a ROG Ally.

## 4.2 The seven pillars

- **A.** Lush ground coverage in layers — terrain, grass, groundcover, weeds,
  flowers, litter — never bare green terrain with scattered grass models.
- **B.** Vegetation in clusters and ecological patterns: groves, stream edges,
  forest edges, lone hero trees. Never a uniform scatter.
- **C.** Terrain breakup: rocks, roots, banks, paths cut into the ground.
- **D.** Layered composition per view: a foreground element within a few metres,
  a mid-ground subject, a distant mass with warm/cool separation.
- **E.** Atmosphere and skies that give depth without eating the world.
- **F.** Landmarks integrated into the land, readable at 400 m **and again** at
  100 m.
- **G.** Life — creatures and people that make the world read as inhabited.

## 4.3 The references

In priority order: the owner-approved world boards
(`docs/website/redesign-2026-08-30/02_WEBSITE_ART_BOARD_FINAL.png`);
`docs/reference/tetherbound-meadows-keyart.png` for Tetherbound identity; and
`docs/reference/palworld-0*.jpg` as the owner's shipping-quality bar for
density, layering and composition. **Never copy another game's assets or
compositions.** Per-domain supplementary references are listed in
`ACCEPTANCE.md`.

## 4.4 Standing visual decisions

- Grass density stays at 75k tufts / 4 blades / 3 segments.
- The Pond pocket's density is the approved lush reference; do not spread it.
- No more villagers.
- Every village road has a gate; the boundary cannot be jumped.
- Aerial perspective is a terrain-material gradient, **not fog** — fog was tried
  and rejected.
- Trees are tall, and a scale range is not a re-roll.
- Shared model-material drift is a bug, not a ceiling.
- Burrowback keeps its rock armour: it is dark by design, and brightening it to
  clear a contrast ratio trades away its identity.

**Where the knobs are.** Sky/light/time: `data/config/art.json`,
`scripts/world/world_look.gd`, `shaders/sky_clouds.gdshader`. Terrain:
`data/config/terrain_playground.json`, `shaders/terrain_ground.gdshader`.
Scatter: `data/config/vegetation.json`, per-band `vegetation.json`,
`scripts/world/scatter_rules.gd` — **re-bake after any edit.** Grass carpet:
`data/config/grass_field.json`. Props and camps: per-band `props.json`,
`data/config/village.json`. Hall: `data/config/stronghold.json`. Warrens:
`data/config/burrow_warrens.json`. Relay: `data/config/tether_relay.json`.
Visibility ranges: `data/config/performance.json`.

---

# Part 5 — Decisions and precedence

## 5.1 Precedence when documents disagree

1. The owner's most recent feedback (top of `STATE.md`'s feedback section)
2. `AGENTS.md` / `CLAUDE.md` hard rules
3. this Bible
4. `ACCEPTANCE.md`
5. `STATE.md`, `WORKFLOW.md`, `TECHNICAL.md`
6. anything under `archive/` — history only, never authority

## 5.2 The decision records

125 numbered decision records (D01–D112 plus named Water/Stormwood records) are
archived at `archive/docs/decisions/`, with an index at
`archive/docs/decisions/INDEX.md`. **Every decision that still binds has been
folded into this Bible or into `TECHNICAL.md`.** Open an archived record only
when a code comment sends you to it by number, and read it as history rather
than as an instruction.

Six numbers were assigned twice and one three times (D28, D50, D53, D70, D91,
D100 ×3). The index disambiguates them. Do not cite a bare duplicate number in
new work.

## 5.3 When to ask instead of inventing

Ask only when implementation requires choosing between materially different
game behaviours that nothing in these documents settles: the five-creature
limit, human weapons, the type system, creature storage, a major story rewrite,
traversal philosophy, harsher hunger, or the stronghold structure. Implementing a
documented owner directive is ordinary work, not a question.

If nobody is there to answer — the normal case in an unattended session —
**record the question in `STATE.md`, take the conservative option, and keep
going.** Do not stall the session waiting for an answer that isn't coming.
