# F01#2 — Normal-controller DAY walk reaches every opening NPC, camp and gate

- Commit under test: 826d273c3 (origin/tb/integration)
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, `--rendering-driver opengl3`, 1280x720 (the resolution CI's render.yml used for this tool in the replaced evidence; 1920x1080 would roughly double the ~2 h walk cost on 4 CPUs)
- Command (see cmd.txt):
  `XDG_DATA_HOME=<fresh> xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --script tests/capture_village_walk.gd -- --route=visits --time=day --from-title --capture-dir=<dir>`
- Replaces: ralph/reports/MEADOWS/f01-walks/day_d41ff2f0

## Harness result: FAIL (exit 1)

`[village-walk] FAIL route=visits time=day: ended 9.29m from Mira (needs 3.0m) (captures=24)`
Visited: Grandpa (1.50 m), Tam (0.99 m). Not reached: Mira and everything after (Oskar, Bram, Nessa, Maren, old key, Practice Meadow camp, RoadGate, PondGate, TrailGate). Full walk lines: walk_log.txt. The walk stalls at (17.32, 0.90, 3.92), frames 022-024.

## Code-blind judge (fresh agent; saw only the 24 PNGs, the criterion text and the target list): FAIL

Defects, verbatim, most important first:
1. The walk ends in failure (frames 022–024) with the player stalled by a lamppost and cottage near the "Grandpa's House / The Rise" signpost. 10 of 12 targets are never reached.
2. No frame shows Mira, Oskar, Bram, Nessa, Maren, the old key, Practice Meadow camp, RoadGate, PondGate or TrailGate at interaction distance.
3. The "South Bridge" gateway (frames 019 and 021) is passed by and never reached or prompted.
4. Frame 001: the house wall takes up half the screen at the start position.
5. Frames 002–003: the "Talk to Grandpa" prompt shows while Grandpa is hidden behind the player in a cramped indoor camera.
6. Frame 011: a foreground lamppost covers the player area and the prompt.
7. Frames 004, 006–007 and 012–014: the quick bar hides world content (Grandpa, the bed, a background NPC).

Judge's readability note: trainer centred and clear, dirt paths legible, building scale right beside the 1.80 m trainer.

## Verdict: FAIL

Owning-lane work: the visits route can no longer reach Mira from Tam on current village geometry/NPC placement (stall beside a lamppost and cottage corner at x≈17, z≈4). Reproduced by the independent night run (F01-3: 9.32 m from Mira); the separate day confirm re-run was cancelled.
