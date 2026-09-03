# RG17 — Continuous tether-pylon navigation spine

## Goal
Turn Team Tether's energy pylons into a clear, continuous world-space navigation spine through the Meadows so that, after the village tournament, the player can physically follow the enemy infrastructure toward the stronghold route instead of depending only on HUD text or map markers.

This is **not** a magical breadcrumb trail. It is environmental storytelling doing double duty as navigation: the pylons are part of the fiction, they visibly drain the land, and their placement should naturally pull the player onward.

## Owner decisions — locked

- RG16 now establishes the progression sequence:
  1. starter / first catch;
  2. build a team for the local village tournament;
  3. enter and win the tournament;
  4. then head east toward the bridge / Team Tether route.
- RG17 is the world-space reinforcement for that post-tournament journey.
- Tether pylons should form a **continuous, readable line** that the player can follow toward the stronghold.
- An NPC near the beginning of the pylon route should explain in simple terms that the pylons are draining the land, so the player understands both what they are seeing and why following them matters.
- The pylon line should guide, not replace exploration. Do not add a glowing GPS trail, floating arrows, or giant waypoint beam.

## Current state / repo evidence

The Meadows already has the correct pylon visual language and a functioning pylon builder. Do **not** invent a second pylon system.

Important current evidence:

- `CLAUDE.md` explicitly reserves Meshy hero assets for Team Tether objects including pylons, relay apparatus, and the tether machine. Reuse the existing pylon family; do not source a generic substitute.
- `data/config/old_quarry.json` already defines an unbroken, lit pylon run at the Old Quarry and states the narrative intent clearly: this is **present-tense machinery doing present-tense harm**, and the player should see "a line of live pylons walking away over the hill on the stronghold's own bearing."
- That file also documents the existing implementation seam: SF33's Tether Energy Pylon and conduit spans are built by the existing severed-spoke/pylon builder and reused by `old_quarry.gd`.
- Current Old Quarry pylon positions are tied to `terrain_playground.json` drain stations. Keep terrain/drain/pylon coordinate ownership coherent rather than creating unsynchronized duplicate lists.
- `data/config/map_landmarks.json` already defines the chapter's major geographic progression in the long corridor world: village, South Bridge, Old Quarry, Burrow Warrens, Tether Relay, Old Mill Crossing / Long Water, and Meadows Hall stronghold.
- The current world is long (stronghold landmark around Z 7560), so four pylons at one quarry are not enough to function as a chapter-long navigation grammar.

Before changing anything, inspect current `main` for:

- `data/config/old_quarry.json`
- `scripts/world/old_quarry.gd`
- the existing shared pylon/conduit builder (documented by current code/comments as the same builder used for severed spokes)
- `scripts/world/severed_spokes.gd` or its current equivalent
- `data/config/terrain_playground.json`, especially `drains` and authored road/crossing coordinates
- `data/config/relay_site.json` and `scripts/world/tether_relay.gd`
- stronghold configuration and stronghold approach files
- all band-local `props.json` / world-authoring data that may already contain Team Tether infrastructure
- `data/config/map_landmarks.json`
- `docs/specs/MEADOWS_MACRO_LAYOUT.md`
- `docs/specs/MEADOWS_PROGRESSION_SPEC.md`, especially the reveal ladder / Team Tether environmental-storytelling sections
- RG16 prompt and whatever RG16 implementation has landed by execution time
- current RG19 tournament state/flag, if landed

## Desired player-facing experience

### Before the tournament
Do not prematurely turn the pylon chain into the player's main route if the intended first major goal is still the local tournament.

The infrastructure may already be visible in the distance or around existing sites, but the objective/navigation emphasis stays on tournament preparation until the tournament has been won.

### Tournament victory handoff
After tournament victory, RG16 should make the player's major objective eastbound / Team Tether-facing.

At or shortly after that handoff, the player should encounter the first clearly readable active pylon line.

An appropriate NPC near the beginning of this route should communicate the minimum fiction needed, along the lines of:

- Team Tether put these pylons across the land.
- They are draining energy from the Meadows.
- Follow the line and you will find where that energy is going / where Team Tether is operating.

Do **not** dump the full reveal-ladder explanation early. Existing progression docs intentionally reveal the system in stages. The NPC should explain the navigation-relevant truth without spoiling relay/stronghold discoveries.

### Following the line
From normal third-person gameplay, the player should usually be able to answer:

> "Which pylon do I head toward next?"

without opening the map every 20 seconds.

That means pylon spacing and siting must be authored around **line-of-sight continuity**, not just mathematical regularity.

A good chain can bend around hills, water, roads, gates, and authored content. It does not need to be perfectly straight. It does need to remain visually traceable.

