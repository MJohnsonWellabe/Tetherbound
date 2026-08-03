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
