# Doss's bank perch from the earned save

- **Save:** `tests/fixtures/earned_saves/checkpoints/seed4_hall/save`, loaded unmodified with `--save-dir` (earned C1 chain). It carries 1 wood and no fiber.
- **Run:** render.yml 36287727447 at 28c0fa05, `--act --activity=doss --budget-s=2400`.
- **Walk:** the player leaves the Hall, walks the road to Doss and is offered the prompt.
- **Gather:** the walker draws the knife from its quick slot (in hand on the second press), fells the nearest fiber bush (`felled:meadows:bushes#40375`), and gathers the felled pile by hand. Fiber goes 0 → 2.
- **Action:** "Help Doss repair the bank perch"; three dialogue rounds pay the wood and fiber.
- **Result:** perch repaired, and the game set `river_nest_doss_cleared`.

No inventory edits.
