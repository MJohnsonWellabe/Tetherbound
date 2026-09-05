# TETHERBOUND — BUILD BIOME 3: THE STORMWOOD TO COMPLETION

**Status:** DRAFT for owner review, 2026-09-05. When the owner merges this file it becomes
the authoritative Biome 3 directive and outranks older biome-order prose (`docs/specs/GAME_DESIGN.md`
§9, the Cloudreach directive's "Water comes after Cloudreach" line). Until then it is a proposal.

**Who this is for:** the Codex orchestration session that will build the biome in one goal, the
way `docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md` was used for Biome 2.
Everything the biome needs except its final creature roster is specified here, with counts.

## `/goal`

Build **Biome 3: The Stormwood** — an electric forest — all the way through to a complete,
integrated, playable third chapter after Cloudreach Cliffs.

This is **not** a design-only task and not a massing prototype.

Take the game from the end of Cloudreach into a fully playable third biome: terrain, world,
story, the Surge weather cycle, Arc-Step traversal, NPCs, trainers, encounters, resources,
gear, pickups, objectives, mini-bosses, the Dynamo finale, the captive legendary, the Realm
Heart reward, save-state integration, UI hooks, tests, evidence, and integration to `main`.

Creatures are the one deliberate exception. **Use Meadows creatures as placeholders in every
encounter slot** (§17). The final Stormwood roster is dropped in later through replaceable
encounter tables; the missing roster is not permission to leave anything else incomplete.

You are responsible for orchestration and completion. Use lower-tier agents aggressively for
bounded implementation, content authoring, tests, capture and repetitive work. Keep senior
responsibility for architecture, canon, sequencing, integration, world composition,
progression coherence, visual judgment and final acceptance.

---

# 0. OWNER DECISIONS THIS DOCUMENT ASSUMES

Each of these is a real game decision that nothing in the repository settles. Each is stated
with the recommendation this document is written against. The owner should confirm or change
them before Codex starts; Codex must not silently choose differently.

| # | Decision | Recommendation written into this document |
|---|---|---|
| 0.1 | **Biome order.** Canon (`GAME_DESIGN.md` §9, the Cloudreach directive §1) put Water third. The owner now wants the electric forest next. | Electric Forest is Biome 3. Water moves to Biome 4. Cloudreach's completion rewards are retargeted from `realm_key_water` / `waterward_route_revealed` to `realm_key_stormwood` / `stormward_route_revealed` (§5). |
| 0.2 | **Name.** The Meadows already signposts this direction as "Storm Country" (`terrain_playground.json` spoke `storm_road`, fingerpost label `Storm Country`). | **The Stormwood.** Alternatives for the Creative Director to pick from: Voltwood, Thunderwood, Glimmerwood, the Sparkwild. The realm id is `stormwood` whichever display name wins; change the display string, not the id. |
| 0.3 | **The biome's traversal verb is Teleport (Arc-Step).** `docs/specs/C1_RIDEABLE_ROSTER_FLY_TELEPORT.md` promises the Ripplet starter learns teleport "in a later biome"; Cloudreach paid off Galewisp's Fly. | The Stormwood teaches Arc-Step. Ripplet learns it here; a catchable wild blink-capable creature also exists so a Terrapup or Galewisp player can complete the chapter (§10). |
| 0.4 | **A captive legendary.** `GAME_DESIGN.md` §5 gives every stronghold a captive legendary; the Cloudreach chapter data has none. | The Stormwood has one, imprisoned in the Dynamo, freed in the finale, offering to join with the existing release ceremony. Its final art comes later; a placeholder body ships (§17.5). |
| 0.5 | **Heart of the Stormwood power.** Only Meadowstride (double stamina) exists; Cloudreach's power is intentionally undefined. | **Livewire:** the piloted creature's move cooldowns are 25 % shorter. Tunable in `realm_hearts.json`. Cloudreach's power stays deferred unless the owner names it. |
| 0.6 | **Lightning can hurt the player.** The Meadows has player death and persistent satchels; Cloudreach prevents falls with recovery currents. | Yes, Valheim-style: telegraphed strikes on exposed ground during a Surge damage the player and creatures; never in regions 1–2, never inside a rod-protected camp, never a one-shot at the region's expected level (§11). |
| 0.7 | **Level range.** Meadows 3→20, Cloudreach 18→34; `GAME_DESIGN.md` §11 caps levels at 50 with five biomes still to come. | Team enters at 33 and leaves at 44; captain ace 44. The cap question is the owner's: this document recommends raising the cap to 100 in a later decision rather than compressing the Stormwood. |
| 0.8 | **Concept board.** Cloudreach's board never reached the repo and its first visual pass failed the blind judge. | Build against the written visual language in §4 and the installed nature family. If the owner supplies a Stormwood board, it wins over §4. |

---

# 1. READ FIRST

Before changing anything, read and obey, in this order:

1. `CLAUDE.md`
2. `docs/00_START_HERE.md`
3. newest `docs/owner/` directives (the 2026-09-04 density, progression-visibility and companion directives apply to this biome in full)
4. `docs/CURRENT_STATE.md` — especially the Cloudreach checkpoints and their honest visual verdict
5. `docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md` and `ralph/reports/CLOUDREACH-PHASE3-AUDIT-0904/REPORT.md` — the realm seams (persistence namespaces, 3D placement, dialogue manifest, catalogue injection, map isolation) that Cloudreach had to open are the seams this biome reuses
6. `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` — the encounter standard (G-1 three-sentence test, G-3 behaviour profiles) applies here unchanged
7. `docs/specs/C1_RIDEABLE_ROSTER_FLY_TELEPORT.md` — the teleport promise this biome pays off
8. `docs/specs/C4_CAMPING_NECESSARY.md`, `docs/specs/C2_TASK_FEED.md`
9. `docs/WORLD_AND_CONTENT.md` §7 — the Meadows density census this biome is measured against
10. this document

Do not reopen archived backlogs as active truth. Do not create a competing master plan unless
current canonical documentation is provably wrong. Where older docs order Water before
Electric, update them so the Stormwood becomes the authoritative third biome (§0.1).

---

# 2. FINAL OUTCOME

At the end of this goal a player can:

1. finish Cloudreach and defeat Captain Veyra;
2. receive the **Heart of Cloudreach** and the **Key to the Stormwood**;
3. see the Stormward route revealed from the summit (a distant wall of permanent storm over a forest);
4. travel to the Stormward gate and open it with the key;
5. enter the Stormwood and immediately understand: a forest, under a storm that never ends;
6. play through the entire Stormwood chapter across six regions;
7. live with the **Surge** cycle — the storm building, breaking, fading — and learn to use it;
8. learn **Arc-Step** and reach the teleport-only **Hollow Crown**;
9. disable Team Tether's four **rod stations** and reach the **Dynamo**;
10. defeat the Dynamo captain in a real arena fight;
11. free the captive legendary, face the five-creature choice, and see the Long Storm end;
12. receive the **Heart of the Stormwood** and place it at a shrine;
13. see the world point clearly toward the Water biome without entering it.

The Stormwood must be a real playable chapter that a blind tester can finish in a
**3–4 hour focused first clear**, with more available for exploration, optional trainers,
gathering and building. Not scaffolding, not a massing prototype.

---

# 3. THE STORMWOOD — CORE IDENTITY

## Name

**Biome 3: The Stormwood** (see §0.2 for alternates). Realm id `stormwood`.

## Core fantasy

A deep old forest under a storm that has not stopped in years. Giant trees, glass-fused
trunks where lightning has struck a thousand times, glowing moss and fungus lighting the
understory because the sun never gets through, copper-veined vines, still black pools
mirroring lightning, and Team Tether's rod lines — iron lightning rods marching through the
canopy on scaffold towers — pulling every strike toward the Dynamo.

It is built around:

- canopy so dense the forest floor is lit from below, by moss, not from above;
- lightning-struck clearings of black glass and cinder where the sky briefly shows;
- the **Surge** — a visible, audible cycle of the storm building and breaking;
- rod lines and capacitor trees: Team Tether hardware bolted onto living wood;
- **Waystones**: ancient conductor stones the forest folk once used to travel;
- ravines, root bridges, hollow trunks and fallen giants as traversal;
- settlements built into and under trees, lit by moss lanterns;
- the Hollow Crown, a grove on an island of glass no path reaches;
- the Dynamo, a storm-harvesting station at the forest's heart, humming.

It should feel like the world got darker and stranger after Cloudreach's open sky — closed
in, alive, crackling, beautiful in the way a lit cave is beautiful.

## Tone

The Stormwood should feel:

- enclosed, vertical in the other direction (looking up, not down);
- electric, alive, humming, never silent;
- lit from within (moss, fungus, glass, arcs), not dark for darkness' sake;
- dangerous on a rhythm the player learns to read;
- old (the Waystones) under something new and wrong (the rod lines);
- generous with discovery: every clearing, hollow and pool has something in it.

It should NOT feel like:

- a horror biome, a haunted forest, or a night-only Meadows;
- a swamp;
- a corridor with trees painted beside it;
- Cloudreach with trees;
- a place where the storm is decoration — the Surge must change play.

---

# 4. VISUAL TARGET

No concept board exists yet (§0.8). Build against this written language and the installed
nature family, and run the code-blind visual judge against the Meadows key art and the
Palworld bar exactly as Cloudreach was judged.

**Learn from Cloudreach's failed first pass.** The judge rejected procedural mesas with flat
materials and sparse props. The Stormwood must use the Meadows presentation stack from day
one: **Terrain3D authored heightfield**, the baked scatter pipeline (`scatter_rules.gd`,
`bake_playground_scatter.gd`, per-region `vegetation.json`), the procedural grass/ground-cover
layers retuned for a forest floor, habitat prop clusters, and the same material and lighting
language. Do not build the world out of box and cylinder primitives.

Preserve these ideas in every frame:

- **canopy scale**: trunks 3–6 m across, canopy 40–60 m up, the player small under it;
- **lit from below**: emissive glowmoss, fungus shelves, glass veins in trunks, arc flicker on
  copper vines; the sky is a dim purple-grey ceiling seen through gaps;
- **the Surge as light**: calm is blue-green moss light; building adds copper flicker; the
  break is white-violet strikes with hard shadows and afterglow; fading is warm ember light;
- **Team Tether grammar** exactly as the Meadows Hall and Relay use it: iron, rivets, reserved
  faction colours, pipes and conduits leading toward the Dynamo, drained ground (D45) under
  every rod station;
- **large readable silhouettes**: capacitor trees, rod towers over the canopy, the Crown's
  glass island, the Dynamo's chimneys;
- **places seen before reached**: the Hollow Crown from region 2, the Dynamo's glow from
  region 3 onward.

Materials, textures, emissive maps, modest scale, VFX and shaders differentiate the forest
from the Meadows grove. The tree meshes are the installed Stylized Nature MegaKit and Nature
Kit families (`assets/stylized_nature`, `assets/nature`); the village family is the installed
Medieval Village MegaKit; props are the installed Fantasy Props, Survival Kit and Team Tether
hero objects (`team_tether_scaffold_tower`, `rift_siphon_wall_machine`, `tt_pipe_*`,
`team_tether_banner_rig`). **No new nature, village or prop families. No Meshy spend without
owner reference art.** The one legitimate Meshy target is the Dynamo core (a Team Tether hero
object, per `CLAUDE.md`), and only after the owner supplies a board for it; ship a kitbashed
placeholder otherwise.

---

# 5. CLOUDREACH ENDING REWORK

Cloudreach currently ends by granting `realm_key_water` and revealing a Waterward route. Under
§0.1 that changes, in data and in tests:

- Captain Veyra's defeat grants **Key to the Stormwood** (`realm_key_stormwood`) and the
  **Heart of Cloudreach** (`realm_heart_cloudreach_earned`, power still deferred).
- `waterward_route_revealed` becomes `stormward_route_revealed`; the Waterward Overlook
  landmark becomes the **Stormward Overlook**: from the summit the player sees, far off, a
  bruise-coloured permanent storm sitting over a dark forest — the Tether Rift that is this
  biome (`MEADOWS_PROGRESSION_SPEC.md` §23 lists "permanent storms" as a Rift form).
- The Water biome remains visible as a second, further, non-enterable direction — a glint of
  water past the storm — so the game still points at Biome 4.
- `data/config/realm_hearts.json` `realms` gains `stormwood` with `entry_key_flag:
  "realm_key_stormwood"` and its scene; `cloudreach_chapter.json` rewards, aftermath, map
  unlocks and `tests/test_cloudreach_chapter_data.gd` are updated together.
- Old saves that already hold `realm_key_water` migrate it to `realm_key_stormwood` on load.

Nothing else in Cloudreach's chapter changes.

---

# 6. HEART OF THE STORMWOOD

Extend the existing Realm Heart system (`autoload/realm_heart_state.gd`,
`scripts/world/realm_heart_shrine.gd`, `data/config/realm_hearts.json`). Do not write a
second one.

- **Earned** when the legendary is freed (`realm_heart_stormwood_earned`).
- **Placed** at the **Stormwood shrine** in Lantern Hollow (§12 region 5); placing it is
  the aftermath beat that shows the forest lit calm for the first time.
- **Power — Livewire:** the piloted creature's move cooldowns are shortened by 25 %
  (`cooldown_multiplier: 0.75`, tunable). It must go through the same single-active-power
  selection as Meadowstride, swap cleanly, never stack, and persist.
- The shrine must show three Heart slots (Meadows, Cloudreach, Stormwood) with the
  Cloudreach slot holding an earned-but-undefined Heart that displays honestly ("its power
  has not woken") rather than a fake power.

---

# 7. ENTRY TO THE STORMWOOD

A real realm transition, modelled on `realm_transitions.json` and `realm_gate.gd`:

- the **Stormward gate** stands physically in Cloudreach's Summit region, past the Dynamo
  captain's arena, on the far side of the Stormward Overlook: a storm-scarred stair down
  from the plateau into a wall of cloud, barred by a Tether relay gate;
- visibly locked before Veyra's reward; the Key opens it without being consumed;
- the descent is a short authored passage (cloud, then the first struck tree) so the first
  Stormwood frame lands under the canopy with the Surge audible;
- returning to Cloudreach and the Meadows stays possible through the same gate;
- entry and return anchors are realm-tagged; the arrival autosave follows Cloudreach's
  terrain-settling pattern; no sequence break by Fly or geometry (Fly is refused inside the
  Stormwood's canopy volume: there is no sky to launch into, and the data says so).

---

# 8. THE STORMWOOD STORY

## The regional problem

The Stormwood always had storm seasons. Its people — the **Rodfolk** — lived by them: they
raised Waystones to travel under the canopy, harvested stormglass after the season, and let
the forest rest between. Team Tether built the **Dynamo** at the forest's heart, bound the
forest's legendary inside it, and used it to hold one storm over the forest permanently:
the Rift that severs the Stormwood from the world. Their **rod lines** drag every strike to
the Dynamo. The canopy is dying at the edges, the Waystones have gone dark, the Rodfolk
cannot travel their own forest, and Team Tether's public line is that the Long Storm keeps
the wild forest from spilling into the neighbouring realms.

Persistent flags (namespace `stormwood:`), acts, objectives, NPCs, trainers, tables,
pickups, resources, camps, map, audio, finale, rewards and aftermath are authored in
`data/config/stormwood_chapter.json` with the same schema shape as
`cloudreach_chapter.json` (schema_version 1, `world_contract` pointing at
`stormwood_world.json`), consumed at runtime through the catalogue-injection seams the
Cloudreach audit names. Data presence is not content; every objective below must run.

## Act I — Under the Storm (regions 1–2)

- Arrive at the Cinder Verge; reach **Ashfoot Waycamp**.
- Meet **Rodkeeper Hesk**, who explains the Long Storm and the dark Waystones.
- Learn the Surge: survive the first break under canopy (tutorialised by Hesk's daughter
  **Tamsin**, who reads the storm for a living).
- Trace the first two rod stations (Verge and Hollows) and disable them: each is a small
  Team Tether picket, a grunt fight, a rod-tower switch, and a visible change (the local
  Waystone relights, drained ground begins to heal).
- Relight the Hollows Waystone; the Rodfolk can move again between camps.
- Act I ends when the player reaches **Rodline Post** at the foot of the Conductor Run and
  **Warden-Elect Bryn** (the Rodfolk's own defiant leader, not a Team Tether Warden) tells
  them the Waystones are only half the road: the old road went *across*, by Arc-Step.

## Act II — The Road Across (regions 3–4)

- Climb the Conductor Run under full storm exposure; learn rod protection and insulation.
- Reach the **Still Grove**, the one place the storm does not touch, where **Keeper Ondra**
  teaches Arc-Step to the player's blink-capable creature (Ripplet, or a caught Sparkit-role
  creature) in a controller-safe trial across a ring of Waystones.
- Arc-Step across the Glass Sink to the **Hollow Crown** — the teleport-only destination —
  and find the truth at its heartstone: the Dynamo is not harvesting storms, it is *making*
  them, by draining the legendary bound inside it; the Long Storm is the Rift.
- The Crown's heartstone releases the **Rootgate**: a grounded route into the Deepwood that
  no amount of walking opened before.

## Act III — The Dynamo (regions 5–6)

- Enter the Deepwood; reach **Lantern Hollow**, the main settlement, which has been cut off
  since the Long Storm began.
- Disable the two upper rod stations (Deepwood and Dynamo Approach); each is a larger
  Team Tether holding with an officer fight and a visible aftermath.
- Meet **defector Sable**, a former Dynamo engineer who describes the core and the
  captive.
- Cross the Dynamo approach: dead-wind corridor equivalent — a storm-blasted glass field,
  banners, patrols, the last camp.
- Fight **Officer Kestrel** at the outer works, then **Captain Marrow** in the Dynamo core
  arena (§18).
- Disable the core; the legendary wakes and offers to join; the five-creature ceremony runs
  if the team is full.
- **Aftermath:** the Long Storm breaks for the last time and does not return; sky shows
  through the canopy; Waystones all relight; Rodfolk travel the forest; NPCs get post-storm
  dialogue; the Stormwood Heart is placed; the Stormward-to-Waterward route is revealed
  from Lantern Hollow's high platform as a distant, non-enterable view.

Do not stop at "boss defeated." Aftermath and region-state change are part of the chapter.

---

# 9. THE SURGE (new mechanic 1 — storm weather cycle)

The Stormwood's storm is not a weather preset that happens to be on. It is a cycle the
player learns to read and use. Implement it as a realm-scoped extension of `WorldWeather`
(`data/config/weather.json` currently declares only clear/cloudy/fog/rain, and
`spawn_tables.json` already notes that a storm preset is missing).

**Four phases, tunable in `data/config/stormwood_surge.json`:**

| Phase | Default length | What the player sees and hears | What it changes |
|---|---|---|---|
| Calm | 240 s | blue-green moss light, drizzle on canopy, distant rumble | baseline spawns; Waystones idle-glow; rod stations hum |
| Building | 90 s | copper flicker on vines, wind, rising hum, birds go quiet | storm-linked species begin to appear; ground-glow telegraphs start in exposed clearings |
| Break | 120 s | strikes every 4–8 s on exposed ground, white-violet light, hard shadows | lightning hazard live (§11); surge encounter tables replace calm tables; capacitor trees charge (harvestable stormglass nodes open); Arc-Step range +50 % |
| Fading | 60 s | ember afterglow, steam off glass, thunder rolling away | charged nodes stay open; rare "afterglow" spawns; strikes stop |

Rules:

- The cycle runs independently of day/night; both continue to exist. Night in a Break is
  the most dangerous state; day in Calm the safest.
- Regions 1–2 have a gentler cycle (longer Calm, strikes only in marked clearings).
- Camps with a lightning rod, settlements, the Still Grove and the Hollow Crown are
  **surge-safe**; the HUD shows a small surge-phase glyph and a "sheltered" state there.
- Disabling a rod station shortens Break and lengthens Calm in its region (visible, tested).
- After the finale the cycle becomes an ordinary storm *season*: rare Breaks, mostly Calm,
  the sky visible.

**Fails if** a blind tester cannot say what phase the storm is in from sound and light
alone, or if the phase changes nothing about what they meet and what they can gather.

---

# 10. ARC-STEP AND WAYSTONES (new mechanic 2 — teleport traversal)

This is the biome's Fly. It pays off the C1 promise ("Teleports — beyond the Meadows").

## Visual concept

The blink-capable creature is piloted, the player beside it. On Arc-Step the creature
gathers charge (arcs along its body, 0.6 s), the pair collapse into a bolt that jumps to
the target Waystone or charged anchor, and re-form there with a thunderclap and a ground
scorch. It should read as lightning travelling between conductors, not as a menu teleport.

## Two verbs, one unlock

1. **Arc-Step (hop):** from anywhere, target a visible **charged anchor** (a lit Waystone
   or a charged capacitor tree) within range — default 28 m, +50 % during a Break — and jump
   to it. Line of sight required; no jumping through canopy or terrain; a target must be
   *lit*, so an unlit Waystone is a locked door the player can see.
2. **Waystone travel (fast travel):** interact with any lit Waystone to travel to any
   other lit Waystone the player has *stood at*. Costs nothing but a short charge-up; not
   available during a Break; never crosses a realm.

Both unlock together at the Still Grove trial (`arc_step_unlocked`). Neither works before
it. Nothing in the Meadows or Cloudreach gains them.

## Who can Arc-Step

- **Ripplet** (the starter) learns it here, reading the `future_traversal` block C1 placed in
  `species.json`.
- **Placeholder wild blink-capable role** (`blink_capable: true` on the encounter role, not on
  the species): the Sparkit-role creature in regions 2–3 is catchable and carries the verb, so
  every player can complete the chapter. The final roster will replace the body; the role
  and flag stay.
- The freed legendary can Arc-Step.
- A traversal creature costs one of five slots exactly as riding and flying do
  (`chapter_curve.json` `five_slot`). No sixth slot, no storage.

## Rules

- Controller-first: hold the traversal button to aim, anchors highlight in range, release to
  jump; the same context map pattern as Fly.
- No Arc-Step through locked progression: the Rootgate and the Dynamo's gates are not
  anchors; the Hollow Crown's Waystone ring is the only way across the Glass Sink.
- Collision-safe: arrival is always on an authored surface at the anchor; never inside
  geometry; never off the world.
- Landing near an enemy engages normally; Arc-Step is not an escape from a started fight
  (mirror the existing combat-lock rules).
- Completing an authored Waystone circuit grants a small bond event to the piloted creature,
  subject to the bond cap (mirror Cloudreach's `fly_bond_rule`).

## The required teleport-only destination: the Hollow Crown

Region 4. An ancient grove standing on an island of black glass in the **Glass Sink**, a
lightning-fused crater no path enters; the sink floor is a live strike field in every
phase. Visible from regions 2 and 3 as a ring of tall pale trees with a lit crown above
the canopy. Before Arc-Step: "I can see that place, and I cannot get there." After: the
ring of Waystones across the sink lights one by one as the player hops.

It contains: the story truth (§8 Act II), **Keeper Ondra's** counterpart **Archivist Wen**,
the Crown heartstone that releases the Rootgate, a Rare Candy, a TM, and the biome's
richest stormglass. It is memorable or it is wrong.

---

# 11. LIGHTNING, INSULATION AND THE ROD

The hazard that makes the Surge real and camping necessary, kept light the way satiety is
light.

- **Strike telegraph:** during a Break, exposed ground (no canopy, no rod) shows a ground
  glow 1.2 s before a strike; the strike is a 3 m radius; damage is authored per region and
  never one-shots a full-health creature or the player at the region's entry level
  (compute against `chapter_curve` stats before shipping a number). Strikes stagger and apply
  **Static** (stamina regen halved, 8 s).
- **Shelter:** canopy, rod radius, settlements, the Still Grove and the Crown are safe.
  Regions 1–2 only strike inside marked glass clearings.
- **Insulated gear** (§20): each piece worn reduces strike damage and Static duration; the
  full set makes strikes a stagger only. Gear is preparation, never a key.
- **Lightning rod** buildable (§21): a placed rod makes a 12 m radius surge-safe. Camping in
  regions 3–6 without one means a Break wakes the camp — creature recovery is interrupted
  and the player is struck. This is how the biome makes camping *matter* without hunger.
- **Player death** uses the existing satchel system unchanged; satchels persist and are
  realm-tagged.

**Fails if** a strike is ever unavoidable, unannounced, or lethal from full health at the
expected level; or if a rod-protected camp is ever struck.

---

# 12. WORLD STRUCTURE

Build the Stormwood as one authored Terrain3D world, realm-local coordinates, in
`data/config/stormwood_world.json` (same schema as `cloudreach_world.json`: realm bounds,
transition points, unlocks, regions, landmarks, routes, bridges, gates), built by a thin
`scripts/world/stormwood_world.gd` composer that reuses the Meadows/Cloudreach actors.

**Size:** playable footprint about **4.5 km × 6.0 km** (wider than Cloudreach; a forest is
not a corridor), critical path about **6.5 km**, total authored route **≥ 12 km** including
loops, side routes and the Waystone network. Vertical range about 120 m of terrain plus the
canopy; the Conductor Run ridge and the Deepwood's fallen-giant root bridges provide
vertical play without Cloudreach's cliffs.

Six named map regions (D36: few and large), each with its own map banner:

## Region 1 — Cinder Verge

Purpose: arrival; the burnt edge where the storm wall meets the trees; struck trunks, black
glass, the first living canopy ahead; Ashfoot Waycamp; the Surge tutorial; the first rod
station; first trainers; a gentle cycle.
Landmarks: **the Struck Sentinel** (a lightning-split giant, arrival orientation),
**Ashfoot Waycamp**, **Verge Rod Station**.

## Region 2 — Glowmoss Hollows

Purpose: wet low forest lit by moss and fungus; still pools; hollow trunks as passages; the
first route choices (three ways through, one flooded until a Break drains it); the Hollows
rod station; the first relit Waystone; the first view of the Hollow Crown.
Landmarks: **the Lantern Pools**, **Hollows Rod Station**, **the First Waystone**.

## Region 3 — The Conductor Run

Purpose: a ridge of glass-fused trees carrying the main rod line toward the Dynamo; full
storm exposure; insulation and rod tutorials; the mid-biome conflict (a Tether lieutenant
holding Rodline Post's old bridge); the Still Grove at its end.
Landmarks: **Rodline Post** (settlement), **the Capacitor Grove**, **the Still Grove**.

## Region 4 — The Hollow Crown (Arc-Step only)

Purpose: story pivot, memorable reward, Rootgate release. See §10.
Landmarks: **the Glass Sink**, **the Crown**, **the Crown Heartstone**.

## Region 5 — The Deepwood

Purpose: the largest region; canopy giants and root bridges; **Lantern Hollow** (main
settlement, trade, shrine); stronger trainers and the ace optional circuit; the Deepwood
rod station; the Stormwood's richest resources and optional pockets; the Heart shrine.
Landmarks: **Lantern Hollow**, **the Fallen Giant** (a root bridge over the Blackwater
ravine), **Deepwood Rod Station**, **the Old Rodfolk Hall** (optional dungeon, mini-boss).

## Region 6 — The Dynamo

Purpose: the storm-harvesting station; Team Tether's stronghold; final approach across the
glass field; outer works, the last camp, the officer, the captain's core arena, the
legendary's chamber; aftermath.
Landmarks: **the Glass Field**, **Dynamo Outer Works**, **the Dynamo Core**.

Do not build these as six straight checkpoints. Required structure:

- **≥ 4 loops** that return the player to a place they know by another way;
- **≥ 3 shortcuts** that open from the far side (a hollow trunk kicked through, a root
  bridge dropped, a Waystone relit);
- **≥ 5 dead-end reward pockets** off the main routes, each paying in candy, TM, gear or a
  named encounter;
- **≥ 2 alternate routes** between consecutive regions after region 2;
- every region's main landmark visible from at least one neighbouring region.

---

# 13. CONTENT DENSITY — REQUIRED COUNTS

This is the contract the biome is measured against. The baseline is the Meadows census
(`docs/WORLD_AND_CONTENT.md` §7: 321 spawn clusters, 198 harvest nodes, 101 pickups and
31 trainers over 11.5 km of route, i.e. about 28 clusters, 17 nodes and 9 pickups per km),
which is the density the owner has already accepted as "a reason to keep going." The
Stormwood must not be thinner than the Meadows anywhere, and Cloudreach's 19 pickups and
7 trainers are the example of what *not* to ship.

Counts are minimums unless a range is given. "Route" means authored route length
(`stormwood_world.json` routes) as the density lanes census it with
`tools/_probe_band_density.gd`; "met" means within 30 m of the walked critical path as
`tools/_probe_gate_f_corridor.gd` counts.

| Thing | Total | Per region | Rule |
|---|---|---|---|
| Named map regions | 6 | — | D36: large, banner on first entry |
| Landmarks (map + silhouette) | 16 | ≥ 2 | each a real mass visible from ≥ 1 other region or route |
| Authored route | ≥ 12 km | — | ≥ 4 loops, ≥ 3 shortcuts, ≥ 5 reward pockets, ≥ 2 alternates per late region |
| Wild spawn clusters | ≥ 330 (≥ 27 / km) | ≥ 40 (Crown ≥ 12) | worst gap between things met on the critical path ≤ 120 m; average ≤ 80 m |
| Encounter tables | 12 | 2 (Calm, Surge) | ≥ 3 roles per table; Surge tables differ in ≥ 2 roles; night variant weights on every table; `replaceable: true` on all |
| Named wild encounters | 6 | — | 3 mini-bosses (Old Rodfolk Hall guardian, Capacitor Grove alpha, Blackwater elder) + 3 alphas; each passes G-1 and uses a G-3 profile; catchable; once-only |
| Trainers | 26 | ≥ 3 | 14 on the critical path, 12 optional; ladder step ≤ 4 levels; no trainer out-levels the captain; every trainer has intro / win / lose lines and a rank body |
| Team Tether pickets | 4 rod stations + Dynamo outer works | — | each: ≥ 2 grunts, 1 switch, drained ground that heals when disabled |
| Named NPCs | 18 | ≥ 2 | pre-storm and post-storm dialogue states; body/portrait from the installed cast; none stacked in one settlement |
| Settlements / camps with residents | 3 (Ashfoot 4, Rodline Post 4, Lantern Hollow 8) | — | trade at Rodline Post and Lantern Hollow; shrine at Lantern Hollow |
| Authored safe camps | 6 | 1 | save, rest, cook, creature recovery; rod pre-built; Cloudreach `camping_contract` shape |
| Rod-able clearings | 10 | ≥ 1 in regions 3–6 | flat, buildable, visibly exposed; a rod placed there makes it surge-safe |
| Waystones | 10 | ≥ 1 | 1 (Hollows), 2 (Run), 4 (Crown ring), 2 (Deepwood), 1 (Dynamo approach) |
| Harvest nodes (authored) | ≥ 210 (≥ 17 / km) | ≥ 25 | plus every scattered tree and stone harvestable and staying gone (D60, D72) |
| Charged nodes (Break-only stormglass) | 24 | ≥ 3 in regions 2–6 | open only in Break/Fading; the biome's reason to be out in a storm |
| Placed item pickups (total) | 120–140 | ≥ 15 | authored placement logic; persistent, one-time; a stable `pickup_id` per placement |
| — Good / Great / Rare Candy | 40 / 20 / 8 | — | Good on side exploration, Great on detours and named fights, Rare on secrets, the Crown, the Hall, the Dynamo; critical path carries ≤ 10 candy total |
| — Potions (small / large) | 18 / 12 | — | main routes occasional, dangerous spaces stronger |
| — Revives | 16 | — | ≥ 2 within reach of every mini-boss and the Dynamo |
| — Tonics / elixirs / mushrooms | 12 | — | elixirs respect the existing cap (D47) |
| — Orbs (greater / prime) | 6 | — | late regions only |
| — TMs | 4 (electric ladder, §20) | — | one each in regions 2, 4, 5, 6 |
| — Insulated gear pieces (found, not crafted) | 2 of 4 | — | the other two are crafted |
| — Story items | 3 | — | Rootgate release, Dynamo core key, Heart |
| Main objectives | 24–30 | — | three acts; count-flags for the rod stations; ≥ 1 objective visibly changes at `arc_step_unlocked` |
| Side chains | 6 | — | ≥ 3 steps each; categories: exploration, affected locals, Arc-Step exploration, trainer completion, resource, mystery |
| Dialogue nodes | ≥ 160 | — | every NPC ≥ 2 states; every trainer 3 lines; every objective a `how` |
| Buildables (new) | 3 | — | lightning rod, moss lantern, insulated workbench upgrade |
| Resources (new) | 6 | — | §20 |
| Recipes (new) | ≥ 12 | — | §20 |
| Audio cues | 10 | — | §23 |
| Visual review points | 8 | — | §27 |
| Surge phases | 4 | — | §9 |

**Fails if** any region's count is under its minimum, if the critical-path worst gap exceeds
120 m, if any pickup lacks a stable id, or if the count is met by uniform scatter rather
than authored placement (the blind route strip must show *reasons*, not objects).

---

# 14. NPCS

Eighteen named NPCs across the six regions, every one with purpose, location, dialogue,
progression relevance and an installed body/portrait profile from
`docs/art/HUMANOID_ASSET_INVENTORY.md`. Names are proposals for the Creative Director;
ids stay.

| Id | Name | Region | Body profile | Roles |
|---|---|---|---|---|
| rodkeeper_hesk | Rodkeeper Hesk | 1 Cinder Verge | local_historian | arrival guide, explains the Long Storm, late-story reward |
| stormreader_tamsin | Tamsin | 1 | young_trainer | Surge tutorial, optional trainer, memorable side character |
| cook_marl | Marl | 1 | innkeeper | camp support, teaches rod protection, food buffs |
| courier_pim | Pim | 2 Glowmoss Hollows | courier | affected local stranded between Waystones; side chain giver |
| trainer_ivo | Ivo | 2 | wandering_trainer | optional trainer, route-choice hints |
| grunt_lieutenant_dace | Lieutenant Dace | 2 | grunt_c | Hollows rod station picket, first Team Tether fight |
| warden_elect_bryn | Warden-Elect Bryn | 3 Conductor Run (Rodline Post) | craftsperson | Rodfolk leader, Act I close, insulation recipes |
| trader_oswin | Oswin | 3 | trader | Rodline Post trade |
| tether_lieutenant_varga | Lieutenant Varga | 3 | officer_a | holds the Rodline bridge, mid-biome conflict fight |
| keeper_ondra | Keeper Ondra | 3 (Still Grove) | creature_caretaker | Arc-Step mentor, trial giver |
| archivist_wen | Archivist Wen | 4 Hollow Crown | field_researcher | the truth, Rootgate release, late-story NPC |
| elder_maud | Elder Maud | 5 Deepwood (Lantern Hollow) | local_historian | Lantern Hollow elder, shrine keeper, Heart placement |
| trader_fenn | Fenn | 5 | trader | Lantern Hollow trade, high-tier recipes |
| caretaker_lio | Lio | 5 | creature_caretaker | creature recovery, bond gifts |
| ace_trainer_rook | Rook | 5 | rival_trainer | ace optional circuit, "the Deepwood Circuit" side chain |
| defector_sable | Sable | 5 | former_tether_member | Dynamo engineer, describes the core and the captive |
| officer_kestrel | Officer Kestrel | 6 Dynamo | officer_b | outer-works fight, antagonist representative |
| captain_marrow | Captain Marrow | 6 | captain_a | primary antagonist, final trainer |

NPCs must not show the player's face (the placeholder-portrait defect); every profile above
exists in `data/config/art.json` today.

---

# 15. QUESTS / TASK FEED

Use the task-feed system (`C2_TASK_FEED.md`, `QuestLog`, flat durable flags) with the
Cloudreach act/objective shape. The Stormwood has:

- one main chain of 24–30 objectives across three acts, with count-flags for the four rod
  stations (feed shows "2 of 4", no GPS route);
- six side chains (§13) — including **"Dark Stones"** (relight every Waystone),
  **"The Deepwood Circuit"** (Rook's trainer completion), **"Pim's Parcels"** (affected
  locals across Waystones), **"What the Crown Remembers"** (mystery, Archivist Wen),
  **"Glass for Bryn"** (resource), **"Across the Sink"** (Arc-Step exploration);
- at least one objective that visibly changes at `arc_step_unlocked`;
- clear completion feedback through the existing banner and reward summary.

Avoid GPS spam; the feed says what matters, the world says where.

---

# 16. LEVEL CURVE

No player scaling. Tunable in `data/config/stormwood_curve.json`, read by the same
`chapter_curve.gd` path after catalogue injection, enforced by a Stormwood copy of the
`test_chapter_curve.gd` invariants (wild high ≤ team exit; wild low ≤ team enter; catch
deficit ≤ `max_catch_level_deficit`; trainer step ≤ 4).

| Region | team enters → leaves | wild field (Calm / Surge) | authored opposition | key tools |
|---|---|---|---|---|
| 1 Cinder Verge | 33 → 35 | 30–34 / 32–35 | trainers 33–35, picket 34 | rod protection, first insulated piece |
| 2 Glowmoss Hollows | 35 → 37 | 32–36 / 34–37 | trainers 35–37, Dace 36, alpha 38 | first Waystone, TM 1 |
| 3 Conductor Run | 37 → 39 | 34–38 / 36–39 | trainers 37–39, Varga 39, Capacitor alpha 40 | insulation set, Arc-Step |
| 4 Hollow Crown | 39 → 40 | 37–40 / 38–41 | Crown guardian 41 | TM 2, Rootgate |
| 5 Deepwood | 40 → 42 | 38–42 / 39–42 | trainers 40–42, Rook ace 42, Hall guardian 43, Blackwater elder 43 | TM 3, prime orbs, Heart shrine |
| 6 Dynamo | 42 → 44 | 40–42 / 41–43 | Kestrel 42–43, Marrow 43–44 (ace 44), legendary 44 | TM 4, everything |

Stronger than Cloudreach must come from moves, composition, G-3 behaviour profiles,
terrain and the Surge, switching pressure and positional threats — not HP inflation
(`hp_strategy: normal_progression_not_hp_sponge`).

---

# 17. ENCOUNTERS AND PLACEHOLDER CREATURES

## 17.1 Placeholder rule

Every encounter slot names a **role** and a **placeholder_species** from the live Meadows
roster in `data/creatures/species.json`. Tables are `replaceable: true`. The final roster
(10–12 species, one evolution line, one legendary, per `BIOME_DESIGN_WORKFLOW.md` §8)
replaces bodies later without touching architecture, flags, or placement.

- Never field the starters (Terrapup, Ripplet, Galewisp) as wilds or trainer creatures (D72).
- Prefer the electric-, storm- and night-flavoured bodies: **Sparkit** (electric),
  **Stormtrail** (the lightning-marked Trailpup aspect, already storm-linked in
  `spawn_tables.json`), **Duskhush**, **Pipwing**, **Shadelet**, **Nightburrow**,
  **Cindercub**, **Frostclaw**, **Riftfrill**, **Brooktail**, **Mosshell**, **Veridian**,
  **Meadowhart**, **Burrowback**, **Tuskroot**, **Ashtusk**, **Galecrest**, **Reedwing**.
- Differentiate placeholders from their Meadows selves with the allowed levers only:
  vivid/alpha colourways, modest scale, emissive tint toward the Surge palette, habitat,
  behaviour profile, traits, encounter context.
- Every placeholder is listed in the final report with its exact replacement point.

## 17.2 Encounter tables (12: Calm and Surge per region)

| Table | Level | Calm roles (placeholder) | Surge roles (placeholder) |
|---|---|---|---|
| verge_calm / verge_surge | 30–34 / 32–35 | cinder_forager (bramblebun), edge_scout (pipwing), ash_digger (burrowback) | storm_runner (stormtrail), edge_scout, glass_lurker (shadelet, rare) |
| hollows_calm / hollows_surge | 32–36 / 34–37 | pool_drifter (brooktail), moss_grazer (meadowhart), blink_spark (sparkit, `blink_capable`) | blink_spark, night_glider (duskhush), pool_ambusher (riftfrill) |
| run_calm / run_surge | 34–38 / 36–39 | ridge_stalker (frostclaw), blink_spark (sparkit), vine_climber (veridian) | storm_runner (stormtrail), arc_diver (galecrest), ridge_stalker |
| crown_calm / crown_surge | 37–40 / 38–41 | crown_keeper (mosshell), blink_spark (sparkit, vivid) | crown_wisp (duskhush, vivid), glass_lurker (shadelet) |
| deepwood_calm / deepwood_surge | 38–42 / 39–42 | giant_rooter (tuskroot), canopy_hunter (galecrest), ember_scavenger (cindercub) | storm_runner (stormtrail), night_glider (duskhush), ash_charger (ashtusk) |
| dynamo_calm / dynamo_surge | 40–42 / 41–43 | fence_prowler (shadelet), conduit_gnawer (nightburrow) | arc_diver (galecrest), blink_spark (sparkit, alpha), ash_charger (ashtusk) |

Night weights raise the night_glider, glass_lurker and conduit_gnawer roles on every table.

## 17.3 Named wild encounters (six, all G-1 / G-3 / G-5 compliant)

| Encounter | Where | Level | Profile | Identity |
|---|---|---|---|---|
| Hollows Alpha | region 2 flooded route after a Break | 38 | CHARGER | a Sparkit alpha that Arc-Steps between the pool's stones every third attack (visual only until the roster lands — the behaviour override is the `reposition_distance` lever) |
| Capacitor Alpha | Capacitor Grove, Break only | 40 | DIVER | strikes land where it stood; the fight is about leaving the glow |
| Crown Guardian | Hollow Crown | 41 | WALL | a Mosshell alpha, vivid, glass-plated; blocks the heartstone |
| Old Rodfolk Hall Guardian | Deepwood optional dungeon | 43 | ACE | the one telegraph you must read; guards the Hall's Rare Candy and gear |
| Blackwater Elder | Fallen Giant ravine floor | 43 | CURRENT | relentless in the dark under the bridge |
| Glass Field Alpha | Dynamo approach | 42 | CHARGER | patrols the strike field; catching it is a legal way past |

## 17.4 Trainers (26)

Fourteen critical-path trainers (Tamsin's introduction fight, the four picket lieutenants
and officers, Varga, Kestrel, Marrow, and six Rodfolk / traveller trainers who hold
route chokepoints) and twelve optional (the Deepwood Circuit's five, three at Rodline Post,
two in the Hollows, two on the Verge). Each names mechanics from the Meadows vocabulary
(switch pressure, narrow arena, forced reposition, counter-switch, hazard lanes). Team
Tether ranks use TM-tier quicks at officer and captain only (G-4).

## 17.5 The legendary (placeholder)

Bound in the Dynamo core. Placeholder body: Sparkit at ×1.8 scale, alpha colourway, the
aspect emissive boosted, nickname **"the Stormheart"** (rename is the Creative Director's).
Level 44. It Arc-Steps. It is the single strongest catch in the chapter and the reason the
five-creature cap bites again at the end (`five_slot`). Its final art and name arrive with
the roster; the chamber, the release beat, the offer to join and the ceremony ship now.

---

# 18. FINAL CONFRONTATION — THE DYNAMO

Design and implement, as a separate authored climax controller that calls the shared fight
system (never a large generic trainer):

- **Pre-boss approach:** the Glass Field under a permanent Break; disabled upper rods gone
  dark behind; Team Tether banners; the last camp (**Ember Bivouac**, rod pre-built);
  Officer Kestrel at the Outer Works.
- **Arena identity — the Dynamo Core:** a circular turbine floor around the captive's
  containment pillar, ringed by four **capacitor banks** that charge on a visible cycle and
  discharge across lanes of the floor; three grounded **rod plates** are safe; the hum rises
  with each bank. The Surge is inside the room.
- **Stakes:** Marrow is running the Dynamo past its limit to hold the Rift; one more cycle
  and the forest's edge burns for good.
- **Phases:**
  1. *Bank Cycle* — Marrow's team fights across discharge lanes; the player reads bank
     charge and positions on plates; captain counter-switches.
  2. *Overload* — at half team, Marrow vents the core: shorter safe windows, forced switch
     decisions, Static on the exposed.
  3. *Break the Core* — team defeated, Marrow retreats to the pillar; the player Arc-Steps
     between the three plates while the floor arcs, striking four exposed conduits with the
     piloted creature before the banks re-fire.
- **Tests:** team strength, switching, bond/level investment, preparation (insulation, rod,
  revives), recovery planning, movement/combat skill, and the biome's own verb.
- **Loss** returns the player to Ember Bivouac with flags intact and no duplicated rewards.
- **Victory** (`captain_marrow_defeated`) → the pillar opens → the legendary release
  (§17.5), the offer, the ceremony → the Long Storm's last Break, then silence, then sky.

---

# 19. PROGRESSION / LEVELING / BONDING

Everything the 2026-09-04-C directive requires continues here unchanged: XP visible, level
progress visible, level-up celebration, bond progress visible during ordinary play, milestone
celebration, an understandable bond UI, companion personality visible outside combat. New
shared actions that reinforce bond in this biome: sheltering together through a Break at a
rod camp, completing a Waystone circuit, and feeding Voltcap. The player should feel the team
become strong enough to stand in a Break by the end.

---

# 20. RESOURCES, CRAFTING, GEAR, TMS

**Tier 3 — Stormwood.** Useful preparation, never a factory chain. Item definitions in
`data/items/items.json`, recipes in a new `data/recipes/recipes_stormglass.json`, gated by
dialogue flags (D43).

| Resource | Kind | Gather | Where | Uses |
|---|---|---|---|---|
| **Stormglass** | ore (fulgurite) | pickaxe; charged nodes open in Break/Fading | 2–6 | insulated gear, lightning rod, TM orb sockets |
| **Thunderwood** | wood | axe, glass-fused trunks | 3, 5 | rod mast, moss lantern, camp upgrade |
| **Conductor Vine** | fiber | knife | 1–3 | rod wiring, insulated lining |
| **Glowmoss** | herb | hand | 1, 2, 5 | moss lantern, recovery tonic, sight in the Deepwood |
| **Voltcap** | food (mushroom) | hand | 2, 5 | satiety, Static resistance, bond food |
| **Sparkfur** | creature drop | encounter reward | 2–6 | insulated gear, bond gift |

**Insulated gear** — a four-piece set (`insulated_helm`, `insulated_vest`,
`insulated_leggings`, `insulated_boots`) above the hide set: two pieces crafted at Rodline
Post from Stormglass + Sparkfur + Conductor Vine, two found (§13). Each piece reduces strike
damage and Static; the set makes a strike a stagger only. This is the "biome-specific
protection" `GAME_DESIGN.md` §21 promises, and it is preparation, not a key.

**Electric TM ladder** — mirror the shipped per-type shape (four TMs: quick 1.15, charged
1.3, charged 1.5–1.6, charged 2.0). Two moves exist (`spark_bite` 1.0, `arc_lash` 1.05);
author four TM-tier moves in `data/moves/moves.json` with the existing schema:
`static_snap` (quick 1.15), `arc_lash` promoted to TM tier only if its number is raised, else
`voltaic_whip` (charged 1.3), `thunder_break` (charged 1.6), `stormfall` (charged 2.0);
items `tm_static_snap`, `tm_voltaic_whip`, `tm_thunder_break`, `tm_stormfall`, type-coloured
orbs through the existing TM orb path. A TM is an item and it is spent (D44).

**≥ 12 recipes**: the four gear pieces, lightning rod, moss lantern, rod mast, insulated
workbench upgrade, Voltcap stew, glowmoss tonic (recovery), stormglass orb socket (prime
orb), and a Waystone repair kit (a story-gated recipe for "Dark Stones").

---

# 21. BUILDING / CAMPING

Camping matters more than in Cloudreach without any change to satiety
(`satiety_policy: reuse_existing_slow_nonlethal_drain`).

- **Lightning rod** (new buildable; Thunderwood mast + Stormglass + Conductor Vine): a placed
  rod makes a 12 m radius surge-safe; the six authored camps have one pre-built; the ten
  rod-able clearings do not.
- **Moss lantern** (new buildable): light and a small bond/rest bonus in the Deepwood dark.
- **Insulated workbench** upgrade at the player's camp: unlocks the gear recipes away from
  Rodline Post.
- Build v2 snap/dismantle rules unchanged; multiple satchels persist; beds/creature beds
  work under canopy.
- Long distances, the Surge and the Deepwood dark create the recovery pressure; hunger does
  not.

---

# 22. MAP / NAVIGATION

Realm-keyed `MapState` (the Cloudreach audit's map-isolation seam), `map_stormwood.png`,
fog, landmarks and regions per §12–13. The player must recognise the six regions from the
world before the map: the Struck Sentinel, the Lantern Pools' glow, the rod towers over the
ridge, the Crown's lit ring, Lantern Hollow's lanterns under the giants, the Dynamo's
chimneys. Unlock events: `arc_step_unlocked` reveals the Waystone network on the map;
`rootgate_released` reveals the Deepwood; `stormwood_upper_rods_disabled` reveals the Dynamo
approach; `stormwood_storm_broken` reveals the Waterward view. Waystone travel uses the map
screen to pick a destination, controller-first.

---

# 23. AUDIO / ATMOSPHERE

Wire the system now; use installed assets and mark bespoke gaps non-blocking, as
Cloudreach did. Ten cues: canopy rain, distant thunder (Calm), rising hum (Building), strike
crack + close thunder (Break), fading roll and steam (Fading), moss-lit stillness (Still
Grove, Crown), rod-line hum (near rod stations; `tether_drone.wav` is the installed
placeholder), settlement (Lantern Hollow), Dynamo escalation, Dynamo music
(`music_warden.wav` placeholder). Aftermath mix: drone gone, thunder rare and distant, birds
return under the canopy.

---

# 24. ART / ASSET RULES

Priority: installed assets, then suitable free-pack assets already in the tree, then
owner-approved generated assets with reference art. One nature family, one village family,
one prop family. No new creature meshes. No Meshy without reference art; the Dynamo core is
the only candidate and ships kitbashed until a board exists. For structural art gaps write
explicit art briefs in `docs/art/`, never vague TODOs. Trees are tall (D74); creatures stand
taller than the trainer; fix scale by growing the smaller side.

---

# 25. SAVE / STATE REQUIREMENTS

Everything survives save/load and realm travel, under the `stormwood:` namespace and the
realm-aware persistence the Cloudreach audit specifies:

Key to the Stormwood earned; Stormward gate discovered/unlocked; chapter started; every act
and objective flag; the Surge phase and timer; each rod station's state; each Waystone's
lit state and visited state; `arc_step_unlocked`; Rootgate released; trainers defeated;
named encounters beaten/caught (once-only); pickups collected by `pickup_id`; harvest
records; charged-node state; camps discovered; rods and lanterns built; side-chain
progress; shortcuts opened; Kestrel and Marrow state; legendary freed/joined/released;
Heart earned/placed/active; the storm broken; NPC post-storm states; the Waterward reveal.
Add migration and defaults so Meadows-only and Cloudreach-only saves load cleanly, and
migrate `realm_key_water` to `realm_key_stormwood` (§5).

---

# 26. TESTING REQUIREMENTS

Code existing is not completion. Unit tests (in `tests/`, run through `run_tests.gd`) for:

Cloudreach reward retarget and save migration; Stormward gate key gating and non-consumption;
realm transition both ways; `stormwood_world.json` and `stormwood_chapter.json` contracts
(a `test_stormwood_chapter_data.gd` in the shape of the Cloudreach test, plus the §13 count
minimums as assertions against the data); the level-curve invariants; the Surge state
machine and its region modifiers; strike telegraph, shelter and damage bounds; rod safe
radius; Arc-Step eligibility, range, line of sight, lit-anchor rule, arrival grounding,
combat lock, slot cost; Waystone travel rules; Rootgate release; rod-station disable
effects; pickup identity and persistence; harvest identity; camp restore; named-encounter
once-only; trainer defeat persistence; the Dynamo phases and loss recovery; legendary
release, offer, ceremony when full; Heart earn/place/Livewire/single-active/swap; aftermath
state; save/load of every §25 item.

Smoke: `smoke_stormwood_foundation.gd` (real scene, regions, landmarks, routes, collision,
player grounded), `smoke_stormwood_transition.gd` (Cloudreach → Stormwood → Cloudreach →
Meadows), and a **continuous `smoke_stormwood_chapter.gd`** that drives the whole chapter
Act I → Arc-Step → Crown → Rootgate → rods → Dynamo → legendary → Heart with a real body,
whose reliable prefix gates in CI. A CI run under five minutes verified nothing.

---

# 27. VISUAL VALIDATION

Every major visual batch is implemented, captured from the real gameplay camera on real
route frames, judged code-blind against the two bars (belongs to the Meadows key art's
world; looks like the same kind of game as the Palworld references), and revised. Eight
required review points: first Stormwood reveal under the canopy; Cinder Verge in a Break;
Glowmoss Hollows in Calm at night; the Conductor Run's rod line; Arc-Step in flight; the
Hollow Crown across the Glass Sink; Lantern Hollow; the Dynamo core. The Stormwood does not
advance past its foundation until the environment review materially closes the gaps, as
the owner required of Cloudreach.

---

# 28. PERFORMANCE

A forest is expensive in a different way from cliffs: instanced trees, emissive materials,
ground-cover density, weather VFX, strike lights and shadows. Profile against the Meadows
Hall reference ceiling (4,000 draw calls) and the ROG Ally target
(`docs/specs/PERFORMANCE_BUDGET.md`) at every review point; budget the canopy with
MultiMesh, LOD and the existing structure-visibility ranges; cap simultaneous strike lights;
never `--headless` with a rendering driver. Beautiful editor scenes that fail on the Ally do
not count.

---

# 29. BRANCH / PR / INTEGRATION MODEL

Never push to `main`. For each bounded task: branch from current `main`, own explicit files,
implement, test, validate, commit, push, open a PR, review the actual diff, merge verified
work, verify integrated `main` with `git merge-base --is-ancestor`. Land continuously; do not
leave finished branches unmerged; dependent work branches from the latest integrated `main`.
If a Stormwood change conflicts with in-flight Cloudreach work, Cloudreach's completion wins
and the Stormwood rebases.

---

# 30. AGENT DELEGATION

Delegate: tables and catalogues, NPC dialogue drafts, pickup and harvest placement, trainer
data, objective data, recipes, tests, capture runs, bug investigations, placeholder
integration, regional dressing, map pins, save-migration tests, tuning slices.
Retain: chapter story, world composition, the Surge and Arc-Step architecture, gating,
major encounter design, the Dynamo, integration, visual acceptance, final acceptance.

---

# 31. EXECUTION ORDER

## Phase 0 — Reconcile
Verify clean `main`; inspect open branches; land or rebase on Cloudreach; update biome-order
docs (§0.1, §5); confirm the Cloudreach seams (persistence, 3D placement, dialogue manifest,
catalogue injection, map isolation) exist on `main` or open them first — the Stormwood must
not re-learn that audit.

## Phase 1 — Cloudreach handoff
Reward retarget; Stormward Overlook; the Stormward gate; realm registry; save migration;
transition smoke.

## Phase 2 — World foundation (Terrain3D first)
Heightfield; the six regions; routes, loops, shortcuts; root bridges; landmarks; settlements
massing; scatter bake with forest layers; canopy; the Glass Sink and Crown; the Dynamo mass;
the eight review captures; the blind judge; iterate until the environment passes.

## Phase 3 — The Surge and the hazard
Weather extension, four phases, region modifiers, light and audio, strike telegraph and
damage, shelter, rod buildable, insulation items, HUD glyph, tests.

## Phase 4 — Core chapter content
NPCs, dialogue, main chain Act I, trainers, pickets, encounter tables with placeholders,
harvest and charged nodes, pickups, camps, side chains, Waystones (lit/unlit), density
census against §13.

## Phase 5 — Arc-Step
Mechanics, controls, VFX, unlock trial, Waystone travel, the Crown, Rootgate release,
tests, bond rule.

## Phase 6 — Deepwood and the Dynamo
Lantern Hollow, shrine, upper rods, optional Hall dungeon, the Circuit, Kestrel, the Dynamo
climax, legendary release and ceremony, Heart, aftermath, Waterward reveal.

## Phase 7 — Evidence and polish
Continuous chapter smoke; route strip and blind judge on all eight points; balance pass on
the curve; persistence pass; performance pass; docs (`CURRENT_STATE.md`, `ROADMAP.md`,
`WORLD_AND_CONTENT.md`, `GAMEPLAY_SYSTEMS.md`, `realm_hearts.json` comments); final `main`
verification.

Do not wait until the end to integrate.

---

# 32. EXIT CRITERIA — THE STORMWOOD IS DONE WHEN

Every line below holds on `main`, with evidence, on the continuous player path. A line with
a **fails if** is scored by a blind run, not by inspection.

1. **Entry.** A completed-Cloudreach save reaches the Stormwood through the Stormward gate
   with the Key, and can return. *Fails if* a debug path is the only way in, or the gate
   opens without the Key.
2. **First minute.** The first frame under the canopy says "forest" and "storm" without a
   caption; the Surge is audible; the first landmark is visible. *Fails if* the judge reads
   it as the Meadows grove or as Cloudreach.
3. **The Surge changes play.** A blind tester names the phase from sound and light, meets
   different things in a Break than in Calm, gathers something only a Break opens, and
   shelters on purpose. *Fails if* the storm is decoration.
4. **Arc-Step is required and remembered.** The Hollow Crown is unreachable by walking,
   riding, jumping or Fly; after the Still Grove trial it is reached by Arc-Step; the tester
   can say what changed about the map afterwards. *Fails if* any grounded route or exploit
   reaches the Crown, or Arc-Step works before the trial.
5. **Every player can complete it.** A Terrapup or Galewisp starter completes the chapter
   through a caught blink-capable creature. *Fails if* the chapter requires Ripplet.
6. **The story runs.** All three acts, every objective, every side chain, every NPC state,
   the four rod stations, the truth at the Crown, the Rootgate, the Dynamo, the release,
   the ceremony when full, the Heart, the aftermath and the Waterward reveal run in order
   from the task feed with no dead ends. *Fails if* any objective needs a console or a
   re-load to advance.
7. **Density meets §13.** Every count and gap rule holds by census and by the walked route
   probe. *Fails if* any minimum is under, if the critical-path worst gap exceeds 120 m, or
   if the route strip shows a stretch of only holding forward longer than 45 s.
8. **The curve holds.** The §16 invariants pass; a five-creature team that spends every
   candy cannot break a gate; a late catch is worth arguing for; the legendary makes the
   cap bite. *Fails if* any wild out-levels the region's exit level, any trainer out-levels
   Marrow, or a candy spend skips an authored fight.
9. **Encounters have identity.** All six named encounters and the Dynamo pass the G-1
   three-sentence test on the evidence template. *Fails if* any answer is "bigger", "more
   health", "looked different" or "nothing".
10. **The hazard is fair.** No strike is unavoidable, unannounced, or lethal from full
    health at the expected level; rod camps are never struck; insulation is felt. *Fails if*
    a blind run dies to a strike it could not see coming.
11. **Camping matters.** A tester who tries to push through regions 3–6 without a rod camp
    is set back by a Break and learns; one who builds is not. Satiety is unchanged.
    *Fails if* the pressure comes from hunger, or if findables erase it.
12. **Realm Heart.** The Heart is earned, placed at Lantern Hollow, Livewire works and is
    measurable, only one power is active, swapping works, all persists. *Fails if* two
    powers stack or the Cloudreach slot lies about its power.
13. **Persistence.** Every §25 item survives save/load, realm travel and an old-save
    migration. *Fails if* a one-time reward respawns, a satchel lands in the wrong realm,
    or a Meadows-only save crashes.
14. **Visuals pass.** All eight review points pass both blind-judge bars on real route
    frames from the shipping build. *Fails if* any view is judged a prototype, or if only
    posed shots were judged.
15. **Performance.** Every review point is within the Hall ceiling and the Ally budget with
    grass and canopy on. *Fails if* it passes only in the editor.
16. **Evidence exists.** Unit suite green on first attempt, the three smokes pass, the
    continuous chapter smoke's prefix gates in CI, a full CI run over five minutes, the
    judge verdicts and the performance file are committed under `ralph/reports/`, and
    `docs/CURRENT_STATE.md` describes reality. *Fails if* a claim has no run behind it.
17. **Placeholders are listed.** Every placeholder body and the legendary carry an exact
    replacement point in the final report and in `stormwood_chapter.json` comments.
18. **It points onward.** The game ends the chapter looking at water, not entering it.
    *Fails if* the Water biome is enterable or absent from view.

A biome is not done because its folders exist. It is done when the complete player path
produces the intended Tetherbound experience.

---

# 33. INTENTIONALLY DEFERRED

- the final Stormwood creature roster (10–12 species, one evolution line);
- the legendary's final body, name and animations;
- a Meshy Dynamo core hero object (needs owner reference art);
- the Cloudreach Heart's power definition;
- the Water biome.

Placeholders must let the entire chapter function. The missing roster is not permission to
leave anything else incomplete.

---

# 34. REQUIRED FINAL REPORT

Before ending the goal, provide: current `main` SHA and merge confirmation; open branches
and why; the Cloudreach handoff status; for each of world, Surge, hazard, Arc-Step, Crown,
story, NPCs, trainers, encounters, objectives, resources, gear, pickups, camps, Dynamo,
legendary, Heart, aftermath, Waterward setup — classify **proven / implemented but unproven
/ blocked / intentionally deferred**; the evidence list (tests, smokes, continuous run,
judge verdicts, performance); every placeholder with its replacement point; the §13 census
table with actuals beside minimums; and the highest-value remaining work if anything is
short. If the Stormwood is truly complete except creature art, say so plainly.

---

# 35. CORE PRINCIPLES

Build the chapter, do not describe it. Terrain3D and baked scatter from day one; never a
box-and-cylinder forest. Integrate continuously. Evidence over assumptions. The Surge must
change what the player does. Arc-Step must change the player's understanding of the map. Lit
from within, never dark for its own sake. Designed density over empty acreage. The Heart must
feel like a realm reward. The Stormwood must feel like the third chapter of the same game.

Do not stop at architecture. Do not stop at scaffolding. Do not stop at "ready for
implementation."

**Finish the biome.**
