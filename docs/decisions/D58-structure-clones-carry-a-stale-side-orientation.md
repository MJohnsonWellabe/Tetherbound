# D58. Structure clones carried a stale side orientation, and it read as missing walls

Kind: implementation

The owner reported village houses as "half walls or something weird" and said
you could see clean inside them on approach. Two earlier sessions looked for a
hole in the geometry and did not find one, because there was never a hole.

**What was actually wrong:** `bakedPrototype()` in `src/world/StructureModels.ts`
bakes the loaded source's world matrix into the prototype's vertices. That
matrix has a negative determinant (the glTF right-to-left-handed conversion the
loader puts on `__root__`), and Babylon's `bakeTransformIntoVertices` responds
to a negative determinant by calling `flipFaces()`, so the baked vertex data
comes out with counter-clockwise front faces. But the mesh ALSO carries an
`overrideMaterialSideOrientation` stamp of clockwise-front, set by the loader
for the mirrored transform the mesh was born under, and `clone()` copies that
stamp. Nothing reset it after the bake.

So every placed structure rendered with its front and back faces swapped. From
outside a house you were looking at the unlit interior surface of the far wall
through where the near wall should have been. Thin single-plate pieces
disappeared entirely from some angles. It looked exactly like a missing wall,
which is why it kept getting investigated as one.

**The fix** is one line: stamp the baked prototype
`Material.CounterClockWiseSideOrientation` so every clone inherits an
orientation that matches the vertex data it actually has.

**Why the earlier investigations missed it.** They tested the assets, and the
assets were fine. Per-side outward area, index winding against stored normals,
and a backface-culling raster all came back clean on the shipped GLBs, because
the defect is not in the file. It is introduced at placement time, four steps
downstream. The lesson worth keeping: when a rendering bug survives a clean
asset audit, the next place to look is the transform and material state the
runtime puts on the mesh, not the bytes on disk.

**How it was found:** by flipping `overrideMaterialSideOrientation` on the live
placed meshes in a browser and re-shooting the same camera pose. The walls
filled in. That took one experiment; two sessions of static analysis had not.
When a bug is about what the renderer draws, drive the renderer.
