# Tetherbound — Meadows Art Pack

This pack gives Claude/Ralph and the 3D pipeline concrete visual targets for the Meadows.

## Current authority map

Use the most specific current source:

- **Installed/reusable human NPC assets + current Warden state:** `HUMANOID_ASSET_INVENTORY.md`
- **Current wild roster/species art:** `docs/art/wild/` and `docs/art/reference/wild/`
- **Character/reference precedence:** `REFERENCE_CANON.md`
- **Whole Meadows roster list:** `ROSTER_MANIFEST.md`
- **3D production pipeline:** `TETHERBOUND_3D_ART_PIPELINE.md`
- **Asset provenance/license:** `docs/specs/ASSET_LEDGER.md`

Older production reports are valuable for pipeline history, but current asset availability comes from the inventory above and current files on `main`.

## Current humanoid production state

Do **not** assume the Meadows has only the trainer, Grandpa, and Warden.

Current `main` has six production humanoid rigs/models:

- trainer/player base;
- Grandpa;
- rebuilt Warden;
- villager male;
- villager female;
- Team Tether grunt.

Claude should reuse these existing families and their material/rank/config variants before considering a new human generation. See `HUMANOID_ASSET_INVENTORY.md` for exact paths and rules.

The Warden is already rebuilt from the owner-supplied `reference/16_Warden_Aldis_Character.png`; historical notes saying he still has a painted/unmodelled face or needs a better reference sheet are obsolete.

## Current creature art state

The three starter sheets remain the direct visual source of truth for:

- Terrapup — Ground starter;
- Ripplet — Water starter;
- Galewisp — Air starter.

The owner's later Meadows Wild Canon Pack in `docs/art/wild/`, with sheets in `docs/art/reference/wild/`, is authoritative for the twelve wild species and Tuskroot. It makes `Mudsnout -> Tuskroot` the Meadows' only normal evolution and retires the older evolved-canine assumption.

## Important use rule

Reference images establish visual language, proportions, materials, silhouette quality and character identity. Markdown/current decisions win on mechanics, names/types where explicitly settled, and production status.

Do not infer a new species, type, mechanic, or required asset merely because an older concept board depicts it.

## Key reference files

- `reference/01_Ground_Starter_Terrapup.png`
- `reference/02_Water_Starter_Ripplet.png`
- `reference/03_Air_Starter_Galewisp.png`
- `reference/04_Main_Character_Style_Reference.png`
- `reference/12_NPC_Bases_Reusable.png`
- `reference/13_Tether_Energy_Pylon.png`
- `reference/14_Relay_Apparatus.png`
- `reference/15_Legendary_Tether_Machine.png`
- `reference/16_Warden_Aldis_Character.png`
- `reference/wild/` — production sheets for the current wild roster

Boards `05`–`11` remain useful historical exploration/donor references where a current source explicitly still points to them, but they do not override newer production sheets, current installed assets, or settled markdown canon.
