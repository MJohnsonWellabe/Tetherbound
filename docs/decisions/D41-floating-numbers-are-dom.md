# D41. Floating numbers are pooled DOM, not in-canvas text

Kind: implementation

Damage numbers and pickup totals render as pooled `<span>` elements positioned
by projecting a world point to a pixel, not as sprites or meshes in the scene.

`ARCHITECTURE.md` already puts the HUD in an HTML overlay because it is cheaper
and more accessible than in-canvas UI. The argument is stronger for text that
moves: in-canvas text needs a font atlas, a material and at least one draw call
per batch, charged against a 150-call budget, and it renders at whatever
resolution the atlas was baked at. A `<span>` costs nothing against that budget,
gets real font rasterisation at any DPI, and inherits `tokens.css`, so the colour
semantics hold automatically (lime for a gain, Tether orange for damage).

Three details that make it work rather than merely compile:

- **The pool is fixed and pre-created.** At capacity the oldest live number is
  recycled. Twenty simultaneous numbers are unreadable anyway, so recycling
  costs nothing visible, and the alternative is a DOM insertion during the
  busiest frame in the game.
- **Only `transform` and `opacity` are written per frame.** Both are compositor
  properties. Writing `left`/`top` instead forces a layout pass per number per
  frame, which is how a cosmetic overlay becomes a frame-time problem.
- **The view-space depth is checked before projecting.** A point behind the
  camera still projects to finite screen coordinates, mirrored into view, so a
  chop at the player's back would paint a number in front of them.

Ages advance on the fixed simulation step rather than on wall clock, so numbers
hold still during a hit pause along with everything else.

The cost of this choice is that numbers cannot be occluded by world geometry:
they always draw on top. For a number whose entire job is to be read, that is
the behaviour we would have implemented deliberately anyway.
