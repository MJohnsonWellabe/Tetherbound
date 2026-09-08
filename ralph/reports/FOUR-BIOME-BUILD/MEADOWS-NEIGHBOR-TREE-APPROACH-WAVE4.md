# Native exact-neighbor harvest diagnosis — wave 4

This is synthetic native geometry and input evidence, not campaign completion.
The fresh campaign reached wood 40/42, then could not select its original
tree at (78.98997, -2.175245, -44.09865). No production data, interaction
radius, helper attempt count, or movement budget changed in this diagnosis.

## Exact fixture

`tools/_probe_neighbor_tree_material_approach.gd` reads the shipped scatter
region `data/scatter/playground/region_0_-1.bin`, retains target trees#892
(CommonTree_3, scale 0.94999218) and neighbor trees#889 (CommonTree_2,
scale 1.35764771), and all other colliding placements within 12 m. It omits
only the previous tree at (73.17308, -1.875435, -51.2081), already harvested
in the fresh log. Fourteen standing placements remain. Actual Player,
InteractionArbiter, vegetation prompt construction and collision shapes run
over a 1 m triangle patch sampled from the canonical playground heightfield.
This is not a loaded Terrain3D world; native grounding can differ slightly.

Stone retains its production item, yield and `1 + scale` prompt height;
wood retains the current human-height 1.4 m anchor. Both standing verbs are
called **Chop** by production, including rocks. Labels in the log therefore
do not indicate that stone was incorrectly constructed as wood.

The default admission-only mode disconnects harvest callbacks and observes
physical activation. Mining mode instead retains the production callbacks,
ledger and production collision batch bookkeeping, and uses the actual HUD
scene for ordinary hotbar input. Its initial tool inventory and hotbar are
explicit synthetic preparation. No owner save is loaded; each launch uses a
new isolated APPDATA directory. No target or neighbor is skipped as progress.

## Controls and rejected explanations

Logs are under `C:/Users/mattj/AppData/Local/Temp/`; every prefix below has
separate `-console.log`, `-engine.log` and isolated `-profile` directory.

| Prefix | Result |
| --- | --- |
| `wave4-neighbor-trees-old` | Two-tree-only control passed exit 0. Neighbor alone does not reproduce the failure. |
| `wave4-neighbor-fullpatch` | Actual local cluster reproduced exit 1. Original target prompt 1.9724 m away; neighbor 1.6508 m wins. Grounded, zero unsticks. |
| `wave4-neighbor-winning-frames` | Same movement plus read-only observation: zero target-winning frames in all 17 movement legs (initial, ten stances, six press repositions). Stop-on-winner alone cannot fix this reproduction. |
| `wave4-neighbor-stance-scan` | 13,556 sampled points within the unchanged 2.6 m prompt sphere: 12,610 occupied by props, 946 capsule-free, zero exact target winners. Exit 1. |
| `wave4-neighbor-remove714` | Explicit fixture omission of only rock#714 collider and prompt: 12,599 occupied, 957 free, still zero winners. Exit 1. Single-rock removal is insufficient. |

The scan uses the actual Player capsule (radius 0.4, height 1.8, safe margin
0.001) and actual physics prop overlaps, prompt offers and arbiter ranking.
Candidate foot height comes from the canonical heightfield. The floor and
current distant player are excluded from the prop-overlap query. A 1-degree,
5-cm sample lattice is diagnostic resolution, not a gameplay approach ring.
Zero sampled winners is not a mathematical proof of continuous impossibility.
No candidate walk followed either empty scan.

Rock#714 lies only about 0.384 m XZ from the target tree's base and has
production scaled collision radius 1.4282 m. The neighboring rock cluster
also occupies the existing small stance rings. The exact collision query,
not a guessed larger interaction distance, drove the next strategy.

## Ordinary mining control

Production already supports pickaxe mining: the actual standing prompt
starts the tool swing, submits `deplete_vegetation`, the committed delta
calls `vegetation.fell`, removes its collider and stands a separately
gatherable stone pile. The original material helper performs both physical
stages and checks the inventory receipt.

`wave4-neighbor-mine716-hud-scene` passed exit 0: walked to rocks#716 in
81 physics frames, exact prompt won at 2.3634 m, ordinary hotbar equipped
pickaxe, physical mining plus pile pickup earned stone +2, collider count
14→13, no remaining felled pile, no helper failures or unsticks. Its console
has no ERROR/WARNING lines. Neighbor and original tree remained alive.

Two earlier mining-fixture failures are retained, not campaign defects:
`wave4-neighbor-mine716` lacked the HUD's hotbar reader and stopped at equip;
`wave4-neighbor-mine716-hud` instantiated only the HUD script without its
required scene children and emitted script errors. The corrected control
instantiates the shipped HUD scene. These invalid controls are not clean
runtime evidence.

The finite follow-up `wave4-neighbor-mine-approach` attempts actual rocks
#716, #718 and #719, then the ORIGINAL trees#892, using unchanged helper
movement/selection/press/pickup bounds. It failed in fixture setup before any
mining: a conditional untyped array could not be assigned to `Array[int]`.
The native process was stopped; the declaration is corrected to `Array`,
but the sequence has NOT been run after that correction. The owner asked
to stop expanding diagnostics and prioritize playable content, so no new
launch followed. Full original-tree access after mining remains unproved.
