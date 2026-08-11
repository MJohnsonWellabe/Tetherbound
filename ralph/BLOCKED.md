# Blocked

Items parked with a specific reason and what would clear them. A firing that
adds an entry here has done its job correctly — `CLAUDE.md` requires surfacing a
design decision rather than inventing one.

---

## ✅ RESOLVED — the loop can push again

**This entry is retracted as of the R0.3.5 fix.** The two earlier firings that
diagnosed read-only access were correct about what they saw, but the
environment has since been reattached with **write/push** access via a
persistent host session: `git push` to a new branch, and to `ralph-status`,
both succeeded and were verified (`ralph/R0.3.5` merged through the normal
CI → `ralph-merge.yml` path).

One residual gap: `git push --delete` (and the GitHub API's branch-delete)
still returns HTTP 403 at the proxy level, even though creating and pushing
branches works. Probe branches from the reattachment check could not be
deleted and, being plain docs commits, one of them (`ralph/PUSH_TEST.md`) went
green on CI and got auto-merged into `main` before this was noticed — cleaned
up in the same commit as this entry. **Future firings: do not create
throwaway probe branches** unless you also plan to leave them merged; there is
currently no way to delete a remote branch from a fired session.

**What the wall cost while it stood:** the first firing to hit it solved
`R0.3.5` — three real bugs found and fixed, verified 10/10 green — and the
commits died with the container. The diagnosis was recovered into
`BACKLOG.md`; the code was not, and was redone from that diagnosis once push
access returned.

---

## Blocked on the owner

### RB4 — ROG Ally freeze: on-device data now in, points at the Vulkan/Forward+ present path, not a slow compile
On-device data collected 2026-08-10/11 by the owner, directly on the Ally,
against the shipped release build. This changes the leading hypothesis.

**Boot log** (`user://boot_log.txt`, two separate launches ~25 minutes
apart, both hung): both runs write the identical phase sequence — autoload
ready, terrain node built, terrain data assigned, ground shader applied,
player placed, vegetation scattered (~16,700 props), settlement built —
ending on the SAME last line both times: `_ready complete, waiting for
first frame`. Each run took ~6 seconds to reach that line, with no visible
stall anywhere in the build sequence itself. Neither run ever wrote the
next line (`first frame presented`), which only fires after `await
get_tree().process_frame` returns.

**Task Manager, during the freeze**: the process shows as `Tetherbound (Not
Responding)`, ~1.4GB memory, but **0% CPU, 0% disk, 0% network** — not
climbing, not busy. Left for well over 10 minutes: **never resolves**.

Together this rules out the original leading hypothesis (a first-launch
shader/pipeline-compile stall) — a compile taking a long time would show
CPU or GPU load while it worked, and this shows neither. The evidence now
points at something in the render thread blocking on a call that never
returns — most likely a Vulkan/Forward+ present or pipeline-compile call
deadlocking against this specific integrated GPU's driver, between "the
scene is fully built" and "the engine presents its first frame."

Static inspection already ruled out several other suspects, so don't
re-check them: the shipped release build already exports `--export-release`,
not debug (`release.yml`); the Terrain3D GDExtension is staged correctly at
both the flat and `res://`-relative paths
(`tools/stage_gdextension_libs.sh`, fixed after an earlier bug that broke
exactly this); the export architecture is `x86_64`, matching the Ally's
Ryzen Z1; nothing forces exclusive fullscreen in `project.godot`.

**Next concrete step, on the owner**: launch with `--rendering-driver
opengl3` appended to the shortcut/exe target (bypasses Forward+/Vulkan
entirely, using the same Compatibility renderer `tools/survey.sh` already
uses for headless CI rendering). If it loads under OpenGL, that confirms a
Vulkan-driver-specific stall — actionable two ways: ship OpenGL/
Compatibility as the default renderer for this hardware class, or dig into
what specifically triggers the Vulkan-side hang. If it *also* hangs under
OpenGL, the render backend is cleared and the search moves elsewhere in
the render-thread startup path.

This needs a real Windows/Ally run, which CI cannot provide (same
limitation `smoke_menu.gd` already documents for mouse capture) — do not
guess-fix the Vulkan-stall hypothesis without the OpenGL test result
first.

**Clears when:** the owner reports whether `--rendering-driver opengl3`
loads successfully or also hangs.

### `ASSET_LEDGER.md` licence claim is false
The ledger states "Everything currently in the build is CC0 1.0." It is not: the
Meshy-generated creatures and the Plumberry Plains pack are not CC0. The correct
wording depends on the owner's Meshy plan terms, which no agent can verify.

**Clears when:** the owner supplies the licence wording.

---

## Blocked on credits

*(nothing yet)*

Balance at last check: **175**, after Reedwing's texture pass (confirmed
via `meshy.py check`, was 185 after Pipwing's). R0.6 is complete — no
more wild-species texture spends are needed. Next art-credit spend, if
any, depends on whatever R0.9+ actually needs (the opening scene wiring
is code, not art; nothing currently on the backlog obviously needs a
fresh Meshy generation).

---

## Resolved — the four bird species do not need `animate_bird.py`

**This entry is retracted.** The premise — "no `animate_bird.py` exists" —
was true but the conclusion drawn from it was wrong. `rig_bird.py`
(1546 lines) is not a bare rigging script the way
`rig_quadruped.py`/`rig_glider.py`/`rig_sitter.py` are: it authors all six
standard clips itself (`author_all()`), already proved end-to-end on
three winged test meshes per its own docstring, and its bone names
deliberately overlap `animate_quadruped.py`'s glider layout "so that
script still produces something sane if it is ever pointed at a bird."

The real bug was in `finish.py`'s `rig` subcommand: it called
`animate_quadruped.py` unconditionally after rigging, regardless of
`--kind`. For a bird this didn't just duplicate work — it would silently
re-detect the already-animated bird rig as a glider and overwrite
`rig_bird.py`'s bird-specific animation with generic glider animation,
including `animate_quadruped.py`'s documented faint-spin bug (root bone
yaw applied where the rig's local Y is world-up, so the creature spins on
the spot instead of toppling).

