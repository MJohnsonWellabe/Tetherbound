# Coordinator handover — 2026-08-26, ~00:45Z

Written for a successor with no memory of this session. Read this before
`ralph/COORDINATION_2026-08-25_GATE_F_AND_GRASS.md`, which carries the longer
reasoning; this file is what is true now and what to do next.

## 1. State, verified not assumed

`origin/main` is at **`7c47b893`** — `636673ce` plus one commit, the
`verify-core-verb-shard` timeout fix. That is the only thing that landed in the
session's whole first nine hours, for reasons in §3.

Branches, none of them on `main` yet:

| branch | carries |
|---|---|
| `ralph/UNITTEST-VEG-CORRIDOR-SPLIT` | `run_tests.gd --skip=` + `test_veg_corridor.gd` in its own 25-min job. **CI running; sweep when green.** |
| `ralph/WORLD-GRASS` (`e213a7a4`) | the grass tuning. Rebased onto `7c47b893` by the coordinator. CI was green everywhere except unit shard 2, which the split above fixes. |
| `ralph/GRASS-FIELD` | the shader-carpet spike + sky/stone/path work. Ships OFF. |
| `ralph/GATE-F-INSTRUMENTATION` | Gate F harness, protocol, frozen candidate, and per-segment run evidence. **Held off `main` deliberately** — landing it mid-run moves the frozen candidate under the playtest. |

**Do not trust a CI run-level conclusion.** Two separate false signals bit this
session; see §3. Always check that the jobs actually executed.

## 2. Immediate next actions, in order

1. **Sweep `ralph/UNITTEST-VEG-CORRIDOR-SPLIT`** once its CI is green with jobs
   executed (`mcp__github__actions_run_trigger` → `ralph-sweep.yml` on `main`).
   Confirm `git log origin/main` moved; the sweep reporting success is not proof.
2. **Rebase `ralph/WORLD-GRASS` onto the new `main`** (the sweep is
   fast-forward-only, so every `main` move invalidates the branch's base), push,
   let CI run, sweep it.
3. **A `main` push fires `release.yml`**, which rebuilds the Windows binary and
   redeploys the download site. See §5 — the site is currently serving a build
   made from a branch.
4. **Restart the two lanes** from the handovers they are writing now (§4).
5. Gate F's own next step is its S02 blocker fix on `ralph/OPENING-STARTER-FOCUS`
   if that branch appears — land it like any other, but note it changes the
   candidate and forces a re-freeze.

## 3. Two CI defects found and fixed tonight — both were blocking everything

**`verify-core-verb-shard`: retry chain could not fit its own timeout.**
`timeout-minutes: 22` against `smoke_traversal` retried three times at ~6 min
each — ~18 minutes before the other three smokes ran at all. The job only
survived while no retry was needed, which is exactly the case the third retry was
added to cover. Fixed to 40 minutes (landed, `7c47b893`); verified working —
the job now passes in 13-14 minutes on branches where it previously died.

**`verify-unit-tests` shard 2: one FILE exceeds the shard ceiling.**
`test_veg_corridor.gd` measured **10m11s** alone on `ralph/WORLD-GRASS` against a
12-minute ceiling that also covers checkout, cache and two imports. More shards
cannot fix this — sharding distributes files and cannot split one. Fixed by
giving that file its own 25-minute job (`ralph/UNITTEST-VEG-CORRIDOR-SPLIT`),
which is what `ci.yml`'s own note prescribed. **Its runtime tracks vegetation
density**, so any future density change needs re-timing.

**The lesson worth carrying:** a `timeout-minutes` kill reports as **cancelled**,
not failed. Both defects therefore looked like infrastructure noise. `ci.yml` says
this in its own comments and it is still easy to miss.

## 4. Lanes, mid-rotation right now

Both lanes were told at ~00:38Z to finish their current atomic unit, write a
handover, push, and stand down. **Their handovers are the successor's input:**

- `ralph/reports/GRASS_HANDOVER_2026-08-26.md` on `ralph/GRASS-FIELD`
- `ralph/reports/GATE_F_RUN_HANDOVER_2026-08-26.md` on `ralph/GATE-F-INSTRUMENTATION`

Spawn a fresh session per lane from those, via `create_session` with
`source_revision` set to the lane's branch.

**Why rotate:** cost is dominated by cache reads, which scale with context size ×
turns. Measured tonight: the first Gate F session reached **$186.93 on 274M
cache-read tokens** for 851K output and never started its playtest; its fresh
replacement froze a candidate and ran three segments for a fraction of that. The
grass lane hit **$131.60 / 205M**. Rotate at task boundaries where state is on
disk. Never rotate a Gate F lane mid-segment — the journey chains through exit
saves, so a segment boundary is the only safe stop.

## 5. Owner decisions in force

- Gate F runs **agent-driven**; handheld frame rate, GPU, VRAM, thermals,
  controller feel, audio and Windows-export identity are **[OWNER-ONLY]** and
  recorded as coverage gaps, never as measured results.
- Gate F runs the **full** S01–S10 plus X01–X08. Budget cap lifted; run to
  roughly **90% of the seven-day rate limit**, at which point the owner pulls it
  back. (An earlier $400 cap was superseded.)
- The grass lane's work **beyond prompt 72** — sky/clouds, stone and path grit,
  narrowed paths — was **explicitly authorised by the owner**. It is not drift.
  Do not revert it.
- Ship through `ralph/<task>` branches and a dispatched sweep. Never push `main`.
  No pull requests.
- **The download site and `latest` release currently serve a build made from
  `ralph/WORLD-GRASS`**, dispatched deliberately so the owner could playtest the
  grass. `site/` content is byte-identical to `main`'s, so nothing drifted
  visually, but the binary is a branch build until a `main` push re-releases.

## 6. Coordinator errors this session, so they are not repeated

- **Claimed `main` was CI-green on `636673ce`.** Retracted: 25 of that run's 26
  jobs were `skipped` on a docs-only commit. Check jobs, not conclusions.
- **Gave both lanes a 260,000 placement cap.** The real ceiling is **900,000**
  (`tests/test_scatter_perf_budget.gd:79`, raised on owner directive 2026-08-24)
  and the baseline bake is 466,922, not ~144,456. Taken from prompt 72's prose
  without re-deriving from the file. **Cite file and line for any constraint
  handed to a lane; treat `docs/ralph-prompts/**` and `ralph/HANDOVER_*` as
  secondary sources for anything living in code or config.**
- **Told Gate F it had made pre-freeze gameplay changes.** It had not; the diff
  was 34 files, all added, zero modified. It refused the instruction and proved
  it mechanically. Both corrections came from lanes, not from the coordinator.
- **Let the CI fix sit green for over two hours** before dispatching the sweep,
  while answering questions instead of watching the critical path. The owner
  asked three times whether anything was landing. **Watch your own blocking
  chain; a green branch that nobody sweeps is not progress.**

## 7. Mechanics that cost time to discover

- **Cross-session messaging does not reach cloud sessions in either direction**,
  and this coordinator's session name changed mid-run, so name-addressed sends
  were undeliverable. What works: lanes write check-ins to a file on their branch
  and the coordinator polls it. Keep that.
- **To message a specific remote session:** `create_trigger` with
  `persistent_session_id`, then `fire_trigger`. **`update_trigger` cannot edit
  the prompt of a trigger firing into a session you do not own** — a stale prompt
  fired with a correction appended produced a self-contradictory message that a
  lane obeyed the wrong half of. **Delete and recreate instead of patching.**
- `fire_trigger`'s `text` parameter appends after the stored prompt; the returned
  `session_id` should match the target, which is how to confirm delivery.
