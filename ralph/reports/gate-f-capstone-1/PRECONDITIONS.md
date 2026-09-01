# GATE-F-CAPSTONE-1 — section A preconditions, closed before step 1

Run dir: `ralph/reports/gate-f-capstone-1`. Branch `ralph/GATE-F-CAPSTONE-1`,
candidate `88df9f47` (nine Gate F leg lanes consolidated onto `main`).

Protocol section A requires four things before S01. All four were done, in this
order, and none of them was done after any evidence existed.

## A.1 — instrumentation landed, candidate SHA frozen

The section I instrumentation (`tools/gate_f/operator_harness.gd` and the
segment step-scripts) is already on `main` at the candidate. This lane adds
nothing to it and changes no game code, data or config for the length of the run
(section 13 / section J). The branch was cut from `origin/main` at `88df9f47`
and nothing under `scripts/`, `scenes/`, `data/`, `assets/` or `shaders/` is
touched by it.

## A.2 — freeze record written

`RUN_METADATA.json`, in this directory, written before the run and committed
before S01 started.

It carries a `lanes` block. That is not a convenience: the global freeze record
at `ralph/reports/gate-f-candidate/RUN_METADATA.json` is the 2026-08-27 freeze
and claims a flat `display_server` of "X11 under xvfb-run", and
`operator_harness.gd::_freeze_display_claim` reads the run-local record first and
that one second. Without a run-local record declaring the logic lane honestly
headless, CD-8b refuses every journey segment before step 1.

`config_flags` is read MECHANICALLY (CD-8), not hand-listed: every boolean at
any depth of every one of the 47 `data/config/*.json` files, 83 in total, with
the 27 that are FALSE repeated in `config_flags_off` so an absent subsystem is
visible without diffing. **`grass_field.enabled` is `true` on this candidate** —
this run is therefore not the configuration CD-8 was written about, and the
ground cover is present in anything the capture lane photographs.

## A.3 — historical snapshot

Coordinator bookkeeping, not the operator's (section 0.2, blind-first). This
lane did not read the prior run's defect catalogue as a checklist.

## A.4 — capture smoke, and the suite green at the SHA

**Capture smoke: PASS at the protocol's requested 1920x1080.** No fallback, so
no substitution to record.

```
$ xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
    --rendering-driver opengl3 --resolution 1920x1080 \
    --script tools/capture_diag_minimal.gd -- --gatef-out=<tmp>
capture smoke: display_server=X11 adapter=llvmpipe (LLVM 20.1.2, 256 bits) viewport=(1920.0, 1080.0)
capture smoke: OK — wrote 1920x1080 to <tmp>/capture_smoke.png
```

**Test suite: GREEN at the candidate.**

```
$ godot --headless --path . --script tests/run_tests.gd
1675 tests, 3630805 assertions, 0 failed
(exit 0)
```

A red suite would have been a blocker before the run rather than a finding of
it. It is green, so the run may start.

## Also measured before step 1 — section I.7 instrumentation overhead

`tools/gate_f/run_segment.sh --overhead`, written to
`overhead/RUN_METADATA.json`. Means over 30 s x 2 windows per condition, in the
order off/telemetry/recording/recording/telemetry/off so drift cancels:

| condition | mean frame time |
|---|---|
| telemetry off | 14.994 ms |
| telemetry on | 14.624 ms |
| telemetry + recording @ 0.5 Hz | 14.574 ms |

Both deltas are **negative** and both are **below the 1.116 ms/frame noise
floor** (the widest a single condition disagreed with itself). The honest
reading is *"instrumentation costs under ~1.12 ms/frame on this box"*, not
*"instrumentation is free"* — the measurement cannot resolve an effect that
small, and section 3's last clause asks for that stated rather than hidden. The
recorder's own grab cost was not measured directly because a headless process
wrote no frames.

CPU frame time on this container only. Device frame rate, GPU time, VRAM and
thermals remain **[OWNER-ONLY]** (section 0.4, section K).

## Envelope facts this run inherits

- **Logic lane, headless.** The journey segments S01-S10e all declare
  `evidence_lane: "logic"` and hand every prescribed section G frame to their
  `SnnC` capture lane. That debt is recorded, not erased: `DELEGATED.md` per
  segment and `tools/gate_f/run_inventory.py` over the run directory.
- **Godot 4.7.stable.official.5b4e0cb0f**, Linux editor binary, sha256 in the
  freeze record. Not the shipped Windows export (section 0.5).
- **4 cores, no GPU, 21 GB free disk** at the start of the run.
