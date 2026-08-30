# Conventions — restated for a session with no memory

`CLAUDE.md` is authoritative. This file exists because a fresh Ralph firing has
no conversation history, and the mistakes below have all been made at least once
on this project already.

## The hard rules, which no task may break

- **Five creatures, ever.** No storage beyond five, in any form, for any reason.
  A "storage container" build piece stores *items*, never creatures.
- The human **never fights**. No trainer weapons.
- Combat is **real-time and piloted** — you play as your creature. No shields,
  no dodge.
- **Trainer-owned creatures cannot be caught.**
- No hunting or butchering.
- Food gives **buffs**. There is no starvation-death meter and never will be.
- Slot/stack inventory. **No carry-weight system.**
- Multiple death satchels persist.
- **An evolved creature is always larger than what it evolved from** (`D17`,
  enforced by `tests/test_evolution_links.gd`).
- **No Biome 2 work** until Meadows passes its exit gate (`GAME_DESIGN.md` §33).
  The spec's reconnection payoff is a **view of** the next biome across a
  seam, never a place you can walk into — D23's carve-out, and the one hard
  rule the Meadows chapter comes closest to breaking.
- **No new creature meshes or Meshy generations for the Meadows** (spec §20,
  D23). Separate two creatures that read alike with `grade.py`'s palette path,
  not a regeneration. This forecloses `R4.5`'s "generate Tuskroot fresh"
  fallback; that item is now verify-or-graft-or-block. The owner reaffirmed
  this on 2026-08-11 **with 5000 credits in the account** — it was never a
  budget rule, so a healthy balance does not lift it.
- **No generation without an owner-supplied reference sheet.** Credits stopped
  being the constraint on 2026-08-11; reference art is. If a task appears to
  need a new model and no board exists in `docs/art/reference/`, that is a
  `BLOCKED.md` entry, not a spend. `BLOCKED.md` carries the standing list of
  what the owner still has to draw.
- **One nature family, one village family, one prop family** (D24). An asset
  that joins no existing family does not land, however good its store page
  looks. Meshy is reserved for Team Tether hero objects.
- **Human NPCs reuse the trainer, Grandpa and Warden rigs**, differentiated
  **per material** (spec §21). `art.json`'s `tint` key is a single multiply
  over every surface, which is the exact failure §21 names — fine for R7.2's
  three villagers, not enough for a cast of a dozen.
- `GAME_DESIGN.md` §32 is a list of things deliberately NOT built. It is a
  boundary, not a backlog. `MEADOWS_PROGRESSION_SPEC.md` §19 is a second such
  list, for the chapter.

## Branch naming — `ralph/**` means "ship this"

**Anything pushed to a `ralph/**` branch is a shipping request.** `ci.yml`
triggers on it, which is a full Godot import and test run. There is no "just
parking this here" on that prefix.

The branch does not merge on its own any more — see **Shipping** below; a green
`ralph/**` branch waits for a dispatched consolidation run. But it still costs
a full CI run and still leaves a permanent branch behind, so the rule against
pushing throwaways under this prefix is unchanged.

**CI takes about 17 minutes, not the ~5 this file used to claim.** Measured
2026-08-15 on real `ralph/**` runs: the twelve checks are now separate parallel
jobs, so wall time is bounded by the slowest single check rather than their sum
— `smoke_traversal.gd` alone is ~6 minutes. `ci.yml`'s own header carries the
full measurement.

The corrected number matters in both directions. Five minutes is cheap enough
that a push to find out whether something works is reasonable. It is not cheap
enough to spend eight times on one visual pass, which is what a three-round
blind critique cost before rounds were required to run locally.

So a throwaway — a capability probe, a scratch experiment, a diff you want to
look at — must **not** be named `ralph/anything`. Use `scratch/<whatever>`,
which no workflow watches.

Two capability probes were pushed as `ralph/push-capability-test` and
`ralph/sonnet-host-check`. Each burned a full eight-minute CI run to validate a
one-line text file, and each asked the merge workflow to put that file on
`main`. They were only refused because they could not fast-forward — luck, not
design. A probe branched from a current `main` would have shipped its junk.

**Branches cannot be deleted from a session.** `git push --delete` and
`git push origin :branch` both fail at the git proxy; only GitHub Actions can
remove a branch, which is why shipped branches disappear and abandoned ones do
not. Assume anything you push is permanent unless it ships. That is another
reason not to push throwaways at all.

