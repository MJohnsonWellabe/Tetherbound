# Blocked

Items parked with a specific reason and what would clear them. A firing that
adds an entry here has done its job correctly — `CLAUDE.md` requires surfacing a
design decision rather than inventing one.

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
