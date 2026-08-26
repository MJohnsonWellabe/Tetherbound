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

## DEFECT-FIX lane — check-in 1 — 2026-08-26 — items 1 and 3 fixed and pushed; item 2 is not the defect it was reported as

Branch `ralph/GATE-F-DEFECT-FIX`, off `main` at `7dae36c6`. This lane is the
**defect-fix** role of §13, not the operator: it does not run segments, and a
separate session re-runs S01–S10 / X01–X07 after these land.

### Item 1 — permanent immobility in the open world. FIXED.

`scripts/player/player_controller.gd::_recover_if_entombed`, tuned from a new
`unstick` block in `data/config/movement.json`.

What the evidence actually says, re-derived from `S05/telemetry/route.csv` on
`ralph/GATE-F-INSTRUMENTATION` rather than taken on trust:

- 1,004 rows read exactly `91.39, -6.00, 821.68`, and the pinned run is 1,019
  rows counting the two that drift 91.38 → 91.39 first. Total movement over the
  whole eight minutes: **under 2 cm.**
- The `heading` column across those rows takes **more than twenty distinct
  values**. Heading is only written in `_face`, which only runs when
  `_apply_movement` resolved a non-zero direction — so the stick was held, in
  many different directions, for the whole eight minutes, and the body went
  nowhere in any of them.
- `y = -6.00` is **not** below-terrain. The 60 rows before the freeze walk that
  same stretch at y between +1.35 and −7.08, rising and falling smoothly: the
  corridor is genuinely below zero there. This is a pocket, not a fall, and it
  is unrelated to the `ground_height_at()` NaN class the dispatch note
  suggested relating it to. Worth saying plainly so the next lane does not
  spend the search there.

Why `_unwedge` never covered it: it steers along ONE tangent of the wall normal
and resets its own timer (`_wedged_for = 0.0`) the moment `_ground_under` says
that one step is not clear. In a pocket whose contacts oppose, that tangent is
into the opposite face, so the deflection is rejected every frame and nothing
else is ever tried. Right tool for a boulder; nothing to offer a box.

The fix, and the part that matters most about it: **time-without-progress only
opens the question.** `_entombed_at` decides it, by sweeping eight compass
directions through the physics server from `STEP_HEIGHT` up. If any one of them
is clear the body can still walk out and **nothing happens** — which is what
keeps a player leaning on a cliff from ever being moved. Recovery then rewinds
to a breadcrumb: ground this body stood on and walked away from, so a recovery
can never grant access to anywhere the player had not already legitimately
reached. Lifting is a bounded fallback for when there is no usable breadcrumb.

**Proof it discriminates**, per the standing rule that a test which cannot fail
on the unfixed code is not evidence. `tests/smoke_unstick.gd` walks the body on
open ground, then seals it in a six-sided box (lid included, so only the
breadcrumb path can resolve it) with the stick still held:

- `unstick.enabled: true` → `recovered 9.82m clear after 1 recovery`, passes.
- `unstick.enabled: false` (the pre-fix path exactly) → **FAIL: sealed in at
  0.00, 0.00, -14.74 and still there 6.0s later (moved 0.15m, 0 recoveries)**.

The same file's second case walks the body into a cliff and holds for six
seconds, and asserts the controller's own recovery counter is **zero**. A
failsafe that fired during ordinary play would be worse than the bug.

Regressions run: `smoke_input` OK, `smoke_riding` OK, `smoke_traversal` (result
in the next check-in). `smoke_step_up` fails — **and fails identically on a
clean `main` checkout** (`git stash`, same two FAILs, `z=-16.74`, `y=0.00`): the
trainer walks through both the step and the 2 m barrier. Pre-existing, not from
this branch, and not in `ci.yml`. Flagged, not touched.

### Item 3 — X07's three identical camera variants. FIXED.

`tools/gate_f/segments/X07.json`. **Sanctioned exception to the `tools/gate_f/**`
freeze**, recorded here and in every changed step's own `observation`, exactly
the way the handover's §5 changes are recorded.

All eleven region blocks took their six audit frames from one `face` step, which
is why the visual pass measured `arrival`/`gameplay`/`landmark` at 0.1–2.3%
pixel difference. Each block now sweeps five bearings and two pitches:

