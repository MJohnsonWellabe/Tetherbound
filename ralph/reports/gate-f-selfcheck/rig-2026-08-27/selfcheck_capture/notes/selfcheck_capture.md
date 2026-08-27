# selfcheck_capture — Harness self-check: capture mode writes real PNGs and honest manifest rows

### preflight — capture available
- display_server: X11, smoke 10616 bytes, self-test shots/_preflight.png

### SC-C-01 — boot the real title screen
- expected: the real title scene comes up with Start New Game focused
- actual: booted title in 527 ms (30 settle frames); re-priced in scene: 0.0435 s/frame (was 0.0074 on the empty tree), 113 frames + 1 s boot = 5 s predicted
- events: t=1.67
- verdict: PASS

### SC-C-02 — the title screen is named as the title screen
- expected: input_context is 'title'. Not a formality: every world-verb gate reads permissively when the node it asks about is absent, so the first cut of the probe fell through all of them and reported the title screen as 'world'. This step is what caught it.
- actual: input_context=title (wanted title)
- events: t=1.67
- verdict: PASS

### SC-C-03 — single capture with the HUD on
- expected: a PNG under shots/ in capture mode; a manifest row with file:null and reason 'headless' otherwise
- actual: captured SC-C-title at 1920x1080 (mean luma 50.8, spread 32.4, 5.4% dark)
- events: t=2.02
- verdict: PASS

### SC-C-04 — move focus so the next frames differ
- expected: focus moves off Start New Game, so the sequence below is not three identical frames
- actual: 1 x ui_down moved focus 'Start New Game' (@Button@27) -> 'Load Game' (@Button@28)
- events: t=2.28
- verdict: PASS

### SC-C-05 — a short timed sequence
- expected: three rows, each with its own file (or its own file:null and reason)
- actual: capture_seq SC-C-seq: 3/3 frames written at 4 Hz
- events: t=3.62
- verdict: PASS

### SC-C-06 — close the segment
- expected: a note event closes the segment
- actual: compare shots/manifest.json between a capture-mode run and a headless run of this same segment
- events: t=3.62
- verdict: PASS
