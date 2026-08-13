#!/usr/bin/env python3
"""Ear-clip every polygon face in an OBJ into triangles, in place.

OF4-gate-arch (2026-08-13). Godot's OBJ importer turns an n-gon face into a
triangle FAN from the polygon's first vertex. A fan is only correct for a
CONVEX polygon; on a concave one it emits triangles that spill across the
concavity. BG2's Quaternius castle kit authors each wall face as one big
n-gon, and on the two entrance modules that n-gon is a 15/16-sided CONCAVE
loop wrapping the doorway arch -- so the importer filled a lopsided wedge of
the archway back in with solid geometry, which is what "the gate reads as a
jagged opening rather than a clean archway" actually was. Not a placement
problem and not a kit-geometry mismatch: a triangulation bug that only shows
up on concave faces.

Fix at the asset, not at the loader: pre-triangulate the faces so the
importer has nothing left to fan. Vertex/UV/normal data is untouched -- this
only rewrites `f` lines, re-emitting the SAME `v/vt/vn` index triples in
correct triangles, so the mesh is bit-identical in every other respect and
the MTL material names the castle's `retint` keys off are unchanged.

Usage: python3 tools/retriangulate_obj.py <file.obj> [more.obj ...]
Idempotent -- already-triangular faces are passed through untouched.
"""

import sys
from pathlib import Path


def _newell(points):
    nx = ny = nz = 0.0
    n = len(points)
    for i in range(n):
        ax, ay, az = points[i]
        bx, by, bz = points[(i + 1) % n]
        nx += (ay - by) * (az + bz)
        ny += (az - bz) * (ax + bx)
        nz += (ax - bx) * (ay + by)
    return nx, ny, nz


def _project(points, normal):
    """Drop the normal's dominant axis; return 2D points wound CCW."""
    ax, ay, az = abs(normal[0]), abs(normal[1]), abs(normal[2])
    if ax >= ay and ax >= az:
        flat = [(p[1], p[2]) for p in points]
        sign = 1.0 if normal[0] > 0 else -1.0
    elif ay >= az:
        flat = [(p[2], p[0]) for p in points]
        sign = 1.0 if normal[1] > 0 else -1.0
    else:
        flat = [(p[0], p[1]) for p in points]
        sign = 1.0 if normal[2] > 0 else -1.0
    if sign < 0:
        flat = [(-x, y) for (x, y) in flat]
    return flat


def _area2(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _inside(a, b, c, p):
    d1 = _area2(a, b, p)
    d2 = _area2(b, c, p)
    d3 = _area2(c, a, p)
    has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (has_neg and has_pos)


def ear_clip(points):
    """Return triangles as index triples into `points` (2D, any winding)."""
    n = len(points)
    idx = list(range(n))
    # Signed area decides winding; ear clipping below assumes CCW.
    area = sum(_area2((0.0, 0.0), points[i], points[(i + 1) % n]) for i in range(n))
    if area < 0:
        idx.reverse()
    out = []
    guard = 0
    while len(idx) > 3 and guard < 4 * n:
        guard += 1
        clipped = False
        for k in range(len(idx)):
            i0 = idx[k - 1]
            i1 = idx[k]
            i2 = idx[(k + 1) % len(idx)]
            a, b, c = points[i0], points[i1], points[i2]
            if _area2(a, b, c) <= 1e-12:
                continue  # reflex or degenerate corner, not an ear
            if any(
                _inside(a, b, c, points[j])
                for j in idx
                if j not in (i0, i1, i2)
            ):
                continue  # another vertex sits inside: not an ear
            out.append((i0, i1, i2))
            idx.pop(k)
            clipped = True
            break
        if not clipped:
            break  # degenerate loop; fall through to a fan for the rest
    for k in range(1, len(idx) - 1):
        out.append((idx[0], idx[k], idx[k + 1]))
    return out


def is_convex(points):
    n = len(points)
    signs = set()
    for i in range(n):
        cross = _area2(points[i - 1], points[i], points[(i + 1) % n])
        if abs(cross) > 1e-12:
            signs.add(cross > 0)
    return len(signs) <= 1


def process(path):
    lines = Path(path).read_text().splitlines()
    verts = []
    for line in lines:
        if line.startswith("v "):
            parts = line.split()
            verts.append((float(parts[1]), float(parts[2]), float(parts[3])))
    out_lines = []
    concave = 0
    split = 0
    for line in lines:
        if not line.startswith("f "):
            out_lines.append(line)
            continue
        toks = line.split()[1:]
        if len(toks) <= 3:
            out_lines.append(line)
            continue
        vi = [int(t.split("/")[0]) - 1 for t in toks]
        pts3 = [verts[i] for i in vi]
        flat = _project(pts3, _newell(pts3))
        if is_convex(flat):
            # A fan is already correct here; still emit triangles so the file
            # carries no n-gons at all and the importer has no choice to make.
            tris = [(0, k, k + 1) for k in range(1, len(toks) - 1)]
        else:
            concave += 1
            tris = ear_clip(flat)
        split += 1
        for a, b, c in tris:
            out_lines.append("f %s %s %s" % (toks[a], toks[b], toks[c]))
    Path(path).write_text("\n".join(out_lines) + "\n")
    return split, concave


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        n, c = process(arg)
        print("%s: %d polygons triangulated (%d were concave)" % (arg, n, c))
