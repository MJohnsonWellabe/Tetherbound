#!/usr/bin/env python3
"""Discover the `# peers: 2` net smokes and plan them onto the
verify-multiplayer-shard matrix (.github/workflows/ci.yml).

    net_shards.py --check              discover-net-smokes: roster, floor, plan
    net_shards.py --shard N            one shard job: the same checks, then its
                                       two lanes' files to $GITHUB_OUTPUT
                                       (files_a, files_b)

Every shard runs the discovery itself, so the shards need only `changes` and
queue with the first wave of jobs instead of behind discover-net-smokes.
Discovery reads only the checkout, so every shard computes the same plan.

The plan is longest-processing-time first over MEASURED_SECONDS. It fails if
any discovered smoke is unassigned or assigned twice. A bin over
BIN_SMOKE_BUDGET_SECONDS is a warning: it costs wall time, not coverage.

Each job runs LANES plan bins side by side (tools/ci/run_net_lanes.sh): two
two-peer smokes on one 4-vCPU runner each took 1.10x as long as one alone.
"""
import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# Plan bins, run LANES at a time per job. SHARD_COUNT jobs must equal the
# `shard:` matrix in ci.yml (tests/test_ci_net_shards.py).
BIN_COUNT = 22
LANES = 2
SHARD_COUNT = BIN_COUNT // LANES
# Smoke time per bin: a 13-minute job is ~140 s of checkout, Godot setup and
# upload plus the slower lane at 1.10x (1.10 x 580 + 140 = 778 s).
BIN_SMOKE_BUDGET_SECONDS = 580

# Seconds per smoke: the SLOWEST of the three green full runs 37289058162,
# 37282220875 and 37270789359 (2026-10-05), from one smoke's
# `##[group]smoke_net_<name>.gd attempt` log line to the next (the last smoke
# of a shard ends at the upload step).
# Refresh it from newer full runs when a shard drifts past the budget.
MEASURED_SECONDS = {
    # Provisional (coordinator, 2026-10-05): smokes new in batch #542, planned at a
    # conservative 330 s until three green full runs give real durations.
    "f22_forced_break": 330,
    "f27_guest_wild_win": 330,
    "gather_departure": 330,
    "homestead_station_craft": 330,
    "behind_character_joins_ahead_world": 129,
    "boss_rewards_each_participant": 228,
    "catch_race": 158,
    "client_trainer_rewards": 249,
    "cloudreach_riding": 422,
    "crossing_hall_agreement": 351,
    "deploy_two_creatures": 131,
    "f32_node_contention": 165,
    "farm_race": 133,
    "fly": 159,
    "fog_is_personal": 137,
    "foundations": 186,
    "gate_opens_for_both": 131,
    "hearts": 137,
    "home_creature_bed": 265,
    "host_exit_saves": 149,
    "host_join_leave": 124,
    "identity_admission": 125,
    "join_by_address": 125,
    "join_version_mismatch": 131,
    "late_join_modified_world": 124,
    "meadows_identity_fresh_join": 196,
    "menu_does_not_freeze_peer": 256,
    "movement_two_peers": 133,
    "peer_death": 124,
    "pickup_race": 137,
    "realm_owner_disconnect_mid_fight": 275,
    "reconnect_keeps_character": 192,
    "revive": 156,
    "riding": 186,
    "session_host_first_realm": 267,
    "shared_boss": 291,
    "shared_building": 129,
    "shared_wild_fight": 202,
    "sleep_vote": 136,
    "split_realms": 306,
    "storage_concurrency": 135,
    "stormwood_finalized_death": 202,
    "stormwood_glass_for_bryn": 198,
    "stormwood_hosted_trainers": 178,
    "stormwood_livewire": 177,
    "stormwood_realms": 240,
    "trade": 137,
    "two_peers_boot": 125,
    "veridian_choices": 396,
    "veridian_full_refusal": 172,
    "veridian_mixed": 156,
    "veridian_relic_key": 282,
    "veridian_same_five": 293,
    "water_alpha": 152,
    "water_deep_watch_chart": 83,
    "water_local_chains": 95,
    "water_mounted_swimming": 82,
    "water_return": 95,
    "water_swim_stone_late_join": 74,
    "water_swimming": 95,
}
# Each alone on the LAST shard(s), so a hang cannot take a shard's other
# smokes down with it at the 30-minute job limit: split_realms once ran 24+
# minutes and was cancelled with the smokes queued behind it
# (ralph/reports/FOUR-BIOME-BUILD/ci-shard-balance/REPORT.md).
ISOLATED = ("split_realms",)
# An unmeasured smoke is planned as the slowest measured one until measured.
UNMEASURED_SECONDS = max(MEASURED_SECONDS.values())

