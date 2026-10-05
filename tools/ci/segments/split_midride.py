#!/usr/bin/env python3
"""Split tools/net/proof_scenarios/f06_cloudreach_midride_rejoin.json into CI
segments under tools/net/proof_scenarios/segments/midride/.

Every original step is copied unchanged except `peer` (remapped in the
single-peer setup producers) and a `_comment` "orig #N" naming its source
step; steps a segment adds to start from / write its checkpoint carry
`_comment` "SEGMENT: ...". tools/ci/segments/check_coverage.py proves every
original (step, peer) instance is run exactly once by some segment.

    python3 tools/ci/segments/split_midride.py   # rewrites the five files
"""
import copy, json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
ORIGINAL = "tools/net/proof_scenarios/f06_cloudreach_midride_rejoin.json"
OUT = "tools/net/proof_scenarios/segments/midride"

orig = json.load(open(os.path.join(ROOT, ORIGINAL)))
steps = orig["steps"]


def o(n, peer=None):
    s = copy.deepcopy(steps[n - 1])
    if peer is not None:
        s["peer"] = peer
    s["_comment"] = "orig #%d" % n
    return s


def seg(why, **step):
    step["_comment"] = "SEGMENT: " + why
    return step


def fixture(peer="all"):
    s = copy.deepcopy(steps[0])
    s["peer"] = peer
    s["_comment"] = "SEGMENT: orig #1 again -- every fresh process takes the disclosed fixture"
    return s


def start_host(boundary):
    return [
        seg("committed checkpoint is fresh and meets the start contract", peer=0, action="seg_verify",
            args={"boundary": boundary, "role": "host"}, label="handoff: host checkpoint %s" % boundary),
        seg("host resumes from the checkpoint through Game.load_game and a boot of its realm", peer=0,
            action="load_save", args={"from": "tests/fixtures/segments/%s/host" % boundary},
            expect_data={"realm": "cloudreach"}, budget_frames=20000, label="host loads %s" % boundary),
        seg("live host state meets the start contract", peer=0, action="seg_contract",
            args={"boundary": boundary, "role": "host"}, label="handoff: live host meets %s" % boundary),
    ]


def seed_guest(boundary):
    return seg("guest's own disk holds the checkpoint; the next production join reads it", peer=1,
               action="seg_seed_home", args={"boundary": boundary, "role": "guest"},
               label="handoff: guest checkpoint %s seeded" % boundary)


def end(boundary, label, peers=(("host", 0), ("guest", 1)), capture=True):
    out = []
    if capture:
        out.append(seg("the production save at the end of this segment", peer="all" if len(peers) > 1 else 0,
                       action="capture_saves", args={"label": label}))
    for role, p in peers:
        out.append(seg("segment end meets the next segment's start contract and reproduces the committed checkpoint",
                       peer=p, action="seg_checkpoint", args={"boundary": boundary, "role": role, "label": label},
                       label="checkpoint %s:%s" % (boundary, role)))
    return out


def rejoin_from_title(why):
    return [
        seg("host opens its session (orig #15's step, for this segment's fresh host)", peer=0, action="host"),
        seg("orig #16's check, for this segment's fresh host", **{k: v for k, v in steps[15].items() if k != "label"},
            label="host world: gate CLOSED before the join"),
        seg(why, **{k: v for k, v in steps[16].items() if k != "label"}, label="guest continues its own save through the title's production join"),
        seg("both peers registered", peer="all", action="expect_peers", args={"count": 2}),
        seg("same identity check as orig #20", **{k: v for k, v in steps[19].items() if k != "label"},
            label="JOIN: guest in Cloudreach, five owned"),
    ]


def scenario(name, peers, peer_map, body, claim, budget=1500):
    return {"name": "%s -- %s" % (orig["name"], name),
            "claim": claim + " Segment of %s (CI segments: tests/helpers/ci_segments.gd)." % ORIGINAL,
            "_comment_segment": {"original": ORIGINAL, "peer_map": peer_map},
            "peers": peers, "scene": orig["scene"], "budget_s": budget, "steps": body}


files = {
    "s0_setup_host.json": scenario(
        "segment 0 (host setup)", 1, {"0": 0},
        [o(1, 0), o(2, 0), o(3, 0), o(11, 0)] + end("midride/setup", "checkpoint", (("host", 0),)),
        "The host's world: fresh Meadows, Cloudreach key, crossed into Cloudreach; gate closed. Writes checkpoint midride/setup:host."),
    "s0_setup_guest.json": scenario(
        "segment 0 (guest setup)", 1, {"0": 1},
        [o(1, 0), o(2, 0), o(3, 0)] + [o(n, 0) for n in range(4, 11)] + [o(12, 0), o(13, 0), o(14, 0)]
        + end("midride/setup", "checkpoint", (("guest", 0),)),
        "The guest's own world and character: fresh Meadows, Cloudreach key AND the upper route open, five owned, a saddle, saved at the Cloudreach arrival. Writes checkpoint midride/setup:guest."),
    "s1_ride_a.json": scenario(
        "segment 1 (A: mid-ride drop on the arrival road)", 2, {"0": 0, "1": 1},
        [fixture()] + start_host("midride/setup") + [seed_guest("midride/setup")]
        + [o(n) for n in range(15, 60)] + end("midride/after_a", "checkpoint"),
        "Part A from checkpoint midride/setup; writes midride/after_a."),
    "s2_ride_b.json": scenario(
        "segment 2 (B: mid-ride drop at the closed gate)", 2, {"0": 0, "1": 1},
        [fixture()] + start_host("midride/after_a") + [seed_guest("midride/after_a")]
        + rejoin_from_title("guest resumes the character A left on disk, through the title's production join")
        + [o(n) for n in range(60, 94)] + end("midride/after_b", "after_midride_rejoins", capture=False),
        "Part B from checkpoint midride/after_a; orig #91's own capture writes midride/after_b."),
    "s3_control.json": scenario(
        "segment 3 (CONTROL: open gate)", 2, {"0": 0, "1": 1},
        [fixture()] + start_host("midride/after_b") + [seed_guest("midride/after_b")]
        + rejoin_from_title("guest resumes the character B left on disk, through the title's production join")
        + [o(n) for n in range(94, len(steps) + 1)],
        "CONTROL from checkpoint midride/after_b."),
}

for name, data in files.items():
    path = os.path.join(ROOT, OUT, name)
    with open(path, "w") as f:
        json.dump(data, f, indent=1)
        f.write("\n")
    print("wrote", os.path.relpath(path, ROOT), len(data["steps"]), "steps")
