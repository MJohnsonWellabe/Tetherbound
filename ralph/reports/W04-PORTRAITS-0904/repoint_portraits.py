#!/usr/bin/env python3
"""Re-point every `portrait` in data/dialogue/*.json (NOT stronghold.json) at
its speaker's own plate. Line-based so the files' hand formatting and every
`_comment` survive; verified afterwards by parsing the JSON."""
import json, re, glob, sys

DIR = "res://assets/ui/portraits/"
BY_SPEAKER = {
    "Grandpa Elias": "grandpa",
    "Mira": "mira", "Oskar": "villager_male", "Tam": "tam", "Halda": "halda",
    "Bram": "villager_male", "Quarry Foreman": "villager_male", "Kell": "villager_male",
    "Coll": "villager_male",
    "Sela": "villager_ranger", "Rescued Ranger": "villager_ranger",
    "Dara": "villager_ranger", "Nan": "villager_ranger",
    "Rae": "rae", "Doss": "doss",
    "Bryn": "bryn", "Gil": "wandering_trainer", "Old Bram": "wandering_trainer",
    "Juno": "juno", "Wilhelm": "wilhelm", "Nessa": "nessa", "Corin": "corin",
    "Ada": "ada", "Fenn": "fenn", "Garrick": "garrick", "Old Perrin": "old_perrin",
    "Tobin": "tobin", "Maren": "maren", "Sorrel": "sorrel", "Lark": "lark", "Ren": "ren",
    "Dorn": "grunt_b", "Pell": "grunt_c", "Kest": "grunt_a", "Hess": "grunt_b",
    "Orrin": "grunt_c", "Officer Dell": "officer_a", "Captain Vance": "captain_a",
    "Captain Oreth": "captain_b", "Captain Halder": "captain_a", "Captain Vess": "captain_b",
    "Watchman Corr": "grunt_a", "Warder Ness": "officer_b",
    "Patrolman Verrick": "grunt", "Warder Solene": "officer", "Keeper Hald": "captain",
    "Team Tether Notice": "grunt",
    "Trainer": "villager_male",
}
# Same generic speaker name, different body per placement (band trainers.json `base`).
BY_CONVERSATION_PREFIX = {
    "south_bridge_grunt_": "grunt_a",
    "night_watch_farro_": "grunt",
    "lost_creature_rue_": "grunt",
    "patrol_ridgeline_": "grunt_b",
}

def plate_for(conv_id, speaker):
    for prefix, f in BY_CONVERSATION_PREFIX.items():
        if conv_id.startswith(prefix):
            return f
    return BY_SPEAKER.get(speaker)

files = sorted(f for f in glob.glob("data/dialogue/**/*.json", recursive=True)
               if not f.endswith("stronghold.json"))
key_re = re.compile(r'^\s*"([A-Za-z0-9_]+)": \{')
speaker_re = re.compile(r'^\s*"speaker": "([^"]*)"')
portrait_re = re.compile(r'^(\s*"portrait": ")res://assets/ui/portraits/[a-z_]+\.png(".*)$')
changed = 0
for path in files:
    lines = open(path, encoding="utf-8").read().split("\n")
    conv_id, speaker, out = None, None, []
    for line in lines:
        m = key_re.match(line)
        if m and not m.group(1).startswith("_"):
            conv_id, speaker = m.group(1), None
        m = speaker_re.match(line)
        if m:
            speaker = m.group(1)
        m = portrait_re.match(line)
        if m:
            plate = plate_for(conv_id, speaker)
            if plate is None:
                sys.exit("no plate for %s speaker %r in %s" % (conv_id, speaker, path))
            new = "%s%s%s.png%s" % (m.group(1), DIR, plate, m.group(2))
            if new != line:
                changed += 1
            line = new
        out.append(line)
    open(path, "w", encoding="utf-8").write("\n".join(out))

# Verify by parsing: every conversation's portrait is the expected plate.
bad = []
for path in files:
    d = json.load(open(path, encoding="utf-8"))
    for cid, conv in d["conversations"].items():
        want = plate_for(cid, conv.get("speaker"))
        got = conv.get("portrait", "").split("/")[-1].replace(".png", "")
        if want != got:
            bad.append((path, cid, conv.get("speaker"), got, want))
print("%d portrait lines re-pointed across %d files" % (changed, len(files)))
for b in bad:
    print("MISMATCH", b)
sys.exit(1 if bad else 0)
