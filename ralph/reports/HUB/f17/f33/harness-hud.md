# Harness HP on the combat HUD (in-engine capture, text record)

**Source:** `tools/capture_combat_actions.gd -- --harness=stormglass_harness_plus_3`, run in render mode (opengl3, 1280x720).

**Frames:** two (normal, and low HP with charged). They are not kept in the repo; owner ruling 12 says new evidence images go to CI artifacts.

**Observed:**
- The ally panel's level line reads "Lv 3 · HP 229/229". At low HP it reads "Lv 3 · HP 36/229".
- 229 = base 134.4 × 1.702 (Stormglass +3).
- Both lines fit on one line of the 280 px panel, with no overlap and no crowding.

**Reproduce:** run the command above. It writes `shots/_diag/combat_*_harness.png`.
