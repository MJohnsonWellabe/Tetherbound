# F04#1 named-fight tells: frames for the code-blind judge

Captured Sun 11 Oct 2026, finished about 2:22 PM CT, by the captures lane. This lane captures; it does not judge.

- **Shows:** Captain Vance (relay_captain): lead Galecrest diver_leap marker (a hit on the still ally, a miss after a step-out) and ace Tuskroot charge lane (a hit, then a miss after a step-off).
- **Source:** tb/ev-captures `355f7ec8`, which merges origin/tb/ev-coordinator `a8899257` (the F22 cue placement fix). Low/Compatibility (llvmpipe), 1280x720, real time.
  - Lead creatures: render.yml run 38159851742.
  - Aces: local run at the same tree with `--live-member=relay_captain:4,captain_field:1,captain_ridge:4`.
- **Tool:** `tools/capture_f04_strike_beats.gd`. It renders the existing `tests/smoke_named_fight_hit_avoid.gd` witness and saves production-camera frames at each strike's tell start, mid-tell, strike and outcome (+3 frames).
  - Its only change to the smoke is the stand/dodge cycle `--policies=stand,stand,dodge,dodge`, so each two-step pattern gets both policies. Dodges use the smoke's approved escape: sideways off a lane or field, away from a cone or ring.
- **Witness result:** every fight PASSed (a landed player hit, a held-still strike that landed, and a strike avoided by moving).
  - Leads: Vance 3/4, Oreth 3/4, Halder 3/4, Vess 3/4 dodges avoided.
  - Aces: Vance 2/4, Halder 4/4, Vess 1/4.
- **Disclosed (the smoke's own help):**
  - a fixture level-3 Terrapup, healed after every strike;
  - a teleport to the stand spot;
  - the ace's earlier team members resolved by `_begin_resolve("won")`;
  - real-time llvmpipe means a beat frame can land up to about 0.13 s after its nominal beat.
