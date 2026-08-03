# Asset Ledger

Provenance for every non-original asset in the project, per `CLAUDE.md` and
`docs/TECHNICAL_START.md`.

Assets do not need to be CC0 for this private project. The rule is that nothing
ships without a row here, so attribution is a lookup rather than an archaeology
project, and so a licence audit before any public release is possible at all.

A row is required **before** the file is committed. Record the licence as found
at the time it was fetched, not as remembered.

| Asset | Creator | Source | Licence | Paid | Local path | Modifications |
|---|---|---|---|---|---|---|
| Meadows key art board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/reference/tetherbound-meadows-keyart.png` | None |
| Palworld screenshots ×5 | Pocketpair | Owner-supplied screenshots | Reference only, not shipped | No | `docs/reference/palworld-0*.jpg` | None |
| Trainer character (`character-a`) | Kenney | [Blocky Characters](https://kenney.nl/assets/blocky-characters) | CC0 1.0 | No | `assets/characters/trainer.glb` | Renamed. 27 baked clips kept as-is. |
| Trainer textures | Kenney | [Blocky Characters](https://kenney.nl/assets/blocky-characters) | CC0 1.0 | No | `assets/characters/Textures/` | None |
| Meadow Hopper (rabbit) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/dyeBDJxhDwP) | CC-BY 3.0 | No | `assets/pals/meadow_hopper.glb` | Renamed. Scaled at runtime to the gameplay collider. |
| Thornback (boar) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/57fSWum6F1P) | CC-BY 3.0 | No | `assets/pals/thornback.glb` | Renamed. Scaled at runtime. |
| Bramblit (fox) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/10u8FYPC5Br) | CC-BY 3.0 | No | `assets/pals/bramblit.glb` | Renamed. Scaled at runtime. |
| Nature Kit — 27 models | Kenney | [Nature Kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 | No | `assets/environment/nature/*.glb` | Curated subset of 329; trees, bushes, grass, flowers, rocks, logs. Unmodified. |

**CC-BY 3.0 carries an attribution obligation.** The three creature models are
placeholders standing in for bespoke art (see `docs/decisions/D10`), but while
they are in the build the credits owe Google and Poly Pizza a line. Kenney's CC0
work does not require it; crediting him anyway is good manners.

## Rules

- `docs/` carries a `.gdignore`, so nothing in it is imported by Godot or
  included in an export. The reference images are documentation, not game
  content, and the Windows export preset excludes them explicitly.
- Never assume an asset is redistributable. "Free to download" is not a licence.
- Prefer assets with animations appropriate to their role over assets that look
  better in a still.
- Test scale and materials in-engine before committing to a roster. A pack that
  looks cohesive on a store page can fall apart under one directional light.
- If the game is ever distributed publicly, audit this table and purchase or
  replace anything that needs it.
