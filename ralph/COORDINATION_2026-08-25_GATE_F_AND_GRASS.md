# Coordination record — Gate F and WORLD-GRASS, two concurrent lanes (2026-08-25)

Opus coordinator session. Opened per `ralph/START_HERE.md` and
`ralph/HANDOVER_2026-08-25_CI_GREEN_AND_TWO_LANES.md`, which route the next
coordinator into exactly these two lanes. This file records what was verified
before dispatch, the owner decisions taken at dispatch, and the lane contracts —
so the next session does not re-derive any of it.

## 1. State verified before dispatch

- `origin/main` is at `636673ce`. ~~**CI run #2424 is green on that exact SHA**
  (`32862114528`, push event, conclusion `success`).~~ **RETRACTED 2026-08-25
  18:00Z — see §7. That run's green is vacuous: 25 of its 26 jobs concluded
  `skipped`.** `verify-continuous-core-known-red` remains the intentional
  `continue-on-error` job tracking a real unfixed CONTINUOUS-CORE defect; that is
  by design and its flag is not to be removed without fixing the underlying thing.
- **The handover's branch list is already stale.** It records `ralph/WORLD-GRASS`
  as still present and safe to delete, and `claude/ci-consolidation-main-sync-lmztz6`
  as redundant. `git ls-remote --heads origin` now returns only `main` and
  `ralph-status`. Both were deleted after the handover was written. Nothing to
  clean up, and both `ralph/GATE-F` and `ralph/WORLD-GRASS` are free names again.
