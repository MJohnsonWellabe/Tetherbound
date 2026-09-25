#!/usr/bin/env python3
"""F01-a: labelled overhead plan of the village's OLD vs NEW traversable road
topology, drawn straight from the data files (no engine, no screenshots).

    python3 ralph/reports/MEADOWS-PAYOFFS/village-road/make_plan.py [OLD_REV]

OLD_REV (default 47774c350) is the git revision whose
data/config/terrain_playground.json is drawn as OLD; NEW is the working tree.
Buildings, gates, NPCs, harvest nodes and the work_area props are read at the
same revision as each panel's roads. Moves still only proposed
(proposed_moves.json) are drawn dashed on the NEW panel.
"""
import json
import math
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "plan_old_new.png")
TERRAIN = "data/config/terrain_playground.json"
OLD_REV = sys.argv[1] if len(sys.argv) > 1 else "47774c350"

# World window (x right, z down: +z is toward the South Bridge, so north is up).
X0, X1, Z0, Z1 = -52.0, 80.0, -66.0, 34.0
SCALE = 7.0
PAD_TOP = 110
PANEL_W = int((X1 - X0) * SCALE)
PANEL_H = int((Z1 - Z0) * SCALE)
LEGEND_H = 250
GAP = 24

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def font(size, bold=False):
    try:
        return ImageFont.truetype(FONT_B if bold else FONT, size)
    except OSError:
        return ImageFont.load_default()


def load(path, rev=None):
    if rev:
        raw = subprocess.check_output(["git", "-C", ROOT, "show", "%s:%s" % (rev, path)])
        return json.loads(raw)
    with open(os.path.join(ROOT, path)) as fh:
        return json.load(fh)


def rot(local, yaw_deg):
    t = math.radians(yaw_deg)
    x, z = local
    return (x * math.cos(t) + z * math.sin(t), -x * math.sin(t) + z * math.cos(t))


def village_roads(terrain):
    """Every road polyline road_bands() unions, tagged by source section."""
    out = []
    paths = terrain.get("paths", {})
    for r in paths.get("routes", []):
        out.append(("route", r.get("label", "?"), r.get("id", ""), r["points"]))
    for r in paths.get("approaches", []):
        out.append(("approach", r.get("label", "?"), r.get("id", ""), r["points"]))
    for b in terrain.get("trail", {}).get("bands", []):
        if b.get("id") == "band1_lower_meadows":
            out.append(("band", "Lower Meadows spine", b["id"], b["points"]))
    return out


def seg_len(pts):
    return sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


class Panel:
    def __init__(self, img, ox, oy):
        self.d = ImageDraw.Draw(img)
        self.ox, self.oy = ox, oy

    def p(self, x, z):
        return (self.ox + (x - X0) * SCALE, self.oy + (z - Z0) * SCALE)

    def line(self, pts, fill, width, dash=None):
        pix = [self.p(x, z) for x, z in pts]
        if not dash:
            self.d.line(pix, fill=fill, width=width, joint="curve")
            return
        on, off = dash
        for a, b in zip(pix, pix[1:]):
            L = math.dist(a, b)
            if L == 0:
                continue
            ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
            s = 0.0
            while s < L:
                e = min(s + on, L)
                self.d.line([(a[0] + ux * s, a[1] + uy * s), (a[0] + ux * e, a[1] + uy * e)],
                            fill=fill, width=width)
                s += on + off

    def poly(self, pts, fill=None, outline=None, width=1):
        self.d.polygon([self.p(x, z) for x, z in pts], fill=fill, outline=outline, width=width)

    def dot(self, x, z, r, fill, outline=None):
        cx, cy = self.p(x, z)
        self.d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=outline)

    def circle_m(self, x, z, rm, outline, width=2, fill=None):
        cx, cy = self.p(x, z)
        r = rm * SCALE
        self.d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=outline, width=width, fill=fill)

    def text(self, x, z, s, f, fill=(20, 20, 20), anchor="mm", halo=True):
        px = self.p(x, z)
        if halo:
            self.d.text(px, s, font=f, fill=fill, anchor=anchor, stroke_width=3,
                        stroke_fill=(250, 248, 240))
        else:
            self.d.text(px, s, font=f, fill=fill, anchor=anchor)


def footprint_corners(c, half, yaw):
    hx, hz = half
    out = []
    for lx, lz in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)):
        dx, dz = rot((lx, lz), yaw)
        out.append((c[0] + dx, c[1] + dz))
    return out


