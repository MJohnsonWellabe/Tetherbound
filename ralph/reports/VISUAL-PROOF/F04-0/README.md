# F04#0 Warrens guardian: witness frames for the code-blind judge

Captured Sun 11 Oct 2026, about 10:20 AM CT, by the captures lane (branch `tb/ev-captures`). This lane captures frames; it does not judge.

- **Source:** commit `70f74007` (tb/ev-captures = origin/tb/ev-coordinator `94368e45` + one capture-tool commit that does not touch this path). It contains the F04#0 fix `ea3a1ebb` and the F04#2 witness change `2304f46c`.
- **Run:** render.yml run 38152212608 (render mode, `gl_compatibility`, OpenGL on llvmpipe in xvfb, 1280x720, real-time). Exit 0 in 2060 s.
- **Command:** `tests/smoke_warrens.gd -- --guardian-attacks --guardian-settled-approach --capture-dir=<abs>`. This is the existing smoke's own capture mode; no new tool was used.
- **Result printed by the smoke:** natural admission after a 46.3 m input walk from the hall; sequence Q, C, Q, C; resolved through CombatManager with 1 hit and 2 misses; "warrens guardian attack witness passed". See `run_excerpt.log`.

## Frames (`sheet.jpg`, full frames in `frames/`)

1. Fight start at the normal production fight camera, reached by walking in from the hall (not a teleport into the den).
2–4. Quick strike: tell start, mid-tell with the ally held still, after the strike (a hit).
5–7. Earth Fist: tell start, mid-tell (1.1 s tell), after the strike, with the ally moved sideways (a miss).
8–9. Second quick strike: mid-tell, and 3 frames after the strike.
10. Second Earth Fist, mid-tell.

## Disclosures

- **The sideways step in frame 7 is a fixture move.** The smoke teleports the ally 4 m sideways of the guardian's locked heading at mid-tell (declared in `tests/smoke_warrens.gd`), not by stick input. The miss itself is the production resolver's outcome.
- **Fixture setup:** a level-12 Terrapup enrolled in `Game.party`, with HP refilled each frame. The player is teleported to the hall start; everything after that is input-driven.
- **Strike 3's outcome isn't confirmed at its frame.** It was saved 3 frames after the strike and the running count is still 1 hit / 1 miss. The run's final total is 2 misses. Strike 4 has no after-strike frame because the smoke stops after four strikes.
- **Renderer limits:** Compatibility only. render.yml has no Low/Medium/High input, and Forward+ crashes on its llvmpipe Vulkan (coordinator, 11:13 AM CT). Software GL in real time, so frame pacing and fine lighting are not representative.
