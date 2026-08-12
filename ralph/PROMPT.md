# Ralph — the standing instruction

You are one firing of an autonomous build loop on **Tetherbound**. You have no
memory of previous firings. Everything you need is on disk.

## Read first, every time

1. `CLAUDE.md` — the hard rules. They override everything here.
2. `ralph/conventions.md` — how work is done and shipped in this repo.
3. `ralph/BACKLOG.md` — the ordered task list. **This is the state of the
   project.** It is ~83 KB and you do not need all of it: **read from the top
   until you have found your item, then stop.** The open phases are at the top
   by design and everything below Phase 1 is months away.
4. `ralph/BLOCKED.md` — what is parked, and why.
5. `docs/HANDOFF.md` — where the project actually is.
6. `docs/decisions/D23-the-meadows-is-the-first-game.md` and
   `D24-one-nature-family-one-village-family.md` — both short, and between them
   they change what several older docs mean. D24 also sets two rules that will
   stop a task dead if you learn them late: **no Meshy generation without an
   owner-supplied reference board**, and **one nature / village / prop family**.

**Do not read `ralph/DONE.md` end to end.** It is ~100 KB of history, it grows
every firing, and it is a reference, not a briefing. `grep` it for the specific
task id or symptom you are chasing. Reading it whole is most of the ~9.5-minute
cold start, and it is the least useful of the files that cost it.

Read `docs/GAME_DESIGN.md`, `docs/MEADOWS_VERTICAL_SLICE.md` and
`docs/MEADOWS_PROGRESSION_SPEC.md` for the sections your task touches. Do not
read them end to end; they are long and most of them will not be about your
task.

**The spec wins over the older two where they disagree** (D23) — it is the
owner's later word, written after playing the published build. D23 names the
two carve-outs where an older rule still governs, and they are both load-
bearing: the Biome 2 rule, and `GAME_DESIGN.md` §33's criteria numbering.

## Before you pick anything: is the pipeline healthy?

Nothing else matters if work cannot ship. Every firing, first:

1. **Check `main`'s latest CI run.** If it is red, **fixing that is your task**
   — ahead of everything in the backlog. A red `main` means the build the owner
   downloads is the last green one, and every branch after it inherits the
   problem.
2. **Check the branch the previous firing pushed.** If its CI failed, it never
   merged and its work is sitting unshipped. Finish it on the same branch before
   starting anything new — do not abandon it and open a fresh one, or the
   backlog will quietly fill with orphaned branches.
   **Green CI is not the same as shipped.** Check the *auto-merge* run too, and
   verify the ship by looking at `main`, never by looking at CI.

   **A "cannot fast-forward" failure now FIXES ITSELF. Do not race it.**
   Changed 2026-08-11: `ralph-merge.yml` rebases the branch onto `main` itself,
   force-pushes it and dispatches a fresh CI run, which ships on green. So when
   you see that failure, the correct action is usually **to wait one CI cycle
   and look at `main` again** — roughly five minutes.

   Rebasing by hand at the same moment is a new way to collide: you and the
   workflow both force-push the same branch, and whichever lands second
   discards the other's work. Only step in when the run says the rebase
   **conflicted** — that one still stops dead and genuinely needs you.

   The old advice, which was right before this and is wrong now: *"the fix is
   always the same, rebase onto current main and push again."* Two branches
   were stranded before the workflow could do it for you; that is what the
   change removes.
   **A branch CI run is ~5.2 minutes with essentially no queue time.** Older
   notes in this repo say eight or nine; they are stale, and the loop spent a
   while optimising against a number 80% too high. Five minutes is cheap enough
   that pushing to *find out* whether something works is a reasonable move; it
   is not cheap enough to do eight times for one visual pass, which is what the
   local-iteration rule below exists to stop.
3. **If a test fails on your branch that has nothing to do with your change**,
   that is a flake, and a flake is a real defect here: `ralph-merge.yml` only
   ships green branches, so an intermittent test rejects healthy work at random.
   Say so in your report and add it to the backlog rather than re-running until
   it passes.
   **Before you push a whole new CI run to confirm that suspicion, reproduce
   the ONE named test locally, headless, in your own checkout** —
   `godot --headless --path . --script tests/<the_test>.gd`, a few seconds to
   a minute. A full verify run is several minutes for the same yes/no answer.
   Only escalate to a real CI re-run if the local repro also flakes, or
   won't reproduce at all and you need CI's exact environment to be sure.

