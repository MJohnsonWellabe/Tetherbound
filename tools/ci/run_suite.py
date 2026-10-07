#!/usr/bin/env python3
"""Run a verify-suite job: single-process smoke/unit GROUPS in parallel LANES.

    run_suite.py --check                       every group planned once
    run_suite.py --list --tier T --jobs J      `suites=[..]`: the suites with work
                                               (the `changes` job; matrix input)
    run_suite.py --suite N --tier T --jobs J [--nightly]
                                               run suite N's lanes side by side

CI-SPEED (owner, 2026-10-07). The full-ci PR gate is bound by the account's
~20 concurrent runners, not by any one test, and every job pays ~2 minutes of
checkout and Godot setup. The single-process verification jobs (unit-test
shards, verify-*-shard, catching, harvest, gate evidence, handoffs) are
therefore GROUPS here: tools/ci/suites/<job>[--<matrix value>].steps, each the
former job's steps copied verbatim (ci.yml `run:` bodies, step `env:`), run in
order in one lane exactly as the job ran them. A suite job runs LANES lanes at
once on its 4-vCPU runner; groups are planned longest-processing-time first
onto SUITE_COUNT * LANES lanes from each group's measured `### seconds:`.

Isolation per lane (what a separate runner used to give each job):
  * its own XDG_DATA_HOME (Godot's user://), RUNNER_TEMP and GITHUB_ENV file;
  * its own network namespace (`sudo unshare --net`, loopback up), so two
    lanes never contend for the session's udp/27015, the LAN beacon port or
    any test port. Without passwordless sudo (a local run) lanes share the
    host network and a warning says so.

Step semantics: every step of a group runs even after an earlier one failed
(as `if: !cancelled()` did; steps that had no `if` now also run, which can
only add failures), with `bash --noprofile --norc -eo pipefail` like a ci.yml
`run:` step, the step's own `timeout-minutes` or else the group's job limit.
`### nightly` steps run only on the scheduled/dispatched tier (--nightly).
A KEY=VALUE a step appends to $GITHUB_ENV reaches the group's later steps.
Leftover processes of a group are swept when the group ends.

Tiers and affected-only selection (tools/ci/select_jobs.py) work per former
job: on the full tier a group runs when `jobs` holds |ALL| or its `### job:`
name; on the fast tier only `### tier: fast` groups run (the unit-test shards,
as before). select_jobs.py reads these files as part of that job's text.
"""
import argparse
import glob
import os
import queue
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SUITES_DIR = os.path.join(ROOT, "tools", "ci", "suites")

# Must equal the `suite:` matrix in ci.yml (tests/test_ci_suites.py).
SUITE_COUNT = 4
LANES = 2
# A lane's measured (solo) seconds; two single-process lanes ran at ~1.0-1.1x
# their solo time (PR #573 runs 37636924943, 37642447200).
LANE_BUDGET_SECONDS = 1080
DEFAULT_STEP_TIMEOUT_MINUTES = 30


class PlanError(Exception):
    pass


class Group:
    def __init__(self, path):
        self.path = path
        self.file = os.path.basename(path)
        self.job = None
        self.group = None
        self.seconds = None
        self.job_timeout = DEFAULT_STEP_TIMEOUT_MINUTES
        self.tier = "full"
        self.steps = []
        step = None
        with open(path, encoding="utf-8") as f:
            for raw in f.read().splitlines():
                m = re.match(r"^### (job-timeout-minutes|timeout-minutes|seconds|group|job|tier|step|env|nightly)(?:: ?| |$)(.*)$", raw)
                if m:
                    key, val = m.group(1), m.group(2)
                    if key == "step":
                        step = {"name": val, "env": {}, "nightly": False, "timeout": None, "body": []}
                        self.steps.append(step)
                    elif step is None:
                        if key == "job":
                            self.job = val
                        elif key == "group":
                            self.group = val
                        elif key == "seconds":
                            self.seconds = int(val)
                        elif key == "job-timeout-minutes":
                            self.job_timeout = int(val)
                        elif key == "tier":
                            if val not in ("fast", "full"):
                                raise PlanError("%s: tier must be fast or full" % self.file)
                            self.tier = val
                        else:
                            raise PlanError("%s: `### %s` before the first step" % (self.file, key))
                    elif key == "nightly":
                        step["nightly"] = True
                    elif key == "timeout-minutes":
                        step["timeout"] = int(val)
                    elif key == "env":
                        k, _, v = val.partition(": ")
                        step["env"][k.strip()] = v
                    else:
                        raise PlanError("%s: `### %s` inside step %r" % (self.file, key, step["name"]))
                elif step is not None:
                    step["body"].append(raw)
        if not self.job or self.seconds is None or not self.steps:
            raise PlanError("%s needs `### job:`, `### seconds:` and at least one `### step:`" % self.file)

    @property
    def label(self):
        return self.job if self.group is None else "%s (%s)" % (self.job, self.group)


def load(directory=SUITES_DIR):
    groups = [Group(p) for p in sorted(glob.glob(os.path.join(directory, "*.steps")))]
    labels = [g.label for g in groups]
    if len(set(labels)) != len(labels):
        raise PlanError("duplicate suite groups: %s" % sorted(l for l in labels if labels.count(l) > 1))
    return groups


