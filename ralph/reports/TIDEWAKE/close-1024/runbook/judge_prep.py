"""Build a code-blind judge folder + prompt for one batch (close-1024 recipe).

Usage: python3 judge_prep.py <name> <seed> <spec.json>
spec.json: [{"label", "a": png, "b": png, "brief", "defects": [...]}, ...]
(a/b are stacked contact sheets from stack.py). Writes /tmp/claude-0/judge_<name>
(images + docs/reference + sets.md) and /tmp/claude-0/key_<name>/{key.json,
recorded_defects.txt, p.txt}. Then run three fresh general-purpose agents with:
"Read the file /tmp/claude-0/key_<name>/p.txt and follow its instructions
exactly; it is your complete task. (Reading that one prompt file is the only
exception to its isolation rule.)" Map A/B back through key.json, take the
anchor scores from the judges' JSON, write batch.json and run calibrate.py.
"""
import shutil, subprocess, sys
name, seed, spec = sys.argv[1], sys.argv[2], sys.argv[3]
J, K = f"/tmp/claude-0/judge_{name}", f"/tmp/claude-0/key_{name}"
shutil.rmtree(J, ignore_errors=True)
subprocess.run(["mkdir", "-p", K], check=True)
shutil.copy(spec, f"{K}/spec.json")
subprocess.run(["python3", "tools/visual_judge/anchor_tiles.py", "--out", J, "--key", f"{K}/key.json",
                "--candidates", f"{K}/spec.json", "--seed", seed, "--pairs", "3",
                "--include", "craft", "--include", "f36_0_npc:C1"], check=True)
shutil.copytree("docs/reference", f"{J}/reference")
lines = open("tools/visual_judge/JUDGE_PROMPT.md").read().split("\n")[36:155]
text = "\n".join(lines).replace("[JUDGE FOLDER]", J)
text = text.replace("[SET LIST]", open(f"{J}/sets.md").read().strip())
text = text.replace("[RECORDED DEFECTS]", open(f"{K}/recorded_defects.txt").read().strip())
open(f"{K}/p.txt", "w").write(text)
print(open(f"{K}/key.json").read())