- A fresh container carries neither Godot nor the GL libraries. Shared prep was
  run once, centrally, before dispatch rather than per-lane: `apt-get update`
  first (per `conventions.md`'s stale-index trap), then `libegl1 libegl-mesa0
  mesa-vulkan-drivers xvfb`, then `tools/art_pipeline/setup.sh godot`
  (4.7-stable, matching `ci.yml`), then `--headless --path . --import`.

## 2. Owner decisions taken at dispatch, 2026-08-25

`ralph/GATE_F_PROTOCOL.md` §1 requires the candidate's conditions be recorded
before the freeze, and §18 requires a judgment on ROG Ally performance. The
protocol assumes an operator that this container cannot fully supply: there is no
ROG Ally here, no human hands, and no physical controller. Put to the owner, who
decided:

1. **Gate F runs agent-driven now, with handheld items flagged rather than
   claimed.** The operator is a Sonnet agent driving a scripted harness under
   xvfb with synthetic input. Handheld frame rate, GPU cost and controller feel
   are recorded as **owner-only, unverified** — never as measured results. The
   owner's own pass on a later frozen candidate is what will actually satisfy
   §18's exit criterion.
2. **This session carries Gate F through publishing the regenerated authoritative
   backlog, then self-chains into §17 remediation** on SHIP BLOCKERs without
   waiting for approval — consistent with `START_HERE.md` §4's standing rule that
   evidence gates are not owner-blocking.
3. **Repo shipping convention wins over the session's assigned branch name.**
   Implementation code ships on `ralph/<task>` branches through CI and a
   dispatched `ralph-sweep.yml` consolidation, per `CLAUDE.md` ("ship through the
   Ralph branch/CI process; do not bypass it") and `conventions.md`. Coordinator
   bookkeeping — this file — rides the session branch. This also keeps the
   published Windows build current, which is what the owner actually plays.

## 3. WORLD-GRASS lane — the diagnosis is partly stale, and it matters

`docs/ralph-prompts/72-WORLD-ground-cover-and-mid-layer.md` states its numbers
were measured on `main` at `ded2e697` and tells the reader not to re-derive them.
Re-verified against `636673ce` before dispatch, because the handover asked for it:

| field | prompt 72 says | current `main` | status |
|---|---|---|---|
| `scale_min` / `scale_max` | 0.14 / 0.42 | **0.14 / 0.42** | unchanged — the root cause holds |
| `lod_range` | 55.0 | **55.0** | unchanged — still a bald ring |
| `corridor_fill.density_scale` | 1.0 | **1.4** | moved |
| `strays` | 900 | **300** | moved |
| `per_clump` | 130 | **190** | moved |

The root cause prompt 72 identifies is real and still present. The density
numbers are not.

**This is not a bookkeeping nit.** The layer moved because a later lane,
`GROUND-LAYERS`, deliberately drove grass density *down* and recorded why in
`vegetation.json` itself and in `ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md`:
raising density had taken the chapter from 143,630 to 532,886 placements for no
measured change in near-field clump count, because the near field is terrain
*surface*, not somewhere a mesh can stand — ground appearance is a material
problem and scatter was the wrong instrument for it. It also set a target
composition of roughly 70% open grass / 15% path / 10% low accents / 5% special,
i.e. the meadow is supposed to have negative space.

So prompt 72's "raise `density_scale` off 1.0" reads, on current `main`, as an
instruction to reverse a later measured decision.

**Coordinator's resolution, given to the lane as its contract:** prompt 72 is
newer and owner-directed and wins on intent, but its actual lever is **blade
scale and LOD range, not instance count** — and that is fully compatible with
GROUND-LAYERS' finding rather than in conflict with it. Grass scaled to 0.14-0.42
is invisible at any density. The lane leads with `scale_min`/`scale_max` and
`lod_range`, prefers the Tall models in open frames, and treats `density_scale`
as a last resort that must be justified in its report and must not undo the
negative-space intent. The lane was told to push back with evidence if real
frames prove this resolution wrong.

Standing constraints restated to the lane: no new assets; the 260,000 placement
cap in `test_scatter_perf_budget.gd` is headroom, not a number to raise; the
OP23-01 CPU win (33-40ms to 3.8-4.7ms) is not to be spent; GPU is unmeasurable
here and is stated as risk, never as a frame rate.

## 4. Gate F lane — sequencing

The protocol's model roles are mandatory and are being honoured as a sequence of
separately-engaged agents, not one agent wearing three hats:

1. **Fable Phase A** (running) — designs `ralph/GATE_F_MASTER_PROTOCOL.md`: the
   coverage matrix, state transitions, abuse cases, instrumentation schema, the
   six studies, the prescribed screenshot plan, segment structure, and the
   instrumentation build list. Told the execution envelope honestly so the
   protocol is runnable, and required to name what the envelope cannot reach as a
   coverage gap for the owner's pass rather than pretending a script covers it.
   Given the §16.1 blind-first constraint: it may not build coverage by
   transcribing `BACKLOG.md`.
2. **Instrumentation build** — a developer agent implements Fable's schema.
   §1.5 requires this land *before* the freeze.
3. **Freeze the candidate SHA.** No patching during an authoritative run (§1.6).
4. **Sonnet operator** executes the protocol. Changes no code (§13).
5. **Fable Phase B** — blind analysis, provisional backlog hashed before
   comparison (§16.2), then historical reconciliation (§16.3) and the capture-rate
   metric (§16.5).
6. **§17 remediation**, grouped by root cause by the coordinator.

Fable is not permitted to become the implementation agent at any point.

## 5. Parallel safety

No file collision, as the handover predicted. WORLD-GRASS owns
`data/config/vegetation.json`, `scripts/world/scatter_rules.gd`, the five
vegetation test files, and any new capture tool it adds. Gate F is read-only
against the build until remediation, and remediation is scoped per-finding by the
coordinator rather than blanket-owned by the lane.

One resource *does* collide: **Godot itself**. `conventions.md` records that
concurrent captures produced load 47, OOM kills, and zombie processes pinned to
deleted worktrees that were then misdiagnosed as contention. Sequenced
deliberately — Fable's Phase A is pure document work, so WORLD-GRASS has
exclusive engine use for its whole bake/capture/critique loop.

If Gate F's playtest surfaces ground-cover findings, they route to WORLD-GRASS
through the coordinator rather than being remediated twice.

## 6. Correction — the lanes run as separate sessions, not in-process subagents

§5 above described sequencing two lanes inside one coordinator's container, with
git worktrees for file isolation and a deliberate ordering so only one lane held
Godot at a time. **That was the wrong architecture and it has been replaced.**
The owner caught it. Recorded here because the reasoning generalises to any
future multi-lane run on this project.

Each lane is now an independent Claude Code session with its own container, its
own clone, and its own Godot install:

- WORLD-GRASS — `session_01SL1tPZcK46kEojuyMYS1f6`
- Gate F — `session_01TAzwxvKd5DkpX3kTA4xShx`, started on
  `ralph/GATE-F-INSTRUMENTATION` so it inherits Fable's Phase A.

Three reasons, in order of weight:

1. **The worktree scaffolding was a bad reimplementation of a container.** A
   single working tree cannot hold two lanes that both check out branches, so
   the coordinator built a second worktree and pre-seeded a second import cache
   by hand. Separate containers give that for free and cannot drift.
2. **Godot contention is a documented disaster here, not a hypothetical.**
   `ralph/conventions.md` records concurrent renders driving load to 47,
   OOM-killing Blender, and leaving zombie processes pinned to deleted
   worktrees that were then misdiagnosed as contention for a whole session.
   One box means the grass lane's bake/capture loop and Gate F's chapter-length
   operator run compete for CPU no matter how carefully branches are sequenced.
   Separate containers make that structurally impossible rather than merely
   scheduled around.
3. **A single coordinator context is a single point of failure for Gate F.**
   Gate F is protocol design, instrumentation, a frozen-candidate run producing
   dense telemetry, blind Phase B analysis, and reconciliation of every
   unresolved historical item with a capture-rate metric. Funnelling all of it
   through one context degrades the analysis exactly where it must be sharpest.
   Separate sessions each carry a full budget and survive this container being
   reclaimed.

What the in-process approach had going for it was thin — a shared 512 MB import
cache and a tighter steering loop — and neither is worth the above.

Nothing was lost in the migration. The verification in §1, the lane contracts,
the grass diagnosis reconciliation in §3, and Fable's Phase A were all already
durable; the lane briefs became the session prompts. The grass lane had produced
no file changes when it was stopped, so it restarts from a clean baseline
measurement costing about a minute of engine time.

**The general rule for this project:** lanes that both need Godot belong in
separate containers, not in separate worktrees of one container. File isolation
was never the binding constraint — CPU and the coordinator's own context were.

## 7. Retraction — §1's "CI is green on 636673ce" was not evidence

The Gate F lane caught this and pushed back rather than complying with an
instruction built on it (`ralph/reports/gate-f-lane-log.md`, check-in 4). It is
right, and the coordinator verified it independently before recording this.

**CI run #2424 (`32862114528`) concluded `success` while executing nothing.** Of
its 26 jobs, only `changes` ran; the other 25 — all six unit shards, every
regional and combat shard, `verify-core-verb-shard`, and `export` — concluded
`skipped`. The commit it ran on touched only `ralph/`, so the path filter
correctly decided documentation-only. Nobody misread the run; it genuinely
concluded success.

That is what makes this class of false green dangerous: **at the run level a
path-filtered skip and a real pass are indistinguishable.** `conventions.md`
already warns from the other direction — "Check `git log origin/main`, not the CI
badge" — and this is the missing second half of that rule: **check that the jobs
actually ran.** A run-level conclusion is not evidence that code compiles or that
tests pass.

Consequence: `636673ce` has never been verified by a run that executed its tests.
The first run in this lineage that genuinely compiled and tested the code is
`2432` attempt 2 on `ralph/GATE-F-INSTRUMENTATION`. The Gate F freeze record
states this rather than inheriting §1's retracted claim.

### A second coordinator error, also corrected by the lane

§2 of the 17:08Z coordinator instruction told the Gate F lane it had "fixed a
level-up bug and an arena defect pre-freeze" and must enumerate those in the
candidate metadata. **It had made no such change.** The register agent had only
*read* those two defects out of history and noted that earlier lanes
(`GATE-E-LOGIC`, `CI-BOSS`) already fixed them on `main`. The lane declined to
comply, on the correct grounds that inventing a non-instrumentation change would
corrupt the evidence chain the instruction exists to protect, and proved it
mechanically: `git diff --name-status origin/main HEAD` returns 34 paths, every
one `A`, zero `M`. Independently re-verified by the coordinator.

The honest enumeration of non-instrumentation changes in the candidate is
**none**, and `RUN_METADATA.json` records the `--name-status` output as evidence
rather than the claim alone.

### `verify-core-verb-shard`'s retry policy cannot fit its own timeout

Also from check-in 4, and independently confirmed against `ci.yml`. The job sets
`timeout-minutes: 22` and runs `smoke_playground`, `smoke_input`,
`smoke_traversal` (retried up to **three** times) and `smoke_catching` (up to
two). `conventions.md` measures `smoke_traversal.gd` at ~6 minutes, so three
traversal attempts alone are ~18 of the 22 minutes before the other three smokes
run at all. On run 2432 the job was killed mid-`smoke_traversal` at 22m50s while
still emitting progress — a workload that does not fit its budget, not an
assertion failure.

The third retry was added by the 2026-08-25 consolidation session to mitigate the
real player-slide wedge at world (53,-65). That mitigation and this timeout are in
direct conflict: **the job only survives while no retry is needed**, which is
exactly when the retry was supposed to help.

This is a Gate F backlog candidate in its own right. A CI job whose retry policy
cannot fit its own timeout reports red for reasons unrelated to the code under
test, which is precisely how a real defect gets waved off as infrastructure noise.

## 8. Second retraction — the placement ceiling is 900,000, not 260,000

§3 above gave both lanes a hard constraint: *"`tests/test_scatter_perf_budget.gd`
caps placements at 260,000; current bake ~144,456. That is your headroom."*

**Both numbers are wrong.** Verified on `origin/main`:

    tests/test_scatter_perf_budget.gd:79
    const MAX_SANE_PLACEMENT_COUNT := 900000

The ceiling was raised to 900,000 on owner directive 2026-08-24 against a
measured 789,511, and the test's own header records it. The committed bake at
`636673ce` is 466,922, not ~144,456. Real headroom was therefore ~433,000
placements rather than ~116,000 — which is what made a ground-cover tier
affordable at all.

The coordinator took both figures from `docs/ralph-prompts/72`'s prose and the
2026-08-25 handover without re-deriving them from the test file, then repeated
them in the WORLD-GRASS brief and again in an 18:00Z intervention that told the
lane it was "2.8x over a hard cap" and should revert. The lane was never over
budget: 725,949 against 900,000 is 19% headroom, and it did not touch the cap
(`git diff origin/main origin/ralph/WORLD-GRASS -- tests/test_scatter_perf_budget.gd`
is empty). It answered with the test file's own header rather than complying.

**This is the same failure mode §3 itself diagnoses, committed one level up.**
§3 correctly warned that prompt 72's *layer* numbers were measured at `ded2e697`
and had drifted — and then inherited that same prompt's *budget* numbers without
applying the same scepticism. Re-deriving a document's headline claim while
trusting its supporting figures is not verification.

**Rule for the next coordinator:** a constraint handed to a lane is only as good
as the file it was read from. Cite the file and line, not the prompt that quotes
it. `docs/ralph-prompts/**` and `ralph/HANDOVER_*` are secondary sources for any
number that lives in code or config.

## 9. What the lanes actually produced, and what they cost

### WORLD-GRASS — shipped items 1-4, blind pass converged WITHOUT passing

On `ralph/WORLD-GRASS`, cut from `636673ce`. Report:
`ralph/reports/WORLD_GRASS_2026-08-25.md`.

It corrected the contract's stated cause, which is most of why it got anywhere.
Prompt 72 says 0.14-0.42 means "blades a few centimetres tall". Measured off the
four source meshes' own glTF `POSITION` accessors, mean tuft height on `main` was
**0.41 m** — shin height on the 1.80 m trainer standing in every judged frame.
`R9.4` had cut the range to that value *deliberately*, after a blind critic
measured the previous 0.34-1.0 range at ~1.2 m and called it "pampas, not meadow
grass". The grass was never too short. It was **isolated**: a census
(`tools/_probe_grass_census.gd`) measured 0.019 tufts/m2 at the band-1 open
meadow — one tuft per ~50 m2 at the game's opening.

Levers used, two of which cost nothing in placements: scale 0.14-0.42 -> 0.32-0.58
(mean height 0.41 m -> 0.71 m), a new per-model `model_scale` giving four height
classes, `lod_range` 55 -> 120 with the fade band 12 -> 55, verge 14,000 ->
30,000, clumps 110 -> 150, a new `groundmat` tier, and flower drifts tightened.
Bake 466,922 -> 725,949 against the real 900,000 ceiling.

**The blind pass converged without passing — three rounds, three independent
sub-agents, both bar questions answered `no` every time.** Round 3's remaining
defect is filed by the critic under "needs art that is not in the build": the
grass mesh is flat two-tone polygon with no base-to-tip gradient and no ground
blend, so it meets the terrain at a hard line however it is scaled. That is
exactly the R9.4 wall `conventions.md` describes, and it is an owner art
decision, not a tuning number. Correctly recorded as `WORLD-GRASS-remainder` in
`ralph/BACKLOG.md` rather than marked done.

Honest measurement worth preserving: the lane ran two perf profiles per config
rather than one, and found band 4 measuring **4.72 ms and 9.36 ms on the same
config**. Per-site frame CPU on this container varies more than the change does,
so it made no per-site claim. The structural numbers that the OP23-01 guarantee
actually rests on are exact and unchanged — solid placements 51,511, harvest
points 56,430 — because every layer it touched is `collides:false` with no
`harvest_item`.

### Gate F — instrumentation landed; the playtest had not started

Instrumentation is committed and CI-verified on `ralph/GATE-F-INSTRUMENTATION`:
operator harness, read-only live-state probe, runner, segment schema, S01-S10 and
X01-X08 step-scripts, and `tools/capture_diag_minimal.gd` — the file
`conventions.md` had cited for days without it ever existing.

**Cost discipline is the open risk.** The lane twice ended a turn idle while a
subagent was "mid-flight" — 54 minutes the second time — and had spent ~$175 and
three hours without a second of playtest, with its seven-day rate limit already
in warning. Standing rule issued: never end a turn idle awaiting a subagent;
either wait inside the turn or checkpoint and continue. A dead subagent and a
working one are indistinguishable from outside, and a lane in its own container
has nobody watching it.

**Structural lesson for lane briefs:** a lane told to "check in at every stage
boundary" will still go silent if its check-in channel does not work and nothing
external polls it. Cross-session messaging does not reach cloud sessions in
either direction, and this coordinator's session name changed mid-run
(`tetherbound-06` -> `tetherbound-ba`), so every name-addressed send the lane
attempted was undeliverable. What worked: the lane writing check-ins to a file on
its own branch, and the coordinator polling it on a timer.
