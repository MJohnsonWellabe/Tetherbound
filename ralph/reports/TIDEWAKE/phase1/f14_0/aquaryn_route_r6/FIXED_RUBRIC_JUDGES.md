# Aquaryn r6, ordinary route, under `../../C3_RUBRIC.md`

**Approach** (`APPROACH.txt`): starts at the `shellwatch_to_tidal_cradle_arrival` landing.
- The player walks 152 m (24 legs) by left stick.
- The lead is deployed by the `creature_recall` input.
- The player closes on the "Challenge Aquaryn" prompt and presses `interact` (`engaged_by=challenge_prompt`).
- There is no placement beside the basin and no direct `request_engage()` call. The capture code is `tests/capture_tidewake_named_fights.gd::_walk_to_aquaryn`.

**Results:**
- **Judge A (sonnet):** FRAMING 20/20 (100%), 1 excluded (t-040.02: Aquaryn at 0 HP, won). Tell-start markings 4/4.
- **Judge B (default model):** FRAMING 20/20 (100%), 1 excluded (t-040.02). Tell-start markings 4/4.
  - Recovery frames where Aquaryn's own crest hides its head pass by the own-pose clause.

**Protocol result: PASS.** The 0.25 s clause is unverified from stills.

**Declared shortcut:** a granted L43 five with a Ripplet lead, and the READER harness pilot pressing real inputs.
