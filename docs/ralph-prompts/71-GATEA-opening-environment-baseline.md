# Gate A — Opening environment baseline

## Purpose

Gate A is still primarily about trustworthy core verbs. Do **not** turn this into a whole-Meadows vegetation/ecology rebuild.

However, the opening/village/pond play area must be representative enough that catching, combat, gathering, travel, navigation, camping/rest, and visual readability can be judged honestly without developer spawning, teleporting, or running through an obviously sterile test space.

This prompt adds that minimum environment baseline.

## Owner direction

- The dense vegetation around the pond is a **positive reference**. Preserve it.
- Meadows should not have one global density. Some pockets should be lush and enclosed; other areas should be broad open grassland with long sightlines.
- The opening should contain enough naturally present creatures and useful gatherables to exercise the real game loop repeatedly.
- This is a baseline for Gate A and Gate B testing, **not** final chapter-wide ecology or regional composition tuning. `60-WILD-ecology-journey.md` and regional prompts `62`–`66` own the deeper pass.

## Required outcome

Within the normal opening/village/pond travel area:

1. **Representative wild presence**
   - The player can encounter multiple naturally spawned wild creatures during ordinary opening-area travel.
   - Catching/combat/rest can be tested repeatedly without debug spawning or travelling an unreasonable distance.
   - Do not solve this with an everywhere-dense spawn carpet. Preserve habitat variation and breathing room.

2. **Representative resource presence**
   - Wood and other currently appropriate early gatherables are naturally available near the opening routes.
   - Gathering/building can be tested from a normal fresh-game path without developer setup.
   - Resource placement should give the player a reason to leave the exact center of a trail without becoming visual clutter.

3. **Open-versus-lush composition**
   - Preserve the approved lush pond-side vegetation pocket.
   - Ensure the nearby Meadows also contains broad open grassy stretches with long sightlines and readable terrain/landmarks.
   - Do not globally increase or decrease vegetation density.
   - Use regional composition: dense pockets, open fields, edge transitions, readable paths.

4. **Travel readability**
   - Meaningful trails remain visually legible.
   - Vegetation should not routinely block ordinary traversal, hide every landmark, or make the opening feel like one continuous thicket.
   - Open areas should not read as unfinished empty terrain: they may be quieter, but should still have visual pulls such as creatures, resources, landmarks, trail forks, structures, terrain shape, or a distant destination.

5. **No regression of approved presentation**
   - The pond vegetation is a keep/reference area.
   - Do not thin it simply to make all zones match.
   - Do not overpopulate every open field simply because Gate A needs creatures/resources available for testing.

## Inspect first

Before changing anything:

- inspect current opening/village/pond spawn data and world composition;
- verify what is already present on current `main`;
- identify whether missing creatures are a spawning-system failure or content-density configuration problem before adding data;
- inspect the current trails and the approved pond vegetation visually;
- check performance implications before increasing any density.

Prefer the smallest changes that make the opening representative and testable.

## Evidence

Capture and verify at least:

- one representative **open-field** view with readable long sightlines;
- one representative **lush pond-side** view preserving the approved density;
- ordinary player travel between the two without vegetation becoming an obstacle course;
- multiple natural wild encounters without debug spawning;
- enough natural early resources to perform the Gate A gathering/building test;
- readable trail/navigation through the tested area;
- no material performance regression from the baseline changes.

Use the repo visual-judge workflow for visual changes until pass or convergence.

## Gate relationship

This child helps Gate A produce a credible test environment.

It does **not** replace:

- `06-RG20-meadows-wild-creature-population.md`;
- `53-MEADOWS-pokemon-first-core-loop-density.md`;
- `60-WILD-ecology-journey.md`;
- regional packages `62`–`66`.

Those later tasks own final creature ecology, regional density, trainer/resource cadence, optional encounters, and complete world composition.

## Definition of done

Gate A can be judged in the real opening environment without debug setup: there are naturally available creatures and resources, the pond-side lush pocket remains strong, nearby open Meadows provide contrasting breathing room and long sightlines, trails remain readable, and the area is representative enough to test the actual game rather than only its systems.