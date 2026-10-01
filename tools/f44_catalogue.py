"""Build F44 identity profiles from authored source. Never duplicates teams."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def write(path, value):
    (ROOT / path).write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")

def main():
    profiles = {}
    bosses = {"warden_aldis", "water_trainer_nerissa", "captain_veyra_storm_anchor", "captain_marrow_dynamo_core"}

    def add(row, biome, path, kind=None):
        id = row["id"]
        assert id not in profiles, id
        rank = row.get("rank", "")
        if kind is None:
            kind = "boss" if id in bosses else "leader" if rank in {"ace", "elite", "captain", "officer", "lieutenant", "grunt", "mentor"} or any(t in id for t in ("captain", "officer", "lieutenant", "relay_")) else "trainer"
        flag = row.get("defeat_flag", "")
        if not flag and biome == "tidewake":
            flag = "defeated_" + id
        if not flag and biome == "stormwood":
            flag = "stormwood:trainer:%s:defeated" % id
        profiles[id] = {"id": id, "biome": biome, "kind": kind, "source": "res://" + path,
                        "defeat_flag": flag, "essence_types": {"meadows": ["ground"], "tidewake": ["water"], "cloudreach": ["air"], "stormwood": ["electric"]}[biome]}

    for p in sorted((ROOT / "data/config/bands").glob("*/trainers.json")):
        for row in read(p.relative_to(ROOT))["trainers"]:
            add(row, "meadows", p.relative_to(ROOT).as_posix())
    for biome, path, field in [
        ("tidewake", "data/config/water_characters.json", "trainers"),
        ("cloudreach", "data/config/cloudreach_chapter.json", "trainer_ladder"),
        ("stormwood", "data/config/stormwood_trainers.json", "trainers"),
    ]:
        for row in read(path)[field]: add(row, biome, path)
    for row in read("data/config/masters.json")["masters"]:
        add(row, row["biome"], "data/config/masters.json", "master")
        profiles[row["id"]]["defeat_flag"] = ""
        profiles[row["id"]]["original_win_field"] = "master_wins"
    biomes = {}
    gates = ["defeated_warden", "water_captain_nerissa_defeated", "captain_veyra_defeated", "stormwood:marrow_defeated"]
    for index, row in enumerate(read("data/schema/material_tiers.json")[:4]):
        biomes[row["biome"]] = {"climax_flag": gates[index], "r1_levels": {"trainer": [32,43,54,55][index], "leader": [33,44,55,58][index], "master": [33,44,55,58][index]},
                                "unique_materials": {row["refined"]: 2}, "repeat_materials": {row["raws"][0]: 3}}
    write("data/config/rematches.json", {"schema_version": 1, "runtime_enabled": False,
          "day_seconds": 600, "repeat_days": 2, "unique_candy": 1, "repeat_essence_per_type": 12,
          "maximum_transaction_receipts": 4096, "credits_flag": "regional_credits_seen",
          "endgame_levels": {"trainer":55,"leader":58,"master":58,"boss":60},
          "biomes": biomes, "profiles": profiles,
          "witnesses": {"meadows":"relay_captain", "tidewake":"water_trainer_yara", "cloudreach":"officer_voss_summit_approach", "stormwood":"officer_maren_verge_rod"}})
    sites = {}
    for p in sorted((ROOT / "data/config/bands").glob("*/spawns.json")):
        for row in read(p.relative_to(ROOT)).get("spawns", []):
            if not row.get("alpha"): continue
            id = "wild_once_%d" % row["order"]
            sites[id] = {"id": id, "biome":"meadows", "region_id":p.parent.name, "source":"res://"+p.relative_to(ROOT).as_posix(), "source_order":row["order"], "original_completion_flag":id}
    for row in read("data/config/stormwood_encounters.json")["named_encounters"]:
        id = row["id"]
        sites[id] = {"id":id, "biome":"stormwood", "region_id":row["region_id"], "source":"res://data/config/stormwood_encounters.json", "original_completion_flag":"stormwood:named:%s:cleared" % id}
    for row in read("data/config/water_encounters.json")["named_encounters"]:
        id = row["id"]
        sites[id] = {"id":id, "biome":"tidewake", "region_id":row["island_id"], "source":"res://data/config/water_encounters.json", "original_completion_flag":row["completion_flag"]}
    row = read("data/config/water_alpha.json")
    sites[row["id"]] = {"id":row["id"], "biome":"tidewake", "region_id":row["island_id"], "source":"res://data/config/water_alpha.json", "original_completion_flag":row["completion_flag"]}
    write("data/config/alpha_respawns.json", {"schema_version":1, "runtime_enabled":False,
          "day_seconds":600, "respawn_days":3, "requires_all_region_departures":True,
          "trait_profiles":{"alpha":{"count_weights":[0,10,40,50],"rarity_weights":[25,45,30]},
                            "alpha_unusual":{"count_weights":[0,5,30,65],"rarity_weights":[15,45,40]}},
          "sites":sites, "cloudreach_disposition":"No named alpha in existing authored Cloudreach source; no new encounter invented."})

if __name__ == "__main__": main()
