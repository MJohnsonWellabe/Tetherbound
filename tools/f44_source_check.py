"""F44 content/grammar check. This does not execute or certify Godot behavior."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tmp/f44-parser"))
from gdtoolkit.parser import parser

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

cfg = read("data/config/rematches.json")
alpha = read("data/config/alpha_respawns.json")
assert cfg["runtime_enabled"] is False and alpha["runtime_enabled"] is False
assert cfg["day_seconds"] == alpha["day_seconds"] == 600
assert cfg["repeat_days"] == 2 and alpha["respawn_days"] == 3
assert cfg["endgame_levels"] == {"trainer":55,"leader":58,"master":58,"boss":60}
assert set(cfg["profiles"]) >= {"warden_aldis", "water_trainer_nerissa", "captain_veyra_storm_anchor", "captain_marrow_dynamo_core"}
assert len([p for p in cfg["profiles"].values() if p["kind"] == "master"]) == 5
assert len([p for p in cfg["profiles"].values() if p["kind"] == "boss"]) == 4
items = read("data/items/items.json")["items"] | read("data/config/water_crafting.json").get("item_registration_proposals", {})
for id, p in cfg["profiles"].items():
    assert id == p["id"] and (ROOT / p["source"].removeprefix("res://")).is_file()
    for type_id in p["essence_types"]: assert "essence_"+type_id in items
    source = read(p["source"].removeprefix("res://"))
    rows = source.get("trainers", source.get("trainer_ladder", source.get("masters", [])))
    assert any(r["id"] == id for r in rows), id
for biome, id in cfg["witnesses"].items(): assert cfg["profiles"][id]["biome"] == biome
for b in cfg["biomes"].values():
    assert all(id in items and n > 0 for field in ["unique_materials", "repeat_materials"] for id,n in b[field].items())
for biome, lo, hi in [("meadows",32,33),("tidewake",43,44),("cloudreach",54,55)]:
    assert all(lo <= n <= hi for n in cfg["biomes"][biome]["r1_levels"].values())
for id, site in alpha["sites"].items():
    assert site["id"] == id and site["region_id"] and site["original_completion_flag"]
    assert (ROOT / site["source"].removeprefix("res://")).is_file()
    assert site["biome"] in ["meadows", "tidewake", "stormwood"]
traits = read("data/config/traits.json")
def expectation(weights): return sum(i*w for i,w in enumerate(weights))/sum(weights)
for key, profile in alpha["trait_profiles"].items():
    ordinary = traits["profiles"][key]
    assert expectation(profile["count_weights"]) > expectation(ordinary["count_weights"])
    assert profile["rarity_weights"][2]/sum(profile["rarity_weights"]) > ordinary["rarity_weights"][2]/sum(ordinary["rarity_weights"])
char = read("data/schema/character_state.schema.json")
world = read("data/schema/world_state.schema.json")
assert "rematch_cooldowns" not in char["required"]
assert "sites" not in world["properties"]["alpha_cycles"]["required"]
assert "rematch_cooldowns" not in read("data/schema/character_state.json")
assert read("data/schema/world_state.json")["alpha_cycles"] == {}

paths = sorted((ROOT / "scripts/repeatables").glob("*.gd")) + [ROOT / p for p in [
    "scripts/net/character_action_rules.gd", "scripts/net/character_action_delivery.gd",
    "scripts/data/redesign_state.gd", "scripts/world/trainer_npc.gd",
    "scripts/combat/encounter_director.gd", "scripts/combat/cloudreach_encounter_director.gd",
    "tests/test_f44_repeatables.gd", "tools/f44_rematch_witness.gd"]]
for p in paths: parser.parse(p.read_text(encoding="utf-8"))
assert 'not spec.has("rematch")' in (ROOT/"scripts/combat/encounter_director.gd").read_text()
assert 'if spec.has("rematch"): return' in (ROOT/"scripts/combat/cloudreach_encounter_director.gd").read_text()
assert '"rematch_win"' in (ROOT/"scripts/net/character_action_rules.gd").read_text()
subprocess.run(["git", "diff", "--check"], cwd=ROOT, check=True)
report = {
    "status": "source_checks_pass_runtime_unrun", "baseline":"7f18f5e75dc2744bb283bb1c3576da4e5d61b87d",
    "profiles":len(cfg["profiles"]), "alpha_sites":len(alpha["sites"]),
    "parsed_files":{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
    "checks":["identity references and full roster census", "configured tier/reward item references", "alpha count/rarity improvement", "optional additive carrier fields", "gdtoolkit grammar", "git diff --check"],
    "limitations":["No Godot parse/type check, unit execution, imported scene, real encounter, disk save/rejoin, peer, visual or acceptance proof was run.",
                   "Both runtime gates remain OFF. Shared Session source registration, durable outcome retention/participant reconstruction and alpha world CAS/save/publish closures are unmounted.",
                   "Portable unique receipts are global per trainer/tier/character. Cooldowns use each host-world clock; cross-world hopping remains the existing F47#4 exploit audit, not a new global cap."],
    "overlapping_files":["data/schema/character_state.schema.json","data/schema/world_state.schema.json","scripts/data/redesign_state.gd","scripts/net/character_action_rules.gd","scripts/net/character_action_delivery.gd","scripts/world/trainer_npc.gd","scripts/combat/encounter_director.gd","scripts/combat/cloudreach_encounter_director.gd"],
    "dependencies":{"F16":"authenticated source registration, existing character_training delivery and owner-save/ACK; alpha CAS/world-save; accepted outcome retention before encounter forget", "F19":"current authored teams/levels and boss facts", "F20":"own-character regional_credits_seen", "F22":"canonical patterns and host encounter/vitals; no current repair rewrite", "F23":"learnset utility/ultimate execution", "F28":"actual one-creature Master duel admission and outcome producer", "F30":"host trait registration/catch projection", "F32":"canonical chapter materials", "F42":"board/source interactions mounting RematchService", "F43":"consume settled rematch identity after owner-save/ACK"},
    "pending_queue":[
        {"proof":"F44 focused logic", "command":"godot --headless --path D:/tetherbound/r2-f44 --script tests/run_tests.gd -- --only=test_f44_repeatables.gd"},
        *[{"proof":"F44 real %s rematch"%biome, "trainer_id":id, "command":"godot --path D:/tetherbound/r2-f44 --script tools/f44_rematch_witness.gd -- --biome=%s --save-dir=D:/tetherbound/r2-f44/.tmp/f44-native/%s/save-copy --output=D:/tetherbound/r2-f44/ralph/reports/R2-F44/native/%s"%(biome,biome,biome), "requires":"ROOT engine slot, mounted host producers, disposable copy of earned post-biome checkpoint (Stormwood own credits), normal title/travel/challenge/combat input; instrument captures start and settlement"} for biome,id in cfg["witnesses"].items()],
        {"proof":"F44 actual two-peer transaction/save witness", "requires":"Host and guest rematch participation; late observer refusal; loss/retry; full satchel; failed bool world/owner save; disconnect after outcome before ACK; process restart and same-ID new epoch; rejoin; first reward exactly once and repeat at 1199/1200 elapsed world seconds; original keys/relics/offers/aftermath unchanged. Driver requires pending shared runtime binding; no executable proof claimed."},
        {"proof":"F44 actual alpha respawn/catch witness", "requires":"One host site resolve/catch; both peers leave its principal region; save/reload before/after 1800 elapsed seconds; new generation retained roll; one actual catcher/UID; no copy to other peer; original first defeat/catch rewards unchanged; clock regression, concurrent spawn CAS and publication retry. Driver requires pending shared runtime binding; no executable proof claimed."}
    ]}
out = ROOT/"ralph/reports/R2-F44/source-audit.json"
out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"status":report["status"],"profiles":report["profiles"],"alpha_sites":report["alpha_sites"],"grammar_files":len(paths),"report":str(out)}))
