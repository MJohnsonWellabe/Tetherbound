# Gate F rig lane — log

Branch `ralph/GATE-F-RIG`. Tier 0 of the post-Phase-B plan: make the Gate F
operator harness able to drive the game and able to prove what it saw.

The lane's premise, from Phase B: the run against candidate `f082bdf6`
independently found 13 of 162 known player-facing issues — **8.0%** — and three
of the four loudest findings in it were harness artefacts, refuted by the run's
own data. That is a defect in the instrument, not a verdict on the game.

**Read Finding 2 first.** The coordinator's brief gave this lane a diagnosis of
CD-2 that is wrong, corrected mid-lane from the Gate F operator's check-in 30.
The captures were taken; `.gitignore` swallowed them. The capture path was not
rewritten and did not need to be.

The run's own final numbers, from the operator: **2205 PASS / 373 FAIL** across
the 13 segments that wrote verdicts, X07 stopped at step 184 of 266 with **79 of
80 frames taken**, and X04, X05, X06 and X08 never ran.

---

## Finding 1 — the lane's own specification was not on `main`

The lane brief routes through five documents. At session start, four of them
did not exist in the checkout:

| Document | On `main`? |
|---|---|
| `ralph/COORDINATION_2026-08-27_POST_PHASE_B.md` | no |
| `ralph/reports/gate-f-phase-b/README.md` | no |
| `ralph/reports/gate-f-phase-b/COVERAGE_DEFECTS.md` | no |
| `ralph/reports/gate-f-phase-b/FINAL_BACKLOG.md` | no |
| `ralph/reports/GATE_F_OPERATOR_STANDDOWN_2026-08-27.md` | no |
| `ralph/GATE_F_MASTER_PROTOCOL.md`, `ralph/GATE_F_PROTOCOL.md` | yes |
| `ralph/.gdignore` | yes (`b6ad894a`) |

They are on the unmerged branch **`origin/ralph/GATE-F-PHASE-B`** (`ae3ee33d`),
which `git ls-remote` shows but which nothing routed to.

(`ralph/.gdignore` **is** on `main`, from `b6ad894a`, exactly as the brief
says. An earlier draft of this log claimed otherwise; that was wrong and this
line is the correction. The import does not churn through the evidence PNGs.)

This matters beyond bookkeeping. The brief's summary of the coverage defects is
accurate but partial: it names CD-1, CD-2, CD-3, CD-8 and GF-B-011. The actual
`COVERAGE_DEFECTS.md` has **eight**, and four of the ones the brief does not
mention — CD-4, CD-5, CD-6's second half, CD-7 — are instrument work too. CD-5
is ranked **first** by the coverage review's own ordering: *"nothing else
matters while the first wild fight cannot be staged."* A lane working only from
the brief would have shipped without it.

All eight are addressed on this branch. `origin/ralph/GATE-F-PHASE-B` should be
merged to `main`, or the next lane will start from the same gap.

**A second document lag:** `ralph/reports/gate-f-candidate/RUN_METADATA.json` on
`main` still freezes `14e88c7c` (2026-08-26). The run this lane exists because
of was against `f082bdf6`, whose freeze record is not on `main` either.

---

## Finding 2 — CD-2 is not a harness defect at all. It is `.gitignore`.

**Corrected 2026-08-27 after the coordinator's stand-down notice and the Gate F
operator's check-in 30 on `ralph/GATE-F-RUN-20260827`.** An earlier draft of
this log said the two halves "compound" and that the headless journey segments
produced no PNGs, "so none did". That last clause was wrong and it is the whole
point of the correction, so it is restated here rather than edited away.

`COVERAGE_DEFECTS.md` reads: *"`operator_harness.gd:1212` writes to
`shots/<id>.png`. No `shots/` directory exists anywhere in the run and git has
never carried one."* The second half is true. **The first half is false, and
this lane must not act on it.**

The operator, who had the files on its own disk, reports:

> `shots/` exists in every segment. X07's held **79 real 1920×1080 PNGs**, ~1.5
> MB each, 134 MB. I read their pixels — check-in 28's colour verification was a
> from-scratch PNG decode over all 79, not a manifest read.

**The capture path works and was not rewritten by this lane.** X07 ran under
xvfb, its `CAPTURE_RESOLUTION.json` records the smoke passing at 1920×1080, and
it produced 79 of 80 planned frames with no resolution fallback. Phase B read
the *repository*, saw no frames, and reasonably concluded none were produced.
Reading the *container* reverses that.

### The one line

```
$ git check-ignore -v .../X07/shots/GF-14-COMBAT-13b.png
.gitignore:34:shots/	.../X07/shots/GF-14-COMBAT-13b.png
```

`.gitignore` line 34 was a bare `shots/`, written for `tools/survey.sh` output.
**A bare directory pattern matches at any depth**, so it swallowed every Gate F
segment's own `shots/` — this run and every previous one, since the harness was
written.

And `git add <dir>` skips ignored contents **silently**. Verified here from
first principles rather than taken on trust:

```
$ printf 'shots/\n' > .gitignore && mkdir -p run/seg/shots
$ echo frame > run/seg/shots/a.png && echo notes > run/seg/notes.md
$ git add run          # exit 0, no output at all
$ git diff --cached --name-only
.gitignore
run/seg/notes.md       # the frame is simply not there
$ git commit -m x      # succeeds
```

That is how **fourteen** per-segment evidence commits looked clean while
carrying no frames.

### What this lane changed, and what it did not

Anchored to `/shots/`, which is the permanent fix. The operator recovered X07's
79 frames with `git add -f` in `89c87b56` and deliberately did **not** touch
`.gitignore`, because a repo change belongs to this lane under §13.

Two checks the coordinator asked for before changing that pattern:

**What else was the bare pattern eating?** Nothing. Every `shots/`-writing tool
in the repository (`tools/survey.sh`, `tools/contact_sheet.gd` and the rest)
writes under the *repository-root* `shots/`, which `/shots/` still ignores. The
only nested `shots/` directories that exist anywhere are the Gate F per-segment
ones — precisely what the pattern was wrongly swallowing. `shots-*/` matched
nothing at any depth. The anchor is exactly scoped: nothing else loses its
ignore.

**Does `ralph/.gdignore` interact with it?** No, and the two are complementary.
`.gdignore` is a **Godot** mechanism and `.gitignore` is a **git** one; they do
not see each other. `ralph/.gdignore` stops Godot importing everything under
`ralph/` — including this lane's committed evidence PNGs, which is why the
import no longer churns through them — while git now carries those same files.
Confirmed: `git check-ignore` returns 1 (not ignored) for
`ralph/reports/gate-f-selfcheck/rig-2026-08-27/selfcheck_capture/shots/SC-C-title.png`,
and ten PNGs are committed on this branch. Root `shots/.gdignore` is untouched
and still keeps the survey output out of the import.

### The inventory check is not weakened by this — it is sharpened

CD-2's fix was never really about the capture path, and the closing inventory is
what would have caught this: **it turns a silent `git add` no-op into a loud
failure.** A segment that believes it committed 79 frames and committed none is
exactly the shape `INVENTORY.json` exists to make impossible, because `exists`
and `bytes` are read off disk and `complete` is computed rather than claimed.

So the inventory now asks git directly. At close it runs `git check-ignore -v`
over every capture that exists on disk, and a capture git will not carry is an
**uncommittable artefact**: named in `INVENTORY.json`, named with its rule in
`INCOMPLETE.md`, `complete` false, process exit non-zero. A file that exists and
can never be committed is not evidence — it lives on a container that gets
reclaimed.

