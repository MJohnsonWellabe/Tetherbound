# BELOW6-WALL-BAND: pale top band on Cloudreach island walls (F40#1)

Row: F40#1 Cloudreach open terrain (GPU High 5.90). Step 1 of the BELOW6-F40-1 note: at the Realm Gate Crag approach stand the lower fifth of the frame is the island's own side wall under the turf lip, a dark brown band.

## What draws it

No false-colour capture was needed: `_mesa` in `scripts/world/cloudreach_world.gd` emits every wall band of a mass into one surface in `cliff_high` (unless the side material is `cliff_shadow`). Lit from behind, that tan reads dark brown.

## Arm

`data/config/cloudreach_visual.json` `landmass.wall_top_band_1113` (OFF): for masses labelled `LandmarkLedge` and `CliffMass`, the first wall band (turf lip down to the upper ring) is emitted with the same vertices into its own surface, in the same cliff texture under a pale tint (`#eeece4`). Material only: no vertex moves, and the collider is built from the crown alone. Cloudreach only (the code is `cloudreach_world.gd`). Overlay: `overlay.json`.

## CPU

- `_sheet_cpu_matched_first_tint.jpg`: Realm Gate Crag approach, base (left) against the arm at the first tint `#f1e6cc` (right), same stand. The dark soil band becomes a pale faceted stone band.
- `_sheet_cpu.jpg`: top left base; top right the same landmark's approach at the shipped tint (a different survey stand in this run, with the cobble pad in view, so not a matched pair); bottom, Heartstone approach and Sky Shrine close with the flag on. Those two show no island wall, so the arm does not change them.

Honest read: one of the row's three frames changes. At the shipped tint the band is a smooth pale cream that can read as sand as much as rock; the first tint kept more of the texture's facets. If the pre-check finds it sandy, use `tint` `#d9d6cb`. This is a no-loss risk for every Cloudreach frame that looks across at another island's wall, so it needs a wide no-loss set (Three Bells, High Perches, the overlook).
