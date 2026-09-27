# Doss's bank perch from the earned save

- **Save:** `tests/fixtures/earned_saves/checkpoints/seed4_hall/save`, loaded unmodified with `--save-dir` (earned C1 chain). It carries 1 wood and no fiber.
- **Run:** render.yml **36293529797** at **c9b311ef** (replaces 36287727447, whose frames judge C failed), `--act --activity=doss --budget-s=2400`.
- **Walk:** the player leaves the Hall, walks the road to Doss and is offered the prompt.
- **Gather:** the walker draws the knife from its quick slot (in hand on the second press), fells the nearest fiber bush (`felled:meadows:bushes#40375`), and gathers the felled pile by hand. Fiber goes 0 → 2.
- **Satchel:** opened with its ordinary key before and after the repair (`act-0c`, `act-97`). The receipt reads wood 1→0 and fiber 2→1.
- **Perch frames:** taken from the stand 8 m east of the perch, where the river channel runs behind it. The walker sets the camera pitch to -24° for these frames, a disclosed camera write like the yaw writes.
- **Action:** "Help Doss repair the bank perch". Doss says "Your wood braced the boards and your fiber lashed them."
- **Result:** perch repaired, and the game set `river_nest_doss_cleared`.

No inventory edits.
