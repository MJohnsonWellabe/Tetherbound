# LOOK close-1022 (tb/look)

## TO COORDINATOR

- 2026-10-22 08:40 CT QUESTION P2-094: the "stray plank at the base" is not the wall. `tools/phase2_capture_build_systems.gd` places the floor piece where a world boulder already stands, so the floor's edge pokes out under the rock beside the wall. May I move that fixture's floor and wall to clear ground, keeping the same camera, or must it stay as the catalog fixture?
- 2026-10-22 08:40 CT WARNING (all lanes): `data/config/terrain_playground.json` fingerprints the scatter bake. Any byte change there, even an added OFF candidate key, makes `vegetation.gd` refuse to build ("Stable harvest generation is invalid"), and the world renders with no trees. tb/look carried such a key for one commit; it now lives in `terrain_presentation.json` (`texture_candidates`), and `terrain_playground.json` is byte-identical to main again.
- 2026-10-22 08:40 CT STATUS: F04#6 r23 maps to 5.75, the same as shipping (5.75), on CPU, so it is one flat round. r24 (painted grass plus the Dell fixes) is rendering. P2-094 r5 is pushed OFF and comes next. Zero closures.

## Work log

- F04#6: see `F04-6.md`.
- P2-094 wall r5 (OFF): `build_wall_interior.json meshy_wall.r5`:
  - darker infill and backing;
  - an oak post at each end;
  - a 0.2 m cap with 0.16 m overhang;
  - an earth footing strip.
- Painted Meadows grass (OFF): `terrain_presentation.json texture_candidates.grass`, made by `tools/art_pipeline/make_painted_grass.py`.
