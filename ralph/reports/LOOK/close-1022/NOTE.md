# LOOK close-1022 (tb/look)

## TO COORDINATOR

- 2026-10-22 08:40 CT QUESTION P2-094: the "stray plank at the base" is not the wall. `tools/phase2_capture_build_systems.gd` places the floor piece where a world boulder already stands, so the floor's edge pokes out under the rock beside the wall. May I move that fixture's floor and wall to clear ground, keeping the same camera, or must it stay as the catalog fixture?
- 2026-10-22 08:40 CT WARNING (all lanes): `data/config/terrain_playground.json` fingerprints the scatter bake. Any byte change there, even an added OFF candidate key, makes `vegetation.gd` refuse to build ("Stable harvest generation is invalid"), and the world renders with no trees. tb/look carried such a key for one commit; it now lives in `terrain_presentation.json` (`texture_candidates`), and `terrain_playground.json` is byte-identical to main again.
- 2026-10-22 09:15 CT ANSWERED (coordinator, 08:54): fixture moved to clear ground, camera unchanged (`tools/phase2_capture_build_systems.gd`). The real-game bug was confirmed and fixed: `build_placer.gd preview_placement` now refuses ordinary pieces whose footprint overlaps world geometry (`tests/test_build_placer_world_overlap.gd` passes).
- 2026-10-22 09:15 CT STATUS: F04#6 r24 maps to 5.71 against shipping 5.69, the second round under +0.5 (CPU). The next approach is the new art below plus anisotropic ground filtering.
- 2026-10-22 08:40 CT STATUS: F04#6 r23 maps to 5.75, the same as shipping (5.75), on CPU, so it is one flat round. r24 (painted grass plus the Dell fixes) is rendering. P2-094 r5 is pushed OFF and comes next. Zero closures.
- 2026-10-22 09:15 CT MESHY docs/reference/tetherbound-meadows-keyart.png (crop: Team Tether stronghold) + docs/art/reference/13_Tether_Energy_Pylon.png + docs/reference/palworld-04-plateau-landmark.jpg | 11.2 m wide x 8.7 m tall x 2.6 m deep overall; clear arched opening 6.8 m wide x 7.2 m to the springing (4.8 trainers tall) | F04#6 Dell + F38 P2-013: hero relay gatehouse arch replacing the tiled WallEntranceBricks kit arch at the Tether relay gate (tether_relay.gd _build_gate_presentation fits any mesh to these bounds). Weathered fieldstone masonry with depth (rusticated quoins, a projecting cornice, a keystone), moss in the joints, a dark iron Team Tether retrofit (riveted plates, a cable conduit with a cyan glow strip, an iron portcullis slot). Oxblood only on small Tether plates. Chunky stylised Palworld-class readable silhouette. Every GPU and CPU judge names this wall as new_art.
- 2026-10-22 09:15 CT MESHY docs/art/reference/13_Tether_Energy_Pylon.png + docs/reference/palworld-02-open-field-path.jpg | lying 6.0 m long x 1.2 m wide x 1.4 m tall; the standing post 2.4 m | F04#6 Riverwatch aftermath hero: a smashed Team Tether river-road toll boom. A thick timber barrier pole with iron Tether bands and a counterweight, snapped in two and thrown off its pivot post onto the verge, with a broken padlock chain. Replaces the shared fallen-banner kit there.
- 2026-10-22 09:15 CT MESHY docs/art/reference/13_Tether_Energy_Pylon.png + docs/reference/palworld-03-field-boss-meadow.jpg | lying 2.6 m long x 1.4 m wide x 1.1 m tall (2.5 m tall if stood) | F04#6 Ridge aftermath hero: a toppled Team Tether signal brazier on an iron tripod, knocked over and cold, with spilled dark coals and ash and a dented cyan-glass lens. Replaces the shared fallen-banner kit there.

## Work log

- F04#6: see `F04-6.md`.
- P2-094 wall r5 (OFF): `build_wall_interior.json meshy_wall.r5`:
  - darker infill and backing;
  - an oak post at each end;
  - a 0.2 m cap with 0.16 m overhang;
  - an earth footing strip.
- Painted Meadows grass (OFF): `terrain_presentation.json texture_candidates.grass`, made by `tools/art_pipeline/make_painted_grass.py`.
