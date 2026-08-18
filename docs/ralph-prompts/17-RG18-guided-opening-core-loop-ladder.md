# RG18 — Guided opening core-loop ladder

## Goal
Turn the opening/tutorial from a short handoff into a coherent, persistent guided ladder that teaches the player the actual early-game loop before the Meadows opens into longer-form exploration.

The owner has now locked the intended sequence at a high level:

1. Get creatures/pals for the village tournament.
2. Train with them.
3. Gather materials.
4. Build a house/home.
5. Build a creature/pal bed.
6. Build the player's own bed and sleep.
7. Enter the village tournament.
8. Win / complete the tournament beat.
9. Head to the bridge and continue into the Team Tether route.

This item is about the **guided progression ladder and on-screen teaching**, not about duplicating every underlying mechanic. Reuse the systems that already exist, and hand off to RG19 for tournament mechanics and to RG16/RG17 for the post-tournament navigation spine.

## Owner decisions — locked

- The early game should actively tell the player to go get creatures/pals for the local tournament.
- The player should be told to train with those creatures before the tournament.
- Gathering is part of the guided ladder and should be taught explicitly.
- Building a real home/house is part of the guided ladder.
- The player should build a creature/pal bed.
- The player should build their own bed and use sleep as part of the guided ladder.
- Tournament entry is the culmination of the early tutorial/progression sequence, not an unrelated side activity.
- After the tournament, the guided objective should hand off to the bridge / Team Tether route.
- These steps should be surfaced through the objective/tutorial system as the player reaches them. Do **not** dump the whole list into one Grandpa speech.

## Relationship to other backlog items

### RG16
RG16 owns the broad major-objective spine:

**starter / first catch -> prepare for tournament -> enter/win tournament -> head east to bridge / Team Tether**

RG18 should supply the **detailed guided beats inside the preparation phase**.

### RG19
RG19 owns tournament mechanics, including the authoritative eligibility rules, creature-condition system, bracket/arena/rewards, and exact numeric thresholds.

RG18 may tell the player to prepare/train/build/care for the team, but must not duplicate RG19's tournament-entry logic.

### RG13
RG13 owns progressive crafting/building unlock knowledge. RG18 should use those unlocks as tutorial moments rather than exposing recipes before they are learned.

### RG17
RG17 owns the pylon navigation spine after the tournament. RG18 only needs to hand the player into that phase.

## Current problem
The current opening successfully establishes Grandpa, the starter, first catch, a few items, and a small number of handoff beats. But it becomes free play too early relative to the actual systems the game expects the player to understand.

The owner wants a Palworld-like guided opening in the sense of **a clear sequence of on-screen goals that teaches the game's core loop by doing it**, not a giant written tutorial.

The player should not reach the end of the opening while still asking:

- Why should I catch more creatures?
- How do I train them?
- Why should I gather materials?
- Why should I build?
- What is the creature bed for?
- Why do I need my own bed / sleep?
- What am I preparing for?
- Where do I go after the tournament?

## Relevant current systems / files to inspect
Before implementation, inspect current `main` and reuse existing systems rather than creating parallel tutorial state:

- `data/dialogue/opening.json`
- `data/dialogue/village.json`
- `scripts/world/quest_log.gd`
- current HUD objective/tutorial prompt presentation
- `autoload/progression_state.gd`
- current opening/sequence director
- current catch/party state and five-creature cap
- combat / XP / level progression systems
- gathering/harvest systems
- `data/items/buildables.json`
- `scripts/ui/build_menu.gd`
- `scripts/build/build_placer.gd`
- creature bed implementation / interaction
- player bed / camp / sleep implementation
- save/load progression and placed-building persistence
- RG13 recipe/build unlock path
- RG16 objective-state path
- RG19 tournament state if it has landed
- RG17 pylon/navigation state if it has landed

## Design principle
The tutorial should be a **ladder of meaningful goals**, not a checklist overlay showing ten things at once.

At any moment, the player should have:

- one clear major objective;
- optionally one immediate sub-objective;
- a visible completion response when that step is satisfied;
- then the next step appears.

Do not overwhelm the player with the full future sequence from the start.

## Desired guided sequence

The exact decomposition can follow current quest architecture, but the player-facing order should preserve this logic.

### Beat 1 — starter / first catch
Preserve the existing opening and starter/first-catch flow.

This is still the foundation of the tutorial. Do not rewrite it unnecessarily.

### Beat 2 — build a tournament team
After the first catch, the player should learn that one creature is not enough for the local tournament.

