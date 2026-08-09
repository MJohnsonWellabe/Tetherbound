# Manual tasks — only the owner can do these

The loop cannot do any of these. Each one blocks something specific.

---

## How to tell if Ralph is alive

**Trigger-fired sessions do not appear in the normal Claude sessions list.**
That is not a fault; it is how scheduled runs work, and it is the single reason
the loop looked dead when it was working fine. Look here instead:

| Question | Where to look |
|---|---|
| **What is it doing?** | `ralph/STATUS.md` on the **`ralph-status` branch** — task, state, timestamp. Fastest answer, needs nothing but GitHub. **Not the copy on `main`**, which is a frozen placeholder and always reads `idle`. |
| **Is it running right now?** | The Routine page → **Runs** tab → click the run. That opens the live transcript. A spinner there means in flight. |
| **What has it finished?** | `ralph/DONE.md`, newest first, each entry with a commit SHA. |
| **Why has it stopped?** | `ralph/BLOCKED.md`. A parked loop is a correct outcome, not a failure. |
| **Did a feature actually ship?** | Commits on `main`, and a fresh Windows build at the download link. |

**Two signals that mislead:**

- **Token usage.** Dashboards lag, and a Sonnet firing is small next to an
  interactive Opus session. Flat usage does not mean nothing is happening.
- **No branch yet.** Investigation tasks legitimately produce nothing for a
  while — reproducing a flaky test means running it repeatedly before a single
  line changes. `STATUS.md` exists precisely so this is not ambiguous.

A firing that dies leaves a **stale timestamp** in `STATUS.md`. The next hourly
run should pick the work back up; if two hours pass with no change to that file
and no run in the Runs tab, the Routine itself needs looking at.

## Done

- ~~**Let GitHub Actions write to the repository.**~~ Done — `Settings → Actions
  → General → Workflow permissions` is on **Read and write**, so
  `.github/workflows/ralph-merge.yml` can fast-forward `main`.
- ~~**Merge the setup pull request.**~~ Done — PR #2 landed at `3d60db6`.

- ~~**Put the Meshy key where the loop can reach it.**~~ Done, and it needed
  nothing from the owner in the end. The key is carried in the **Routine's own
  prompt**, which every fired session reads. There is no tool to set an
  environment variable on this environment, and the repository is the one place
  it must never go — GitHub history is permanent and secret scanning would
  likely revoke the key on push. To change or rotate the key later, edit the
  Routine, not the repo.

## Nothing is blocking the loop

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
