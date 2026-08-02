# D30. Vertex colours only where geometry needs them

Kind: implementation

Trees are welded into a single mesh so a tree costs one draw call and one thin
instance rather than two. That requires vertex colours, because bark and leaf
have to live in one geometry.

Extending the idea to every family, one shared white vertex-coloured material
for all props, was tried and reverted. `proto_rock` is a sphere at
`segments: 2`, degenerate enough that attaching a colour buffer to it rendered
the entire rock batch as two screen-filling triangles across the landscape.

A prop that is one colour gains nothing from vertex colours, so the
single-colour families keep a flat material each. The lesson worth keeping is
that the bug was invisible to typecheck, tests, and reasoning about the code;
it was found by taking a screenshot.
