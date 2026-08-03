# D03. Terrain is unresolved, and M1 cannot start until it is

Kind: open question

Godot 4 ships no terrain system. `docs/MEADOWS_VERTICAL_SLICE.md` M1 requires
"rolling terrain" and M7 requires an authored region with hills, a grove, a
stream and an outcrop. Neither is reachable without picking one of these, and
`docs/TECHNICAL_START.md` does not mention terrain at all. This record exists to
stop that gap being discovered halfway through M1.

## The options

**Terrain3D.** Sculpting, texture splatting, LOD, foliage scattering. It is a
GDExtension, so it ships compiled per-platform binaries and becomes a build
dependency; a Godot version bump can require waiting for it. Strongest fit for
"the ground reads as a continuous grass surface", which is the second of the
three findings that killed the prototype.

**HTerrain.** Pure GDScript, no native dependency, therefore no version-bump
risk. Older, less actively developed, heightmap-only workflow.

**Sculpted mesh from Blender.** No plugin at all, total authoring control, and
correct for exactly one hand-authored region. Bad for iteration: every terrain
change becomes a round trip through another program, and the owner does not use
Blender.

## Recommendation

Terrain3D, with the Blender mesh as the fallback if it fights the toolchain.
The deciding factor is texture splatting. "Bare dirt with props stabbed into it"
was a named defect in the prototype critique, and splatting is the mechanism
that fixes it; the other two options make it hand-work.

## Not yet decided

Deliberately left open for the owner, because it adds a dependency to a project
whose whole premise is finishing. Flagged rather than silently chosen, per
`CLAUDE.md`'s Ask/Flag rule.
