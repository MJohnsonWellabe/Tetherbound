# Gate F lane — stage-boundary log

This lane runs in its own container (session `tetherbound-2c`) and cannot reach
the coordinator session (`tetherbound-06`) by message — `ListAgents` shows no
cross-session peer from here, and a `SendMessage` to that name returns "no agent
reachable". The mandate requires a check-in at every stage boundary, so the
check-ins are written here instead, where they survive this container being
reclaimed and where the coordinator can read them off the branch.

Stages, per the lane mandate: instrumentation pushed/green -> candidate frozen
(with SHA) -> operator run complete -> provisional backlog hashed -> final
backlog published -> §17 remediation.

---

## Check-in 1 — 2026-08-25 — STAGE 1 (instrumentation build) STARTED

- Container prepped: `apt-get update` first (per the stale-index trap), then
  `libegl1 libegl-mesa0 mesa-vulkan-drivers xvfb`; Godot
  `4.7.stable.official.5b4e0cb0f` from `tools/art_pipeline/setup.sh godot`;
  `--headless --path . --import` building `.godot/`.
- Branch `ralph/GATE-F-INSTRUMENTATION` at `c196e18a` = `origin/main` `636673ce`
  plus Fable's completed Phase A commit.
- Developer subagent building `ralph/GATE_F_INSTRUMENTATION_REQUEST.md` in full:
  `tools/gate_f/operator_harness.gd`, `scripts/debug/gate_f_probe.gd`,
  `tools/gate_f/run_segment.sh`, `tools/gate_f/SEGMENT_SCHEMA.md`, tests.
  Prime directive enforced: no gameplay path changes behavior, accessors are
  additive and read-only, telemetry only under a CLI flag, telemetry reads live
  game state. No `vram` and no device-fps field exists in the schema at all.
- Phase A is NOT being redone. It is Fable's and it is done.

Nothing is pushed yet. When the branch is green it needs the coordinator's
`ralph-sweep.yml` dispatch — this lane does not push to `main` and does not open
pull requests.

---

## Check-in 2 — 2026-08-25 — §16.1 register frozen (210 items)

`ralph/reports/gate-f-historical-snapshot.md` is committed and pushed at
`34d1a368`. It is the §16.1 freeze: every unresolved historical item, enumerated
and stable-IDed, taken before the playtest so reconciliation has a fixed base.

**Read restrictions carried by that file, and enforced by this lane:**

- the Gate F operator must never read it during the run (§16.1 blind-first);
- Fable must not read it before its provisional backlog is hashed (§16.2).

Both are on the same branch as the protocol, so the restriction is procedural,
not structural. Every operator and Phase B brief this lane issues names the file
explicitly as forbidden rather than trusting the agent not to wander into it.

### Counts

| | first pass | after gap-closing sweep |
|---|---|---|
| total enumerated | 145 | **210** |
| player-facing | 106 | **162** |
| not player-facing | 29 | 36 |
| superseded/obsolete candidates | 8 | 10 |
| owner-reported | 40 | 45 |
| §16.5 denominator bracket | 67–101 | **108–156** |

The register was returned once. The first pass disclosed its own gaps — the
visual reports grepped rather than read, `ralph/lanes|ledger|planning` never
opened, and eleven of sixteen `OP` owner items closed by inference from
`PROMPT_COMPATIBILITY_MAP.md` rather than by a closing record. Closing those
three gaps found 65 further items, 55 of them in the visual reports alone.

That is worth recording as a method result, not just a number: **an omission in
this register is invisible at reconciliation and silently raises the capture
rate**, because an item nobody enumerated cannot be scored as missed. A
misclassification, by contrast, is Fable's to catch. Omission and
misclassification are therefore not symmetric risks, and the register was built
to over-include deliberately. The residual risk is now over-inclusion of
visual-report rows that one reproduction will retire — which is what §16.3
category 5 (NOT REPRODUCED) exists to absorb.

The denominator is stated as a **bracket, not a number**. 54 of 198 rows are
honestly `unsure`; collapsing them would mean resolving them in whichever
direction flattered the metric, which is the specific thing §16.5 forbids.

### Two findings that are not bookkeeping

