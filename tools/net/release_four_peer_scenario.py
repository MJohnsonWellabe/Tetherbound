#!/usr/bin/env python3
"""ACCEPTANCE §7 four-peer replays, one chain piece per scenario.

  python3 tools/net/release_four_peer_scenario.py tidewake 02_reedhaven > <scenario.json>
  tools/net/run_two_peer_proof.sh <scenario.json> --out=<dir>

The host loads the piece's committed handoff save (tools/release_replay_pieces.sh
map) and plays the piece's earned helper (proof step piece_start/piece_wait)
while three separate guest processes stay joined. Guests are disclosed fixture
guests: a fresh world with the region key and a granted five at L18.
"""
import argparse, json, pathlib, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "earned_saves"))
from validate_piece_receipt import validate

FROM = {"tidewake": {"02_reedhaven": "tidewake_01_opening", "03_brine": "tidewake_02_reedhaven",
    "04_shellwatch": "tidewake_03_brine", "05_tidal": "tidewake_04_shellwatch",
    "07a_salt_bex": "tidewake_05_tidal", "07b_calder": None,
    "07c_venn": None, "07d_nerissa": None, "08_ending": None}}
PREDECESSOR = {"07b_calder": "07a_salt_bex", "07c_venn": "07b_calder", "07d_nerissa": "07c_venn", "08_ending": "07d_nerissa"}
REALM = {"tidewake": ("water", "realm_key_water")}
# Guests reach the host's realm the production way: the Crossing Hall arch
# (RD-17), through the disclosed initial Hall-position fixture (no credit).
PORTAL = {"tidewake": "f15_dock"}
FIXTURE = "initial_hall_position_and_open_route_no_earned_credit"
GUEST_FIVE = ["bramblebun", "terrapup", "brooktail", "mudsnout", "trailpup"]

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("region", choices=FROM)
parser.add_argument("piece")
parser.add_argument("--checkpoint", help="actual preceding split checkpoint directory containing save/ and receipt.json")
options = parser.parse_args()
region, piece = options.region, options.piece
if piece not in FROM[region]:
    parser.error("unknown/retired piece; use 07a_salt_bex -> 07b_calder -> 07c_venn -> 07d_nerissa")
source = "tests/fixtures/earned_saves/%s" % FROM[region][piece]
if piece in PREDECESSOR:
    if not options.checkpoint: parser.error("split continuation requires --checkpoint from " + PREDECESSOR[piece])
    checkpoint = pathlib.Path(options.checkpoint).resolve()
    try: receipt = validate(checkpoint, PREDECESSOR[piece])
    except (OSError, ValueError) as error: parser.error(str(error))
    source = checkpoint.as_posix()
elif options.checkpoint:
    parser.error("--checkpoint is reserved for the split continuation pieces")
realm, key = REALM[region]
load_args = {"from": source + "/save", "slot": 0}
if piece in PREDECESSOR:
    load_args.update(piece_receipt=source + "/receipt.json", piece_predecessor=PREDECESSOR[piece])
steps = [{"peer": 0, "action": "load_save", "budget_frames": 20000,
    "args": load_args,
    "label": "host: the %s handoff save, loaded through Game.load_game" % source}]
for g in (1, 2, 3):
    steps += [{"peer": g, "action": "boot", "args": {"scene": "world"}, "budget_frames": 20000,
        "label": "FIXTURE guest %d: a fresh world" % g},
        {"peer": g, "action": "dismiss_dialogue", "args": {"presses": 40, "settle": 0}},
        {"peer": g, "action": "story_flag", "args": {"flag": key, "scope": "world"},
         "label": "FIXTURE guest %d holds the %s key" % (g, region)}]
    steps += [{"peer": g, "action": "party_grant", "args": {"species": s, "level": 18}} for s in GUEST_FIVE]
    steps += [{"peer": g, "action": "enter_realm", "budget_frames": 3000, "args": {"realm": realm,
        "actual_portal_fixture": FIXTURE, "portal_regression": PORTAL[region], "portal_prepare_only": True},
        "label": "DISCLOSED SETUP: guest %d at the initial Hall arch position" % g}]
steps += [{"peer": 0, "action": "host"}]
for g in (1, 2, 3):
    steps += [{"peer": g, "action": "join", "budget_frames": 20000},
        {"peer": g, "action": "dismiss_dialogue", "args": {"presses": 40, "settle": 0},
         "label": "guest %d answers the post-join welcome as a player does" % g}]
steps += [{"peer": "all", "action": "expect_peers", "args": {"count": 4}},
    ] + [{"peer": g, "action": "enter_realm", "budget_frames": 60000, "args": {"realm": realm,
        "actual_portal_fixture": FIXTURE, "portal_regression": PORTAL[region], "budget_frames": 54000},
     "label": "guest %d walks through the Crossing Hall arch into the host's %s" % (g, realm)} for g in (1, 2, 3)] + [
    {"peer": "all", "action": "wait_realm", "args": {"realm": realm, "budget_frames": 20000}, "budget_frames": 21000,
     "label": "every peer is in the host's %s realm" % realm},
    {"peer": 0, "action": "piece_start", "args": {"segment": piece},
     "label": "host plays the %s piece's earned helper with three guests joined" % piece},
    {"peer": 0, "action": "piece_wait", "args": {"budget_frames": 90000}, "budget_frames": 91000,
     "label": "the piece passes on the host"},
    {"peer": "all", "action": "expect_peers", "args": {"count": 4},
     "label": "all four peers still connected after the piece"},
    {"peer": 0, "action": "hashes_agree", "args": {"budget_frames": 3600, "stable": True}},
    {"peer": "all", "action": "capture_saves", "args": {"label": "after"}}]
json.dump({"name": "RELEASE four-peer %s %s" % (region, piece),
    "claim": "ACCEPTANCE §7 four-peer replay piece: host plays %s %s from its committed handoff save while three separate guest peers stay joined; guests are disclosed fixture guests." % (region, piece),
    "peers": 4, "scene": "title", "budget_s": 1800, "build_allowance_s": 600, "steps": steps}, sys.stdout, indent=1)
print()
