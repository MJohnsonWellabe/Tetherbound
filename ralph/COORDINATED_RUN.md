# Running Ralph from one coordinator session

**What this is.** An operating manual for driving the backlog from a single
Claude Code session that owns the queue and fans work out to lanes it launches,
watches and lands — instead of independent cron Routines firing blind. It was
written from a run on 2026-08-16/17 that landed 76 commits, cleared the owner's
entire ROG bug list, and built the Meadows corridor. It includes what went
wrong, because those parts are the ones worth reading twice.

It does not replace `ralph/PROMPT.md`. `PROMPT.md` tells a *lane* how to behave;
this tells a *coordinator* how to run them, and `PROMPT.md`'s own section on
which rules are suspended under a coordinator is the seam between the two.

---

## 0. Why this instead of Routines

Cron Routines are blind firings with no memory that coordinate only through a
lease file. That works, and it is the right shape when nobody is watching. Its
costs, measured on this repo:

- **Bookkeeping collisions.** `BACKLOG.md`, `DONE.md` and `BLOCKED.md` are where
  every concurrent ship in this project had been colliding.
- **No priority.** Every firing does its item well; nothing asks whether it is
  the *right* item.
- **Findings die.** A firing ends and everything it learned that is not in its
  diff goes with the container.

A coordinator fixes all three cheaply, and adds one thing a Routine cannot do:
it can look at CI, read *which job* failed, and decide.

**Do not run both at once.** Disable the Routines first, explicitly — do not
assume a stale `next_run_at` means paused.

---

## 1. Bootstrap, in order

1. **Read the repo before launching anything.** `CLAUDE.md`, `ralph/conventions.md`,
   `ralph/PROMPT.md`, the top of `ralph/BACKLOG.md`, and any handoff documents.
   Half an hour here saves a lane a night.
2. **Reconcile the backlog first, not last.** Check what has actually landed
   against `git log origin/main`. If the file has drifted, fix it before you
   dispatch, or you will send lanes at finished work. (We did this last. See §9.)
3. **Read `ralph/NOTES.md` on the `ralph-status` branch.** Live findings from
   previous runs.
4. **Pick lanes by file conflict, not by topic.** Two items that never touch the
   same file can run together whatever they are about; two UI items that both
   edit `tab_backpack.gd` cannot.

---

## 2. How many lanes

**Three to five. Not eight.**

The binding constraint is not agent capacity, it is CI. On this account roughly
**five GitHub Actions jobs run at once**, and one CI run is 19 jobs — so a single
run takes about four waves, and nine branches in flight means ~170 jobs against
5 slots. That is what strangles a run, and it looks exactly like "everything is
slow" when the lanes are in fact idle.

`ci.yml`'s own header claims splitting into 19 parallel jobs bounds wall-clock at
the slowest check. **That is false on this account.** Verify the real cap before
believing any throughput estimate — read a run's job list and count how many are
`in_progress` at once.

More lanes past that point make the queue longer, not the game better.

---

## 3. The lane brief

Launch each lane as its own remote session with the repo pinned explicitly:

```
source_url: https://github.com/<owner>/<repo>
source_revision: main
```

**Do not rely on repo inheritance.** We launched three lanes without
`source_url` and only one inherited a checkout. The other two correctly refused
to work — one replied *"fabricated task context detected; no Tetherbound repo
present"* — which is the right behaviour and cost twenty minutes anyway.

Every brief contains, without exception:

- **`date -u` first.** Agents will otherwise invent timestamps. One reported a
  duration that was wrong by 38 minutes and I relayed it as fact.
- **The item, verbatim**, plus the spec sections that govern it.
- **A file exclusion list** — which files other lanes hold. This, not the lease
  file, is what actually prevents collisions.
- **The queue after this item**, so the lane self-chains instead of idling.
  "When it is done, write your notes and pull the next one yourself."
- **Do not edit `BACKLOG.md` / `DONE.md` / `BLOCKED.md`.** The coordinator owns them.
- **Do not claim leases.** See §8.
- **Do not merge to `main` by hand.** Push the branch; CI and `ralph-merge` ship it.
- **Known-red CI jobs**, by name, with "if it is red on that job alone it is not
  your diff — never weaken anything to clear it."
- **The repo's own traps** (§10).
- **Write to `ralph/NOTES.md` before finishing.** See §4.
- **Report at your estimate and again at ~1.5x.** See §7.

---

## 4. `ralph/NOTES.md` — the highest-value thing here

A shared notepad on the `ralph-status` branch, which merges into nothing and
runs no CI, so writing to it is free and cannot conflict with anyone's work.

**It goes both ways.**

- **Coordinator writes down**: anything learned after a lane launched that it
  could not know — a red CI job, a branch already carrying half its task.
- **Lanes write up**: what they found that is worth knowing and does not belong
  in a diff. Especially **what they noticed and ruled out of scope.**

This is not documentation hygiene. On its first night it produced the single
largest finding of the run: a lane finishing four UI items wrote up, unprompted,
that `ui_accept` had no joypad binding at all — meaning **no focused button in a
controller-first game could be pressed with a controller**, and the build menu
had never been operable. That would have died in a closed container behind a
twelve-word status summary.

