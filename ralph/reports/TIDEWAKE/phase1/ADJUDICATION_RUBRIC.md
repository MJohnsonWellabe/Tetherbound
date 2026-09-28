# C3 framing adjudication (Tidewake Phase 1)

Two code-blind judges given the same prompt disagreed widely on identical frames:

| Fight | Judge A | Judge B |
|---|---|---|
| Tess r4 | 97% | 81% |
| Tidecoil r12 | 100% | 87.5% |
| Nerissa r14 | 100% | 65% |

So a third, code-blind adjudicator ruled every frame for each fight against the COMBAT.md camera sentence:

> Camera must show both combatants' facing and the actionable tell in 90% of active combat samples; no continuous actionable-tell occlusion longer than 0.25s.

The rubric was fixed before any adjudication ran and was the same for all three fights:

- **Excluded (not an active sample):** a knocked-out or downed fighter, or a gap between opponents.
- **FAIL:** a body mostly off-screen; the camera in or behind geometry; the other fighter, a human or scenery hiding a head or direction; a HUD panel over the part that shows facing; or a tell-start frame whose marking is not visible.
- **PASS:** facing reads from the head, or from the body's orientation when the head is hidden. A creature's own pose (a shell, a crouch) passes. A ring partly under its own body passes if its extent shows.

Each adjudicator saw only the fight's folder: the frames, `frames.json`, `JUDGE_A.md` and `JUDGE_B.md`.

**Limit:** stills 4-16 s apart cannot test the clause "no continuous actionable-tell occlusion longer than 0.25s". All three adjudicators called that clause unverified, not passed.
