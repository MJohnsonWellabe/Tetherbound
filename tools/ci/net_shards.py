#!/usr/bin/env python3
"""Discover the `# peers: 2` net smokes and plan them onto the
verify-multiplayer-shard matrix (.github/workflows/ci.yml).

    net_shards.py --check              roster, floor and plan (the `changes` job)
    net_shards.py --shard N            one shard: the same checks, then this
                                       shard's files and lanes to $GITHUB_OUTPUT

Every shard runs the discovery itself, so the shards need only `changes` and
queue with the first wave of jobs.
Discovery reads only the checkout, so every shard computes the same plan.

The plan is longest-processing-time first over MEASURED_SECONDS, onto
SHARD_COUNT * LANES_PER_SHARD lanes; each shard job runs its lanes at the same
time (tools/ci/run_net_lanes.sh). It fails if any discovered smoke is
unassigned or assigned twice. A lane over SHARD_SMOKE_BUDGET_SECONDS is a
warning: it costs wall time, not coverage.
"""
import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# Must equal the `shard:` matrix in ci.yml (tests/test_ci_net_shards.py).
SHARD_COUNT = 8
# Lanes per shard job. Two lanes at once (tools/ci/run_net_lanes.sh) ran at
# 1.0-1.6x solo time and broke timing-sensitive smokes under the CPU load
# (PR #573 runs 37636924943, 37642447200: f20_ending's hello budget,
# f22_forced_break, water_return), so each shard runs ONE lane again.
LANES_PER_SHARD = 1
# Measured smoke time per shard: ~18.5 min, so with ~2 min of checkout and
# Godot setup a shard job stays near 20 minutes on the slowest measurements.
SHARD_SMOKE_BUDGET_SECONDS = 1110

# Seconds per smoke, measured SOLO: the SLOWEST of the three green full runs
# 37615388024, 37575215387 and 37563845433 (2026-10-07), from one smoke's
# `##[group]smoke_net_<name>.gd attempt` log line to the next (the last smoke
# of a shard ends at the upload step).
# Refresh it from newer full runs when a lane drifts past the budget (the
# lane runner prints each smoke's seconds; they include the ~1.1x of two
# lanes sharing a runner, so divide by ~1.3 when refreshing from those).
MEASURED_SECONDS = {
    "behind_character_joins_ahead_world": 124,
    "boss_rewards_each_participant": 171,
    "catch_race": 132,
    "client_trainer_rewards": 183,
    "cloudreach_riding": 360,
    "crossing_hall_agreement": 270,
    "deploy_two_creatures": 107,
    "f18_fixture_teaching": 182,
    "f44_alpha_respawn": 480,
    "f20_ending": 620,
    "f20_home_diagnostic": 136,
    "f22_forced_break": 169,
    "f32_node_contention": 136,
    "farm_race": 112,
    "fly": 127,
    "fog_is_personal": 118,
    "forward_camp": 152,
    "foundations": 148,
    "gate_opens_for_both": 108,
    "gather_departure": 240,
    "harness_max_hp": 122,
    "hearts": 114,
    "home_creature_bed": 222,
    "homestead_station_craft": 289,
    "host_exit_saves": 124,
    "host_join_leave": 100,
    "identity_admission": 100,
    "join_by_address": 102,
    "join_version_mismatch": 101,
    "late_join_modified_world": 103,
    "meadows_identity_fresh_join": 171,
    "menu_does_not_freeze_peer": 226,
    "movement_two_peers": 112,
    "peer_death": 100,
    "pickup_race": 115,
    "realm_owner_disconnect_mid_fight": 206,
    "reconnect_keeps_character": 158,
    "revive": 129,
    "riding": 147,
    "session_host_first_realm": 209,
    "shared_boss": 181,
    "shared_building": 113,
    "shared_wild_fight": 159,
    "sleep_vote": 113,
    "split_realms": 268,
    "storage_concurrency": 112,
    "stormwood_charged_ground": 181,
    "stormwood_finalized_death": 178,
    "stormwood_glass_for_bryn": 152,
    "stormwood_hosted_trainers": 165,
    "stormwood_livewire": 137,
    "stormwood_realms": 181,
    "trade": 117,
    "two_peers_boot": 112,
    "veridian_choices": 256,
    "veridian_full_refusal": 129,
    "veridian_mixed": 124,
    "veridian_relic_key": 203,
    "veridian_same_five": 130,
    "water_alpha": 131,
    "water_deep_watch_chart": 84,
    "water_local_chains": 96,
    "water_mounted_swimming": 85,
    "water_return": 155,
    "water_swim_stone_late_join": 76,
    "water_swimming": 97,
}
# Smokes that must run alone in their LANE (none today). A shard used to be
# reserved for each of split_realms and f20_ending so a hang could not take
# other smokes down at the job limit; tools/ci/run_net_lanes.sh now ends any
# single smoke at NET_SMOKE_TIMEOUT_SECONDS, which bounds that on its own.
ISOLATED = ()
# Smokes that run ALONE on their shard's runner, after both lanes finish:
# timing-sensitive two-process checks that a second smoke's CPU load can
# break. f22_forced_break (host-committed charge timing against a tell) failed
# in a lane on run 37636924943 and passed alone on every earlier full run.
# Each counts its full time on both lanes of its shard.
EXCLUSIVE = ()

