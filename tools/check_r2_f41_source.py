"""Non-engine source audit only. Never produces a visual/runtime PASS."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = "7f18f5e75dc2744bb283bb1c3576da4e5d61b87d"
checks = []


def check(name, condition):
    checks.append({"check": name, "pass": bool(condition)})
    assert condition, name


def config(name):
    return json.loads((ROOT / "data/config" / f"{name}.json").read_text(encoding="utf-8"))


tree = config("stormheart_presentation")
check("tree and core candidate stay disabled", not tree["enabled"] and not tree["core_finish"]["enabled"])
check("road finish stays disabled", not config("stormwood_road_current")["finish_candidate"]["enabled"])
check("ground profile stays disabled", not config("stormwood_ground_finish")["enabled"])
check("legacy scar candidate stays disabled", not config("stormwood_glass_field")["scorched_scars"])
check("Stormwood time grade remains pinned", config("stormwood_surge")["presentation"]["storm_base"]["pin_time_of_day"])

path = "scripts/world/stormheart_tree.gd"
current = (ROOT / path).read_text(encoding="utf-8")
baseline = subprocess.check_output(["git", "show", f"{BASE}:{path}"], cwd=ROOT, text=True)


def function(source, name):
    return re.search(rf"^func {name}\(.*?(?=^func |\Z)", source, re.M | re.S).group(0).strip()


for name in ("_ring", "_ascent", "ascent_point", "_ramp", "_surface", "add_approach"):
    check(f"physical tree function {name} unchanged", function(current, name) == function(baseline, name))

changed = subprocess.check_output(["git", "diff", BASE, "--name-only"], cwd=ROOT, text=True).splitlines()
check("no terrain/scatter/gameplay/save/shared look edits", not any(
    p.startswith(("data/terrain/", "data/scatter/", "autoload/", "scripts/combat/")) or
    p in ("data/config/art.json", "data/config/grass_field.json", "scripts/world/world_look.gd", "data/config/stormwood_surge.json")
    for p in changed))

audio_text = (ROOT / "data/config/stormwood_audio.json").read_text(encoding="utf-8")
audio_paths = sorted(set(re.findall(r'"asset_path":\s*"res://([^"]+)"', audio_text)))
missing = [p for p in audio_paths if not (ROOT / p).exists()]
report = {"scope": "Non-engine structural checks; runtime/native/judge/audio acceptance pending",
          "base": BASE, "checks": checks, "missing_audio": missing,
          "regional_config_sha256": {name: hashlib.sha256((ROOT / "data/config" / f"{name}.json").read_bytes()).hexdigest()
          for name in ("stormheart_presentation", "stormwood_road_current", "stormwood_ground_finish")}}
destination = ROOT / "ralph/reports/R2-F41/source-audit.json"
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(f"{len(checks)} structural checks passed; {len(missing)} absent audio assets remain owner decision; no runtime proof")
