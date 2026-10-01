"""R15 failure-only diagnostic source audit; no native/parser acceptance."""
from pathlib import Path
import hashlib,json,re,math
P=Path(__file__).resolve().parent
HUB=P.parents[4]
H=lambda b:hashlib.sha256(b).hexdigest()
checks=[]
def check(n,ok):checks.append({"name":n,"passed":bool(ok)})
def read(n):return (P/n).read_text(encoding="utf-8").replace("\r\n","\n")
def functions(s):
    lines,result=s.splitlines(),{}
    for i,line in enumerate(lines):
        match=re.match(r"(?:static )?func (\w+)\(",line)
        if match:
            end=i+1
            while end<len(lines) and (not lines[end] or lines[end].startswith("\t")):end+=1
            result[match[1]]="\n".join(lines[i:end]).rstrip()
    return result
m=json.loads(read("manifest.json"));r=json.loads(read("prior-failure/receipt.json"))
for n,pin in m["files"].items():
    b=(P/n).read_bytes();check("frozen "+n,len(b)==pin["bytes"] and H(b)==pin["sha256"])
for n,pin in m["protected_hub_sha256"].items():check("unchanged HUB "+n,H((HUB/n).read_bytes())==pin)
for n,pin in m["root_executed_sha256"].items():check("actual executed ROOT input "+n,r["source_before"].get(n)==pin)
path=m["changed_path"];old,new=read("originals/"+path),read("proposal/"+path)
check("original matches executed bytes",H((P/"originals"/path).read_bytes())==r["source_before"][path])
check("live proposal exact",(P/"proposal"/path).read_bytes()==(HUB/path).read_bytes())
check("source before/after closure same",r["source_before"]==r["source_after"])
check("actual failed head",r["head"]=="aba5268a53de6724ad5ec5097c063dc0363bcc09")
of,nf=functions(old),functions(new)
changed=["_observed_live_clear","_production_live_check","_production_record"]
check("only three instrumentation insertion functions changed",[n for n in of if of[n]!=nf.get(n)]==changed)
check("only capture and transform helpers added",set(nf)-set(of)=={"_capture_failed_pre_sample","_failed_sample_transform"})
for n in of:
    if n not in changed:check("unchanged native/guard/function "+n,of[n]==nf[n])
