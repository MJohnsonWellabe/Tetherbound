# Ripplet — production report

Second character through the `tools/art_pipeline` chain. The process is
Terrapup's (`TERRAPUP_PRODUCTION_REPORT.md` is the long-form template); this
records what differed.

## Summary

| | |
|---|---|
| Reference | `docs/art/reference/02_Water_Starter_Ripplet.png` |
| Candidates | 1 round × 3 preview; blind critique chose **c** ("carries the most identity features: lobed ear frills, crest spike, head-heavy proportions") |
| Mesh fixes | `fix_ripplet_c.py`: tail fan 1.7× and rotated 38° **up**, thighs 1.22× |
| Rig | `rig_sitter.py` (new skeleton: hind legs, held forepaws, two-bone tail fan) + `skin_transfer.py` — 16,037 verts, 0 unweighted |
| Clips | 6, sitter set: held-paw idle, hop gait, body-driven double paw-swipe attack |
| Grade | `grade_ripplet.py`: pale cyans → sheet teal (#5FA8BE), pink frills +35% saturation, roughness floor |
| Shipped | `assets/pals/tetherbound/ripplet/models/pal_ripplet_lod0.glb` |
| Gate | In-engine critique round 1: close-but-not-yet, both iterate-now items colour-level; the teal grade addressed them. Post-grade frames read blue at every distance. |

## What this creature taught the pipeline

- **"Rearmost ground contact = feet" is false** when the tail itself touches
  the ground. The first tail edit found zero vertices on a creature whose
  tail is its defining feature. Feet now come from the middle band of body
  length, in the fix scripts and the rigs alike.
- **Never open a generated surface before voxel remeshing.** Deleting the
  dangling whisker took chin surface with it, and the remesher answered the
  open mesh by double-shelling the entire body — every render came back as
  crumpled foil. The remesh eats sub-voxel strands anyway; the right amount
  of whisker code is none.
- **Bone heat is a lottery on retextured meshes** — 14,025 of 14,025
  unweighted here after the same weld that worked for Terrapup. The
  weight-transfer path (`skin_transfer.py`: rig the clean twin, copy weights
  by nearest face) replaces the lottery for every future creature.

## Known imperfections

- The tail fan and ear frills are opaque; the concept's translucency is
  faked in albedo. Real membrane transparency needs the fan split to its own
  material — deferred as over-investment for one of nineteen (the gate
  critique's own words).
- The fan has two lobes, not the concept's four-to-five; scallops are left
  to the texture.
- Clips are procedural cycles, same caveat as Terrapup's.

## Owner review

§18's last box is yours, same as Terrapup: the frames are in
`shots/validation/ripplet_*` and the sheets in `shots/candidates/`.