**1. `tools/capture_diag_minimal.gd` has never existed in this repository.**
`git log --all -- tools/capture_diag_minimal.gd` returns nothing; it is absent
from `origin/main`. Yet `ralph/conventions.md` cites it as settled fact — the
120-second smoke for the `--headless` + `--rendering-driver opengl3` hang, which
that same file calls "the single most expensive trap in this repo" — and
`GATE_F_INSTRUMENTATION_REQUEST.md` §9 requires capture mode be *gated* on it
passing. So the documented first line of defence against the trap that burned
four capture attempts and ~43 minutes on 2026-08-22 alone was a pointer to a
file that was not there. A session following conventions.md to diagnose a hung
capture would have found nothing to run and, per that file's own account of the
incident, would likely have misdiagnosed it as contention again. The
instrumentation lane had to write the file to satisfy §9.

**2. The game has essentially no world audio, and no backlog item says so.**
`scripts/ui/audio_cues.gd` is the only file touching `AudioStreamPlayer`; the
nine `.wav` files under `assets/ui/audio/` are the only audio assets in the
project. A case-insensitive grep for audio/sound/music across `BACKLOG.md` and
`ACTIVE_GAME_PLAN.md` returns nothing. This is not a deprioritised item — it is
an unenumerated one, and it is a whole missing domain rather than a defect.

The reason it went unenumerated is structural and worth naming: the standing
whole-game sweep is the visual ledger, whose eight domains are visual by
construction, so nothing in the routine process was ever pointed at audio.

**Gate F cannot close this.** §K.6 of the master protocol pre-registers audio as
[OWNER-ONLY] — no audio path exists in this envelope at all, and
`test_audio_cues.gd` covers wiring only. So at reconciliation this will land as
MISSED BY GATE F traceable to a *declared* gap, which the protocol distinguishes
from an undeclared coverage hole. Recording it here so that distinction is made
on the evidence rather than reconstructed later, and so the owner's pass — which
is the only thing that can judge it — gets it in writing beforehand.

Three rows the sweep also refuted against live code, rather than trusting the
prose: every level-up in the chapter aborted its own announcement
(`int(Callable)` on a `get()` that returned a method) while its test stayed green
by asserting on the function's *source text*; the boss-arena defect was the same
root cause as the owner's arena-phasing report; and the 132-module stronghold
silhouette stood 7,708 m from the stronghold the player actually walks to. The
first two are fixed. The third is re-sited but has never been blind-judged.

---

## Check-in 3 — 2026-08-25 17:15Z — instrumentation pushed; one coordinator claim corrected

Instrumentation is committed and pushed: `8d25c8d2` on
`ralph/GATE-F-INSTRUMENTATION`. CI is running on it. Files:
`tools/gate_f/operator_harness.gd`, `scripts/debug/gate_f_probe.gd`,
`tools/gate_f/run_segment.sh`, `tools/gate_f/SEGMENT_SCHEMA.md`,
`tools/gate_f/harness_config.json`, four self-check segment scripts,
`tools/capture_diag_minimal.gd`, and two test files. Acceptance results are
being collected from the developer agent and land in check-in 4 with the freeze.

### Correction: this lane has made no gameplay change, pre-freeze or otherwise

The 17:08Z coordinator check-in says:

> you fixed a level-up bug and an arena defect pre-freeze, so the candidate is
> no longer "main plus instrumentation" — enumerate every non-instrumentation
> change in the candidate metadata.

**That did not happen, and the instruction it motivates would put a false entry
in the candidate metadata.** Correcting it here rather than complying, because
an invented "non-instrumentation change" corrupts the evidence chain in exactly
the way the instruction is trying to protect.

What actually happened: the §16.1 register agent *read* those two defects out of
repo history while enumerating unresolved items, and reported that earlier lanes
(`GATE-E-LOGIC`, `CI-BOSS`) had already fixed them. Those fixes are on
`origin/main` and predate this lane. The register recorded them to revise two of
its own rows from `unsure` to `no` — a bookkeeping change inside a Markdown
register, not a code change.

Verified mechanically rather than asserted:

    git diff --name-status origin/main HEAD

returns **16 paths, every one of them `A` (added)**. Zero `M`. No existing file
in the repository is modified by this branch — no gameplay script, no UI, no
save format, no input map, no data config, no existing test. The candidate is
`main` plus additive Gate F files, which is the strongest form of the §1.5
non-invasiveness requirement and is exactly what the freeze wants to be able to
claim.

The standing instruction — enumerate every non-instrumentation change in the
candidate metadata — is correct and is being followed. The honest enumeration is
**none**, and `RUN_METADATA.json` will record the `--name-status` output as the
evidence for that rather than the claim alone.

