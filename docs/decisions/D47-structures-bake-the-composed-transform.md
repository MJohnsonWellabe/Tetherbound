# D47. Structure models bake the composed transform into their vertices

Kind: implementation

A placed building is a clone of a hidden prototype whose world transform has
already been baked into its vertex data. Placement lives on the parent node.
Clones start from an identity local transform.

The first version carried the source's composed node transform on every clone,
decomposed into position, rotation and scaling. The reasoning was sound: two
things ride on that transform that the prop path can drop and this one cannot.
The glTF loader puts its right-handed to left-handed conversion on `__root__`,
and `KHR_mesh_quantization` puts a dequantization scale on the node, so a
quantized hall without it renders at raw int16 scale.

The handedness conversion is a mirror, so that composed matrix has a negative
determinant. Carrying it on a clone inverts the triangle winding, backface
culling then removes the faces that should be visible and keeps the ones that
should not, and every building renders inside out. On screen this reads as
see-through walls with the interior showing through the exterior, which looks
like a transparency or draw-order bug and sends you hunting in the wrong place.

`bakeTransformIntoVertices` handles exactly this: it transforms positions and
normals and calls `flipFaces` when the determinant is negative. Baking once per
loaded url fixes the winding, keeps the dequantization scale, and leaves every
clone on an identity transform, which is the same contract `PropModels.ts`
already uses for props.

Two details that are easy to get wrong:

- **Bake onto a unique copy.** `AssetLoader` caches containers, so baking the
  container's own geometry would corrupt the cached copy for every later
  caller. `makeGeometryUnique()` first.
- **Reset the node transform after baking.** `bakeTransformIntoVertices` bakes
  the matrix it is handed and leaves the node's own local transform standing.
  Without the reset the transform applies twice and the building lands at the
  square of its intended scale.

Placement, yaw and per-slot scale go on the parent node, which keeps the helper
reusable for houses, the Hall, stations, dressing and the standing stones.
