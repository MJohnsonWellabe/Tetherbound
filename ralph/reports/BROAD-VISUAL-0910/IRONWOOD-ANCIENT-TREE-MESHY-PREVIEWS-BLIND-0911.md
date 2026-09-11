# Ironwood ancient-tree Meshy previews — code-blind selection (2026-09-11)

## Verdict

**Visual winner: A. Ranking: A > C > B.**

Select A as the reconstruction source for a cleanup/retopology pass. Do **not** ship
any of the three raw meshes as-is. A is the only candidate whose four views retain a
reasonably broad, ancient-tree mass while keeping the root plate, trunk bundle and
crown readable as one structure. It remains materially below the selected reference:
the reference has heavier interlocked trunks, clearer hollows, broader hand-shaped
boughs and a calmer, more coherent crown.

The topology inspection was performed only after the visual ranking. It confirms
that A is a source candidate, not production geometry: all three are highly
disconnected triangle soups with extensive non-manifold boundaries and inward faces.

## 1. Candidate A — SELECT FOR CLEANUP

### Visual form

- **Front:** Closest of the set to the reference's broad crown and fused multi-trunk
  silhouette. The base spreads convincingly beyond the trunk and the major boughs
  create useful negative spaces. It reads as an old hero tree at thumbnail distance.
- **Three-quarter:** Best view in the set. The trunk bundle, lateral limbs and root
  flare remain continuous rather than collapsing into a single pole. The outer crown
  is broad enough to hold a landmark silhouette.
- **Back:** Still reads as the same tree, with a stable crown width and central mass.
  The lower side crowns are separated but remain attached to legible main boughs.
- **Side:** Considerably thinner than the front and loses much of the reference's
  monumental breadth, but it retains more crown depth and lower-root mass than B or C.

### Remaining reconstruction defects

- The reference's large hollow/doorway and secondary trunk cavities are absent or too
  shallow to read in the untextured geometry.
- Thousands of small angular leaf shards create visual fizz. At gameplay distance
  these will alias into noise rather than the reference's broad painted foliage forms.
- Several crown edges look like loose paper fragments, and thin internal twig/leaf
  elements appear to float.
- Root fingers are numerous and sharp. They need consolidation into fewer thick,
  ground-bearing masses with a flat, reliable underside.
- The side profile remains too narrow for a truly colossal 360-degree landmark.

### Topology rejection risk

The inspection reports 16,292 triangles but 9,830 disconnected components, 35,862
non-manifold/boundary edges, 28,209 duplicate vertices and roughly 3,731 inward-facing
faces. Those numbers support the visible leaf-debris concern. A must be cleaned,
welded and rebuilt into deliberate trunk/root and foliage components before production
use. Its off-origin bounds also require an explicit ground pivot.

## 2. Candidate C — second

Candidate C has a broad front and back and a respectable root flare. Its front crown
is less cohesive than A's, with a flatter top and more obvious isolated foliage
chunks. The side view collapses into a narrow column, making the tree feel like a
two-dimensional reconstruction rather than a colossal volume. The three-quarter view
also exposes abrupt limb wedges and a less convincing trunk-to-crown transition.

It has fewer disconnected components than A, but still reports 8,798 components,
31,529 non-manifold/boundary edges, 25,263 duplicate vertices and about 3,339 inward
faces. It is additionally off-centre. That modest topology advantage does not overcome
the weaker silhouette.

## 3. Candidate B — third

Candidate B's front view has an attractive domed crown and a large root opening, but
the trunk is cleaner and younger-looking than the reference and the root openings
read more like thin arches than massive grounded buttresses. Its side view is the
weakest of all twelve frames: the crown and trunk compress into a very narrow,
top-heavy slab. Several lower branch tips end in detached-looking leaf scraps.

The inspection reports 9,400 disconnected components, 32,794 non-manifold/boundary
edges, 26,427 duplicate vertices and about 3,106 inward faces. It is not sufficiently
cleaner than A to justify the substantially weaker multi-angle form.

## Acceptance conditions for A

Before production integration, A needs:

1. a widened side/depth profile so the crown and root mass remain monumental from
   ordinary 360-degree approach angles;
2. consolidation into a small number of watertight trunk/root components and a few
   intentional foliage masses, removing microscopic floating debris;
3. fewer, thicker root buttresses with a planar grounded underside and correct pivot;
4. a readable principal hollow or scar that survives gameplay distance;
5. normals repair, vertex welding and explicit LODs whose silhouette does not collapse
   into leaf shimmer.

If that cleanup is unavailable, HOLD all three rather than importing a raw preview.