Report pipeline health in every completion message, even when it is fine — the
owner gets a push notification for each firing, and "CI green, shipped R2.1" is
the one line that tells them the loop is alive and working.

## One live firing per lane — claim that before anything else

Owner directive, 2026-08-12, reversing part of the "multiple firings is the
design" call below. In practice, more than three concurrent firings kept
happening anyway — self-chained successors and the hourly cron backstop both
fire independently, with nothing stopping them from being alive at once, and
this repo's own "Realistically this supports two or three concurrent lanes,
not five" line (further down) was already naming the exact failure mode that
then happened. Every extra concurrent writer multiplies `BACKLOG.md`/
`DONE.md` conflicts directly — that is most of what has been slow.

**Zero live firings for the same lane at once, full stop.** This is checked
*before* the area-lease section below, using the identical mechanism —
`tools/ralph_status.py`, the same liveness rule, your lane name as a reserved
pseudo-`area`:

```
python3 tools/ralph_status.py claim --file ralph/STATUS.md \
  --firing <your-firing-id> --session <your-session-id> --task lane-heartbeat \
  --area lane-<b|c|keyed> --state started
```

- **Claim succeeds** (pushed, or the existing `lane-<you>` block was dead by
  the same 40-minute/branch-check test used for real areas): you're the only
  live firing on this lane. Proceed to the area-lease section, and refresh
  this same heartbeat on the same cadence as any other lease you hold.
- **Claim fails** — `lane-<you>` is live: **stand down immediately.** Do not
  read the backlog, do not claim a work area — the live firing already
  covers that. Say so and end. This is a correct, successful outcome, not a
  failure.

Release this lease exactly like any other, as your very last act before you
end — see "Releasing your leases" below. `lane-<b|c|keyed>` is a reserved
name, never a real work area — do not put backlog items under it.

## Claim a lease FIRST — before reading the backlog, before anything else

**Multiple firings running at once, across DIFFERENT lanes, is still the
design** — that part is not reversed. Three Routines fire on staggered
schedules, and the hourly cron fires whether or not the previous firing
finished. So the lease no longer asks "is anyone working?" — it asks **"is
anyone working on MY AREA?"**

Every backlog item carries an `area:` field. Two firings on different areas do
not collide and should both run. Two firings on the same area do collide, badly:
they take the same item, create the same `ralph/<task-id>` branch, and race.

The leases live in `ralph/STATUS.md` on the **`ralph-status` branch** — a branch
nothing merges, which no CI triggers on, and which is separate from `main` so
heartbeats never move the target under an in-flight task branch. There is one
block per **live** firing.

1. `git fetch origin ralph-status` and read every lease block.
2. **Work out which areas are held.** A lease holds its area if `state` is
   `started` or `working` **and** it is live by the test in step 3.
3. **Liveness — the branch is the signal, the clock is the backstop.** In order:
   - **`updated` under 40 minutes old → live.** Stay off that area.
   - **`updated` 40+ minutes old → check the branch** its `task` names:
     `git fetch origin ralph/<task-id> && git log -1 --format=%cI FETCH_HEAD`.
     **A commit on that branch in the last 40 minutes means the firing is alive
     and just slow** — a long render pass, a deep instrumentation loop — and the
     area is still held no matter what the timestamp says. This is not
     hypothetical: on `RB3` a firing was ~50 test-runs deep into finding a real
     bug, hadn't touched its heartbeat, and the next firing reclaimed the lease
     and nearly duplicated the fix.
   - **Stale heartbeat AND no branch, or a branch as stale as the lease → dead.**
     The area is yours. Overwrite that block.

   The expiry was 90 minutes and is now 40, because 90 was measured costing
   real time: two dead firings in one five-hour window burned **~2 hours** of
   stand-down apiece waiting out a corpse. The branch check above is what makes
   the shorter clock safe — it, not the timestamp, is the real liveness test.
