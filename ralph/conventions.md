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
triggers on it, which is a full Godot import, test run and Windows export —
about eight minutes — and `ralph-merge.yml` then fast-forwards `main` if it goes
green. There is no "just parking this here" on that prefix.

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
- Branch `ralph/<task-id>` → push → CI → **`.github/workflows/ralph-merge.yml`
  fast-forwards main on green.** You do not open a pull request and you do not
  merge anything yourself: a fired session has no GitHub MCP tools and no `gh`
  CLI, so pushing the branch *is* the ship action.
- The merge is **fast-forward only**. If main moved while you worked, the
  workflow fails loudly and you rebase `ralph/<task-id>` on main and push again.
  Never resolve that by force-pushing main.
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
   **Cap this at three rounds.** A visual defect that survives three
   real attempts is not a quick fix, and burning a whole firing's budget
   looping on one asset is worse than stopping and saying so.
4. If it still fails after three rounds, do not mark the task done and do not
   keep silently iterating. Record it plainly — what was tried, what the
   critic still says is wrong, and why — either as a `BLOCKED.md` entry (if
   it needs a decision only the owner can make, e.g. an asset that needs
   replacing rather than tuning) or as a clearly-labelled remainder item in
   `BACKLOG.md`, the same pattern R7.1-remainder already uses.

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
