"""Declare real producer input routes; never a ready CI/earned profile."""
import argparse, copy, hashlib, json
from pathlib import Path
import save_document

def step(step_action, **args): return {"action": step_action, "args": args}
def approach(target):
    # A restored save does not retain its transient deployed body. The original
    # idempotent input step verifies ownership and uses ordinary recall if needed.
    return [step("f48_deploy_owned"), step("f48_fixture_approach", target=target,
                 fixture_disclosure="named_mechanics_actor_and_owned_ally_placement_no_earned_credit")]
def press(action, **args): return step("press", action=action, **args)
def button(text): return step("f48_button", text=text)
def wait(frames=45): return step("wait", frames=frames)
def contact(target): return approach(target)+[press("interact"),wait()]
def close(): return [press("ui_cancel"),wait(15),press("ui_cancel"),wait(15)]
def fight(trainer):
    return step("f48_fixture_trainer_fight", trainer_id=trainer,
                budget_frames=9000 if trainer == "warden_aldis" else 3000,
                fixture_disclosure={"scope":"named_mechanics_only","self_hp_topups":True,
                    "ally_placement":True,"enemy_hp_ceiling":0,"earned_campaign_credit":False})

def produce(source: Path, output: Path):
    assert not output.exists(), "Fresh output required"
    raw=source.read_bytes(); profile=json.loads(raw)
    assert len(profile["saves"])==2 and profile.get("configuration_scope")=="full"
    routes=profile["routes"]
    routes["craft_prepare"]=contact("forge")
    routes["craft_reopen"]=copy.deepcopy(routes["craft_prepare"])
    routes["essence_spend_prepare"]=contact("altar")+[button("Creature training"),wait()]
    routes["essence_spend_reopen"]=copy.deepcopy(routes["essence_spend_prepare"])
    for peer in range(2):
        files=list(Path(profile["saves"][peer]).rglob("character.json")); assert len(files)==1
        owner=save_document.decode(json.loads(files[0].read_bytes())); cards=owner["party"]
        assert len(cards)==1 and cards[0]["species_id"]=="terrapup" and cards[0]["level"]==9
        uid=cards[0]["uid"]; nickname=cards[0]["nickname"]
        routes[f"hub_{peer}"]=copy.deepcopy(routes["essence_spend_prepare"])+[button("Ground Essence · Cost 20 · Have 100"),wait(120)]+close()
        routes[f"craft_{peer}"]=contact("forge")+[button("Refine Rootiron Ingot"),wait(150)]+close()
        routes[f"portal_{peer}"]=contact("home_arch")+[wait(180)]
        routes[f"master_{peer}"]=contact("master_t1")+[button(f"{nickname} · Lv 10"),wait(60),fight("master_t1"),wait(120)]+contact("master_t1_chest")
        cook=contact("kitchen")+[button("Cook learned Ascension Feasts"),wait()]
        routes[f"feast_cook_{peer}"]=cook+[step("f48_button", feast_recipe="feast_t1_ground"),wait(120)]+close()
        feed=cook+[button("Feed creatures"),wait()]
        routes[f"feast_{peer}"]=feed+[button(f"{nickname} · Breakthrough needed · Ascension Feast 1 (ground)"),wait(120)]+close()
        routes[f"boss_prepare_{peer}"]=approach("warden_aldis")
        routes[f"relic_{peer}"]=contact("meadows_pedestal")+[wait(120)]
        profile["outcomes"][f"feast_{peer}"]={"creature":{"uid":uid,"level":10,"breakthroughs":[1]},
            "item_delta":{"feast_t1_ground":-1},"equals":{f"redesign_character/creatures/{uid}/cap_level":20}}
    routes["boss_start"]=[press("interact"),wait(),step("f48_dialogue",conversation="stronghold_warden_challenge"),wait(90)]
    routes["boss_join_1"]=[step("f48_fixture_join_boss",fixture_disclosure="named_mechanics_actual_announced_boss_join_no_earned_credit")]
    routes["boss_fight"]=[fight("warden_aldis")]
    routes["feast_prepare"]=copy.deepcopy(feed)
    routes["feast_reopen"]=copy.deepcopy(feed)
    routes["feast_commit"]=[button("B · Breakthrough needed · Ascension Feast 1 (ground)"),wait(120)]
    routes["key_prepare"]=approach("tidewake_arch"); routes["key_reopen"]=copy.deepcopy(routes["key_prepare"])
    routes["key_commit"]=[press("interact"),wait(120)]
    routes["relic_prepare"]=approach("meadows_pedestal"); routes["relic_reopen"]=copy.deepcopy(routes["relic_prepare"])
    routes["relic_commit"]=[press("interact"),wait(120)]
    profile["prepare_paid_altar"]=True; profile["prepare_alpha_capture"]=True
    profile["provenance"]+=" Explicit source-derived INPUT producer routes: actor/owned-ally placement, paused real Alpha RNG, real announced boss join, self-HP aid and ally placement, enemy HP ceiling0. No ordinary survival/balance/campaign credit. Captured source and every actual journal/owner write/ACK must be native; NOT a complete CI bundle."
    output.mkdir(parents=True)
    path=output/"profile.json"; path.write_text(json.dumps(profile,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    (output/"source.json").write_text(json.dumps({"source":str(source),"source_sha256":hashlib.sha256(raw).hexdigest(),
        "profile_sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"acceptance_credit":False,
        "ready_ci_bundle":False,"release_uid":"Requires actual producer result; never invented"},indent=2)+"\n",encoding="utf-8")
    return path

if __name__=="__main__":
    parser=argparse.ArgumentParser(); parser.add_argument("--source",type=Path,required=True); parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args(); path=produce(args.source,args.output)
    print(json.dumps({"profile":str(path),"sha256":hashlib.sha256(path.read_bytes()).hexdigest(),"acceptance_credit":False}))
