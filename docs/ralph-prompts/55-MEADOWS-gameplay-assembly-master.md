# MEADOWS-GAMEPLAY-ASSEMBLY — Build the chapter, not a pile of features

## Authority
Read, in order:
1. `CLAUDE.md`
2. `docs/TETHERBOUND_GAME_VISION.md`
3. `ralph/ACTIVE_GAME_PLAN.md`
4. `ralph/OWNER_PLAYTEST_2026-08-18.md`
5. `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md`
6. relevant child prompts/spec sections

This prompt is the integration contract for the entire Meadows chapter.

## Problem
The repository has many strong systems and unusually detailed design, but the player can still experience them as disconnected features separated by long traversal. Completing more isolated tasks is not enough.

The Meadows must become a coherent 3–4 hour creature-training adventure where every major system supports the player’s team of five and every region feels like a finished place.

## Goal
Assemble the existing systems/content into a continuous chapter whose central player question is:

> **Is my five-creature team strong, healthy, prepared and versatile enough for the next meaningful challenge?**

Do not create duplicate combat, quest, spawn, build, progression, map, or save systems. Use the infrastructure already in the repo.

## Required chapter spine
Preserve canonical progression:

Grandpa/opening → first catches → team preparation → village tournament → Lower Meadows/South Bridge → Quarry/Rootstone/Burrow Warrens → river/crossing/Tether Relay → Upper Meadows/Ironwood/riding/three captains → stronghold approach → Meadows Hall/Warden → free legendary → release choice if full → world healing.

Exact canonical story/state remains governed by the progression spec and current decisions.

## Assembly principles
### 1. Every region needs purpose
A player entering a region should know both:
- what meaningful challenge they are moving toward;
- what they can do in this region to become more capable.

### 2. Every core system must feed the journey
- wilds create team choices and XP;
- trainers test the team and reward progression;
- gathering feeds known builds/upgrades;
- building enables home/camps/recovery;
- creature beds make attrition meaningful;
- objectives explain the current goal;
- exploration reveals optional value;
- special wilds create tempting skill checks;
- rewards make detours worthwhile.

### 3. Open does not mean empty
Preserve lush areas such as the approved pond composition, but deliberately create broad open Meadows as well. Open areas still need distant gameplay/visual pulls.

### 4. Do not fill the world uniformly
Author regional density. Scenic breathing room is good. Dead running is not.

### 5. The five-creature rule must happen before the ending
A normal playthrough should encounter more than five legitimately desirable creatures before the legendary.

### 6. Major challenges need identity
Tournament, Warrens guardian, Relay Captain, regional captains, stronghold elite and Warden should not be interchangeable standard fights with more HP.

## Execution
Follow `ralph/ACTIVE_GAME_PLAN.md` gates. Do not attempt one giant branch.

For each gate/package:
1. inspect current `main` and reconcile already-shipped children;
2. settle shared contracts before parallel lanes edit them;
3. implement the smallest coherent missing pieces;
4. run the complete player path for that gate;
5. record purpose, team progression, choices, empty travel, failures and presentation;
6. fix the highest-impact failure;
7. replay until pass;
8. continue automatically.

## Do not
- replace the existing backlog;
- delete old tasks because this prompt groups them;
- invent a second progression engine;
- shrink the map merely to hit pacing;
- add creature storage;
- add human combat;
- add creature labor;
- add new Meadows creature meshes;
- wait for owner approval after evidence gates;
- optimize counts instead of experience.

## Chapter-level acceptance
A fresh focused run should reach the end in roughly 3–4 hours while preserving all required beats and should demonstrate:
- reliable core verbs;
- clear current goals;
- continual team improvement;
- meaningful roster decisions;
- useful resources/rewards;
- memorable optional detours;
- natural camp/rest decisions;
- distinct regional identity;
- escalating trainers and special encounters;
- a strong Warden payoff;
- a meaningful legendary/release decision;
- visible post-win world change.

## Definition of done
The Meadows is no longer a long map containing systems. It is a complete enjoyable first Tetherbound chapter.