# X07 stopped at step 184 of 266 — BLOCKER, by cost, in this envelope

**Status: STOPPED by the operator under §A's blocker rule.** Evidence preserved,
nothing deleted. `notes/` is empty because the harness writes step verdicts at a
segment end this segment never reached — the same mechanism that left
`gate-f-run-20260825T201354Z/S01-superseded-1/notes/` empty.

## What was captured before the stop

| | |
|---|---|
| planned captures | 80 |
| **captures completed** | **79** |
| frames (background record) | 550 |
| events | 368 |
| route rows | 1,199 |
| segment t at stop | 10,247 s |
| wall clock consumed | **~3 h 05 m** |

**The one missing capture is `GF-14-COMBAT-13-weather` (X07-187)**, a fight frame
under the pinned rain/fog preset. Every other planned frame exists.

## Why it was stopped rather than waited out

`operator_harness.gd::_step_wait` converts seconds to physics frames:

```gdscript
frames = maxi(frames, int(seconds * float(Engine.physics_ticks_per_second)))
```

So `{"seconds": 90}` is **5,400 physics frames**, and in capture mode every
physics frame is a rendered 1920×1080 frame on llvmpipe.

**This segment's own `route.csv` measures that frame:**

- **mean `frame_ms` 9,416 ms** over 1,194 sampled rows
- recent rows **10,426 – 10,698 ms**, max **21,714 ms**
- i.e. **~0.095 FPS**

Therefore one `wait 90 seconds` step costs **5,400 × ~10.5 s ≈ 15.75 hours**.

X07 has **two** such steps remaining — `X07-184` (in progress at the stop) and
`X07-188` — for **roughly 31 hours** to gather one additional frame and the
verdict file. That is not a viable use of the envelope, and it is a **cost**
blocker, not a hang: the process was alive and advancing throughout.

**Do not read the 9,416 ms as a game performance number.** It is llvmpipe
software-rasterising 762,058 props with no GPU. Device frame rate remains
**[OWNER-ONLY]** (§K.1). For scale, check-in 8 measured ~3,400 ms/frame in the
same mode against **466,922** props; this candidate carries **762,058**, and the
cost has risen roughly 3×.

## The evidence is not compromised

**The 79 captured frames are complete and verified.** The mandated colour
spot-check was run over **all 79** before the stop:

- **no step change after frame 1** (frame 1 R/B 1.279, frame 79 0.694);
- **nothing in the 2.9–3.9 artefact band** (max 2.154, min 0.614, median 1.044);
- the single elevated cluster is confined to `the_ridgeline_watch` and recovers
  on the very next region (`stronghold_approach`, 1.042), with the 18 frames
  after it averaging **1.055**.

So the deterministic hue-rotation artefact **does not affect this batch**, and
X07's capture path is now **tested** rather than assumed — closing the question
`GATE_F_HANDOVER_2026-08-26_EVENING.md` §5 left open.

## For whoever runs X07 next

**`wait` is priced in rendered frames, and in capture mode on this box that is
~10.5 s each.** Any capture-mode segment carrying `wait` steps measured in tens
of seconds cannot finish here. The fix is not to shorten the protocol's waits —
they exist so fights resolve — but to price them against the renderer before
launching, or to run the capture batch on hardware with a GPU. That is a
harness/envelope decision for outside a run; **`tools/gate_f/**` is frozen to the
operator and was not modified** (§13).