# CI-SPEED (owner, 2026-10-07): run on the 8-hourly scheduled tier and on
# workflow_dispatch only (`--nightly`), not on a full-ci pull request. Each is
# a duplicate path or regional content; the PR gate keeps every authority,
# save, rejoin, reward, catch and shared-boss smoke.
NIGHTLY_ONLY = {
    "two_peers_boot": "every net smoke boots two peers, joins and checks the registry",
    "host_join_leave": "leave/rejoin stays gated by reconnect_keeps_character and host_exit_saves",
    "cloudreach_riding": "6-min regional ride; riding stays gated by smoke_net_riding and smoke_net_fly",
    "f20_home_diagnostic": "diagnostic companion of smoke_net_f20_ending, which stays gated",
    "water_swimming": "Tidewake swim sync; traversal sync stays gated by riding/fly/movement_two_peers",
    "water_mounted_swimming": "Tidewake mounted swim sync; same coverage as water_swimming",
    "water_deep_watch_chart": "Tidewake side-chain replication; chain/flag replication stays gated by water_alpha",
    "water_local_chains": "Tidewake side-chain replication; same mechanism as water_deep_watch_chart",
    "stormwood_livewire": "Stormwood regional hazard; host authority stays gated by stormwood_realms/hosted_trainers",
    "stormwood_glass_for_bryn": "Stormwood regional quest; quest replication stays gated by other chain smokes",
    "stormwood_charged_ground": "Stormwood regional hazard; same coverage as stormwood_livewire",
}
# An unmeasured smoke is planned as the slowest measured one until measured.
# Isolated smokes run alone, so their (possibly lower-bound) times are not a
# guide for an ordinary smoke.
UNMEASURED_SECONDS = max(v for k, v in MEASURED_SECONDS.items() if k not in ISOLATED)

# The floor is the TRUE count of files declaring the header, regenerated from
# the files on disk at every landing, never incremented from a lane's guess:
#
#   for f in tests/smoke_net_*.gd; do
#     head -5 "$f" | grep -qE '^#[[:space:]]*peers:[[:space:]]*2$' && echo "$f"
#   done | wc -l
DISCOVERY_FLOOR = 63
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
    "stormwood_charged_ground", "harness_max_hp", "forward_camp",
    "f44_alpha_respawn",
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


def gate_files(files):
    """The smokes a full-ci pull request runs: all but NIGHTLY_ONLY."""
    return [p for p in files if smoke_name(p) not in NIGHTLY_ONLY]


def solo_plan(files, shard_count=SHARD_COUNT, exclusive=EXCLUSIVE):
    """{shard: [files]}: each EXCLUSIVE smoke on its own shard, from the last."""
    alone = sorted(p for p in files if smoke_name(p) in exclusive)
    if len(alone) != len(exclusive):
        raise PlanError("exclusive net smokes not discovered: %s"
                        % sorted(set(exclusive) - {smoke_name(p) for p in alone}))
    out = {}
    for i, path in enumerate(alone):
        out.setdefault(shard_count - (i % shard_count), []).append(path)
    return out


