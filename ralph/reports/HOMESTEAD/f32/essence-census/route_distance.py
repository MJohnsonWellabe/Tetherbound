"""F32#2 off-route census: XZ distance from each essence node to its realm's
authored routes. Meadows: terrain_playground paths.routes; Tidewake: water_world
land_routes with main_path; Cloudreach: cloudreach_world routes; Stormwood:
stormwood_world routes of kind 'critical'. Threshold: essence_nodes.json
off_route_minimum_m. Run from the repo root."""
import json, math
def seg(p, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]; L = dx * dx + dz * dz
    t = 0 if L == 0 else max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / L))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dz)
xz = lambda pt: (pt[0], pt[-1])
load = lambda p: json.load(open(p))
routes = {
    "meadows": [[xz(p) for p in r["points"]] for r in load("data/config/terrain_playground.json")["paths"]["routes"]],
    "water": [[xz(p) for p in r["polyline"]] for r in load("data/config/water_world.json")["land_routes"] if r.get("main_path")],
    "cloudreach": [[xz(p) for p in r["polyline"]] for r in load("data/config/cloudreach_world.json")["routes"]],
    "stormwood": [[xz(p) for p in r["points"]] for r in load("data/config/stormwood_world.json")["routes"] if r["kind"] == "critical"],
}
data = load("data/config/essence_nodes.json"); minimum = data["off_route_minimum_m"]
summary = {}
for n in data["nodes"]:
    d = min(seg(tuple(n["at"]), a, b) for r in routes[n["realm"]] for a, b in zip(r, r[1:]))
    off = d >= minimum
    summary.setdefault(n["realm"], [0, 0])[0 if off else 1] += 1
    print(f'{n["realm"]:10} {n["type"]:9} {d:8.1f} m  recorded={n["placement"].get("main_route_distance_m")}  {"off" if off else "ON-ROUTE"}')
for realm, (off, on) in summary.items():
    print(f"{realm:10} off-route {off}/{off + on}  {'PASS' if off > on else 'FAIL'} (mostly off-route, >= {minimum} m)")