The next pylon should normally be visible from the current pylon or become obvious within a short movement around the obstruction. Avoid long dead gaps where the player reaches one pylon and has no idea where the chain continues.

### Major content beats
The line should support the existing Meadows progression rather than bulldoze through it.

Use the authored corridor and major landmarks as anchors. The pylon grammar can help pull the player through / toward content such as:

- the first bridge/gate area;
- Old Quarry evidence;
- the relay region;
- later river/crossing content;
- upper Meadows / stronghold approach;
- final stronghold infrastructure.

Do not make the pylon chain a shortcut that lets the player walk around required gates or bypass trainer/bridge/terrain progression.

## Pylon siting rules

### 1. Continuous visual handoff
Author the chain so adjacent pylons read as one system.

At each significant waypoint, test the actual gameplay camera from ground level. The acceptance test is visual, not merely coordinate distance.

Good:
- current pylon visible;
- next pylon clearly identifiable ahead;
- line bends naturally with terrain;
- conduit / repeated shape language reinforces the connection.

Bad:
- next pylon hidden behind a hill for hundreds of metres;
- line disappears across empty meadow and restarts later with no clue;
- pylons are technically aligned on a map but invisible from the player's route;
- line points into an impassable cliff or across an unavailable crossing.

### 2. Terrain-aware, route-aware placement
Use walkable ground and the authored road/gate topology.

Do not flatten major terrain merely to make a straight pylon line. Move/bend pylons to the terrain unless a specific Team Tether installation already justifies terrain work.

Respect:
- bridges and gated crossings;
- rivers/gullies;
- trainer gates;
- cliffs and collision;
- authored trails;
- landmarks and composition sightlines.

### 3. Reuse the existing visual grammar
The Old Quarry already defines the active-line grammar:

- intact pylons;
- lit / active;
- conduit spans where appropriate;
- repeated Team Tether material language.

Keep this distinct from the severed-spoke grammar where dead/broken infrastructure communicates old severance.

Do not casually redesign the pylon asset in RG17.

### 4. Do not spam the landscape
"Continuous" does not mean a pylon every few metres.

Spacing should be as wide as the terrain and visibility allow while preserving an obvious visual handoff. This is important for both composition and ROG Ally performance.

Treat spacing as tunable data where possible.

### 5. Stronghold bearing without rigid straight-line math
The existing Quarry data explicitly describes pylons heading on the stronghold bearing while bending to walkable ground. Preserve that philosophy chapter-wide.

The player should feel that all active lines are feeding the same Team Tether network, not that somebody drew a perfectly straight fence across the biome.

## Environmental-storytelling requirements

The pylon chain is not just signage.

Where appropriate, reinforce that these objects are affecting the land through systems/art that already exist or are already specified:

- drained/altered ground around stations;
- conduits or energy-routing hardware;
- active light/energy state;
- site composition that reads as installed machinery rather than ruins.

Do not invent a completely new ecological damage simulation for this item. Use existing terrain/art/drain conventions.

The reveal ladder must remain intact:

- early: pylons are visibly wrong and someone tells you they drain the land;
- quarry: evidence of extraction/routing;
- relay: larger Team Tether operation;
- stronghold: full destination/payoff.

## NPC handoff

Add or update the minimum appropriate NPC dialogue near the first meaningful post-tournament pylon route.

Requirements:

- short;
- readable by a child/new player;
- tells the player the pylons drain the land;
- gives a practical directional clue: follow them / they lead toward Team Tether;
- does not explain the whole conspiracy or stronghold machinery too early.

Reuse an existing NPC/rig/location if one fits. Do not generate a new human just to deliver two lines.

If RG16 already puts a suitable NPC/tournament organizer on the route, consider extending that existing conversation instead of creating a redundant character.

## Relationship to map/minimap

The pylon line is primarily **world-space** navigation.

RG15 owns minimap orientation and full-map zoom/pan.
RG16 owns the major objective state and objective marker.
RG17 should complement both:

- HUD says what the player is trying to accomplish;
- map shows the strategic destination;
- pylons show how the enemy network physically runs through the world.

Do not add every individual pylon to the map as a landmark unless current design/docs explicitly call for that. A map cluttered with dozens of pylon icons defeats the purpose of environmental navigation.

## Data / architecture

Prefer data-driven authored pylon runs using the existing builder.

Do not create a new scene/script per pylon.

Where pylon positions correspond to terrain drain stations or other authored Team Tether infrastructure, maintain a single clear ownership rule and update all coupled data together. The current `old_quarry.json` comments explicitly call out the risk of pylon/drain coordinate drift; honor that warning.

If the existing pylon builder only supports short local runs, extend it minimally so multiple authored runs can use the same visual/connection logic. Do not over-generalize into a procedural power-grid simulator.

## Preserve

