# Humanoid Asset Inventory — current Meadows authority

**Status:** Current owner-directed humanoid asset inventory.

This file is the source of truth for **which humanoid character meshes already exist on current `main` and should be reused**.

It supersedes older availability/status statements in `docs/art/HUMANOIDS_PRODUCTION_REPORT.md` and `docs/art/REFERENCE_CANON.md` where those files describe only the trainer/Grandpa/Warden set or say the Warden still needs to be rebuilt.

## Current production humanoid rigs

Current `main` contains six independently baked humanoid production rigs/models:

| Archetype | Installed model | Current role/use |
|---|---|---|
| Trainer / player base | `assets/characters/trainer/trainer_lod0.glb` | Main trainer/player visual family and reusable trainer-family source where current data already uses it |
| Grandpa | `assets/characters/grandpa/grandpa_lod0.glb` | Grandpa Elias / older civilian family where explicitly appropriate |
| Warden | `assets/characters/warden/warden_lod0.glb` | Meadows Warden; current rebuilt version |
| Villager male | `assets/characters/villager_male/villager_male_lod0.glb` | Reusable male civilian/NPC archetype |
| Villager female | `assets/characters/villager_female/villager_female_lod0.glb` | Reusable female civilian/NPC archetype |
| Team Tether grunt | `assets/characters/grunt/grunt_lod0.glb` | Reusable Team Tether rank-and-file archetype |

These six were all rebaked through the shared humanoid locomotion pipeline in the MQ1A locomotion rebuild. Treat them as live production assets, not abandoned experiments.

`assets/characters/Ranger.glb` and the `Rig_Medium_*` files also exist at the character root as older/source/generic assets. Do not count or choose them as a new production archetype merely because they are present; inspect current config/scene usage before relying on them.

## NPC production rule

Before generating, sourcing, or inventing any new human model for the Meadows:

1. inspect this inventory and current NPC/trainer configuration;
2. reuse one of the six installed production humanoid families when it can represent the role cleanly;
3. differentiate reusable NPCs through the existing per-material palette/variant system, rank badges/accessories already supported by the game, dialogue, team composition, location, and behavior;
4. preserve clearly distinct roles where a dedicated existing archetype already exists — e.g. use the grunt family for ordinary Team Tether personnel rather than repainting a civilian and calling it a grunt;
5. do not create another humanoid generation simply to make every named NPC a unique mesh.

A new humanoid mesh is exceptional work. It requires a real player-facing need that the existing six cannot satisfy and still requires owner-supplied reference art under `CLAUDE.md`.

## The Warden is already fixed

The current Warden is **not** the old board-06 painted-mask version described in earlier production notes.

The owner later supplied `docs/art/reference/16_Warden_Aldis_Character.png`. That sheet superseded board 06 for the Warden's appearance.

The Warden was then rebuilt through the full humanoid pipeline:

- new body from board 16;
- separately generated/modelled head from the board-16 head views;
- head grafted onto the body;
- textured;
- rigged;
- five clips authored/installed;
- installed at `assets/characters/warden/warden_lod0.glb`;
- rendered and verified;
- `smoke_art` and `smoke_boss` passed at the rebuild.

Do **not** create a new task saying the Warden still has a painted face, lacks a modelled face, or needs a production-quality reference sheet. Those statements are historical and were resolved by the board-16 rebuild.

If a future playtest finds a new Warden visual defect, reproduce that specific current defect against the installed board-16 model rather than reopening the obsolete board-06 problem.

## Reference priority for humans

For current humanoid work:

1. explicit newer owner direction / owner play evidence;
2. this inventory for installed/reusable humanoid availability and Warden current state;
3. current `data/config/art.json` and current scene/NPC/trainer config for what is actually wired into the game;
4. `docs/art/reference/16_Warden_Aldis_Character.png` for the current Warden visual design;
5. `docs/art/reference/12_NPC_Bases_Reusable.png` for reusable NPC visual direction;
6. `docs/art/reference/04_Main_Character_Style_Reference.png` for human proportion/material language;
7. older production reports/reference boards only for historical pipeline lessons that do not conflict with the current state above.

## Why this exists

The repository accumulated production reports at different moments in the art pipeline. Some were accurate when written but became stale after new NPC archetypes and the Warden rebuild landed. Claude/Ralph should use the assets already paid for and already integrated rather than rediscovering or regenerating a human cast.