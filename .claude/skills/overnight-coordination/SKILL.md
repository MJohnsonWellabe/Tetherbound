---
name: overnight-coordination
description: Coordinating parallel Ralph lanes, CI landings, or any async/delegated work unattended (overnight, or any stretch where you will not be re-prompted soon). Load before delegating a fix-and-wait, launching a CI run you won't watch live, or handing off to a sub-lane. Prevents work silently stalling for hours because the follow-up was never actually armed.
---

# Coordinating work you won't watch live

This skill exists because of a real failure on 2026-09-01: a regression was
found, correctly delegated to a lane with the tools to fix it, and that lane
did its job in under an hour. Then the coordinator scheduled no follow-up,
went idle, and the fix's own CI result — and a second, unrelated failure in
the same run — sat unread for **over six hours** until the owner noticed
nothing had landed and asked what was going on. The lanes were not the
problem. The gap between "I delegated this" and "I checked back" was.

## The one rule

**Every push that triggers CI, and every delegation whose result you need,
ends with either a known result or an armed follow-up — never neither.**

"Armed" means a mechanism that will actually re-invoke you: `send_later`
(preferred for a single resumable check) or a scheduled wakeup, not a mental
note, not "I'll check when I'm back". If you don't have a working mechanism
to arm — verify it works before relying on it (see Monitor pitfall below) —
that itself is a blocker to flag, not something to route around by promising
to remember.

## Chain the follow-up, don't fire it once

A single scheduled check-in is not enough for a multi-step async sequence
(push → CI fails → delegate a fix → fix lands → CI runs again → might fail
differently). Each check-in's own instructions must re-arm the *next*
check-in if the work isn't actually done yet. "Schedule one wake-up and
assume it closes the loop" is exactly the bug that caused the six-hour gap:
the first check-in fired, found a real regression, correctly delegated the
fix — and then nothing scheduled the *next* check on that delegate's result.
Treat "did I just delegate something whose outcome I still need to see?" as
a question to answer explicitly before ending a turn, every time, not just
the first time.

## When a CI run comes back, read the whole run

A run's top-level `conclusion: failure` can hide a job that's a known flake
sitting next to a job that's a real, novel regression. Always list every job
in the run and check each one's own conclusion — don't stop at the first
failure you recognize and assume the rest is clean, and don't assume a
green re-run of "the job I was watching" means the whole run is green if
other jobs changed between attempts.

## Distinguish flake from regression before touching anything

- Same failure signature on a clean re-run of just that job → treat as
  confirmed flake, proceed.
- Same signature reproduces → real, root-cause it. Do not merge, and do not
  re-run a second time hoping it changes — re-running a real failure wastes
  a CI slot and teaches nothing.
- A *different* job fails on the next attempt → a new, separate issue
  engaged that isn't what you were chasing. Don't assume it's related.
  Don't assume it's a flake either. Get its own log before deciding.

## Root-causing without a Godot binary

The coordinator's own shell has no Godot binary and no local way to run the
project's smoke tests — CI and delegated cloud lanes are the only way to
actually execute anything. So: reason from logs and static code review as
far as it goes (this narrowed a regression to two named suspects in the
2026-09-01 incident), but don't guess past that point. Delegate the actual
bisection to a lane that has Godot access, and hand it everything you found
— the exact repro, the exact commits to check first, what you already ruled
out and why — so it isn't starting cold. It found the real cause (a third,
unconsidered commit) faster than either named suspect would have panned out.

## Batch CI, don't fragment it

If several independent branches are ready, merge them into one consolidated
landing branch, push once, and let one CI run cover all of them — then
cancel the now-redundant individual per-branch runs. Re-doing this
consolidation after every new push is fine; re-triggering N parallel CI runs
for N branches that are all headed to the same place is not. This applies
throughout a long coordination session, not just at the start of it: watch
for the queue growing back after you've flattened it once.

## Verify tool access before depending on it

`curl` to `api.github.com` with `$GITHUB_TOKEN`/`$GH_TOKEN` from the shell
does **not** work in this environment — GitHub access is only enabled
through the `mcp__github__*` tools, not raw API calls, even though the
token variables are present in the shell. A `Monitor` polling loop built on
that assumption fails silently in a way that looks like it's working (it
still fires periodic notifications) but never actually detects completion.
If a monitoring approach's first result looks wrong (`? ?`, an auth error,
an empty response), stop and fix the mechanism immediately rather than
letting it spin — a broken monitor is worse than no monitor, because it
looks like coverage.

## Before landing anything, confirm what's actually true

- A lane's own self-reported summary ("fix shipped", "all tests pass") is a
  claim, not evidence. Check the actual diff before trusting it — this
  session caught more than one lane whose summary overstated what it had
  actually pushed.
- "Landed" means `git merge-base --is-ancestor <branch> origin/main`
  succeeds, never the CI badge alone and never a session's own say-so.
- A fresh, direct reproduction (by the owner or by re-running a probe)
  reopens a finding even if an old doc says it's fixed — see CLAUDE.md's
  own precedence rule. The reverse also holds: don't let old bookkeeping
  keep something open once actually-landed evidence exists.

## Keep your own local checkout honest

A local branch checkout can silently drift behind `origin` while a delegate
lane pushes to the same branch name (exactly what a consolidated landing
branch is for). Before committing anything onto a shared landing branch,
`git fetch` and diff local HEAD against the remote tip — don't trust a
`git log -1 HEAD` you read earlier in the session. A commit built on a stale
parent either gets rejected as non-fast-forward (the safe outcome) or, if
force-pushed without checking, silently reverts someone else's already-landed
fix. If the push is rejected, `git fetch` and re-base/re-apply on the actual
current tip rather than force-pushing over it.

## When you resume after a gap

If you're picking this up after an unknown amount of idle time, don't assume
your last-known state is current: re-check CI status, re-list running/idle
lanes, and re-fetch the target branch before acting on anything you
"remember" from before the gap. State can have moved in either direction
while you weren't watching.