## Shipping

- **Never push to `main` directly.** Work reaches `main` only through
  `ralph/<task-id>` and CI; heartbeats go to the `ralph-status` branch. Pushing
  to `main` mid-firing moves the target under an in-flight task branch and
  forces a rebase for no reason — the coordinator did exactly that once and
  caused it.
- Branch `ralph/<task-id>` → push → CI. **Pushing is no longer the ship
  action.** Both `ralph-merge.yml` and `ralph-sweep.yml` are now
  `on: workflow_dispatch` only — merge's own header states it plainly:
  "Manual consolidation is now the sole path to main... never start it from
  branch CI." A green `ralph/**` branch therefore sits there until somebody
  dispatches a consolidation run. Nothing lands by itself.

  This file told every session the opposite until 2026-08-22, and a session
  that believes it will report work as shipped, watch CI go green, and never
  notice `main` did not move. Check `git log origin/main`, not the CI badge.
- **Who dispatches.** A session holding GitHub Actions tools (the MCP
  `actions_run_trigger`, or `gh`) dispatches `ralph-sweep.yml` against `main`;
  it takes no inputs and sweeps every green `ralph/**` branch. A lane without
  those tools pushes its branch, says so plainly in its report, and leaves
  consolidation to whoever is coordinating. Under a coordinator, integration
  is the coordinator's job — do not leave green branches unswept.
- The merge is **fast-forward only**. If main moved while you worked, the
  consolidation fails loudly and you rebase `ralph/<task-id>` on main and push
  again. Never resolve that by force-pushing main.

### Match branches into ONE consolidation branch before spending CI

**Do not sweep green branches one at a time when several are queued.** Merge the
compatible ones into a single `ralph/CONSOLIDATE-*` branch, run CI once, sweep
once. This is not a style preference; sweeping serially is self-defeating, and
the mechanism is in this repo's own tooling:

- `tools/ci/ship_branch.sh` ships a branch only when `origin/main` is already an
  ancestor of its tip (`git merge-base --is-ancestor origin/main "$SHA"`).
- Every sweep moves `main`. So the moment one branch lands, every other branch
  fails that test.
- A branch that then goes green is **rebased and force-pushed** by the next
  sweep, which cancels its CI run and rewrites history under any live lane.

So N queued branches cost N full CI rounds plus a rebase round each, not N
rounds. **Measured 2026-08-26: a full run is ~40 minutes** — about 16 minutes
queueing for runners plus ~22 minutes for `verify-core-verb-shard`, which is the
long pole and which no amount of unit-test sharding shortens (run 32926498498:
jobs created 03:28:31, core-verb started 03:45:02 and ended 04:06:51). Four
branches swept serially is most of a working day; one consolidation branch is
forty minutes.

**Probe compatibility first — it costs seconds, not a CI run:**

```
git checkout -B probe origin/main
for b in <branches>; do
  git merge --no-edit "origin/$b" >/dev/null 2>&1
  git diff --name-only --diff-filter=U | wc -l   # conflict count
  git merge --abort 2>/dev/null
done
```

Merge them in ascending conflict order and push once.

### Save CI for the commit you actually want verified

Owner directive, 2026-08-30. A consolidation is worth a full 55-job run. A WIP
checkpoint is not, and when ten lanes each push three of them, the consolidation
starves behind them.

**Put `[skip ci]` in the commit message of every WIP or checkpoint push.** Push
freely — pushing is how a lane survives its own container dying, and that safety
is why WIP pushes exist. Just do not spend a CI round on a commit whose results
you are not going to read. Drop the marker on the commit you want verified.

Measured the night this rule was written: `ralph/LAND-0830G` sat 43 minutes in
`queued` without dispatching a single job while lane WIP runs executed ahead of
it. Cancelling four lane runs freed the queue; the consolidation still had to be
re-triggered, because a run stuck in `queued` does not recover on its own — see
below.

**A run stuck in `queued` is not a slow run.** If a newer run on another branch
is `in_progress` while yours has not started a single job, yours is stuck, not
waiting. Cancel it and re-trigger with a fresh push; re-running does not help a
run that never dispatched.

