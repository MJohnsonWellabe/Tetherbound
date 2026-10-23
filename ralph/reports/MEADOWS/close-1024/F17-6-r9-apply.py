"""F17#6 r9 candidate (capture only; reverted with git afterwards).

r8 shipping plus: nave posts and braces at x=+-5.0 (out of the camera near
field) with the ties lengthened to span 10 m; hall_dressing ON without its
plaster runners; hall_great_hall ON (woven runner, tapestries, ceiling
beams, iron candle rings)."""
import json, sys
P = "data/config/crossing_hall.json"
d = json.load(open(P))
for p in d["hall_timber_frame"]["pieces"]:
    if abs(abs(p["at"][0]) - 3.3) < 1e-6:
        p["at"][0] = 5.0 if p["at"][0] > 0 else -5.0
    if p["name"].startswith("NaveTie"):
        p["scale_xyz"] = [2.2, 10.0 / 3.0, 2.2]
dr = d["hall_dressing"]
dr["enabled"] = True
if "--keep-runner" not in sys.argv:
    dr["pieces"] = [p for p in dr["pieces"] if "Runner" not in p["name"]]
if "--no-great" not in sys.argv:
    d["hall_great_hall"]["enabled"] = True
json.dump(d, open(P, "w"), indent=2)
open(P, "a").write("\n")
