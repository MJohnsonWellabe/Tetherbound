"""Strip a Meshy image-to-3D baked ground patch (grass disc / plinth) from a
standing creature, in Blender, before rigging.

    import strip_ground_patch as patch
    report = patch.strip(body, band=0.10, probe=(0.13, 0.22), grow=1.6, toe=2.2)

`body` is one welded mesh standing on z=0, front towards -Y
(rig_quadruped.join_and_normalise). The patch is the wide slab in the lowest
`band` of the height. Leg columns are measured from a probe slice above it
(`probe`, fractions of height) where only legs cross; every vertex in the band
outside a dilated footprint of those columns is patch or grass and goes. Inside
a footprint, vertices below the patch's own top surface (the 70th percentile of
the removed band) go too, so a paw keeps its sides but not the fused disc under
it. Loose islands left behind (grass blades beside a paw) are dropped, keeping
the largest connected part, and the body is re-grounded on z=0.
`toe` stretches each footprint forward (-Y) so paws and long hind feet stay.
"""
import bmesh
import math
from mathutils import Vector


def _columns(points, n_cols):
    """k-means on xy with quadrant seeding (front/rear x left/right)."""
    xs = sorted(p.x for p in points); ys = sorted(p.y for p in points)
    mx = xs[len(xs) // 2]; my = ys[len(ys) // 2]
    if n_cols == 2:
        seeds = [Vector((mx - .1, my, 0)), Vector((mx + .1, my, 0))]
    else:
        seeds = [Vector((sx, sy, 0)) for sy in (my - .2, my + .2) for sx in (mx - .1, mx + .1)]
    for _ in range(25):
        groups = [[] for _ in seeds]
        for p in points:
            k = min(range(len(seeds)), key=lambda i: (p.x - seeds[i].x) ** 2 + (p.y - seeds[i].y) ** 2)
            groups[k].append(p)
        seeds = [Vector((sum(q.x for q in g) / len(g), sum(q.y for q in g) / len(g), 0)) if g else s
                 for g, s in zip(groups, seeds)]
    out = []
    for s, g in zip(seeds, groups):
        if not g:
            continue
        r = sorted(math.hypot(q.x - s.x, q.y - s.y) for q in g)[int(len(g) * .9)]
        out.append((s, max(r, .01)))
    return out


def strip(body, band=0.10, probe=(0.13, 0.22), grow=1.6, toe=2.2, heel=1.3, n_cols=4, surface_q=0.7,
          islands_only=False, low_islands=None):
    """islands_only: no disc, only loose tufts (separate islands) to drop.
    low_islands: for a fragmented Meshy shell (body in many islands that only the
    patch joined), drop only the loose islands lying wholly below this fraction
    of the height (grass tufts) instead of keeping just the largest part."""
    me = body.data
    H = max(v.co.z for v in me.vertices)
    if islands_only:
        band = 0.0
    cut = band * H
    probe_pts = [v.co.copy() for v in me.vertices if probe[0] * H < v.co.z < probe[1] * H]
    cols = _columns(probe_pts, n_cols) if band > 0 else []

    def inside(p):
        for c, r in cols:
            dx = (p.x - c.x) / (r * grow)
            fwd = toe if p.y < c.y else heel
            dy = (p.y - c.y) / (r * fwd)
            if dx * dx + dy * dy <= 1.0:
                return True
        return False

    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
    outside = [v for v in bm.verts if v.co.z < cut and not inside(v.co)]
    zs = sorted(v.co.z for v in outside)
    surface = zs[int(len(zs) * surface_q)] if zs else 0.0
    doomed = set(outside)
    doomed.update(v for v in bm.verts if v.co.z < surface and inside(v.co))
    bmesh.ops.delete(bm, geom=list(doomed), context='VERTS')
    # keep the largest connected part
    bm.verts.ensure_lookup_table()
    seen = set(); parts = []
    for v in bm.verts:
        if v in seen:
            continue
        stack = [v]; seen.add(v); part = []
        while stack:
            x = stack.pop(); part.append(x)
            for e in x.link_edges:
                o = e.other_vert(x)
                if o not in seen:
                    seen.add(o); stack.append(o)
        parts.append(part)
    parts.sort(key=len, reverse=True)
    if low_islands is None:
        loose = [v for part in parts[1:] for v in part]
    else:
        loose = [v for part in parts[1:] if max(x.co.z for x in part) < low_islands * H for v in part]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context='VERTS')
    low = min(v.co.z for v in bm.verts)
    for v in bm.verts:
        v.co.z -= low
    bm.to_mesh(me); bm.free(); me.update()
    return {'patch_band_m_normalised': round(band, 3), 'patch_surface_z': round(surface / H, 4),
            'islands_only': islands_only, 'columns': [[round(c.x / H, 3), round(c.y / H, 3), round(r / H, 3)] for c, r in cols],
            'removed_vertices': len(doomed), 'removed_islands': len(parts) - 1,
            'removed_island_vertices': len(loose), 'regrounded_by': round(low / H, 4)}
