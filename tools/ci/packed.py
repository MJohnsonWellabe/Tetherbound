#!/usr/bin/env python3
"""Run the packed solo suites (.github/ci/suites.yml) two lanes per runner.

    packed.py plan --runner N    selection + plan; writes units=<count> to
                                 $GITHUB_OUTPUT (0: this runner has nothing)
    packed.py run --runner N     run this runner's two lanes side by side
    packed.py check              plan every suite (all selected) and verify it

A suite is a former ci.yml job, moved verbatim; each value of its matrix is
one suite instance (`verify-regions-relay (meadows)`), selected by the job's
original `if:`. A solo smoke uses about a quarter of a 4-vCPU runner; two
side by side each took ~1.08x as long as one alone. So each verify-packed
job runs two lanes, and the ~2 min of checkout and Godot setup is paid once
per two lanes instead of once per suite.

Units. A step whose `if:` says `!cancelled()` or `always()` ran in its job
whatever the steps before it did, so it is a unit of its own. Any other step
depended on every step before it in its job, so it joins them into one
unit. A unit runs in one lane, in order.

Isolation. Every unit gets fresh XDG_DATA_HOME / XDG_CONFIG_HOME /
XDG_CACHE_HOME (so `user://` is its own, never another unit's), TMPDIR and
RUNNER_TEMP. GITHUB_ENV written by a step applies to the later steps of its
unit, as it did in its job. Every step runs in its own process group under
`bash --noprofile --norc -eo pipefail`, like a GitHub `run:` step.

Verdicts. Each step's log is printed in its own `::group::`; every failed
step is an `::error::` naming the suite instance, the step and the lane, and
a step skipped after a failed step of its unit is reported by name. The
job fails if any step failed. A table of suite verdicts goes to the step
summary.
"""
import argparse
import json
import os
import re
import signal
import subprocess
import sys
import tempfile
import threading
import time

import yaml

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
# PACKED_SUITES / PACKED_DURATIONS: other files, for tests and failure drills.
SUITES = os.environ.get("PACKED_SUITES") or os.path.join(ROOT, ".github", "ci", "suites.yml")
DURATIONS = os.environ.get("PACKED_DURATIONS") or os.path.join(ROOT, "tools", "ci", "packed_durations.json")

# Must equal the `runner:` matrix of verify-packed in ci.yml (tests/test_ci_packed.py).
RUNNERS = 8
LANES = 2
# Planned seconds per lane: a ~15 min job is ~2 min of setup plus the slower
# lane at ~1.08x. A single step longer than this is planned alone in a lane.
LANE_BUDGET_SECONDS = 720
# An unmeasured step is planned at this until measured.
UNMEASURED_SECONDS = 300
# A step without its own timeout-minutes gets this (a job had 20-40).
DEFAULT_STEP_TIMEOUT_MINUTES = 30
SETUP_USES = ("actions/checkout", "./.github/actions/setup-godot")


class PackError(Exception):
    pass


# --- expressions -----------------------------------------------------------
# Exactly the subset the suites use; anything else is an error, never a guess.

TOKEN = re.compile(r"\s*(?:(\$\{\{|\}\})|('(?:[^']|'')*')|(&&|\|\||==|!=|!|\(|\)|,)|([A-Za-z_][\w.-]*))")


def tokens(text):
    out, i = [], 0
    while i < len(text):
        m = TOKEN.match(text, i)
        if not m or m.end() == i:
            if text[i:].strip() == "":
                break
            raise PackError("cannot parse expression %r at %r" % (text, text[i:]))
        i = m.end()
        wrap, lit, op, name = m.groups()
        if wrap:
            continue
        out.append(("str", lit[1:-1].replace("''", "'")) if lit else ("op", op) if op else ("name", name))
    return out


