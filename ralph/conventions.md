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
- `GAME_DESIGN.md` §32 is a list of things deliberately NOT built. It is a
  boundary, not a backlog.

## Shipping

- Branch `ralph/<task-id>` → push → CI → **auto-merge on green**.
- CI always runs: clean-checkout import with no script errors, and the Windows
  export. Both are cheap and catch the failures that make the project unopenable.
- Run **only the tests your backlog item names**, plus `tests/smoke_art.gd` for
  anything touching creature data or models.
- Full suite on: the rename, any autoload or save-format change, and nightly on
  `main`.
- Every push to `main` publishes a Windows build. That is what the owner plays.

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

## Writing style

The codebase's comments explain **why**, name the failure they prevent, and are
honest about what is not built. Match that. Do not write marketing prose, do not
add emoji, and do not leave a comment that only restates the line below it.

## Secrets

`MESHY_API_KEY` comes from the environment and from nowhere else. Never write it
to a file, never echo it, never put it in a manifest or a commit.
