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

---

## Check-in 7 — harness smoke passed; one real finding out of the self-check

Both smokes ran on `a3f61b60` with Godot 4.7.stable, imported cache 1728 assets.

**`selfcheck_capture` — 6/6 PASS, and the frames are real.** Capture mode reached
the framebuffer at the **requested 1920×1080 with no fallback**
(`CAPTURE_RESOLUTION.json`: `"substituted": false`). I opened `SC-C-title.png`
rather than trusting the byte count: it is the shipped title screen, correctly
composed — "THE MEADOWS / TETHERBOUND", the tagline, three focusable buttons with
Start New Game holding a visible focus ring, the A/D-pad hint line, and the
parallax landscape with the tether pylon. Not a black frame, not a stub.

The three `SC-C-seq-*.png` frames are byte-identical to each other and *different*
from `SC-C-title.png`. That is the correct result, not a stuck recorder: the focus
move happened between the two (so the pair differs), and nothing animates during
the 0.75 s window (so the triple matches).

**`selfcheck_walk` — 11 PASS, 1 FAIL, exit 0.** The trace instrument itself is
sound: 140 route rows over the 10 s idle + 60 s walk (2 Hz, as specified), the
teleport recorded as a teleport with the accumulators reset, 162.3 m walked on a
held stick, and the dead-travel meter resetting correctly through populated band 1
(peak 24.9 m against a 30 m ceiling).

`SC-W-11` FAILED: dead travel peaked at **24.9 m against a `>= 25.0 m` threshold**.
I am **not** adjusting that threshold. Tuning an assertion by 0.1 m to make a
self-check go green is the exact move this lane exists to not make, and the
number is not the interesting part anyway.

**The interesting part is why, and it is a candidate defect.** The second walk —
`SC-W-10`, 7200 frames of full-forward left stick, two solid minutes — moved the
player **zero metres**. Total distance walked is 162.3 m after step 6 and still
162.3 m after step 10. The route trace shows position pinned at
`(-161.03, 2.13, 286.01)` and heading pinned at `-49.4°` for 120 consecutive
seconds, identical to two decimal places on every row from t=160.45 to t=280.94.

What it is *not*: `input_context` stays `world` for the entire stall, and
`events.jsonl` records **no** combat, dialogue, menu or region event in that
window. So this is not locomotion being legitimately held by a conversation or a
fight — the world verbs are live, the stick is being read, and the player does
not move. `nearest_poi_dist_m` sits at 0.62 m throughout, which is also why the
dead-travel meter reads 0.00 and never climbed to 25: the player is wedged
*inside* a point of interest's radius, so the meter correctly keeps resetting.
The failing assertion is a true report of a stuck player, not a bad threshold.

Recorded as a candidate reliability defect: **player can become permanently
immobile in the open world with input context still `world` and no holder**.

Two constraints on that, both binding:

- It came out of a **DIAG** segment that teleported to its start point, so per §0.6
  and §J **no pacing, navigation or economy claim may be sourced from it** — and I
  am making none. "Player got stuck" is a reliability observation, which is the one
  class a DIAG segment can legitimately carry.
- I am the operator, not a developer (§13): I am **not** diagnosing the cause and
  **not** fixing it. It is recorded, with its evidence preserved under
  `ralph/reports/gate-f-selfcheck/selfcheck_walk/`, and the journey segments will
  say whether a player on a production route ever meets it.

Worth noting against the instrumentation lane's own recorded baseline: that lane
measured 326 m over this same segment on this same SHA. I got 162.3 m and a hard
stall. Same script, same commit, different outcome — so whatever this is, it is
**not deterministic**, which is itself part of the finding.

Tooling is now **frozen**. Both smokes run; nothing further gets "improved."

---

## Check-in 8 — S01 committed. Capture mode is off the table for the journey; here is the number.

**S01 — 13 PASS / 1 FAIL.** Evidence in `ralph/reports/gate-f-run-20260825T201354Z/S01/`.

**Mode change, forced by measurement, recorded before it is used.** S01 was first
run in **capture** mode as §H requires. All 14 steps executed (last event
`t=180.8`), then the process never terminated — 35 minutes later the step list was
exhausted, `events.jsonl` frozen at 14 records, and `frames/` held **one PNG**
against §H's requested one-every-two-seconds. `route.csv`'s own `frame_ms` column
says why: **~3,400 ms per frame, sustained — 0.29 FPS — with a single physics step
at 611 ms.** That is llvmpipe drawing 466,922 props with no GPU. It is a fact
about this container and **not** a device frame-rate claim; §K.1 stays [OWNER-ONLY].