- `gameplay` + `arrival` keep the entry bearing (they are a hud:on/hud:off pair
  and are *supposed* to share it);
- `landmark`, `ecology`, `vegetation` get the entry bearing turned 72 / 144 /
  216°, computed from each block's own existing `at`;
- `terrain` returns to the entry bearing and pitches to the camera's own floor
  via the right stick, then restores to `pitch_start_deg` by driving to the
  opposite clamp and back — both ends clamp, so it lands on the same angle every
  time rather than on whatever the frame budget bought.

**No position is moved** — E.7 fixes them before play and forbids moving them to
improve a composition — and **no coordinate is invented**. Where
`data/config/map_landmarks.json` carries a landmark more than 20 m from the
block's position, the `landmark` slot aims at that instead of at the 72° arm:
`grandpa_house` for `grandpas_village`, `road_gate` for `the_rise`, and the
`silhouette: true` stronghold for `stronghold_approach` — which is precisely the
frame the visual pass found had no stronghold in it.

Frame count is unchanged at 80. `test_gate_f_instrumentation.gd`: 17 tests,
23,424 assertions, 0 failed.

### Item 2 — "night and weather do not render". NOT CONFIRMED, and the labelled defect is in X07.

This is the one place I am contradicting the dispatch, so here is the
measurement rather than an opinion.

`X07/telemetry/route.csv`, all 135 rows of the 2026-08-25 run:

- `clock_hour` runs **8.16 → 11.14**. It never leaves mid-morning.
- `weather` reads **`clear` on every single row**.

Every frame in that segment — the six labelled `-night` and the four labelled
`-weather` included — was captured at mid-morning in clear weather. The
luminance table (day 96.6 vs "night" 99.2) is therefore not a measurement of
night rendering; it is two day frames, correctly reporting that they are both
day frames.

The cause is in `X07.json`, not in the renderer. Every "DIAG PIN" step in it is
an `action: "note"` whose text *claims* a pin. `X07-002` states outright that
"SEGMENT_SCHEMA.md's vocabulary has no clock-pin action" — **that is now stale.**
`pin_clock` is implemented (`operator_harness.gd:501` dispatch, `:1572`
`_step_pin_clock`), documented in `SEGMENT_SCHEMA.md` under Setup and time, and
covered by its own test
(`test_pin_clock_freezes_both_clocks_and_is_diag_only`). X07 simply never
called it.

**Fixed on this branch:** all 19 pin notes are now real `pin_clock` steps,
`diag: true`, day at `hour 11.0` / `clear`, night at `hour 23.0`, weather
variants at `rain` and `fog`, `freeze: true`, pinned after the settle per
`_step_pin_clock`'s own ordering note. `hour` rather than `preset` deliberately:
it drives `world_look.gd::_apply_blended`, the same continuous path `_process`
uses, and it makes the `clock_hour` recorded on every manifest row honest — a
preset snap would have left the telemetry still reading morning and a future
reader repeating this exact mistake. `X07-002` is rewritten to say what
superseded it, and kept rather than deleted because the run it describes is on
the record.

**What is still open:** whether night actually renders dark is now an *untested*
question rather than a settled one — the evidence that was supposed to answer it
never pinned anything. I am measuring it independently before making any claim
either way, with `tools/_capture_day_night_transition.gd`, which drives the same
`_apply_blended` path across a twelve-hour sweep from one fixed viewpoint. That
result goes in the next check-in. **If it comes back flat, item 2 is a real game
defect and I will fix it; if it comes back dark, the only defect was the label,
and the re-run's night frames will be night.** Either way the X07 fix above is
required first, and it is in.

### Not started yet

Item 4 (visual defects: Team Tether teal, the black-cutout trainer, the
placeholder box, the `hall` black sphere, `the_rise`'s camera in the hillside,
and the grass lane's duplicated/airborne trainer, floating oversized band-3
house and leaked oxblood boulder) and item 5 (the S02 drop-confirmation
trigger). Next check-in.

### Constraints observed

No `main` push, no PR. Nothing touched under `shaders/`,
`data/config/grass_field.json`, `data/config/terrain_playground.json`,
`data/config/vegetation.json` or `data/scatter/**` — the grass lane's files. No
device claim: everything above is a file, a config value or a container
measurement.

