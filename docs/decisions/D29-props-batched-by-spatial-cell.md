# D29. Props are batched by spatial cell, not by terrain chunk

Kind: implementation

The frame measured 1576 draw calls against ARCHITECTURE.md's budget of 150.
`ChunkManager` built one mesh per prop family per terrain chunk, which let chunk
size implicitly decide the draw distance of every prop in the game. Grass is
invisible past ~40m and an oak reads at 200m; batching both at 64m is wrong for
both, producing hundreds of near-empty grass batches and hundreds of redundant
tree batches.

Each family now declares its own `drawDistance` and a `cellSize` equal to it in
`scatter.json`, and `PropBatcher` builds one thin-instance mesh per (family x
cell). A disc of radius R touches at most a 3x3 neighbourhood of cells R across,
so nine cells per family is the hard ceiling and each is one draw call.

Generation did not change. `scatterInRect` is defined on a global jittered grid
with no reference to chunks or cells (D19), so props land exactly where they
did. Verified by counting oaks within 60m of spawn before and after: 5 both
times.

Terrain moved to 128m chunks at view distance 3, covering more ground in 29
meshes instead of 81, with `LOD_RESOLUTION` doubled so grid spacing is
unchanged. Shadow casters are distance-culled per cell rather than every
collidable batch casting.

Measured at 1280x720 in a dense grove: 1576 draw calls and 224k triangles down
to 67 and 137k.

This is the spatial-cell thin-instance batching that D01 cited as a reason to
choose Babylon over Three.js, finally applied.
