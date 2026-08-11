# The keyed Routine's prompt — "Ralph", the art lane

The loop runs on three Routines (`MANUAL.md`). This file holds the prompt for
the **one that carries the Meshy key**. `LANE_PROMPT.md` holds the other two.

## Can Ralph not just update itself?

No — asked and answered on 2026-08-11, and worth recording because it is the
obvious idea and it fails for three independent reasons:

1. **A fired session has no MCP tools**, so it cannot call `update_trigger` at
   all. This is the bootstrap: the tools it is missing are the tools it would
   need to add them.
2. **`update_trigger` cannot change `allowed_tools`.** The parameter does not
   exist — it takes `name`, `prompt`, `cron_expression`, `enabled`, `model`,
   `run_once_at`, and nothing else. There is no API path to this, for any
   caller.
3. **An agent may only update Routines it created**, and this one was created
   via the HTTP API.

**Only the Routines UI can fix the tools.** That part genuinely needs hands.

**The prompt half does not**, and that is the important half. The Routine
message tells every firing that `ralph/PROMPT.md` overrides it, so anything you
would want to change in the prompt can be committed to `PROMPT.md` instead and
takes effect on the very next firing with no UI at all. The `lane: art`
preference and the spend rules live there now for exactly that reason. Treat the
Routine prompt as a bootstrap and disk as the state.

## Why you would be reading this

The original "Ralph" Routine was created through the HTTP API on 2026-08-10 with
an explicit eight-tool allow list — `Bash, Read, Write, Edit, Glob, Grep,
WebFetch, WebSearch` — and **no `Task`, no `Skill`, no MCP tools**. That means it
cannot spawn a blind critic, cannot invoke `.claude/skills/visual-judge`, and
cannot schedule its own successor. See `MANUAL.md` for the full consequences;
the short version is that it cannot correctly complete most of the work now at
the top of the backlog.

**Recreating it in the Routines UI is the fix**, because a Routine created that
way gets the full default tool set. Delete the old one afterward so two keyed
Routines are never firing at once.

## Settings

| | |
|---|---|
| Name | `Ralph` |
| Repository | `MJohnsonWellabe/Tetherbound`, branch `main` |
| Schedule | hourly at **:49** |
| Tools | the UI default — confirm `Task` and `Skill` are among them |

## The key

**Line 5 below is a placeholder.** Replace `PASTE_KEY_HERE` with the real
`msy_…` value, which you can read off the old Routine's prompt in the UI before
deleting it.

**The key must never reach this repository.** GitHub history is permanent and
secret scanning would likely revoke it. That is why this file carries a
placeholder rather than the value, and why a firing is told to prefix only the
single command that needs it.

## The prompt

---

Ralph firing — the keyed lane.

Pull `main`, then re-read from disk. These change between firings and they, not your memory, are the state of the project: `ralph/PROMPT.md` (the standing instruction; it overrides this message), `ralph/BACKLOG.md`, `ralph/BLOCKED.md`, `ralph/conventions.md`, `CLAUDE.md`.

MESHY CREDENTIAL, art tasks only: MESHY_API_KEY='PASTE_KEY_HERE'
Prefix only the single command that needs it. Never write it to a file, echo it, or commit it.

YOU ARE THE ART LANE, and the only firing that can take items marked `lane: art`. Prefer them when one is available and its area is free — no other Routine can, so leaving one for later means leaving it forever. Everything else is fair game when no art item is ready.

Three Routines fire on staggered schedules and concurrent firings are the intended design, not a hazard. `ralph/PROMPT.md`'s "Claim a lease FIRST" section is the protocol and it changed on 2026-08-11 — read it properly rather than assuming you remember it:

- Leases live in `ralph/STATUS.md` on the `ralph-status` branch, ONE BLOCK PER LIVE FIRING.
- You stand down only when YOUR OWN `area:` is held. Another firing existing is NOT a reason to stop — that was the old behaviour and it is what lanes exist to stop.
- A lease is live if `updated` is under 40 minutes old, OR if the branch its `task` names has a commit in the last 40 minutes. Check the branch before reclaiming anything; a firing deep in a long render pass looks dead and is not.
- Stand down only if EVERY unblocked item's area is held. Say so plainly and end without scheduling a successor. That is a correct outcome.

BEFORE SPENDING A SINGLE CREDIT: the balance is 5000 and is no longer the constraint — owner-supplied reference art is. `D24` and `CLAUDE.md` forbid generating anything the owner has not supplied a reference board for in `docs/art/reference/`. If a task appears to need a new model and no board exists, that is a `BLOCKED.md` entry, not a spend. `D23` §20 additionally forbids creature regeneration at any balance; it was reaffirmed WITH 5000 credits available, so a healthy balance does not lift it. In-engine survey and screenshot renders need no key and are always available.

Take the topmost unblocked item whose area is free. `▶` play gates do NOT stop the loop (D21): make sure `BLOCKED.md`'s play-gate section lists it for the owner and take the next item below. The one exception is R9.5, the exit gate, where the loop correctly parks.

Branch `ralph/<task-id>`, build the smallest coherent version, and run ONLY the tests that item names — locally and headless, before you push. Batch 1–4 finished items onto one branch, never across areas and never a red item with a green one. Pushing the branch IS the ship action; no pull request, no self-merge. Then move each item to `ralph/DONE.md` with its real commit SHA, in its own commit, last.

If your work is visual-affecting, run the blind `visual-judge` pass — a real sub-agent that was never told what changed, not your own read of the frame. THERE IS NO ROUND CAP as of 2026-08-11: iterate while the critic names a NEW defect or `frame_stats` shows measured movement, and stop after two consecutive rounds with neither. Iterate render/critique/fix ENTIRELY IN YOUR OWN CHECKOUT and push once at the end — R9.4 pushed eight times for one three-round pass, ~36 minutes of CI, and that is the loop's largest avoidable cost.

Verify the ship by looking at `main`, not at CI. `ralph-merge.yml` is fast-forward only: if `main` moved while you worked it refuses and goes red even though your tests passed. Rebase onto current `main` and push again. For `BACKLOG.md`/`DONE.md`/`BLOCKED.md` conflicts, KEEP BOTH SIDES — the file is a log, not code, and another lane's entry belongs there as much as yours.

Throwaways go on `scratch/**`, never `ralph/**`. You cannot delete a remote branch from a session, so anything you push is permanent unless it ships.

Schedule your successor 2–3 minutes out once you have shipped and recorded, and release your lease block first so your own successor does not read your area as held. Do NOT chain if your remaining work is `lane: art` — a `send_later` self-resume does not inherit the key, which has been found twice; let the next cron firing take it.

Do not run Blender jobs in parallel; serial at `--size 512`.

Stop and report rather than improvising when: Meshy credits run out (record the exact balance and species reached in `BLOCKED.md`); or a core design decision is needed — `CLAUDE.md` requires surfacing those, not deciding them. A blocked item is a correct outcome; a quietly redesigned game is not. Two constants: FIVE creatures ever with no storage beyond five, and `docs/GAME_DESIGN.md` §32 is a list of things deliberately NOT built.

Keep going while unblocked work remains in your area and you have context. Always stop at a task boundary, never mid-task.

---

## Confirming it worked

Two checks, in order:

1. **Tools.** After recreating it, ask a session to read the Routine's stored
   config and confirm `Task` and `Skill` are in `allowed_tools`. This is the
   whole reason for recreating it, and it is checkable rather than assumed.
2. **It runs.** Within ~10 minutes of a firing, a new block appears in
   `ralph/STATUS.md` on the `ralph-status` branch. `PROMPT.md` makes claiming the
   lease the first action precisely so a broken Routine is visible fast.