**What does NOT belong in a consolidation.** A branch whose conflict is
*generated state* rather than source. Measured the same day: `ralph/WORLD-GRASS`
and `ralph/GRASS-FIELD` each merge onto `main` with **zero** conflicts, but
against each other they conflict on **257** `data/scatter/**` files, because the
two carry different bakes (725,949 vs 479,881 placements). Resolving that is a
re-bake plus a config decision — `"groundmat"` has to join
`suppress_scatter_layers` in `data/config/grass_field.json`, or both systems
dress the same ground (`ralph/reports/GRASS_HANDOVER_2026-08-26.md` §1). Land
that kind of branch on its own, against a settled `main`, with the re-bake in the
same commit so `data/scatter/playground/manifest.json`'s fingerprint stays valid.

**Two traps worth naming, both paid for on 2026-08-26:**

- A branch more than `MAX_BEHIND` (20) commits behind `main` is silently skipped
  by the sweep as stale (`.github/workflows/ralph-sweep.yml:89`), and
  `MAX_BEHIND` is **not** exposed as a dispatch input. One 20-commit landing put
  three live branches past the cap at once. Merge `main` forward before expecting
  a sweep to look at a branch.
- Merge `main` forward, do not rebase, whenever a lane is live on the branch: a
  merge needs no force-push, keeps the lane's checkout valid, and still satisfies
  `ship_branch.sh`'s ancestor test.
- If CI is red, the branch simply does not ship. Fix it on the same branch.
- CI always runs: clean-checkout import with no script errors, and the Windows
  export. Both are cheap and catch the failures that make the project unopenable.
- Run **only the tests your backlog item names**, plus `tests/smoke_art.gd` for
  anything touching creature data or models.
- Full suite on: the rename, any autoload or save-format change.
- **A shipped branch publishes a Windows build. That is what the owner plays** —
  but not because pushing `main` triggers it. `ralph-merge.yml` pushes with the
  default `GITHUB_TOKEN`, and GitHub refuses to raise workflow events from that
  token, so `release.yml`'s `on: push` never fires for a Ralph ship. It fired
  only when a human merged a pull request. The loop ran twelve hours and
  twenty-five commits publishing nothing while the download link looked current,
  serving a build with none of the roster and none of the opening in it.
  `ralph-merge.yml` now dispatches `release.yml` explicitly after a successful
  fast-forward. **Check the release asset's timestamp, not the merge, when you
  want to know what the owner can actually play.**
- **`ralph/DONE.md`'s single insertion point is a real collision under
  concurrency, not a hypothetical.** Every branch's bookkeeping commit inserts
  its new entry right after the file's 4-line header, so two branches shipping
  in the same window collide there on rebase — a genuine, unresolvable-by-bot
  merge conflict, not the usual clean auto-rebase. Confirmed 2026-08-12: one
  `ralph-sweep.yml` run hit this identical conflict on three separate branches
  at once (`R2.3`, `SA7-remainder`, `menu-json-stray-refs`), each stopped dead
  with "a human or a firing has to resolve it." The fix is easy once you know
  to look for it — `git rebase origin/main`, keep both `##` entries in the
  conflicted block (yours after the one already there), `git add`, `git
  rebase --continue` — but a firing that doesn't check job logs when a branch
  stops landing can burn 30–60 minutes re-dispatching the sweep and rebasing
  by hand before finding it, because the sweep's own summary line just says
  "conflicts with main," not what the conflict is or that it's this one,
  extremely common shape. `mcp__github__get_job_logs` (or the run's own
  `::group::<branch>` log) shows the real reason; don't assume a stuck branch
  is bad code without checking.

## Testing traps already paid for

- **UI focus navigation cannot be tested with `Input.action_press`.** It needs
  `Input.parse_input_event`. Send both — `tests/smoke_menu.gd` shows the pattern.
  A poll-only test reports a working menu while the stick moves nothing.
- **Run smoke tests headless.** Under xvfb + software GL they take 25× longer
  and flake under load.
- A test that passes because the feature is absent is worse than no test. Assert
  the thing exists, then assert it behaves.
- `assert_true(x or not x)` shipped a real bug on this project for weeks. If an
  assertion cannot fail, it is not a test.

## Art pipeline traps already paid for

