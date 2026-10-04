# F13#5 — Currents, inhabited docks, Veilfall distance read pass the T2 matrix

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1920x1080 (tool writes JPG q0.85; day, clock frozen)
- Command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_tidewake_f13_5.gd -- --out=<dir>` (exit 0; 16 frames; per-frame pose lines in frame_lines.txt)
- Replaces: ralph/reports/TIDEWAKE/phase1/f13_5/ (r1, r2, r3_currents)

## Code-blind judge (fresh agent; 16 frames, criterion, Tidewake §4/§4.1 bar incl. dunes direction, Veilfall board): FAIL

CURRENTS: YES, weakly. DOCKS inhabited: NO. VEILFALL distance read: NO. Bar A: NO. Bar B: NO.

Defects (verbatim summary):
- Veilfall: "None of the three frames shows a mountain, cliff, waterfall or anything white-falls-like." veilfall_1 low sand island; veilfall_2 flat horizon with sandbars; veilfall_3 mostly blocked by a large axolotl creature. No detail gain across 1→2→3; horizon is an empty grey band, no high cloud masses.
- Blocking placeholders: dock_shellwatch flat pale-blue cube on a tan slab beside the NPCs; dock_salt_crown flat white slab beside the NPCs; dock_sluice_isle large untextured blue-grey cube on a tan slab with an orange post in front of the camera, under the "Open the eastern sluice" prompt, hiding the trainer.
- Docks: every dock uses the same short pier with crates and the same 2–3 NPC cluster; no buildings, stalls, nets, boats, lanterns or pumps; dock_first_shore most lived-in (tent, workbench, "Reedhaven Channel Open" sign) but its raft-and-rope ring looks like a stray floor prop.
- Currents: white streak lanes move between plain and _b frames (direction reads) but strength does not; all three share one composition; "read as one pasted streak decal ... nothing about them explains why an approach is gated."
- Bar A misses: single flat cyan sea (no navy depth), no wet dark/salt rock, no damp shore edges, no reeds/marsh, sluice is a cube, no Veilfall, no distance haze. Islands are smooth untextured sand mounds (dock_salt_crown split sand cone with dark shading seams; dock_reedhaven dome with visible crease). Matches: pale warm rippled sand, upright sage/straw beach-grass, shallow transparent cyan at shore.
- Artefacts: white sandbar disc reads as a flat floating plane (current_brine_steps, dock_reedhaven, dock_brine_steps, dock_shellwatch); stone arch in dock_first_shore has a flat blue fill reading as a portal decal; flat cobble decal on sand in veilfall_1; crate/barrel cluster cuts bottom-right of all three veilfall frames.
- Repetition: identical dock prop, NPC trio and camera bearing on every island. Lighting flat, no warm dock accents, no near/far value hierarchy.
- Positive: creatures (axolotl, drake, turtles, frog) appealing and correctly larger than the trainer.

Judge's re-judge prerequisites: Veilfall mountain with white falls on the horizon visible from First Shore and growing per island; replace cube/slab sluice/pump placeholders; dress each dock as a distinct destination; rocky vegetated island silhouettes, navy depth and distance haze.

## Verdict: FAIL
