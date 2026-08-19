# Reference canon — current Meadows art authority

This file answers **which art/reference source wins now**. Historical donor-board analysis and superseded production warnings remain recoverable in Git history; current agents should not have to reason through obsolete art states.

## Precedence

For Meadows character/art work:

1. explicit newer owner direction and current owner-play evidence;
2. current installed production asset state on `main`;
3. `docs/art/HUMANOID_ASSET_INVENTORY.md` for humanoid availability/reuse and Warden current state;
4. `docs/art/wild/` + `docs/art/reference/wild/` for the twelve wild species and Tuskroot;
5. dedicated current production sheets listed below;
6. `ROSTER_MANIFEST.md` / current game design for names, roles and mechanics;
7. older concept/donor boards only where a current source explicitly still uses them.

Never infer a new mechanic/type/species from an old image label.

## Current dedicated production references

### Starters

- `reference/01_Ground_Starter_Terrapup.png`
- `reference/02_Water_Starter_Ripplet.png`
- `reference/03_Air_Starter_Galewisp.png`

These remain the direct visual authority for the three starters.

### Human style

- `reference/04_Main_Character_Style_Reference.png`

This defines the trainer/main-character proportion and the shared stylized human material language.

### Reusable NPC direction

- `reference/12_NPC_Bases_Reusable.png`
- `HUMANOID_ASSET_INVENTORY.md`

Current `main` already has six production humanoid families: trainer, Grandpa, Warden, villager male, villager female and Team Tether grunt. Reuse them before considering another human generation.

### Warden — current source

- `reference/16_Warden_Aldis_Character.png`
- installed model: `assets/characters/warden/warden_lod0.glb`

**Board/reference 16 supersedes board 06 for the Warden.**

The Warden was fully rebuilt from the owner-supplied board-16 sheet: new body, separately generated/modelled head, texture, rig and clips, then installed and verified. Historical statements that the Warden still has a painted/unmodelled face, lacks a good reference, or needs a fresh production sheet are obsolete.

If the current Warden later fails a visual review, reproduce the defect against the installed board-16 asset. Do not reopen the solved board-06 problem.

### Wild roster

`docs/art/wild/` is authoritative for the Meadows wild roster. The production sheets live under `docs/art/reference/wild/` and cover all twelve wild species plus Tuskroot.

The current evolution is **Mudsnout -> Tuskroot**. The old evolved-canine/Ridgewolf assumption is retired.

### Legendary

The Veridian Stag remains the Meadows Ground legendary. Use its current installed production asset and current design/spec state. Older board labels that imply other type systems do not override the game's Ground/Water/Air rules.

### Team Tether hero objects

Current owner-supplied hero-object references include:

- `reference/13_Tether_Energy_Pylon.png`
- `reference/14_Relay_Apparatus.png`
- `reference/15_Legendary_Tether_Machine.png`

These are the special Team Tether object family reserved for the higher-touch production pipeline.

## Older boards 05–11

Boards `05`–`11` are historical exploration/donor references. They contain superseded species concepts, labels, types and earlier Warden concepts.

Use them only where a current source explicitly says a remaining element still comes from one of those boards. They never override:

- the current wild canon pack;
- board 16 for the Warden;
- the current humanoid inventory;
- current installed assets;
- settled game-design mechanics.

## Current human-production rule

Before creating or sourcing any human character asset:

1. inspect `HUMANOID_ASSET_INVENTORY.md`;
2. inspect current scene/config usage;
3. reuse an installed archetype if it can cleanly serve the role;
4. differentiate through existing material variants, accessories/rank presentation, dialogue, teams, location and behavior;
5. create a new humanoid only if the existing production cast cannot satisfy a real player-facing need and owner-supplied reference art exists.

The goal is a coherent cast, not a unique mesh for every named NPC.