Asked of `git check-ignore` rather than by reimplementing gitignore matching in
GDScript. Every subtlety that made CD-2 possible — a bare directory pattern
matching at any depth, negations, precedence between `.gitignore` files — lives
in that command, and a second implementation of it would be a second set of
answers.

Proven both ways, inside the repository, by temporarily restoring the bare
pattern:

```
### A: pre-fix .gitignore
run_segment: INVENTORY.json says selfcheck_capture is INCOMPLETE
  - 4 capture(s) exist on disk and git WILL NOT CARRY THEM:
    - shots/SC-C-title.png    (ignored by .gitignore:45:shots/)
    - shots/SC-C-seq-000.png  (ignored by .gitignore:45:shots/)
    - shots/SC-C-seq-001.png  (ignored by .gitignore:45:shots/)
    - shots/SC-C-seq-002.png  (ignored by .gitignore:45:shots/)
    `git add <dir>` skips these silently and exits 0. Committing this segment
    would look clean and carry nothing.

### B: fixed .gitignore
run_segment: INVENTORY.json says selfcheck_capture is COMPLETE.
  complete=True  git_check=clean: git will carry all 4 capture(s)  uncommittable=[]
```

A first cut of this check ran the segment into `/tmp`, outside the work tree,
where `git check-ignore` exits 128 — and reported the segment incomplete for
that. Wrong: an *unanswerable* check is not an uncommittable file. It is now
recorded as `git_check: "unknown: …"`, which must read as unknown and never as
clean, and it does not fail completeness. Failing every run on a box where git
cannot answer would be this lane's own mistake in mirror image — making the rig
refuse work it can do.

---

## Finding 3 — every `inventory` field ever emitted was zeros, and it had
## disabled two of the detectors this lane was asked to build

CD-6 records the symptom: S03's `save` event reported `{"axe": 0,
"berries": 0, "orb_basic": 0, …}` for a save that actually held `orb_basic ×15,
potion_small ×3, berries ×5, revive ×2`. The cause is one key.

`scripts/debug/gate_f_probe.gd::inventory_snapshot()` read each stack's
`count`. `autoload/inventory.gd` builds a stack as `{"id": id, "n": put}` and
every reader in the game — `count()`, `_merge`, `take`, `move` — uses `n`. So
the accessor returned the right item ids with the default `0` for every
occupied slot.

It also silently disabled the `gather` and `craft` detectors this lane added for
GF-B-011, which work by comparing two inventory snapshots. They would have been
comparing two dictionaries that were always equal, and the run would have
reported "no gathering happened" for a second unrelated reason.

**This is the only file under `scripts/` this lane touches, and it is a
deliberate, narrow exception to the brief's "do not modify game code".** It is
the Gate F probe; nothing in the game loads it
(`test_the_probe_is_not_wired_into_the_shipped_build` asserts exactly that);
and reading the key the game writes changes no game behaviour whatsoever. The
alternative was to ship an instrument known to be reading the wrong field,
which would defeat the point of the lane. Recorded here rather than done
quietly. `tests/test_gate_f_rig.gd` now asserts both the probe's key and
`inventory.gd`'s stack shape, so the pair cannot drift apart again silently.

---

## Finding 4 — the cost model has to be taken twice, and the first one lies

CD-7's fix is to price a segment's `wait` budget against the measured frame
cost before launch. Implemented — and the obvious place to measure, the
pre-flight before step 1, gives a number that is **not about the scene the
segment will render**. The pre-flight runs on an empty tree. Measured here:

| when | s/frame (logic mode) |
|---|---|
| pre-flight, empty tree | 0.0059 |
| after `boot: world` | see `preflight.measured_frame_cost_s_in_scene` |

Under xvfb the gap is the difference between an empty viewport and 762,058
scattered props through llvmpipe, and a prediction built on the first would
clear a ceiling the real segment cannot. So the harness prices twice: once at
the pre-flight (which is what catches "no display server", the cheap case), and
again immediately after the first `boot`, where the number is finally honest —
and where the boot's own cost, whole seconds in a single frame that no
per-frame model predicts, is finally known. Over the ceiling at the second
measurement is a BLOCKER and the segment stops there.

Measured on this container: the Meadows world stand-up is **67.5 s** in logic
mode. No frame-count model would have anticipated it.

---

## Finding 5 — the reach self-check found where the chapter actually starts

`tools/gate_f/segments/selfcheck_reach.json` is the regression CD-5 asks for by
name (*"walk to Grandpa, to a harvest node and to a wild creature, asserting the
prompt each time"*). Its first run against the real Meadows reported:

```
SC-R-04  FAIL  the live prompt "… Get up" belongs to 'BedPrompt', which is not
               'Mira' nor part of it. Not pressed.
SC-R-05  FAIL  did not reach Mira (node name) in 2400 walking frames; stopped
               43.9 m short at (-23.0, 5.0, -15.0) (0 held)
SC-R-07  FAIL  no interact prompt is live, so `interact` was NOT pressed. The
               nearest 'Mira' is 44.05 m away in 3D (43.89 m in x/z, 3.75 m
               vertical).
