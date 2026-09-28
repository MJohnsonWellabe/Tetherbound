# Judge B (code-blind, default model): Tidecoil r12
FRAMING 21/24 (87.5%). TELLS 4/4 readable.

Failures:
- tell-ended-000.78: the camera swings behind the ally in 0.2 s. The serpent's body is cut off at the bottom right and under the ability HUD; its head still shows.
- tell-ended-003.97: the trainer stands in front of the serpent's head and neck, partly hiding its facing; the cliff fills about half the frame.
- t-044.02: the ally is in front of the serpent's head and the trainer covers its neck, so its facing can't be read.

Borderline passes: t-000 and t-052 (the ally overlaps the neck), and tell-ended-002.65 and t-048 (stagger flash).

Breaks:
- The ability panel is missing at 003.97.
- The ally's HP reads empty at t-052.
- The tell ring runs into the cliff at t-028.
- The cliff takes 35-50% of the frame.
