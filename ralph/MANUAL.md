# Manual tasks — only the owner can do these

The loop cannot do any of these. Each one blocks something specific.

## Done

- ~~**Let GitHub Actions write to the repository.**~~ Done — `Settings → Actions
  → General → Workflow permissions` is on **Read and write**, so
  `.github/workflows/ralph-merge.yml` can fast-forward `main`.
- ~~**Merge the setup pull request.**~~ Done — PR #2 landed at `3d60db6`.

## Before any art task can run — THE ONE THING STILL OPEN

### 1. Put `MESHY_API_KEY` in the environment

**This is not the same as rotating it.** The owner has decided not to rotate the
key, which is their call and closes that question. But the key currently exists
only in a chat transcript, and **a fired Ralph session cannot read the
conversation** — it starts fresh with nothing but the repository and the
environment. So the key still has to be *placed* somewhere a fresh session can
reach, and the environment is the only such place: it must never be written to a
file, because files get committed.

Set `MESHY_API_KEY` as an environment variable on the Claude Code environment
(`env_01JcoSxnn6SYsHdxGPGCQ8yV`).

**What breaks without it:** the loop runs fine through `R0.4`, the blind
critique, which needs no credits. It then hard-stops at `R0.5` (retexture) and
parks every art task. The non-art backlog — the rename, gathering, building,
save/load — is unaffected and will keep moving, so this is a partial block, not
a stopped loop.

### 4. Top up Meshy credits when `BLOCKED.md` says so
Balance was **375**. Retexturing the ten winners costs about **300**. Per the
owner's instruction the loop spends down, parks the art tasks with the exact
balance and species reached, and carries on with non-art work rather than
stopping.

## Ongoing

### 5. Play the game at each `▶` gate
`ralph/BACKLOG.md` marks them. `GAME_DESIGN.md` §33's exit criteria are entirely
subjective — "is repeated combat enjoyable, not merely functional", "would you
voluntarily keep playing". No amount of green CI substitutes, and the bible says
so directly. The loop parks at a gate and will not build past it.

Each push to `main` publishes a Windows build at
`/releases/download/latest/Tetherbound-windows.zip` — **by tag**. The
`/releases/latest/download/` form 404s because the release is a prerelease.

### 6. Supply the licence wording for `ASSET_LEDGER.md`
It claims "Everything currently in the build is CC0 1.0." That is false and was
false before this backlog existed: the Meshy-generated creatures and the
Plumberry pack are not CC0. The right wording depends on Meshy plan terms no
agent can verify.

### 7. Answer design questions parked in `BLOCKED.md`
`CLAUDE.md` requires the loop to surface a core design decision rather than
invent one — dodge/block, party limit, weapons, the type system, storage, story
rewrites, traversal philosophy, mandatory hunger/thirst, stronghold structure.
An entry appearing there is the loop working correctly, not failing.

## Worth knowing

The Routine fires **hourly at :43**, a fresh session each time, and pushes a
notification when a run finishes. The hourly cron is a floor, not the cadence —
a session that finishes early schedules its own successor a few minutes out, and
one that is parked at a play gate deliberately does not.

To pause the loop, disable the Routine. To change its cadence or prompt, edit
the Routine rather than this file.
