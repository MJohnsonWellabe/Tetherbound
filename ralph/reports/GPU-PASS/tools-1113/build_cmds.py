"""Derive arm_run's cmds.json and frame_to_cmd.json from an item-scores job.json.
Usage: build_cmds.py <job.json> <out_dir>
Each frame's repro ("godot --path . <engine args> --script tool -- <tool args>") becomes {biome, key, args}; identical repros share a key,
and the output path argument is replaced by {OUT}. Writes an empty cmds_extra.json only if there is none."""
import json, os, shlex, sys

job = json.load(open(sys.argv[1], encoding="utf-8"))
out = sys.argv[2]
cmds, fmap, odd = [], {}, []
for biome, doc in job["biomes"].items():
    seen, fmap[biome] = {}, {}
    for item in doc["items"]:
        for frame in item.get("frames", []):
            repro = (frame.get("repro") or "").strip()
            if not repro.startswith("godot --path . "):
                odd.append((biome, frame.get("id"), repro[:80]))
                continue
            args = shlex.split(repro)[3:]
            for i, a in enumerate(args):
                for flag in ("--output=", "--out="):
                    if a.startswith(flag):
                        args[i] = flag + "{OUT}"
            # A repro with no output flag (cloudreach_ride) would write to the tool's default folder, where arm_run can't collect it.
            if not any(a.startswith(("--output=", "--out=")) for a in args):
                args.append("--output={OUT}")
            k = tuple(args)
            if k not in seen:
                seen[k] = "c%03d" % len(seen)
                cmds.append({"biome": biome, "key": seen[k], "args": args})
            fmap[biome][frame["id"]] = seen[k]
json.dump(cmds, open(os.path.join(out, "cmds.json"), "w", encoding="utf-8"), indent=1)
json.dump(fmap, open(os.path.join(out, "frame_to_cmd.json"), "w", encoding="utf-8"), indent=1)
extra = os.path.join(out, "cmds_extra.json")
if not os.path.exists(extra):
    json.dump([], open(extra, "w", encoding="utf-8"))
print("commands", len(cmds), "frames", sum(len(v) for v in fmap.values()), "odd repros", len(odd))
for o in odd[:20]:
    print("  ODD", o)