# The floor is the TRUE count of files declaring the header, regenerated from
# the files on disk at every landing, never incremented from a lane's guess:
#
#   for f in tests/smoke_net_*.gd; do
#     head -5 "$f" | grep -qE '^#[[:space:]]*peers:[[:space:]]*2$' && echo "$f"
#   done | wc -l
DISCOVERY_FLOOR = 36
# Named registration on top of the count: a smoke that loses its `# peers: 2`
# header in a rebase must fail discovery, not silently drop out of CI. Each
# lane that ships a net smoke adds its file here.
ROSTER = (
    "behind_character_joins_ahead_world", "boss_rewards_each_participant", "catch_race",
    "deploy_two_creatures", "farm_race", "fly", "fog_is_personal", "gate_opens_for_both", "hearts",
    "host_exit_saves", "host_join_leave", "join_by_address", "late_join_modified_world",
    "menu_does_not_freeze_peer", "movement_two_peers", "peer_death", "pickup_race",
    "realm_owner_disconnect_mid_fight", "reconnect_keeps_character", "revive", "riding",
    "shared_boss", "shared_building", "shared_wild_fight", "sleep_vote", "split_realms",
    "storage_concurrency", "stormwood_hosted_trainers", "stormwood_livewire", "stormwood_realms",
    "trade", "two_peers_boot", "water_alpha", "water_mounted_swimming",
    "water_swim_stone_late_join", "water_swimming",
)

PEERS_RE = re.compile(r"^#\s*peers:\s*2\s*$")
FLAG_RE = re.compile(r"^#\s*requires-flag:\s*(\S+)\s+(\S+)\s*$")


class PlanError(Exception):
    pass


def smoke_name(path):
    return os.path.basename(path)[len("smoke_net_"):-len(".gd")]


def flag_on(root, cfg, key):
    with open(os.path.join(root, "data", "config", cfg), encoding="utf-8") as f:
        node = json.load(f)
    for part in key.split("."):
        node = node.get(part, {}) if isinstance(node, dict) else {}
    return node is True


def discover(root=ROOT):
    """(files, held): `# peers: 2` smokes in tests/, minus those whose
    `# requires-flag: <config file> <dotted.key>` production flag is off."""
    files, held = [], []
    for path in sorted(glob.glob(os.path.join(root, "tests", "smoke_net_*.gd"))):
        with open(path, encoding="utf-8") as f:
            head = [f.readline().rstrip("\n") for _ in range(8)]
        if not any(PEERS_RE.match(line) for line in head[:5]):
            continue
        rel = os.path.relpath(path, root).replace(os.sep, "/")
        need = next((FLAG_RE.match(line) for line in head if FLAG_RE.match(line)), None)
        if need and not flag_on(root, need.group(1), need.group(2)):
            held.append((rel, need.group(1), need.group(2)))
            continue
        files.append(rel)
    return files, held


def check_roster(files):
    if len(files) < DISCOVERY_FLOOR:
        raise PlanError("expected at least %d tests/smoke_net_*.gd files declaring '# peers: 2', found %d"
                        % (DISCOVERY_FLOOR, len(files)))
    names = {smoke_name(f) for f in files}
    missing = [n for n in ROSTER if n not in names]
    if missing:
        raise PlanError("not being discovered as 'peers: 2' net smokes: %s"
                        % " ".join("tests/smoke_net_%s.gd" % n for n in missing))


