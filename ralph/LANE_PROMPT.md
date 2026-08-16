# The lane Routine prompt — copy this when creating a lane

Three Routines run the loop (see `MANUAL.md`). This file holds the **exact
prompt text** for the two unkeyed lanes, so a lane can be recreated without
anyone reconstructing it from memory.

## Why this file exists

An agent tried to create the lanes with the `create_trigger` tool on
2026-08-11. It succeeded, and the Routines were useless: **`create_trigger` has
no `sources` parameter**, so the sessions it fires start with **no repository
checked out**. Both lanes fired on schedule and produced nothing — no lease, no
branch, no commit — because there was nothing on disk to read.

**Lanes must be created in the Routines UI at `claude.ai/code/routines`, with
the GitHub repository attached.** That is not a preference; it is the only way
the source gets set. An agent can create the Routine but cannot give it a repo.

## Before you create anything

- The lanes carry **no Meshy key**, deliberately. The key lives in the "Ralph"
  Routine's prompt and nowhere else, because GitHub history is permanent and
  secret scanning would likely revoke it if it ever reached a commit. Do not
  paste it into a lane.
- Set the repository to `MJohnsonWellabe/Tetherbound`, default branch `main`.
- Schedule hourly, staggered ~20 minutes apart from `49 * * * *`:
  lane B at `9 * * * *`, lane C at `29 * * * *`.

## The prompt

Copy everything between the rules. Change **one word** — "lane B" to "lane C"
on the first line — and nothing else.

---

Ralph firing — lane B.

Pull `main`, then re-read from disk. These change between firings and they, not your memory, are the state of the project: `ralph/PROMPT.md` (the standing instruction; it overrides this message), `ralph/BACKLOG.md`, `ralph/BLOCKED.md`, `ralph/conventions.md`, `CLAUDE.md`.

YOU ARE A LANE. Three Routines fire on staggered schedules and concurrent firings are the intended design, not a hazard. `ralph/PROMPT.md`'s "Claim a lease FIRST" section is the protocol and it changed on 2026-08-11 — read it properly rather than assuming you remember it:

- Leases live in `ralph/STATUS.md` on the `ralph-status` branch, ONE BLOCK PER LIVE FIRING.
- You stand down only when YOUR OWN `area:` is held. Another firing existing is NOT a reason to stop — that was the old behaviour and it is what lanes exist to stop.
- A lease is live if `updated` is under 40 minutes old, OR if the branch its `task` names has a commit in the last 40 minutes. Check the branch before reclaiming anything; a firing deep in a long render pass looks dead and is not.
- Stand down only if EVERY unblocked item's area is held. Say so plainly and end without scheduling a successor. That is a correct outcome.

YOU DO NOT HAVE THE MESHY API KEY, and this is deliberate rather than a fault. Skip every backlog item marked `lane: art` as though its area were held, and take the next one down. Do NOT report this as blocked — it is not blocked, it is simply not yours; the keyed Routine picks it up. Do NOT pivot to ledger or bookkeeping busywork instead; a firing did that once after losing the key and produced nothing anyone wanted. In-engine survey and screenshot renders need no key and are fully available to you.

Take the topmost unblocked item whose area is free. **There are no play gates any more** — the owner retired every `▶` gate on 2026-08-16, including R9.5, the exit gate the loop used to park on; D21 stays as history and reads as superseded, so do not re-add one. When the backlog runs out, stop and report — an empty backlog is the terminal condition, and inventing work or starting Biome 2 is not.

ONE ITEM ONLY. Branch `ralph/<task-id>`, build the smallest coherent version, and run ONLY the tests that item names — locally and headless, before you push. Push that single item's commit (plus its bookkeeping commit, last). Pushing the branch IS the ship action; no pull request, no self-merge.

VERIFY IT LANDED ON `main` BEFORE DOING ANYTHING ELSE. Watch `main`, not CI — green CI is not the same as shipped. `ralph-merge.yml` is fast-forward only: if `main` moved while you worked it refuses and goes red even though your tests passed. Rebase onto current `main` and push again if that happens; that is a genuine conflict, not a race to avoid. For `BACKLOG.md`/`DONE.md`/`BLOCKED.md` conflicts, KEEP BOTH SIDES — the file is a log, not code, and another lane's entry belongs there as much as yours. Only once you've confirmed the item is actually on `main` do you move it to `ralph/DONE.md` with its real commit SHA.

If your work is visual-affecting, run the blind `visual-judge` pass — but iterate render/critique/fix ENTIRELY IN YOUR OWN CHECKOUT and push once at the end. R9.4 pushed eight times for one three-round pass, ~36 minutes of CI, and that is the loop's largest avoidable cost.

Throwaways go on `scratch/**`, never `ralph/**`. You cannot delete a remote branch from a session, so anything you push is permanent unless it ships.

RELEASE YOUR LEASE BLOCK (both your area and your lane heartbeat) AND END. Owner directive, 2026-08-12: do NOT schedule a successor, ever, under any circumstance — no `send_later`, no self-resume. Pausing the Routines was found not to stop work, because a chained firing ignores the pause; this is the fix. The next item on this lane happens at the next scheduled fire, not sooner. Do not take a second item in this same firing either, even if it shares your area and you have context left — one item per firing, full stop.

Do not run Blender jobs in parallel; serial at `--size 512`.

Stop and report rather than improvising when a core design decision is needed — `CLAUDE.md` requires surfacing those, not deciding them. A blocked item is a correct outcome; a quietly redesigned game is not. Two constants: FIVE creatures ever with no storage beyond five, and `docs/GAME_DESIGN.md` §32 is a list of things deliberately NOT built.

Always stop at a task boundary, never mid-task — and never take a second item, see above.

---

## How to tell it worked

A healthy lane writes a lease block to `ralph/STATUS.md` on the `ralph-status`
branch **within a few minutes** of firing — before it does anything else.
`PROMPT.md` requires that ordering precisely so a broken lane is visible fast.

So: fire it, wait ten minutes, and look at that file. A new block means the repo
attached and the lane is working. No block and no `ralph/*` branch means the
session came up with nothing to read, which is the failure this file documents.
