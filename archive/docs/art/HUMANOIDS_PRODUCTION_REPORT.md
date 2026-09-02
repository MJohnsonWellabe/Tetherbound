# Humanoids — current production report

**Current availability/source-of-truth:** `docs/art/HUMANOID_ASSET_INVENTORY.md`.

This report used to describe an earlier moment when only the trainer, Grandpa and an older Warden asset had been produced. That snapshot became materially wrong after the NPC archetype work and the board-16 Warden rebuild. The detailed old report remains in Git history; this file now records the current production state so agents do not repeat obsolete work.

## Current production set

Current `main` has six independently baked humanoid production rigs/models:

| Archetype | Installed model |
|---|---|
| Trainer / player base | `assets/characters/trainer/trainer_lod0.glb` |
| Grandpa | `assets/characters/grandpa/grandpa_lod0.glb` |
| Warden | `assets/characters/warden/warden_lod0.glb` |
| Villager male | `assets/characters/villager_male/villager_male_lod0.glb` |
| Villager female | `assets/characters/villager_female/villager_female_lod0.glb` |
| Team Tether grunt | `assets/characters/grunt/grunt_lod0.glb` |

The MQ1A locomotion rebuild explicitly rebaked all six through the shared humanoid motion pipeline. These are live production assets, not placeholder folders.

## Reuse policy

The Meadows should use the existing humanoid cast before making more human models.

- civilians and ordinary local NPC roles should reuse the installed villager/trainer/Grandpa families where current configuration makes sense;
- ordinary Team Tether personnel should reuse the dedicated grunt family and existing rank/material/accessory presentation;
- named NPC identity should come from role, palette/material variation, dialogue, team composition, placement and behavior as well as the mesh;
- do not make every named human a unique Meshy generation;
- any truly new humanoid requires a demonstrated player-facing need not satisfiable by the current six and owner-supplied reference art.

See `HUMANOID_ASSET_INVENTORY.md` for the binding current rule.

## The Warden — resolved

The old report's largest warning was that the Warden's face was painted/unmodelled because board 06 was too weak a reference. That is **no longer true**.

The owner supplied:

`docs/art/reference/16_Warden_Aldis_Character.png`

That reference superseded board 06 for the Warden.

The Warden was fully rebuilt afterward:

- new body from board 16;
- head generated separately from board-16 head views;
- modelled facial features and beard;
- head grafted to the body;
- texture pass;
- auto-rig;
- five humanoid clips;
- installed as `assets/characters/warden/warden_lod0.glb`;
- rendered and validated;
- `smoke_art` and `smoke_boss` green at the rebuild.

Do not create backlog work to obtain a better Warden sheet or replace a painted-mask face. Those problems were solved by the board-16 rebuild.

## Pipeline lessons that still matter

The old production work established several useful rules that remain valid:

- whole-body generations can under-resolve faces; separate head generation/grafting is a proven route when a strong head reference exists;
- reference images influence image-to-3D more strongly than prompt prose, so crop out visual information the model must not reconstruct;
- humanoid thin clothing/capes can be damaged by indiscriminate voxel remeshing; the Warden rebuild added the pipeline options needed to avoid that;
- scale, materials, rigging, clips and final in-engine renders must all be verified rather than trusting a successful generator response;
- the shared humanoid animation pipeline should remain shared so a gait fix does not leave half the cast behind.

For detailed historical dead ends, generator rounds and tool bugs, consult Git history for this file and the art-pipeline decision/asset-ledger entries rather than treating those old intermediate states as the current asset plan.

## Current conclusion

There is **not** a missing-NPC-model problem in the Meadows that should be solved by broadly generating more humans.

There is an existing reusable six-rig humanoid cast. Claude/Ralph should first make better use of it across trainers, villagers, Team Tether personnel and story NPCs, and only escalate to new human art when actual gameplay evidence shows a role the existing cast cannot represent.