- **Re-baking an asset mid-session does not reach a capture until you
  re-import.** A `--script` capture run loads the IMPORTED form out of
  `.godot/`; overwriting the `.glb` on disk leaves that cache alone, so the
  frames come back pixel-identical to the asset you just replaced and read as
  "the re-key changed nothing". Paid for once on OP21-24's chop clip, where a
  whole re-key round was judged against the previous bake. Run `godot
  --headless --path . --import` between the bake and the capture, every time.

- **`--headless` HANGS FOREVER with `--rendering-driver opengl3`. This is the
  single most expensive trap in this repo.** Verified 2026-08-22 both ways on a
  bare `ColorRect` with no project scenes and no autoloads: with `--headless`
  the process prints its first line and then sits in silence until killed — no
  error, no crash, no partial output, exit 124/143 from `timeout`. Drop
  `--headless`, keep `xvfb-run` for the virtual display, and the identical
  script writes its PNG and exits 0 in under a second.

  **Correct invocation for any capture:**

      xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path . \
        --rendering-driver opengl3 --resolution 1280x800 --script tools/<capture>.gd

  Note `--headless` is still correct and fast for **tests**, which render
  nothing. It is specifically the combination of `--headless` with a real
  rendering driver that hangs.

  What this cost on 2026-08-22 alone: four LOD capture attempts (one running 43
  minutes), several map captures, and two HUD captures — all abandoned as
  "contention" or "the world is too slow to build." None of that was true. The
  world builds fine; one lane got through the full Meadows stand-up, 129,723
  scattered props and a 240-frame settle in about 50 seconds on an idle box.
  The hang is always in the render step and is unrelated to scene weight.

  It also leaves **zombie processes**: a hung capture keeps running after its
  lane gives up, so a session that removes the worktree leaves a Godot process
  pinned to a deleted directory burning CPU. Three such orphans were found
  running 33-57 minutes, which then produced real contention and made the
  original misdiagnosis look correct. Before pruning a worktree, check:

      for pid in $(pgrep -f "godot --headless"); do echo "$pid $(readlink /proc/$pid/cwd)"; done

  and `kill -9` anything whose cwd reads "(deleted)".

  `tools/capture_diag_minimal.gd` is a 120-second smoke test for exactly this:
  if it cannot write a PNG, stop and fix the invocation before blaming the
  capture script, the scene, or the box.


- **A fresh container has no `.godot/` import cache and no Blender/Godot.**
  `tools/art_pipeline/setup.sh all` fetches both; `godot --headless --path .
  --import` builds the import cache once (needed before `tools/survey.sh` or
  any script-driven capture — without it, resources fail to load and
  viewpoints silently render flat/empty instead of erroring).
- **`libEGL.so.1` missing breaks both Godot's OpenGL renderer and Blender's
  EEVEE.** `apt-get install -y libegl1 libegl-mesa0 mesa-vulkan-drivers`
  fixes it — but run `apt-get update` FIRST if the package index is stale
  (404s on `libegl-mesa0`/`mesa-vulkan-drivers` are the tell). A stale index
  aborts the WHOLE `apt-get install` transaction, including packages that
  would have installed fine — `libegl1` silently did not get installed this
  way once, and Blender kept aborting with the same "cannot open shared
  object file" error even though the install command had reported no error
  for `libegl1` specifically. Verify with `dpkg -l | grep libegl1` if
  turntable renders keep aborting after installing what looks like the
  right packages. Ephemeral container — re-run each firing, it is not a
  standing blocker.
- **State the signature feature in CAPITALS and first**, or the generator drops it.
- **Generate heads separately** where a face carries the character — a
  whole-figure pass at 30k polys cannot resolve an eye socket.
- The shared negative prompt list is a **shape** ban list. Before adding a term,
  check no species is supposed to have that shape. `DROP_FOR_SPECIES` in
  `meshy.py` exists because it banned a deer's long legs, a deer's saddle and an
  otter's paddle tail — all canon signatures.
- **There is no stray Icosphere** in any model. A 42-vertex sphere seen on
  import is invented by Blender's glTF importer.
- **Do not run Blender renders in parallel.** Ten concurrent turntables on this
  box drove load to 47, OOM-killed Blender, and pushed frames to 5 minutes each.
  Serial at `--size 512` renders the whole roster in about 20 minutes.
- Preview-tier Meshy models come back **untextured** (zero materials). Colour
  cannot be judged until retexture.
- Godot's import cache does not travel between worktrees. After merging art, run
  an editor import pass, then `git checkout project.godot` — that pass strips
  the file's documentation comments.

