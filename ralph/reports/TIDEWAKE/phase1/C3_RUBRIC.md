# C3 framing rubric and protocol (fixed before any judge runs; Tidewake Phase 1, from Nerissa r15 on)

The strict F14#0 re-check found that `ADJUDICATION_RUBRIC.md` was written after two judges' scores were known. That makes the r12, r4 and r14 adjudications soft evidence. From Nerissa r15 on, every C3 round uses this file, unchanged, handed to each judge before it sees any frame.

**Spec** (COMBAT.md, camera): "Camera must show both combatants' facing and the actionable tell in 90% of active combat samples; no continuous actionable-tell occlusion longer than 0.25s."

**Per frame:**
- **EXCLUDED:** a fighter is knocked out, lying downed, at 0 HP, or absent between opponents.
- **FAIL** if any of these holds:
  1. A combatant is mostly off-screen.
  2. The camera is inside or behind geometry.
  3. The OTHER fighter, a human or scenery covers a combatant's head (the camera could have avoided it). This fails even if facing could be inferred from the body.
  4. A HUD panel covers a combatant's head.
  5. On a tell-start frame, the tell's ground marking is not visible.
- **PASS** otherwise. A creature's OWN pose hiding its own head (a shell, a crouch) passes when its body orientation reads. A creature's own body covering part of its own ring passes when the ring's extent shows.

**Protocol:**
- Two independent code-blind judges score each round, one on sonnet and one on the default model.
- A round passes only if BOTH are at or above 90% framing and every tell-start frame shows its marking.
- Each judge's verdict is archived in the round's folder as `JUDGE_A.md` and `JUDGE_B.md`.
- Stills cannot test the 0.25 s clause; it is reported as unverified.
