# OP-BED — Physical gradual overnight creature recovery

## Goal
Replace the current instant-heal creature-bed interaction with a real recovery state that creates a meaningful camp/rest decision.

## Owner intent — locked
When a creature is assigned to a creature bed:
- it is visibly lying/resting in that bed;
- it is unavailable for active combat/deployment while resting;
- health restores gradually while it remains there;
- the intended full-rest cycle is overnight;
- if removed early, recovery stops and it keeps only health actually regained;
- full overnight rest leaves it appropriately recovered/rested for the next day.

This supersedes the current `creature_bed_panel.gd` behavior that calls `HOME_RECOVERY.rest(...)` immediately and says the creature has already woken fully refreshed.

## State model
Use persistent creature/bed state, not a menu animation illusion.

Track enough authoritative data to answer:
- which creature is assigned to which bed;
- when rest began / how much valid rest time has elapsed;
- current recovery progress;
- whether the creature is currently unavailable;
- what happens across save/load and day transition.

Prefer game-time/day-cycle state over wall-clock time.

## Recovery
Recovery should be gradual and data-tunable. Do not hard-code a one-frame full heal.

At minimum:
- partially injured creature gains HP over valid rest time;
- fainted creature follows existing revive/rest canon rather than bypassing dedicated faint rules accidentally;
- early removal leaves partial HP recovery;
- overnight completion grants the intended rested condition used by RG19/tournament readiness.

Coordinate with the creature-condition model so there is one definition of `rested`, not a bed-only duplicate.

## World presentation
The resting creature must be physically visible at the bed in a believable lying/sleeping pose. Reuse existing creature body/animation infrastructure where possible. Do not leave the active roaming copy simultaneously visible elsewhere.

When assigned:
- remove/recall it from active deployment cleanly;
- display the correct creature body at the bed;
- keep scale/shiny/individual visual traits consistent with that instance.

When removed/wakes:
- clear bed visual;
- restore eligibility and normal summon behavior.

## Combat eligibility
A resting creature cannot be selected for combat or deployed. Party/menu UI should clearly show that it is Resting and why it is unavailable.

Do not delete it from the five-creature party. The bed is not storage and does not permit owning a sixth creature.

## Save/load
Save/reload during rest must restore:
- bed assignment;
- creature resting state/unavailability;
- partial health progress;
- visible bed occupant;
- correct continuation toward morning.

No duplicate creature bodies or instant completion on reload.

## Interaction/UI
The bed interaction should let the player assign an eligible party creature and later remove/wake it early. Show current HP and resting/recovery status. Keep controller navigation functional and ensure closing the panel returns world control (coordinate with OP1/RG1 modal lifecycle).

## Acceptance
1. Assigning a creature does not instantly full-heal it.
2. Creature visibly lies in bed.
3. HP increases over valid rest time.
4. Resting creature cannot fight/deploy.
5. Early removal preserves only earned recovery.
6. Overnight completion produces the intended full-rest result.
7. Save/load mid-rest preserves state.
8. No sixth-creature/storage loophole.
9. Bed UI never leaves world input frozen after close.

## Definition of done
Creature beds are a real expedition-management system: an injured pal must spend meaningful time physically resting, which gives the player a reason to build a camp, protect downtime and decide which team members are available for the next fight.