---

## DEFECT-FIX lane — check-in 2 — 2026-08-26 — X07 fix is PUSHED (gates the run); night is red in ordinary play, cause isolated and fixed

### First, the thing the coordinator asked to be told explicitly

**The `X07.json` fix is pushed.** Branch `ralph/GATE-F-DEFECT-FIX`, commit
`a2b80641`, pushed at 02:47Z, CI run 2490. It contains BOTH X07 changes:

1. the six-per-region camera fix (three of six variant slots were one shot), and
2. **19 real `pin_clock` steps** replacing 19 `action: "note"` steps that only
   claimed a pin.

The second one was not on the original work list and matters more for the run.
X07's own `route.csv` from 2026-08-25 reads `clock_hour` 8.16 → 11.14 across the
whole segment and `weather: clear` on **all 135 rows**. Every frame labelled
`-night` and `-weather` was captured mid-morning in clear weather. Without this,
the overnight X07 re-run would have produced ten more mislabelled day frames.

Nothing else in `tools/gate_f/**` is touched. Both changes are recorded in every
changed step's own `observation`, per the freeze rule.

### The ordering directive is understood and is being followed

No visual judge, no blind critic pass, no X07-style capture batch until `main`
is called complete. What has run here is diagnosis and fix verification of
single named defects — an A/B of one frame, and a twelve-hour sweep of one fixed
viewpoint measuring one channel ratio. No conclusion about how the game looks
overall has been drawn or will be until the word comes.

This also **changes which item-4 defects are worth doing tonight**, and that is
worth saying rather than quietly reordering. `ralph/WORLD-GRASS` and
`ralph/GRASS-FIELD` are landing grass scale, ground-material tiers, sky and
clouds, stone and path grit, and narrowed paths. Four of the item-4 findings sit
directly on top of that work — the near-black trainer (a lighting/key question),
`the_rise`'s camera inside a hillside (terrain), the floating oversized band-3
house, and the oxblood boulder in band 1. Diagnosing those against a build that
is about to be replaced is the wasted cycle the directive is guarding against,
so they are deferred until `main` settles rather than being worked now. The
grass lane's own findings (duplicated airborne trainer, band-3 house, band-1
boulder) came with frames I do not have and coordinates I could not recover from
config, which is a second, independent reason to wait for them.

### Night renders. It renders RED. Cause isolated, fixed, and the fix is tested.

Check-in 1 said item 2 was "not confirmed" and that I was measuring it. Here is
the measurement, and it found something worse than the original report.

**Night lighting works.** Twelve-hour sweep, one fixed viewpoint
(`tools/_capture_day_night_transition.gd`): mean luminance ramps 115.0 at hour
08 down to 60.8 at hour 23.9, smooth and monotonic through dusk. A 1.89× spread.
The renderer draws night.

**It draws it crimson.** Same sweep, mean channel values:

| hour | R | G | B | R/B |
|---|---|---|---|---|
| 17.90 | 86.4 | 104.1 | 85.8 | 1.01 |
| 20.50 | 54.0 | 95.2 | 107.0 | **0.50** — cool, correct |
| 22.00 | 135.0 | 48.1 | 39.5 | **3.42** — blood red |
| 23.90 | 120.1 | 36.1 | 33.1 | 3.62 |

The dusk ramp is correct right up to 20.50 and then flips. No blend can do that:
`night`'s palette is cool throughout (`#1b2d5c` sky, `#3d5285` horizon, `#2a3b6e`
ambient, `#b7c6ea` sun) and `golden`'s is warm, so every intermediate lies
between a warm and a cool.

**What changes there is a snap, not a blend.** `world_look.gd::_blend_dict` has
no meaningful blend for a boolean and snaps one at `t >= 0.5`. `night` was the
only preset declaring `adjustment_enabled`. `golden` is at hour 18 and `night`
at hour 0, so `t = 0.5` falls at **exactly hour 21.0** — between the last cool
frame and the first red one.

**My first hypothesis was that the colour grade caused the red. It is the
opposite, and the A/B says so.** `tools/_probe_night_crimson.gd` boots the world
once, pins hour 22, freezes the clock, and shoots the same frame twice, changing
nothing but that flag:

- as shipped, grade **on** — R 41.7 G 77.5 B 94.2, **R/B 0.44**: a correct cool night
- grade **forced off**, nothing else touched — R 130.1 G 46.6 B 46.2, **R/B 2.82**

Identical geometry, identical shadows, hue rotated to red. So the defect is the
**toggle**, not either state, and the red follows whichever direction it is
thrown.

**This is not a capture artefact.** The day is 600 seconds. Tracing the merge:
`golden → night` snaps the flag false → true at hour 21.0, and `day → golden`
resolves to no key at all and snaps it back to false. That is **two toggles per
ten real minutes of ordinary play**, on the renderer the game ships on (D01).
The world goes red at night for the owner, not just for the harness. It is also,
almost certainly, the "2026-08-23 crimson artefact" that `X07.json`'s own note
warns about and attributes to an unpinned clock — the attribution was wrong; the
clock was never the mechanism.

**The fix** is to stop toggling it. `art.json`'s base `environment` block now
declares `adjustment_enabled: true` plus the three grade values at 1.0
(identity), so every preset inherits one always-on, no-op grade;
`world_look.gd::_apply_environment` sets the flag to a constant `true` and no
longer reads it from config at all; and `night`'s own `adjustment_enabled` key is
removed. Night's actual grade is unchanged — `adjustment_saturation` 0.72 and
`adjustment_contrast` 1.08 — and now **lerps in smoothly from 1.0** instead of
arriving all at once at hour 21, which quietly fixes a second defect the snap
was causing.

**Proof it discriminates.** `tests/test_night_grade_never_toggles.gd` pins two
independent halves, each of which fails alone. On the tree as it stood before
this branch, the config half fails outright: *"art.json's `night` preset declares
adjustment_enabled. A per-preset value is exactly what `_blend_dict` snaps at
t >= 0.5."* That is not a hypothetical — it is the failure I watched it produce
before removing the key. Both halves now pass, 15 assertions. The test is a
source-and-config test on purpose, per D02: this harness is pure logic, and the
rendered proof lives in the two tools, whose numbers it quotes rather than
re-measures.

A confirming twelve-hour sweep on the fixed build is rendering now; its result
goes in the next check-in. It is verification of a named fix, not a judging pass.

### Correction to check-in 1

Check-in 1 said that if night came back dark, "the only defect was the label."
That was wrong, and only half the story: the label WAS a defect and is fixed, but
underneath it the world has been turning red every night in ordinary play. Both
are real; the second is the more serious.

### State

| item | status |
|---|---|
| 1 — permanent immobility | **fixed, pushed** (`a2b80641`), `smoke_unstick.gd` discriminates |
| 2 — night/weather | **X07 mislabelling fixed and pushed**; **crimson-night cause isolated and fixed**, render confirming |
| 3 — X07 three identical cameras | **fixed, pushed** (`a2b80641`) — this is the one that gates the overnight run |
| 4 — visual defects | four of them deferred pending the grass lanes, with reasons above |
| 5 — S02 drop-confirmation trigger | not started |

`smoke_step_up.gd` still fails on a clean `main` checkout (the trainer walks
through both a 0.3 m step and a 2 m barrier). Pre-existing, not in `ci.yml`,
flagged and not touched.

### Constraints observed

No `main` push, no PR. Nothing touched under `shaders/`,
`data/config/grass_field.json`, `data/config/terrain_playground.json`,
`data/config/vegetation.json` or `data/scatter/**`. No device claim anywhere: the
numbers above are channel means over committed PNGs and values read out of
config.

---

## DEFECT-FIX lane — check-in 3 — 2026-08-26 — CORRECTION: the night fix in check-in 2 does not fix the night

### The correction, first

Check-in 2 and commit `379f9bc2` both claim the crimson night is fixed. **They
are wrong.** I re-ran the twelve-hour sweep against the fixed build and it is
unchanged:

| hour | R/B before the fix | R/B after the fix |
|---|---|---|
| 20.50 | 0.50 | **0.53** |
| 22.00 | 3.42 | **3.43** |
| 23.90 | 3.62 | **3.62** |

