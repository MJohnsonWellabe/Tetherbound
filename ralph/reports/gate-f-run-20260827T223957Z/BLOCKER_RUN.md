# Gate F run 2 — run-level BLOCKER: this envelope cannot execute the protocol in capture mode

**Operator report, per section 13 ("report inability to continue as a BLOCKER
rather than improvising around it") and section A's blocker rule. Candidate
`e12a6b60`. Branch `ralph/GATE-F-RUN-2`.**

I am not the judge. Nothing below is a verdict on the game, and no finding in
this run directory should be read as one. This is a statement about the
instrument and the box, measured on both.

---

## The one-line result

**A rendered frame of the Meadows costs 12,721 ms on this container. A logic-mode
frame of the same scene costs 6.1 ms. The protocol's eighteen segments ask for
4,607,802 physics frames. In capture mode that is about 8,283 hours; the cost
gate predicted 505 seconds for the first one.**

## What did run, and it is real

The instrument works. This is the first Gate F run since the rebuild that
photographed the game.

* Capture pre-flight **PASSED**: display server present, `capture_diag_minimal.gd`
  wrote a PNG at the requested **1920x1080** with **no fallback**, and the
  harness's own framebuffer self-test wrote `_preflight.png`.
* **`GF-01-TITLE-01` exists on disk** — 1920x1080, mean luma 50.8, spread 32.4,
  5.4% dark, on its manifest row. The previous run wrote 9,231 rows saying
  `file: null` and called each one PASS.
* S01 steps 02-08 all PASS on production paths: fresh `user://`, title booted in
  **780 ms**, `input_context=title`, focus held by a Control reading
  **"Start New Game"**, `ui_accept` resolving to `JoyBtn:0`, and the New Game
  path standing the Meadows up — `flag_set` and `region_enter grandpas_village`
  at t=280.7 s, `landmark_discover` at t=281.7 s.
* **X08** (performance audit) ran to completion in logic mode. It is the only
  segment of the eighteen that declares neither a capture nor a continuous
  record, so the pre-flight returns *"not required"* and no cost gate applies —
  and section E.9 prescribes `--headless` for its CPU numbers anyway. Its
  evidence is not degraded and carries no caveat beyond section K's standing
  [OWNER-ONLY] list.

## What stopped it

### 1. The measured frame cost

From S01's own `route.csv`, in the Meadows, with `grass_field.json:enabled` TRUE:

| measure | value |
|---|---|
| row-to-row wall delta, in-world | **median 6.465 s**, mean 6.752 s (n=527) |
| `Performance.TIME_PROCESS` per rendered frame | **median 12,721 ms** (min 12,184, max 14,385) |
| `TIME_PHYSICS_PROCESS` | median 634 ms |
| same scene, logic mode (X08) | **6.1 ms** |

`_tick` writes at most one `route.csv` row per physics frame, against a 0.5 s
wall threshold — so a row every 6.465 s is a **lower bound** on the cost of a
physics frame, and the 12,721 ms rendered frame is consistent with about two
physics steps inside it. Two independent measurements, agreeing.

Step `S01-09` asks for 10,800 physics frames. **19.4 hours, for one settle
step.** 66 minutes bought 549 of them, 5.1%.

### 2. The cost gate prices the wrong scene

CD-7 measures twice because the empty-tree number "is not about the scene the
segment will render". Correct — but for **every journey segment the first `boot`
is the title screen**, which is not that scene either. The re-price is taken on
a menu and applied to hours of Meadows:

| | s/frame | S01 predicted cost |
|---|---|---|
| pre-flight, empty tree | 0.0065 | 71 s |
| re-priced after `boot: title` | 0.0465 | **505 s** — this is what the gate used |
| measured, in the Meadows | **6.465** | **70,197 s** |

A **139x** under-price against the row cadence, **274x** against `TIME_PROCESS`.
At the measured cost the 14,400 s ceiling buys **2,225 frames**, and the
**smallest** of the eighteen segments (X07) asks for 26,835. Every
capture-bearing segment should have BLOCKed on cost. The gate blocked two.

I did not raise the ceiling, shorten a wait, or re-cadence a script. Section 0.8
forbids all three and says what a refused segment actually needs: a GPU.

### 3. Two clocks that are wall clock, and should not be

`_t()` is `Time.get_ticks_usec() - _t0_usec`. Both of these read it:

* **`route.csv`'s `t` and its 2 Hz cadence.** Section D takes elapsed time,
  `since_interaction_s` and dead-travel intervals from `route.csv` *precisely
  because* "harness wall time lies" — and this is harness wall time. Distances
  are unaffected. Every duration is inflated by the ratio between a 6.465 s
  frame and the 1/60 s the game believes it is.
* **The continuous recorder.** `_record_next_t = _t() + 1/hz`, so section H's
  "PNG every 2 s (0.5 Hz)" is 2 s of **wall**. Under a 12.7 s frame it fires on
  every rendered frame. Section H planned about 90 frames for S01; the segment
  was on course for about **5,400**, roughly **10 GB**, into a container with
  23 GB free — and a second copy into `.git` to be committable at all.

Disk is a ceiling nobody has priced. At section H's planned cadences the
eighteen segments were already 25 GB before this multiplier; with it they are
not expressible.

### 4. The degraded lane is refused too, and correctly

`--gatef-allow-no-capture` is the obvious fallback: run the journey for its
logic, accept that the evidence half is void, let the harness mark every segment
incomplete. **It is unavailable here, and I proved that by running it rather
than by reading the code.**

```
$ tools/gate_f/run_segment.sh --allow-no-capture S02
run_segment: WARNING -- S02 plans captures and is running WITHOUT a display server ...
gate-f harness ERROR: capture pre-flight BLOCKER: the freeze record contradicts
  this process: the freeze record ... says display_server=X11 under xvfb-run;
  this process has none
run_segment: INVENTORY.json says S02 is INCOMPLETE
  exit=1   steps ran: 0 of 75
```

That is **CD-8b behaving exactly as designed**, against a freeze record I wrote
before the run and deliberately stated as the capture-mode fact. `hard_why` is
not waivable by the acknowledgement flag, which is the fix Finding 9 of the rig
log landed on purpose. `S02/BLOCKER.md` and `S02/INVENTORY.json` are that
refusal, preserved.

The fix is **not** to edit the freeze record mid-run. Amending a freeze record so
a segment will start is the sin CD-8b exists to prevent, in mirror image.

## So the journey lane is unavailable in both modes

| mode | S02..S10, X01..X07 |
|---|---|
| capture | ~8,283 h and ~10 GB per segment of continuous record |
| logic + `--allow-no-capture` | hard BLOCKER at step 1 (CD-8b), 0 steps run |

## What this run therefore contains

| segment | state | why |
|---|---|---|
| S01 | **partial, stopped by operator** | 8 of 14 steps PASS incl. the prescribed capture; stopped inside step 09. `S01/STOPPED.md` |
| S02 | **BLOCKER at step 1** | CD-8b freeze-record refusal, deliberately provoked and preserved. `S02/BLOCKER.md` |
| S03..S10, X01..X07 | **not run** | the cost above |
| X08 | **ran** | declares no capture and no continuous record; no cost gate applies |

No code, data or config was changed at any point (section 13). A path-restricted
diff of `e12a6b60..HEAD` excluding `ralph/` is empty, and that is checked rather
than asserted.

## What the coordinator has to decide, because the operator may not

1. **Run the protocol on hardware with a GPU.** This is section 0.8's own answer
   and the only one that preserves the protocol as written.
2. **Whether a capture-free logic lane is worth having at all**, and if so, that
   it needs a freeze record that says so *before* the run — not an amendment
   during one. It would deliver the majority of section L's coverage matrix
   (contexts, dialogue predicates, walks, catches, combat, save handoff) and
   **none** of sections 11, G or E.7. That trade is a judgement about what Gate F
   is for, and section 13 puts it outside the operator's authority.
3. **Where the three instrument facts above get fixed** — the cost re-price
   after the first *world* boot rather than the first boot; the two wall-clock
   gates; and a disk budget beside the time budget. Each is a permanent-template
   change of the same kind CD-1 through CD-8b already made.

I have not decided any of these. This document exists so someone with the
authority can.
