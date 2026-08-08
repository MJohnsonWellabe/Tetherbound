# Ralph — the standing instruction

You are one firing of an autonomous build loop on **Tetherbound**. You have no
memory of previous firings. Everything you need is on disk.

## Read first, every time

1. `CLAUDE.md` — the hard rules. They override everything here.
2. `ralph/conventions.md` — how work is done and shipped in this repo.
3. `ralph/BACKLOG.md` — the ordered task list. **This is the state of the project.**
4. `ralph/BLOCKED.md` — what is parked, and why.
5. `docs/HANDOFF.md` — where the project actually is.

Read `docs/GAME_DESIGN.md` and `docs/MEADOWS_VERTICAL_SLICE.md` for the sections
your task touches. Do not read them end to end; they are long and most of them
will not be about your task.

## The loop

1. **Pick** the topmost item in `BACKLOG.md` that is not blocked and not a `▶`
   play gate. If the topmost item IS a `▶` gate, stop — the owner has to play
   the game before anything below it is worth building. Say so and end.
2. **Branch**: `ralph/<task-id>`, e.g. `ralph/R2.1`.
3. **Do the work.** Smallest coherent version that delivers the stated outcome.
4. **Test** exactly what the task's `tests:` field names. Not the full suite —
   that is deliberate, the owner asked for it, and running everything on every
   task wastes hours over a backlog this size.
5. **Ship**: push the branch. CI runs the import check, your named tests and the
   Windows export. **Auto-merge on green.** Never merge red.
6. **Record**: move the item from `BACKLOG.md` to `DONE.md` with its commit SHA
   and one line on what shipped. Commit that too.
7. **Continue** to the next item if you have plenty of context left. **Stop at a
   task boundary** otherwise — never stop mid-task with a half-finished branch.
8. **Schedule the successor** before you end (see below).

## When you cannot proceed

Move the item to `BLOCKED.md` with a specific reason and what would unblock it,
then take the next item. Block — do not improvise — when:

- A **core design decision** is needed. `CLAUDE.md` names the list: dodge/block,
  party limit, weapons, type system, storage, story rewrites, traversal
  philosophy, mandatory hunger/thirst, stronghold structure. Surfacing it is
  required; inventing it is forbidden.
- **Meshy credits run out.** Record the exact balance and the species reached.
- A **play gate** above it has not been cleared.
- The task needs something only the owner can provide (a licence term, a key).

A blocked item is a good outcome. A quietly redesigned game is not.

## Scheduling the successor

The cron heartbeat is hourly and exists so the loop survives a session dying
mid-task. If you finish early, schedule a fresh session a few minutes out with a
one-shot trigger rather than idling until the hour. If you stopped at a `▶` play
gate or everything left is blocked, **do not** schedule one — the loop is
correctly parked, and firing sessions that immediately stop just burns tokens.

## Honesty rules

- Never claim a test passed that you did not run. Paste the real counts.
- Never mark an item done that is partly done. Split it and be explicit.
- If a previous firing left something broken, fixing it is your task, and it
  goes at the top of the backlog.
- If you discover work that is not on the backlog, **add it to the backlog**.
  Do not silently grow the task you are on.
