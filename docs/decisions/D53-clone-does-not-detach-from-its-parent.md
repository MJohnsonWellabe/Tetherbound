# D53. `Mesh.clone(name, null)` does not detach, and it cost us the world

Kind: implementation

Anything cloned from a loaded glTF container must have its parent cleared
explicitly. A null `newParent` argument means "leave the parent alone", not "no
parent".

The Meadows looked empty for several sessions. Trees, bushes, grass and flowers
were all scattered, all in the right places according to every CPU-side check,
and almost none of them were on screen. Raising the density did nothing.
Doubling the draw distance did nothing. The absence was blamed on a
SwiftShader rendering artifact and written off twice.

The cause: `PropModels.ts` built each prototype with

    const proto = source.clone(`proto_${family}_model`, null);

`source` is a mesh inside the loaded `AssetContainer`, parented to the loader's
`__root__` node, which carries the right-handed to left-handed conversion. The
clone kept that parent. The next line baked the prototype's world matrix into
its vertices, which correctly included the conversion, and then the parent
applied the conversion a second time at render.

Two applications of a mirror is a mirror. Every prop in the world was drawn
reflected through the world origin, so the trees standing next to the player
were drawn at twice their distance on the far side of the map, and the trees
drawn near the player were the ones that genuinely stood 400m away. Density
changes could not possibly have helped, which is exactly why they did not.

What actually settled it was refusing to accept the artifact story and
measuring instead of looking: hide every thin-instanced prop cell, screenshot,
show them, screenshot, and diff the two frames. Props were changing 3.5% of
the pixels. After the fix, 27%. A number moved, so the argument ended.

Three lessons worth keeping:

- **"It renders wrong" is not the same claim as "it renders nowhere".** The
  giant dark wedges in the survey frames were a real and separate puzzle, and
  attributing the missing vegetation to them meant nobody asked the simpler
  question of where the vegetation actually was.
- **A visual bug deserves a numeric test.** Eyeballing a software-rendered
  frame is how three sessions disagreed with each other. A pixel diff between
  two states is cheap, objective, and settles it.
- **The same trap sits in `placeStructure`.** D47 is this bug's twin, found
  first and fixed separately: there the mirrored transform was carried on the
  clone rather than doubled, so buildings rendered inside out instead of
  displaced. Both come from the same misreading of `clone`'s second argument.