The world still goes red. `adjustment_enabled` is not the mechanism, and I
should not have pushed a headline that said it was before this render came back.
Landing the fix and reporting it in the same breath as the diagnosis was the
mistake; the render was already running and I had no reason not to wait for it.

The comments in `world_look.gd`, `art.json` and
`tests/test_night_grade_never_toggles.gd` now all say this in their first
paragraph, so nobody reads the branch and concludes the defect is closed.

### What the pushed change is actually worth

I have kept it rather than reverted it, on narrower grounds, and it is now
described that way everywhere:

- The boolean snap is real. `_blend_dict` cannot blend a boolean, `night` was the
  only preset declaring the flag, and it flipped at exactly hour 21.0 on
  `golden → night` and back on `day → golden` — twice per 600-second day. That
  switched the whole grade pass on and off mid-blend and landed night's own
  saturation/contrast all at once instead of easing them in. Both are gone.
- The A/B still stands and still says the grade is **protective**: one pinned,
  frozen frame at hour 22, shot twice, changing nothing but the flag — grade on
  R/B **0.44** (a correct cool night), grade off R/B **2.82** on identical
  geometry and shadows.

So: a real, smaller fix, honestly labelled. Not the crimson fix.

### What the two results together actually point at

The A/B frame was pinned **and frozen** (`set_process(false)`) — the pattern
`pin_clock` implements. The sweep does not freeze: WorldLook's `_process` keeps
advancing `_elapsed_seconds` and re-blending. That is now the **only** remaining
difference between a cool frame and a red one at the same hour.

On this container that difference is large. At ~0.29 FPS with
`day_length_seconds` 600, each rendered frame advances the clock **0.136 in-game
hours** — roughly 200× what a real machine at 60 FPS does per frame. The sweep's
"hour 22.00" frame is really taken at ~23.4 after ten settle frames.

`tools/_probe_night_crimson.gd` is rewritten to decide this and is running: three
pinned-and-frozen hours spanning the transition (20.5, 22.0, 23.5), then the same
hour again with `_process` left live. The outcome decides something that matters
well beyond this item:

- **If only the live frame is red**, the crimson is an artefact of a clock
  advancing faster than the renderer can follow. It would then be a capture-rig
  finding, not a defect a player can reach — and the overnight X07 run, which
  now pins and freezes, would be immune. It would also finally explain the
  "2026-08-23 crimson artefact" that `X07.json`'s own note records.
- **If the frozen frames go red too**, it is a real time-of-day defect and the
  hunt continues on the presets themselves.

I will not guess which before the frames land.

### Everything else is unchanged from check-in 2

Items 1 and 3 are fixed and pushed and are not affected by any of this. **The
`X07.json` fix — both the camera variants and the 19 real `pin_clock` steps — is
pushed in `a2b80641` and still gates the overnight run.** Item 4's four
grass-lane-adjacent defects remain deferred per the ordering directive; item 5 is
not started.

---

## DEFECT-FIX lane — check-in 4 — 2026-08-26 — night IS red for a player; my grade change is reverted; cause still open

### The matrix result

`tools/_probe_night_crimson.gd`, one boot, one fixed viewpoint, three hours
pinned **and frozen** the way `pin_clock` does it, then the same hour again with
`_process` left live:

| frame | R | G | B | R/B |
|---|---|---|---|---|
| frozen 20.5 | 55.5 | 90.6 | 102.5 | **0.54** — cool |
| frozen 22.0 | 129.0 | 44.9 | 44.5 | **2.90** — red |
| frozen 23.5 | 118.5 | 34.7 | 37.6 | **3.15** — red |
| live 22.0 (drifted to 22.06) | 128.6 | 44.5 | 44.3 | **2.91** — red |

Two things follow, and they close two of my three hypotheses:

1. **Freezing the clock changes nothing** — 2.90 frozen against 2.91 live. The
   live-clock theory from check-in 3 is dead. So is the idea that this is a
   capture-rig artefact: `pin_clock` does not protect the overnight X07 run
   from it.
2. **A pinned, frozen frame at an ordinary hour renders red.** This is a real
   time-of-day defect and **a player reaches it every night.** The transition
   sits between hour 20.5 and 22.0.

### I have reverted my own change

