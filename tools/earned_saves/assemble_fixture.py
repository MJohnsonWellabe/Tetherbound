#!/usr/bin/env python3
"""Copy the earned chain's final save into the repo fixture and write PROVENANCE.json.

    tools/earned_saves/assemble_fixture.py <chain_root> <seed> "<runner command>"

Reads each segment's receipt.json under <chain_root>/<segment>/, refuses unless
all seven passed, copies <chain_root>/warden/save/ to
tests/fixtures/earned_saves/c1_arrival/save/ and refuses above 20 MB.

Checkpoint-joined mode (owner speed rule: iterate from the save just before a
failure):

    assemble_fixture.py <chain_root> <seed> "<cmd>" --prefix=<receipts_dir> \
        --legs=warden@village_pre_kell,kell_rift2@storm_road_join,storm2

<receipts_dir> holds passed receipts for the segments before `warden` (the
committed seed4_hall checkpoint). Each leg is a dir under <chain_root>; a leg
with @<checkpoint> may have failed later but must carry the passed
`checkpoint_<checkpoint>` receipt, and the next leg must have been started from
that checkpoint's save. The last leg must pass; its save becomes the fixture.

Explicit generated input mode (owner #5726060136810):

    assemble_fixture.py <input_save> <saved_seed> "<generator command>" \
        --mode=generated_fixture --destination=<absent_template_root> \
        --predecessor=warrens --expected-day=5 --expected-realm=meadows \
        --expected-position=<x,y,z> [--node=<node executable>]

Copies production bytes unchanged and writes generated_fixture_template
provenance. The existing runner applies its declared profile, saves/exports the
actual predecessor and performs production title Load. No earned receipt is
invented here, and neither prior play nor a continuous fresh-save run is claimed.
"""
import json
import hashlib
import math
import os
import re
import shutil
import subprocess
import sys

SEGMENTS = ["opening_team", "camp_tournament", "bridge", "warrens", "relay", "hall", "warden"]
LIMIT = 20 * 1024 * 1024
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DEST = os.path.join(REPO, "tests", "fixtures", "earned_saves", "c1_arrival")
GENERATED_BOUNDARIES = {"warrens", "relay_prepared", "relay", "hall", "meadows_settled",
                        "tidewake_settled", "cloudreach_settled", "stormwood_settled"}

