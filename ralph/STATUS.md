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
2. **Lease** — stops two firings working the same backlog. The cron fires hourly
   whether or not the previous run finished, which is not configurable, so
   overlap is the default rather than the exception. It has already happened.

---

    firing:    (placeholder — see the ralph-status branch)
    session:   —
    task:      —
    state:     idle
    updated:   —

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
- **Timestamp stale, no run in the Routine's Runs tab** — the loop died. The
  next hourly firing should pick it up; if two pass with no change, something is
  wrong with the Routine itself.
- **`state: started` and stale** — a firing died early, most likely before it
  could push anything. Its branch may exist with no commits worth keeping.
- **`state: blocked` or `play-gate`** — working as designed. Read `BLOCKED.md`.

A stale heartbeat is a real signal. Silence, which is what existed before this
file, is not.
