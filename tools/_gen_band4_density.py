import json, math, random

random.seed(4065)

# ---- source polylines (band4 spine + its 3 loops), copied from terrain_playground.json ----
SPINE = [
    (0,4760),(-140,4870),(-300,4990),(-420,5140),(-330,5310),(-170,5410),(0,5490),
    (170,5590),(330,5700),(450,5860),(390,6040),(230,6140),(60,6230),(-110,6340),
    (-280,6460),(-210,6620),(-70,6720),(80,6820),(40,6930),(0,7000),
]
WIND_RIDGE = [(330,5700),(400,5780),(440,5870),(420,5960),(370,6050),(300,6110),(230,6140)]
HIGH_PASTURE = [(60,6230),(30,6270),(-30,6300),(-80,6320),(-110,6340)]
WATCHTOWER = [(-280,6460),(-320,6510),(-330,6570),(-290,6600),(-210,6620)]

def zone(z):
    # non-uniform density bands, matching the owner's "dense old-growth/high
    # pasture, thinner wind ridge/overlook" shape.
    if z < 5410:
        return "old_growth"      # western swing, spine pts 0-5
    if z < 6230:
        return "pasture"         # high pasture / captain_field approach
    if z < 6720:
        return "ridge"           # wind ridge / watchtower / captain_ridge
    return "approach"            # run-out to band5

SPACING = {"old_growth": 50.0, "pasture": 52.0, "ridge": 100.0, "approach": 66.0}
COUNT_RANGE = {"old_growth": (3,5), "pasture": (3,5), "ridge": (2,4), "approach": (3,4)}
RADIUS = {"old_growth": (14,20), "pasture": (16,24), "ridge": (14,20), "approach": (14,20)}

WEIGHTS = {
    "old_growth": [("trailpup",30),("galecrest",14),("burrowback",16),("mudsnout",14),("terrapup",6),("pipwing",10),("duskhush_night",10)],
    "pasture":    [("meadowhart",22),("burrowback",24),("pipwing",20),("galecrest",14),("mudsnout",14),("trailpup",6)],
    "ridge":      [("galecrest",42),("pipwing",30),("trailpup",28)],
    "approach":   [("trailpup",34),("burrowback",30),("galecrest",20),("pipwing",16)],
}

def pick_species(zn, rng):
    pool = WEIGHTS[zn]
    total = sum(w for _,w in pool)
    r = rng.uniform(0, total)
    upto = 0
    for sp,w in pool:
        upto += w
        if r <= upto:
            return sp
    return pool[-1][0]

def walk_points(pts, spacing, zn_for_z, avoid, rng, order_start, off_route_every=3, lateral_off=(28,55), on_jitter=(4,14)):
    out = []
    order = order_start
    # cumulative distance walk
    total = 0.0
    next_mark = 0.0
    i = 0
    n = len(pts)
    idx_along = 0
    while i < n - 1:
        x0,z0 = pts[i]; x1,z1 = pts[i+1]
        seg = math.hypot(x1-x0, z1-z0)
        segs_here = max(1, int(seg // 5))
        for s in range(segs_here):
            t = s/segs_here
            x = x0 + (x1-x0)*t
            z = z0 + (z1-z0)*t
            total += seg/segs_here
            if total >= next_mark:
                zn = zn_for_z(z)
                sp_local = spacing[zn]
                next_mark = total + sp_local
                idx_along += 1
                # direction perpendicular to segment for lateral offset
                dx, dz = x1-x0, z1-z0
                L = math.hypot(dx,dz) or 1.0
                nx, nz = -dz/L, dx/L
                off_route = (idx_along % off_route_every == 0)
                if off_route:
                    side = 1 if (idx_along % 2 == 0) else -1
                    dist = rng.uniform(*lateral_off)
                    cx = x + nx*dist*side + rng.uniform(-6,6)
                    cz = z + nz*dist*side + rng.uniform(-6,6)
                else:
                    cx = x + nx*rng.uniform(-on_jitter[1],on_jitter[1]) + rng.uniform(-on_jitter[0],on_jitter[0])
                    cz = z + nz*rng.uniform(-on_jitter[1],on_jitter[1])
                # skip if too close to an existing/avoided site
                too_close = False
                for (ax,az,ar) in avoid:
                    if math.hypot(cx-ax, cz-az) < ar:
                        too_close = True
                        break
                if too_close:
                    continue
                sp = pick_species(zn, rng)
                night = False
                if sp == "duskhush_night":
                    sp = "duskhush"
                    night = True
                lo,hi = COUNT_RANGE[zn]
                count = rng.randint(lo,hi)
                rlo,rhi = RADIUS[zn]
                radius = round(rng.uniform(rlo,rhi),1)
                entry = {
                    "order": order,
                    "species": sp,
                    "count": count,
                    "centre": [round(cx,1), 0.0, round(cz,1)],
                    "radius": radius,
                }
                if night:
                    entry["time"] = "night"
                entry["_why"] = "GATE-D4-DENSITY (%s, %s). %s" % (
                    zn, "off-route pocket" if off_route else "on-route",
                    "Habitat pocket set back off the trail so a loop/branch has something in it worth the detour." if off_route
                    else "Route population at the density the owner's Pokemon/Palworld/Valheim-comparison directive asks for.")
                out.append(entry)
                order += 1
        i += 1
    return out, order

# sites to keep clear of (existing hand-authored clusters/trainers/props), so the
# dense fill doesn't stack a new cluster directly on an already-placed one.
AVOID = [
    (60,6230,22),(-310,5000,24),(-410,5150,22),(180,5595,20),(440,5870,22),
    (-120,6345,20),(-215,6625,22),(60,6830,20),(-285,5080,12),(-260,5220,20),
    (400,6040,18),(-235,6510,16),(170,5590,14),(-280,6460,14),(-235,6470,14),
]

rng = random.Random(4065)
order = 4011
all_new = []

for pts, every in [(SPINE, 3), (WIND_RIDGE, 4), (HIGH_PASTURE, 3), (WATCHTOWER, 3)]:
    new, order = walk_points(pts, SPACING, zone, AVOID, rng, order, off_route_every=every)
    all_new.extend(new)
    for e in new:
        AVOID.append((e["centre"][0], e["centre"][2], e["radius"]*0.6))

print("generated", len(all_new), "clusters,", sum(e["count"] for e in all_new), "creatures")
print("orders", all_new[0]["order"], "..", all_new[-1]["order"])

with open("/tmp/band4_density_new.json","w") as f:
    json.dump(all_new, f, indent=2)
