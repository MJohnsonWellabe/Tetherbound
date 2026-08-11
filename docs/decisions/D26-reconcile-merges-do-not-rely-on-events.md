# D26 — Reconcile merges; do not rely on events arriving

**Date:** 2026-08-11 · **Decided by:** a lane reported a green branch that would
not merge; the run data named the mechanism.

Kind: implementation

## The report

A firing finished `EV4-textures-remainder`, went green on the Windows export,
and stopped with: *"The branch just hasn't been auto-merged to `main` yet due to
a dispatch gap in the merge workflow."*

It was right that something was wrong, and wrong about the scope. Four branches
were stranded, not one, and the mechanism was not a gap in the dispatch — the
dispatch works fine.

## The mechanism

`ralph-merge.yml` triggers on `workflow_run: [CI] completed`. When `main` has
moved under a branch it rebases, force-pushes, and dispatches CI explicitly:

```bash
gh workflow run ci.yml --ref "$BRANCH"    # with secrets.GITHUB_TOKEN
```

That dispatch succeeds and CI runs — `workflow_dispatch` is a documented
exception to GitHub's recursion guard. But when that run **completes**, no
`workflow_run` event is raised, because the run was initiated with the default
`GITHUB_TOKEN`. So nothing wakes up to merge the branch it had just rebased and
re-tested.

The file's comments already knew about the guard; `release.yml` had been
silently unfired for twelve hours and twenty-five commits over the same thing.
What was missed is that **escaping the guard on the way in does not escape it on
the way out.**

## The evidence

Every live branch, 2026-08-11, by how its latest green CI run was triggered:

| Trigger of the green run | Branches | Merged? |
|---|---|---|
| `push` | `NP3`, `NP3-bookkeeping`, `SA2`, `EV3-path-stones-note`, `lease-file-legibility` | **all** |
| `workflow_dispatch` | `EV3`, `EV4-textures-remainder`, `EV9`, `LP3` | **none** |

Not a flake. The rebase path was a dead end by construction — and under about
ten lanes it is the *common* path, because `main` moves during most 5-minute CI
runs. Two corroborating symptoms: `LP3` burned six dispatched CI runs
ping-ponging, and `EV3` was dispatched twice on the same sha.

## The decision

**Stop depending on the delivery of an event.** `ralph-sweep.yml` runs every ten
minutes, lists `ralph/**`, and ships any branch whose tip has a completed green
CI run and fast-forwards onto `main`.

A reconciler rather than a third patched event chain, because this is now the
second instance of the same guard biting in a different place, and the shape of
the failure is what makes it expensive: a missed event is **silent**. The branch
looks green, CI looks green, and nothing says the work is not shipping. A
reconciler converts that entire class into latency.

`ralph-merge.yml` is **kept**, not replaced. Immediate merges on the ordinary
green path are worth having; the sweep is the backstop. Both share the
`ralph-merge` concurrency group so they can never race on `git push origin main`
— the failure that took out twelve of eighteen runs when the loop went to ten
writers.

The shipping logic moved to `tools/ci/ship_branch.sh` and both call it. Two
hand-maintained copies of a routine that has already destroyed unmerged work
once — the delete step's scar — is not a trade worth taking to avoid one
indirection.

Two smaller corrections rode along:

- **A rebase cap** (3), which `ralph-merge.yml`'s own comment had asked for in
  advance: *"If a branch is ever seen rebasing more than two or three times,
  that assumption is wrong and this needs a cap."* `LP3` reached six. Counted
  **since the branch was last pushed by its author**, not over all time, so a
  fresh push is a fresh start and the branches that burned attempts on this very
  bug are not permanently blocked by it.
- **Skip the dispatch when the rebased sha already has a green run.** A rebase
  onto an unchanged `main` is deterministic, so the second attempt can produce a
  commit that has already been tested. That was the `EV3` double-dispatch.

## Cost

Up to ten minutes of latency on any merge whose event goes missing, and one
scheduled run every ten minutes whether or not there is anything to do.

The fast-forward guarantee is unchanged: nothing reaches `main` without a green
CI run on the exact commit that lands. The sweep verifies that from the run
history rather than from an event payload, which is the same fact read a
different way.

A branch that conflicts, or that exceeds the rebase cap, still stops dead and
says so. The sweep records it and carries on to the next branch rather than
letting one stuck branch strand the queue behind it.

## What would change this

If the owner mints a fine-grained PAT (`contents: write`, `actions: write`) as
`RALPH_TOKEN` and the `gh workflow run` calls use it, the dispatched runs are
attributed to a real actor and the event chain works — merges become immediate
again. That is worth doing, and it is **not** a reason to delete the sweep: the
sweep is what makes the system tolerant of a missed event at all, whatever the
next cause turns out to be.