def plan(groups, suite_count=SUITE_COUNT, lanes=LANES):
    """[[Group]] per lane; suite N owns lanes (N-1)*lanes .. N*lanes-1."""
    bins = [[] for _ in range(suite_count * lanes)]
    loads = [0] * len(bins)
    for g in sorted(groups, key=lambda g: (-g.seconds, g.label)):
        i = min(range(len(bins)), key=lambda i: (loads[i], i))
        bins[i].append(g)
        loads[i] += g.seconds
    seen = [g.label for lane in bins for g in lane]
    if sorted(seen) != sorted(g.label for g in groups) or len(seen) != len(set(seen)):
        raise PlanError("suite plan is not an exact one-time cover")
    return bins, loads


def suite_lanes(bins, suite, lanes=LANES):
    return bins[(suite - 1) * lanes:suite * lanes]


def selected(group, jobs, tier):
    """fast: the fast-tier groups (they also run on full); full: the groups the
    affected-only selection names; anything else: nothing."""
    if tier == "fast":
        return group.tier == "fast"
    if tier == "full":
        return "|ALL|" in jobs or ("|%s|" % group.job) in jobs
    return False


def suites_with_work(groups, jobs, tier):
    bins, _ = plan(groups)
    return [n for n in range(1, SUITE_COUNT + 1)
            if any(selected(g, jobs, tier) for lane in suite_lanes(bins, n) for g in lane)]


# --- lane execution (runs inside the lane's own namespace) -------------------

def emit(kind, *fields):
    sys.stdout.write("\t".join([kind] + [str(f) for f in fields]) + "\n")
    sys.stdout.flush()


