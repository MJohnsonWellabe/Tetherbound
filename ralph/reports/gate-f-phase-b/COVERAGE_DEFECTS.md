# Gate F Phase B — Deliverable 4: coverage-defect feedback loop (§16.4)

138 of 162 player-facing historical items were classified `MISSED BY GATE F /
COVERAGE DEFECT`. §16.4 requires that for **every** such item the protocol is
told why it missed, and strengthened.

They do not need 138 separate answers. They have **seven** causes. Each is stated
as §16.4's five-step loop: *why it missed → what action to add → what evidence to
add → what regression to add → what changes in the permanent template.*

Step 6 ("re-run the new segment against the candidate") is **not discharged by
this Phase B** and is not claimed to be: re-running is operator work, and the
candidate must be re-frozen after the instrument changes land (§1.5, §1.6).
Every entry below names which segment must be re-run.

---

## CD-1 — Segments with planned captures ran with no display server

**Why it missed.** `run_segment.sh` launched the journey and study lanes without
the §0.1 xvfb invocation — while the freeze record claimed X11 under xvfb was
present (CD-8b). Nothing stopped them. The harness wrote 9,231 manifest
rows saying `file: null` and the segments reported PASS on the capture steps
("capture GF-… skipped (headless run); manifest row written with file:null").
A step that cannot produce its evidence returned **PASS**.

**Action to add.** A capture pre-flight, before step 1 of any segment whose
step-script contains a planned capture: assert a display server and a successful
`capture_diag_minimal.gd` PNG. Fail as a **BLOCKER** (§A), not a skip.

**Evidence to add.** `RUN_METADATA.json` gains `display_server` and
`capture_preflight` (pass/fail + the smoke PNG path).

**Regression to add.** CI check: a segment JSON containing a `capture` step must
be launched by a runner path that sets the xvfb invocation. Assert in
`run_segment.sh`'s own self-check.

**Permanent template change.** §G gains a rule: *a planned capture that cannot
be taken is a **FAIL**, and a segment that cannot take any of its planned
captures is a **BLOCKER** at step 1. `file: null` is evidence of absence only
when the absence was unavoidable and singular; 9,231 of them is a run that did
not happen.* §C.4's "absent frame is evidence too" is amended to say so.

**Re-run:** S01–S10, X01, X02 — every segment with a planned capture.

---

## CD-2 — Planned captures were never written, even where rendering worked

**Why it missed.** `operator_harness.gd:1212` writes to `shots/<id>.png`. No
`shots/` directory exists anywhere in the run and git has never carried one.
X07 rendered 550 background frames and its `WHY_INCOMPLETE.md` reports "captures
completed: 79", but the named artefacts do not exist, and **23 of those 79
timestamps have no background frame within 3 s** (worst gap 257 s) — including
the §E.7-required HUD-on `-gameplay` frame for **all 11 regions**.

**Action to add.** §M's closing inventory check — "the operator's final act is an
inventory check that every planned artifact exists or carries a recorded reason"
— must run as **code**, not as an instruction. It never ran here.

**Evidence to add.** A machine-written `INVENTORY.json` per segment: planned id →
file → exists(bool) → bytes. A segment cannot be marked complete without it.

**Regression to add.** Runner post-step: fail the segment if any manifest row
claims a capture whose file is absent.

**Permanent template change.** §M gains: *the inventory check is a harness step,
not an operator promise, and its output is a committed artefact.* §11 gains:
*a capture is "completed" only when its file exists on disk.*

**Re-run:** X07 in full (it also never reached its `notes/` verdicts).

---

## CD-3 — Step-scripts guess how many presses a conversation needs