check("original overlap refusal exact",nf["_observed_live_clear"].replace("\t\t_capture_failed_pre_sample()\n","")==of["_observed_live_clear"])
check("phase tagging only",nf["_production_live_check"].replace("\t_production_check_is_post = post\n","")==of["_production_live_check"])
check("record adds cached failure field only",nf["_production_record"].replace('\tif not _failed_pre_sample.is_empty():\n\t\trecord["failed_original_pre_sample"] = _failed_pre_sample\n',"")==of["_production_record"])
check("all native constants exact",re.findall(r"^const .*",old,re.M)==re.findall(r"^const .*",new,re.M))
check("two diagnostic transient states only",re.findall(r"^var .*",new,re.M)==re.findall(r"^var .*",old,re.M)[:re.findall(r"^var .*",old,re.M).index("var _recorded_failure := false")+1]+["var _production_check_is_post := false","var _failed_pre_sample: Dictionary = {}"]+re.findall(r"^var .*",old,re.M)[re.findall(r"^var .*",old,re.M).index("var _recorded_failure := false")+1:])
f=nf["_capture_failed_pre_sample"]
check("first failure PRE after only original query",all(s in f for s in ["not _production_steering","_production_check_is_post","_queries != 1","not _failed_pre_sample.is_empty()"]))
check("capture called only at original raw refusal",new.count("_capture_failed_pre_sample()")==2 and nf["_observed_live_clear"].index("_capture_failed_pre_sample()")<nf["_observed_live_clear"].index('_stop_geometry("deep actual overlap'))
check("same registered full capsule",all(s in f for s in ["query.shape = _body.shape_owner_get_shape(_owner, 0)","pose := _body.global_transform","query.transform = pose * _body.shape_owner_get_transform(_owner)"]))
check("no shifted pose/clone/shrink/body writes",not any(s in f for s in ["pose.origin +","CapsuleShape3D.new","query.shape.radius =","global_position =","global_transform =","move_and_slide(","move_and_collide(","body_set_","shape_set_"]))
check("same mask zero margin self-only exclusion",all(s in f for s in ["query.collision_mask = _body.collision_mask","query.margin = 0.0","query.exclude = [_body_rid]","query.motion = Vector3.ZERO","query.collide_with_bodies = true","query.collide_with_areas = false"]))
check("two budgeted native queries only",f.count("_spend()")==2 and f.count("space.collide_shape(")==1 and f.count("space.get_rest_info(")==1)
check("preflight unchanged frame/lifetime allowance", "_queries + 2 > MAX_QUERIES_FRAME or _total_queries + 2 > MAX_QUERIES_LIFETIME" in f)
check("both native results checked for registration/deadline",f.count("if not _registered_body_contract() or Time.get_ticks_usec() > _deadline:")==2)
check("same capsule pair limit recorded without dedup", "space.collide_shape(query, CONTACTS)" in f and "pairs.size() >= CONTACTS * 2" in f and "for point: Vector3 in pairs:" in f and "dedup" not in f)
check("contact geometry from original raw motion result without dedup","for index in _observed_live.get_collision_count():" in f and "shape_get_data(shape)" in f and "body_get_shape_transform(rid, shape_index)" in f and "BODY_STATE_TRANSFORM" in f)
check("geometry data restricted to bounded primitives",all(s in f for s in ["SHAPE_BOX","SHAPE_CAPSULE","SHAPE_SPHERE","SHAPE_CYLINDER","<unsupported bounded geometry>"]))
check("explicit nonacceptance/noncertificate/backend caveat",all(s in f for s in ['"acceptance": false','"raw_pairs_are_not_a_penetration_certificate": true','"backend_identity_proven": false']))
check("no new live admission value or branch","return true" not in f and "_stop_geometry(" not in f)
check("sticky reset cannot clear failure evidence","_failed_pre_sample" not in nf["reset"])
check("no print/serialize/wait inside sample","print(" not in f and "JSON.stringify" not in f and "await " not in f)
check("snapshot remains within existing callback timing",nf["_production_live_check"].index("_observed_live_clear()")<nf["_production_live_check"].index("Time.get_ticks_usec() - began"))
api=read("native-api/PhysicsDirectSpaceState3D.xml")
check("official 4.7 actual pair API type",'<method name="collide_shape">' in api and '<return type="Vector3[]" />' in api and '<method name="get_rest_info">' in api)
server=read("native-api/PhysicsServer3D.xml")
for method in ["body_get_shape_count","body_get_shape","shape_get_data","body_get_state","body_get_shape_transform","shape_get_type"]:
    check("official 4.7 native geometry getter "+method,'<method name="'+method+'"' in server)
raw=read("prior-failure/native.log")
observations=[json.loads(l.split(" ",1)[1]) for l in raw.splitlines() if l.startswith("OPENING_PRODUCTION_OBSERVATION ")]
failed=next(o for o in observations if o["refusal"]=="deep actual overlap: zero-motion recovery exceeds unchanged skin")
check("actual original PRE failed one query",failed["live_state_phase"]=="pre" and failed["queries"]==1 and failed["frame"]==3113 and failed["physics_frame"]==7473)
check("actual four raw contacts preserved",len(failed["live_contacts"])==4)
check("actual recovery norm exceeds original skin threshold",math.sqrt(sum(x*x for x in failed["live_recovery_travel"]))>failed["safe_margin"]+0.00001)
check("three Bram cycles completed before guarded exit",raw.index("Bram cycle 3 exited and movement resumed")<raw.index('ERROR: Native opening refused: deep actual overlap'))
check("original misleading coordinate label identified",'str(_player.global_position.round())' in functions(read("root-actual/tests/helpers/gate_a_npc_gather_segment.gd"))["_visit_villager"])
check("actual first catch and gather prefix, no completion", "catch complete; exploration resumed with two-creature party" in raw and "gathered +4 Wood" in raw and "gathered +4 Stone" in raw and "gathered +4 Fiber" in raw and not r["campaign_result"]["campaign_complete"])
check("no new autosave failure evidence","SAVE_SNAPSHOT_REFUSAL" not in raw)
result={"classification":"AUTHOR SOURCE ONLY; FAILURE-ONLY DIAGNOSTIC; F17#4 OPEN","passed":all(c["passed"] for c in checks),"checks":checks}
(P/"source-results.json").write_bytes((json.dumps(result,indent=2)+"\n").encode("utf-8"))
print(json.dumps({"passed":result["passed"],"checks":len(checks),"failed":[c["name"] for c in checks if not c["passed"]]}))
raise SystemExit(0 if result["passed"] else 1)
