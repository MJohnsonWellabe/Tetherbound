# Ironwood ancient-tree Meshy refinements — code-blind review (2026-09-11)

## Verdict

**Winner: Refine A. Ranking: A > B.**

Refine A is the better visual reconstruction and the only candidate worth carrying
into a production cleanup pass. Its front and three-quarter views most closely retain
the reference's defining read: a wide ancient crown, interlocked rising trunk columns,
heavy lateral boughs, visible hollows and a broad grounded root plate. Refine B has a
strong root base but loses too much crown mass and branch cohesion.

Neither raw refined mesh should ship without geometry cleanup. The visual selection
does not override the severe topology risks recorded after ranking.

## Refine A — SELECT FOR CLEANUP

### Silhouette and gameplay-distance read

- **Front:** A is substantially closer to the reference than B. The crown forms a
  broad, mostly continuous umbrella, with lower lateral tiers extending the silhouette
  rather than reading as clipped branch ends. The fused trunk bundle and central lower
  hollow produce a recognizable ancient-tree landmark even at thumbnail size.
- **Three-quarter:** The strongest all-purpose view. Root flare, trunk twist and crown
  width remain readable together, and the main limbs form useful large negative spaces.
- **Back:** Maintains credible mass and a continuous trunk-to-crown hierarchy. It is
  less iconic than the front but still reads as the same colossal tree.
- **Side:** The major weakness. The tree compresses into a narrow, stacked foliage
  column, showing that the reconstruction still lacks the reference's true crown depth.
  This will matter on a location approached from several directions.

### Crown and fragments

The textured crown is fuller and more coherent than B's, but it is still assembled
from many angular paper-like leaf fragments. Large colour groups help fuse those
fragments at distance; close and side views expose sharp spikes, irregular detached
tips and a crumpled-surface read. It needs silhouette pruning and explicit LODs rather
than more leaf density.

### Roots and grounding

The broad front root flare is convincing and the large buttresses feel capable of
supporting the trunk. Some small root tips become flat shards, and the underside/pivot
is not visibly production-grounded. Consolidate the foot into fewer thick masses and
place it on a planar contact base.

### Material/style match

The grey-brown bark, muted moss and blue-green foliage are directionally close to the
selected hand-painted reference. The main forms remain legible through the texture.
However, the bark is somewhat washed and repetitive, while foliage variation is mottled
across individual fragments rather than organized into the reference's broad painted
light and shadow groups. Preserve the palette but repaint at the crown-lobe scale.

## Refine B — second

Refine B's front has a massive, grounded root plate and clearer deep hollows, but its
upper half is too sparse and evenly tiered. The visible limb ends and isolated leaf
clusters make it read more like an old pollarded tree than the reference's immense,
accumulated crown. Its side view is also narrow and top-heavy, and the lower foliage
stack obscures the trunk transition. Back and three-quarter views have large useful
negative spaces, but the outer crown breaks into several separate clumps with stray
leaf strips at the tips.

Its bark/foliage palette is coherent but flatter and darker than A's. At gameplay
distance, the massive roots would survive, while the thin lateral crown fragments
would shimmer or disappear, leaving a heavy stump with a small cap.

## Post-ranking topology risks

Both candidates contain a texture, but both remain extreme generated triangle soups:

| Risk | Refine A | Refine B |
|---|---:|---:|
| Triangles | 23,425 | 23,070 |
| Disconnected components | 14,292 | 14,403 |
| Non-manifold/boundary edges | 51,895 | 51,782 |
| Duplicate vertices | 40,974 | 41,071 |
| Approx. inward faces | 5,386 | 5,194 |
| Strongly stretched UV faces | 1,505 | 56 |

A's visible win is not a topology win. Its 1,505 stretched-UV faces are a specific
material risk absent from B: broad bark or leaf regions may smear at closer production
distance. Both meshes are off the ground origin and consist of thousands of microscopic
components, consistent with the visible leaf-fragment problem.

## Conditions for carrying A forward

1. Consolidate/weld the trunk and root structure, repair inward normals, and reduce the
   foliage to intentional crown components rather than thousands of debris islands.
2. Widen or selectively rebuild crown depth so the side silhouette remains colossal.
3. Prune detached leaf spikes and author at least one silhouette-safe gameplay LOD.
4. Re-unwrap the stretched faces and verify the bark/hollow material at close range.
5. Establish a flat contact underside and correct ground pivot before world placement.

Choose A for that cleanup. If the pipeline can only import the raw GLB unchanged,
**HOLD both**.