# Read with the existing production Node codec: signed identities remain BigInt.
# This validator never serializes a save. The runner owns live setup, production
# save/export and title Load; this command only supplies a declared template.
GENERATED_VALIDATOR = r"""
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [codec, root, specification] = process.argv.slice(1);
const {parseSaveDocument} = await import(pathToFileURL(codec).href);
const expected = JSON.parse(specification);
const object = x => x !== null && typeof x === 'object' && !Array.isArray(x);
const finite = x => typeof x === 'number' && Number.isFinite(x);
const integer = x => Number.isSafeInteger(x);
const id = x => typeof x === 'string' && /^[A-Za-z0-9_-]+$/.test(x);
function read(relative, version) {
  const file = path.join(root, relative);
  const bytes = fs.readFileSync(fs.existsSync(file) ? file : file + '.gz');
  const data = parseSaveDocument((fs.existsSync(file) ? bytes : zlib.gunzipSync(bytes)).toString('utf8'));
  assert.ok(object(data) && data.version === version, 'Unsupported production schema: ' + relative);
  return data;
}
const slot = read('slot_0.json', expected.versions[0]);
const locator = slot.split_locator;
assert.ok(object(locator) && id(locator.world_id) && id(locator.character_id), 'Missing safe production locator');
const world = read(`worlds/${locator.world_id}/world.json`, expected.versions[1]);
const character = read(`characters/${locator.character_id}/character.json`, expected.versions[2]);
assert.equal(world.world_id, locator.world_id);
assert.equal(character.character_id, locator.character_id);
assert.equal(character.last_world_id, locator.world_id);
assert.ok(typeof world.reward_delivery_namespace === 'string' && world.reward_delivery_namespace.length > 0);
assert.equal(slot.reward_delivery_namespace, world.reward_delivery_namespace);
assert.ok(typeof world.world_seed === 'bigint' || integer(world.world_seed), 'Invalid saved seed');
assert.equal(String(world.world_seed), expected.seed, 'Saved seed differs from declared input');
assert.equal(slot.world_seed, world.world_seed);
assert.ok(integer(world.day) && world.day > 0 && world.day === expected.day, 'Unexpected saved day');
assert.equal(slot.day, world.day);
assert.ok(finite(world.clock_elapsed_seconds) && world.clock_elapsed_seconds >= 0, 'Malformed saved clock');
assert.equal(slot.clock_elapsed_seconds, world.clock_elapsed_seconds);
assert.equal(slot.current_realm, expected.realm);
assert.equal(character.realm, expected.realm);
const pose = character.player_pose;
assert.ok(object(pose) && pose.realm === expected.realm && Array.isArray(pose.position) &&
  pose.position.length === 3 && pose.position.every(finite), 'Missing finite saved pose');
assert.deepEqual(pose.position, expected.position, 'Saved position differs from declared input');
for (const key of ['model_yaw', 'camera_yaw', 'camera_pitch']) assert.ok(finite(pose[key]), 'Malformed saved camera');
if (pose.traversal !== undefined) assert.ok(object(pose.traversal) && pose.traversal.mode === 'grounded' &&
  pose.traversal.realm === expected.realm, 'Generated template must use a grounded pose');
assert.deepEqual(slot.player_pose, pose);
assert.ok(Array.isArray(character.party) && character.party.length === 5, 'Exactly five creatures required');
const uids = character.party.map(member => {
  assert.ok(object(member) && typeof member.uid === 'string' && member.uid.length > 0, 'Missing creature UID');
  return member.uid;
});
assert.equal(new Set(uids).size, 5, 'Duplicate creature UID');
assert.deepEqual(slot.party, character.party);
assert.ok(object(character.redesign_character) && object(character.redesign_character.creatures));
for (const uid of uids) assert.ok(object(character.redesign_character.creatures[uid]), 'Missing durable creature record');
assert.deepEqual(slot.redesign_character, character.redesign_character);
assert.deepEqual(slot.redesign_world, world.redesign_world);
assert.ok(Array.isArray(character.inventory), 'Missing slot inventory');
for (const stack of character.inventory) assert.ok(stack === null || (object(stack) &&
  typeof stack.id === 'string' && stack.id.length > 0 && integer(stack.n) && stack.n > 0), 'Malformed inventory stack');
assert.deepEqual(slot.inventory, character.inventory);
function flags(carrier) {
  assert.ok(object(carrier) && Array.isArray(carrier.flags) && carrier.flags.every(x => typeof x === 'string' && x.length > 0), 'Malformed flags');
  assert.equal(new Set(carrier.flags).size, carrier.flags.length, 'Duplicate flag');
  return carrier.flags;
}
const combined = [...new Set([...flags(world.flags), ...flags(character.flags)])].sort();
assert.deepEqual([...flags(slot.progression)].sort(), combined, 'Split flags disagree');
console.log(JSON.stringify({character_id: character.character_id, world_id: world.world_id,
  reward_delivery_namespace: world.reward_delivery_namespace, ordered_uids: uids,
  saved_world_seed: String(world.world_seed), saved_day: world.day, saved_realm: character.realm,
  saved_position: pose.position, saved_clock_elapsed_seconds: world.clock_elapsed_seconds,
  inventory_slots: character.inventory.length, flags: combined}));
"""


def tree_hashes(source):
    hashes = {}
    for directory, dirs, files in os.walk(source, followlinks=False):
        for name in dirs + files:
            if os.path.islink(os.path.join(directory, name)):
                sys.exit("generated input refuses symbolic links")
        for name in files:
            path = os.path.join(directory, name)
            with open(path, "rb") as fh:
                hashes[os.path.relpath(path, source).replace(os.sep, "/")] = hashlib.sha256(fh.read()).hexdigest()
    return hashes


