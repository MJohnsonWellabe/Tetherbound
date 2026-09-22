# Owner directive — parallel Meadows and Cloudreach lanes, one machine, 2026-09-19

Two Codex sessions now run concurrently on the same Windows box: one continuing
Meadows to acceptance, one starting a scoped Cloudreach visual/environment lane.
Claude (the orchestrator session) coordinates across both through this repository —
there is no other live channel between the two sessions or to Claude. This directive
is binding process for both until superseded.

## Scope: the Cloudreach lane is a bounded exception to a standing rule

`CLAUDE.md` states: "No Biome 2 implementation until the Meadows passes its exit
gate." `OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md` reinforced this: no
Cloudreach/Stormwood/Water work of any kind until Meadows' Tier 0/1 items closed.

This directive carves out one explicit, scoped exception, effective 2026-09-19:
**Cloudreach VISUAL AND ENVIRONMENT PRODUCTION may proceed now, concurrently with
Meadows.** This is the terrain wear-overlay, cloud-bank, cliff-strata and grass work
already fully specified in `docs/HANDOFF_FULL_GAME_2026-09-11.md` and mid-flight
before the Meadows-first pause — not new Cloudreach gameplay systems, not new
content, not progression, not anything that reads as "starting Biome 2" in the
sense the hard rule protects against. See
`docs/CODEX_GOAL_2026-09-19_CLOUDREACH_VISUAL_PRODUCTION.md` for the exact scope.

Stormwood and Water remain fully paused. Nothing here reopens them.

Meadows remains the priority. If the render lock (below) or any other resource
forces a choice between the two lanes, Meadows wins.

## Same machine: the render lock

One Godot process per machine is this project's own established ceiling
(`AGENT_WORKFLOW.md` §3). Two sessions capturing screenshots at once is a known
corruption/contention risk, not just a slowdown.

**Code, test, and root-cause work is not render-bound and runs fully concurrent in
both sessions, no coordination needed.**

**Screenshot/visual capture is render-bound and must be serialized** through a
plain local file, not tracked by git (a git round-trip is too slow for this):

```
D:\tetherbound\RENDER_LOCK.json
{ "held_by": "meadows" | "cloudreach" | null, "since_utc": "<ISO8601>" }
```

Rule for both sessions: before launching Godot with a rendering driver for
capture, read the lock file. If null or missing, write your own session name and
timestamp, then capture. If held by the other session, do not wait idle — switch
to code/root-cause/test work and recheck later. Release (set `held_by` back to
null) immediately after capture completes, including on a crashed/aborted capture
attempt. If a lock has been held more than 2 hours with no corresponding new
capture output, treat it as abandoned and reclaim it, noting that in your own
session's checkpoint log.

## Agent tiers, inside each session

Unchanged from `OWNER_DIRECTIVE_2026-09-09_BIOME_CAST_VISUAL_LANES.md`: lower-tier
agents handle bounded implementation; Astra is reserved for independent judgment
and difficult architecture decisions, not typing. This applies inside each of the
two sessions independently. Astra is not a cross-session coordinator — with no live
channel between the two sessions, only the shared repository (and Claude, reading
it) can see both at once.

## Claude's role: plan review before work starts, results review at completion

Claude cannot pause or interrupt a running Codex session directly. Both checkpoints
below work through committed files instead.

**Before starting substantive implementation**, each session writes its intended
approach and scope for the work window to:

```
ralph/reports/<LANE>-0919/PLAN.md
```

(`<LANE>` is `MEADOWS` or `CLOUDREACH`), commits and pushes it. Continue low-risk,
reversible investigation while waiting, but hold anything with real cost or that is
hard to undo — spending a Meshy generation, claiming a ledger promotion, committing
to a specific architectural approach, or (for Cloudreach) anything not obviously
inside the visual/environment scope above — until an approval file appears at:

```
ralph/reports/<LANE>-0919/PLAN-APPROVED.md
```

Claude watches for each `PLAN.md` push, reviews it, and drops the approval file.
This is not a design review of implementation detail — it is a check that the
plan stays in scope, respects the render lock, and doesn't quietly reopen Stormwood,
Water, or new Cloudreach gameplay.

**At completion of a work window**, each session writes a results package to:

```
ralph/reports/<LANE>-0919/RESULTS.md
```

in the same style already established by `ralph/reports/MEADOWS-0916/CLOSEOUT.md`:
real captured frames sanity-checked against the actual shipping build (not a
capture harness with missing geometry), a played-path or reviewed-frame summary,
and ledger deltas. Claude reviews this package and the evidence it references —
not the code diff. A results package that only asserts completion without
referenced evidence is treated the same as any other self-report: not itself
proof.

## What this directive does not change

Everything in `docs/HANDOFF_FULL_GAME_2026-09-11.md`,
`OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md`, and
`docs/CODEX_EXIT_HANDOFF_2026-09-19_GOAL.md` (or whichever handoff is newest when
a session picks this up — check `AGENTS.md` / `docs/00_START_HERE.md` for the
current pointer) stays in force for the Meadows lane. This directive adds process
(render lock, plan/results checkpoints) and one scoped exception (Cloudreach
visual production); it does not relax any evidence, testing, or acceptance
standard already in place.
