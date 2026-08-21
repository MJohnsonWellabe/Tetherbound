# Owner playtest — 2026-08-21 ROG Ally

This is the newest owner-play priority overlay for the Meadows and **supersedes older positive assumptions wherever this playtest conflicts with them**.

The owner played the current build on the ROG Ally and found the following issues. Treat these as **Gate A reopen/blocker items unless explicitly noted otherwise**. Gate A must not be declared complete while these current owner reproductions remain unresolved or unverified on the real shipped/control path.

## P0 — ROG performance / controller ownership / hard play blockers

### OP21-01 — ROG Ally performance is unacceptably laggy
- Current game is "super laggy" on the ROG Ally.
- Gate A evidence must include target-hardware performance, not only desktop/headless correctness.
- Diagnose actual frame-time/GPU/CPU pressure and fix the dominant causes without destroying approved environment composition.
- Preserve the lush pond-side pocket and deliberate open-field contrast; do not solve performance by globally stripping the world.

### OP21-02 — Satchel input leaks into hotbar
- While the Satchel is open, the same controller input also moves/changes hotbar state.
- Modal UI must own its controls exclusively; gameplay/hotbar actions must not fire underneath an open inventory/menu.
- Add a real controller regression covering Satchel navigation while hotbar state remains unchanged unless explicitly selected through the Satchel UI.

### OP21-03 — Build shortcut opens menu but controller still cycles creatures
- Opening Build through the shortcut does not transfer controller ownership to the Build menu.
- Inputs cycle active creatures instead of navigating Build.
- Fix modal/input routing so Build owns navigation immediately and exploration/party-cycle actions are suppressed until Build closes.

### OP21-04 — Settings menu still cannot be fully navigated by controller
- Owner cannot reliably scroll through settings on ROG Ally.
- Teleport destination list in Settings also does not scroll on ROG Ally.
- Gate A controller audit must prove every reachable settings control/list is reachable, scrollable, adjustable, and escapable by controller.

### OP21-05 — First village trainer battle loses camera control
- On the first trainer battle in the village, normal camera control stops when combat starts.
- This is a fresh reproduction against the shipped path; reopen combat-camera acceptance even if prior smoke tests passed.
- Regression must enter the actual first village trainer battle through normal play/controller input and prove orbit/look control during combat and correct restoration afterward.

### OP21-06 — Controller binding collisions remain
- Active-companion cycling shares inputs with hotbar buttons.
- Menu/cycle transitions look confusing and appear to fire overlapping actions.
- Audit the complete controller action map for context conflicts across exploration, hotbar, Build, Satchel, menus, combat, and party cycling.
- A button may be reused across mutually exclusive contexts only when ownership is deterministic and no hidden action fires.

### OP21-23 — Load Game does not resume into play
- Choosing Load Game can enter the menu/home UI but never transition into the loaded world; the game then just sits there.
- Treat this as a Gate A save/load/front-door blocker, not a cosmetic title issue.
- Reproduce from the actual shipped title/load flow with a real save, prove scene transition completes, world controls become active, and saved state/position are restored.
- Add regression coverage for title -> Load -> selected save -> playable world, including controller focus handoff away from the menu.

## P0/P1 — Build system correctness and scale

### OP21-07 — Building rotate does not work
- Rotate input is shown/expected but does not rotate placed preview/build pieces reliably.
- Fix the real controller path and add a placement regression proving visible orientation change and successful placement at the rotated orientation.

### OP21-08 — Doors are not usable and modular scale is wrong
- Doors are not openable.
- Door/build-piece sizing does not make sense relative to the trainer and authored buildings.
- Owner expectation: the free-build kit should be capable, in principle, of reproducing a house at Grandpa-house scale/proportions.
- Reconcile floor, wall, doorway, door, and roof dimensions around a coherent module rather than patching individual anchors.

### OP21-09 — Roof pieces appear to be the wrong size
- Roof geometry/proportions do not match the modular wall/floor footprint cleanly.
- Include roof dimensions and overhang in the modular-kit audit.
- Gate A 2x2 house evidence should produce a visually coherent roof, not merely technically snapped pieces.

