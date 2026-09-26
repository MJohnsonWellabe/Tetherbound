"""Village road-graph analysis shared by make_plan.py (and mirrored, rule for
rule, by tests/test_village_road_topology.gd). Pure data: reads the same road
sections playground_heightfield.road_bands() unions."""
import math

WELL = (10.0, -10.0)
WELL_RADIUS = 8.0
SNAP = 0.75
ARM_MERGE = 2.5
HOME_DOOR = (-16.5, -16.0)


def _pt_in_poly(p, poly):
    x, z = p
    inside = False
    n = len(poly)
    for i in range(n):
        ax, az = poly[i]
        bx, bz = poly[(i + 1) % n]
        if (az > z) != (bz > z):
            t = (z - az) / (bz - az)
            if x < ax + t * (bx - ax):
                inside = not inside
    return inside


def _seg_x(a, b, c, d):
    r = (b[0] - a[0], b[1] - a[1])
    s = (d[0] - c[0], d[1] - c[1])
    den = r[0] * s[1] - r[1] * s[0]
    if abs(den) < 1e-9:
        return None
    t = ((c[0] - a[0]) * s[1] - (c[1] - a[1]) * s[0]) / den
    u = ((c[0] - a[0]) * r[1] - (c[1] - a[1]) * r[0]) / den
    if 0 <= t <= 1 and 0 <= u <= 1:
        return (a[0] + r[0] * t, a[1] + r[1] * t), t
    return None


def _closest_t(p, a, b):
    ab = (b[0] - a[0], b[1] - a[1])
    L2 = ab[0] ** 2 + ab[1] ** 2
    t = max(0.0, min(1.0, ((p[0] - a[0]) * ab[0] + (p[1] - a[1]) * ab[1]) / L2))
    return t, (a[0] + ab[0] * t, a[1] + ab[1] * t)


def roads(terrain):
    out = []
    paths = terrain.get("paths", {})
    for r in paths.get("routes", []):
        out.append((r.get("id") or r.get("label"), r["points"]))
    for r in paths.get("approaches", []):
        out.append((r.get("id") or r.get("label"), r["points"]))
    for b in terrain.get("trail", {}).get("bands", []):
        if b.get("id") == "band1_lower_meadows":
            out.append((b["id"], b["points"]))
    return out


def analyse(terrain, boundary):
    outline = [tuple(p) for p in boundary["outline"]["points"]]
    gates = {g["id"]: tuple(g["at"]) for g in boundary["gates"]["entries"]}
    clear = float(boundary.get("wall", {}).get("gate_clear_m", 3.4)) + 1.0
    # 1. clip every road segment to the fence, recording crossings.
    segs = []
    crossings = []
    for rid, pts in roads(terrain):
        pts = [tuple(map(float, p)) for p in pts]
        for a, b in zip(pts, pts[1:]):
            cuts = [(0.0, a), (1.0, b)]
            for i in range(len(outline)):
                hit = _seg_x(a, b, outline[i], outline[(i + 1) % len(outline)])
                if hit:
                    cuts.append((hit[1], hit[0]))
                    near = min(gates, key=lambda g: math.dist(gates[g], hit[0]))
                    gid = near if math.dist(gates[near], hit[0]) <= clear else "NO GATE"
                    crossings.append((gid, hit[0][0], hit[0][1]))
            cuts.sort()
            for (t0, p0), (t1, p1) in zip(cuts, cuts[1:]):
                if t1 - t0 < 1e-6:
                    continue
                mid = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
                if _pt_in_poly(mid, outline):
                    segs.append((p0, p1))
    # 2. nodes: endpoints + intersections + endpoints lying on other segments.
    nodes = []

    def node(p):
        for i, q in enumerate(nodes):
            if math.dist(p, q) <= SNAP:
                return i
        nodes.append(p)
        return len(nodes) - 1

    for a, b in segs:
        node(a)
        node(b)
    for i, (a, b) in enumerate(segs):
        for j in range(i + 1, len(segs)):
            hit = _seg_x(a, b, *segs[j])
            if hit:
                node(hit[0])
    # 3. split each segment at every node lying on it; dedupe edges.
    edges = set()
    for a, b in segs:
        on = []
        for k, q in enumerate(nodes):
            t, c = _closest_t(q, a, b)
            if math.dist(c, q) <= SNAP:
                on.append((t, k))
        on.sort()
        chain = []
        for t, k in on:
            if not chain or chain[-1] != k:
                chain.append(k)
        for u, v in zip(chain, chain[1:]):
            if u != v:
                edges.add((min(u, v), max(u, v)))
    adj = {i: set() for i in range(len(nodes))}
    for u, v in edges:
        adj[u].add(v)
        adj[v].add(u)
    # 4. arms leaving the well's disk.
    hits = []
    for u, v in edges:
        a, b = nodes[u], nodes[v]
        dx, dz = b[0] - a[0], b[1] - a[1]
        fx, fz = a[0] - WELL[0], a[1] - WELL[1]
        A = dx * dx + dz * dz
        B = 2 * (fx * dx + fz * dz)
        C = fx * fx + fz * fz - WELL_RADIUS ** 2
        disc = B * B - 4 * A * C
        if disc < 0:
            continue
        for sgn in (-1, 1):
            t = (-B + sgn * math.sqrt(disc)) / (2 * A)
            if 0 <= t <= 1:
                hits.append((a[0] + dx * t, a[1] + dz * t))
    arms = []
    for h in hits:
        if all(math.dist(h, q) > ARM_MERGE for q in arms):
            arms.append(h)
    junctions = [(nodes[i][0], nodes[i][1], len(adj[i])) for i in adj if len(adj[i]) >= 3]
    # 5. home door -> TrailGate crossing.
    home = min(range(len(nodes)), key=lambda i: math.dist(nodes[i], HOME_DOOR))
    trail = [c for c in crossings if c[0] == "TrailGate"]
    ok, length = False, 0.0
    if trail and math.dist(nodes[home], HOME_DOOR) <= 1.0:
        goal = min(range(len(nodes)), key=lambda i: math.dist(nodes[i], trail[0][1:]))
        dist = {home: 0.0}
        todo = [home]
        while todo:
            todo.sort(key=lambda i: dist[i])
            u = todo.pop(0)
            for v in adj[u]:
                nd = dist[u] + math.dist(nodes[u], nodes[v])
                if nd < dist.get(v, 1e18):
                    dist[v] = nd
                    todo.append(v)
        if goal in dist:
            ok, length = True, dist[goal]
    # de-dup crossings (overlapping polylines cross at the same place)
    uniq = []
    for c in crossings:
        if all(math.dist(c[1:], u[1:]) > 0.5 for u in uniq):
            uniq.append(c)
    return {
        "well_radius": WELL_RADIUS,
        "well_arms": len(arms),
        "max_degree": max((len(s) for s in adj.values()), default=0),
        "junctions": junctions,
        "home_to_bridge": ok,
        "home_to_bridge_len": length,
        "crossings": uniq,
    }
