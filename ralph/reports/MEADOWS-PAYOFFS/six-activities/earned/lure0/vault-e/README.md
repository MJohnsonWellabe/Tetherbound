# Warrens vault lure, set E (F03#0)

- **Changes:** existing assets and lights only.
  - `data/config/burrow_warrens.json` `site.vault_door_seam`:
    - the seam is wider, warmer and brighter;
    - the den-side floor pool is stronger;
    - a new den-side lintel light (`burrow_warrens.gd` `VaultDoorLintelGlow`, off unless configured).
  - Two small `Bonfire_Fire` fire-pots flank the door on the den side. This is the chapter's existing lit-doorway recipe (Grandpa's door fire-pot).
  - Walker: the den-entry shot stands at the den threshold and faces the door itself, not the vault centre. A leg shot waits (up to 5 s) while a wild creature's Engage prompt is up, so the camera is not inside it. A walk stuck beside a wild creature presses its Engage prompt.
- **Run:** local render (see `../RENDER.txt`), from the derived disclosed fixture `S06-exit-band3-warrens-uncleared` (S06 with only `warrens_cleared` removed).
  - `vault_06` den entry, at 19 m: the guardian stands at right, and the door is lit at left.
  - `vault_08`: at the door.
  - The walk is lure-only and ends "stuck" at the still-shut door, as in set D.
- **Disclosure:**
  - The vault walk is not deterministic under llvmpipe: wild creatures in the hall and den move differently run to run.
  - While tuning, about fifteen local vault runs were made on successive walker/config revisions. Several had the camera inside a creature or stuck at the mouth.
  - This set is the one run at the committed code and config. It was not picked from repeats.