- Existing SF33 pylon asset / Team Tether hero-object family.
- Old Quarry's current unbroken, active run and its reveal-ladder role.
- Severed/dead pylon language where existing content intentionally uses it.
- Existing road/gate/bridge progression.
- Tether Relay and stronghold content.
- Existing terrain/drain authoring ownership.
- ROG Ally performance budget.
- RG16 tournament-first progression.
- RG15 map/minimap responsibilities.
- RG19 tournament mechanics responsibilities.

## Do not

- Do not replace pylons with generic signs/arrows.
- Do not add a glowing ground breadcrumb trail.
- Do not add giant floating objective beams.
- Do not make every pylon a map icon.
- Do not create a second pylon asset/system.
- Do not bypass progression gates by routing the chain around them.
- Do not reveal stronghold/relay story details too early through NPC exposition.
- Do not place pylons by coordinate spacing alone without in-engine sightline verification.
- Do not flood the long corridor with unnecessary geometry that harms performance.

## Edge cases

- Player explores far east before winning the tournament.
  - Existing world geometry may still exist; objective state remains tournament-first.
- Player approaches a gate from the wrong side by unusual traversal.
  - Pylons must not create or expose a trivial bypass.
- Night/fog/weather reduces visibility.
  - Active pylons should remain sufficiently recognizable through their existing light/material language without becoming giant beacons.
- Terrain changes after this prompt is written.
  - Re-evaluate sightlines on current `main`; do not blindly keep coordinates from an older layout.
- A long sightline makes the next two or three pylons visible.
  - Fine, as long as it reads as a coherent line rather than clutter.
- A hill blocks the direct chain.
  - Bend the run around/over the readable route rather than cutting a tunnel through the hill.
- Existing drain stations and pylon positions disagree.
  - Diagnose and reconcile the source-of-truth relationship; do not knowingly ship drift.

## Acceptance criteria

1. After the village tournament is won and RG16 sends the player eastward, the player encounters an obvious active Team Tether pylon route.
2. A nearby NPC or existing dialogue clearly tells the player that the pylons drain the land and that following them leads toward Team Tether activity.
3. From one pylon, the next intended pylon/direction is normally visually legible from ordinary gameplay camera height, with no long unexplained gaps.
4. The chain remains readable through the major Meadows progression corridor all the way toward the stronghold approach, using multiple terrain-aware runs if necessary.
5. The line does not bypass required bridges, gates, trainer fights, river crossings, or progression barriers.
6. Old Quarry pylons remain intact, lit, and consistent with their current evidence/reveal role.
7. Existing severed/dead pylon content remains visually/narratively distinct.
8. Pylon/drain/conduit positions stay synchronized according to the repo's existing ownership conventions.
9. No duplicate pylon system, map-clutter system, or GPS trail is introduced.
10. The feature performs acceptably on the ROG Ally / compatibility renderer.

## Testing / verification

### Code/data tests
Run the tests named by the current backlog item plus any existing world-authoring/content validation touched by the change.

Add focused validation where useful for:

- pylon data parses and references valid builder/assets;
- authored runs have at least two pylons where continuity is intended;
- no accidental duplicate IDs/orders if band-local data is used;
- drain/pylon coupling remains valid where the current architecture expects matched stations;
- progression gates remain intact.

Do not pretend a coordinate-distance unit test proves navigation quality.

### Traversal test
Perform an actual in-engine traversal on current Meadows from the first post-tournament route through the stronghold approach.

At each authored pylon/run transition, record whether the next target is visible/obvious from player camera height.

The critical test is:

> Starting without map knowledge, can a player follow the Team Tether infrastructure forward without repeatedly stopping to guess where the line went?

### Visual verification — required
This is visual-affecting world work, so follow `docs/AGENT_WORKFLOW.md`:

1. capture representative in-engine frames of the line from gameplay viewpoints across multiple bands;
2. include at least one transition where terrain forces the chain to bend;
3. include day and a darker period if pylon emissive/readability changes materially;
4. run the repository's blind visual-judge workflow;
5. fix named defects and iterate according to the convergence rule.

Specific visual questions for the critic:

- Does this read as one intentional Team Tether network?
- Is the next direction obvious without UI arrows?
- Are pylons too sparse, too dense, or compositionally noisy?
- Do they look like active machinery rather than generic fence posts?
- Does the line work with the terrain instead of fighting it?

## Definition of done

RG17 is done when Team Tether's pylons function as a coherent chapter-long piece of environmental storytelling and navigation:

**tournament victory -> eastbound objective -> first active pylon line -> follow the draining infrastructure through the Meadows -> Team Tether relay/stronghold route**

The player should understand both **what the pylons are doing** and **why following them is the right direction**, without the game resorting to a magical breadcrumb trail.