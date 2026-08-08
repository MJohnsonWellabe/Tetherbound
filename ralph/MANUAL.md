# Manual tasks — only the owner can do these

The loop cannot do any of these. Each one blocks something specific.

## Before the loop can ship anything

### 1. Let GitHub Actions write to the repository
`Settings → Actions → General → Workflow permissions` → **Read and write
permissions**.

`.github/workflows/ralph-merge.yml` fast-forwards `main` when CI goes green on a
`ralph/**` branch. Without write permission it fails on the push and every task
stops one step short of shipping. There is nothing to "enable auto-merge" for —
the workflow replaces that, because Ralph's fired sessions have no GitHub MCP
tools and no `gh` CLI and so cannot open a pull request at all.

### 2. Merge the setup pull request
PR **#2**, `claude/roster-artwork-alignment-2j6cat` → `main`. Until it lands,
`ralph/` does not exist on `main` and every firing will correctly do nothing but
say it is waiting.

## Before any art task can run

### 3. Rotate the Meshy key, then set it on the environment
The key was pasted into a chat transcript, so treat it as exposed. Rotate it in
the Meshy dashboard, then set `MESHY_API_KEY` as an **environment variable on
the Claude Code environment** — fired sessions read the environment and cannot
see the conversation.

Without it, `R0.5` onward fail immediately.

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
