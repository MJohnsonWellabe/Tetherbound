# Blocked

Items parked with a specific reason and what would clear them. A firing that
adds an entry here has done its job correctly — `CLAUDE.md` requires surfacing a
design decision rather than inventing one.

---

## ⛔ THE LOOP IS STOPPED — fired sessions cannot push

**Trigger-fired sessions have read-only GitHub access.** `git push` is rejected
by the git proxy with:

    MJohnsonWellabe/Tetherbound is not in this session's authorized repository set

A direct GitHub API call with the session's own `GITHUB_TOKEN` hits the same
proxy-level denial, and it points at an `add_repo` mechanism a fired session has
no tool to reach. Interactive sessions push fine; only the trigger-minted ones
are read-only.

**Pushing is the loop's only ship mechanism**, so this blocks the entire
backlog, not one item. The Routine is **paused** — an hourly firing that hits
this wall spends real tokens and lands nothing.

Both firings behaved correctly: they did the work, hit the wall, wrote it down,
and declined to schedule a successor that would fail identically. The second
also discarded its local branch rather than leave dangling state. That is the
right behaviour and it is why this was diagnosed in two runs rather than twenty.

**What it cost:** the first firing solved `R0.3.5` — three real bugs found and
fixed, verified 10/10 green — and the commits died with the container. The
diagnosis was recovered into `BACKLOG.md`; the code was not.

**Clears when** the repository is reattached to the Claude Code environment with
**write/push** access for trigger-fired sessions. If that is not configurable,
the cloud-Routine design cannot work and the loop has to move to a local host,
where push uses the owner's own credentials.

---

## Blocked on the owner

### `ASSET_LEDGER.md` licence claim is false
The ledger states "Everything currently in the build is CC0 1.0." It is not: the
Meshy-generated creatures and the Plumberry Plains pack are not CC0. The correct
wording depends on the owner's Meshy plan terms, which no agent can verify.

**Clears when:** the owner supplies the licence wording.

---

## Blocked on credits

*(nothing yet — R0.5 will add an entry here if the balance runs out mid-roster)*

Balance at last check: **375**. Retexturing ten winners costs ~300.

---

## Resolved — the key reaches the loop

The Meshy key is **carried in the Routine's own prompt**, so every fired session
has it without the owner doing anything. There is no tool to set an environment
variable on this environment, and the repository is the one place the key must
never go: GitHub history is permanent and secret scanning would likely revoke
the key on push.

Use it by prefixing the one command that needs it. Never write it to a file,
never echo it, never put it in a commit message, a manifest or a report.

If `meshy.py check` fails to authenticate, the key has been rotated — say so
here and stop the art tasks rather than guessing.

---

## Blocked on a play gate

*(nothing yet — the first is R0.10, the opening's fifteen minutes)*

---

## Design questions awaiting the owner

*(none open)*

Anything on `CLAUDE.md`'s flag list goes here rather than being decided:
dodge/block, party limit, weapons, type system, storage, story rewrites,
traversal philosophy, mandatory hunger/thirst, stronghold structure.
