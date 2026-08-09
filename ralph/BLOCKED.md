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

### `ASSET_LEDGER.md` licence claim is false
The ledger states "Everything currently in the build is CC0 1.0." It is not: the
Meshy-generated creatures and the Plumberry Plains pack are not CC0. The correct
wording depends on the owner's Meshy plan terms, which no agent can verify.

**Clears when:** the owner supplies the licence wording.

---

## Blocked on credits

*(nothing yet)*

Balance at last check: **195**, after Duskhush's texture pass (confirmed
via `meshy.py check`, was 205 after Galecrest's). **Pipwing, Reedwing
each still need a full `clean` (free) then `texture` (~10 credits) pass**
— every R0.5-committed `textured/model.glb` is structurally unusable (see
`DONE.md`'s Tuskroot entry: R0.5 textured raw candidates directly,
skipping `clean`, so 50,000+ triangles against a 30,000 budget with
thousands of non-manifold edges). Confirmed true for Duskhush same as
Galecrest — budget ~20 credits total for the remaining two, leaving a
projected balance around 175.

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

## Blocked on a play gate

*(nothing yet — the first is R0.10, the opening's fifteen minutes)*

---

## Design questions awaiting the owner

*(none open)*

Anything on `CLAUDE.md`'s flag list goes here rather than being decided:
dodge/block, party limit, weapons, type system, storage, story rewrites,
traversal philosophy, mandatory hunger/thirst, stronghold structure.