Major intent:

> **Build a team for the village tournament**

The owner has already tied the tournament concept to the game's five-creature cap. If RG19 confirms the entry roster is five, surface that clearly. If RG19 is not yet authoritative on the exact roster size, derive the target from shared tournament state rather than hard-coding a second copy.

This beat should motivate catching more creatures, not merely say "catch more" in isolation.

### Beat 3 — train with the team
The player should be explicitly taught that catching creatures is only the start; they must train/use them.

Training should mean using the game's real progression loop, not an invented minigame unless one already exists.

Acceptable examples depending on current systems:

- win fights with your creatures;
- gain XP;
- raise one or more team members to an appropriate early level;
- practice swapping/using multiple owned creatures if that is already part of the combat loop.

The exact permanent level threshold belongs to RG19 if it gates tournament entry. RG18 should not invent a second number.

### Beat 4 — gather materials
Give a concrete gathering objective that teaches the resource loop.

The player should gather the baseline early materials that actually matter to the next build step rather than collect arbitrary filler.

Coordinate with RG13 so gathering a material can trigger the corresponding recipe/build unlock teaching at the right time.

### Beat 5 — build a home/house
The player should now be told to establish a real home, not just place a random isolated object.

The implementation should use the current building system and whatever minimum set of structures the current game recognizes as a sensible starter home.

Do not invent a giant housing-validation system unless one already exists. The tutorial needs an honest, achievable condition that reads to the player as "I built my place."

If current building pieces make a minimal home naturally (for example floor/walls/roof/door or an existing camp/shelter construct), use the smallest coherent completion rule.

### Beat 6 — build a creature/pal bed
Once the player has a home, teach creature care by asking them to place a creature bed.

This beat should connect the object to a real player-facing reason:

- their creatures need a place to rest;
- this matters for condition/readiness if RG19's rested state has landed;
- creature beds are part of making the player's home useful rather than decorative.

Do not tell the player "build a pal bed" if the placed object does not yet have meaningful behavior. If the current implementation is only a marker, coordinate with the owning system so the tutorial and mechanic are honest.

### Beat 7 — build/use the player's bed and sleep
The player should build their own bed (or the current canonical player sleep object) and actually sleep once.

This should teach:

- where sleep happens;
- that time/night can be managed through rest if that is currently supported;
- the distinction between the player's bed and creature beds.

Completion should require the actual sleep/rest interaction, not just placing the object.

### Beat 8 — tournament readiness / entry
Once the player has learned the core preparation loop, the objective should shift clearly to the village tournament.

Examples:

- `Return to the tournament organizer`
- `Enter the village tournament`

If RG19's eligibility system exists, derive readiness from it.

If the player is missing a requirement, the organizer should explain what remains using the authoritative tournament state. RG18 should not maintain a separate hidden checklist that can disagree.

### Beat 9 — tournament complete
Tournament mechanics/rewards belong to RG19, but RG18 should listen for the shared victory state and advance the guided sequence.

### Beat 10 — handoff to the wider Meadows route
After tournament victory, the guided opening/tutorial ladder ends by transitioning into the broader adventure:

> **Head to the bridge**

or equivalent current RG16 wording.

This should hand directly into RG16/RG17:

- map/minimap objective;
- eastbound road/bridge destination;
- Team Tether fiction;
- pylon navigation spine.

The player should feel that the tutorial has ended because they have proven they understand the core loop, not because tutorial text simply stopped.

## Tutorial presentation requirements

Use the existing HUD/quest/tutorial presentation if possible.

Each beat should:

- appear when actionable;
- remain visible enough to be useful;
- complete automatically when the authoritative game state says it is complete;
- show a brief completion acknowledgement;
- advance to the next beat without requiring the player to reopen a menu just to discover what changed.

Do not use modal popups for every step.

Do not pause the world for routine objective updates.

Controller-first readability on ROG Ally is mandatory.

## Dialogue responsibilities

NPC dialogue should introduce **why** the next beat matters, while HUD objectives carry **what to do now**.

Examples of responsibility split:

- Grandpa / tournament organizer: "You'll need a real team before they'll let you in."
- HUD: `Catch more creatures for the tournament.`

- Villager/crafter: teaches the relevant recipe or building concept.
- HUD: `Gather wood and fiber.`

- Care-oriented NPC/tutorial line: explains resting creatures.
- HUD: `Build a Creature Bed.`

Do not turn any one NPC into a wall of tutorial text covering the entire ladder.