4. **Claim your area** with `tools/ralph_status.py`, not by hand-editing the
   file. `LP6` found `STATUS.md` repeatedly growing past its own
   `## END LEASES` marker because a firing edited by eye, misjudged where the
   end was, and appended there — a mistake the script cannot make, because it
   always computes the insertion point from the marker line itself, never from
   "the bottom of the file". The script itself lives on `main`, but the file
   it edits lives on `ralph-status`, which never merges from `main` — so once
   you are sitting on a `ralph-status` checkout, pull the script's *content*
   across rather than expecting it in the tree: `git show origin/main:tools/
   ralph_status.py > /tmp/ralph_status.py`, then run `python3
   /tmp/ralph_status.py ...` against `ralph/STATUS.md` as it exists on
   `ralph-status`.
   ```
   python3 tools/ralph_status.py claim --file ralph/STATUS.md \
     --firing <your-firing-id> --session <your-session-id> --task <TASK-ID> \
     --area <area> [--area <area2> ...] --state started
   ```
   If you are overwriting a block you have confirmed dead (the liveness test
   above), release it first — `python3 tools/ralph_status.py release --file
   ralph/STATUS.md --firing <dead-firing> --task <dead-task>` — then claim.
   Use `heartbeat` for `state: working` updates and their `note`, and
   `release` (never leaving a `shipped` corpse) when you finish — see below.
   Run `python3 tools/ralph_status.py check --file ralph/STATUS.md` before
   every push to `ralph-status`; a non-zero exit means something (a script
   bug, a manual edit, a merge) put lease content past the marker again, and
   that is worth fixing before you push it forward. Commit and push to
   `ralph-status`.
   - **If the push is rejected**, someone claimed in the same instant — a plain
     `git push` is the lock, because it only succeeds if your parent is still
     the branch tip. Re-fetch, re-read, and pick again. **Do not stand down for
     a rejection alone**: their claim may be on a different area, in which case
     yours is still free and you should re-claim it.
5. **Stand down only when every non-blocked item's area is held.** That is a
   correct, successful outcome — say so and end. Standing down because *some
   other firing exists* is the old behaviour and is now wrong; it is what
   parallel lanes exist to stop.

### Areas, and which of them actually conflict

The `area:` field is a claim on **files and rebakes**, not on subject matter.
Current areas: `story`, `terrain`, `vegetation`, `village`, `npc`, `art`,
`ui`, `lighting`, `visual`, `assets`, `perf`, `loop`.

Two honest cautions, because the naming makes them look safer than they are:

- **`terrain` is one lane, not several.** `SA3` and `SA4` both edit
  `terrain_playground.json` and both need a terrain rebake. Same for `EV4` and
  `EV5`. One at a time.
- **`vegetation` and `terrain` overlap at the rebake.** If your vegetation task
  needs `build_playground_terrain.gd` re-run, claim `terrain` as a second area
  in your block rather than discovering the conflict in a merge.

Realistically this supports **two or three concurrent lanes, not five.** Do not
force a third if the only remaining item shares an area with a live one.

### `lane: art` — only one Routine can do these

An item marked `lane: art` needs the Meshy API key. **The key reaches a firing
only through the cron Routine's own prompt**, and the two additional lane
Routines were deliberately created without it, because the key must never reach
the repository — GitHub history is permanent and secret scanning would revoke
it. So:

- **If you have the key** (test with `meshy.py check`) — **prefer `lane: art`
  items** whenever one is available and its area is free. Not merely "may take":
  no other firing can take them, so an art item you skip is an art item nobody
  picks up until the next keyed firing an hour later. Take other work only when
  no art item is ready.
- **If you do not**, skip every `lane: art` item as though its area were held,
  and take the next one. Do not report this as blocked — it is not, it is just
  not yours. Do not pivot to ledger busywork either; one firing did exactly that
  after losing the key, and it produced nothing anyone wanted.

Note that in-engine survey and screenshot renders need **no** key. Only Meshy
generation and retexture do.

### `model: fable` items — dispatch, don't author