def generated(root, seed, command, options):
    """Validate/copy an input template; the runner exports the actual boundary."""
    required = {"mode", "destination", "predecessor", "expected-day", "expected-realm", "expected-position"}
    if not required <= options.keys() or options.keys() - required - {"node"}:
        sys.exit("generated_fixture requires destination, predecessor, expected-day/realm/position; optional node")
    if options["predecessor"] not in GENERATED_BOUNDARIES:
        sys.exit("generated input requires an unfinished Warrens-or-later predecessor")
    source = os.path.realpath(root)
    destination = os.path.realpath(options["destination"])
    try:
        shared = os.path.commonpath([source, destination])
    except ValueError:  # Distinct Windows drives cannot contain each other.
        shared = None
    if not os.path.isdir(source) or os.path.lexists(destination) or shared in [source, destination]:
        sys.exit("generated input requires distinct source and absent destination roots")
    day = int(options["expected-day"])
    position = [float(value) for value in options["expected-position"].split(",")]
    realm = options["expected-realm"]
    authored_realm = {"tidewake_settled": "water", "cloudreach_settled": "cloudreach",
                      "stormwood_settled": "stormwood"}.get(options["predecessor"], "meadows")
    if day <= 0 or len(position) != 3 or not all(math.isfinite(value) for value in position) or \
            realm != authored_realm:
        sys.exit("generated input requires a positive day, finite XYZ position and authored realm")
    versions = []
    for name in ["save_game", "world_save", "character_save"]:
        with open(os.path.join(REPO, "scripts", "save", name + ".gd"), encoding="utf-8") as fh:
            versions.append(int(re.search(r"^const VERSION := (\d+)$", fh.read(), re.MULTILINE)[1]))
    hashes = tree_hashes(source)
    total = size_of(source)
    if not hashes or total > LIMIT:
        sys.exit("generated input must contain readable production bytes within 20 MB")
    expected = {"seed": str(seed), "day": day, "realm": realm, "position": position, "versions": versions}
    codec = os.path.join(REPO, "tools", "earned_saves", "save_document.mjs")
    observed = json.loads(subprocess.check_output([options.get("node", "node"), "--input-type=module", "-e",
                                                  GENERATED_VALIDATOR, codec, source, json.dumps(expected)], text=True))
    if tree_hashes(source) != hashes:
        sys.exit("generated source changed during validation")
    sha = subprocess.check_output(["git", "-C", REPO, "rev-parse", "HEAD"], text=True).strip()
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        sys.exit("generated template requires an exact source commit")
    os.makedirs(destination)
    shutil.copytree(source, os.path.join(destination, "save"))
    if tree_hashes(source) != hashes or tree_hashes(os.path.join(destination, "save")) != hashes:
        sys.exit("generated template copy changed production bytes")
    provenance = {"kind": "generated_fixture_template", "owner_policy": "#5726060136810",
                  "template_source": sha, "template_boundary": options["predecessor"],
                  "prior_earned_play_claim_for_generated_input": False, "continuous_fresh_save": False,
                  "generator": command, "files_sha256": hashes, "save_bytes": total, "observed": observed,
                  "validation_scope": "Production codec and declared split carriers; runner production Load/export still required"}
    with open(os.path.join(destination, "PROVENANCE.json"), "x", encoding="utf-8") as fh:
        json.dump(provenance, fh, indent=1, sort_keys=True, allow_nan=False)
    print("generated fixture template %s: %d bytes; no earned predecessor or PASS claim" % (destination, total))


def size_of(path):
    return sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(path) for f in fs)


def beats(receipt):
    out = []
    for block in receipt.get("helper_receipts", []):
        out.extend(block.get("receipts", []) if isinstance(block, dict) else [])
    return out


def joined(root, prefix, legs):
    segments, disclosures = [], []
    for name in SEGMENTS[:-1]:
        with open(os.path.join(prefix, name + ".json")) as fh:
            receipt = json.load(fh)
        if not receipt.get("passed"):
            sys.exit("prefix segment %s did not pass" % name)
        segments.append(receipt)
    specs = [leg.split("@") for leg in legs.split(",")]
    for index, spec in enumerate(specs):
        with open(os.path.join(root, spec[0], "receipt.json")) as fh:
            receipt = json.load(fh)
        receipt["segment"] = "%s (%s)" % (receipt.get("segment"), spec[0])
        if len(spec) == 2:
            mark = [b for b in beats(receipt) if b.get("beat") == "checkpoint_" + spec[1]]
            if not mark or not mark[0].get("saved"):
                sys.exit("leg %s has no saved checkpoint_%s receipt" % (spec[0], spec[1]))
            disclosures.append("Leg %s was cut at its earned checkpoint %s (saved at %s); its later failure %s is "
                               "discarded and leg %s started from that checkpoint save." % (
                                   spec[0], spec[1], mark[0].get("player"), receipt.get("failures"), specs[index + 1][0]))
        elif index != len(specs) - 1 or not receipt.get("passed"):
            sys.exit("final leg %s did not pass" % spec[0])
        segments.append(receipt)
    disclosures.append("Kell-to-Rift helper routing is disclosed in BLOCKERS.md B13-B16 with receipts: the ordinary "
                       "Kell walk (B13), the stick-walked quarry_northbound_detour (B14), storm_road_via_sigil_gate "
                       "(B15), and cloudreach_arrived readiness evaluated on the deadline frame as production does (B16). "
                       "None writes a flag, item, party member or position.")
    return segments, os.path.join(root, specs[-1][0], "save"), disclosures


