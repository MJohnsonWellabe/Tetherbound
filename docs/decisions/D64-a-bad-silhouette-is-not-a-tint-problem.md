# D64. A bad silhouette is not a tint problem

Kind: implementation

The vegetation moves from the Kenney Nature Kit to Quaternius Stylized Nature.
This record is mostly about how much time went into avoiding that move.

## What happened

The Meadows read wrong and the diagnosis started with the numbers, which were
all genuinely bad and all genuinely fixable in data: ground cover at one tuft
per 20.6 m², a `minDistance` of 2.1 that capped density no matter what
`density` said, a 19m circle of suppressed ground cover centred on the spawn
point, `variants[0]` hardcoded so every tree in the world was one mesh, and no
per-instance colour so every one of them was the same green.

All of that got fixed. The frames got denser, greener and better lit, and the
foliage still looked wrong, so the response was to tune the tint harder: pull
blue down, push red up, widen the per-instance spread. What the owner said,
looking at the result, was that the bushes looked horrible and were a huge part
of the problem.

They were right, and no value in `scatter.json` was ever going to fix it. The
kit's `plant_bush` and `plant_bushDetailed` are flat-shaded spiked fans. At one
per 150 m² they are scenery; at real density they are a field of green
starfish. **The silhouette was the defect, and tint, scale and density cannot
change a silhouette.**

## The rule

When a family looks wrong at density, check the source model's shape before
touching its numbers. Density and tint changes are cheap to make and cheap to
believe in, which is exactly why they absorb hours that a five-minute look at
the model would have saved. D51 established the same shape of lesson for
triangles ("for a family you meet a thousand at a time, the source model IS the
budget"); this is the same sentence with "silhouette" in it.

## What shipped

Vegetation is now Quaternius Stylized Nature, pulled from poly.pizza through
the existing scraper. The pack is the same artist as all fifteen creatures, all
five humanoids and every village building (D62), so this also closes a real
cohesion problem: the world was three art styles in one frame.

Cost, accepted under D63's lifted ceiling: 3x to 16x the triangles of the
models replaced. Grass 96 against 36, bush ~360 against 104, tree ~1800 against
114. Only the trees carry a simplify pass. Every job takes the same gamma 0.4
brighten the village buildings needed, because the pack bakes shading into its
albedo.

The Kenney kit is still the source for standing stones, logs and stumps. They
are met one at a time, they are stone and wood rather than foliage, and the
complaint that moved the vegetation does not apply to a boulder.

## Pick models on measured values, not on their names

Three of the six "Bush" models in the pack are unusable and the names say
nothing about which. Measured baked vertex-colour means, after the full
pipeline:

| model | mean COLOR_0 | verdict |
|---|---|---|
| bush_e | 0.000, 0.000, 0.000 | pure black, unusable |
| bush_c | 0.078, 0.069, 0.081 | near black, unusable |
| bush_a | 0.345, 0.431, 0.297 | usable, agave rosette |
| bush_d | 0.817, 0.866, 0.190 | usable, agave rosette |
| bush_f | 0.564, 0.288, 0.264 | shipped; berries drag the mean red |

Shape needs measuring too. Height-to-width ratio sorted the rosettes from the
shrubs faster than any amount of looking at thumbnails would have: bush_d 0.63,
bush_a 0.73, bush_f 0.84. Only the last is shrub-shaped.

`tools/probe.mjs` exists because of this. Three frames instead of the survey's
nine, and a `--close` framing at head height, because the survey's 3.2m eye
pitched down flattens a tuft into a speck and hides exactly the defects this
round was about. Iterating a material against a ten-minute survey is how a
tint pass eats a night.

## The one that was never a bush

The large flat rosettes in every village frame survived four bush swaps because
they were never bushes. They were `reed_a`, the fern, which is 9 metres wide
natively and was still 2.7m wide after scaling, planted across every riverbank
including the one Hollowbrook stands on. Four models were changed to fix
something the fifth was causing.

Worth stating plainly: the frames were read correctly every time and attributed
wrongly. A visual defect needs its family confirmed before its model is
swapped, and `?debug=build` or an instance count would have said so in seconds.