### Accepted without further action

Per the coordinator: the register is frozen at 210 items and that stage is
closed. No further sweeping. No backlog-grep-driven remediation before the run —
fixing what history says is broken is upstream of the blind-first discipline the
capture-rate metric depends on, and every pre-freeze gameplay change widens a
candidate that then has to be justified. Remediation is §17, after the backlog
exists. This lane has made no such fix and will make none before the run.

### Channel

Confirmed: cross-session messaging does not reach the coordinator from here, and
the coordinator session was renamed (`tetherbound-06` -> `tetherbound-ba`), so
the name-addressed sends this lane attempted were never going to land. This file
is the channel. Check-ins land at every stage boundary and after each journey
segment.

---

## Check-in 4 — 2026-08-25 17:40Z — the baseline "green" is vacuous, and it matters

Instrumentation CI ran for real (run 2432, attempt 2, `8d25c8d2`). Result:

| job | conclusion |
|---|---|
| `verify-unit-tests` shards 1-6 | **success** (all six) |
| `verify-gate-a-ui-build-shard` | success |
| `verify-combat-shard` | success |
| `verify-regions-shard` | success |
| `verify-owner-regressions-shard` | success |
| `verify-gate-evidence-shard` | success |
| `verify-continuous-core-known-red` | failure — **expected**, `continue-on-error: true`, tracks a real unfixed CONTINUOUS-CORE defect by design |
| `verify-core-verb-shard` | **cancelled at the 22-minute job timeout** |

### The finding: CI run #2424 tested nothing

`ralph/COORDINATION_2026-08-25_GATE_F_AND_GRASS.md` §1 records, as the verified
precondition for both lanes:

> `origin/main` is at `636673ce`. **CI run #2424 is green on that exact SHA**
> (`32862114528`, push event, conclusion `success`).

That run's conclusion is `success`. **Every one of its 26 jobs concluded
`skipped`.** Only `changes` executed, and it decided documentation-only, so
`verify-core-verb-shard`, all six unit shards, every regional and combat shard,
and `export` never ran. The commit it was green on
(`ralph: correct the handover's branch-cleanup section`) touched only `ralph/`.

So the green that the Gate F freeze was told to stand on is a **badge, not
evidence**. It says "nothing needed building", not "the code passes". Nobody
misread it; the run genuinely concluded success. That is exactly what makes this
class of false green dangerous, and it is the same class `conventions.md` warns
about from the other direction: *"Check `git log origin/main`, not the CI badge."*
The rule needs a second half — **check that the jobs actually ran**, because a
path-filtered skip and a real pass are indistinguishable at the run level.

**Consequence for Gate F:** run 2432 attempt 2 is the first run in this lineage
that has actually compiled and tested this code. The protocol's §A.4 requires a
green suite at the candidate SHA and says plainly that a red suite is a blocker
*before* the run rather than a finding of it. That precondition had never
genuinely been checked.

### The timeout is not the instrumentation's

`verify-core-verb-shard` runs `smoke_playground`, `smoke_input`,
`smoke_traversal` and `smoke_catching`, with the traversal smoke retried up to
three times and catching up to twice. The log shows it killed mid-`smoke_traversal`
while still emitting progress (severed-spokes recoveries, river crossings), at
22m50s into a job with `timeout-minutes: 22`. Not an assertion failure — a
workload that does not fit its budget once a retry fires.

Established rather than assumed:

- none of those four scripts is modified by this branch (`git diff --name-only
  origin/main HEAD --` over them is empty);
- none references any Gate F file;
- this branch adds 16 files and modifies zero.

`conventions.md` already measures `smoke_traversal.gd` at ~6 minutes and says the
twelve checks are bounded by the slowest single check. Three retried traversal
runs plus three other smokes cannot fit in 22 minutes. **The retry chain and the
timeout are in direct conflict**, and the job only survives while no retry is
needed. One confirming re-run has been triggered — the single re-run
`conventions.md` permits — to establish whether it clears without a retry.

This is a candidate finding for the Gate F backlog in its own right: a CI job
whose retry policy cannot fit its own timeout is a test that reports red for
reasons unrelated to the code under test, which is how a real defect gets
dismissed as infrastructure noise.

### What this does to the freeze

