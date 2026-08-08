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

## Blocked on the key being reachable

### R0.5 and every later art task — `MESHY_API_KEY` is not in the environment

The owner has an active key and has decided not to rotate it. That is settled.
The problem is a different one: the key lives in a chat transcript, and a fired
Ralph session starts fresh with only the repository and the environment. It
cannot read the conversation, so it has no way to obtain the key.

**Clears when:** `MESHY_API_KEY` is set as an environment variable on the Claude
Code environment. See `ralph/MANUAL.md`.

**Check before assuming this is still true** — `tools/art_pipeline/meshy.py check`
prints the balance and never prints the key. If it answers, this entry is stale;
delete it and carry on with `R0.5`.

**This blocks art only.** `R0.4` (blind critique) needs no credits and no key.
Everything from `R1.1` onward — the rename, gathering, building, save/load,
combat, progression — is unaffected. Do not stall the loop on this; skip the art
items and keep working down the backlog.

---

## Blocked on a play gate

*(nothing yet — the first is R0.10, the opening's fifteen minutes)*

---

## Design questions awaiting the owner

*(none open)*

Anything on `CLAUDE.md`'s flag list goes here rather than being decided:
dodge/block, party limit, weapons, type system, storage, story rewrites,
traversal philosophy, mandatory hunger/thirst, stronghold structure.
