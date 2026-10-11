# F04#0 Warrens guardian: frames for the code-blind judge (recapture on the cue fix)

Captured Sun 11 Oct 2026, finished about 12:44 PM CT, by the captures lane. This lane captures; it does not judge.

- **Source:** tb/ev-captures `20cc3183`, which merges origin/tb/ev-coordinator `a8899257` (the F22 cue placement fix, the Earth Fist filled wedge and quick-strike outline wedge, the Tether Commands meter at bottom-centre, and the den cairn moved out of the arena). Local Linux container, Godot 4.7-stable, Low/Compatibility (llvmpipe), 1280x720, real time.
- **Tool:** the existing `tests/smoke_warrens.gd -- --guardian-attacks --guardian-settled-approach --capture-dir=<abs>`.
  - The player walks into the den from the hall at the normal fight camera; the guardian was naturally admitted after a 46.9 m input walk.
  - Smoke result: sequence Q, C, Q, C; 1 hit and 2 misses through CombatManager; "warrens guardian attack witness passed".
- **Frames (`sheet.jpg`, `frames/`):**
  - 01: fight start;
  - 02–04: quick strike (violet outline cone): tell, mid-tell, then a hit on the still ally;
  - 05–07: Earth Fist (orange 72° cone, 1.1 s tell): tell, mid-tell, then a miss after a sideways step;
  - 08–09: second quick strike;
  - 10: second Earth Fist, mid-tell.
- **Disclosed:**
  - the step in frame 07 is the smoke's declared 4 m sideways teleport at mid-tell, not stick input;
  - the ally is a level-12 fixture Terrapup with HP refilled;
  - strike 3's frame is saved before its outcome is counted.
