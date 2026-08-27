# Gate F rig lane — log

Branch `ralph/GATE-F-RIG`. Tier 0 of the post-Phase-B plan: make the Gate F
operator harness able to drive the game and able to prove what it saw.

The lane's premise, from Phase B: the run against candidate `f082bdf6`
independently found 13 of 162 known player-facing issues — **8.0%** — and three
of the four loudest findings in it were harness artefacts, refuted by the run's
own data. That is a defect in the instrument, not a verdict on the game.

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

They are on the unmerged branch **`origin/ralph/GATE-F-PHASE-B`** (`ae3ee33d`),
which `git ls-remote` shows but which nothing routed to. `ralph/.gdignore` did
not exist either, though the brief says it does; it is created on this branch.

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

## Finding 2 — CD-2's other half was `.gitignore`, not the harness

`COVERAGE_DEFECTS.md` reads: *"`operator_harness.gd:1212` writes to
`shots/<id>.png`. No `shots/` directory exists anywhere in the run and git has
never carried one."*

Both halves of that are true and they have different causes.

`_open_outputs()` has always created `<run>/<segment>/shots/` and
`_step_capture` has always written into it. What was never true is that git
carried any of it: `.gitignore` line 34 read

```
shots/
```

**unanchored**, which in gitignore syntax matches a directory of that name *at
every depth* — including `ralph/reports/gate-f-run-*/<segment>/shots/`. The
comment above it says "Survey output. Regenerate with tools/survey.sh", so the
pattern was written for the repository-root `shots/` and has been quietly
swallowing every Gate F capture and every `shots/manifest.json` since the
harness was written.

Anchored to `/shots/`. Verified both ways with `git check-ignore -v`.

The two halves compound: the run that *could* have produced PNGs (CD-1's
segments ran headless, so none did) would have had them dropped on the way to
the commit, and the reviewer's "no prescribed screenshot exists anywhere" would
have been true either way, for a second reason nobody had looked for.

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

## What landed

Against `COVERAGE_DEFECTS.md`'s own numbering. CD-1…CD-7 are instrument work
that lands outside a run (§13, §1.5); step 6 of §16.4's loop — re-run the new
segment against the candidate — is **not** discharged here and is not claimed
to be. Operator/developer separation (§13) still applies and no Gate F segment
was re-run by this lane.

| | What it was | What landed |
|---|---|---|
| **CD-1** | Capture steps under a headless process returned `"capture … skipped"`, which does not begin with `FAIL`, so the step recorded **PASS**. 9,231 times. | Capture pre-flight before step 1 of any segment declaring a capture or a continuous record: display server, `capture_diag_minimal.gd` PNG beside the run, and the process's own framebuffer readback. Any of the three failing is a BLOCKER; no step runs. `--gatef-allow-no-capture` acknowledges it explicitly and still cannot mark the segment complete. An untakeable capture now returns `FAIL`. `run_segment.sh` refuses the same combination before Godot starts. |
| **CD-2** | No prescribed screenshot exists anywhere in the run. | §M's closing inventory runs as code: `INVENTORY.json` per segment, planned id → file → **exists** → **bytes** read off disk, `complete` computed rather than claimed, `INCOMPLETE.md` written when it is false, non-zero exit on a missing artefact. Plus the `.gitignore` anchor — see Finding 2. |
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

`tests/test_gate_f_rig.gd`, 29 tests. `--only=gate_f` runs 35 across both Gate F
files, green. Three pure helpers (`_context_matches`, `_plan_captures`,
`_predict_frames`) were made `static` so they can be called directly rather than
grepped for — a source-level test checks the spelling, not the rule.

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