Owner directive, 2026-08-12. Unlike every other `model:` value, `fable` is not
advisory ("the cheapest tier that can do the job") — it names a real ceiling.
These items are ceiling-setting narrative or aesthetic authorship: world-
building, story beats, dialogue, or a "does this actually look right" visual-
direction judgment call. A weaker first pass on this class of work becomes the
ceiling nothing later can rescue — this is not theoretical, it already
happened once in this exact backlog: `R9.4` ran an uncapped, multi-round blind-
critique loop against an already-built scene, converged, and both critics
still ranked "needs art that is not in the build" first. The entry's own
conclusion was that it had "run out of things tuning could reach." Tuning a
weak first draft cannot substitute for authoring the right one.

**Any lane that reaches the topmost unblocked `model: fable` item does not do
that item's creative work in its own session.** Instead:

1. Claim the lease as you normally would (same area rules as any other item).
2. Spawn a single subagent at `model: fable` (the Agent tool's `model`
   parameter) and hand it the item's full context: the `### ID` entry itself,
   the relevant section(s) of `docs/GAME_DESIGN.md` /
   `docs/MEADOWS_PROGRESSION_SPEC.md` / the art bible it cites, and this
   file's usual "smallest coherent version" instruction. That subagent owns
   the actual authorship — the world text, the dialogue, the aesthetic
   judgment calls.
3. **The Fable subagent should itself delegate purely mechanical sub-steps —
   wiring the data/dialogue into the existing systems, writing or running
   tests, git bookkeeping, asset staging — to `model: opus` subagents of its
   own**, rather than spending its own context on work that doesn't need
   taste. It stays the author and the judge; it is not the one running
   `godot --headless --import`.
4. Ship exactly as any other item: test, push to `ralph/<task-id>`, record in
   `DONE.md`.

**If Agent-tool subagent spawning isn't available in your checkout** (this has
happened before — see the `R7.2` blind-pass entry in `DONE.md`), say so
honestly in your bookkeeping the same way that entry did, rather than quietly
doing the work yourself at the wrong tier. A `model: fable` item done at a
lower tier and reported as done is worse than one left open with an honest
note, because it consumes the one shot this class of work gets before the
ceiling is baked in.

### Before spending a single credit

The balance is **5000** and is no longer the constraint. **Owner-supplied
reference art is.** Both rules are in `CLAUDE.md` and `D24`, and both will stop
a task dead if you learn them late:

- **No generation without a reference board** in `docs/art/reference/`. If a
  task appears to need a new model and no board exists, that is a `BLOCKED.md`
  entry, not a spend. The standing list of what the owner still has to draw is
  already there.
- **`D23` §20 forbids creature regeneration at any balance.** It was reaffirmed
  *with* 5000 credits available, which is exactly what proves it was never a
  budget rule. Creatures and humans are rework-only, permanently.

Older material in this repo tells you to spend down and park when credits run
out. That was written at a balance of 175 and is now the least likely reason
you will ever stop.

### This file overrides the Routine message that started you

Said plainly because it is load-bearing and easy to miss: **the prompt in the
Routine is a bootstrap, not the state.** It is edited by hand, rarely, and goes
stale between firings — the keyed Routine's own prompt predates the per-area
leases, batching, local critic iteration and the removed round cap, and still
describes one global lease.

So when the Routine message and this file disagree, **this file wins**, and the
same goes for `CLAUDE.md`, `conventions.md` and `BACKLOG.md`. Anything worth
telling every future firing belongs on disk, where it can be changed by a commit
rather than by a human editing a Routine.

## Then keep the heartbeat moving

The owner cannot see you: a firing that thinks quietly for twenty minutes looks
exactly like one that died on boot. So update the lease block as you go with
`tools/ralph_status.py heartbeat` —
`state: working` with a `note` saying what you are **actually doing right now**
— and finish with `shipped`, `blocked` or `play-gate`. Push each update to
`ralph-status`.

Never push heartbeats to `main`. Work reaches `main` only through
`ralph/<task-id>` and CI.

The first firing ran for 65 minutes, spent 139k output tokens and produced no
branch, no commit and no `DONE.md` entry — and nobody could tell whether it was
working or dead the entire time. That is what this section exists to prevent.
**If you are about to spend a long time on something, say so in the `note`
first.**