def plan(files, shard_count=SHARD_COUNT, isolated=ISOLATED, lanes_per_shard=LANES_PER_SHARD,
         exclusive=EXCLUSIVE):
    """[(files, seconds)] per LANE (shard N owns lanes (N-1)*L .. N*L-1): each
    ISOLATED smoke alone on the last lanes, the rest longest first onto the
    lightest ordinary lane. EXCLUSIVE smokes are not on a lane (solo_plan);
    their time is pre-loaded onto every lane of their shard."""
    lane_count = shard_count * lanes_per_shard
    solo = solo_plan(files, shard_count, exclusive)
    solo_files = [p for group in solo.values() for p in group]
    alone = [p for p in files if smoke_name(p) in isolated]
    if len(alone) != len(isolated):
        raise PlanError("isolated net smokes not discovered: %s"
                        % sorted(set(isolated) - {smoke_name(p) for p in alone}))
    ordinary = lane_count - len(alone)
    if ordinary < 1:
        raise PlanError("no ordinary lane left beside %d isolated" % len(alone))
    bins = [[] for _ in range(ordinary)] + [[p] for p in sorted(alone)]
    loads = [0] * ordinary + [weight(p) for p in sorted(alone)]
    for shard, group in solo.items():
        for lane in range((shard - 1) * lanes_per_shard, shard * lanes_per_shard):
            if lane < ordinary:
                loads[lane] += sum(weight(p) for p in group)
    for path in sorted((p for p in files if p not in alone and p not in solo_files),
                       key=lambda p: (-weight(p), p)):
        i = min(range(ordinary), key=lambda i: (loads[i], i))
        bins[i].append(path)
        loads[i] += weight(path)
    check_cover(files, bins + [group for group in solo.values()])
    for group in bins[ordinary:]:
        if len(group) != 1:
            raise PlanError("%s must be the only smoke on its lane" % group)
    return list(zip(bins, loads))


def shard_lanes(lanes, shard, lanes_per_shard=LANES_PER_SHARD):
    """The lanes shard `shard` (1-based) runs."""
    return lanes[(shard - 1) * lanes_per_shard:shard * lanes_per_shard]


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
    ap.add_argument("--nightly", action="store_true",
                    help="the scheduled/dispatched tier: also plan the NIGHTLY_ONLY smokes")
    args = ap.parse_args(argv)
    try:
        files, held = discover()
        for rel, cfg, key in held:
            print("::notice::held off the gate until %s %s is on: %s" % (cfg, key, rel))
        print("held (%d) smokes whose required production flag is off" % len(held))
        print("found (%d): %s" % (len(files), " ".join(files)))
        check_roster(files)
        missing = sorted(set(NIGHTLY_ONLY) - {smoke_name(p) for p in files})
        if missing:
            raise PlanError("NIGHTLY_ONLY names smokes that are not discovered: %s" % missing)
        if not args.nightly:
            files = gate_files(files)
            print("nightly-only (%d, not on a pull request): %s" % (len(NIGHTLY_ONLY), " ".join(sorted(NIGHTLY_ONLY))))
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
        if load > SHARD_SMOKE_BUDGET_SECONDS:
            print("::warning::net lane %d is planned at %d s, over the %d s budget: refresh MEASURED_SECONDS "
                  "or raise SHARD_COUNT in tools/ci/net_shards.py" % (i, load, SHARD_SMOKE_BUDGET_SECONDS))
        print("plan shard %d/%d lane %d: %d s: %s" % ((i - 1) // LANES_PER_SHARD + 1, SHARD_COUNT,
                                                     (i - 1) % LANES_PER_SHARD + 1, load, " ".join(group)))
    for shard, group in sorted(solo_plan(files).items()):
        print("plan shard %d/%d alone after its lanes: %s" % (shard, SHARD_COUNT, " ".join(group)))
    if args.shard is not None:
        mine = shard_lanes(shards, args.shard)
        out = os.environ.get("GITHUB_OUTPUT")
        if out:
            with open(out, "a", encoding="utf-8") as f:
                f.write("files=%s\n" % " ".join([p for group, _ in mine for p in group]
                                                 + solo_plan(files).get(args.shard, [])))
                # One line per lane, `lanes=` joins them with `;` for the runner.
                f.write("lanes=%s\n" % ";".join(" ".join(group) for group, _ in mine))
                # Run alone after the lanes (EXCLUSIVE).
                f.write("solo=%s\n" % " ".join(solo_plan(files).get(args.shard, [])))
                f.write("scheduling_weight_seconds=%d\n" % max((load for _, load in mine), default=0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