The attempt is preserved at `ralph/reports/gate-f-run-20260825T201354Z/S01-superseded-1/` with `WHY_SUPERSEDED.md` and
its one real frame (`GF-01-TITLE-01.png`, a correct 1920×1080 title screen). It
was killed, not deleted, and `notes/` is empty there because the harness writes
verdicts at a segment end this segment never reached.

**So the journey runs in logic mode** (`--headless`, no rendering driver — the
shape §0.2 and `ralph/conventions.md` both call correct and fast; ~5 ms/frame
here). S01 then completed cleanly. Every planned shot becomes a manifest row with
`file: null`, which §C.4 states is itself evidence. Visual evidence will come from
**X07**, the DIAG world audit: 80 teleport-sited stills with no walking between
them, the one segment shape this box can still render. **This changes how the run
executes, not what it executes** — steps, assertions and telemetry are untouched,
and the missing frames are recorded rather than papered over.

### The S01 failure

`S01-12` FAIL. Expected the fresh-game tracked objective to be
`opening_first_catch`; the game tracks `opening:beat:road`, text *"Catch your
first wild creature."*

I am recording this exactly as it came out and **not** editing the step-script to
match the shipped id. Read plainly: the objective a new player sees is the right
one — the text is precisely the intended first rung — but **the objective id named
throughout the protocol's §E.5 chain does not exist in the build.** Whether that
makes it a defect in the game's chain ids or a defect in the protocol's expectation
is a Phase B call, not mine (§13: record, do not diagnose). It matters beyond one
assertion because §E.5 tracks 24 main-chain objectives by id, so if the id scheme
differs everywhere, later objective assertions will fail the same way and each one
needs reading as this same question rather than as 24 separate bugs.

The other 13 steps passed: fresh `user://` wiped clean, title booted in 375 ms with
`Start New Game` holding focus, one `ui_accept` tap resolved to `JoyBtn:0`, the
world stood up, region `grandpas_village`, party size 0, and 354 route rows.

---

## Check-in 9 — **BLOCKER at S02. The journey chain stops at the opening.**

**S02 — 52 PASS / 19 FAIL, no exit save.** Full report at `ralph/reports/gate-f-run-20260825T201354Z/S02/BLOCKER.md`;
telemetry and notes committed alongside it.

The nineteen failures are not nineteen problems. They are one problem with
eighteen consequences. `route.csv`'s `input_context` column changes five times in
the entire segment and then never again:

```
0.38  title
2.68  world
53.94 locked            (the wake beat)
56.00 world
253.38 narrative_modal  <- and it stays here for the remaining ~1,750 s
```

The opening's modal opens at **t=253.4**, about three seconds after the script's
last input burst and sixteen seconds after the first `interact` on Grandpa. Every
step that would have answered it — advance the briefing, pick the orb, confirm,
name the starter — had already run, into a `world` context, against no modal.
Everything after that fails downstream of one held modal: three walks report
`locomotion never came back: held ... by input_context 'narrative_modal'`, the
segment walked 10.1 m against a 150 m expectation, the party never reaches 1, the
road gate flag never sets, and slot 4 has no file, so **there is no S02-exit save**.

**Consequence for the run:** S03–S10 each entry-depend on the previous exit save
(§B), and X01–X06 seed from journey saves. All of them are blocked. **X07 and X08
are DIAG segments that need no journey save and remain runnable** — I am going to
them next, which is continuation of the parts that stayed valid, not improvising
around the blocker.

### The candidate defect worth the coordinator's attention

Three late steps identify what is holding input:

- `game_menu` did not open the pause shell: `narrative_modal -> narrative_modal
  (owner=StarterPicker)`
- `4 × ui_down did not move focus off **nothing**`
- slot 4 has no file — nothing could be saved

**The StarterPicker owns input while nothing owns focus.** Directional input has
nothing to move between, confirm has nothing to activate; the modal cannot be
answered or dismissed, locomotion stays held, the pause shell will not open, and
the game cannot be saved. In that state the chapter is unexitable.

**And the caveat, which travels with the finding:** the script pressed `ui_right`
and `menu_confirm` *before* the picker existed and only probed it afterwards. It
is **not** established that a human pressing at the right moment gets locked out.
What is established is that the picker sat open and input-owning for ~1,750 s and
every input sent to it in that window did nothing. Two readings fit — the picker
opens with no focused control (chapter-ending), or it fails to take focus when
input arrives late (recoverable). Separating them is diagnosis, which is not the
operator's job (§13), and I have not done it.

### What I did not do