## State / persistence requirements

Every completed tutorial beat must persist through save/load.

Reloading must restore the correct current beat based on authoritative progression state, not blindly restart the tutorial.

Where possible, infer completion from real permanent state rather than save a redundant tutorial boolean.

Examples:

- party size / tournament state for team-building;
- XP/level state for training;
- inventory/progression/material discovery for gathering;
- placed-building state for home / beds;
- sleep/rest state if a persistent acknowledgement is required;
- tournament victory state for the final handoff.

Use explicit progression flags only where the real game state cannot answer the question cleanly.

Older saves should migrate to the most appropriate current beat from the state they already contain.

## Sequence flexibility / edge cases

Players will do things out of order. The tutorial must tolerate that.

Examples:

- Player catches five creatures before the "build a team" beat becomes active.
- Player has already gained enough levels before the training beat appears.
- Player gathers materials early.
- Player builds a house or bed before the tutorial asks.
- Player already slept before the sleep beat becomes active.
- Player reaches the tournament organizer early.

When a beat becomes active, immediately check whether its condition is already satisfied. If yes, acknowledge and advance instead of forcing repetition.

Do not delete or punish legitimate early progress just to preserve tutorial order.

## Preserve

- Existing starter choice and naming flow.
- Existing first-catch mechanics.
- Five-creature hard cap.
- Current gathering/building/sleep/combat systems.
- RG13's progressive recipe/build knowledge model.
- RG16's major objective spine.
- RG19's ownership of tournament mechanics and condition thresholds.
- RG17's ownership of pylon navigation after the tournament.
- Save/load compatibility.

## Do not

- Do not show the entire ten-step ladder at once.
- Do not put all tutorial instructions in Grandpa's dialogue.
- Do not create a second quest/tutorial framework if the current quest log can handle staged objectives.
- Do not duplicate tournament eligibility logic.
- Do not invent permanent numeric level/condition thresholds that RG19 owns.
- Do not require repeating already-completed legitimate actions.
- Do not make tutorial completion depend on hidden conditions the player cannot see.
- Do not add arbitrary grind simply to stretch the opening.

## Acceptance criteria

1. A new player is guided from the existing starter/first-catch opening into building a tournament-ready team.
2. The game explicitly teaches that creatures should be trained/used, not merely caught.
3. The game explicitly teaches gathering through a concrete resource objective tied to upcoming construction/crafting.
4. The player is guided to build a real starter home using the current building system.
5. The player is guided to build a creature bed and understands why it matters.
6. The player is guided to build/use their own bed and completes an actual sleep/rest interaction.
7. The sequence naturally culminates in village tournament entry.
8. Tournament readiness and victory come from RG19/shared authoritative state rather than duplicated tutorial booleans.
9. After tournament victory, the active major objective hands off to the bridge / Team Tether route.
10. The current active tutorial beat persists correctly through save/load.
11. If the player already satisfied a future beat early, that beat auto-completes when reached rather than forcing repetition.
12. A first-time ROG Ally player can progress through the full early loop without needing external instructions.

## Testing / verification

Add focused progression coverage for the ladder.

At minimum verify:

1. opening -> first catch -> tournament-team objective;
2. catching/progression satisfies team-building beat;
3. training state satisfies training beat;
4. gathering the required baseline materials advances gathering beat;
5. placing the minimum valid starter home advances home-building beat;
6. placing a creature bed advances creature-bed beat;
7. placing/using the player bed and sleeping advances sleep beat;
8. tournament eligibility state advances to entry;
9. tournament victory advances to bridge objective;
10. save/reload at multiple points restores the correct current beat;
11. pre-completed future beats are recognized and skipped honestly.

Use current relevant tests for:

- dialogue/opening progression;
- quest/progression state;
- save/load;
- building placement;
- creature bed/rest;
- player sleep;
- tournament state once RG19 exists.

Run a real controller-first playthrough on the ROG Ally/Windows target. This item is only done if the sequence feels like the game teaching itself through play.

## Definition of done

RG18 is done when the first phase of Tetherbound teaches the player the actual game loop in a coherent sequence:

**starter / first catch -> build a team -> train -> gather -> build a home -> build a creature bed -> build/use your bed and sleep -> enter/win the village tournament -> head to the bridge / Team Tether route**

with each step surfaced at the right time, grounded in real game state, persistent through save/load, tolerant of out-of-order player behavior, and integrated with RG13/RG16/RG17/RG19 rather than duplicating them.