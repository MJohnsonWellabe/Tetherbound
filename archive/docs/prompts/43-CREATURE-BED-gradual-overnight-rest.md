# CREATURE-BED — Physical, gradual overnight recovery that removes the pal from combat

## Owner decisions — locked
The current creature-bed behavior is wrong because pressing Rest immediately heals/revives the creature and the creature is not visibly resting.

New behavior:
- assigning a pal to a creature bed places that actual pal visibly in/at the bed in a lying/resting pose;
- while assigned/resting, the pal is **not eligible to fight** or be selected as the active combat creature;
- HP recovers **gradually while time passes in bed**;
- the pal must stay through the overnight/rest-completion boundary to gain the full `rested` recovery/condition benefit;
- if the player removes the pal early, keep whatever HP it legitimately regenerated so far, but do **not** grant the completed overnight/rested benefit;
- this is part of RG19's rested/fed/happy creature-condition model, not a parallel status system.

## Why this matters
This turns beds, camps and overnight stops into real gameplay. The player has a reason to stop pushing the Meadows: injured team members can recover, but doing so temporarily reduces the usable fighting roster. That tradeoff supports the five-creature cap, tournament preparation and the long-journey design.

## Current implementation to replace/extend
Inspect:
- `scripts/build/creature_bed.gd`
- `scripts/ui/creature_bed_panel.gd`
- `scripts/creatures/home_recovery.gd`
- `scripts/creatures/creature_instance.gd`
- `scripts/creatures/creature_body.gd` and available faint/lie/revive animations
- party selection/combat eligibility code
- save format and GameState persistent registries
- day/night clock and day increment logic
- RG19 condition prompt/decision once landed

Current `creature_bed_panel.gd` calls `HOME_RECOVERY.rest(...)` immediately and reports that the creature wakes fully rested. That instant transaction is superseded.

## Data/state model
A resting assignment must survive scene rebuild and save/load. Store enough authoritative state to answer:
- which unique party creature/slot/instance is assigned to which player-built bed;
- when rest began in game-time terms;
- HP at assignment / latest recovery timestamp as needed;
- whether overnight/full-rest completion occurred;
- whether creature is currently unavailable for combat.

Do not key the relationship solely by transient node instance id.

If creatures are currently identified only by party index, account for party reordering/release so a save cannot accidentally put the wrong creature in a bed. Prefer a stable creature-instance identifier if current architecture has/needs one; keep the change as small as possible.

## Gradual HP recovery
Make recovery data-driven/tunable. Do not hardcode a permanent balance rate in UI code.

Requirements:
- HP increases monotonically while assigned and resting;
- never exceeds max HP;
- update may be computed from elapsed game time rather than every frame, so save/load/offscreen beds are correct and cheap;
- sleeping through night may advance game time using existing player-bed/day systems, and creature recovery must account for that elapsed time;
- removing early preserves partial healing already earned;
- assigning at full HP can still be useful for the `rested` condition if RG19 defines it that way.

### Fainted creatures
Preserve the project's existing creature-bed recovery intent unless a newer decision says otherwise. A bed may recover a fainted creature, but not instantly. Ensure this does not accidentally make ordinary potions revive fainted creatures; D40's dedicated revive-item rule remains separate.

## Overnight/full-rest completion
Define completion against the authoritative day/night clock, not wall time.

The exact completion rule should be consistent with player sleeping/home recovery. A practical implementation is: creature remains assigned across the night's sleep/rest boundary (or a defined minimum rest window that includes overnight) and then receives the completed `rested` condition.

Do not let repeated open/close of the bed panel instantly advance completion.

## World presentation
The creature must be visible at the bed while resting.

Use existing creature visuals/animation pipeline:
- spawn/show the correct creature model at an authored bed rest anchor;
- play a lying/faint/rest pose that reads as sleeping/resting, not dead if possible;
- orient/scale correctly for varied species;
- avoid clipping badly through the bed for larger/smaller creatures; use per-species or generic offset metadata if necessary;
- do not duplicate the creature in the world if it was active when assigned—recall/retarget it cleanly.

When rest ends/removal occurs, remove the bed presentation and return the creature to normal party availability.

## Combat/selection eligibility
Every path that chooses a usable creature must respect resting state:
- exploration pal cycling;
- summon/active creature selection;
- wild combat start;
- trainer combat team selection;
- tournament readiness/entry;
- switch-in during combat.

UI should show `Resting`/bed status rather than silently skipping it.

A player with several resting creatures may have fewer than five available fighters; that is intended.

## Bed interactions
The bed UI should support:
- assign an eligible party creature to an empty bed;
- inspect who is resting and current HP/recovery state;
- remove/wake early with clear consequence (`partial HP kept; not fully rested`);
- refuse assigning two creatures to one bed;
- prevent one creature being assigned to multiple beds;
- handle dismantle: a bed with a resting creature should preferably refuse dismantling until the creature is removed, with clear feedback.

## Save/load/time tests
Required cases:
1. assign injured pal, wait partial period, verify partial HP;
2. save/reload during rest, HP/time continues correctly without duplication;
3. remove early, partial HP remains, full-rest condition absent;
4. assign before night, sleep/advance through morning, full recovery/condition resolves according to tunables;
5. resting pal cannot enter combat or be cycled active;
6. completed/removed pal becomes eligible again;
7. move/reorder party or release another pal without corrupting assignment;
8. attempt to dismantle occupied bed;
9. multiple beds with multiple creatures recover independently.

## Modal-freeze coordination
The owner also reported freezing immediately after resting a pal. The bed UI transition is part of reopened RG1. This task must not paper over that; run the RG1 bed exit regression after changing the bed flow.

## Acceptance criteria
- Pal visibly lies/rests at the assigned bed.
- Resting pal is unavailable for combat/active selection.
- HP restores gradually from game-time elapsed.
- Early removal preserves partial HP but not overnight/full-rest condition.
- Overnight completion grants the intended rested state and appropriate recovery.
- State persists across save/load and offscreen world rebuild.
- No duplicated creature bodies or wrong-creature bed assignments.
- Bed UI clearly communicates status and early-removal consequence.
- RG1 modal exit remains healthy.

## Definition of done
A player can return to camp injured, put one or more pals to bed, visibly leave them there while the usable team shrinks, and wake/collect them later with health restored according to time actually spent resting.