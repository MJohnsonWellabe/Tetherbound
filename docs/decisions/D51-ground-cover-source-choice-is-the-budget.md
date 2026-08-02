# D51. Ground cover is chosen by triangle cost, not by detail

Kind: implementation

Grass, reeds and flowers render by the thousand through thin instances, so the
per-model triangle count of those three families decides what the whole world
can afford. They are picked from the kit by cost first and silhouette second.

The Meadows read as a bare golf course: 384m of visible terrain with ground
cover stopping at 44m and nothing between. Measuring where the triangles
actually went explained why.

| family | model | tris | instances | total |
|---|---|---|---|---|
| grass | `grass_large` | 224 | 441 | 98,784 |
| reed | `crops_bambooStageA` | 276 | 181 | 49,956 |
| oak | `tree_default` | 114 | 277 | 31,578 |
| bush | `plant_bushDetailed` | 104 | 261 | 27,144 |

Two ground-cover families were spending 148,740 triangles, more than half the
prop budget, on the two things you can barely see, while the trees that carry
the landscape cost a third of that. The draw distances had been cut to 44m and
64m to fit, which is the wrong end of the problem to squeeze.

The Nature Kit already contains the cheap versions. `grass_leafs` is 36
triangles against `grass_large`'s 224 and reads identically past about 15m;
`plant_flatShort` is 44 against bamboo's 276. Swapping the sources cut ground
cover by roughly 125,000 triangles and paid for doubling the grass draw
distance to 88m, raising meadow tree density, and doubling rock and bush
density, while total triangles went DOWN from about 311k to 226k and draw calls
from the 142-149 band to 125-132.

The rule this leaves behind: for any family whose instance count runs to the
hundreds, look up the source model's triangle count before tuning its density
or its draw distance. Detail on a model you meet ten at a time is worth paying
for. Detail on a model you meet a thousand at a time is the budget.

Simplifying the detailed model instead does not work here, for the reason in
D52: the simplifier was already configured and was silently doing nothing.