def main():
    root, seed, command = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    options = dict(arg[2:].split("=", 1) for arg in sys.argv[4:] if arg.startswith("--") and "=" in arg)
    if options.get("mode") == "generated_fixture":
        return generated(root, seed, command, options)
    if "mode" in options and options["mode"] != "earned":
        sys.exit("input mode must be earned or generated_fixture")
    if "legs" in options:
        segments, source, join_notes = joined(root, options["prefix"], options["legs"])
        return write(root, seed, command, segments, source, join_notes)
    segments = []
    for name in SEGMENTS:
        with open(os.path.join(root, name, "receipt.json")) as fh:
            receipt = json.load(fh)
        if not receipt.get("passed"):
            sys.exit("segment %s did not pass" % name)
        segments.append(receipt)
    write(root, seed, command, segments, os.path.join(root, "warden", "save"), [])


def write(root, seed, command, segments, source, join_notes):
    total = size_of(source)
    if total > LIMIT:
        sys.exit("final save is %d bytes (> 20 MB); not copying" % total)
    if os.path.isdir(os.path.join(DEST, "save")):
        shutil.rmtree(os.path.join(DEST, "save"))
    os.makedirs(DEST, exist_ok=True)
    shutil.copytree(source, os.path.join(DEST, "save"))
    sha = subprocess.check_output(["git", "-C", REPO, "rev-parse", "HEAD"], text=True).strip()
    final = segments[-1]
    provenance = {
        "fixture": "earned C1 handoff: trainer at the Cloudreach arrival after the physical Rift crossing",
        "world_seed": seed,
        "source_sha": sha,
        "runner_command": command,
        "injections": 0,
        "total_wall_seconds": round(sum(s["wall_seconds"] for s in segments), 1),
        "save_bytes": total,
        "legendary_species": "veridian",
        "final_location": final["location"],
        "final_party": final["party_after"],
        "disclosures": [
            "TB_WORLD_SEED pins the world roll for every segment; the fresh save stores the same seed.",
            "Segments are separate processes joined by Game.save_game(1) and the production title Load list.",
            "Veridian accepted through the full-belt farewell ceremony: the lowest-level earned member was let go "
            "(tools/earned_saves/warden_accept.gd). The inherited helper receipt 'meadows_ending_settled' keeps its "
            "hard-coded 'release_pending_legendary_keep_earned_five' label; 'veridian_accepted' is the actual choice.",
            "Every helper workaround is disclosed in tools/earned_saves/BLOCKERS.md (B1-B12) with per-beat receipts: "
            "bench/road/pre-Warden Satchel care (between_fight_care, pre_warden_bench_care), delayed-dialogue prompt "
            "presses, the Warden reward read-out, the F05 spatial accept prompt, and the acknowledgement walk on the "
            "forward roads reversed (warren_undertrail and the B3 mound detour). None writes a flag, item, party member or position.",
        ] + join_notes + [d for s in segments for d in s.get("disclosures", [])],
        "segments": [{k: s[k] for k in (
            "segment", "passed", "wall_seconds", "game_day", "game_clock_seconds", "location",
            "flags_gained", "flags_total", "party_before", "party_after", "key_items", "free_build",
            "helper_receipts")} for s in segments],
    }
    with open(os.path.join(DEST, "PROVENANCE.json"), "w") as fh:
        json.dump(provenance, fh, indent=1, sort_keys=True)
    print("fixture %s: %d bytes save, %.0f s wall" % (DEST, total, provenance["total_wall_seconds"]))


if __name__ == "__main__":
    main()