**Why it missed.** Dialogue advance is scripted as a fixed count. Under-press and
the modal sits open; over-press and it re-opens the conversation the previous
press closed (`S02-28`, recorded by the operator: *"every tap past the third can
re-open the conversation the previous tap just closed"*). Downstream cost was
total: `X01-463` held **3,601 frames** in `narrative_modal` 15.8 m short of Bram,
and every X01 surface after it — Settings, rebind, panic reset, shop, tournament,
craft, storage, swap, bed, combat_aim, riding — was probed inside that dialogue.

**Action to add.** Replace `press N times` with `advance_dialogue_until_closed`,
bounded, that presses and re-reads `input_context` each iteration and BLOCKERs on
the bound.

**Evidence to add.** Emit a real `dialogue` event per line (see CD-6) carrying
line index and speaker, so an unanswered modal is visible in telemetry rather
than inferable from a walk failure.

**Regression to add.** Harness self-check: after any dialogue step,
`input_context` must not be `narrative_modal`.

**Permanent template change.** §J gains: *no step may encode a guessed repetition
count for a state-changing UI. Reach a state, then assert it.*

**Re-run:** S02, S03, S04, X01.

---

## CD-4 — Cell probes never re-establish their intended context

**Why it missed.** X01 walks a list of (control, context) cells and presses each
in sequence. A press that changes context is not undone, so the next cell fires
into the new surface. Measured: **303 of 418 cells (72.5%)** were injected in a
context other than the one the step names; eight different surfaces were all
actually probed inside `menu_map`; twelve named surfaces were **never entered at
all**. The matrix's headline "1085 PASS / 118 FAIL" describes mostly nothing, and
its **only** trustworthy content is 115 in-context cells — which were 115/115
clean.

**Action to add.** Every cell is `enter(context) → assert(context) → probe →
restore`. A cell whose context assert fails is `SKIPPED (context not reached)`,
never PASS and never FAIL — those are different facts and the run conflated them.

**Evidence to add.** `input_probe` gains `intended_context` as a first-class
field, so the mismatch is one query rather than a regex over `expected`.

**Regression to add.** Matrix post-processor: fail the segment if
`intended_context != context_before` on more than 5% of cells.

**Permanent template change.** §E.4 gains: *a cell is coverage only if the probe
happened in the named context. Report in-context coverage as a headline number
beside the pass rate — a matrix at 27% in-context coverage must not be reported
as 87.9% behaving.*

**Re-run:** X01 in full.

---

## CD-5 — `move_to` cannot express "be next to the thing"

**Why it missed.** `move_to` compares x/z only. The operator diagnosed one
instance himself (`S02-15`: the bed is 0.89 m from Grandpa in x/z and 3.3 m above
him, so *"the segment pressed `interact` 31 times through the floor"*). The same
shape recurs as 65 `did not reach (x,z)` failures, and it is why the chapter's
first wild fight never staged: `S02-32` pressed `interact` once at a walked-to
coordinate and `S02-34` measured `input_context=world`.

**Action to add.** `move_to_entity(id, within_m)` using the live entity position,
including y; and `interact_with(id)` that asserts the prompt is present before
pressing.

**Evidence to add.** Walk steps record target entity, final distance, and whether
the interact prompt was live at press time.

**Regression to add.** Self-check segment: walk to Grandpa, to a harvest node and
to a wild creature, asserting the prompt each time.

**Permanent template change.** §F gains a definition of *reached*: within
interaction range of the **entity**, prompt live — not within a radius of a
literal coordinate.

**Re-run:** S02 (blocks everything), then S03, S05, S06.

---

## CD-6 — Thirteen §C.1 event types have no emitter

**Why it missed.** `catch_throw`, `combat_hit`, `combat_switch`, `dialogue`,
`gather`, `craft`, `build_place`, `build_cancel`, `build_dismantle`, `rest`,
`feed`, `landmark_discover` and `defect` are in the schema and in nothing else.
Their absence from a run therefore proves **nothing**, and the most tempting
inferences available from this evidence ("no gathering happened", "no orb was
thrown") are unsupportable. `catch_result` compounds it: it fires on party
*growth*, so the single one per segment is the starter loading, not a catch.

**Also in this cluster:** the `inventory` field reported `{"axe": 0,
"berries": 0, "orb_basic": 0, …}` on S03's save event while the very save it
describes contains `orb_basic ×15, potion_small ×3, berries ×5, revive ×2,
pickaxe, knife, torch, axe`. And **no `save` or `load` event in the run carries
`duration_ms`**, so §18's required save/load timings do not exist.

**Action to add.** Implement each emitter as a state watcher (the existing
non-invasive pattern), or strike the type from §C.1 with a recorded reason.
Half a schema is worse than a small one.

**Evidence to add.** As above.

**Regression to add.** Schema conformance test: every type in the §C.1 enum is
either emitted by a self-check segment or explicitly marked `not-instrumented`.
A telemetry test asserting the `inventory` snapshot equals the written save.

**Permanent template change.** §C.5 gains: *a schema field that no code writes is
an instrumentation defect, and Phase B may not treat its absence as evidence.*

**Re-run:** self-check, then any journey segment.

---

## CD-7 — `wait` is priced in rendered frames, so capture-mode segments cannot finish

**Why it missed.** `_step_wait` converts seconds to physics frames, and in
capture mode every physics frame is a rendered 1920×1080 frame. On llvmpipe at
~10.5 s/frame, one `{"seconds": 90}` step costs ~15.75 hours. X07 stopped at
step 184/266 with two such steps remaining (~31 h). The operator's diagnosis in
`X07/WHY_INCOMPLETE.md` is correct and this entry adopts it.

**Action to add.** Price every capture-mode segment's `wait` budget against the
measured frame cost **before** launch, and refuse to start a segment whose
predicted cost exceeds the envelope. The fix is not to shorten the protocol's
waits — they exist so fights resolve.

**Evidence to add.** `RUN_METADATA.json` gains `predicted_segment_cost_s` and the
frame-cost measurement it was computed from.

**Regression to add.** Runner pre-flight comparing predicted cost to a
configured ceiling.

**Permanent template change.** §0 gains an eighth envelope fact: *`wait` is
priced in rendered frames in capture mode. A protocol written in seconds must be
costed in frames before it is launched, or run on hardware with a GPU.*

**Re-run:** X07, X02–X06, X08 — every capture-mode segment.

---

## CD-8 — The freeze record does not enumerate feature flags that change what is rendered

**Added 2026-08-27 after publication, from a Coordinator fact and verified
against the candidate. This is the one coverage defect the run's own evidence
could never have exposed** — which is exactly why it belongs here.

**Why it missed.** `ralph/reports/gate-f-candidate/RUN_METADATA.json` is thorough
about the *envelope*: renderer, display server, resolution, input mode, save
state, `free_build`, binary sha256, instrumentation overhead, suite state. It
records **nothing about `data/config/` feature flags that materially change what
is rendered**. `data/config/grass_field.json` has `"enabled": false` on the
candidate; `grass_field.gd::_ready()` returns before building anything and
`playground_world.gd::_stand_up_the_grass_field()` returns before the node enters
the tree, so **the procedural ground cover is absent from every frame in this
run** — and no artifact anywhere says so. A reviewer judging ground cover from
these frames would be judging the baked scatter while believing they were judging
the shipped ground system, with nothing in the evidence to correct them.

§1.2 requires graphics settings to be part of the freeze record. A boolean that
decides which of two ground systems dresses the entire world is a graphics
setting.

**Action to add.** The freeze step enumerates the state of every gameplay- or
render-affecting flag in `data/config/`, mechanically — read the files, do not
hand-list them — into the freeze record.

**Evidence to add.** `RUN_METADATA.json` gains `config_flags: {file: {flag:
value}}`, generated at freeze. Any flag whose value differs from the file's own
documented default is called out in its own field, so a reviewer sees it without
diffing.

**Regression to add.** Freeze-time check: fail the freeze if a known
render-owning flag is absent from `config_flags`. Runtime: the world prints which
ground system stood up, so the run's own log carries it (`playground_world.gd`
already prints the scatter line; the disabled branch prints nothing).

**Permanent template change.** §A.2's metadata list gains **`config_flags`**, and
§0 gains a ninth envelope fact: *a candidate is a build **and** its
configuration. A flag that decides which subsystem renders the world is part of
the freeze, and a reviewer must never have to infer it from source.*

**Re-run:** none. This is a freeze-record defect, not a segment defect — but no
future Gate F may freeze without it.

### CD-8b — the freeze record and the artifacts contradict each other

Found while verifying CD-8. `RUN_METADATA.json` records:

> `"display_server": "X11 under xvfb-run"`

**Every journey segment's frame manifest says the opposite** — 9,231 rows of
*"headless: this process has no display server and cannot render a frame"*. The
freeze record and the evidence disagree about the single fact that determined
whether §11 could execute at all, and nothing reconciled them for the length of
the run.

**Action to add.** The capture pre-flight of **CD-1** must *write back* what it
actually found, and fail when the observed display-server state contradicts the
freeze record. A metadata field asserting a capability is not evidence that the
capability existed.

---

## Coverage that is a declared §K gap, not a defect

Eight of the 162 trace to §K's pre-registered [OWNER-ONLY] limitations —
device GPU/VRAM/thermal/battery, audio, and first-time-human pacing
(`HIST-001`, `HIST-042`, `HIST-043`, `HIST-044`, `HIST-045`, `HIST-066`,
`HIST-134`, `HIST-204`). Per §K's own closing paragraph these are **declared**
gaps, closed by the owner's pass or by new instrumentation — categorically
different from the 138 undeclared holes above, and they are not counted as
protocol failures.

---

## What must change before the next run is called Gate F

CD-1 through CD-7 are all **instrument** work and all land **outside** a run
(§13, §1.5). Ordering:

1. **CD-5** — nothing else matters while the first wild fight cannot be staged.
2. **CD-3** — unblocks X01 and the village ladder.
3. **CD-1 + CD-2** — without these the next run produces no visual evidence
   either, and half of §14 stays unanswerable.
4. **CD-4** — makes the matrix mean something.
5. **CD-6** — makes absence-of-evidence interpretable.
6. **CD-7** — makes the study lane finishable at all.
7. **CD-8** — cheapest of all, and lands at freeze time rather than in the
   harness. Do it with the re-freeze.

**CD-5's confidence is raised to HIGH, and it gains a cheaper reproduction.**
`RUN_METADATA.json`'s `suite_state_at_freeze.known_open_defect` records, **at
freeze time**, that `tests/smoke_party_count_after_catches.gd` fails
intermittently with *"could not engage the real wild body at Wild_bramblebun_0_3
(stopped 23.7m away (engage range 6.0m))"*, with four hypotheses already killed
and the failure self-diagnosing at this SHA via `_why_the_engage_failed`. That is
the same defect this pass reconstructed independently from S02 telemetry — and it
means the run was launched knowing the chapter's **first required player action**
was unreliable. Start CD-5 from that test, not from a re-run of S02.

Then re-freeze a candidate (§1.1) and re-run. **Not before.**