def weight(path):
    return MEASURED_SECONDS.get(smoke_name(path), UNMEASURED_SECONDS)


def plan(files, shard_count=BIN_COUNT, isolated=ISOLATED):
    """[(files, seconds)] per shard: each ISOLATED smoke alone on the last
    shards, the rest longest first onto the lightest ordinary shard."""
    alone = [p for p in files if smoke_name(p) in isolated]
    if len(alone) != len(isolated):
        raise PlanError("isolated net smokes not discovered: %s"
                        % sorted(set(isolated) - {smoke_name(p) for p in alone}))
    ordinary = shard_count - len(alone)
    if ordinary < 1:
        raise PlanError("no ordinary shard left beside %d isolated" % len(alone))
    bins = [[] for _ in range(ordinary)] + [[p] for p in sorted(alone)]
    loads = [0] * ordinary + [weight(p) for p in sorted(alone)]
    for path in sorted((p for p in files if p not in alone), key=lambda p: (-weight(p), p)):
        i = min(range(ordinary), key=lambda i: (loads[i], i))
        bins[i].append(path)
        loads[i] += weight(path)
    check_cover(files, bins)
    for group in bins[ordinary:]:
        if len(group) != 1:
            raise PlanError("%s must be the only smoke on its shard" % group)
    return list(zip(bins, loads))


def job_lanes(bins, job):
    """The LANES bins job `job` (1-based) runs side by side."""
    return bins[(job - 1) * LANES:job * LANES]


def check_cover(files, bins):
    """Every discovered smoke in exactly one shard, and nothing else."""
    seen = {}
    for i, group in enumerate(bins, start=1):
        for path in group:
            seen.setdefault(path, []).append(i)
    twice = {p: s for p, s in seen.items() if len(s) > 1}
    unassigned = sorted(set(files) - set(seen))
    stray = sorted(set(seen) - set(files))
    if twice or unassigned or stray:
        raise PlanError("net-shard plan is not an exact one-time cover: assigned twice %s, unassigned %s, "
                        "not discovered %s" % (twice, unassigned, stray))


def main(argv=None):
    ap = argparse.ArgumentParser()
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--shard", type=int)
    args = ap.parse_args(argv)
    try:
        files, held = discover()
        for rel, cfg, key in held:
            print("::notice::held off the gate until %s %s is on: %s" % (cfg, key, rel))
        print("held (%d) smokes whose required production flag is off" % len(held))
        print("found (%d): %s" % (len(files), " ".join(files)))
        check_roster(files)
        if args.shard is not None and not 1 <= args.shard <= SHARD_COUNT:
            raise PlanError("shard %d is outside 1..%d" % (args.shard, SHARD_COUNT))
        for path in files:
            if smoke_name(path) not in MEASURED_SECONDS:
                print("::warning::%s has no measurement; planned as %d s" % (path, UNMEASURED_SECONDS))
        shards = plan(files)
    except PlanError as e:
        print("::error::%s" % e)
        return 1
    for i, (group, load) in enumerate(shards, start=1):
        if load > BIN_SMOKE_BUDGET_SECONDS:
            print("::warning::net bin %d is planned at %d s, over the %d s budget: refresh MEASURED_SECONDS "
                  "or raise BIN_COUNT in tools/ci/net_shards.py" % (i, load, BIN_SMOKE_BUDGET_SECONDS))
        print("plan bin %d/%d (shard %d lane %s): %d s: %s"
              % (i, BIN_COUNT, (i - 1) // LANES + 1, "ab"[(i - 1) % LANES], load, " ".join(group)))
    if args.shard is not None:
        lanes = job_lanes(shards, args.shard)
        out = os.environ.get("GITHUB_OUTPUT")
        if out:
            with open(out, "a", encoding="utf-8") as f:
                for name, (group, load) in zip("ab", lanes):
                    f.write("files_%s=%s\n" % (name, " ".join(group)))
                f.write("scheduling_weight_seconds=%d\n" % max(load for _, load in lanes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
