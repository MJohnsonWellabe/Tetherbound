# S01 — stopped by the operator at 66 minutes, 5.1% through one step

This segment did **not** reach its close, so the harness wrote no
`INVENTORY.json` and no `RUN_METADATA.json`. That absence is correct and is not
a harness fault; `run_segment.sh`'s own closing line for it is *"no
INVENTORY.json was written; the segment did not reach its close"* and its exit
status is 143 (SIGTERM, sent by the operator). Everything else in this directory
is real, was produced by the production path, and is preserved exactly as found.

## What it got through

| step | verdict | evidence |
|---|---|---|
| S01-01 | note | section H cadence declared |
| S01-02 | PASS | fresh `user://`; the save directory did not exist yet |
| S01-03 | PASS | **booted title in 780 ms** |
| S01-04 | PASS | `input_context=title` |
| S01-05 | PASS | `focus_owner=@Button@27`, `focus_text="Start New Game"` |
| S01-06 | PASS | **`GF-01-TITLE-01` captured at 1920x1080** — mean luma 50.8, spread 32.4, 5.4% dark |
| S01-07 | note | front-door observation |
| S01-08 | PASS | `ui_accept` tap resolved to `JoyBtn:0`; New Game taken |
| S01-09 | **stopped inside** | the 180-second settle: ~549 of 10,800 physics frames in 3,963 s |
| S01-10..14 | not reached | region / party_size / objective asserts |

The world did stand up on the production New Game path and reported itself:
`flag_set` and `region_enter grandpas_village` at t=280.7 s, `landmark_discover`
at t=281.7 s. 275 continuous-record frames and 535 `route.csv` rows are on disk.
The capture pre-flight PASSED: display server present, `capture_diag_minimal.gd`
wrote a PNG at the requested 1920x1080 with no fallback
(`CAPTURE_RESOLUTION.json` `substituted: false`), and the harness's own
framebuffer self-test wrote `_preflight.png`.

## Why it was stopped

Not because it failed. Because it cannot finish, and the arithmetic that says so
is in its own telemetry.

Measured from `route.csv`, in the Meadows, with `grass_field.json:enabled` TRUE:

* row-to-row wall delta **median 6.465 s**, mean 6.752 s. `_tick` writes at most
  one row per physics frame against a 0.5 s wall threshold, so a row per frame
  is a **lower bound of 6.465 s per physics frame**;
* Godot's own `Performance.TIME_PROCESS` **median 12,721 ms** per rendered frame
  (min 12,184, max 14,385) — consistent with ~2 physics steps per rendered frame;
* `physics_ms` median 634 ms.

Step S01-09 asks for 10,800 physics frames. At the measured 6.465 s that is
**19.4 hours for one step**, of which 66 minutes had been spent. The rest of the
segment would have written roughly 5,400 continuous-record PNGs — about **10 GB**
— into a container with 23 GB free, and a second copy into `.git` to be
committable at all. Its evidence could not have left this container.

The full protocol at this measured cost is **4,607,802 physics frames, about
8,283 hours**.

## The three instrument facts behind that, measured not inferred

1. **The cost gate prices the wrong scene.** CD-7 re-prices after the first
   `boot` because the empty-tree number "is not about the scene the segment will
   render". For every journey segment the first `boot` is the **title screen**,
   which is not that scene either. It priced this segment at **0.0465 s/frame**
   and predicted 505 s. The Meadows measured **6.465 s/frame**: a **139x**
   under-price against the row cadence, **274x** against `TIME_PROCESS`. At the
   measured cost the 14,400 s ceiling buys 2,225 frames, and the **smallest** of
   the eighteen segments asks for 26,835. Every capture-bearing segment in this
   protocol should have BLOCKed on cost; the gate passed seventeen of eighteen.
2. **`t` is wall clock, not play time.** `_t()` is
   `Time.get_ticks_usec() - _t0_usec`. Every `t` in `events.jsonl` and
   `route.csv` is wall seconds of a software rasteriser. Section D takes its
   elapsed times, `since_interaction_s` and dead-travel intervals from
   `route.csv` precisely *because* "harness wall time lies" — and this is
   harness wall time. Distances are unaffected; every duration is inflated by
   the ratio between a 6.465 s frame and the 1/60 s the game believes it is.
3. **The continuous recorder is wall-gated too.** `_record_next_t = _t() + 1/hz`
   with the same `_t()`. Section H's "PNG every 2 s (0.5 Hz)" is 2 s of wall, so
   under a 12.7 s frame the recorder fires on **every rendered frame**. Section H
   planned about 90 frames for S01; the segment was on course for about 5,400.

None of these is a finding about the game. Nothing in this directory should be
read as one. No code, data or config was changed (section 13); the ceiling was
not raised, no wait was shortened, no script was re-cadenced (section 0.8).