The habit compounds. A lane told to stop mid-item wrote its *design* into the
notes instead of pushing half-built code; the next lane started from that design
rather than from scratch.

---

## 5. Landing work: bundle it

The default path is one branch at a time: CI, then `ralph-merge` fast-forwards
`main` and rebases the rest. With several lanes that degrades badly — every
landing invalidates every other waiting branch.

**When three or more branches are green, bundle them:**

```
git checkout -B integrate-N origin/main
for b in ...; do git merge --no-edit origin/ralph/$b; done   # resolve as needed
git push origin integrate-N:ralph/integrate-N
```

One CI run and one fast-forward instead of N of each. At a 5-job cap this is not
a nicety — 19 jobs versus ~209.

**The objection, and its answer.** A bundle can be sunk by one unrelated red
job, taking healthy branches with it. That happened on the first attempt. The
answer is `rerun_failed_jobs` on the single failing job — with re-run available,
a bundle is *fewer* dice rolls than N separate branches, not more.

**Rules that make bundling safe:**

- Only bundle branches whose **current tip** has a completed green run. Check;
  do not assume from a stale reading.
- Resolve conflicts by **understanding both sides**. Almost every conflict in a
  parallel run is two lanes doing correct, complementary work at the same lines
  — "keep both" is usually right, and "pick a side" usually loses something.
- After resolving, **check for what keep-both breaks**: duplicate declarations,
  two of the same node created, a constant left used-but-undefined.
- If `main` moves under the bundle by a docs-only commit, merge it in and push
  again — the `changes` job will diff against the already-green tip, see only
  `ralph/` paths, and skip all 19 verify jobs. A ~1 minute run, not 20.

---

## 6. Reading CI

**Never conclude a branch is broken from the run's conclusion. Read which job
failed.** This is the single most repeated lesson of the run:

- A real game bug in creature pathing was called "a marginal test" — by me —
  because I read the conclusion and not the evidence.
- Two healthy branches were nearly excluded from a bundle on a stale red.
- A branch sat unlanded for 100 minutes because its only CI run was
  **cancelled**, and a cancelled run is neither failed (so nothing flags it) nor
  green (so the merge workflow correctly refuses it).

Rules:

- One job red, eighteen green, and that job unrelated to the diff → re-run the
  job. **This is legitimate only when the failure is provably in a different
  subsystem.** "Flaky" is not a diagnosis.
- Six jobs red across different subsystems → that is real. Read all six.
- A branch with **no completed run** is not the same as a branch that has not
  been pushed. Check for cancellations.

---

## 7. Checkpoints, not kill times

Kill times sound disciplined and do nothing. Across a full night **not one lane
was killed**; the one furthest past its estimate was *extended*, correctly,
because it had stopped chasing a flaky test and started finding a real bug.

What works is the lane reporting in:

> At your **estimate**, report where you are — even mid-task. At your
> **checkpoint** (~1.5x), report again and say whether you should continue.

The coordinator decides from that report. **Going silent is the failure, not
going long.**

**Watch for the stall pattern.** A session that ends its turn while a background
render or test batch runs may never be woken when that work finishes. It shows
as `IDLE` with a status like "batch in flight". Poke it. Two lanes were parked
this way and were only caught because the owner asked a question.

---

## 8. Leases: don't

`ralph/STATUS.md` on `ralph-status` is load-bearing for **uncoordinated** firings
— there it is the only thing between two firings and the same branch.

Under a coordinator it is not, and maintaining it is actively harmful. We wrote
one lease per lane while every lane had been told not to claim: a guard that
could not fail, running unnoticed inside the tooling of a repo whose reviews keep
catching exactly that defect. Worse, a stale block written "for visibility" makes
the next uncoordinated firing avoid an area nobody holds.

**So: no leases under a coordinator, from anyone.** File exclusions in the brief
do the real work. Leave `STATUS.md` empty rather than decorative.

---

## 9. Bookkeeping

The coordinator owns `BACKLOG.md`, `DONE.md` and `BLOCKED.md` and writes them in
its own commits on `ralph/bookkeeping-N` branches. Paths under `ralph/` classify
as docs-only, so those runs skip every verify job and ship in about a minute.

**Reconcile continuously, not at the end.** We landed 76 commits and marked
almost none, so the backlog showed 55 open items of which 35 were finished —
`OPS1`'s own failure mode happening while `OPS1` sat open. A backlog nobody can
trust is worse than no backlog, and a fresh session reading it would have sent
lanes at completed work.

**The test for "shipped":**

> An item is done when its content is an **ancestor of `main`**.

Not a green branch. Not a lane's report. Not a branch ref that looks right — one
branch's ref had moved and an ancestor check called it missing while its code was
demonstrably in the tree. When in doubt, check the tree: does `main` contain the
line the change was supposed to add?

---

## 10. The traps that cost us time

Repo-specific; put the relevant ones in every brief.

