"""F32#2 off-route census: XZ distance from each essence node to its realm's
MAIN route. Main routes:
- Meadows: terrain_playground paths.routes + paths.approaches (the authored
  village street/approach network, including the Stronghold road) plus every
  spokes.routes[].road (the roads out across the bands);
- Tidewake: water_world land_routes with main_path;
- Cloudreach: cloudreach_world region-to-region roads plus the arrival road
  (loops, circuits, links and the optional observatory latch are detours);
- Stormwood: stormwood_world routes of kind 'critical'.
Threshold: essence_nodes.json off_route_minimum_m. Run from the repo root.
--write records main_route_distance_m/off_route in essence_nodes.json."""
import json, math, sys
def seg(p, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]; L = dx * dx + dz * dz
    t = 0 if L == 0 else max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / L))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dz)
xz = lambda pt: (pt[0], pt[-1])
load = lambda p: json.load(open(p))
paths = load("data/config/terrain_playground.json")["paths"]
cloud = load("data/config/cloudreach_world.json")["routes"]
routes = {
    "meadows": [[xz(p) for p in r["points"]] for r in paths["routes"] + paths["approaches"]]
               + [[xz(p) for p in r["road"]] for r in load("data/config/terrain_playground.json")["spokes"]["routes"] if r.get("road")],
    "water": [[xz(p) for p in r["polyline"]] for r in load("data/config/water_world.json")["land_routes"] if r.get("main_path")],
    "cloudreach": [[xz(p) for p in r["polyline"]] for r in cloud
                   if (r["from_region_id"] != r["to_region_id"] or r["id"] == "arrival_gate_road") and r["id"] != "observatory_latch_descent"],
    "stormwood": [[xz(p) for p in r["points"]] for r in load("data/config/stormwood_world.json")["routes"] if r["kind"] == "critical"],
}
path = "data/config/essence_nodes.json"
text = open(path).read(); data = json.loads(text); minimum = data["off_route_minimum_m"]
summary = {}
for n in data["nodes"]:
    d = min(seg(tuple(n["at"]), a, b) for r in routes[n["realm"]] for a, b in zip(r, r[1:]))
    off = d >= minimum
    summary.setdefault(n["realm"], [0, 0])[0 if off else 1] += 1
    print(f'{n["realm"]:10} {n["type"]:9} {d:8.1f} m  {"off" if off else "ON-ROUTE"}')
    n["placement"]["main_route_distance_m"] = round(d, 3)
    n["placement"]["off_route"] = off
for realm, (off, on) in summary.items():
    print(f"{realm:10} off-route {off}/{off + on}  {'PASS' if off > on else 'FAIL'} (mostly off-route, >= {minimum} m)")
if "--write" in sys.argv:
    open(path, "w").write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