### OP21-10 — Free building implies free crafting in the current mode
- Owner expectation: if building is intentionally free in the current game/test mode, crafting should also be free.
- Do not create inconsistent friction where structures cost nothing but prerequisite crafting consumes resources.
- Reconcile the current economy/mode contract so free-build and crafting rules are coherent and clearly communicated.

## P1 — HUD / menus / readability

### OP21-11 — Move major hotkeys under the hotbar and make them legible
- Build, Map, and similar major shortcut prompts should sit under the hotbar.
- Keys/buttons should be larger and more legible at ROG Ally viewing distance.
- Treat handheld readability as the acceptance target, not desktop-only legibility.

### OP21-12 — Party/menu cycling presentation is confusing
- The menus/UI shown while cycling active companions look strange; owner cannot tell what is happening.
- Redesign the cycle feedback so previous/next creature selection is immediately understandable and does not resemble broken menu state.

### OP21-13 — Replace remaining "Pal" terminology
- UI still says "Change Pal".
- Tetherbound terminology is **creature**, not Pal.
- Audit reachable player-facing strings and replace inappropriate Pal terminology with Creature/current game language.

### OP21-14 — Team count is wrong after catching
- Owner caught three creatures but team HUD showed `2/5` rather than `3/5`.
- Verify catch -> party add -> HUD refresh -> save/load state using the real capture path.
- Party count and visible portraits/slots must agree with actual team membership immediately after a catch.

## P1 — Map / navigation / opening clarity

### OP21-15 — Map is currently unusable
- Owner cannot see useful information on the map.
- Zoom does not center/zoom around the player's current location as expected.
- Improve contrast/readability of terrain, roads/trails, landmarks/objectives, player position, and relevant map content at handheld resolution.
- Zoom behavior should preserve the player's location as the meaningful focal point unless the player deliberately pans elsewhere.
- Prove controller pan/zoom/reset/current-location behavior on ROG-style controls.

### OP21-16 — Opening direction remains too unclear
- It is still difficult to know where to go or what to do near the beginning.
- Minimum current guidance should explicitly communicate the next meaningful actions such as gathering wood/stone, building, preparing for/entering the tournament, and traveling toward the pond/next intended location as appropriate to the authored progression.
- Gate B owns the full polished first-session ladder, but Gate A cannot pass with the current owner-described state of being unable to tell what to do.
- Implement enough objective/HUD/NPC guidance now that normal opening play is understandable without external instructions; Gate B can deepen pacing and presentation afterward.

### OP21-26 — Pond-to-village route is long, bare, and boring
- If the intended post-tournament route sends the player between the village and pond, that stretch currently feels like empty traversal rather than gameplay.
- Populate and compose the route with meaningful reasons to stop: wild creatures, trainers/NPCs, gatherables/resources, landmarks, side interactions, visual pulls, and/or camp/build opportunities appropriate to the progression.
- Do not simply carpet the route with random density. Author a paced sequence with open breathing room, readable landmarks, and recurring gameplay purpose.
- Gate A only needs the opening area representative enough to judge honestly; the full post-tournament cadence belongs to Gate B/C and the D1 Lower Meadows package. Keep this item in the backlog until that route no longer reads as dead walking.

## P1 — World composition / environment correctness

### OP21-17 — Village shape/layout makes no sense
- Current village footprint/road/building arrangement does not read as a believable or navigable settlement.
- Rework the opening village composition so roads, building fronts, paths, signs, gathering spaces, and exits have understandable spatial logic.
- Preserve gameplay routes and required NPC/building access while improving composition.
- This is not a request for final whole-Meadows polish; it is a Gate A readability/believability blocker in the representative opening area.

### OP21-18 — Signs should sit beside roads, not in the road
- Move roadside signs off the travel lane and place them naturally at shoulders/intersections.
- Preserve readability without obstructing movement.

### OP21-19 — Pond contains misplaced world objects
- Pond water itself looks good.
- Trees, houses, bushes, and/or other world props are visibly occupying/submerged in the water incorrectly.
- Audit pond footprint against vegetation/structure placement and remove/reposition implausible objects while preserving the approved lush shoreline pocket.

### OP21-20 — Submerged player should take damage
- Fully submerging the trainer in water currently has no meaningful consequence.
- Add the intended water hazard/damage behavior for unsafe submersion, with clear feedback and without making ordinary shoreline contact punitive.

