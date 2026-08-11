# Manual tasks — only the owner can do these

The loop cannot do any of these. Each one blocks something specific.

---

## How to tell if Ralph is alive

**Trigger-fired sessions do not appear in the normal Claude sessions list.**
That is not a fault; it is how scheduled runs work, and it is the single reason
the loop looked dead when it was working fine. Look here instead:

| Question | Where to look |
|---|---|
| **What is it doing?** | `ralph/STATUS.md` on the **`ralph-status` branch** — one block per live firing, each with its task, area, state and timestamp. Fastest answer, needs nothing but GitHub. **Not the copy on `main`**, which is a frozen placeholder and always reads `idle`. |
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

**Several blocks at `working` on different areas is the loop running correctly**,
not a collision. Several on the *same* area is a real collision.

**An interactive session — a person working with Claude directly, not a
Routine — appears in neither place unless it claims a lease too.** On
2026-08-11 one worked for two hours shipping three commits while this file read
`shipped` throughout, and the owner reasonably concluded nothing was happening.
Interactive sessions now claim a block like any firing. If you are ever
wondering whether anything is happening, this file is the answer, and if it is
silent that is a bug in whoever is working, not in you.

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

### 4. ~~Top up Meshy credits~~ — done, and it stopped being the constraint
Balance is **5000** as of 2026-08-11. The authorised programme spends ~540 of
it, so credits will not block anything for the foreseeable future.

**What blocks art now is reference art.** The owner's rule, same message:
*"we should never render without me loading art first."* Nothing gets generated
without a board in `docs/art/reference/` first, and `BLOCKED.md` carries the
standing list of what is waiting on one — currently the Tether energy pylon,
the relay apparatus and the legendary tether machine.

Note what this does **not** unlock: `D23` §20 forbids creature regeneration, and
the owner reaffirmed it *with* the 5000 in the account, which proves it was
never a budget rule. Creatures and humans are rework-only, permanently.

## Ongoing

### 5. Play the game at each `▶` checkpoint — in parallel, whenever you can
`ralph/BACKLOG.md` marks them and `BLOCKED.md` lists the ones waiting.
`GAME_DESIGN.md` §33's exit criteria are entirely subjective — "is repeated
combat enjoyable, not merely functional", "would you voluntarily keep
playing". No amount of green CI substitutes, and the bible says so directly.
**Per your 2026-08-09 directive (D21) the loop no longer parks at gates** —
it keeps building and your playtest feedback lands as new backlog items
whenever you play. The one place it still stops is R9.5, the exit gate,
which only you can call.

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

### Three Routines, not one (2026-08-11, `D25`)

The owner chose parallel lanes. Each Routine starts a fresh session and pushes a
notification when its run finishes.

| Routine | Fires | Meshy key | Trigger id | Who can change it |
|---|---|---|---|---|
| **Ralph** | `49 * * * *` | **Yes** — the only one that can do art | `trig_01HJmwxGFfWZHaKP5UJMV8HV` | **Owner only** |
| **Ralph lane B** | `9 * * * *` | No | `trig_01TkPuw6fMmjQ2FM5LA5xAKN` | Owner or an agent |
| **Ralph lane C** | `29 * * * *` | No | `trig_01VgHpVNCrsAWB8xNPBZScjw` | Owner or an agent |

### ⚠ Check the Routine's ALLOWED TOOLS — the keyed one is missing three

The "Ralph" Routine's stored `allowed_tools` is exactly:

    Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch

Eight tools. **No `Task`, no `Skill`, no MCP tools.** For comparison, a Routine
created through the normal tooling gets `preset:default` plus `Task`, `Skill`,
`Monitor`, `TodoWrite` and the rest. Two consequences, both load-bearing:

1. **It cannot chain.** Scheduling a successor needs the `send_later` MCP tool,
   and MCP tools are not in the list. `PROMPT.md` tells every firing to schedule
   a successor 2–3 minutes out; a firing that cannot will fall back to the
   hourly cron, quietly, and the ~25% idle that chaining was meant to remove
   stays.