It does not block it. The candidate is `main` plus 16 additive files, the unit
suite is green across all six shards, and every gameplay shard that ran passed.
But the freeze record must state the baseline honestly rather than inheriting
§1's claim: **`636673ce` was never verified by a run that executed its tests**,
and the first real verification of this lineage is run 2432 attempt 2, with
`verify-core-verb-shard`'s timeout recorded as a pre-existing CI-budget defect
rather than a candidate defect.

---

## Check-in 5 — 2026-08-25 18:10Z — transcription complete; five pre-freeze gaps found and closing

Both transcriptions are committed. Measured scale of the authoritative run:

| lane | steps | planned `GF-` frames |
|---|---|---|
| journey S01–S10 | 1,011 | 57 |
| studies X01–X08 | 2,536 | 115 |
| **total** | **3,547** | **172** |

X01's matrix is **418 cells** (19 physical controls × 22 contexts), 487
`probe_cell` steps once the boundary and combat-edge probes are counted.

Both lanes' load-bearing confirmations came back clean: zero `teleport` in the
journey; `teleport` only in X07/X08 and only on `"diag": true` steps; save
handoff genuinely through the production Save tab and title-screen Load path
with `save_out` copying the artefact afterwards rather than standing in for a
save; `free_build` OFF everywhere but §E.3's single toggle, restored in an
explicit step; CT-06 and CT-09 written as expected **refusals**.

### Five gaps that had to close before the freeze — which is what §1.5 is for

Found by transcription, not by the run. Each would have been a blocker and a
re-freeze if it had surfaced mid-run instead.

1. **§H's continuous evidence had no action at all.** The requirement is a
   background recorder (0.5 Hz on high-risk segments, 0.1 Hz elsewhere, plus a
   frame on every event). The vocabulary had only `capture_seq`, which is
   bounded and blocking — so "every band handoff ±60 s at 0.5 Hz" was
   inexpressible. Adding `record_start`/`record_stop` plus a per-segment
   background rate.
2. **Nothing pinned the WorldLook clock** for X07, though §E.7 requires
   pin-and-freeze and names the artefact the unpinned variant produced on
   2026-08-23. The transcriber wrote all 15 pin notes the protocol asks for; the
   pin itself could not happen. Adding `pin_clock`, DIAG-only.
3. **The keyboard half of every dual-bound action was unreachable.** The
   harness resolves joypad → key → mouse, so W/A/S/D, E, I, M, Esc and Tab all
   injected pad events. §L.1's Mouse/KBM parity row was **half-covered while
   appearing covered** — the worst of the three states. Adding a `device` arg,
   with a missing binding recorded as a FAIL rather than falling back silently,
   because the silent fallback is how this stayed invisible.
4. **Four assert checks were missing** — mouse-capture, satiety, clock hour,
   placed buildings. All four values were already on the event fields, so X05
   was recording them and verdicting none: a load that silently dropped the
   player's placed buildings would have read PASS.
5. **§G had no row for the level-up shot §L.4 requires.** §L.4 asks for "first
   level-up moment captured; announcement verified visible ... shot + event" in
   S03; §G defined no row, and §C.4 forbids the operator inventing a planned id.
   The requirement was unsatisfiable by anyone. Added as `GF-19-UI-10`, recorded
   in the protocol as the single coordinator amendment rather than edited in
   silently — Fable authored Phase A and an edit to it has to be visible as one.

Note for §16.4, kept here rather than in the protocol: the register's
`HIST-053` records that a real defect once aborted **every** level-up
announcement in the chapter while its test stayed green by asserting on the
function's own source text. That is not why the row was added — §L.4's
requirement is — and the operator is told nothing about it, per §16.1
blind-first. It is recorded here only so the reconciliation can see that this
frame had independent reason to exist.

### Declared limitations, not solved

- **Same-frame probe at a combat edge.** `press_multi` must name a frame; a
  fight starts and ends on a frame the harness does not choose. World↔combat
  gets next-frame probes only.
- **The §L.5 website desk check** and **§E.9's `perf_profile` runs** — the
  harness cannot read a file off disk or launch a second process, and §10
  forbids modifying that tool. Both handled by the coordinator outside the
  harness, which is what §E.9 actually describes.
- **§L.5's optional "lose a tournament round"** needs a mid-S04 save that X04's
  three entry saves cannot supply. Recorded as a declared gap.
- **S03 is expected to FAIL `flag_set home_materials_gathered`**: the 20 village
  harvest nodes yield 28 wood / 9 stone against a 45 wood / 17 stone
  requirement. That is the owner's three-bed budget directive being genuinely
  paid rather than asserted. If it fails it is an economy finding, not a broken
  script.