def draw_panel(main, ox, oy, title, terrain, topo_kind, shared, proposed):
    img = Image.new("RGB", (PANEL_W + 1, PANEL_H + 1), (250, 248, 240))
    P = Panel(img, 0, 0)
    d = P.d
    d.rectangle([0, 0, PANEL_W, PANEL_H], fill=(226, 236, 206))
    # 10 m grid
    for gx in range(int(math.ceil(X0 / 10) * 10), int(X1) + 1, 10):
        d.line([P.p(gx, Z0), P.p(gx, Z1)], fill=(210, 222, 190), width=1)
    for gz in range(int(math.ceil(Z0 / 10) * 10), int(Z1) + 1, 10):
        d.line([P.p(X0, gz), P.p(X1, gz)], fill=(210, 222, 190), width=1)
    boundary, village, npcs, harvest, props = shared
    outline = boundary["outline"]["points"]
    P.poly(outline, fill=(236, 242, 220), outline=(120, 90, 60), width=3)
    # flats (level pads) faint
    for f in terrain.get("flats", []):
        c = f.get("centre")
        if c and X0 < c[0] < X1 and Z0 < c[1] < Z1 and "height" in f:
            P.circle_m(c[0], c[1], f["radius"], outline=(200, 214, 176), width=1)

    roads = village_roads(terrain)
    topo = terrain.get("paths", {}).get("village_topology", {})
    through_ids = set(topo.get("through_road", {}).get("roads", []))
    lane_ids = {l.get("road") for l in topo.get("side_lanes", [])}
    # subareas (NEW only: declared in data)
    for sub in topo.get("subareas", []):
        c, r = sub["centre"], sub["radius"]
        P.circle_m(c[0], c[1], r, outline=(70, 110, 160), width=3, fill=(214, 226, 236))
        P.text(c[0], c[1] - r - 2.2, sub["name"], font(15, True), fill=(40, 70, 120))

    # draw roads: base width then colour
    roads = [(k, lab, rid or lab, pts) for k, lab, rid, pts in roads]
    order = sorted(roads, key=lambda r: (r[2] in through_ids, r[2] in lane_ids))
    for kind, label, rid, pts in order:
        P.line(pts, (170, 140, 100), int(3.6 * SCALE))
    for kind, label, rid, pts in order:
        if topo_kind == "old":
            radial = kind == "route" and pts and math.dist(pts[0], (10.0, -10.0)) < 0.5
            col = (196, 60, 40) if radial else (120, 84, 48)
            P.line(pts, col, 5)
        else:
            if rid in through_ids:
                P.line(pts, (214, 136, 20), 8)
            elif rid in lane_ids:
                P.line(pts, (40, 120, 60), 6)
            else:
                P.line(pts, (120, 84, 48), 4)

    # buildings
    fp = terrain.get("building_aprons", {}).get("footprints", [])
    names = {(-22.0, -16.0): "Grandpa's house", (2.0, 12.0): "Tam's workshop",
             (18.0, 4.0): "Mira's shop", (19.0, -18.0): "stone cottage",
             (-1.5, -2.0): "Inn", (10.0, -10.0): "well"}
    for f in fp:
        c = tuple(f["centre"])
        if not (X0 < c[0] < X1 and Z0 < c[1] < Z1):
            continue
        if c == (10.0, -10.0):
            P.circle_m(c[0], c[1], 1.6, outline=(60, 60, 60), width=2, fill=(150, 160, 170))
            P.text(c[0] + 3.5, c[1] - 2.5, "Well", font(13, True))
            continue
        P.poly(footprint_corners(c, f["half_extents"], f["yaw_deg"]), fill=(160, 90, 70),
               outline=(70, 40, 30), width=2)
        if c in names:
            P.text(c[0], c[1], names[c], font(12, True), fill=(255, 255, 255), halo=False)
    # doorsteps / doors
    doors = [(-16.5, -16.0)]
    for s in village["structures"]:
        if s["prefab"] == "doorstep":
            doors.append(tuple(s["at"]))
    for x, z in doors:
        P.dot(x, z, 5, (255, 220, 60), outline=(90, 60, 0))
    # other structures (fences, oaks, wagons)
    for s in village["structures"]:
        x, z = s["at"]
        if not (X0 < x < X1 and Z0 < z < Z1):
            continue
        if s["prefab"] == "fence_run":
            dx, dz = rot((3.0, 0.0), s["yaw_deg"])
            P.line([(x - dx, z - dz), (x + dx, z + dz)], (110, 80, 50), 3)
        elif s["prefab"].startswith("square_oak"):
            P.circle_m(x, z, 2.2, outline=(40, 90, 40), width=2, fill=(110, 160, 90))
        elif s["prefab"] == "wagon":
            P.dot(x, z, 4, (140, 110, 70))
    # the work_area prop cluster (band1 props.json), at this panel's revision
    for c in props.get("clusters", []):
        if c.get("name") != "work_area":
            continue
        for pr in c.get("props", []):
            x, z = pr["at"][:2]
            cx, cy = P.p(x, z)
            d.rectangle([cx - 3, cy - 3, cx + 3, cy + 3], fill=(60, 60, 70))
        x, z = c["props"][0]["at"][:2]
        P.text(x, z + 2.4, "work_area props", font(10), fill=(40, 40, 50))
    # harvest nodes near the village
    colours = {"stone": (120, 120, 130), "berries": (170, 40, 120), "wood": (110, 70, 30),
               "fiber": (150, 170, 60)}
    for n in harvest["nodes"]:
        x, z = n["at"][:2]
        if X0 < x < X1 and Z0 < z < Z1 and n["item"] in colours:
            P.dot(x, z, 4, colours[n["item"]], outline=(30, 30, 30))
    # NPCs in the village
    for v in npcs["villagers"]:
        pos = v["position"]
        x, z = pos[0], pos[2] if len(pos) > 2 else pos[1]
        if X0 < x < X1 and Z0 < z < Z1:
            P.dot(x, z, 5, (40, 90, 200), outline=(255, 255, 255))
            P.text(x + 0.2, z + 2.6, v["name"], font(11), fill=(30, 50, 140))
    # gates
    for g in boundary["gates"]["entries"]:
        x, z = g["at"]
        dx, dz = rot((2.0, 0.0), g["yaw_deg"])
        P.line([(x - dx, z - dz), (x + dx, z + dz)], (20, 20, 20), 7)
        P.text(x, z + (3.2 if g["id"] != "RoadGate" else -3.2), g["id"], font(13, True),
               fill=(10, 10, 10))
    # named-subarea fingerposts (paths.trailheads inside the window)
    for th in terrain.get("paths", {}).get("trailheads", []):
        x, z = th["at"]
        if X0 < x < X1 and Z0 < z < Z1:
            P.dot(x, z, 4, (230, 230, 230), outline=(60, 40, 20))
            P.text(x, z - 2.0, "post: " + th["label"], font(10), fill=(60, 40, 20))
    # proposed moves (NEW panel only)
    for mv in proposed:
        fx, fz = mv["from"]
        tx, tz = mv["to"]
        P.line([(fx, fz), (tx, tz)], (200, 0, 160), 2, dash=(6, 4))
        P.dot(tx, tz, 5, None, outline=(200, 0, 160))
        P.text(tx, tz - 2.4, mv["label"], font(11), fill=(150, 0, 120))
    # route labels
    for kind, label, rid, pts in roads:
        if label in ("The Stronghold",):
            continue
        # label at the midpoint of the part that is on-screen
        vis = [p for p in pts if X0 + 4 < p[0] < X1 - 4 and Z0 + 4 < p[1] < Z1 - 4]
        if len(vis) < 1:
            continue
        mx, mz = vis[len(vis) // 2] if len(vis) > 2 else vis[-1]
        P.text(mx, mz + 2.2, label, font(12), fill=(90, 50, 10))
    # exit arrows
    P.text(12.0, Z1 - 2.0, "to South Bridge (0,1330) via Lower Meadows spine", font(12, True),
           fill=(120, 60, 0))
    main.paste(img, (ox, oy))
    ImageDraw.Draw(main).text((ox + 8, oy - 36), title, font=font(20, True), fill=(20, 20, 20))
    return P


def graph_stats(terrain, boundary):
    """Same topology the unit test computes, for the caption."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from topology import analyse  # noqa: E402
    return analyse(terrain, boundary)


def main():
    boundary = load("data/config/village_boundary.json")
    village = load("data/config/village.json")
    npcs = load("data/config/village_npcs.json")
    harvest = load("data/config/bands/band1_lower_meadows/harvest.json")
    old = load(TERRAIN, OLD_REV)
    new = load(TERRAIN)
    props_path = "data/config/bands/band1_lower_meadows/props.json"
    shared = (boundary, village, npcs, harvest, load(props_path))
    shared_old = (load("data/config/village_boundary.json", OLD_REV),
                  load("data/config/village.json", OLD_REV),
                  load("data/config/village_npcs.json", OLD_REV),
                  load("data/config/bands/band1_lower_meadows/harvest.json", OLD_REV),
                  load(props_path, OLD_REV))
    prop_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "proposed_moves.json")
    proposed = json.load(open(prop_path))["moves"] if os.path.exists(prop_path) else []
    W = PANEL_W * 2 + GAP * 3
    H = PAD_TOP + PANEL_H + LEGEND_H
    img = Image.new("RGB", (W, H), (250, 248, 240))
    draw_panel(img, GAP, PAD_TOP, "OLD (%s): radial spokes from the well" % OLD_REV, old, "old",
               shared_old, [])
    draw_panel(img, GAP * 2 + PANEL_W, PAD_TOP,
               "NEW (F01 branch): through-road, lanes, Berry Field / Grove / Stoneyard", new, "new", shared,
               proposed)
    d = ImageDraw.Draw(img)
    y = PAD_TOP + PANEL_H + 14
    so, sn = graph_stats(old, shared_old[0]), graph_stats(new, boundary)
    lines = [
        ("OLD", so, GAP),
        ("NEW", sn, GAP * 2 + PANEL_W),
    ]
    for tag, s, x in lines:
        f = font(14)
        txt = [
            "%s topology (computed from road polylines clipped to the village fence):" % tag,
            "  road arms meeting within %.0f m of the well: %d   max junction degree: %d" % (
                s["well_radius"], s["well_arms"], s["max_degree"]),
            "  junctions (degree>=3): %s" % ", ".join("(%.1f,%.1f)d%d" % (j[0], j[1], j[2])
                                                    for j in s["junctions"]),
            "  home door -> TrailGate connected: %s   path length %.1f m" % (
                s["home_to_bridge"], s["home_to_bridge_len"]),
            "  fence crossings: %s" % ", ".join("%s@(%.1f,%.1f)" % c for c in s["crossings"]),
        ]
        for i, t in enumerate(txt):
            d.text((x, y + i * 20), t, font=f, fill=(20, 20, 20))
    ly = y + 112
    items = [((214, 136, 20), "through-road (home door -> TrailGate -> South Bridge)", 8),
             ((40, 120, 60), "side lane to named subarea", 6),
             ((120, 84, 48), "other road", 4),
             ((196, 60, 40), "OLD: route radiating from the well", 5),
             ((200, 0, 160), "proposed move (proposed_moves.json; none pending)", 2)]
    lx = GAP
    for col, label, w in items:
        d.line([(lx, ly + 8), (lx + 40, ly + 8)], fill=col, width=w)
        d.text((lx + 48, ly), label, font=font(13), fill=(20, 20, 20))
        lx += 60 + d.textlength(label, font=font(13))
    ly += 30
    marks = [((255, 220, 60), "door / doorstep"), ((40, 90, 200), "villager"),
             ((120, 120, 130), "stone node"), ((170, 40, 120), "berry node"),
             ((110, 70, 30), "wood node"), ((150, 170, 60), "fiber node"),
             ((20, 20, 20), "gate leaf (village_boundary.json)")]
    lx = GAP
    for col, label in marks:
        d.ellipse([lx, ly + 2, lx + 12, ly + 14], fill=col)
        d.text((lx + 18, ly), label, font=font(13), fill=(20, 20, 20))
        lx += 40 + d.textlength(label, font=font(13))
    d.text((GAP, ly + 30), "World metres, x right, z down (+z = toward the South Bridge). "
           "Grid 10 m. Each panel reads village/boundary/NPC data at its own revision.", font=font(13), fill=(60, 60, 60))
    d.text((GAP, 16), "Meadows village road topology, OLD vs NEW (WORLD 3.2 / ACCEPTANCE F01)",
           font=font(24, True), fill=(20, 20, 20))
    img.save(OUT)
    print("wrote", OUT)
    for tag, s in (("OLD", so), ("NEW", sn)):
        print(tag, json.dumps(s))


if __name__ == "__main__":
    main()
