# Ralph — live status and lease

> ## ⚠ This copy is a placeholder. The live one is on the `ralph-status` branch.
>
> Heartbeats are pushed to `ralph-status`, never here. The block below on `main`
> is frozen and will always read `idle` — reading it for status is exactly the
> mistake this warning exists to prevent.

The live file does two jobs:

1. **Heartbeat** — answers "is the loop working?" from GitHub alone. Trigger-
   fired sessions do not appear in the normal Claude sessions list, only under
   the Routine's own **Runs** tab, so without this there is no external signal.
2. **Leases** — stop two firings working the same *area*. Three Routines now
   fire on staggered schedules and the hourly cron fires whether or not the
   previous run finished, so **concurrent firings are the design**, not an edge
   case. What must not happen is two of them on the same files.

## One block per live firing

The old format had a single block and a single answer to "is anyone working?".
That answer is now always yes, and it is not the useful question. Each firing
appends its own block; the question is **which areas are held**.

    firing:    (placeholder — see the ralph-status branch)
    session:   —
    task:      —
    area:      —
    state:     idle
    updated:   —

`area` is copied from the backlog item's own `area:` field. List more than one
if the task genuinely touches more than one — a vegetation task that re-runs
`build_playground_terrain.gd` holds `vegetation, terrain`, and saying so up
front is much cheaper than finding out in a merge.

**Delete your block when you finish — don't leave it at `shipped`.** This
changed 2026-08-11: leaving a `shipped` corpse used to be offered as an
equally-fine option, and every firing took it, because it's the path of least
resistance mid-task. The file grew to 53 blocks across ~30 sessions in six
hours and became unreadable at a glance — the owner asked why ten lanes were
running when there were three. There weren't ten; there was one un-pruned
file. `shipped` is a real terminal state and correctly ignored by the
liveness check, so nothing was ever *unsafe* — but a lease file only a script
can read isn't doing its other job, which is letting a human tell at a glance
whether the loop is alive.

A block left at `working` (not deleted, not updated) still costs the next
firing a branch check at best and a stand-down at worst — that part hasn't
changed.

---

## The states

| `state` | Means |
|---|---|
| `started` | Picked a task, branch created, work not begun |
| `working` | Mid-task. `note` says what it is actually doing |
| `shipped` | CI green, fast-forwarded to `main`, `DONE.md` updated |
| `blocked` | Stopped on purpose. `BLOCKED.md` says why |
| `play-gate` | Waiting for the owner to play. The loop is correctly parked |
| `idle` | Backlog empty or everything parked |

## Reading it

- **Timestamp moving, `state: working`** — healthy, leave it alone.
- **Timestamp stale, no run in the Routine's Runs tab** — that lane died. The
  next firing should pick it up; if two pass with no change, something is wrong
  with that Routine itself.
- **`state: started` and stale** — a firing died early, most likely before it
  could push anything. Its branch may exist with no commits worth keeping.
- **`state: blocked` or `play-gate`** — working as designed. Read `BLOCKED.md`.
- **Several blocks at `working` on different areas** — this is the loop running
  as intended, not a collision.
- **Several blocks at `working` on the SAME area** — a real collision. The
  earliest `updated` wins; the others should have stood down.

**A stale timestamp is not by itself proof of death.** The expiry is 40 minutes
(down from 90, which cost ~2 hours of stand-down per dead firing), and the
shorter clock is only safe because the branch check backs it up: if
`ralph/<task-id>` has a commit in the last 40 minutes, that firing is alive and
slow, whatever its heartbeat says. `PROMPT.md` has the exact sequence.

A stale heartbeat is a real signal. Silence, which is what existed before this
file, is not.