### Why nothing is pushed right now

Runs 2432 (attempt 3), 2433, 2434 and 2435 all concluded **cancelled**. `ci.yml`
sets `cancel-in-progress: true` on non-`main` refs, so every push killed the
run before it. Four code CI runs have been started on this branch and **not one
has completed**, which is a real cost of pushing on every commit rather than at
a boundary.

So: no further pushes until the harness agent lands its five additions. Then one
push, one full run, allowed to finish — and that run is the freeze evidence.

---

## Check-in 6 — operator lane takes over; environment up; budget estimate before S01

**Lane:** operator (execution). The instrumentation lane is closed. `tools/gate_f/**`
and `scripts/debug/gate_f_probe.gd` are frozen from this point; I touch a
step-script only if it hard-blocks a segment, and I say so here when I do.

**Environment stood up on this container:**

- `libegl1 libegl-mesa0 mesa-vulkan-drivers xvfb` installed.
- Godot `4.7.stable.official.5b4e0cb0f` via `tools/art_pipeline/setup.sh godot`.
- `--headless --path . --import` running at the time of writing.

**Branch state:** `ralph/GATE-F-INSTRUMENTATION` @ `a3f61b60`, fast-forwarded to
`origin`. `git diff --name-status origin/main HEAD` is **35 files, every one `A`,
zero `M`, zero `D`**. (The register said 34; the 35th is the same lane's own
addition, not a modification.) The honest enumeration of non-instrumentation
changes in this candidate remains **none** — nothing under `scripts/`, `scenes/`,
`data/` or `project.godot` differs from `main`. That is what makes this SHA a
legitimate candidate to playtest: the build under test *is* `main`.

### Budget estimate for step 4, written before starting it

Gate F has spent $186 and produced no evidence. Remaining envelope as given: ~$130.

*Wall clock*, from the step-scripts themselves (sum of `wait` seconds + `stick`
frames/60 + `move_to` steps at a 20 s average against their 2400-frame ceiling),
excluding scene boot:

| | scripted time | + boots | notes |
|---|---|---|---|
| S01–S10 | ~71 min | ~10 boots | S03 is the long one (16 min, 274 steps, 28 walks) |
| X01–X08 | ~190 min | ~12 boots | X05 alone is ~79 min of deliberate wait; X04 ~29, X06 ~28 |

World boot measured by the instrumentation lane at ~90 s on this container, so
add ~15 min per lane. **Journey ≈ 1.5–2 h wall clock, studies ≈ 3.5–4 h.** That
is if capture mode is affordable on the world scene, which is the open question
below.

*Spend*, which is what is actually capped: my cost is per-turn context, not wall
clock — a segment running in the background costs nothing while it runs. Held to
the discipline of launch / poll / bounded-summary / commit / one log line, a
segment cycle is ~4–6 tool calls. I estimate **$3–6 per segment cycle**, so
**S01–S10 ≈ $40–60** and **X01–X08 ≈ $35–50**, plus setup already spent.

**Assessment: the full journey plus studies plausibly fits ~$130, but with no
slack for a segment that fails and needs diagnosis** — and on a first execution
of an instrument this size, some will. So I am ordering the run by value rather
than by the protocol's convenience, and committing each segment the moment it
finishes:

1. **S01–S04** first, unconditionally — opening through tournament, the subset
   that decides whether a new player keeps playing at all.
2. **S05–S10**, continuing the same chained save.
3. Studies in value order: **X07** (world audit; 3 min of script, 80 shots, by
   far the best evidence-per-dollar), **X01**, **X04**, **X03**, **X02**, **X06**,
   **X05**, **X08**. X05's 79 minutes of waiting and X08's 6 minutes of held
   stick are the two I would drop first if the cap bites.

**Scope reduction is the owner's call, not mine.** I am not pre-emptively cutting
anything; I am recording the ordering now so that if the budget ends the run
mid-way, what survives is the part that matters most, and the fact that it ended
early is visible here rather than inferred from a gap.

**Open risk, flagged before the run rather than after:** the harness config's own
note records that under llvmpipe *"six twenty-second windows did not complete in
fifty minutes"* on the Meadows. If capture mode on the world scene is that
expensive, the journey segments may have to run in logic mode, taking their
manifest rows as `file: null` per §C.4 — honest evidence, but no frames. I will
establish which it is empirically on S01 and record the answer here before S02,
rather than discovering it at S08.