2. **It cannot run the blind visual pass.** `.claude/skills/visual-judge` needs
   `Skill`, and a genuinely blind critic needs `Task` to spawn a sub-agent that
   was never told what changed. Without both, a firing can only look at its own
   frames and grade its own work — **which is precisely the failure
   `conventions.md`'s blind-pass rule exists to prevent**, and it has already
   happened: R7.2's own record says the builder had "no way to spawn a genuinely
   blind critic and read back its verdict from its own toolset" and self-graded
   instead.

That second one is not a minor gap right now. **Nearly every item in Phases
-0.9 through -0.55 is visual-affecting**, so as configured the keyed Routine
cannot correctly complete most of the work at the top of the backlog.

**Fix:** edit the Routine in the UI and allow at least `Task` and `Skill`
alongside the eight above, plus MCP tools if you want chaining. When creating
the lanes, give them the same — the default tool set new Routines get is
already correct, so this is a quirk of the keyed one specifically.

**How this was found:** by reading the Routine's stored config, not by watching
it fail. What is *verified* is the eight-tool list; that scheduling and blind
critique are impossible without the missing three is inference from what those
actions require — but it matches the R7.2 report exactly, and it is cheap to
fix either way.

### ⚠ Lanes must be created in the UI, with the repository attached

**An agent cannot create a working lane.** The `create_trigger` tool has no
`sources` parameter, so the sessions it fires start with **no repository
checked out**. Two lanes were created that way on 2026-08-11, fired on
schedule, and produced nothing at all — no lease, no branch, no commit —
because there was nothing on disk to read. They looked healthy in every listing:
`enabled: true`, correct cron, sensible `next_run_at`.

Create lanes at `claude.ai/code/routines` with the repo set to
`MJohnsonWellabe/Tetherbound`. `ralph/LANE_PROMPT.md` holds the exact prompt
text to paste.

**How to tell a lane is really working:** it writes a lease block to
`ralph/STATUS.md` on `ralph-status` within a few minutes of firing, before doing
anything else. `PROMPT.md` requires that ordering precisely so a dead lane is
visible fast. No block and no `ralph/*` branch ten minutes after a firing means
the session came up empty.

### ⚠ Only the owner can pause or resume the "Ralph" Routine

**This is the one genuinely manual step in the whole loop, and it was found the
hard way on 2026-08-11.** The original Ralph Routine was created through the
HTTP API, and an agent can only update Routines it created itself. Attempting
it returns:

    update_trigger: this routine was created via "http_api", not by an agent.

So when Ralph is paused, **no session can turn it back on** — it has to be
toggled in the Routines UI. The two lanes were created by an agent and do not
have this limitation, which means a half-off state is possible and easy to miss:
lanes B and C running while the keyed Routine sits paused looks like a working
loop right up until an art task reaches the top of the backlog and no one can
take it.

If art tasks are silently piling up, **check that "Ralph" itself is enabled**
before looking for a bug anywhere else.

**The old figure in this file said :43. It was `49 * * * *` the whole time** —
worth knowing, because a stale schedule here is exactly what makes the loop look
dead when it is fine.

**Only the keyed Routine can run art tasks.** The Meshy key is carried in that
Routine's own prompt and nowhere else; the repository is the one place it must
never go, since GitHub history is permanent and secret scanning would likely
revoke it. Backlog items needing it are marked `lane: art`, and the unkeyed
lanes skip them. **To rotate the key, edit that Routine's prompt** — not this
file, not the repo.

Lanes coordinate through per-`area` leases in `ralph/STATUS.md` on the
`ralph-status` branch: a firing stands down only if its own area is held.
Realistically this runs two or three at a time, not three always — `terrain` is
one lane however many items sit in it, because they share a rebake.

The cron is a floor, not the cadence. A session that finishes early now
schedules its successor 2–3 minutes out rather than idling to the hour, which
was costing about a quarter of every cycle.

**To pause the whole loop, disable all three Routines** — disabling only
"Ralph" leaves the two lanes running. To change a cadence or prompt, edit the
Routine rather than this file.