`data/config/art.json`, `scripts/world/world_look.gd` and the test I added are
now **byte-identical to their pre-branch state** (`git diff a78c062f` over those
three paths is empty).

Two reasons, and the second is the one that decided it:

- It does not fix the defect it was pushed for. Established in check-in 3.
- There is a measurement suggesting it made that defect **worse**. Pre-change,
  a pinned frozen frame at hour 22 read R/B **0.44** — cool. Post-change, the
  same pinned frozen frame at the same hour reads **2.90**. The only thing
  between them is that `night`'s `adjustment_saturation` stopped snapping to
  0.72 and started lerping (0.813 at that hour). The live sweep shows no such
  difference (3.42 before, 3.43 after), so the two measurements disagree and I
  cannot currently reconcile them.

An unfixed known defect is better than an unproven change carrying a regression
signal, on a branch that gates an overnight run and a frozen candidate. The
boolean snap it addressed is real and still there; it is written up here so
whoever picks this up does not have to rediscover it.

### What is now established about the crimson, and what is not

**Established:**
- Night lighting itself works: mean luminance ramps 115.0 at hour 08 to 60.8 at
  23.9, smooth and monotonic through dusk, 1.89x.
- From somewhere between hour 20.5 and 22.0, the whole frame — sky, ground,
  trees — renders red. R/B goes from ~0.54 to ~2.9-3.6 and stays there through
  midnight to at least hour 02.
- It reproduces with the clock pinned and frozen, so it is not a capture
  artefact and `pin_clock` does not shield the X07 re-run from it.
- It is almost certainly the "2026-08-23 crimson artefact" `X07.json`'s own note
  records. That note blames an unpinned clock; **that attribution is wrong.**

**Refuted, so nobody re-runs them:**
- *The colour grade causes it.* No — an A/B at pinned hour 22 changing only that
  flag gave grade-on 0.44 and grade-off 2.82, i.e. the opposite direction.
- *The `adjustment_enabled` boolean snap at hour 21.0 causes it.* No — declaring
  the flag so it never toggles left the sweep unchanged (3.42 to 3.43).
- *A live clock advancing ~200x faster than a real machine causes it.* No —
  frozen 2.90 against live 2.91.

**Not established:** the cause. Nothing in the presets is red — `night` is
`#1b2d5c` sky, `#3d5285` horizon, `#2a3b6e` ambient, `#b7c6ea` sun, and `golden`
is warm but nowhere near this, so no lerp between them can produce R/B 3.6. The
next place I would look is what `_apply_environment`/`_apply_sun` actually write
into the live `Sky`/`Environment` at high `t` — the procedural sky's own sun
glow and horizon terms at `sun_angle_max_deg` 14 / `sun_curve` 0.35, and the
`exposure` 1.2 / `ambient_energy` 1.5 pair going through ACES — rather than at
the config, which has now been ruled out twice.

I have not chased that further tonight: each round of this costs a ~16-minute
world boot, I have spent four of them, and three hypotheses have died. Handing
over a precise, honestly-bounded defect with the dead ends marked is worth more
than a fifth guess.

### Severity, stated plainly

This is a **shipping defect on the renderer the owner plays** (D01), not a
harness problem. Every night in ordinary play, the world turns blood red from
roughly hour 21 to dawn. It is not in the original work list because the
evidence that was supposed to surface it — X07's six "night" frames — was
captured at mid-morning with the clock never pinned. Fixing that labelling
(pushed, `a2b80641`) is what made this findable at all.

### State

| item | status |
|---|---|
| 1 — permanent immobility | fixed, pushed (`a2b80641`) |
| 2 — night/weather | X07 mislabelling **fixed and pushed**; the real crimson defect is **open, bounded and documented**; my attempted fix **reverted** |
| 3 — X07 three identical cameras | fixed, pushed (`a2b80641`) — still the one gating the overnight run |
| 4 — visual defects | four deferred pending the grass lanes (check-in 2) |
| 5 — S02 drop-confirmation trigger | not started |

The branch now carries: the immobility failsafe and its test, the X07 fix, two
measurement tools, and this log. No unproven game change.

---

## DEFECT-FIX lane — check-in 5 — 2026-08-26 — item 5: the S02 symptom is reproduced deterministically

