"""F04#6 r31 candidate (capture only): r30, plus the r30 judges' two asks.
  Riverwatch: the wrecked checkpoint hut stands in BOTH states (it is the
              site's checkpoint, not a building that appears after the win),
              moved to clear the before crates; the fallen banner returns as
              the after cue.
  Dell:       the win leaves marks: the toppled banner lies by the dead pylon
              and the two crates are knocked over instead of vanishing."""
import json, runpy, os
here = os.path.dirname(os.path.abspath(__file__))
runpy.run_path(os.path.join(here, "F04-6-r30-apply.py"))
P = "data/config/trainer_aftermath.json"
d = json.load(open(P))
S = d["visual_candidate_sites"]
BANNER = {"model": "toppled_tether_banner", "dir": "res://assets/props/meshy-1020/toppled_tether_banner/model_toppled_tether_banner",
          "scale": 1.6, "pitch_deg": -90.0, "sink_m": -0.18, "state": "after"}
rw = S["captain_riverwatch"]["pieces"]
for p in rw:
    if p.get("model") == "meadows_riverwatch_hut":
        p.pop("state", None)
        p["offset"] = [5.0, 0.4]
rw.append(dict(BANNER, offset=[3.0, 0.2], yaw_deg=-30.0))
dell = S["relay_officer_dell"]["pieces"]
crates = [p for p in dell if p.get("model") == "Crate_Wooden"]
crates[0].pop("state"); crates[0]["after"] = {"offset": [-1.6, 1.2], "roll_deg": 90.0, "sink_m": -0.3}
crates[1].pop("state"); crates[1]["after"] = {"offset": [-1.0, 0.0], "pitch_deg": 75.0, "yaw_deg": 30.0, "sink_m": -0.25}
dell.append(dict(BANNER, offset=[-1.4, 2.0], yaw_deg=20.0))
open(P, "w").write(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print("applied r31")