def evaluate(text, ctx):
    """Evaluate a GitHub `if:` / `${{ }}` expression over `ctx` (dotted names)."""
    toks = tokens(str(text))
    pos = [0]

    def peek():
        return toks[pos[0]] if pos[0] < len(toks) else (None, None)

    def take(want=None):
        t = peek()
        if want is not None and t != want:
            raise PackError("expected %r in %r" % (want, text))
        pos[0] += 1
        return t

    def primary():
        kind, val = take()
        if kind == "str":
            return val
        if (kind, val) == ("op", "("):
            v = either()
            take(("op", ")"))
            return v
        if (kind, val) == ("op", "!"):
            return not truthy(primary())
        if kind == "name":
            if peek() == ("op", "("):
                take()
                args = []
                while peek() != ("op", ")"):
                    args.append(either())
                    if peek() == ("op", ","):
                        take()
                take(("op", ")"))
                return call(val, args)
            if val in ("true", "false"):
                return val == "true"
            if val not in ctx:
                raise PackError("unknown name %r in %r" % (val, text))
            return ctx[val]
        raise PackError("unexpected %r in %r" % (val, text))

    def call(fn, args):
        if fn in ("always", "success") and not args:
            return ctx.get("__" + fn, True)
        if fn == "cancelled" and not args:
            return ctx.get("__cancelled", False)
        if fn == "contains" and len(args) == 2:
            return str(args[1]).lower() in str(args[0]).lower()
        if fn == "startsWith" and len(args) == 2:
            return str(args[0]).lower().startswith(str(args[1]).lower())
        raise PackError("unsupported function %s/%d in %r" % (fn, len(args), text))

    def compare():
        v = primary()
        while peek() in (("op", "=="), ("op", "!=")):
            op = take()[1]
            w = primary()
            eq = str(v).lower() == str(w).lower()
            v = eq if op == "==" else not eq
        return v

    def both():
        v = compare()
        while peek() == ("op", "&&"):
            take()
            w = compare()
            v = truthy(v) and truthy(w)
        return v

    def either():
        v = both()
        while peek() == ("op", "||"):
            take()
            w = both()
            v = truthy(v) or truthy(w)
        return v

    v = either()
    if pos[0] != len(toks):
        raise PackError("trailing tokens in %r" % text)
    return v


def truthy(v):
    return v not in (False, None, "", 0)


def substitute(text, ctx):
    """Expand `${{ expr }}` inside a run body, env value or step name."""
    return re.sub(r"\$\{\{(.*?)\}\}", lambda m: str(evaluate(m.group(1), ctx)), str(text))


def independent(step):
    """A step that ran whatever the steps before it in its job did."""
    cond = str(step.get("if", ""))
    return "!cancelled()" in cond.replace(" ", "") or "always()" in cond.replace(" ", "")


# --- suites, units, plan ---------------------------------------------------

def load_suites(path=SUITES):
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)["suites"]


def selection_ctx(env=None):
    env = os.environ if env is None else env
    return {
        "needs.changes.outputs.code": env.get("CI_CODE", "false"),
        "needs.changes.outputs.full": env.get("CI_FULL", "false"),
        "needs.changes.outputs.net": env.get("CI_NET", "false"),
        "needs.changes.outputs.jobs": env.get("CI_JOBS", ""),
        "github.event_name": env.get("CI_EVENT", ""),
    }


def instances(suites, sel):
    """[(instance name, job, matrix ctx, selected)] in file order."""
    out = []
    for job, spec in suites.items():
        matrix = (spec.get("strategy") or {}).get("matrix") or {}
        if len(matrix) > 1:
            raise PackError("%s: only a one-key matrix is supported" % job)
        combos = [{}] if not matrix else [{k: v} for k, vals in matrix.items() for v in vals]
        for combo in combos:
            ctx = dict(sel)
            ctx.update({"matrix." + k: v for k, v in combo.items()})
            name = job if not combo else "%s (%s)" % (job, ", ".join(str(v) for v in combo.values()))
            selected = truthy(evaluate(spec.get("if", "true"), ctx)) if "if" in spec else True
            out.append((name, job, ctx, selected))
    return out


