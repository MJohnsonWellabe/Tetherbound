# EXPEDITION-REST — Make injury, distance and night create natural camp decisions

## Goal
Turn creature health, bed recovery, player sleep, food/satiety, day/night and building into one natural expedition rhythm.

Do not create invisible mandatory-camp gates or a second survival system. Use current creature HP/fainting, condition, beds, satiety, sleep, day cycle, building and save systems.

## Intended experience
A good expedition can produce this sequence naturally:

- leave home with a healthy team;
- fight several encounters;
- one creature becomes badly injured;
- another is low or unavailable;
- night approaches;
- the player reaches a memorable buildable clearing with nearby basic resources;
- the player chooses whether to push on or stop;
- build/use shelter/fire/bed infrastructure as appropriate;
- place an injured creature in its physical bed;
- that creature visibly rests, is unavailable and gradually regains HP;
- the player sleeps;
- morning arrives and the expedition resumes better prepared.

The important word is **chooses**. Do not force this every fixed number of minutes.

## Creature bed contract
Follow the newest owner rule:
- physical visible resting body;
- unavailable for combat/deployment while resting;
- gradual HP restoration during bed occupancy;
- overnight is the intended full-rest cycle;
- early removal keeps HP already regenerated but does not grant completed-rest state;
- fainted/recovery semantics must remain consistent with current revive rules.

## Player bed / sleep
Player sleep should advance/rest the world according to current day/night rules and integrate with creature recovery rather than becoming a disconnected cutscene.

## Food/satiety
Keep light survival philosophy: soft preparation value, no starvation death. Food should improve readiness and condition without becoming constant chore pressure.

## Camp siting
Coordinate regional packages. Where a long band needs a plausible rest point, author remembered clearings rather than hotels.

Good camp-worthy spaces:
- relatively flat/buildable;
- nearby basic wood/stone/fiber availability;
- not inside unavoidable hostile aggro;
- visually memorable;
- placed before/after meaningful combat stretches where a player might genuinely need recovery.

Do not pre-build free full-service camps unless canon calls for one. Player-built camp infrastructure must remain meaningful.

## Home vs field camp
Home remains the strongest emotional/mechanical recovery hub. Field camps extend expeditions. Avoid making either one obsolete.

Home can offer:
- stable creature-bed layout;
- storage/crafting;
- Grandpa/story updates;
- broader home progression.

Field camp offers:
- immediate recovery/sleep close to the frontier;
- a memorable staging point;
- reduced backtracking.

## Attrition tuning
Use combat and travel data to ensure rest matters sometimes but does not become mandatory after every fight.

If players never need beds, the system has no purpose.
If every encounter forces overnight rest, it becomes punitive.

Tune damage/recovery opportunities around the chapter’s challenge ladder, not around one universal timer.

## Save/load
Resting state and gradual recovery must survive save/load honestly. Do not duplicate or instantly complete recovery because a save was loaded.

## Verification
For each regional evidence run record:
- creature HP entering/exiting;
- when a creature became meaningfully injured;
- whether player chose to camp/return home/push on;
- time spent resting;
- whether a camp location was available/useful;
- whether recovery felt understandable;
- whether night contributed to the decision.

## Acceptance
- creature beds have real tactical/expedition value;
- the player occasionally chooses to stop without invisible forcing;
- camps are useful but not mandatory checkpoints;
- home remains relevant;
- recovery is gradual and visible;
- early removal works honestly;
- food/satiety supports readiness without survival punishment;
- save/load preserves state.

## Definition of done
Rest is not a menu heal and building a camp is not decoration. Injury and distance create meaningful moments where stopping to care for the five is part of the adventure.