**If a single step is going to run past ~20-30 minutes wall-clock** — a render
pass, a deep instrumentation loop re-running one test dozens of times, a long
Blender job — **commit a heartbeat update when you start it**, not only when
it finishes. The lease's 90-minute expiry exists to reclaim genuinely dead
firings, and it cannot tell "still working, just slow" from "died an hour
ago" unless you tell it. This is not hypothetical: `RB3`'s investigation ran
long enough in real time that the heartbeat went stale past 90 minutes while
the firing was still actively working it, and the next hour's firing
correctly-by-the-letter reclaimed the lease and started the same task again.
It resolved cleanly only because the original firing shipped first — that was
luck, not the protocol working as intended.

## The loop

1. **Pick** the topmost item in `BACKLOG.md` that is not blocked **and whose
   `area:` no live lease holds**. **`▶` play
   gates do not stop the loop** — owner directive, 2026-08-09 (D21): the owner
   plays in parallel and their feedback arrives as new backlog items, so when
   the topmost item is a `▶` gate, leave it in place for the owner, make sure
   `BLOCKED.md`'s play-gate section lists it, and take the next item below it.
   For `▶`-marked work items (R9.1–R9.4), do everything automatable inside
   them and record what genuinely needs hands on the Ally, then continue.
   The one exception is **R9.5, the exit gate**: only the owner can call
   `GAME_DESIGN.md` §33, and `CLAUDE.md` forbids Biome 2 work until it
   passes — when nothing remains but R9.5, the loop is correctly done and
   parks.
2. **Branch**: `ralph/<task-id>`, e.g. `ralph/R2.1`.
3. **Do the work.** Smallest coherent version that delivers the stated outcome.
4. **Test** exactly what the task's `tests:` field names. Not the full suite —
   that is deliberate, the owner asked for it, and running everything on every
   task wastes hours over a backlog this size. **Run them locally and headless
   before you push.** CI is the gate, not the test runner.
5. **Ship exactly one item.** Push the branch with that single item's commit
   (plus its bookkeeping commit, last). CI runs the import check, your named
   tests and the Windows export. **Auto-merge on green.** Never merge red.
6. **Confirm it actually landed on `main` before doing anything else.**
   Watch `main`, not CI — green CI is not the same as shipped. Wait for
   `ralph-merge.yml`'s auto-merge to fast-forward `main`; if it hits a
   genuine conflict, resolve it yourself (the bookkeeping rule below) rather
   than ending on an unconfirmed push. See "One item, confirmed landed, no
   successor" below for why this step exists.
7. **Record**: move the item from `BACKLOG.md` to `DONE.md` with its commit SHA
   and one line on what shipped. Commit that too — and read the bookkeeping
   warning below first, because these three files are where lanes collide.
8. **Release your leases and end.** Release your area lease and lane
   heartbeat (see "One live firing per lane" above), say what you shipped
   and that it's confirmed on `main`, and stop. **Do not schedule a
   successor.** The next unit of work happens on the next Routine fire —
   see "One item, confirmed landed, no successor" below.

### One item, confirmed landed, no successor