```

Booting `meadows_playground.tscn` directly spawns the player **in Grandpa's
bed**. `BedPrompt` is the only live prompt; 2400 frames of navigator-driven
walking moved 2.4 m, with **zero** frames held — locomotion was never disabled,
the player simply could not walk out of a bed.

That is not a rig defect and not a game defect. It is where the opening starts,
and the segment was written without knowing it. What matters is that the rig
said so *at the step that could not drive the game*: three specific,
self-diagnosing failures naming the provider, the distance, the vertical
component and the held-frame count — instead of the shape this lane exists to
remove, which is a walk reporting success at an empty coordinate and forty
downstream assertions about a game that was never in the expected state.

Note also that SC-R-04's refusal is CD-5's `S02-15` in miniature: the bed is
the exact object the operator watched a segment press `interact` at 31 times
through a floor. `interact_with` refuses it by provider identity.

### Finding 5b — the walker cannot leave Grandpa's house

The segment was then given a get-up step. `interact_with` pressed `BedPrompt`
and reported `flags 1 -> 2`; the player was out of bed. The walk still failed.
From `route.csv`, sampled every 25 rows:

```
t=62.29   -25.40, 4.93, -15.60   heading   0.0
t=75.81   -22.62, 4.65, -13.74   heading  73.0
t=101.44  -22.62, 4.65, -14.28   heading  72.3
t=127.07  -23.01, 4.65, -15.82   heading -20.9
t=152.70  -22.62, 4.65, -17.12   heading  89.5
t=191.93  -22.62, 4.65, -13.74   heading  56.4
```

**6000 walking frames, zero frames held, four metres of travel in a box.**
Locomotion was never disabled — `can_walk()` was true throughout — and the
heading swings through 180 degrees as the navigator tries one detour after
another. The player is enclosed by the house and the walk cannot find the door.

`tests/helpers/stick_navigator.gd` is the repo's one walker that detours around
geometry, and its own header says every straight-line walk in this project
failed on the same village wall. Leaving a *building* is past what it does.
Whether it should be able to — a navmesh question, a door-width question, or a
"the opening sequence is supposed to take you out" question — belongs to
whoever owns the walker and the village geometry. **It is not a rig defect and
this lane did not change the walker.**

What matters here is that the instrument said so exactly: a four-metre box, a
zero held-frame count that rules out a modal, a named distance, and a vertical
component. The failure this lane exists to remove is the other one — a walk
reporting arrival at an empty coordinate, and forty downstream assertions about
a game that was never in the expected state.

The segment now teleports out of the house under `diag: true`, the same
precedent and the same reasoning `selfcheck_walk` already carries, and walks to
**Tam** rather than Mira — OF31 moved Mira indoors, behind a counter inside
`cottage_a`, which would have failed on the same doorway a second time.

---

## Finding 6 — two bookkeeping defects in this lane's own first cut

Found by running the self-check rather than by reading it, which is the point
of having one.

1. **A resynced derail closed looking clean.** `_derailed` is cleared on
   resync, correctly — and `INVENTORY.json` therefore reported
   `"derailed": ""` for a segment that had derailed at SC-R-08, skipped three
   steps, and recovered at SC-R-12. There is now a `derails` array carrying
   every derail with its skip count and its resync point, and `complete` is
   false if it is non-empty.
2. **A refused step was counted as having run.** The context guard's FAIL path
   incremented `_step_ran`, so a segment whose steps were all refused would
   have reported `ran == total`. Refusals are counted separately as
   `steps.refused`, and `complete` requires it to be zero.

---

## Finding 7 — two things `interact_with` caught that were not game defects

Both worth recording, because both are the shape a blunter instrument would
have filed as findings about the game.

**The segment author asked to stand out of reach.** `SC-R-15` walked to within
2.5 m of a harvest node and pressed. `harvest_node.gd` configures its
`Interactable` at a **2.4 m** radius from a prompt node sitting 0.6 m above the
node's origin, so 2.5 m in 3D is outside the game's own reach. `interact_with`
refused rather than pressing into nothing, and named the distance. The fix was
in the segment (`within: 1.5`), not in the game — which is `interact_with`
earning its keep on the *transcriber* rather than on the build.

**A live prompt whose press does nothing observable.** With `within: 1.5` the
prompt is live — *"Strip meadow grass"* — the press reaches its provider, and
nothing changes: no context, focus, satchel, build, party or flag. That is
`harvest_node.gd::_on_gathered` behaving as written: the player boots with an
empty satchel and nothing equipped, and a bare-handed press for a resource that
needs a tool is refused with the node left standing.

The step now carries `expect_change: false`, which the harness requires an
operator to write down **before** playing — the default is FAIL, so a press
that quietly did nothing can never be read as one that was expected to.

Whether that refusal is *legible* to a player is a real question and this lane
does not answer it. An instrument check must not: the answer needs a HUD frame
and a journey segment, and `interact_with`'s no-op detection is exactly the
mechanism that would surface it there.

---

## Finding 8 — an assertion that cannot be evaluated is not a verdict

`selfcheck_context`'s first run reported

```
SC-X-10  FAIL  mouse_mode=visible (wanted captured)
```

against §E.4's restoration checklist — on a build that restores the mouse
fine. The run was headless. A process with no display server has no mouse to
capture and `Input.MOUSE_MODE_CAPTURED` never holds in it, so that check FAILs
every time it runs in logic mode, saying nothing whatever about the game.

This is precisely the class Phase B had to refute from the run's own data:
three of the four loudest findings against `f082bdf6` were the instrument's,
not the build's. So the distinction is now in the harness, and it is a
distinction, not a softening:

* a capture that cannot be **taken** is a **FAIL** — the evidence is missing
  and that is a real deficiency in the run;
* a measurement that cannot be **made** is a **SKIP** — the game never got a
  chance to be wrong.

Collapsing them in either direction produces a lie. `mouse_captured` run
without a display server now returns SKIP and names the reason and the
invocation that would give a verdict.

### Why the untakeable capture stays a FAIL, against the operator's suggestion

The Gate F operator, in check-in 30, agrees CD-1's core criticism is right — *"a
capture step that cannot produce its evidence returned PASS"* — and proposes a
different verdict from the one this lane shipped:

> The `file: null` row is §C.4-compliant — an absent frame is evidence — but the
> **PASS verdict on top of it** asserts a success that did not happen.
> `SKIPPED`/`N/A` would carry the same information honestly.

That is a fair reading and it is not what landed, for two reasons. **The
coordinator confirmed this call on 2026-08-27: keep FAIL.**

**The written spec says FAIL.** CD-1's own permanent-template change is
explicit: *"a planned capture that cannot be taken is a **FAIL**, and a segment
that cannot take any of its planned captures is a **BLOCKER** at step 1."* This
lane implements the specification it was given; changing a verdict the coverage
loop chose is the coordinator's call, not the rig lane's.

**And the two cases are genuinely different.** A prescribed capture is evidence
the run *owes* — §G defines every non-defect entry before play, and the operator
may not delete or re-stage one. A run that does not pay a debt it entered into
has a real deficiency, and FAIL is what that is. A `mouse_captured` assertion is
a *question about the game* that this envelope cannot ask at all; nothing is
owed and nothing is missing. Debt versus unanswerable question.

In practice the disagreement is nearly moot, which is worth saying plainly. With
the pre-flight in place a capture-bearing segment either has a display server —
so its captures are real — or it BLOCKs at step 1, or it runs explicitly
DEGRADED under `--gatef-allow-no-capture` with every planned shot marked absent.
The `_step_capture` FAIL is now only reachable when a display server is lost
*mid-segment*, which is unambiguously a failure. It is kept as defence in depth,
not as the primary control.

---

## Finding 9 — the pre-flight had two of its own bugs, and they were the
## expensive kind

Found by reading the finished branch adversarially rather than by running it,
and then confirmed by running it.

`_preflight_capture` had four reasons to refuse a segment and ran all four
through **one string**. Two consequences:

1. The display-server message **overwrote** the cost message, so a segment that
   was both too expensive and unable to capture reported only the second.
2. `--gatef-allow-no-capture` waved through **any** of the four — including a
   cost-ceiling breach, which has nothing to do with pictures.

The second is the expensive one. It would have reproduced X07's fifteen wasted
hours *with a flag on it*, which is worse than the original defect: a run that
was explicitly told to proceed.

The two kinds of refusal are now separate and named. `capture_why` is "this
invocation cannot take pictures" — the thing the acknowledgement flag exists to
acknowledge. `hard_why` is a refusal the flag has no business waiving: over the
cost ceiling, or a freeze record that contradicts what the process can see.

Both paths are now proved by running them, not by reading them:

```
$ tools/gate_f/run_segment.sh --allow-no-capture selfcheck_capture
run_segment: WARNING -- selfcheck_capture plans captures and is running WITHOUT a display
run_segment:            server by explicit --allow-no-capture. INVENTORY.json will
run_segment:            mark every planned shot absent and the segment incomplete.
run_segment: INVENTORY.json says selfcheck_capture is INCOMPLETE
  exit=1   complete=False   absent=4/4   verdict=DEGRADED (--gatef-allow-no-capture)

$ tools/gate_f/run_segment.sh --allow-no-capture <a segment with a 60000 s wait>
  exit=1   complete=False   verdict=BLOCKER   steps ran: 0 of 3
BLOCKER.md: predicted cost 21276 s (5.9 h) exceeds the 14400 s ceiling: 3600016
  planned frames at a MEASURED 0.006 s/frame on this box. The protocol's waits
  are not the problem -- they exist so fights resolve -- so this segment needs a
  GPU or a re-cadenced script, not a shorter wait.