I did not touch `tools/gate_f/**`. The temptation here is obvious — insert a wait,
re-order two asserts, and S02 probably goes green. That would convert the single
most interesting result this run has produced into a passing line, and it would be
me deciding, alone and unwatched, that the opening is fine. §A is explicit that a
blocker's fix happens outside the run against a newly frozen SHA. So: recorded,
committed, reported, and the build is untouched.

**This is also the answer to the question Gate F exists to ask.** A first-time
player's very first interaction in Tetherbound is talking to Grandpa and choosing a
starter. On this SHA, a scripted run of exactly that path ends with the player
frozen in an unanswerable modal 253 seconds in, with 10 metres walked. Whatever the
root cause turns out to be, the opening is where the evidence says to look first.

---

## Check-in 10 — X07 and X08 in; **and a correction to my own S02 blocker report**

### X08 — 62 PASS / 0 FAIL

The perf audit ran clean, headless, start to finish. Committed at `ralph/reports/gate-f-run-20260825T201354Z/X08/`.

### X07 — 79 of 80 audit frames, no harness verdicts

Killed by my own 4,200 s cap one capture short of the end; exit 143 is that
SIGTERM. **It was still working when it died** (last event: `captured
GF-14-COMBAT-13b at 1920x1080`), so this is a run that ran out of my clock, not
one that hung. 79 real 1920×1080 PNGs, no resolution fallback. `notes/X07.md` is
empty because the harness writes verdicts only at a segment end this segment never
reached; I derived the outcomes by hand from `expected`/`actual` in
`events.jsonl` and **labelled them as derived** in `X07/INCOMPLETE.md`.

19 of 22 assertions clean. Three not, and two of those are E.7's own subject:

| t (s) | derived FAIL |
|---|---|
| 1964.2 | teleport to `the_long_water`'s centre landed **11.3 m off** a 5.0 m tolerance |
| 2580.1 | at the stronghold approach's own centre: **`region=corridor`**, expected `stronghold_approach` |
| 2709.3 | at the Hall's own centre: **`region=corridor`**, expected `hall` |

Standing at the published centre point of two named late-chapter regions, the
game's containment reports neither — it reports `corridor`, the id meaning
"between places."

### Correction: the S02 blocker is NOT a focus bug, and the picker is not broken

Check-in 9 offered two readings and said only a fix-side investigation could
separate them. It has been separated, and **both readings were wrong.** I am
correcting this here because a developer lane acting on my earlier wording would
go and fix a non-bug.

`scripts/ui/starter_picker.gd` reads input by **polling**:

```
377   if Input.is_action_just_pressed("menu_confirm"):
379   elif Input.is_action_just_pressed("ui_right"):
381   elif Input.is_action_just_pressed("ui_left"):
```

It needs no focused control, by design, and `ui_down` is not one of its inputs at
all. So `4 × ui_down did not move focus off nothing` is the harness probing a
poll-driven panel with a verb it does not read. **The picker sat open waiting
correctly for input the script never sent it.** Nothing is wrong with the picker.

**The real failure is upstream of it: Grandpa's briefing never opened.**

`route.csv` samples `input_context` about every 1.6 s across the whole window
(1,256 rows, largest gap in the segment 51 s and that during boot). From t=56.0
to t=253.4 it reads `world` on **every one of 47 consecutive samples**. The probe
maps `dialogue_panel.gd`, `name_prompt.gd` and `starter_picker.gd` all to
`narrative_modal`, so a briefing that opened at any point in there would have
been caught. It never opened.

And it is not a reach problem. Position, from the trace:

| t (s) | player |
|---|---|
| 228.9 – 237 | (-25.40, -15.60) — the wake spot |
| 238.3 – 249.6 | **(-24.50, -15.68)** — where all 31 `interact` presses landed |
| 251.3 | (-22.62, -17.36) |
| 252.9 | (-17.74, -18.26) |
| 254.4 | (-17.74, -17.34), `narrative_modal` |

`grandpa_house.gd:137` puts Grandpa's marker at `to_global(Vector3(-2.4, 0, 1.2))`
on a house whose origin is `HOUSE_AT = (-22, -16)` — so he stands at about
**(-24.4, -14.8)**. The player was **~0.9 m from him**, with `arbiter_enabled:
true` in `input_state` and a prompt radius of 3.8 m
(`sequence_director.gd:861`), and pressed `interact` 31 times over 13 seconds
with nothing happening. The walk itself passed honestly: the step sets
`close_enough: 3.0` and stopped 2.5 m from its target, inside its own tolerance.

Then, with no stick input in flight, the player slid ~5 m between t=251.3 and
t=252.9 and the picker opened at t=253.4 — unprompted by anything the script did.