def units_of(suites, sel):
    """[{id, instance, job, steps:[{name, run, env, timeout}]}] for the selected
    instances, plus every (instance, step) that the matrix keeps."""
    units = []
    for name, job, ctx, selected in instances(suites, sel):
        mine = []
        for index, step in enumerate(suites[job]["steps"]):
            if "uses" in step:
                if step["uses"].split("@")[0] in SETUP_USES:
                    continue
                raise PackError("%s: step %d uses %s; only run: steps can be packed" % (job, index, step["uses"]))
            # The matrix part of the condition decides whether the step exists
            # in this instance; the status part (!cancelled()) only decides
            # units. Both read as true here.
            if "if" in step and not truthy(evaluate(step["if"], dict(ctx, __cancelled=False))):
                continue
            for key in step:
                if key not in ("name", "if", "run", "env", "timeout-minutes", "id"):
                    raise PackError("%s: step %r has unsupported key %r" % (job, step.get("name"), key))
            body = substitute(step["run"], ctx)
            if "${{" in body:
                raise PackError("%s: unresolved expression in %r" % (job, step.get("name")))
            entry = {
                "index": index,
                "name": substitute(step.get("name") or body.splitlines()[0][:60], ctx),
                "run": body,
                "env": {k: substitute(v, ctx) for k, v in (step.get("env") or {}).items()},
                "timeout": float(step.get("timeout-minutes", DEFAULT_STEP_TIMEOUT_MINUTES)),
            }
            if independent(step) or not mine:
                mine.append([entry])
            else:
                merged = [s for u in mine for s in u] + [entry]
                mine = [merged]
        if not selected:
            continue
        for k, steps in enumerate(mine):
            units.append({"id": "%s #%d" % (name, k + 1), "instance": name, "job": job, "steps": steps})
    return units


def load_durations(path=DURATIONS):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)["seconds"]
    except FileNotFoundError:
        return {}


def step_key(instance, step_name):
    return "%s :: %s" % (instance, step_name)


def unit_seconds(unit, durations):
    return sum(durations.get(step_key(unit["instance"], s["name"]), UNMEASURED_SECONDS) for s in unit["steps"])