### The reproduction

`tools/opening_fix/probe_second_start.gd`, headless, real world scene:

```
satchel stocked: 15 orb_basic, 0 left over
before any press     open=false tab=backpack  confirming=-1  guard=false focus=-
after Start #1       open=true  tab=backpack  confirming=-1  guard=false focus=
after Start #2       open=true  tab=backpack  confirming=0    guard=false focus=Drop it
after 5x menu_tab_right: tab=backpack   (the run needed 'save')
```

That is the S02 failure exactly: the drop confirmation focused on a slot nobody
selected, and — because it calls `menu.hold_input(true)` — **five
`menu_tab_right` presses leave the tab on `backpack`, so the Save tab is
unreachable and the segment cannot write its handoff save.**

### Why nobody found it

Everything tried against §4 presses Start **once**.
`tests/smoke_pause_tap_no_drop.gd` stocks the satchel, taps once, and passes.
`tools/opening_fix/probe_drop_confirm.gd` loads the run's own S02 exit save,
taps once, and reports `confirming = -1`. Both are correct: the guard works on
the opening press.

The guard **cannot** cover the second press, by its own construction.
`tab_backpack.gd::poll()` clears `_ignore_drop_until_release` the moment the
opening press is released. From then on the shell is open, the backpack tab is
visible, `backpack_drop` and `game_menu` are the same physical button, and
`game_menu.gd` deliberately does not let Menu CLOSE the shell — so the second
press has nothing left to do except be read as Drop.

### What this does and does not establish

**Establishes:** a deterministic, player-reachable input sequence that produces
the exact symptom S02 recorded, and the mechanism behind it. §4 ends with "the
trigger is something in the run's input sequence rather than the Start binding
itself, and it is still unexplained." It is now explained as a sequence, and the
Start binding is a necessary part of it rather than the whole of it — which is
consistent with the standing instruction not to re-litigate the binding.

**Does not establish** that the 2026-08-25 run reached it by this path. `S02-63`
is a single `open_menu {}`, and `_step_open_menu` presses once and does not
retry (`operator_harness.gd:865-887`). So a second Start press is not in the
step-script as written. Where attempts 5 and 6 got one — a superseded variant, a
step since removed, or a different first-press failure I have not reproduced —
is for whoever holds the run's own event logs to check. **I am not claiming the
run's cause; I am handing over a reproduction it can be checked against.**

### The player-facing half, which is real either way

Open the pause menu on a gamepad, press the same button again expecting it to
close, and you get a destructive prompt one A press from deleting an item you
never selected — and tab navigation stops responding. `tab_backpack.gd`'s own
comment calls exactly this shape "a destructive verb offered without being asked
for", which is why the first-press guard exists at all.

**I have not fixed it, deliberately.** Every available fix changes a settled
input decision — suppressing drop-on-Start removes the gamepad drop verb that
`data/config/menu.json` moved there on purpose, and letting Start close the shell
reverses `game_menu.gd`'s own documented ruling. `CLAUDE.md` says to ask rather
than invent on that class of change. The reproduction, the mechanism and the two
candidate fixes are recorded here; the choice is the owner's.

### CI note, and a correction to my own working style

Runs 2490, 2494, 2495 and 2496 on this branch all concluded **CANCELLED**.
`ci.yml` sets `cancel-in-progress: true` on non-`main` refs, so each of my pushes
killed the run before it — the identical trap this log already records at
check-in "Why nothing is pushed right now". My commit-and-push-per-item habit,
which is right for surviving a container reclaim, is wrong against this workflow.
Run 2497 on `cc074182` was allowed to finish and the probe commit was held back
rather than pushed on top of it.

### State

| item | status |
|---|---|
| 1 — permanent immobility | fixed, pushed, `smoke_unstick.gd` discriminates |
| 2 — night/weather | X07 mislabelling fixed and pushed; crimson night **open, bounded, three hypotheses refuted**; my attempted fix reverted |
| 3 — X07 identical cameras | fixed, pushed — gates the overnight run |
| 4 — visual defects | deferred per the ordering directive |
| 5 — S02 drop confirmation | **reproduced deterministically**; mechanism explained; fix withheld as an owner decision |
