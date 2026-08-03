# D05. Terrain3D, and terrain is authored rather than generated

Kind: implementation

Resolves the open question in D03. The owner chose Terrain3D and set the
direction: terrain is **authored macro geography**, not a procedural Valheim
seed. Terrain3D owns height, shape and ground materials. Procedural rules may
later place vegetation, rocks, gatherables and pal spawns *within* authored
zones, but they never decide where the hills are.

## What shipped

Terrain3D 1.0.2, MIT, from the Godot Asset Library. `compatibility_minimum` is
4.4 and the project is on 4.7, so it loads.

Committed under `addons/terrain_3d/`, trimmed to the platforms this project
targets: Windows x86_64 and Linux x86_64. The release ships Android, iOS, macOS
and Web binaries too, which is 52 MB; dropping them halves it. The rows for the
dropped platforms are removed from `terrain.gdextension` as well, because a row
pointing at a deleted file warns on every import and hides real warnings.

Linux is kept alongside Windows because the development environment for this
project is headless Linux and it is what runs CI.

## Authoring terrain without the editor

Terrain3D is normally sculpted by hand in the Godot editor. This project's
development environment has no display, so the M1 playground is generated from
a seeded recipe and baked to disk:

    godot --headless --path . --script scripts/world/build_playground_terrain.gd

`scripts/world/playground_heightfield.gd` is the shape as a pure function of
position, so it is testable and can be re-baked at any resolution. The builder
turns it into a height image and a colour image and imports both.

This is **not** a world generator and nothing calls it at run time. It is a
reproducible way to author one specific test area, which hand-sculpting is not:
the same config always bakes the same playground. When the real Meadows is
authored, the owner sculpts it in the editor and this whole path becomes
unused, which is the intended outcome.

## Ground colour without any texture assets

The bake writes Terrain3D's colour map from surface slope: grass on walkable
ground, soil on the shoulders, rock on genuinely steep faces, from the palette
in `data/config/palette.json`. That gives a cohesive ground surface with zero
texture assets and no splatmap authoring, which is enough for a movement
playground and is explicitly a placeholder for a real material pass.

## Two engine behaviours that cost time, recorded so they cost it once

**`data_directory` must be assigned after the node is in the tree and a frame
has passed.** Terrain3D constructs its `Terrain3DData` on the node's first
frame. Setting the directory before that leaves `data` permanently null, logs
only `Resource file not found: res://`, and produces a terrain that renders
nothing and has no collision. The player then stands on empty space at the
origin, which looks enough like working to pass a careless check — and did.

**The first import on a clean checkout exits non-zero.** The extension's cold
class registration makes Godot abort on shutdown after the import work has
finished. It reproduces with the terrain data removed entirely, and the second
pass is clean and instant. CI tolerates the first and gates on the second.

## Cost

A compiled dependency in a project whose premise is finishing. A Godot version
bump now needs a matching Terrain3D release, and 26 MB of binaries are in the
repository. Accepted because texture splatting is the mechanism that fixes
"bare dirt with props stabbed into it", which was a named defect in the
prototype critique, and the alternatives make it hand-work.