def plan(units, durations, runners=RUNNERS, lanes=LANES):
    """[[lane units] per lane], lane i on runner i // lanes: longest first onto
    the lightest lane, ties by unit id, so every runner computes the same plan.
    Only as many runners as the selected work needs at LANE_BUDGET_SECONDS are
    used (a small selection must not pay eight runners' setup); the rest get
    empty lanes and stop after the plan step."""
    total = sum(unit_seconds(u, durations) for u in units)
    used = min(runners, max(1, -(-int(total) // (LANE_BUDGET_SECONDS * lanes))))
    count = runners * lanes
    bins = [[] for _ in range(count)]
    loads = [0.0] * count
    active = used * lanes
    for unit in sorted(units, key=lambda u: (-unit_seconds(u, durations), u["id"])):
        i = min(range(active), key=lambda i: (loads[i], i))
        bins[i].append(unit)
        loads[i] += unit_seconds(unit, durations)
    check_cover(units, bins)
    return bins, loads


def check_cover(units, bins):
    """Every unit in exactly one lane, and every step of them in exactly one unit."""
    seen = {}
    for lane, group in enumerate(bins):
        for unit in group:
            seen.setdefault(unit["id"], []).append(lane)
    twice = {u: l for u, l in seen.items() if len(l) > 1}
    missing = sorted({u["id"] for u in units} - set(seen))
    stray = sorted(set(seen) - {u["id"] for u in units})
    steps = [(u["instance"], s["index"]) for group in bins for u in group for s in u["steps"]]
    dup_steps = sorted({s for s in steps if steps.count(s) > 1})
    want = sorted((u["instance"], s["index"]) for u in units for s in u["steps"])
    if twice or missing or stray or dup_steps or sorted(steps) != want:
        raise PackError("packed plan is not an exact one-time cover: units twice %s, units unassigned %s, "
                        "units not selected %s, steps twice %s" % (twice, missing, stray, dup_steps))


def check_every_step_is_reachable(suites):
    """No step of a suite may fall outside every matrix value: it would never run."""
    sel = {k: "" for k in selection_ctx({})}
    kept = {(u["job"], s["index"]) for u in units_of(suites, dict(sel, **{"needs.changes.outputs.jobs": "|ALL|",
                                                                         "needs.changes.outputs.full": "true",
                                                                         "needs.changes.outputs.code": "true",
                                                                         "needs.changes.outputs.net": "true",
                                                                         "github.event_name": "workflow_dispatch"}))
            for s in u["steps"]}
    lost = [(job, i, step.get("name")) for job, spec in suites.items() for i, step in enumerate(spec["steps"])
            if "uses" not in step and (job, i) not in kept]
    if lost:
        raise PackError("steps that no matrix value runs: %s" % lost)


# --- running ---------------------------------------------------------------

class Lane:
    def __init__(self, name, units, out, base_env):
        self.name, self.units, self.out, self.base_env = name, units, out, base_env
        self.results = []          # (unit, step, verdict, seconds, log)
        self.proc = None
        self.stopped = False

    def stop(self):
        self.stopped = True
        p = self.proc
        if p and p.poll() is None:
            try:
                os.killpg(p.pid, signal.SIGTERM)
                for _ in range(20):
                    if p.poll() is not None:
                        break
                    time.sleep(0.1)
                os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    def run(self):
        for k, unit in enumerate(self.units):
            root = os.path.join(self.out, "lane-%s" % self.name, "unit-%02d" % k)
            dirs = {d: os.path.join(root, d) for d in ("data", "config", "cache", "tmp", "runner-temp")}
            for d in dirs.values():
                os.makedirs(d, exist_ok=True)
            unit_env = {}
            failed = None
            for step in unit["steps"]:
                log = os.path.join(root, "step-%02d.log" % step["index"])
                if self.stopped:
                    self.results.append((unit, step, "CANCELLED", 0.0, log))
                    continue
                if failed is not None:
                    self.results.append((unit, step, "SKIPPED (after %s failed)" % failed, 0.0, log))
                    continue
                gh_env = os.path.join(root, "github-env-%02d" % step["index"])
                open(gh_env, "w").close()
                env = dict(self.base_env)
                env.update(unit_env)
                env.update(step["env"])
                env.update({
                    "XDG_DATA_HOME": dirs["data"], "XDG_CONFIG_HOME": dirs["config"], "XDG_CACHE_HOME": dirs["cache"],
                    "TMPDIR": dirs["tmp"], "RUNNER_TEMP": dirs["runner-temp"], "GITHUB_ENV": gh_env,
                    "GITHUB_OUTPUT": os.path.join(root, "github-output-%02d" % step["index"]),
                    "PACKED_SUITE": unit["instance"], "PACKED_LANE": self.name,
                })
                script = os.path.join(root, "step-%02d.sh" % step["index"])
                with open(script, "w", encoding="utf-8") as f:
                    f.write(step["run"])
                started = time.time()
                with open(log, "w", encoding="utf-8") as f:
                    f.write("=== %s :: %s (lane %s)\n" % (unit["instance"], step["name"], self.name))
                    f.flush()
                    self.proc = subprocess.Popen(["bash", "--noprofile", "--norc", "-eo", "pipefail", script],
                                                 cwd=ROOT, env=env, stdout=f, stderr=subprocess.STDOUT,
                                                 stdin=subprocess.DEVNULL, start_new_session=True)
                    try:
                        rc = self.proc.wait(timeout=step["timeout"] * 60)
                        verdict = "PASS" if rc == 0 else "FAIL (exit %d)" % rc
                    except subprocess.TimeoutExpired:
                        verdict = "FAIL (timed out after %g min)" % step["timeout"]
                    finally:
                        # Sweep the step's own process group, whatever it left.
                        try:
                            os.killpg(self.proc.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        self.proc.wait()
                if self.stopped and verdict != "PASS":
                    verdict = "CANCELLED"
                self.results.append((unit, step, verdict, time.time() - started, log))
                unit_env.update(read_env_file(gh_env))
                if verdict != "PASS":
                    failed = repr(step["name"])


def read_env_file(path):
    out, lines, i = {}, open(path, encoding="utf-8").read().split("\n"), 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"^([A-Za-z_]\w*)<<(\S+)$", line)
        if m:
            end = lines.index(m.group(2), i + 1)
            out[m.group(1)] = "\n".join(lines[i + 1:end])
            i = end + 1
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            out[k] = v
        i += 1
    return out


def runner_lanes(bins, runner):
    return bins[(runner - 1) * LANES:runner * LANES]


def build(env=None):
    suites = load_suites()
    check_every_step_is_reachable(suites)
    units = units_of(suites, selection_ctx(env))
    durations = load_durations()
    bins, loads = plan(units, durations)
    return suites, units, durations, bins, loads


def print_plan(units, durations, bins, loads):
    print("packed: %d selected unit(s) on %d runner(s) x %d lane(s)" % (len(units), RUNNERS, LANES))
    for i, (group, load) in enumerate(zip(bins, loads)):
        if load > LANE_BUDGET_SECONDS and len(group) > 1:
            print("::warning::packed lane %d is planned at %d s, over the %d s budget: refresh %s or raise RUNNERS"
                  % (i + 1, load, LANE_BUDGET_SECONDS, os.path.relpath(DURATIONS, ROOT)))
        print("  runner %d lane %s: %4d s  %s" % (i // LANES + 1, "ab"[i % LANES], load,
                                                  "; ".join(u["id"] for u in group)))
    for u in units:
        for s in u["steps"]:
            if step_key(u["instance"], s["name"]) not in durations:
                print("::warning::unmeasured packed step, planned at %d s: %s" % (UNMEASURED_SECONDS,
                                                                                step_key(u["instance"], s["name"])))


def cmd_plan(runner):
    _, units, durations, bins, loads = build()
    print_plan(units, durations, bins, loads)
    mine = runner_lanes(bins, runner)
    count = sum(len(g) for g in mine)
    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a", encoding="utf-8") as f:
            f.write("units=%d\n" % count)
    print("runner %d: %d unit(s)" % (runner, count))
    return 0


def cmd_run(runner, out_dir):
    _, units, durations, bins, loads = build()
    mine = runner_lanes(bins, runner)
    os.makedirs(out_dir, exist_ok=True)
    base_env = dict(os.environ)
    lanes = [Lane("ab"[i], group, out_dir, base_env) for i, group in enumerate(mine)]
    threads = [threading.Thread(target=lane.run) for lane in lanes]

    def on_signal(signum, _frame):
        for lane in lanes:
            lane.stop()
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, on_signal)
    started = time.time()
    for t in threads:
        t.start()
    while any(t.is_alive() for t in threads):
        for t in threads:
            t.join(timeout=0.5)
    print("both lanes done in %d s" % (time.time() - started))
    return report(lanes)


def report(lanes):
    status = 0
    suites = {}
    for lane in lanes:
        for unit, step, verdict, seconds, log in lane.results:
            print("::group::%s :: %s -- lane %s: %s (%d s)" % (unit["instance"], step["name"], lane.name, verdict, seconds))
            if os.path.exists(log):
                with open(log, encoding="utf-8", errors="replace") as f:
                    sys.stdout.write(f.read())
            print("::endgroup::")
            suites.setdefault(unit["instance"], []).append((step["name"], verdict, lane.name))
            if verdict != "PASS":
                status = 1
                print("::error::%s :: %s -- %s (lane %s)" % (unit["instance"], step["name"], verdict, lane.name))
    lines = ["| Suite | Verdict | Steps |", "|---|---|---|"]
    for name, steps in suites.items():
        bad = [s for s in steps if s[1] != "PASS"]
        lines.append("| %s | %s | %d (%s) |" % (name, "PASS" if not bad else "FAIL", len(steps),
                                               ", ".join("%s: %s" % (s[0], s[1]) for s in bad) or "all pass"))
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
    print("\n".join(lines))
    return status


def cmd_check():
    sel = {"CI_CODE": "true", "CI_FULL": "true", "CI_NET": "true", "CI_JOBS": "|ALL|", "CI_EVENT": "workflow_dispatch"}
    _, units, durations, bins, loads = build(sel)
    print_plan(units, durations, bins, loads)
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("plan", "run"):
        p = sub.add_parser(name)
        p.add_argument("--runner", type=int, required=True)
        if name == "run":
            p.add_argument("--out", default=os.path.join(tempfile.gettempdir(), "packed"))
    sub.add_parser("check")
    args = ap.parse_args(argv)
    try:
        if getattr(args, "runner", None) is not None and not 1 <= args.runner <= RUNNERS:
            raise PackError("runner %d is outside 1..%d" % (args.runner, RUNNERS))
        if args.cmd == "plan":
            return cmd_plan(args.runner)
        if args.cmd == "run":
            return cmd_run(args.runner, args.out)
        return cmd_check()
    except PackError as e:
        print("::error::%s" % e)
        return 1


if __name__ == "__main__":
    sys.exit(main())
