# F17#1 — Hall reads as the destination from the farm door, judge YES day and night

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1920x1080 fullscreen
- Command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --fullscreen --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tests/capture_hall_destination_day_night.gd -- --capture-dir=<dir>` (exit 0; frames/farm-door-day.png, farm-door-night.png, frames.json)
- Tool disclosure (run_tail.txt): authored post-opening flags/starter; one initial farmhouse floor placement; Hall at (107, 0.85, 14) down a straight path from the actual door (8.3, 0.9, 14).
- Replaces: ralph/reports/HUB/f17/destination-day-night-r2/

## Code-blind judge (fresh agent; saw only the two frames, criterion, §4.1 Village/Hall bar, key art and palworld-02): PASS (DAY YES, NIGHT YES) — narrow

Judge's reasons: one axis, two rows of half-timbered houses frame a continuous road ending at a symmetric stone facade with tall central gable, lit arched door; sky clear above the tallest roof; night sky properly blue, three-gable silhouette holds, warm door/window pools, three depth bands survive.

Defects (verbatim):
- Both frames, scale/identity: the Hall is about as tall as the nearer houses and barely wider. It reads as the end of the road because of the layout, not because it dominates. Its silhouette is close to a large manor or chapel and has no "hall" mass, such as a bigger roofline or tower, to set it apart from the houses. This is the weakest point and the reason both YES verdicts are marginal.
- Both frames, UI: the MAIN STORY panel covers the near right house. A stray world label "Sout…" is cut off at the right screen edge behind or beside the quest panel. The "Call out Terrapup" prompt is drawn over the trainer's backpack. The hotbar shows four empty "+" slots, which is visual noise.
- Day: the foreground road and grass are oversaturated orange-yellow with flat values, more like late-afternoon amber than the "warm neutral day" the clock (08:00) calls for.
- Night: the trainer is lit much brighter than the scene (hair, backpack and trousers look washed out), as if lit by a separate light. A bright pink/magenta glow by the left house's porch looks like a stray particle. Hall door details are small; no portal labels readable at this distance.
- Both frames: cut-off fence/post at right foreground edge and lamp post at left edge (not blocking). No floating objects.

## Verdict: PASS (narrow; Hall mass/dominance is the standing risk)
