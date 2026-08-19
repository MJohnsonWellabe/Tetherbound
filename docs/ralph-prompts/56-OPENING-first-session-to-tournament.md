# OPENING-FIRST-SESSION — Make start through tournament a finished small game

## Goal
Build and verify the complete first-session experience from launching the game through winning the village tournament and receiving the objective to leave for the South Bridge.

This owns the **experience assembly**. It does not replace RG18, RG19, RG13, the core-verb fixes, or existing opening systems.

## Why
The current repo contains the right ingredients but they can land independently. The opening is only successful if a new player experiences them as one coherent loop that teaches what Tetherbound is.

## Required player journey
1. Launch into the proper title/front door.
2. Start a fresh save.
3. Wake in Grandpa’s farmhouse.
4. Grandpa opening cannot be accidentally skipped.
5. Choose and name starter.
6. Learn basic interaction/movement naturally.
7. Enter first wild fight.
8. Aim and catch first wild creature.
9. Learn that the village tournament is the first major goal.
10. Catch enough creatures to build a meaningful tournament team.
11. Fight/train with them; communicate level-ups.
12. Gather materials with correctly equipped/animated tools.
13. Unlock the relevant early crafting/build knowledge.
14. Build a small functional home using the real build system.
15. Build at least one creature bed.
16. Experience a creature needing rest/recovery and see physical resting.
17. Build/use the player’s own bed and sleep.
18. Satisfy the authoritative tournament-readiness rules.
19. Enter and win the tournament.
20. Receive a clear handoff toward the South Bridge / deeper Meadows.

## Experience requirements
### Motivation
The player should understand why they are catching and training: the tournament is ahead.

### Pace
Do not create arbitrary grind. Enough wilds/trainers/resources must exist near the opening route that preparation happens through interesting play rather than circling one spawn.

### Home
The first house need not be elaborate. It must be fast enough to build that the player learns building without getting trapped in construction friction. Floors/walls/roof/door must actually work.

### Creature care
At least one realistic path through the opening should demonstrate why creature beds matter. Do not force scripted injury if normal tournament preparation naturally creates it; do ensure the mechanic is visible and understandable.

### Tournament
The tournament should feel like the payoff for the first-session learning loop, not another tutorial prompt.

### Objectives
Use the existing objective/progression architecture. One useful current goal at a time. NPC dialogue provides why; HUD objective provides what.

## Child work to inspect/reuse
- RG18 guided opening ladder
- RG19 condition spec + tournament
- RG13 recipe/build unlocks
- current opening dialogue/director
- starter/name flow
- combat/catching/party systems
- XP/level systems
- build placement/snapping/repeat/dismantle
- gathering/tool interaction
- creature bed/player sleep
- save/load
- title/front door
- chapter objective chain
- local trainer/wild ecology maps

## Edge cases
- player catches creatures before objective asks;
- player gathers early;
- player builds early;
- player sleeps early;
- player arrives at tournament early;
- player saves/reloads during any beat;
- a creature is resting/unavailable when tournament readiness is checked.

Recognize legitimate earlier progress instead of forcing repetition.

## Evidence run
Use a fresh save and record:
- elapsed time to first catch, first level-up, first home, tournament entry and tournament victory;
- team composition/levels entering tournament;
- resource/build friction;
- any point where objective intent was unclear;
- any long empty interval;
- every modal/control failure;
- whether a first-time player would need external instructions.

## Acceptance
Pass only when the segment feels coherent enough that it could be shown as a standalone Tetherbound demo:
- no major freeze/input failure;
- catching feels intentional;
- team growth is visible;
- gathering has feedback;
- basic home construction works;
- rest has purpose;
- tournament preparation feels earned but not grindy;
- tournament is a satisfying first milestone;
- post-tournament direction is unambiguous.

## Definition of done
The player finishes the tournament understanding the game: **my job is to build, care for and improve my five because harder challenges are ahead.**