Fixed: `finish.py` now skips the `animate_quadruped.py` call when
`--kind` is `bird`, since `rig_bird.py` already produced the finished,
animated output. Proved on Galecrest, the first bird species shipped —
see `DONE.md`. **No further code work is needed for Duskhush, Pipwing, or
Reedwing** — the same `clean → texture → rig --kind bird → grade →
install` sequence used for every quadruped now works for birds too.

---

## Resolved — the key reaches a CRON firing, not a self-scheduled resume

The Meshy key is **carried in the cron Routine's own prompt**, so every
hourly-fired session has it without the owner doing anything. There is no
tool to set an environment variable on this environment, and the repository
is the one place the key must never go: GitHub history is permanent and
secret scanning would likely revoke the key on push. **A firing's own
`send_later` self-resume is not the cron Routine** — see the entry above,
found twice now — so do not expect the key there.

Use it by prefixing the one command that needs it. Never write it to a file,
never echo it, never put it in a commit message, a manifest or a report.

If `meshy.py check` fails to authenticate on a firing that SHOULD have the
key (i.e. a cron firing), the key has been rotated — say so here and stop the
art tasks rather than guessing.

---

## Play gates awaiting the owner — the loop does NOT wait here (D21)

The owner plays these whenever they can; their feedback comes back as new
backlog items. The loop keeps building past them.

- **R0.11** — play the NEW first day end to end (wake upstairs → Grandpa's
  gifts → choose and name a starter → the paths → harvest → a fight and a
  catch → camp before dark → day 2).

---

## Design questions awaiting the owner

### Creature and human art-pipeline cohesion — rework vs. replace?
Raised by the 2026-08-09 site-frames critique for the three starters alone
("three assets from three different store packs"); **R0.8.5's full blind
review of the whole roster confirms it's bigger than the starters** and adds
a second axis the earlier pass never saw because it had no frame with the
Warden and the trainer together:

- **Creatures**: Paddlenewt, Pipwing and Ripplet render in a glossier,
  big-eyed toy/gacha finish that doesn't match the painted-matte naturalism
  the rest of the roster shares (the moss-and-stone material language on
  Burrowback, Mosshell, Tuskroot and Terrapup is, per the blind critic,
  "the single best piece of cohesive art direction anywhere in this set" —
  which makes the mismatch on the other three more visible, not less).
- **Humans**: the trainer and Grandpa are flat-shaded and low-detail next
  to the Warden's fully painted, richly textured finish — called out as
  "the loudest single problem in the whole review" because the trainer is
  who the player looks at for the entire game, unlike a boss seen once.

Full record: `docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`. Whether
to rework the mismatched assets or replace them is an art-direction call
this evidence is for, not a call to make silently.

**Clears when:** the owner decides rework vs. replace (and for which
assets — the three creatures, the trainer/Grandpa pair, or both).

Anything on `CLAUDE.md`'s flag list goes here rather than being decided:
dodge/block, party limit, weapons, type system, storage, story rewrites,
traversal philosophy, mandatory hunger/thirst, stronghold structure.
