"""Relocate an immutable genuine F48 input bundle without altering saved bytes."""
import argparse, copy, hashlib, json
from pathlib import Path, PureWindowsPath

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def require(ok, message):
    if not ok: raise ValueError(message)
def tail(path, marker):
    parts=PureWindowsPath(path).parts
    require(parts.count(marker)==1, "Ambiguous/outside immutable bundle path")
    suffix=parts[parts.index(marker):]
    require(all(part not in {"..", ".", ""} for part in suffix), "Unsafe bundle suffix")
    return Path(*suffix)

def relocate(bundle, output):
    bundle=bundle.resolve(); output=output.resolve()
    require(not output.exists(), "Fresh relocated profile output required")
    receipt_path=output.with_suffix(".relocation.json")
    require(not receipt_path.exists(), "Fresh relocation receipt required")
    original=bundle/"profile.json"; manifest=json.loads((bundle/"producer-manifest.json").read_bytes())
    require(manifest.get("acceptance_credit") is False and manifest.get("earned_checkpoint") is False and
            manifest.get("mutations")==[], "Immutable actual producer bundle required; no setup mutations")
    require(digest(original)==manifest.get("profile_sha256"), "Original packaged profile hash mismatch")
    profile=json.loads(original.read_bytes()); observed=[]
    expected={"loop","behind","boss_four","craft","release","feast","key","relic","essence_spend"}
    require(expected <= set(manifest["starts"]), "All original default suites/24 cuts require complete actual inputs")
    closure={}
    for name, start in manifest["starts"].items():
        closure[name]={}
        for row in start["documents"]:
            relative=tail(row["path"], "starts")
            require(len(relative.parts)>=4 and relative.parts[1]==name and relative.parts[2].startswith("peer-"), "Cross-case source path replacement")
            actual=bundle/relative
            require(actual.resolve().is_relative_to(bundle) and not actual.is_symlink() and
                    actual.is_file() and digest(actual)==row["sha256"], "Original saved document byte mismatch")
            root=bundle/Path(*relative.parts[:3])
            pinned=closure[name].setdefault(str(root),set())
            require(str(actual) not in pinned, "Duplicate pinned saved document")
            pinned.add(str(actual))
            observed.append({"path":str(actual),"sha256":row["sha256"]})
    def saved_paths(start,name):
        paths=[]
        require(len(start["saves"])==(4 if name=="boss_four" else 2), "Exact original peer count required")
        for index,path in enumerate(start["saves"]):
            relative=tail(path,"starts"); actual=bundle/relative
            require(len(relative.parts)==3 and relative.parts[1]==name and relative.parts[2]==f"peer-{index}" and
                    actual.is_dir() and actual.resolve().is_relative_to(bundle) and not actual.is_symlink(), "Invalid/cross-case actual saved input root")
            require(str(actual) in closure[name], "Saved input root has no verified manifest document closure")
            files=set()
            for candidate in actual.rglob("*"):
                require(not candidate.is_symlink() and candidate.resolve().is_relative_to(actual.resolve()), "Saved input contains link/outside byte source")
                if candidate.is_file(): files.add(str(candidate))
            require(files==closure[name][str(actual)], "Saved input contains unlisted/missing character/world/locator bytes")
            paths.append(str(actual))
        start["saves"]=paths
    all_starts={**profile["suite_profiles"],**profile["transaction_profiles"]}
    require(set(all_starts)==set(manifest["starts"]), "Profile/manifest named starts differ")
    defaults=[name for name,start in all_starts.items() if start["saves"]==profile["saves"]]
    require(len(defaults)==1, "Default save roots must exactly match one original complete named start")
    relocated=copy.deepcopy(profile); saved_paths(relocated,defaults[0])
    for field in ("suite_profiles","transaction_profiles"):
        for name,start in relocated[field].items(): saved_paths(start,name)
    for row in relocated["test_configuration"]:
        actual=bundle/tail(row["overlay_file"],"test-configuration")
        require(actual.resolve().is_relative_to(bundle) and not actual.is_symlink() and
                actual.is_file() and digest(actual)==row["sha256"], "Pinned effective overlay byte mismatch")
        row["overlay_file"]=str(actual)
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(relocated,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    receipt={"original_profile_sha256":digest(original),"relocated_profile_sha256":digest(output),
             "saved_documents":observed,"saved_bytes_changed":False,"configuration_bytes_changed":False,
             "acceptance_credit":False,"claim":"Paths only; original native suites and all24 cuts still required"}
    receipt_path.write_text(json.dumps(receipt,indent=2)+"\n",encoding="utf-8")
    return receipt

if __name__=="__main__":
    parser=argparse.ArgumentParser(); parser.add_argument("--bundle",type=Path,required=True); parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args(); print(json.dumps(relocate(args.bundle,args.output)))