**So the question for the fix lane is: why does `interact`, pressed 0.9 m from
Grandpa during the `house` beat with the arbiter enabled, not open
`grandpa_house`?** One candidate I can see but have not tested is the binding
itself — the harness resolves `interact` to `JoyBtn:2`, and if that is not what
the arbiter reads, no interact in the run ever landed, including the "get up"
press. That is a hypothesis, not a finding, and testing it is developer work.

**Nothing on the candidate has been touched.** Per §1.6 the fix goes on a separate
branch and a new SHA is frozen before S02 is re-run; the S01/S02/X07/X08 evidence
on this branch stays attached to `a3f61b60`, and the seam will be stated plainly
rather than spliced.

---

## Check-in 11 — the opening is recovered; the house exit is not. Tuning stopped.

**S02 best result: 62 PASS / 12 FAIL, still no exit save.** Full report at
`ralph/reports/gate-f-run-20260825T201354Z/S02/BLOCKER.md`. Four attempts preserved as `S02-superseded-1..3` plus the
current `S02/`.

### Attempt 1's diagnosis was wrong, and the correction is the useful part

The real defect was **in the step-script, not the game.** `S02-15 "walk down to
Grandpa"` targeted `[-22,-16]` — the house *origin* — with `close_enough: 3.0`.
`move_to` compares **x/z only**, and the bed is 0.89 m from Grandpa in x/z while
**3.3 m above him in y**: the player wakes on the loft (`grandpa_house.gd`,
`LOFT_W 4.6`, `FLOOR_H 3.2`). The step passed honestly and left the player one
storey up, and the segment then pressed `interact` 31 times **through the floor**.
Route trace y during those presses: **4.93, 4.65, 4.65**. Grandpa's marker: **1.32**.

The house already publishes the fix — `stairs_top` and `stairs_bottom`, commented
"for anything that has to NAVIGATE the house rather than …". Routing the walk
through them recovered the opening: the player descends, Grandpa offers his prompt,
the briefing plays, and **`party_size` reaches 1 — the starter is chosen and named
through the production path.** Ten assertions recovered.

**So the game needed no fix.** Two probes on `ralph/OPENING-STARTER-FOCUS`
(`tools/opening_fix/`) establish it, including one that kills the scariest
hypothesis: the harness injects presses during idle while
`interaction_arbiter.gd` polls from `_physics_process`, which would have
invalidated **every `interact` step in the protocol** — measured, and it is false.
No game file changed, so **no new candidate SHA is needed and there is no §1.6
seam**; S01, X07 and X08 stay valid against `a3f61b60`.

### What is still blocked

From the briefing onward a `narrative_modal` owns input continuously, the player
never leaves the house, and `S02-63` names the holder: **`owner=DialoguePanel`**.

| attempt | S02-28 presses | extra wait | PASS/FAIL | modal block | exit save |
|---|---|---|---|---|---|
| 2 | 12 × settle 20 | — | 61 / 12 | 121 s | none |
| 3 | 20 × settle 30 | 5 s | 62 / 12 | 121 s | none |
| 4 | 4 × settle 30 | 5 s | 62 / 12 | 139 s | none |

Same twelve assertions, same values, three press counts. **The press count is not
the variable**, which rules out "the script under-presses the conversation" —
`grandpa_named` is three lines, so 4, 12 and 20 are all sufficient. Two facts
constrain whoever picks this up: **nothing is pressing anything for the last ~110 s
of the block**, and **the block ends at exactly 7201 held frames, twice, to the
frame** — the instant `S02-30`'s `held_budget_frames: 7200` expires and the
observer stops waiting.

### Why I stopped

I changed `S02.json` twice — the stair routing, which was decisive, and a
transition allowance, which changed nothing — and said in advance that a third
distinct wall would end the tuning rather than start another round. It did, so I
stopped. Continuing would have meant reshaping a frozen step-script against a game
behaviour I do not understand, alone and unwatched, until something went green.
That is how a run stops being evidence. I did not turn on `answer_prompts` for the
blocked walk either: the schema says it "must stay off in any segment whose subject
is whether something blocks travel," and something is blocking travel.

### Run status

| | |
|---|---|
| S01 | 13 PASS / 1 FAIL — committed |
| S02 | 62 PASS / 12 FAIL — **BLOCKED**, no exit save |
| S03–S10 | blocked on S02's exit save |
| X01–X06 | blocked — they seed from journey saves |
| X07 | 79/80 audit frames, 3 derived FAILs — committed |
| X08 | 62 PASS / 0 FAIL — committed |

Journey coverage is the opening only. The DIAG lane is complete. **The [OWNER-ONLY]
set has not moved**: no device frame rate, GPU, VRAM, thermal, audio, controller-feel
or Windows-export claim appears anywhere in this run's evidence.