### OP21-21 — Washed-out grey time-of-day state
- After several minutes of play, the game entered a washed-out/grey visual state.
- Owner noticed it immediately after building the first workbench, but causation is unknown.
- Reproduce over the live day/night cycle and around build placement; identify whether this is lighting/environment transition, post-processing, weather/state, exposure, or a build-event side effect.
- Gate A day/night readability should reject any sustained washed-out grey state that makes the game look broken or materially degrades readability.

## P0/P1 — Gathering presentation

### OP21-24 — Axe hold and swing still do not look right
- The trainer does not hold the axe in a believable expected grip/pose.
- The owner still does not see a convincing chopping swing during normal gathering.
- Reopen the equipped-tool presentation requirement even if focused gathering tests are green.
- Verify on the actual player path that the axe is visibly in hand before the hit, the animation reads as a deliberate swing through the target, and the hit/result is synchronized with that visible action.

## P0 — Combat arena containment

### OP21-25 — Stronghold and Burrow Warrens fights can phase outside the arena
- In some fights in the Stronghold and Burrow Warrens, combatants/player can be phased or displaced outside the intended fight area.
- Once outside, the fight can become effectively impossible to complete.
- Treat this as a core combat reliability blocker even though the reproductions are in later locations.
- Audit encounter teleport/arena bounds/collision/nav placement and ensure every combat participant remains in a reachable legal arena state through entry, movement, switching, knockback/teleport, and teardown.
- Add regressions using representative Stronghold and Burrow Warrens encounters, not only the opening wild-fight harness.

## P2 — Website / story front door

### OP21-22 — Redo the website around the actual game story
The website should be substantially rewritten/redesigned to sell the current Tetherbound premise rather than reading like a generic project page.

Core story direction from owner:
- Team Tether is back.
- They are draining the land.
- Grandpa is too old to take on the journey himself.
- The player has to step up, build a five-creature team, defeat the major challenges/tournament/boss progression, stop Team Tether, and restore the land.
- Present the adventure as exciting and specific to Tetherbound.

This website work may run in parallel with game fixes but is part of the current owner-requested Gate A cleanup batch. It must not consume worker capacity needed for hard controller/performance blockers.

## Gate A owner-evidence additions

Before Gate A may pass after this playtest, the representative evidence should additionally prove:

1. ROG Ally / target-hardware performance is acceptably responsive in the opening village/pond/build/combat route.
2. Satchel, Build shortcut, Settings, teleport list, party cycling and hotbar inputs do not leak across contexts.
3. The first village trainer battle retains camera control.
4. Map is readable and zoom/current-location behavior is useful.
5. Major shortcut prompts are readable at handheld size.
6. Building rotate works; doors are usable; the 2x2 modular house has coherent door/roof proportions.
7. Opening objectives make the next meaningful action understandable without external instructions.
8. Catching a third creature immediately displays `3/5` and consistent party UI.
9. Village/sign/pond composition no longer contains the fresh owner-reported spatial errors.
10. The live lighting cycle does not settle into a broken washed-out grey state.
11. Unsafe full submersion has the intended hazard/damage response.
12. Player-facing terminology uses Creature/Tetherbound language rather than Pal terminology.
13. Title -> Load Game -> selected save reliably enters a controllable loaded world instead of stalling on the home/menu screen.
14. Normal gathering visibly shows a believable held axe and synchronized chopping swing/hit.
15. Representative Stronghold and Burrow Warrens fights keep all participants inside reachable combat bounds.

## Execution guidance

Prioritize in this order:

1. target-hardware lag and controller/input ownership blockers;
2. load-game stall, trainer-battle camera, Settings/Map usability, party-count correctness, and combat-arena containment;
3. build rotate/scale/door/roof correctness and gathering-tool presentation;
4. opening guidance and HUD readability;
5. village/pond/sign/lighting/world composition defects;
6. pond-to-village dead-travel/content cadence as Gate B/C/D1 work once Gate A's representative baseline is trustworthy;
7. website story redesign in parallel where it does not slow the game-critical path.

Use bounded workers. A current owner reproduction outranks an older green test. If an old regression says one of these paths passes, first determine why it failed to represent the real ROG/player path and close that false-positive gap.