def sweep(pgid):
    try:
        os.killpg(pgid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
        pass


def run_lane(files, lane_dir, nightly):
    """Run each group file's steps in order; emit STEP events for the parent."""
    status = 0
    xdg = os.path.join(lane_dir, "xdg")
    tmp = os.path.join(lane_dir, "runner-temp")
    logs = os.path.join(lane_dir, "logs")
    for d in (xdg, tmp, logs):
        os.makedirs(d, exist_ok=True)
    for path in files:
        g = Group(path)
        extra_env = {}
        pgids = []
        for n, step in enumerate(g.steps, start=1):
            if step["nightly"] and not nightly:
                emit("SKIP", g.label, step["name"], "nightly tier only")
                continue
            script = os.path.join(lane_dir, "step.sh")
            with open(script, "w", encoding="utf-8") as f:
                f.write("\n".join(step["body"]) + "\n")
            github_env = os.path.join(lane_dir, "github_env")
            open(github_env, "w").close()
            env = dict(os.environ)
            env.update(XDG_DATA_HOME=xdg, RUNNER_TEMP=tmp, GITHUB_ENV=github_env)
            env.update(extra_env)
            env.update(step["env"])
            log = os.path.join(logs, "%s-%02d.log" % (g.file[:-len(".steps")], n))
            timeout = 60 * (step["timeout"] or g.job_timeout)
            emit("START", g.label, step["name"])
            started = time.monotonic()
            with open(log, "wb") as out:
                proc = subprocess.Popen(["bash", "--noprofile", "--norc", "-eo", "pipefail", script],
                                        cwd=ROOT, env=env, stdout=out, stderr=subprocess.STDOUT,
                                        stdin=subprocess.DEVNULL, start_new_session=True)
                pgids.append(proc.pid)
                try:
                    code = proc.wait(timeout=timeout)
                except subprocess.TimeoutExpired:
                    sweep(proc.pid)
                    proc.wait()
                    code = 124
                    out.write(("\nRUN-SUITE: step exceeded its %d-minute limit\n" % (timeout // 60)).encode())
            with open(github_env, encoding="utf-8", errors="replace") as f:
                for line in f.read().splitlines():
                    k, sep, v = line.partition("=")
                    if sep and k:
                        extra_env[k] = v
            if code != 0:
                status = 1
            emit("STEP", g.label, step["name"], code, int(time.monotonic() - started), log)
        for pgid in pgids:
            sweep(pgid)
    return status


# --- parent: start lanes, relay their logs ---------------------------------

def netns_prefix():
    """argv prefix that runs a command in a fresh network namespace as the
    current user, or [] when that is not available here."""
    if os.environ.get("RUN_SUITE_NETNS", "1") != "1":
        return []
    if not (shutil.which("sudo") and shutil.which("unshare") and shutil.which("setpriv") and shutil.which("ip")):
        return []
    if subprocess.run(["sudo", "-n", "true"], capture_output=True).returncode != 0:
        return []
    probe = subprocess.run(["sudo", "-n", "unshare", "--net", "--", "ip", "link", "set", "lo", "up"],
                           capture_output=True)
    if probe.returncode != 0:
        return []
    uid, gid = os.getuid(), os.getgid()
    return ["sudo", "-n", "--preserve-env", "unshare", "--net", "--", "sh", "-c",
            'ip link set lo up && p="$0" && h="$1" && shift && '
            'exec setpriv --reuid=%d --regid=%d --init-groups -- env PATH="$p" HOME="$h" "$@"'
            % (uid, gid), os.environ.get("PATH", ""), os.environ.get("HOME", "")]


def run_suite(suite, jobs, tier, nightly, groups):
    bins, _ = plan(groups)
    mine = [[g for g in lane if selected(g, jobs, tier)] for lane in suite_lanes(bins, suite)]
    for i, lane in enumerate(mine, start=1):
        print("suite %d lane %d: %s" % (suite, i, ", ".join(g.label for g in lane) or "(nothing selected)"))
    work = os.environ.get("RUN_SUITE_DIR") or tempfile.mkdtemp(prefix="run-suite-")
    prefix = netns_prefix()
    if prefix:
        print("lanes run in their own network namespaces")
    else:
        print("::warning::lanes share the host network (no passwordless sudo/unshare here)")
    lock = threading.Lock()
    results = []
    procs = []

    def relay(lane_no, proc):
        for raw in proc.stdout:
            parts = raw.rstrip("\n").split("\t")
            kind = parts[0]
            with lock:
                if kind == "START":
                    print("lane %d: %s / %s started" % (lane_no, parts[1], parts[2]), flush=True)
                elif kind == "SKIP":
                    print("lane %d: %s / %s skipped (%s)" % (lane_no, parts[1], parts[2], parts[3]), flush=True)
                    results.append((lane_no, parts[1], parts[2], "skipped", 0))
                elif kind == "STEP":
                    label, name, code, secs, log = parts[1], parts[2], int(parts[3]), int(parts[4]), parts[5]
                    print("::group::%s / %s (lane %d, exit %d, %d s)" % (label, name, lane_no, code, secs))
                    with open(log, encoding="utf-8", errors="replace") as f:
                        sys.stdout.write(f.read())
                    print("::endgroup::")
                    if code != 0:
                        print("::error::%s / %s failed (exit %d)" % (label, name, code))
                    sys.stdout.flush()
                    results.append((lane_no, label, name, code, secs))
                else:
                    print("lane %d: %s" % (lane_no, raw.rstrip("\n")), flush=True)

    threads = []
    for i, lane in enumerate(mine, start=1):
        if not lane:
            continue
        lane_dir = os.path.join(work, "lane%d" % i)
        os.makedirs(lane_dir, exist_ok=True)
        argv = prefix + [sys.executable, os.path.abspath(__file__), "--run-lane", lane_dir] + \
            (["--nightly"] if nightly else []) + [g.path for g in lane]
        proc = subprocess.Popen(argv, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, errors="replace")
        procs.append(proc)
        t = threading.Thread(target=relay, args=(i, proc), daemon=True)
        t.start()
        threads.append(t)

    def stop(signum, _frame):
        for p in procs:
            try:
                p.terminate()
            except ProcessLookupError:
                pass
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    status = 0
    for p, t in zip(procs, threads):
        if p.wait() != 0:
            status = 1
        t.join()
    print("lane\tgroup\tstep\texit\tseconds")
    for r in results:
        print("%s\t%s\t%s\t%s\t%s" % r)
    if any(r[3] not in (0, "skipped") for r in results):
        status = 1
    return status


def main(argv=None):
    ap = argparse.ArgumentParser()
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--suite", type=int)
    mode.add_argument("--run-lane", metavar="LANE_DIR")
    ap.add_argument("--jobs", default="|ALL|")
    ap.add_argument("--tier", choices=("fast", "full", "none"), default="full")
    ap.add_argument("--nightly", action="store_true")
    ap.add_argument("files", nargs="*")
    args = ap.parse_args(argv)
    if args.run_lane:
        return run_lane(args.files, args.run_lane, args.nightly)
    try:
        groups = load()
        bins, loads = plan(groups)
    except PlanError as e:
        print("::error::%s" % e)
        return 1
    for i, (lane, load_s) in enumerate(zip(bins, loads)):
        if load_s > LANE_BUDGET_SECONDS:
            print("::warning::suite lane %d is planned at %d s, over the %d s budget: raise SUITE_COUNT "
                  "in tools/ci/run_suite.py" % (i + 1, load_s, LANE_BUDGET_SECONDS))
        print("plan suite %d/%d lane %d: %d s: %s" % (i // LANES + 1, SUITE_COUNT, i % LANES + 1, load_s,
                                                     ", ".join(g.label for g in lane)))
    if args.check:
        return 0
    if args.list:
        work = suites_with_work(groups, args.jobs, args.tier)
        line = "suites=[%s]" % ", ".join(str(n) for n in work)
        print(line)
        out = os.environ.get("GITHUB_OUTPUT")
        if out:
            with open(out, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        return 0
    if not 1 <= args.suite <= SUITE_COUNT:
        print("::error::suite %d is outside 1..%d" % (args.suite, SUITE_COUNT))
        return 1
    return run_suite(args.suite, args.jobs, args.tier, args.nightly, groups)


if __name__ == "__main__":
    sys.exit(main())