```

The acknowledged run executes its logic and can never be complete. The
over-budget run does not start, flag or no flag.

---

## Finding 10 — two of this lane's own tests were coupled to the repository,
## not to behaviour

CI run 2579 on `f1aa42c2` was red with two failures, both in
`tests/test_gate_f_rig.gd`, both passing locally:

```
test_every_schema_event_type_is_emitted_by_something
  (could not parse §C.1's event enum out of GATE_F_MASTER_PROTOCOL.md; got [])
test_the_gitignore_shots_rule_is_the_one_that_was_wrong
  (the committed capture evidence is gone; this test's premise has changed)
```

One cause, and it is mine. `.github/workflows/ci.yml`'s `verify-unit-tests`
sparse-checks out **`!/ralph/`** — deliberately, since those trees are 1.20 GB
of the 2.08 GB tip and no verification job reads them. Both tests read files
under `ralph/`: one the protocol document, one a committed evidence PNG. Neither
exists in that checkout, and neither should.

Neither assertion was weakened.

**The enum test.** `tools/gate_f/SEGMENT_SCHEMA.md` now carries §C.1's enum as a
table, and the test parses it from there — the schema doc is in every checkout,
which is why the sibling tests in `test_gate_f_instrumentation.gd` have always
been able to parse it. So GF-B-011 is now enforced **in CI, where it previously
could not run at all**. A second test,
`test_the_schema_doc_and_the_protocol_agree_on_the_enum`, cross-checks the
restatement against §C.1 whenever the protocol is readable, and where it is not
it *prints why* instead of passing quietly — a restated list whose drift guard
silently no-ops is a list that drifts.

Worth noting the failure mode that did **not** happen: the test went red rather
than vacuously green only because it asserts the parse found something before
asserting over the result. That guard is the important half and it is kept.

**The gitignore test.** Rewritten to ask git about a *path* rather than a
*file*. `git check-ignore` answers about paths whether or not they exist, so the
rule can be pinned without coupling the test to any artefact:

```gdscript
var run_path := "ralph/reports/gate-f-run-20260101T000000Z/S01/shots/GF-01-EXAMPLE.png"
```

It also now asserts the converse — that the repository-root `shots/` is *still*
ignored — because anchoring the pattern was meant to narrow it, not remove it.

### Proved, not assumed

Both fixes were run under CI's actual condition by hiding `ralph/`:

```
$ mv ralph /tmp/ && godot --headless --script tests/run_tests.gd -- --only=gate_f
    (skipped: res://ralph/GATE_F_MASTER_PROTOCOL.md is not in this checkout —
     verify-unit-tests sparse-checks out !/ralph/. The enum was checked against
     SEGMENT_SCHEMA.md only; run this locally or in a full checkout to verify
     the two agree.)
51 tests, 26303 assertions, 0 failed
```

And both negative controls still bite, so neither test has been made vacuous:

```
add `nobody_emits_this` to the schema table  → FAIL, naming it
restore the bare `shots/` pattern            → FAIL, naming the run path
```

### `main` merged forward

`main` moved to `7f18ccee` while this lane ran; `ralph/LAND-0827` carries Phase
B, the Gate F evidence, the grass field ON and the coordination docs. Merged
forward — **merge, never rebase**, since a rebase replays the scatter re-bake
commits onto the new base and conflicts on every binary `region_*.bin`. Clean,
no conflicts.

The merge brings the operator's recovered evidence into this tree: **79 X07
frames** under `ralph/reports/gate-f-run-20260827T025303Z/X07/shots/`. Finding 2
is now confirmable from primary evidence in the working copy rather than from
the operator's report of it.

---

## Finding 11 — the camera-in-masonry report is half wrong, and the half that
## is right has a different cause

The defects lane reported that X07's `hall` teleport/face pair puts the
reconstructed camera **inside the masonry** — *"a slot of world between a floor
slab and a ceiling slab"* — and that `the_rise` has the same failure, raising
the possibility that `GF-B-004` (black sphere) and `GF-B-008` (black Rise
arrival) are rig artefacts rather than game defects. They flagged it rather than
fixing it because `tools/gate_f/**` is this lane's.

The merge brought the operator's 79 recovered X07 frames into this tree, so this
was checkable against primary evidence rather than reasoning.

**`hall` is not buried.** `GF-AUD-hall-gameplay.png` is a clean, well-lit
exterior of the stronghold gate with the player standing in front of it and the
HUD legible — mean luma 72.8, spread 43.2, **2.4%** of the frame below luma 24.
**And `GF-B-004`'s black sphere is plainly visible in the archway.** On this
evidence it is a real rendering artefact in the world, not a camera artefact.
`GF-B-004` should stay a game defect.

**`the_rise` is not buried either, though two of its frames are useless.** All
six `the_rise` captures were taken at the *same camera position* —
`[88.0, 2.22, -43.0]`, from `events.jsonl` — with only yaw varying between them.
Four of the six are wide, fully-lit vistas of the village on the rise
(`the_rise-landmark` is mean luma 111.9). **A camera inside solid geometry is
black at every yaw.** What is actually happening is that at two of the six yaws
the camera's near field is filled by something opaque.

So `GF-B-008` does look like a rig artefact — the frame is useless — but not for
the stated reason, and the proposed fix would not have caught it. A
"refuse if the camera is inside collision geometry" check answers a question
neither of these frames was asking.

### What landed instead

The check is on the **image**, which catches a buried camera, an occluded near
field, a fade caught mid-frame and a black screen alike without needing to know
which. Every prescribed capture now carries its own luminance statistics — mean,
spread, dark fraction — on its manifest and inventory row, and a frame that is
both very dark and very flat FAILs.

Most of the value is the statistics rather than the gate. The 2026-08-27 run
produced 79 X07 frames and the only way to find the two bad ones was to open
them one at a time; three numbers per row turns that into a sort.

**Calibrated against those 79 frames, and the separation is not the obvious
one.** Mean luminance does not work, because the two darkest frames in the set
are legitimate night captures:

| frame | mean | stddev | frac < 24 | |
|---|---|---|---|---|
| `the_pond-night-gameplay` | 25.1 | 41.1 | 0.584 | legitimate |
| `the_rise-gameplay` | 26.6 | 29.0 | **0.755** | degenerate |
| `the_rise-arrival` | 26.6 | 29.0 | **0.755** | degenerate |
| `the_pond-night-arrival` | 26.8 | 43.0 | 0.584 | legitimate |
| *next darkest of the other 75* | 48.2 | 48.8 | 0.284 | |

The night frames are *darker in the mean* and keep their contrast — sky, moon,
silhouette — while the degenerate pair is flat. The gate is therefore dark
fraction **AND** spread, both, with the thresholds between the two populations.

Two validations worth recording:

* **The GDScript implementation was cross-checked against the Python
  measurement that set the thresholds**, on the same frames, and agrees to the
  decimal on all seven sampled. A threshold calibrated with one measurement and
  applied by another is a threshold nobody has actually tested.
* **Both conditions are required, and a real capture proves it.** This repo's
  own title screen measures mean 50.8 / spread **32.4** / 5.4% dark. Its spread
  is *below* the gate — it is a deliberately flat dark UI — and only the
  dark-fraction half keeps it from being thrown away as broken.

### One more thing the telemetry shows

The six `hall` captures were taken with `region=corridor`, while step `X07-165`
asserts `region_is == hall`. That assertion failed and the captures went ahead
anyway, filed under the name `hall`. The context guard this lane built covers
`require_context` and `assert_context`; it does **not** derail on a failed
ordinary `assert`, and on reflection it should not — an `assert` is a verdict on
the game and §1.6 says the run continues. But a capture *named* for a place the
run has just measured itself not to be in is worth the coordinator's attention
when X07 is re-transcribed.

---

## What landed

Against `COVERAGE_DEFECTS.md`'s own numbering. CD-1…CD-7 are instrument work
that lands outside a run (§13, §1.5); step 6 of §16.4's loop — re-run the new
segment against the candidate — is **not** discharged here and is not claimed
to be. Operator/developer separation (§13) still applies and no Gate F segment
was re-run by this lane.

| | What it was | What landed |
|---|---|---|
| **CD-1** | Capture steps under a headless process returned `"capture … skipped"`, which does not begin with `FAIL`, so the step recorded **PASS**. 9,231 times. | Capture pre-flight before step 1 of any segment declaring a capture or a continuous record: display server, `capture_diag_minimal.gd` PNG beside the run, and the process's own framebuffer readback. Any of the three failing is a BLOCKER; no step runs. `--gatef-allow-no-capture` acknowledges it explicitly and still cannot mark the segment complete. An untakeable capture now returns `FAIL`. `run_segment.sh` refuses the same combination before Godot starts. |
| **CD-2** | No prescribed screenshot exists anywhere **in the repository** — but the frames were taken; `.gitignore` swallowed them. See Finding 2: this is not a harness defect and the capture path was not rewritten. | §M's closing inventory runs as code: `INVENTORY.json` per segment, planned id → file → **exists** → **bytes** read off disk, `complete` computed rather than claimed, `INCOMPLETE.md` written when it is false, non-zero exit on a missing artefact. Plus the `.gitignore` anchor — see Finding 2. |
| **CD-3** | Dialogue advance was a guessed fixed press count. Under-press and the modal sits open for the next step to press at; over-press and the extra `interact` re-opens the conversation the previous press closed. `X01-463` held 3,601 frames in `narrative_modal`. | `advance_dialogue_until_closed`: a predicate over the panel's own line (`dialogue_runner.gd::line()`, or the starter picker's index), stopping the instant `is_open()` goes false. The button is read off the panel — `interact` for a conversation, `menu_confirm` for the picker, the naming prompt refused with a pointer at `type_name`. Detects and FAILs a close-then-reopen. CD-3's stated regression is enforced inside the step: after it, `input_context` must not be `narrative_modal`. |
| **CD-4** | 303 of X01's 418 cells (72.5%) were injected in a context other than the one the step names. | `probe_cell` takes `intended_context`; out of context the cell is **SKIPPED**, never PASS and never FAIL. `intended_context` and `context_before` are first-class fields on `input_probe`. Deliberately not `require_context`: a 418-cell matrix that derailed at the first drift would be worse evidence than one that reports which cells were real. |
| **CD-5** | `move_to` compares x/z only; the bed is 0.89 m from Grandpa in plan view and 3.3 m above him. | `move_to_entity` resolves by identity (`poi:<kind>`, script path, node name, group, `label()`, `species_id`, unique substring), re-reads the position every frame, and arrives in **3D**. A walk that closed the plan-view gap and cannot close the vertical one reports the vertical fact. `interact_with` presses only when the arbiter has a live prompt, refuses a prompt belonging to another provider, and FAILs when the press changes nothing. |
| **CD-6** | Thirteen §C.1 event types had no emitter, so their absence proved nothing. | All thirteen have detectors, polling live state with no hook in gameplay code. The expensive half — inventory walk, landmark list, per-member condition — runs at 10 Hz rather than 60. `tests/test_gate_f_rig.gd` parses the enum out of `GATE_F_MASTER_PROTOCOL.md` and fails if any member is unemitted, so this cannot rot back. Plus the inventory key (Finding 3) and `await_save`/`await_load` for §18's missing `duration_ms`. |
| **CD-7** | `wait` is priced in rendered frames in capture mode; X07 stopped at step 184/266 with ~31 h still ahead. | Frame cost measured on the box, whole step-script priced against it, both in `RUN_METADATA.json`, BLOCKER over `segment_cost_ceiling_s`. Measured **twice** — see Finding 4. |
| **CD-8** | The freeze record enumerates no `data/config/` feature flag; `grass_field.json` has `"enabled": false` and the run's ground cover is absent from every frame with nothing saying so. | `config_flags` read mechanically from `data/config/`, recursing into nested blocks so `{"grass": {"enabled": false}}` is found, plus `config_flags_off` so a reviewer sees a disabled subsystem without diffing. Recorded per segment, because a run cannot amend a freeze record it did not write. |
| **CD-8b** | The freeze record said `display_server: "X11 under xvfb-run"`; 9,231 frame-manifest rows said the opposite. | The pre-flight reads the record's claim, writes back what it observed, and BLOCKs when the record promises a display server this process does not have. |

**GF-B-002**'s three primitives are CD-3, CD-5 and the context guard;
**GF-B-003** is CD-1 + CD-2; **GF-B-011** is CD-6.

### The context guard (GF-B-002's first primitive)

A step declares `require_context`, checked **before** the action. A mismatch
records **one** FAIL, at the step that could not drive the game, naming the
context, the input owner, the focused control, the paused state and any armed
build ghost. Every step after it is `SKIP`ped with the derail attached, until
one resynchronises — a step whose own `require_context` holds, any `boot`, or
an explicit `"resync": true`. `assert_context` is the same predicate as a seam
between blocks.

§1.6's "the run continues" is a rule about verdicts on the **game**. A step that
could not be **performed** invalidates the ones after it, and forty assertions
taken in the wrong context are forty findings about the harness.

### Protocol amendments

Nine, all from the "permanent template change" clause of the defect they close:
§0 facts 7/8/9, §A.2 (`config_flags` + the metadata-is-not-evidence rule),
§C.4, §C.5, §E.4, §F (a definition of *reached*), §G, §J, §M.

### Tests

`tests/test_gate_f_rig.gd`, 31 tests. `--only=gate_f` runs 48 across both Gate F
files, green. Three pure helpers (`_context_matches`, `_plan_captures`,
`_predict_frames`) were made `static` so they can be called directly rather than
grepped for — a source-level test checks the spelling, not the rule.

The **full unit suite** is green at the head of this branch: four shards,
`--shard=1/4` through `4/4`, all exit 0. `tests/smoke_gate_f_probe.gd` — the
live half, which the probe's inventory-key fix is under — passes:
*"gate-f probe: OK — every accessor agreed with the live game it reads."*

### Self-check segments

`selfcheck_reach` (CD-5, and the dialogue predicate end to end) and
`selfcheck_context` (the guard, the derail, the skip, the resync — with two
EXPECTED FAILs and two EXPECTED SKIPs that are the point of the segment).
`selfcheck_capture` needed no change: run in logic mode it now BLOCKs at step 1,
which is CD-1's fix demonstrating itself.

---

## Not done here, and why

- **Re-running any Gate F segment.** §13's operator/developer separation. The
  candidate must be re-frozen after these changes land (§1.5, §1.6) and the
  re-run list is in `COVERAGE_DEFECTS.md` per defect.
- **The `not-instrumented` escape in CD-6.** Every one of the thirteen types
  had a detector available from live state, so none was struck from §C.1.
- **CD-5's cheaper reproduction.** `COVERAGE_DEFECTS.md` raises CD-5 to HIGH
  confidence and points at `tests/smoke_party_count_after_catches.gd`, which
  fails intermittently with *"could not engage the real wild body … (stopped
  23.7 m away, engage range 6.0 m)"* and self-diagnoses at the candidate SHA.
  That is a **game-side** engage failure, not a rig one. This lane built the
  instrument that can now express it (`move_to_entity` + `interact_with`); the
  fix belongs to whoever owns that test.

---
---

# Round 2 — branch `ralph/GATE-F-RIG-2`

Round 1 rebuilt the instrument. The 2026-08-27 run
(`ralph/reports/gate-f-run-20260827T223957Z`) is the first Gate F run since the
rebuild that **photographed the game** — `GF-01-TITLE-01` exists on disk,
1920×1080, mean luma 50.8, on its manifest row, where the previous run wrote
9,231 rows saying `file: null` and called each one PASS. The pre-flight passed,
the context guard held, the dialogue predicate worked, S01 booted the title in
780 ms and stood the Meadows up on the New Game path.

And then the run measured three defects in the instrument that stop the
protocol executing, filed them as a run-level BLOCKER rather than improvising
around them, and stood down. This round fixes those three and records the
protocol amendment the owner approved on the back of them.

**Everything round 1 got right is still here and was not touched:** the capture
pre-flight, the context guard, the dialogue predicate, entity walks,
`INVENTORY.json` asking `git check-ignore`, the image-quality gate, and CD-8b
refusing a freeze record that contradicts the process. The operator proved
CD-8b works by *running into it* and did **not** edit the freeze record to get
past it. That behaviour stays possible; see Finding 15.

## The constraint this lane worked under, stated first

The 12,721 ms rendered frame is **llvmpipe software rasterisation with no
GPU**. It is not a statement about the game. `data/config/grass_field.json` is
settled, owner-approved art that this lane did not open and must not:
`git diff main...HEAD -- data/ scripts/ scenes/ assets/ project.godot` is empty
and is checked below rather than asserted. Device frame rate remains
**[OWNER-ONLY]** (§0.4). A content change to make a software rasteriser faster
would be optimising for the wrong target.

---

## Finding 12 — `route.csv` measured the box, not the game, and §D says that is
## the one thing it must not do

`_t()` was `Time.get_ticks_usec() - _t0_usec`. Two consumers read it and both
were wrong for it.

**`route.csv`'s `t` and its 2 Hz cadence.** §D takes elapsed time,
`since_interaction_s` and every dead-travel interval out of `route.csv`
*precisely because* — its own words — "harness wall time lies (the 2026-08-23
evidence records exactly why)". It was harness wall time. Distances were
unaffected: `_distance_m` and `_dead_travel_m` accumulate per physics step and
always did. Every **duration** was inflated by the ratio between a 6.465 s
frame and the 1/60 s the game believed it had just simulated — a factor of
about 388 on that box, and **a different factor on any other box**, which is
the part that makes the numbers uncomparable rather than merely large.

**The continuous recorder.** `_record_next_t = _t() + 1/hz`, so §H's "PNG every
2 s (0.5 Hz)" was 2 s of *wall*. Under a 12.7 s frame it is due on every
rendered frame. §H planned ~90 frames for S01; the segment was on course for
~5,400, roughly 10 GB, into a container with 23 GB free — and a second copy
into `.git` to be committable at all.

### What play time is, and why not an accumulator

`_play_t()` is `(Engine.get_physics_frames() - _t0_frames) /
Engine.physics_ticks_per_second` — the elapsed time the game believes in,
counted in the only unit it has.

An accumulator (`_play_t += delta` in `_tick`) was the obvious alternative and
is worse in two ways. It only advances where a step calls `_tick`, so a boot
settle or a `capture`'s settle frames would be free; and it misses the physics
steps a slow rendered frame packs in — Godot runs up to
`Engine.max_physics_steps_per_frame` per drawn frame, which is exactly what the
run-2 BLOCKER's "the 12,721 ms rendered frame is consistent with about two
physics steps inside it" describes. `Engine.get_physics_frames()` counts the
steps the engine actually ran, and keeps counting while the tree is paused,
which is most of a menu segment.

### Which clock each consumer now reads, and why

Said out loud in `RUN_METADATA.json`'s new `clocks` block, so nobody has to
infer it from source again — which is how this went unnoticed through every run
since the harness was written.

| consumer | clock | why |
|---|---|---|
| `route.csv` `t`; the 2 Hz trace cadence | **play** | §D's numbers are about the game |
| `events.jsonl` `t`; `frames/…` manifest `t`; the note file's `events: t=` | **play** | one shared axis, or §H's timestamp correlation does not join |
| `record_hz` / `trace_hz` | **play seconds** | a cadence in wall seconds is a cadence in box speed |
| `since_interaction_s`, `_distance_m`, dead travel | **play** | already per-physics-step; unchanged |
| `route.csv`'s `wall` column | wall datetime | the join between the two clocks; unchanged |
| the cost gate, the disk gate | **wall** | they are questions about the box |
| `duration_ms` on boot/save/load; `frame_grab_ms` | **wall** | a boot cost is a wall-clock fact |
| `frame_ms` / `physics_ms` columns | neither — `Performance` monitors | unchanged |

The 14 `route.csv` columns are **unchanged**, so nothing downstream re-parses.
§C.2 is amended to say what `t` means rather than the schema being widened.

**What this does not fix:** every run before 2026-08-28 has durations inflated
by that run's own frame cost. They are not retro-correctable from the artefacts
— `wall` gives the wall elapsed but not the physics-step count — and they are
not comparable across boxes. Any §D number quoted from a pre-2026-08-28 run
should be read as the harness's, not the game's.

---

## Finding 13 — the cost gate re-priced on a title screen and applied it to
## hours of Meadows

Round 1's Finding 4 is right about *why* to re-price and shipped it as a
one-shot after the **first** boot. For every journey segment the first boot is
the **title screen**, which is not the scene the segment spends its time in
either. Three prices, same box, same segment, same day, from the run's own
artefacts:

| | s/frame | S01 predicted |
|---|---|---|
| pre-flight, empty tree | 0.0065 | 71 s |
| re-priced after `boot: title` | 0.0465 | **505 s** — what the gate used |
| measured, in the Meadows | **6.465** | **70,197 s** |

139× under-price against the row cadence, 274× against `TIME_PROCESS`. At the
real price the 14,400 s ceiling buys 2,225 frames and the *smallest* of the
eighteen segments asks for 26,835. **Every capture-bearing segment should have
blocked. Two did.**

Four changes, and the first is the one that matters:

1. **Re-price after every boot**, named for the scene (`boot:title`,
   `boot:world`). `_reprice_done` is gone.
2. **Price the remainder, against the remaining budget.** `_predict_frames_from`
   costs the steps that are *left*; the budget is the ceiling minus the wall
   clock already spent. Re-charging a segment for a boot it has already paid
   for would refuse work that is genuinely affordable, which is the same class
   of error in the other direction.
3. **Re-check in play**, every `cost_recheck_frames` (120) ticked frames, from
   wall-already-spent over frames-already-ticked. That costs nothing and it is
   the only number that tracks a scene getting more expensive as the player
   walks into it. `_reprice`'s stop-and-measure is reserved for the moment a
   scene *changes*, where there is no history to read.
4. **`wait` honours a mid-step abort.** `wait` is where the protocol's hours
   live: S01-09 asks for 10,800 physics frames, 19.4 hours at the measured
   price, and a gate that could only act at the next *step* boundary would
   watch the whole of it go past. Every other frame-advancing loop is bounded
   by a walk or a press budget and stops at its own boundary, which the step
   loop then sees — **this is the one loop that aborts mid-step, and that is a
   deliberate limit, not an oversight.**

Two smaller corrections that came with it:

- **The cost probe must not become the cost it measures.** `cost_probe_frames`
  is 20, which was 0.12 s when a frame cost 6 ms and is over two minutes at
  6.465 s — *every time a scene comes up*. It now stops at
  `cost_probe_budget_s` (20 s) once it has `cost_probe_min_frames` samples.
- **The ceiling now applies to every segment with somewhere to write**, not
  only capture-bearing ones. Round 1 gated only segments planning evidence,
  which was defensible while capture was the only expensive thing. The evidence
  split makes a logic lane the normal way to run a journey, and a logic lane
  can spend a week too.

**The ledger records a price that moved, not a heartbeat.** The first cut logged
every recheck and produced ~100 identical rows saying 16.6 ms for one
twelve-step self-check, which buries the two rows that matter and bloats every
artefact carrying them. A boot re-price and any refusal are always kept; an
in-play sample is kept when it moves the price by ≥ `cost_log_change_fraction`
(25%). `cost_rechecks` carries the count of the ones not kept, so the sampling
itself stays auditable.

---

## Finding 14 — disk was a ceiling nobody had priced

At §H's planned cadences the eighteen segments were ~25 GB **before** the
frame-cost multiplier, into a container with 23 GB free, and doubled again by
the copy `.git` must carry for the evidence to survive the container at all.
Nothing anywhere had asked.

The pre-flight now prices bytes beside seconds, from **measured inputs only**:

- **bytes per PNG** from the pre-flight self-test — a real frame of the real
  scene at the real capture resolution, encoded by the same code path every
  evidence frame will use. Not an assumed size.
- **free space** from `df -Pk` asked of the run directory itself.
- **×2 for `.git`** applied only where `git rev-parse --is-inside-work-tree`
  says the run directory is inside one. Cached: the answer cannot change
  mid-segment and spawning git a few hundred times to re-ask would make the
  gate cost more than it saves.
- **file count** = cadence frames (predicted *play* seconds × `record_hz`) +
  one forced frame per remaining step (§H coalesces every event raised on a
  tick into a single frame, so that is the bound) + the prescribed shots not
  yet taken.

Two rules it follows deliberately:

- A **`df` that cannot answer reads as NOT GATED**, never as "no room". A disk
  check that refused every run it could not measure would be this lane's own
  mistake in mirror image — the same reasoning `_uncommittable` uses for a git
  that cannot answer.
- A process that **cannot render writes no frames**, so the estimate is zero
  and the gate is silent. **Disk is never a reason to refuse a logic lane.**

A disk breach is a **`hard_why`**, like a cost breach: it has nothing to do with
whether this invocation can take pictures, so `--gatef-allow-no-capture` cannot
waive it. That is round 1's Finding 9 applied to a third refusal.

---

## Finding 15 — the evidence split, and why a logic lane's completeness is a
## different question from a capture lane's

**Owner decision, 2026-08-27.** Recorded in `ralph/GATE_F_MASTER_PROTOCOL.md`
§H.1 with the measurement behind it, and in `§0.3`, `§G` and `§M` where those
sections make claims the split changes.

### The measurement

A rendered frame of the Meadows costs 12,721 ms on this container; the same
scene in logic mode costs 6.1 ms. The eighteen segments ask for 4,607,802
physics frames — about 8,283 hours in capture mode.

The decisive second measurement is what *is* affordable: `tools/_probe_grass_pass.gd`
took **14 real 1920×1080 frames across four bands in about 28 minutes on this
container with the grass field ON**. Frames from targeted probes are cheap.
**4.6 million rendered physics frames are not.** Continuous *recording* is what
this envelope cannot afford — not capture.

### What a segment declares

`evidence_lane`, default `"both"`, which is exactly what every segment written
before the split means, so nothing unconverted changes behaviour.

| | runs | owes | `record_hz` |
|---|---|---|---|
| `"logic"` | headless, for mechanics, telemetry and step verdicts, at 6.1 ms/frame | its step verdicts, `events.jsonl`, `route.csv`, saves | forced to `0` |
| `"capture"` | under xvfb, at named states | every id in its own `owes`, on disk | `0` baseline; **bounded** `record_start`/`record_stop` windows are fine |
| `"both"` | as before | its own §G frames **and** its own §H record | as declared |

A capture lane reaches a named state the same way the journey did. A title
screen needs only a boot — which is why `S01`/`S01C` is the worked pair and why
it was runnable here. Anything deeper is seeded from the logic lane's nearest
save (`seed_save` → `boot` → `await_load`) and staged forward by a short
scripted approach. **§0.6 still holds**: production paths only, `free_build`
off, no granted state, because the state being photographed was produced by
production play. Some §G frames — mid-dialogue, mid-fight — are not saveable
states and need that staging preamble; that is seconds of play per frame
instead of hours, and it is stated here rather than discovered later.

### The completeness argument — this is the careful part

Round 1's Finding 8 drew a line: *a capture that cannot be **taken** is a FAIL,
because the evidence is owed; a measurement that cannot be **made** is a SKIP,
because nothing is owed.* Debt versus unanswerable question. That was right,
and it was right specifically because the alternative was 9,231 false PASSes.

The split adds a third case that is neither, and getting it wrong in either
direction reproduces a known failure:

- Call a delegated capture a **FAIL** and every logic-lane segment is
  permanently incomplete for frames it never undertook to take. The instrument
  would report a deficiency that does not exist, which is the class Phase B had
  to refute from the f082bdf6 run's own data — three of its four loudest
  findings were the instrument's.
- Call it a **PASS**, or drop it silently, and the debt is discharged by not
  mentioning it. That is the *exact shape* of the 9,231 `file: null` PASSes,
  wearing a different label.

So the resolution is **the debt moves up a level, and is checked there**:

1. A capture a lane **owed** and did not take is still a **FAIL**, at that
   segment. `INVENTORY.json`, unchanged. CD-1 is untouched.
2. A capture a lane **handed over** is a **DELEGATION** — its own verdict word,
   counted separately from PASS, FAIL and SKIP, written into `INVENTORY.json`
   under `captures.delegated` / `delegated_to` and into an unmissable
   `DELEGATED.md` beside `INCOMPLETE.md`. The segment is complete when it has
   done what **its lane** owes.
3. A delegation **nobody paid** is a **run-level deficiency**, and
   `tools/gate_f/run_inventory.py` is where that is answered — over the whole
   run directory, reading every `INVENTORY.json` and every shot **off disk by
   size**, writing `RUN_INVENTORY.json` and `RUN_INCOMPLETE.md` and exiting
   non-zero. It asks `git check-ignore` too, for the same reason the
   per-segment inventory does: evidence git will not carry dies with the
   container.

The level matters. "Does this frame exist anywhere in this run?" is not a
question a segment can answer, and asking it of a segment is what forced the
FAIL-vs-PASS false choice in the first place.

**And the debt cannot evaporate quietly.** Three declarations are refused at
step 1, before any frame is spent:

- a logic lane with prescribed captures and no `capture_lane`;
- a `capture_lane` that does not exist, does not declare
  `evidence_lane: "capture"`, or whose `owes` list does not accept every id
  handed to it;
- a capture lane whose `owes` names an id no step of it actually shoots — CD-1
  wearing a different hat.

The check runs **before** the frame-cost probe, so a typo costs nothing.

### CD-8b is refined, not weakened

A run that is headless for its logic lane and X11 for its capture lane cannot
be described by one flat `display_server`. `RUN_METADATA.json` may therefore
carry `"lanes": {"logic": {...}, "capture": {...}}`, and the pre-flight reads
the entry for the lane the segment declared.

**A record with no `lanes` block still binds every segment by its flat claim**,
exactly as before. So a run that wants a logic lane must **say so in the freeze
record before the run** — which is precisely what the run-2 operator asked the
coordinator to decide, rather than amending a record mid-run to get a segment to
start. That is still the sin CD-8b exists to prevent, the contradiction is still
a `hard_why`, and `--gatef-allow-no-capture` still cannot waive it. Proved by
running it: see the negatives table below, where a logic lane run against the
stale candidate record — which claims X11 and knows nothing about lanes — is
refused exactly as the operator's `S02` was.

---

## What was run, and what was not proved

Round 1's standard: prove it by running it, and say what was not proved.

### The split, end to end, on this container

One run directory, `rig2-b`, with a lane-aware freeze record written **before**
the run:

```json
{ "lanes": { "logic":   {"display_server": "headless"},
             "capture": {"display_server": "X11 under xvfb-run"} } }
```

| | invocation | result |
|---|---|---|
| **S01** (logic) | `run_segment.sh S01` — headless | **COMPLETE**, exit 0. 14/14 steps ran: 12 PASS, 1 FAIL, **1 DELEGATED**. `DELEGATED.md` names `GF-01-TITLE-01` and `S01C`. 362 `route.csv` rows, 0 frames. |
| **S01C** (capture) | `run_segment.sh --capture S01C` — xvfb, 1920×1080, smoke passed with no fallback | **COMPLETE**, exit 0. 7/7 PASS. `shots/GF-01-TITLE-01.png`, **65,297 bytes**, on its manifest row, `exists: true` read off disk. |
| **the run** | `run_inventory.py rig2-b` | `1/1 prescribed frames present on disk`, **run is COMPLETE**, exit 0. |

The frame S01C took measures **mean luma 50.8, spread 32.4, 5.4% dark** — the
same three numbers the 2026-08-27 run recorded for the same id. Same evidence,
different lane, at the cost of a boot instead of a segment.

**CD-8b was exercised, not assumed.** S01C's pre-flight resolved its claim from
`lanes.capture.display_server` and recorded the key it used:
`{"key": "lanes.capture.display_server", "lane": "capture", "claim": "X11 under
xvfb-run"}`. And a capture-lane segment run *headless* against the same record
is refused for the contradiction — see the negatives below, third row.

### The two clocks, separated and visible in one file

S01's `route.csv` runs **t = 0.72 → 180.88** while its `wall` column runs
**02:04:03 → 02:08:12**. 180 play seconds; **249 wall seconds**. 362 rows is
exactly 2 Hz over 181 play seconds. Before this change the same file would have
reported the 180 s wait as ~249 s of "elapsed time" and handed that to §D.

### The cost gate, and the case a per-boot re-price alone would still miss

S01's ledger:

| at | s/frame | frames left | predicted | budget left |
|---|---|---|---|---|
| pre-flight (empty tree) | 0.0059 | 10,856 | 71 s | 14,400 s |
| `boot:title` | 0.0065 | 10,856 | 72 s | 14,399 s |
| **in-play, step 8** | **0.591** | 10,805 | **6,387 s** | 14,328 s |
| in-play, step 8 | 0.0167 | 10,805 | 180 s | 14,326 s |

**There is no `boot:world` row, and that is the point.** On the New Game path
the world is stood up by the button press, not by a `boot` step — so a re-price
that only fires on `boot` would have carried the title screen's 0.0065 s/frame
through the whole segment. The in-play recheck is what caught the 0.591 s/frame
stand-up. Fixing only the "re-price after the *right* boot" half would have
left this hole open.

91 rechecks ran; 3 rows are in the ledger, which is the log-a-move rule working.

### Every new refusal, run rather than read

All at step 1, all with **0 steps executed**, all exit 1.

| what | refusal |
|---|---|
| logic lane → a capture lane that does not exist | *"evidence_lane=logic delegates to \"NoSuchLane\" and res://tools/gate_f/segments/NoSuchLane.json does not exist or does not parse. A handover to a file that is not there is a debt that has quietly stopped existing."* |
| logic lane with captures and no `capture_lane` | *"…with 1 prescribed capture(s) in its steps and no \"capture_lane\". The split moves a debt; it does not cancel one."* |
| capture lane owing an id it never shoots | *"…claims to owe [\"GF-99-FAKE-03\"] but no capture step in this segment takes them…"* — **and, in the same refusal**, the CD-8b contradiction, because a capture lane running headless against a record that says X11 is exactly the fault CD-8b exists for |
| logic lane handing `S01C` an id its `owes` does not accept | *"…hands 1 id(s) to \"S01C\" that its \"owes\" list does not accept: [\"GF-13-FINALE-03\"]. An unaccepted delegation is how a segment would become capture-incomplete forever without anything ever saying so."* |
| **the cost gate re-pricing in scene** (`selfcheck_walk`, ceiling forced to 120 s) | pre-flight priced it at **70.7 s on the empty tree and let it through**; `boot:world` re-priced it at **157 s against the 46 s of budget left** and stopped it. Segment ran 1 of 12 steps. This is the defect's exact shape, reproduced and then caught. |
| **the disk gate** (`S01C`, reserve forced to 20 kB below free) | *"disk: predicted 85 kB of evidence (8 files at a measured 11 kB each, ×1 for the copy git has to carry) … against 23.71 GB free with a 23.71 GB reserve."* Run **with `--gatef-allow-no-capture`**, which did not waive it — a `hard_why`, like cost. |
| **the run-level ledger**, S01 alone in a run directory | S01's own `INVENTORY.json` says `complete: true`; `run_inventory.py` exits **1** with *"UNPAID DELEGATION: S01 handed GF-01-TITLE-01 to S01C and the capture lane never ran in this run directory."* This is the case the whole design exists for. |

### Tests

`tests/test_gate_f_rig.gd` is 49 tests (was 36); `--only=gate_f` runs **66
across both Gate F files, green**. Thirteen are new and each names the finding
it guards. One existing test was **changed**, deliberately and not to make
something pass: `test_the_verdict_ledger_counts_skips_separately` asserted the
literal `{"PASS", "FAIL", "SKIP"}` ledger and now asserts `DELEGATED` alongside
them, with the reason in the message.

---

## What this lane did NOT prove, and what it left for others

- **Nothing about the game.** This lane is not the judge. S01's one FAIL —
  `S01-12`, tracked objective `opening:beat:road` where the step expected
  `opening_first_catch` — is a step verdict the logic lane produced, not a
  finding, and whether it is a segment-script transcription question or a game
  question is the operator's and Phase B's to say.
- **Seventeen of the eighteen segments are still `evidence_lane: "both"`, and
  still block on cost.** That is correct: the gate now prices them honestly
  instead of under-pricing them by 139×. Converting them is authoring work —
  each needs a capture lane that reaches its named states from the logic lane's
  saves — and it belongs to the run lane, not here. Writing seventeen stub
  capture segments that claim ids they cannot reach would be worse than
  writing none, and the pre-flight would refuse them anyway.
- **The mid-step cost abort covers `wait` only.** Every other frame-advancing
  loop stops at its own budget and the step loop then sees the block. Stated as
  a limit rather than left to be discovered.
- **No capture lane deeper than a title screen has been run.** The
  `seed_save` → `boot` → `await_load` → staging-preamble pattern is the
  documented route to a mid-journey state and the harness has all four steps,
  but this lane exercised only the case that needs none of them. That is the
  largest untested claim in this round and it is named here rather than
  implied.
- **Pre-2026-08-28 `route.csv` durations are not retro-correctable.** The
  artefacts carry wall datetimes but not physics-step counts.
- **Nothing in `scripts/`, `scenes/`, `data/`, `assets/` or `project.godot` was
  touched**, `data/config/grass_field.json` included.
  `git diff --stat origin/main...HEAD -- scripts/ scenes/ data/ assets/ project.godot`
  is **empty**, and that is checked rather than asserted.
