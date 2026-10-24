"""F04#6 r30 candidate (capture only): the three Meshy aftermath heroes
(tb/meshy-1024, coordinator task ids in each provenance.jsonl) replace the
shared fallen-banner template. Scale from the normalised GLB bounds to the
requested size; sink_m = native min y x scale, plus a 5 cm bed-in.
  Riverwatch: wrecked checkpoint hut, 3.4 m tall (native 1.53 -> x2.22)
  Ridge:      felled signal pylon, 6.5 m long (native 1.89 -> x3.43)
  Field:      collapsed field tent, 4.2 m long (native 1.87 -> x2.25),
              replacing the standing tent in the after state."""
import json
P = "data/config/trainer_aftermath.json"
d = json.load(open(P))
S = d["visual_candidate_sites"]
M = "res://assets/props/meshy-1024/"
def drop_banner(site):
    S[site]["pieces"] = [p for p in S[site]["pieces"] if p.get("model") != "toppled_tether_banner"]
drop_banner("captain_riverwatch")
S["captain_riverwatch"]["pieces"].append({"model": "meadows_riverwatch_hut", "dir": M + "meadows_riverwatch_hut",
    "offset": [4.2, 1.0], "scale": 2.22, "yaw_deg": -30.0, "sink_m": -1.65, "state": "after"})
drop_banner("captain_ridge")
S["captain_ridge"]["pieces"].append({"model": "meadows_ridge_pylon", "dir": M + "meadows_ridge_pylon",
    "offset": [2.6, 0.8], "scale": 3.43, "yaw_deg": 70.0, "sink_m": -0.63, "state": "after"})
S["captain_field"]["pieces"].append({"model": "meadows_field_tent", "dir": M + "meadows_field_tent",
    "offset": [-7.2, 2.6], "scale": 2.25, "yaw_deg": 25.0, "sink_m": -0.92, "state": "after"})
open(P, "w").write(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print("applied r30")