**Owner directive, 2026-08-12, reversing the 2026-08-11 batching and
chaining directives below.** Pausing all three Routines was found not to
actually stop work: a firing kept producing fresh sessions for **4.5+
hours** after every Routine was disabled, because batching ("take the next
item too... ship 1–4 per branch") and self-scheduled successors
(`send_later`, 2–3 minutes out) together let one firing turn into an
indefinite chain that has no relationship to whether its parent Routine is
even enabled. A `send_later` self-resume is not a Routine fire, so pausing
the Routine literally cannot reach it. That is the failure this section
exists to close.

**One item. One branch. One push. Confirmed on `main`. Then stop —
no successor, ever, regardless of what else is unblocked.**

- Do not take a second item in the same firing, even if it shares your area
  and you have context left. The old "keep going while unblocked work
  remains" instruction is gone; it is what turned pauses into no-ops.
- Do not schedule anything with `send_later` or equivalent. Release your
  area lease and lane heartbeat, report what shipped, and end.
- The next item on your lane happens at the next Routine fire — the keyed
  cron at `:49`, Lane B at `:05`, Lane C at `:13` — not sooner. With three
  lanes staggered ~20 minutes apart, aggregate idle time between *some*
  lane doing something is small even though any single lane waits up to an
  hour for its own next turn.

**This is a deliberate throughput trade, made with full knowledge of the
cost**: less work happens per hour than batching/chaining produced. In
exchange, disabling a Routine now actually means nothing more happens —
there is no other mechanism left that can start new work. That guarantee is
worth more than the throughput, after tonight.

**"One live firing per lane" (above) stays in effect unchanged** — it is a
correct safety net independent of chaining, e.g. if a firing runs long and
the next cron tick arrives while it is still working.

### Iterate the visual critic LOCALLY, then push once

**This is the single biggest time saving available and it costs nothing.**

Measured: a non-visual task pushes once (~5 min of CI). A three-round blind
visual pass pushed **eight times — ~36 minutes of CI** — because each critic
round shipped before the next one ran. About a third of the backlog is
visual-affecting, and **nearly every item in Phases -0.9 through -0.55 is.**

The blind pass in `conventions.md` is still required. What changes is where it
runs: **render, critique, fix, re-render and re-critique entirely in your own
checkout, and push only the final state.** The critic does not need your work to
be on `main` to look at a frame; it needs a PNG.

**This matters more now that the round cap is gone.** Owner directive,
2026-08-11: there is no three-round limit — iterate while the critic names a
**new** defect or `frame_stats` shows **measured movement**, and stop after two
consecutive rounds with neither. `conventions.md` has the full rule and is
strict about what does not count as improvement. A pass that can now run six or
eight rounds would be six or eight CI runs under the old habit of pushing each
one; locally it is still a single push.

Push mid-pass only if you are about to run out of context and want the partial
work preserved.

### The bookkeeping files are the real hotspot

`BACKLOG.md`, `DONE.md` and `BLOCKED.md` are edited by **every** firing, which
makes them the one place parallel lanes reliably conflict — 10% of merges
already fail on fast-forward without any of this.

**Rebase, never merge, for bookkeeping.** When your push is rejected or the
auto-merge refuses:

```
git fetch origin main
git rebase origin/main        # your code commits replay cleanly; only the
                              # bookkeeping commit will conflict
```

Then fix the conflict by **keeping both sides** — another lane's `DONE.md` entry
and yours both belong there. This is the one conflict class where "accept both"
is always correct, because the file is a log, not code.

To make that conflict smaller: **put your bookkeeping in its own commit, last**,
and never reflow or reorder parts of these files you did not touch. A whitespace
tidy across `BACKLOG.md` turns a three-line conflict into a whole-file one.

## When you cannot proceed

Move the item to `BLOCKED.md` with a specific reason and what would unblock it,
then take the next item. Block — do not improvise — when:

- A **core design decision** is needed. `CLAUDE.md` names the list: dodge/block,
  party limit, weapons, type system, storage, story rewrites, traversal
  philosophy, mandatory hunger/thirst, stronghold structure. Surfacing it is
  required; inventing it is forbidden.
- **Meshy credits run out.** Record the exact balance and the species reached.
- The task needs something only the owner can provide (a licence term, a key).
  (A `▶` play gate above it is NOT a blocker — D21; the loop continues past
  gates and the owner plays in parallel.)

A blocked item is a good outcome. A quietly redesigned game is not.

## Releasing your leases

**Releasing means deleting your block from `ralph/STATUS.md`, not setting it
to `shipped`.** `STATUS.md` used to offer `shipped` as an equally-valid
alternative to deleting, every firing took the easier option, and the file
grew to 53 undeleted blocks in six hours, unreadable at a glance even though
nothing was actually colliding. Delete the block with `python3
tools/ralph_status.py release --file ralph/STATUS.md --firing <your-firing-id>
--task <TASK-ID>` for both your area lease and your lane heartbeat; if you
want a record that the task shipped, that's what `DONE.md` is for.

Do this whether you shipped, are blocking the item, or are standing down
because every unblocked item's area is already held — release before you
end, always. See "One item, confirmed landed, no successor" above: nothing
gets scheduled after this, ever.

## Honesty rules

- Never claim a test passed that you did not run. Paste the real counts.
- Never mark an item done that is partly done. Split it and be explicit.
- If a previous firing left something broken, fixing it is your task, and it
  goes at the top of the backlog.
- If you discover work that is not on the backlog, **add it to the backlog**.
  Do not silently grow the task you are on.
