# Ralph — live status

**One file that answers "is the loop working?" from GitHub alone**, with no
session access, no dashboard, and nobody to ask.

Every firing rewrites this before it does anything else, and again as it goes.
So the timestamp is the heartbeat: if it is hours old and no run is in flight,
the loop is dead rather than thinking.

Trigger-fired sessions do **not** appear in the normal Claude sessions list —
only under the Routine's own **Runs** tab. That is why this file exists.

---

    firing:    (none yet)
    session:   —
    task:      —
    state:     idle
    updated:   —
    note:      Set up by the coordinator session. The first Ralph firing
               replaces this block.

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
