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

Balance at last check: **235**, after Paddlenewt's redo-texture pass
(Tuskroot, Meadowhart, Burrowback already redone; see `DONE.md`). **Six
species still need the same redo** (Mosshell, Brooktail, then the four birds
once `animate_bird.py` unblocks them) before R0.6 can rig them — budget ~10
credits each, same as R0.5 estimated, not on top of R0.5's spend since R0.5's
texture charge was wasted, not saved.

---

## Blocked on this firing: no `MESHY_API_KEY` in the environment (again)

**Same shape as the earlier gap this session, now understood rather than
surprising: `MESHY_API_KEY` only arrives when a firing is cron-fired with the
credential in its prompt.** A self-scheduled `send_later` resume (used to
continue past a firing's own stop-at-a-task-boundary point) does not carry
it, because the credential is never something one firing should write into a
message for a later one to read back — that would put it somewhere outside
"the environment and nowhere else". So this is not a rotation, not a balance
problem (last known balance 235, untouched this firing), and not actually
unexpected once you notice which kind of firing this is — but it is still a
real block on continuing R0.6 with `finish.py texture`, and `meshy.py check`
confirms it the same way it did last time: key simply unset.

**Mosshell's `clean` step is done** (Blender only, no key needed): raw
candidate `b`, 54,396 → 28,000 tris, manifold, at
`assets_raw/mosshell/build/clean.glb`. Not committed, will not survive this
container, and does not need to — `clean` takes under a minute to redo. R0.4's
report flagged a possible topology issue (a thin protrusion near the
hindquarters that might read as an errant tail/spike) as worth a check before
this species is considered finished; `inspect_glb.py`'s structural report
came back clean of anything specific to that (the usual pre-texture/pre-rig
findings only — no material, disconnected verts within normal range, no
armature yet), and a visual turntable render to actually look at the
silhouette failed in this container (`libEGL.so.1` missing, a headless
rendering gap unrelated to Meshy). So the concern is neither confirmed nor
ruled out here — flag it for whoever finishes texturing and rigging this
species to look at once there is a textured, renderable model to look at.

**This blocks Mosshell (fifth of ten) and everything below it in R0.6's
order** (Brooktail, then the four birds already blocked on
`animate_bird.py`). Doing something else instead: `docs/ASSET_LEDGER.md` has
no per-creature provenance row yet for any of the four R0.6 species shipped
so far (Tuskroot, Meadowhart, Burrowback, Paddlenewt) despite R0.8 asking for
exactly that, and it needs neither credits nor the key — so that is this
firing's actual work.

**Clears when:** a cron-fired firing (the kind whose prompt names
`MESHY_API_KEY` directly) picks up Mosshell and runs `finish.py texture`.

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