- **`InputEventAction` never travels the `InputMap`.** A test driving input with
  action events asserts far less than it reads, and will pass on code where a
  controller cannot do the thing at all.
- **Terrain3D setters are no-ops out of the tree.** `collision_shape_size` had
  been silently stuck at the 16 m default for months while the code and its own
  comment believed it was 256.
- **Terrain3D clamps silently.** `collision_radius` to [16,256] step 16,
  `collision_shape_size` to [8,64] step 8. Assert the value you **got**, never
  the one you set.
- **`Dictionary.get(key, default)` evaluates its default eagerly.** This cost
  289 µs on every height query and 185 seconds of every boot.
- **Never pass `--headless` to anything that renders.** Check file counts, not
  exit codes — Terrain3D aborts on shutdown by design (`D06`), and the first
  `--import` exits non-zero by design (`D05`).
- **Serialise Godot runs.** Two concurrent headless runs corrupt each other's
  script loading — a missing-script error for a file that is present on disk.
- **The unit suite can take 9 minutes under load** and looks hung. It is not.
- **Every smoke test boots the whole world.** Budget accordingly, and treat boot
  cost as a first-class target: it is the multiplier on every test, every render
  and every CI job.
- **A route is not proven walkable by sampling the heightfield.**
  `ground_height_at()` lied to three separate investigations of the same bug.
  Walk a body and read what the physics engine reports.
- **A keep-both merge needs a duplicate CALL-SITE check, not just a duplicate
  declaration check.** Resolving a conflict by keeping both sides and then
  grepping for duplicate `func`/`var`/`const` feels thorough and is not: it
  cannot see two calls to the same function. That is exactly how a second
  `vegetation.build()` — with a signature two refactors out of date — shipped in
  `integrate-3` and errored on every boot until a lane found it. After any
  keep-both resolution, diff the merged file against **both** parents and read
  what you added, rather than checking a symbol list.
- **Porting a stale branch means re-deriving its constants, not copying them.**
  Every number on an old branch was calibrated against the world that existed
  when it was written. `OF15`'s wedge detector was mechanically correct and
  still failed on landing, because its exclusion was a 200 m *radius* around a
  disc that no longer exists, and because it had no slope exclusion — it never
  needed one on gentle ground, and the corridor is made of deliberately
  unclimbable faces. Same class of bug as `smoke_boss.gd`'s `BARRIER_LIMIT_M`
  (18 m from config arithmetic, 28.3 m when finally measured) and
  `tether_relay`'s `deck_y` (an absolute height calibrated against the old
  site's ground). When you port, list the branch's constants and ask what each
  one was measured against.

---

## 11. Priority

**The owner's stated priority gets a lane that never yields.**

This is the mistake that cost the most. Over one night the run landed eight good
items while the thing the owner had said mattered most sat untouched for four
hours — because each lane surfaced a real prerequisite and each prerequisite was
allowed to go first. Every one was genuinely necessary. None of them was what was
asked for.

- A discovered prerequisite **does not inherit** the priority of what it blocks.
  It gets its own lane, in parallel.
- Check whether it blocks **the deliverable** or something adjacent. Collision
  streaming was treated as blocking the corridor bake; it is needed to *play* the
  corridor, not to *bake* it, and the build order saying otherwise was written
  for one person working alone.
- **Re-read the reasoning, not just the ordering.**

---

## 12. Review

Two kinds, neither optional, both cheap:

- **Blind code review** of the diff by an agent told nothing about the intent.
- **Blind visual pass** for anything a player sees — the repo's own
  `.claude/skills/visual-judge`, told nothing about what changed or what answer
  is wanted, iterated while it names a *new* defect. Judge frames at 40%
  downscale as the 7-inch handheld proxy.

Across one night this caught a light regression measured as a whole-room
brightening, an unpressable glyph on a handheld, a guard that could not fail, a
diagnosis that was wrong, and a test that passed on reverted code.

**And tell lanes the honest answer is the deliverable.** They will then volunteer
things like *"my own test is weaker than it looks"*, *"I reverted this rather
than ship something that looked done"*, *"I disproved the premise of my own
item"*. That culture produced more value than any process rule here.

---

## 13. A checklist to start from

```
[ ] Disable cron Routines explicitly
[ ] Read CLAUDE.md, conventions.md, PROMPT.md, BACKLOG.md top, NOTES.md
[ ] Reconcile BACKLOG against `git log origin/main`
[ ] Measure the real CI job cap
[ ] Pick 3-5 lanes by file conflict; write exclusions into each brief
[ ] Launch with source_url pinned; self-chaining queues
[ ] Arm a ~30 min self check-in that: lands green branches (bundling at 3+),
    reads NOTES.md and files findings, pokes IDLE-with-work-in-flight lanes,
    refills finished lanes, republishes the dashboard, and re-arms itself
[ ] Keep the owner's priority in a lane that never yields
```

The check-in re-arming itself is what keeps the run alive across quiet stretches.
Write into it, explicitly, that it should ignore any older self-note saying the
run is closed — a stale instruction from an earlier wind-down will otherwise stop
a run the owner has since asked to continue.
