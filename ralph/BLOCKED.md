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

Balance at last check: **215**, after Brooktail's texture pass — the sixth
and last of the wild quadrupeds now redone (Tuskroot, Meadowhart,
Burrowback, Paddlenewt, Mosshell, Brooktail; see `DONE.md`). **The four
birds** (Galecrest, Duskhush, Pipwing, Reedwing) still need the same redo
once `animate_bird.py` unblocks them — budget ~10 credits each, same as
R0.5 estimated, not on top of R0.5's spend since R0.5's texture charge was
wasted, not saved.

---

## Blocked: R0.6's four remaining species need `animate_bird.py`

`finish.py rig`'s animate step is hardcoded to call `animate_quadruped.py`
regardless of `--kind`, and no `animate_bird.py` exists. All six wild
quadrupeds are now finished (Tuskroot, Meadowhart, Burrowback, Paddlenewt,
Mosshell, Brooktail) — this is the actual next blocker for R0.6, not a
credits or key problem. Whoever reaches Galecrest needs to write
`animate_bird.py` (or generalise `animate_quadruped.py` to emit believable
bird-appropriate clips) before `rig_bird.py`'s output can move past the rig
step.

**Clears when:** `animate_bird.py` exists and produces the roster's six
standard clips (idle, walk, run, attack, hit, faint) for a bird armature.

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