## Visual-affecting work needs a blind pass, not a look

**Owner directive, 2026-08-10.** A task counts as visual-affecting if it adds
or changes anything a player can see: a 3D model or its materials, a terrain
feature (a signpost, a landmark, a scatter density change), lighting, or UI
art. The signposts and stronghold silhouette that shipped in R7.1 were only
confirmed by the same firing rendering a frame and looking at it — the owner
played the result and said plainly it doesn't look good. That is the gap this
closes.

Before marking a visual-affecting task done:

1. Render representative frames of the actual change (the tools under
   `tools/` — `survey.gd`, `capture_site_shots.gd`, `preview_creatures.gd` —
   already exist for this; use the one that fits, or a small purpose-built
   capture the way `diagnose_frame.gd`'s own header recommends).
2. Run `.claude/skills/visual-judge` against them — the actual blind critic,
   not the firing's own read of the frame. It has no knowledge of what
   changed and no stake in the answer being yes.
3. If it fails: fix the specific defects named, re-render, re-critique.
   **Keep going while it is still improving.** There is no round cap —
   owner directive, 2026-08-11, replacing the three-round cap this file
   carried before.

   **The stopping rule is convergence, not a count.** A round counts as
   improvement if EITHER is true:
   - the critic names a **new** defect it had not named before, or
   - `tools/frame_stats.py` shows **measured movement** on an axis the
     critique is about (saturation, luminance, colour variety).

   **Stop after two consecutive rounds with neither.** Two, not one — a
   single flat round is often a fix that has not landed yet, and stopping
   there would have cut R9.4's own round 3 short.

   Reordered defects, differently-worded versions of the same defect, and
   "still not fixed" are **not** improvement. Neither is movement on an axis
   nobody complained about. Be strict here; the whole point is to detect a
   wall rather than to keep finding reasons to run again.
4. When it converges without passing, do not mark the task done and do not
   keep silently iterating. Record it plainly — what was tried, what the
   critic still says is wrong, and why — either as a `BLOCKED.md` entry (if
   it needs a decision only the owner can make, e.g. an asset that needs
   replacing rather than tuning) or as a clearly-labelled remainder item in
   `BACKLOG.md`, the same pattern R7.1-remainder already uses.

   **State the round count and what the last two rounds failed to move.**
   "Converged after 5 rounds; rounds 4 and 5 named no new defect and moved
   saturation 0.004" is a useful record. "Still not right" is not.

**Why the cap went, and what removing it does not buy.** The cap was the wrong
instrument: it stopped tasks that were still converging and wasted rounds on
tasks that were not. But do not expect uncapped iteration to make things look
right on its own — **R9.4 already ran uncapped, four rounds, four blind
critics**, moved every measurable axis, and both critics still ranked *"needs
art that is not in the build"* first. It had not stopped early; it had run out
of things tuning could reach. That is the wall this stopping rule is designed to
detect quickly, and hitting it is a `BLOCKED.md` entry or an `EV`-item
dependency, never a reason to render the same frame a tenth time.

**One hard budget guard remains.** If you are running low on context, stop at
the current round, record the state, and let the next firing continue — a
half-finished pass that reported honestly is fine; a firing that dies mid-render
having shipped nothing is not.

**Run every round in your own checkout and push once at the end.** The critic
needs a PNG, not a merged branch. R9.4's three-round pass pushed eight times and
spent ~36 minutes of CI to reach a state one push would have expressed — and
about a third of the backlog is visual-affecting, so that multiplier is the
loop's largest avoidable cost. Push mid-pass only to preserve partial work when
you are running out of context.

R9.4's own no-cap override is no longer a special case — it is now how every
visual-affecting task runs.

This is slower than shipping on a green CI run — rendering under the headless
renderer costs real minutes per frame, which is exactly why CI itself was sped
up to skip the export tail on branches. That cost is the point: it is cheaper
than shipping something the owner has to notice is ugly and ask for by hand.

## Writing style

The codebase's comments explain **why**, name the failure they prevent, and are
honest about what is not built. Match that. Do not write marketing prose, do not
add emoji, and do not leave a comment that only restates the line below it.

## Secrets

`MESHY_API_KEY` comes from the environment and from nowhere else. Never write it
to a file, never echo it, never put it in a manifest or a commit.
