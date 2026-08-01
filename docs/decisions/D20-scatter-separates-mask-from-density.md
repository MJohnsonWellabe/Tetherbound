# D20. Scatter separates `mask` from `density`

Kind: implementation

Two parameters that sound like one, doing genuinely different jobs at
different points in the pipeline.

`mask` is hard exclusion (water, cliffs, the village footprint) and applies
BEFORE the spacing pass, so an excluded candidate never suppresses a valid
neighbour. Filtering it afterwards instead would let a candidate standing in a
river suppress the tree on the bank, leaving a bald ring around every
shoreline.

`density` is thinning and applies AFTER the spacing pass, which is the only
place it can control the count. This was caught by a test rather than
reasoned out in advance: thinning candidates beforehand took a 300x300m plot
from 837 points to 830, a 1% reduction from a parameter set to 0.5. Minimum
spacing is the binding constraint, so removing half the candidates just lets
the survivors close ranks. Post-filtering also leaves irregular gaps, which is
what a thinner stand of trees should look like anyway.
